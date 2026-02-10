# Hotwire Turbo Stimulus

## Progressive Enhancement

- Start with server-rendered HTML that works without JS.
- Add Turbo Frames for local partial updates.
- Add Turbo Streams for append/replace/update/remove workflows.
- Use Stimulus for focused client behavior, not SPA reimplementation.

## View Practices

- Keep partials small and composable.
- Use stable DOM ids for stream operations.
- Keep Turbo Stream templates explicit and readable.

## Interaction Patterns

- Use frame-targeted links/forms for inline edit/create flows.
- Use optimistic UI only when rollback/failure handling is defined.
- Keep keyboard/accessibility behavior intact.
