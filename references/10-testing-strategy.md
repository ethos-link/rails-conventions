# Testing Strategy

## Minitest Over RSpec

Use Minitest for new applications. Preserve an existing RSpec suite and its
supported helpers; do not introduce a second framework or migrate test style
as part of unrelated work. Do not add factory or mocking dependencies merely
to follow an example in this skill.

## Fixtures Over Factories

Prefer fixtures for new Minitest suites. Preserve established factory usage
where the app already owns that convention; do not add a parallel data setup
system or another dependency.

```yaml
# test/fixtures/users.yml
david:
  identity: david
  account: basecamp
  role: admin

jason:
  identity: jason
  account: basecamp
  role: member
```

**Why fixtures**:
- Loaded once, reused across tests.
- No runtime object creation overhead.
- Relationships are explicit and visible.
- Deterministic IDs for debugging.

Use labels, not IDs, for relationships:

```yaml
# test/fixtures/cards.yml
urgent_bug:
  board: engineering
  creator: david
  title: "Fix login bug"
```

Use ERB for dynamic values:

```yaml
recent_card:
  board: engineering
  creator: david
  created_at: <%= 1.hour.ago %>
```

## Split Responsibilities By Layer

Each test layer owns a different question. Do not re-prove the same logic at
every layer.

| Layer | Proves | Coverage posture |
|-------|--------|------------------|
| Unit (models, POROs, parsers) | Domain rules, invariants, edge cases | Thorough — high coverage of the logic itself is valuable |
| Job unit | Idempotency, retries, payload handling | Thorough for the job/domain method under test |
| Request / integration | HTTP contract: status, redirect, authz, a few durable side effects | Narrow and value-based |
| System | Critical user journeys that need the browser | Few, high-signal flows only |

### Value-Based Assertions

Assert outcomes that matter to the user or the system — not markup dumps,
framework internals, or every line of a template.

- Prefer persisted state, response status/redirect, flash, enqueued jobs,
  delivered mail, and other real side effects.
- Prefer one clear page signal (for example an `h1` or a stable
  `data-test-id`) over asserting the full HTML body.
- Prefer a couple of side effects after a request over repeating model-unit
  assertions inside the request test.

```ruby
# Good — request test: HTTP + heading + side effects
test "closing a card" do
  card = cards(:urgent_bug)

  assert_difference -> { Event.where(action: :closed).count }, 1 do
    post card_closure_path(card)
  end

  assert_redirected_to card_path(card)
  follow_redirect!
  assert_select "h1", text: card.title
  assert card.reload.closed?
end

# Bad — request test that re-tests the model and scrapes the whole page
test "closing a card" do
  post card_closure_path(cards(:urgent_bug))

  assert_select "div.card-header span.badge", text: "Closed"
  assert_select ".activity-feed .event", count: 12
  assert_select "p", text: /closed by/
  assert_equal users(:david), cards(:urgent_bug).reload.closure.creator
  assert_equal "closed", cards(:urgent_bug).events.last.action
  # ...more model-edge assertions that belong in CardTest
end
```

```ruby
# Good — unit test owns the logic thoroughly
class CardTest < ActiveSupport::TestCase
  test "closing creates closure and event" do
    card = cards(:urgent_bug)

    assert_difference "Event.count", 1 do
      card.close(user: users(:david))
    end

    assert card.closed?
    assert_equal users(:david), card.closure.creator
  end

  test "closing is idempotent" do
    card = cards(:urgent_bug)
    card.close(user: users(:david))

    assert_no_difference "Event.count" do
      card.close(user: users(:david))
    end
  end

  test "closed cards cannot be edited" do
    card = cards(:urgent_bug)
    card.close(user: users(:david))

    assert_not card.editable_by?(users(:david))
  end
end
```

## Library Ownership And Browser Cost

Test each guarantee in the repository that owns its implementation. Shared UI
primitives and generic interactions belong in the design-system library; shared
billing algorithms, accounting invariants and provider reconciliation belong in
the billing library. Consumer applications own configuration, authorization,
tenant binding, product policies and integration with those libraries. Moving a
library matrix from browser tests to consumer unit tests still duplicates its
owner's coverage.

Keep a few critical host browser workflows through real installed libraries,
such as selecting and subscribing to a plan. Control external provider calls;
do not stub the library operation or mutate payment state to bypass the path
being proved. Keep a host regression when composition, asset loading or Turbo
lifecycle creates a specific integration risk. Before deleting duplicate host
coverage, verify the consumed library release proves the contract. Move missing
reusable implementation and its generic tests upstream together; keep product
adapters local and remove them only after adopting the released replacement.

Use one browser worker by default. Increase concurrency only after measuring
CPU, memory, disk use and failure rates under an explicit resource budget. Do
not derive browser concurrency from the machine's processor count. Avoid routine
successful screenshots in functional tests; keep expanded viewport/theme
matrices in explicit visual review tooling. Compare drivers on the same passing
workload and resource limits before selecting one; do not keep two permanent
system suites for an experiment.

