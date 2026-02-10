# API Mode And Serialization

## API Surface

- Keep contracts explicit and stable.
- Version APIs when compatibility risk exists.
- Use consistent error envelopes and status codes.

## Serialization

- Use project-standard serialization approach.
- Keep payloads minimal and documented.
- Avoid leaking internal-only fields.

## Controller Behavior

- Keep API controllers focused on transport concerns.
- Delegate domain operations to model/PORO layer.
- Ensure authn/authz and rate limits are enforced.
