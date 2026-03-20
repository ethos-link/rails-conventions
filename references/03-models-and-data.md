# Models And Data

## Active Record Patterns

### Associations

Declare associations clearly with `dependent` behavior:

```ruby
class Card < ApplicationRecord
  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_many :comments, dependent: :destroy
  has_one :closure, dependent: :destroy
end
```

Use lambda defaults to derive context automatically:

```ruby
class Comment < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

### Validations

Keep validations minimal and focused on invariants:

```ruby
class Account < ApplicationRecord
  validates :name, presence: true
end

class Identity < ApplicationRecord
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email_address, with: ->(value) { value.strip.downcase.presence }
end
```

Use contextual validations for form objects:

```ruby
class Signup
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }, on: :identity_creation
  validates :full_name, :identity, presence: true, on: :completion
end
```

### Callbacks: Used Sparingly

Callbacks are for setup/cleanup, not business logic:

```ruby
# Good — setup callback
class MagicLink < ApplicationRecord
  before_validation :generate_code, on: :create
  before_validation :set_expiration, on: :create
end

# Good — side effect callback
class Card < ApplicationRecord
  after_create_commit :notify_watchers_later
end

# Bad — business logic in callback
class Invitation < ApplicationRecord
  after_create :process_payment_and_send_welcome_email
end
```

## State As Records Over Booleans

When state matters, create a separate record instead of a boolean column. This preserves who did it, when, and why:

```ruby
# Bad — boolean column
class Card < ApplicationRecord
  scope :closed, -> { where(closed: true) }
  scope :open, -> { where(closed: false) )
end

# Good — separate record
class Closure < ApplicationRecord
  belongs_to :card, touch: true
  belongs_to :user, optional: true
  # created_at gives you when
  # user gives you who
end

class Card < ApplicationRecord
  has_one :closure, dependent: :destroy

  scope :closed, -> { joins(:closure) }
  scope :open, -> { where.missing(:closure) }

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

### Query Patterns With State Records

```ruby
Card.open                    # where.missing(:closure)
Card.closed                  # joins(:closure)
Card.active                  # open.published.where.missing(:not_now)
Card.postponed               # open.published.joins(:not_now)
```

## POROs

POROs live under model namespaces. They are model-adjacent, not controller-adjacent.

### Presentation Logic

```ruby
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

### View Context Bundling

```ruby
class User::Filtering
  attr_reader :user, :filter

  def initialize(user, filter, expanded: false)
    @user = user
    @filter = filter
    @expanded = expanded
  end

  def boards
    user.boards.accessible
  end

  def assignees
    user.account.users.active.alphabetically
  end
end
```

### Naming

Do not use `*Service`, `*Manager`, or `*Handler` suffixes. Use domain nouns.

```ruby
# Good
class SystemCommenter
class Event::Description
class User::Filtering

# Bad
class NotificationService
class PaymentProcessor
class InvitationManager
```

## Scope Naming

Name scopes for business concepts, not SQL:

```ruby
# Good
scope :active, -> { where.missing(:pop) }
scope :unassigned, -> { where.missing(:assignments) }
scope :golden, -> { joins(:goldness) }
scope :alphabetically, -> { order(title: :asc) }
scope :recently_updated, -> { order(updated_at: :desc) }

# Bad
scope :without_pop, -> { ... }
scope :no_assignments, -> { ... }
scope :by_title_asc, -> { ... }
```

## Migration Rules

- Add indexes for foreign keys, lookup columns, and common query patterns.
- Use foreign keys for referential integrity where appropriate.
- Backfill data safely in batches for large tables.
- Keep migrations additive and reversible where practical.

### Never Reference Application Models

Migrations must not depend on application model code. If a model changes after the migration runs, the migration will break on future runs.

```ruby
# Bad — depends on User model; breaks if User changes
class AddJobsCountToUser < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :jobs_count, :integer, default: 0
    User.all.each { |u| u.update!(jobs_count: u.jobs.size) }
  end
end

# Good — pure SQL, no external dependencies
class AddJobsCountToUser < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :jobs_count, :integer, default: 0
    execute <<-SQL
      UPDATE users SET jobs_count = (
        SELECT count(*) FROM jobs WHERE jobs.user_id = users.id
      )
    SQL
  end
end
```

If a model class is needed for data migrations, define an inline class within the migration:

```ruby
class BackfillData < ActiveRecord::Migration[7.1]
  class User < ApplicationRecord
    self.table_name = "users"
  end

  def up
    User.reset_column_information
    User.find_each do |user|
      # safe to use inline class
    end
  end
end
```

## Query Safety

- Use eager loading to prevent N+1 (`includes`, `preload`, `eager_load`).
- Use parameterized query APIs; avoid interpolated SQL.
- Measure heavy queries with EXPLAIN before and after changes.

## Performance: Database Over Ruby

Do in SQL what SQL does best. Load data into Ruby only when you need object-level behavior.

```ruby
# Bad — loads ALL records into Ruby memory
Order.all.select { |o| o.total > 100 }
Order.all.map(&:total).sum
user.posts.length

# Good — database does the work
Order.where("total > ?", 100)
Order.sum(:total)
user.posts.count       # SQL COUNT
user.posts.size        # uses counter cache if available
```

Use `find_each` or `in_batches` for large collections — never iterate with `.each` on unbounded queries:

```ruby
# Bad
User.where(active: true).each { |u| u.update!(verified: true) }

# Good
User.where(active: true).find_each { |u| u.update!(verified: true) }
```

### Rules

- Use `.count` not `.length` on associations (SQL vs Ruby).
- Use `.sum(:column)` not `.map(&:field).sum`.
- Use `.where(conditions)` not `.all.select { ... }`.
- Use `find_each` not `each` for large collections.
- Use counter caches instead of manual counting.

## Write-Time Over Read-Time

Pre-compute data at write time when it reduces expensive reads:

- Use counter caches instead of manual counting.
- Pre-compute roll-ups when saving, not when presenting.
- Use `touch: true` on associations for cache invalidation chains.
