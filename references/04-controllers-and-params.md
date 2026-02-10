# Controllers And Params

## Controller Responsibilities

- Authenticate request context.
- Authorize resource/action.
- Parse and validate input.
- Delegate business work to domain layer.
- Return response in expected format.

## Params Handling

- Use strong parameters consistently.
- Prefer `params.expect(...)` in modern Rails where the app already uses it.
- Keep permit/expect declarations local and explicit.

## Response Discipline

- Use consistent status codes and redirect patterns.
- Use `unprocessable_entity` for validation failures.
- Keep response branches explicit for `html`, `turbo_stream`, and `json`.

## Shared Concerns

- Use controller concerns for reusable scoping/loading patterns.
- Keep concern APIs minimal and focused.
