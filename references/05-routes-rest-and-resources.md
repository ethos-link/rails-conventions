# Routes REST And Resources

## Routing Model

- Prefer resourceful routes and REST verbs.
- Create sub-resources for actions that represent state transitions.
- Keep URL structures stable and predictable.

## Patterns

- Use singular `resource` for one-per-parent state.
- Use nested resources where ownership/context is required.
- Use shallow nesting to avoid deep route complexity.

## Controller Mapping

- Map controllers to resources directly.
- Keep namespaces aligned with bounded context.
- Avoid action-heavy controllers that break resource boundaries.
