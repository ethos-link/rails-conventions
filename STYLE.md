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

## CRUD Controllers

Model web endpoints as CRUD operations on resources (REST). When an action does not map cleanly to a standard CRUD verb, introduce a new resource instead of adding custom actions.

```ruby
# Bad
resources :cards do
  post :close
  post :reopen
end

# Good
resources :cards do
  resource :closure      # POST to close, DELETE to reopen
  resource :goldness     # POST to gild, DELETE to ungild
end
```

## Controller And Model Interactions

Favor a vanilla Rails approach: thin controllers directly invoking a rich domain model. Do not use services or other artifacts to connect the two.

Invoking plain Active Record operations is fine:

```ruby
class Cards::CommentsController < ApplicationController
  def create
    @comment = @card.comments.create!(comment_params)
  end
end
```

For more complex behavior, prefer clear, intention-revealing model APIs:

```ruby
class Cards::ClosuresController < ApplicationController
  def create
    @card.close
  end
end
```

When justified, POROs are acceptable but do not treat them as special artifacts:

```ruby
Signup.new(email_address: email_address).create_identity
```

## Concerns

### When To Extract

- Extract a concern when the same behavior pattern appears across 3+ models or controllers.
- Extract a concern for cohesive, related functionality — not to reduce file size.
- Name concerns for the capability they provide: `Closeable`, `Watchable`, `Assignable`.

### Structure

Each concern should be 50–150 lines and self-contained:

```ruby
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy

    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }
  end

  def closed?
    closure.present?
  end

  def close(user: Current.user)
    unless closed?
      transaction do
        create_closure! user: user
        track_event :closed, creator: user
      end
    end
  end

  def reopen(user: Current.user)
    if closed?
      transaction do
        closure&.destroy
        track_event :reopened, creator: user
      end
    end
  end
end
```

## POROs

POROs live under model namespaces for related logic that does not need persistence. They are model-adjacent, not controller-adjacent.

```ruby
# app/models/event/description.rb
class Event::Description
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def to_s
    case event.action
    when "created"  then "#{creator_name} created this card"
    when "closed"   then "#{creator_name} closed this card"
    else "#{creator_name} updated this card"
    end
  end

  private
    def creator_name
      event.creator.name
    end
end
```

Do not use `*Service`, `*Manager`, or `*Handler` suffixes. Use domain nouns.

## Scope Naming

Name scopes for business concepts, not SQL operations:

```ruby
# Good
scope :active, -> { where.missing(:pop) }
scope :unassigned, -> { where.missing(:assignments) }

# Bad
scope :without_pop, -> { ... }
scope :no_assignments, -> { ... }
```

## Job Patterns

### `_later` and `_now` Convention

When a model method enqueues a job that invokes another method on that same class, use `_later` for the async version and `_now` for the synchronous version:

```ruby
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later
  end

  def relay_later
    Event::RelayJob.perform_later(self)
  end

  def relay_now
    # actual work
  end
end

class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

### Shallow Jobs

Jobs should be shallow — they delegate to model methods:

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(notifiable)
    notifiable.notify_recipients
  end
end
```

## Fail-Fast

- Avoid defensive patterns that hide errors (`respond_to?`, `try`, dynamic `send`, broad `rescue`).
- Prefer explicit contracts (`find_by!`, `fetch`).
- Rescue only specific exceptions with intentional handling.
- When a call chain is incorrect, update the call chain and underlying data contracts; do not add indirection layers.
- Do not branch on both symbol and string keys for the same hash. Normalize keys once at the boundary.

### Bang Methods In Jobs And Services

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

### Bulk Operations In Transactions

Wrap multi-step mutations in transactions. If any step fails, all changes roll back:

```ruby
def bulk_change_owner(user)
  transaction do
    all.find_each do |record|
      record.update!(owner: user)
    end
  end
end
```

## Strict Locals

All component partials must declare their variables on the first line using strict locals. Do not rely on instance variables in shared partials. Do not use `**locals` splat.

```erb
<%# locals: (title:, description:, card: nil) %>

<h2><%= title %></h2>
<p><%= description %></p>
<%= render "cards/preview", card: card if card %>
```

## Provider Parsing Contract

- Provider parsers must only map fields present in the source payload or HTML; do not invent fallback values during parsing.
- Do not set model defaults in parsers or import normalizers; defaults belong on the persisted models or their write path.
- If stored/raw provider payloads are partial, normalize the payload shape in the orchestrator before calling the provider parser.
