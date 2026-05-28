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

Do not add a blank line under visibility modifiers. Indent content under them.

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

For modules with only private methods, mark `private` at the top with an extra blank line after, but do not indent:

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
- Prefer explicit contracts (`find_by!`, `fetch`).
- Rescue only specific exceptions with intentional handling.
- When a call chain is incorrect, update the call chain and underlying data contracts; do not add indirection layers.
- Do not branch on both symbol and string keys for the same hash. Normalize keys once at the boundary.

### Bang Methods In Jobs And Orchestration Code

In jobs and POROs, use bang methods (`save!`, `update!`, `create!`) so failures raise immediately. Silent failures in background jobs are invisible until data is corrupt.

```ruby
# Bad — silent failure in job
class ProcessOrderJob < ApplicationJob
  def perform(order)
    order.process
    order.save  # returns false silently
  end
end

# Good — raises on failure
class ProcessOrderJob < ApplicationJob
  def perform(order)
    order.process!
    order.save!
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
