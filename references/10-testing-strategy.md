# Testing Strategy

## Minitest Over RSpec

Use Minitest. It ships with Rails, has simpler syntax, faster boot time, and plain Ruby assertions.

## Fixtures Over Factories

Use fixtures for deterministic, preloaded test data. Do not add factories.

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

Use `data-test-id` selectors for stable, intention-revealing test targets:

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

  parallelize(workers: :number_of_processors)
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
- Cassette naming: `{platform}_{resource}[optional_suffix].yml`.
- Inbound webhooks use JSON captures in `test/support/webhook_captured/` (do not use VCR).

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

Tests ship with features in the same commit — not beforehand, not afterward. Security fixes always include regression tests.

## Minimum Coverage For Feature Work

- Model/business behavior tests.
- Request/controller integration tests covering happy and sad paths.
- Job enqueue/execution tests.
- System tests for critical user flows when UI changes.

## Test Quality

- Assert behavior and observable outcomes, not framework internals.
- Controller/system tests must assert response/redirect plus content or side effects.
- Keep fixtures small (~10 records per type) for speed and determinism.
- Avoid over-mocking core domain behavior.

## Antipatterns To Avoid

### No `sleep` In Tests

Do not use `sleep` to wait for async behavior. Use `travel_to` for time-dependent tests or event-based waits:

```ruby
# Bad
sleep 2
assert page.has_content?("Done")

# Good
travel_to 2.seconds.from_now do
  assert page.has_content?("Done")
end
```

### No Tests Coupled To HTML Structure

Use `data-test-id` selectors, not CSS class or tag-based selectors:

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
