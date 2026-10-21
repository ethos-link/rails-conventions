# Code Style

We write code that is a pleasure to read. We care about how code reads, how code looks, and how it makes you feel when you read it. When writing new code, find similar existing code for inspiration.

## Conditional Returns

Prefer expanded conditionals over guard clauses.

```ruby
# Bad
def todos_for_new_group
  ids = params.require(:todolist)[:todo_ids]
  return [] unless ids
  @bucket.recordings.todos.find(ids.split(","))
end

# Good
def todos_for_new_group
  if ids = params.require(:todolist)[:todo_ids]
    @bucket.recordings.todos.find(ids.split(","))
  else
    []
  end
end
```

Guard clauses are acceptable for early returns at the method start when the main body is non-trivial:

```ruby
def after_recorded_as_commit(recording)
  return if recording.parent.was_created?

  if recording.was_created?
    broadcast_new_column(recording)
  else
    broadcast_column_change(recording)
  end
end
```

## Method Ordering

Order methods in classes:

1. `class` methods
2. `public` methods with `initialize` at the top
3. `private` methods

## Invocation Order

Order methods vertically based on their invocation order. This helps understand the flow of the code.

```ruby
class SomeClass
  def some_method
    method_1
    method_2
  end

  private

  def method_1
    method_1_1
    method_1_2
  end

  def method_1_1
    # ...
  end

  def method_2
    # ...
  end
end
```

## Bang Convention

Only use `!` for methods that have a corresponding non-`!` counterpart. Do not use `!` to flag destructive actions. Ruby and Rails have plenty of destructive methods without `!`.

```ruby
# Good — counterpart exists
user.save
user.save!

# Bad — no counterpart, ! is unnecessary
def calculate!
  # ...
end
```

## Visibility Modifiers

Follow the repository's configured formatter for `private`, `protected` and
`public` sections. With Standard or the usual RuboCop layout, put a blank line
after the visibility modifier and align the methods with public methods.
Visibility modifiers do not introduce an indentation level.

Do not add `rubocop:disable` directives, formatter exceptions or explanatory
comments to preserve a conflicting skill layout. Fix the formatting instead.

```ruby
class SomeClass
  def some_method
    # ...
  end

  private

  def some_private_method_1
    # ...
  end

  def some_private_method_2
    # ...
  end
end
```

Use the same layout for modules containing only private methods:

```ruby
module SomeModule
  private

  def some_private_method
    # ...
  end
end
```

## Naming

## Code Language

Prefer one-word precise names. Qualify only when a bare word is ambiguous
(`contact_phone`, `place_eid`). One canonical term per concept; do not add
parallel names for the same thing.

Review new names across Ruby, JavaScript/Stimulus, component partials, params,
i18n keys, and persisted fields. Namespaces and conventional suffixes (`Job`,
`Controller`, `_at`, `_id`, `_eid`) do not excuse redundant descriptive words.
Necessary ownership qualifiers and framework-defined APIs remain valid; do not
rename public contracts or existing domain terminology for style alone.

Names should be concrete domain nouns or intention-revealing verbs. Public APIs
should say what the caller is asking the object to do, not how the object is
implemented.

Comments should explain why, invariants, data contracts, security assumptions,
or non-obvious Rails behavior. Do not comment what the next line says.

Avoid vague class names such as `Manager`, `Handler`, `Processor`, `Helper`, and
`Service`. Prefer the domain concept: `Publication`, `Closure`, `Signup`,
`Subscription`.

Prefer precise verbs over generic verbs. Use `close`, `publish`, `archive`, or
`charge` instead of `process`, `handle`, `execute`, or `perform` unless Rails
owns the verb, such as `Job#perform`.

## Predicates

### Positive Predicates

Prefer positive predicate names over negative ones:

```ruby
# Good
def active?
  deleted_at.nil?
end

# Bad
def not_deleted?
  deleted_at.nil?
end
```

### Domain Terms

Use domain language over technical names:

```ruby
# Good — domain concept
class Closure < ApplicationRecord
end

# Bad — technical description
class CardCloseRecord < ApplicationRecord
end
```

### Singular `!` for Counterparts

Use `!` only when a non-`!` version exists. Do not use `!` to signal "this raises" or "this is destructive" without a counterpart.

## Rails Architecture References

Keep architecture rules in the topic references:

