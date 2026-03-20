# Hotwire Turbo Stimulus

## Progressive Enhancement

Start with server-rendered HTML that works without JS. Add Turbo for partial updates. Use Stimulus for focused client behavior.

## Turbo Morphing

Enable globally for smooth updates:

```ruby
# config/initializers/turbo.rb
Turbo.session.refresh_method = :morph
Turbo.session.refresh_scroll = :preserve
```

- Use `data-turbo-permanent` for elements that should not refresh.
- Ensure unique DOM IDs — duplicates break morphing.
- Set `refresh: :morph` on frames with `src` to prevent removal during morphs.

## Turbo Frames

### Lazy Loading

```erb
<%= turbo_frame_tag "notifications",
    src: notifications_path,
    loading: :lazy do %>
  <p>Loading...</p>
<% end %>
```

### Targeting Parent Frames

Use `data-turbo-frame="_parent"` to target parent frame without hardcoding IDs:

```erb
<turbo-frame id="search-results">
  <a href="/items/123" data-turbo-frame="_parent">Select Item</a>
</turbo-frame>
```

### Inline Editing

```erb
<%= turbo_frame_tag dom_id(card, :title) do %>
  <h1><%= card.title %></h1>
  <link_to "Edit", edit_card_path(card) %>
<% end %>
```

### Form State Preservation

Wrap independent sections in frames. Respond with targeted replacement instead of redirect:

```ruby
def update
  @record.update(record_params)
  render turbo_stream: turbo_stream.replace(
    [@record, :settings],
    partial: "records/settings"
  )
end
```

## Turbo Streams

### Stream Subscriptions

```erb
<%= turbo_stream_from @card %>
<%= turbo_stream_from @card, :activity %>
```

### Morphing For Complex Updates

Use `method: :morph` when replacing content containing Turbo Frames:

```ruby
render turbo_stream: turbo_stream.replace(
  [@card, :card_container],
  partial: "cards/container",
  method: :morph,
  locals: { card: @card.reload }
)
```

### Turbo Flash Helper

```ruby
# In controller concern
def turbo_stream_flash(**flash_options)
  turbo_stream.replace(:flash,
    partial: "layouts/shared/flash",
    locals: { flash: flash_options })
end

# Usage
render turbo_stream: [
  turbo_stream.append(:comments, @comment),
  turbo_stream_flash(notice: "Comment added!")
]
```

## Stimulus Best Practices

### Timer Cleanup

Always clean up intervals and timeouts in `disconnect()`:

```javascript
export default class extends Controller {
  #timer

  connect() {
    this.#timer = setInterval(() => this.refresh(), 30_000)
  }

  disconnect() {
    clearInterval(this.#timer)
  }
}
```

### Values API

Use the Values API over `getAttribute()` — cleaner and type-coerced:

```javascript
export default class extends Controller {
  static values = { url: String, delay: { type: Number, default: 300 } }
}
```

### Action Filters

Use `:self` action filter to scope events to the controller element.

### Shared Helpers

Extract common utilities to modules:

```javascript
// helpers/timing_helpers.js
export function debounce(fn, delay = 1000) {
  let timeoutId = null
  return (...args) => {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn.apply(this, args), delay)
  }
}
```

## Links Over JavaScript

Use plain `<a>` tags with `data-turbo-method: "post"` for state toggles. Better browser affordances (right-click, cmd+click) than JS-powered buttons.

```erb
<%= link_to toggle_path, data: { turbo_method: "post" } %>
```

## HTTP Caching

Use `fresh_when` and conditional GETs:

```ruby
def show
  @card = Card.find(params[:id])
  fresh_when etag: [@card, Current.user, timezone_from_cookie]
end
```

## Progressive Installation

Show interactive UI only after JS loads:

```javascript
connect() {
  this.element.classList.add("installed")
}
```

```css
.interactive-widget { visibility: hidden; }
.interactive-widget.installed { visibility: visible; }
```

## Model-Level Broadcasts

```ruby
module Card::Broadcastable
  extend ActiveSupport::Concern

  included do
    broadcasts_refreshes
  end
end
```

Always scope broadcasts by account in multi-tenant apps:

```ruby
broadcast_to [Current.account, card], target: "comments"
```
