# Routes REST And Resources

## CRUD Principle

Every action maps to a CRUD verb. When something does not fit, create a new resource.

```ruby
# Bad — custom actions on existing resource
resources :cards do
  post :close
  post :reopen
  post :archive
end

# Good — new resources for state changes
resources :cards do
  resource :closure      # POST to close, DELETE to reopen
  resource :goldness     # POST to gild, DELETE to ungild
  resource :not_now      # POST to postpone
  resource :pin          # POST to pin, DELETE to unpin
  resource :watch        # POST to watch, DELETE to unwatch
end
```

**Why**: Standard REST verbs map cleanly to controller actions. No guessing what HTTP method to use.

Custom routes are acceptable for non-resourceful endpoints, health checks,
provider callbacks, webhooks, protocol endpoints, and mounted Rack apps. Do not
force fake resources for infrastructure endpoints.

## Noun-Based Resources

Turn verbs into nouns:

| Action | Resource |
|--------|----------|
| Close a card | `card.closure` |
| Watch a board | `board.watching` |
| Pin an item | `item.pin` |
| Publish a board | `board.publication` |
| Assign a user | `card.assignment` |

## Singular Resources

Use `resource` (singular) for one-per-parent resources:

```ruby
resources :cards do
  resource :closure      # A card has one closure state
  resource :goldness     # A card is either golden or not
end
```

## Shallow Nesting

Use `shallow: true` to avoid deep URL nesting:

```ruby
resources :boards, shallow: true do
  resources :cards
end

# Generates:
# /boards/:board_id/cards      (index, new, create)
# /cards/:id                   (show, edit, update, destroy)
```

## Module Scoping

Group related controllers without changing URLs:

```ruby
# Using scope module — no URL prefix
resources :cards do
  scope module: :cards do
    resource :closure      # Cards::ClosuresController at /cards/:id/closure
  end
end

# Using namespace — adds URL prefix
namespace :cards do
  resources :drops         # Cards::DropsController at /cards/drops
end
```

## `resolve` For Custom URL Generation

Make `polymorphic_url` work correctly for nested resources:

```ruby
resolve "Comment" do |comment, options|
  options[:anchor] = ActionView::RecordIdentifier.dom_id(comment)
  route_for :card, comment.card, options
end
```

## Controller Mapping

Keep controllers aligned with resources:

```
app/controllers/
├── cards_controller.rb
├── cards/
│   ├── assignments_controller.rb
│   ├── closures_controller.rb
│   ├── pins_controller.rb
│   └── comments/
│       └── reactions_controller.rb
├── boards_controller.rb
└── boards/
    ├── columns_controller.rb
    ├── publications_controller.rb
    └── entropies_controller.rb
```

## Same Controller, Different Format

No separate API namespace. Use `respond_to`:

```ruby
class Cards::ClosuresController < ApplicationController
  def create
    @card.close

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```