- Routing and CRUD resources: `references/05-routes-rest-and-resources.md`
- Controller and model boundaries: `references/04-controllers-and-params.md`
- Naming, concerns, POROs, and scope names: `references/02-naming-and-structure.md`
- Models, transactions, and data handling: `references/03-models-and-data.md`
- Background jobs: `references/07-background-jobs-overview.md`

## Fail-Fast

- Avoid defensive patterns that hide errors (`respond_to?`, `try`, dynamic `send`, broad `rescue`).
- Do not use `send` or `public_send` for a closed set of methods. Use `case`.
- Prefer explicit contracts (`find_by!`, `fetch`).
- Rescue only specific exceptions with intentional handling.
- When a call chain is incorrect, update the call chain and underlying data contracts; do not add indirection layers.
- Do not branch on both symbol and string keys for the same hash. Normalize keys once at the boundary.

## Generated Code Review

Apply these criteria to the actual application diff as required by `SKILL.md`.
They apply to all changed code, whether generated, hand-written, or delegated.
Inspect behavior and contracts before deleting a suspected smell; syntax alone
cannot distinguish a fallback from a supported capability check.

### Forwarding Layers And Parallel Names

Prefer the existing owner over a class that only renames its operation:

```ruby
# Bad: a new name and file with no policy or adaptation.
class PublicationService
  def self.call(article)
    article.publish
  end
end

# Good: the domain owner already exposes the requested operation.
article.publish
```

A domain-named PORO may own real cross-domain orchestration. Its responsibility,
not the word chosen for the class, must justify its existence. Follow the
structure reference rather than introducing a universal service layer. Use one
canonical term through params, models, tests, and serializers; do not alternate
synonyms for the same concept within a change. Preserve established external
contracts when a coordinated rename is outside scope.

### Defensive Fallbacks

Do not hide a missing required collaborator or method behind a successful no-op:

```ruby
# Bad: callers require publication, but an invalid object silently succeeds.
begin
  article.publish if article.respond_to?(:publish)
rescue StandardError
  nil
end

# Good: a broken contract remains visible to the caller.
article.publish
```

Review `try`, safe navigation, `allow_nil`, dynamic dispatch, and rescue paths
against the actual contract. Known optional associations and capability-based
external interfaces can legitimately need checks; do not remove those checks
merely to satisfy a pattern search. Rescue named expected errors with deliberate
handling. Validate untrusted data at its boundary and enforce persisted
invariants at their owner; do not treat dynamic Ruby as a static type proof.

### Comments And Generator Provenance

```ruby
# Bad: repeats the operation's name.
# Save the article.
article.save!

# Good: records a concurrency invariant the call alone cannot explain.
# The unique index arbitrates concurrent delivery creation.
delivery = event.deliveries.create_or_find_by!(webhook: webhook)
```

Keep legal notices, required directives, strict-locals declarations, public
contracts, security assumptions, migration/backfill preconditions, and useful
non-obvious reasons. Do not replace them with a blanket no-comments rule.

Inspect newly added migration, installer, controller, job, and mailer files
against the generator that owns them. Require an actual generator invocation
and inspect its output; a plausible filename or timestamp is not provenance.
If the generator cannot run, report the missing capability under `SKILL.md`'s
generator policy rather than fabricating its output.

Review new compatibility branches and old internal entry points for supported
callers. Delete obsolete paths in a coordinated internal migration; retain
compatibility required by public contracts, staged database rollouts, or the
project's supported version range. Do not add fallback branches for an imagined
older runtime. Review changed tests against the behavior criteria in
`references/10-testing-strategy.md`, including whether they exercise the actual
operation and observe consequential outcomes.

### Bang Methods In Jobs And Orchestration Code

In jobs and POROs, use bang methods (`save!`, `update!`, `create!`) so failures raise immediately. Silent failures in background jobs are invisible until data is corrupt.

```ruby
# Bad — silent failure in job
class Order::SubmissionJob < ApplicationJob
  def perform(order)
    order.update(submitted_at: Time.current) # Validation failure is ignored.
  end
end

# Good — raises on failure
class Order::SubmissionJob < ApplicationJob
  def perform(order)
    order.update!(submitted_at: Time.current)
  end
end
```

In controllers, `save` (without `!`) is acceptable for form validation flows where you re-render on failure. Use `save!` when success is expected and failure is exceptional.

## Strict Locals

All component partials must declare their variables on the first line using strict locals. Do not rely on instance variables in shared partials. Do not use `**locals` splat.

```erb
<%# locals: (title:, description:, card: nil) %>

<h2><%= title %></h2>
<p><%= description %></p>
<%= render "cards/preview", card: card if card %>
```
