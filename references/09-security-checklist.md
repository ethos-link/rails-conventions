# Security Checklist

## Input And Output

- Validate and constrain user input.
- Use strong parameters consistently.
- Escape/sanitize output for HTML contexts.

## Authn/Authz

- Authenticate user/session context early.
- Authorize at resource/action boundaries.
- Deny by default when permission is unclear.

## Data And Infra

- Store secrets in credentials or environment, never in code.
- Use CSRF protection for browser flows.
- Enforce secure cookie/session settings in production.
- Use parameterized queries to prevent injection.

## External Integrations

- Set strict timeouts and retries for outbound requests.
- Validate webhook signatures and replay protection.
- Guard against SSRF by validating destination policies.