When coverage is enabled, use the installed SimpleCov Rails profile and native
worker merging. Prefer Rails `test:all` for one normal-and-system test run; keep
test class names distinct across layers. Preserve the existing report formatter.
Honor an application's always-on coverage requirement; do not add an opt-in
`COVERAGE` flag or another coverage-only test pass. Do not claim a focused run
is full coverage. Ruby coverage does not measure browser JavaScript.

## Test Structure

### Unit Tests (Models)

```ruby
class CardTest < ActiveSupport::TestCase
  setup do
    @card = cards(:urgent_bug)
    @user = users(:david)
  end

  test "closing a card creates an event" do
    assert_difference "Event.count", 1 do
      @card.close(user: @user)
    end

    assert @card.closed?
  end

  test "closed cards cannot be edited" do
    @card.close(user: @user)

    assert_not @card.editable_by?(@user)
  end
end
```

### Integration Tests (Controllers)

Keep these short. Prove the request path works; leave combinatorial logic to
unit tests.

```ruby
class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:david)
    sign_in_as @user
  end

  test "creating a card" do
    assert_difference "Card.count", 1 do
      post board_cards_path(boards(:engineering)),
        params: { card: { title: "New feature" } }
    end

    assert_redirected_to card_path(Card.last)
    follow_redirect!
    assert_select "h1", text: "New feature"
  end

  test "unauthorized users cannot delete" do
    sign_in_as users(:guest)

    assert_no_difference "Card.count" do
      delete card_path(cards(:urgent_bug))
    end

    assert_response :forbidden
  end
end
```

### System Tests

Use stable `data-test-id` attributes for application-owned system-test targets.
Treat their values as testing contracts: name them by purpose, keep them
independent of copy, locale, CSS classes, and layout, and make them unique
within the queried scope. Repeated records may include their stable record ID;
do not use array positions, random values, or translated strings.

Configure Capybara's built-in selectors in the system-test base:

```ruby
Capybara.test_id = "data-test-id"
```

Then a button with `data-test-id="save"` can be addressed semantically:

```ruby
click_button "save"
```

Use semantic controls and preserve labels, roles, and accessible names. When
those properties are part of the behavior under test, assert them explicitly
or locate by them. Test IDs do not prove accessibility or replace assertions on
visible customer outcomes. Do not add a selector attribute to every node.

