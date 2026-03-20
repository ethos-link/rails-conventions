# 37signals Inspired Profile

Apply these patterns inspired by 37signals' approach to Rails development. Treat as guidance, not strict doctrine.

## Core Philosophy: Vanilla Rails Is Plenty

- Thin controllers calling rich domain models.
- No service objects unless truly justified; POROs under model namespaces instead.
- Direct Active Record operations in controllers are fine: `@card.comments.create!(params)`.
- When POROs exist, they are model-adjacent: `Signup.new(email:).create_identity`.

## Fix Root Causes, Not Symptoms

- Do not add retry logic for race conditions — use `enqueue_after_transaction_commit` to prevent the race.
- Do not work around CSRF on cached pages — do not HTTP cache pages with forms.
- When a call chain is incorrect, update the call chain and underlying data contracts.

## Write-Time Over Read-Time

- Pre-compute roll-ups at write time, not when presenting.
- Use counter caches instead of manual counting.
- Use `dependent: :delete_all` when callbacks are not needed.

## When To Extract (Rule of Three)

- Start in the controller; extract when it gets messy.
- Duplicate twice before abstracting.
- Filter logic progression: controller → model concern → dedicated PORO.
- Do not extract prematurely — wait for pain.

## `params.expect` Over `params.require`

Use Rails 7.1+ `params.expect` instead of `require`/`permit` chains. Returns 400 (Bad Request) instead of 500 for bad params:

```ruby
# Before
params.require(:user).permit(:name, :email)

# After
params.expect(user: [:name, :email])
```

## Naming

- Use positive names: `active` not `not_deleted`, `unpopped` not `without_pop`.
- Use domain names over technical: `depleted?` not `over_limit?`.
- Use `StringInquiry` for action predicates: `event.action.completed?` instead of `event.action == "completed"`.

## Concern Organization

- Each concern should be 50–150 lines.
- Must be cohesive — related functionality together.
- Name for the capability they provide: `Closeable`, `Watchable`, `Assignable`.
- Do not create concerns just to reduce file size.

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

## State As Records Over Booleans

Create records for state rather than boolean columns. This preserves who did it, when, and why:

```ruby
# Bad
class Card < ApplicationRecord
  scope :closed, -> { where(closed: true) }
end

# Good
class Card < ApplicationRecord
  has_one :closure, dependent: :destroy

  scope :closed, -> { joins(:closure) }
  scope :open, -> { where.missing(:closure) }

  def closed?
    closure.present?
  end
end
```

## Database Constraints Over AR Validations

Prefer database-level constraints (NOT NULL, unique indexes, check constraints) alongside or instead of application-level validations where data integrity is critical.

## Controller Patterns

- Controllers are thin orchestrators; business logic lives in models.
- Authorization: controller checks permission, model defines what permission means.
- Use controller concerns for reusable scoping (e.g., `CardScoped`, `BoardScoped`).

## Cautions

- Validate patterns against your app constraints and team practices.
- Avoid introducing churn by forcing style migrations in feature PRs.
- This profile is inspiration — do not blindly copy patterns that do not fit your domain.
