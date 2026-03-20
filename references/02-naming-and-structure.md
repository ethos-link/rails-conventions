# Naming And Structure

## Naming

### Domain Language

Use domain terms over technical names:

```ruby
# Good
class Closure < ApplicationRecord
class Membership < ApplicationRecord
class Publication < ApplicationRecord

# Bad
class CardCloseRecord < ApplicationRecord
class UserMembershipEntry < ApplicationRecord
```

Keep one canonical term per concept across code, APIs, and docs. When a term changes, update call chains — do not add long-lived wrappers.

### Positive Predicates

Prefer positive predicate names over negative ones:

```ruby
# Good
def active?
  deleted_at.nil?
end

def unassigned?
  assignments.empty?
end

# Bad
def not_deleted?
  deleted_at.nil?
end

def no_assignments?
  assignments.empty?
end
```

### Explicit Method Names

Keep method names explicit. Hidden behavior in methods with generic names leads to surprises.

```ruby
# Good
def process_payment
  charge_card
  send_receipt
  update_inventory
end

# Bad — hidden behavior
def do_thing
  charge_card
  send_receipt
  update_inventory
end
```

## Layering

### Controllers

- Keep controllers thin and orchestration-focused.
- Controllers authenticate, authorize, parse input, delegate, and return response.
- Business logic does not belong in controllers.

```ruby
# Good
class Cards::ClosuresController < ApplicationController
  def create
    @card.close
  end
end

# Bad
class Cards::ClosuresController < ApplicationController
  def create
    @card.transaction do
      @card.create_closure!(user: Current.user)
      @card.events.create!(action: :closed, creator: Current.user)
    end
  end
end
```

### Models

- Keep domain behavior in models and POROs.
- Models expose intention-revealing APIs that controllers call directly.
- POROs live under model namespaces (`Event::Description`, `User::Filtering`).

### Decision Heuristic: Model Method → Concern → PORO

Start simple. Extract only when pain emerges.

```
1. Method on the model          → simple, local
2. Concern (shared behavior)    → same pattern in 3+ models
3. PORO under model namespace   → complex operation, presentation, or view context
4. Separate service class       → only when cross-domain orchestration is truly needed
```

**Rule of three**: Duplicate a pattern twice before abstracting. The third duplication reveals the real boundary.

### Concerns: When And How

Extract a concern when:

- The same behavior pattern appears across 3+ models or controllers.
- The behavior is cohesive — related associations, scopes, and methods together.
- The concern name describes a capability: `Closeable`, `Watchable`, `Assignable`.

Do NOT extract a concern when:

- Only 1–2 models share it (use a method or callback instead).
- The concern would be a grab-bag of unrelated functionality.
- The main goal is to reduce file size (split responsibilities instead).

```ruby
# Good — cohesive, named for capability
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
end
```

## File Organization

### Directory Layout

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── cards_controller.rb
│   └── cards/
│       ├── closures_controller.rb
│       └── comments_controller.rb
├── models/
│   ├── application_record.rb
│   ├── card.rb
│   ├── card/
│   │   ├── closeable.rb          # Concern
│   │   └── description.rb        # PORO
│   └── closure.rb                 # State record
├── jobs/
│   ├── application_job.rb
│   └── card/
│       └── notify_watchers_job.rb
└── views/
    ├── cards/
    │   ├── _container.html.erb
    │   └── closures/
    │       └── create.turbo_stream.erb
    └── components/
        ├── dashboard/
        └── shared/
```

### Controller Alignment

Map controllers to resources. Nested controllers for sub-resources:

```
CardsController                    → /cards
Cards::ClosuresController          → /cards/:card_id/closure
Cards::CommentsController          → /cards/:card_id/comments
Boards::PublicationsController     → /boards/:board_id/publication
```

### Migrations

- Keep migrations additive and reversible where practical.
- Do not reference application models in irreversible data migrations.
- Backfill data in batches for large tables.
- Add indexes for foreign keys, lookup columns, and common query patterns.

## Law of Demeter

Avoid reaching deep into model associations. Chained dot access (`@var.association.association.method`) is a sign of coupling.

### In Views

```ruby
# Bad — 3+ dot chain
@invoice.customer.address.street

# Good — delegate with prefix
class Invoice < ApplicationRecord
  belongs_to :customer
  delegate :street, :city, :zip, to: :address, prefix: true, allow_nil: true
  # Now: invoice.address_street
end
```

### In Controllers

Access finders through the association proxy, not by crossing boundaries:

```ruby
# Good — scoped through association
@memberships = @user.memberships.recently_active

# Bad — crosses association boundary
@memberships = Membership.where(user: @user, active: true).limit(5)
```

### Rules

- Do not access nested associations in views: `@var.a.b.method` is forbidden.
- Use `delegate :method, to: :association, prefix: true` to flatten access.
- Query through association proxies, not raw `where` on unrelated models.

## Avoid Parallel Names

Do not introduce parallel names for the same concept (e.g., `business` and `category`). When existing parallel names exist, update call chains instead of adding wrappers.