Pair stable selectors with Capybara's waiting finders and assertions. Wait for
the resulting UI state after Turbo or asynchronous work, not merely the
presence of a pre-existing container. Use `assert_no_selector` for disappearance;
do not negate a positive query. Avoid positional selectors and `.first` to hide
ambiguous matches, sleeps, global timeout increases, or retries that mask races.
See [Capybara configuration](https://github.com/teamcapybara/capybara/blob/master/lib/capybara.rb)
and [synchronization](https://github.com/teamcapybara/capybara#asynchronous-javascript-ajax-and-friends).

Assert the journey outcome, not every visible node.

```ruby
class CardSystemTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:david)
  end

  test "dragging card between columns" do
    visit board_path(boards(:engineering))

    card = find("[data-test-id='card-#{cards(:urgent_bug).id}']")
    target = find("[data-test-id='column-doing']")

    card.drag_to(target)

    assert_selector "[data-test-id='column-doing'] [data-test-id='card-#{cards(:urgent_bug).id}']"
  end
end
```

## Test Helpers

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  include SignInHelper

  parallelize(workers: Integer(ENV.fetch("PARALLEL_WORKERS", "1")))
  fixtures :all
end
```

## Testing Time

Use `travel_to` for time-dependent tests:

```ruby
test "cards auto-close after inactivity" do
  card = cards(:stale_card)

  travel_to 31.days.from_now do
    Card.auto_close_stale!
    assert card.reload.closed?
  end
end
```

## Testing Jobs

```ruby
test "closing card enqueues notification job" do
  assert_enqueued_with(job: NotifyWatchersJob) do
    cards(:urgent_bug).close(user: users(:david))
  end
end

test "notification job sends emails" do
  perform_enqueued_jobs do
    cards(:urgent_bug).close(user: users(:david))
  end

  assert_emails 3
end
```

## HTTP, VCR, And Webhooks

- WebMock must remain enabled in tests; do not allow live HTTP.
- Outbound API calls use VCR cassettes in `test/support/cassettes/`.
- Follow the existing cassette naming convention. For new suites, use
  `{platform}/{resource}[optional_suffix].yml`.
- Inbound webhooks use JSON captures in `test/support/webhook_captured/` (do not use VCR).

For webhook delivery architecture, load `references/14-webhooks.md`.

## VCR For External APIs

```ruby
test "fetching provider data" do
  VCR.use_cassette("provider/fetch_reviews") do
    reviews = Provider::Reviews.fetch(business)

    assert_equal 5, reviews.count
  end
end
```

## When Tests Ship

Ship necessary regression coverage with the changed behavior. Reversible copy
or low-impact presentation edits do not require tests that merely mirror their
implementation. Security fixes always include regression tests.

## Minimum Coverage For Feature Work

Select only the layers needed to prove the changed behavior. This is not a
checklist requiring a model, request, job and system test for every change.

- Model/business behavior tests with thorough coverage of the logic.
- Request/controller tests for happy and sad HTTP paths — status, authz, and a
  few side effects — not full-page content inventories.
- Job enqueue/execution tests for async boundaries.
- System tests only for critical user flows when UI behavior cannot be proven
  cheaper at a lower layer.

## Regression Proof

When a bug has a practical local test path, add the smallest regression and run
it against the original behavior before fixing it. Confirm the failure is the
reported defect, not a missing fixture, syntax error, or unavailable service.
Then run it with the fix and the relevant nearby checks. Keep necessary coverage
with the fix; do not require a separately committed failing test.

If the fix already exists, use an isolated checkout or temporarily restore only
the relevant implementation to establish failing-before evidence. Preserve
unrelated work and restore the candidate before its final checks. Do not alter
shared databases or run destructive resets to demonstrate a failure.

For an expensive or production-only reproduction, use the closest meaningful
check and state its limits. Do not build a large test harness, mock the core
operation, or weaken an assertion to manufacture red/green evidence.

## Test Quality

Judge meaningful assertions against two changes:

- Break the contract: return the wrong result, omit an effect, repeat it, or allow
  a forbidden action. The test should fail.
- Preserve observable behavior while changing internal helpers or call order.
  The test should continue passing.

Derive expected values from the contract rather than computing them through the
implementation under test. For a consequential new regression, consider a small
temporary fault injection when practical to confirm the assertion detects the
failure; full mutation testing is not a universal gate. An external provider's
observed payload or absence of a charge can be behavior. A private helper's call
count usually is not. Pair a no-effect assertion with a positive case when needed
to show that the observation can detect that effect.

- Assert behavior and observable outcomes, not framework internals.
- Prefer persisted state, rendered landmarks, delivered mail, enqueued jobs, and
  other real side effects over mocks, stubs, or expectations on framework
  plumbing.
- Split assertions by responsibility: deep logic in unit tests; thin HTTP
  contracts in request tests.
- For catalogs, routes, sitemaps, and navigation, assert representative examples
  and important exclusions or invariants; do not copy the complete configured
  value list into a test.
- Keep fixtures small (~10 records per type) for speed and determinism.
- Do not test private methods directly. If private behavior is hard to reach
  through public behavior, simplify the production design.
- Avoid mocks and stubs for core domain behavior. Use them only at external
  boundaries or when the alternative would make the test slow, flaky, or
  unclear.

## Minitest Mocks

Use `Minitest::Mock` when a test double is justified. Set expectations with
`expect`, exercise the public behavior, and call `verify`.

```ruby
test "notifies provider" do
  provider = Minitest::Mock.new
  provider.expect :deliver, true, [String]

  Notification.new(provider: provider).deliver("Hello")

  provider.verify
end
```

Prefer mocks at external boundaries such as provider clients, mail delivery
adapters, and payment gateways. Do not mock the object under test or its core
domain collaborators just to avoid designing a clearer public API.

## Antipatterns To Avoid

### No Full-Page Content Inventories In Request Tests

Do not `assert_select` every paragraph, badge, and partial. Pick a landmark and
side effects. Exhaustive rendering checks belong in focused view/component tests
only when that contract needs direct rendering coverage. Do not promote a
markup inventory to a browser test.

### No Logic Coverage Gaps Filled By Request Tests

If a model method has many branches, cover them in the model test. A request
test that posts once does not replace unit coverage.

### No `sleep` In Tests

Use Capybara's waiting assertions for browser readiness. `travel_to` changes
Ruby time; it does not advance JavaScript timers, finish fetches or wait for
Turbo. Use it only when the behavior under test depends on server time:

```ruby
# Bad
sleep 2
assert page.has_content?("Done")

# Good
assert_text "Done", wait: 5
```

### No Tests Coupled To HTML Structure

Use `data-test-id` selectors or semantic landmarks (`h1`, role), not brittle CSS
class trees:

```ruby
# Bad — breaks when markup changes
find(".card-wrapper > .header > .title")

# Good — stable, intentional selector
find("[data-test-id='card-title']")
```

### No Shared Mutable State Between Tests

Each test must be independent. Do not rely on test execution order:

```ruby
# Bad — depends on previous test
$global_counter ||= 0

# Good — each test is self-contained
test "increments" do
  counter = 0
  assert_equal 1, counter + 1
end
```

### No Stubbing The System Under Test

Do not stub the object you are testing. If stubbing is needed, simplify the production design:

```ruby
# Bad
test "processes order" do
  order = orders(:pending)
  allow(order).to receive(:charge_card).and_return(true)
  # ...
end
```
