# Controllers And Params

## Controller Responsibilities

Controllers are thin orchestrators. Each action:

1. Authenticates request context.
2. Authorizes resource/action.
3. Parses and validates input.
4. Delegates business work to domain layer.
5. Returns response in expected format.

```ruby
# Good — thin controller, model does the work
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.reopen

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

## Params Handling

Use `params.expect` (Rails 7.1+) over `params.require`/`permit` chains. Returns 400 instead of 500 for bad params:

```ruby
# Before
params.require(:user).permit(:name, :email)

# After
params.expect(user: [:name, :email])
```

Keep permit/expect declarations local and explicit.

## Authorization Pattern

Controller checks permission; model defines what permission means:

```ruby
# Controller
class CardsController < ApplicationController
  before_action :ensure_permission_to_administer_card, only: [:destroy]

  private
    def ensure_permission_to_administer_card
      head :forbidden unless Current.user.can_administer_card?(@card)
    end
end

# Model
class User < ApplicationRecord
  def can_administer_card?(card)
    admin? || card.creator == self
  end

  def can_administer_board?(board)
    admin? || board.creator == self
  end
end
```

## Controller Concerns

Use controller concerns for reusable scoping and loading patterns.

### Resource Scoping

```ruby
# app/controllers/concerns/card_scoped.rb
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        [@card, :card_container],
        partial: "cards/container",
        method: :morph,
        locals: { card: @card.reload }
      )
    end
end

# Usage
class Cards::ClosuresController < ApplicationController
  include CardScoped
  # gets @card, @board, render_card_replacement
end

class Cards::PinsController < ApplicationController
  include CardScoped
  # same concern, different sub-resource
end
```

### Request Context

Populate `Current` with request data via a concern:

```ruby
module CurrentRequest
  extend ActiveSupport::Concern

  included do
    before_action do
      Current.http_method = request.method
      Current.request_id  = request.uuid
      Current.user_agent  = request.user_agent
      Current.ip_address  = request.ip
      Current.referrer    = request.referrer
    end
  end
end
```

### Turbo Flash

```ruby
module TurboFlash
  extend ActiveSupport::Concern

  included do
    helper_method :turbo_stream_flash
  end

  private
    def turbo_stream_flash(**flash_options)
      turbo_stream.replace(:flash,
        partial: "layouts/shared/flash",
        locals: { flash: flash_options })
    end
end
```

Usage:

```ruby
def create
  @comment = @card.comments.create!(comment_params)

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.append(:comments, @comment),
        turbo_stream_flash(notice: "Comment added!")
      ]
    end
  end
end
```

## Response Discipline

- Use consistent status codes: `201 Created` for create, `204 No Content` for update/delete.
- Use `unprocessable_entity` for validation failures.
- Keep response branches explicit for `html`, `turbo_stream`, and `json`.
- Prefer `turbo_stream.replace` with `method: :morph` over redirects for in-place updates.

```ruby
def create
  @comment = @card.comments.create!(comment_params)

  respond_to do |format|
    format.turbo_stream
    format.json { head :created, location: card_comment_path(@card, @comment) }
  end
end
```

## Controller Discipline

### No Query Logic In Controllers

Controllers must not contain `.where`, `.order`, `.joins`, or `.group` chains. Use scopes on models instead:

```ruby
# Bad — query logic in controller
class PostsController < ApplicationController
  def index
    @posts = Post.where(published: true).order(created_at: :desc)
  end
end

# Good — composable scopes
class Post < ApplicationRecord
  scope :published, -> { where(published: true) }
  scope :newest_first, -> { order(created_at: :desc) }
end

class PostsController < ApplicationController
  def index
    @posts = Post.published.newest_first
  end
end
```

### No Query Logic In Views

Views must not contain queries (`Model.find`, `Model.where`). Set all data in the controller:

```erb
<%# Bad %>
<% User.where(active: true).each do |user| %>

<%# Good — controller sets @active_users %>
<% @active_users.each do |user| %>
```

### Store Only Scalar IDs In Sessions

Never store full ActiveRecord objects or collections in the session. Store only the reference:

```ruby
# Bad — stale data, serialization issues
session[:user] = User.find(params[:id])
session[:cart] = @cart_items

# Good — store the ID
session[:user_id] = params[:id]

def current_user
  @current_user ||= User.find_by(id: session[:user_id])
end
```

## Rate Limiting

Use Rails built-in rate limiting for auth and sensitive endpoints:

```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Try again later." }
end
```
