# Webhooks

Use this reference for inbound and outbound webhook work. Match existing app
patterns first. Load `references/09-security-checklist.md` for SSRF, signing,
and authz baselines.

## Inbound Webhooks

- Verify signatures before trusting the payload (provider `construct_event`
  style or HMAC + timestamp).
- After verification, re-fetch canonical state from the provider API when
  ordering or partial payloads are unreliable. Do not treat the webhook body as
  the sole source of truth for money, entitlements, or identity changes.
- Make handlers idempotent. Persist a delivery/event key and ignore duplicates.
- Keep controllers thin: verify, enqueue or call a model/PORO, return quickly.
- Scope records to the correct tenant/account after resolving the provider
  identity. Never look up by naked external ID across tenants.

## Outbound Delivery (Outbox)

Prefer persist-then-deliver over fire-and-forget:

1. Domain event enqueues one dispatch job.
2. Dispatch fans out into one persisted `Delivery` (or equivalent) row per
   destination webhook.
3. Each delivery enqueues its own send after commit.
4. Record request metadata and a capped response body for audit.

Use a dedicated `webhooks` queue so slow destinations cannot starve default
work.

### Failure Classification

Treat destination failures and application bugs differently:

- **Expected destination failures** (timeout, TLS, DNS, connection refused,
  HTTP 4xx/5xx): mark the delivery completed/failed with a symbolic error.
  Do not retry the job as if the worker crashed.
- **Unexpected exceptions** (our bug): mark errored and re-raise so Active Job
  retries.

This keeps dashboards, retries, and delinquency tracking honest.

### Delinquency Circuit Breaker

- Track consecutive failures and first-failure time per webhook.
- Auto-deactivate after N failures across a minimum window.
- Reset on success.
- Expose reactivation as an explicit admin action (`resource :activation` or
  local equivalent).

### Fan-Out Safety

For large destination sets, use crash-safe iteration (`ActiveJob::Continuable`
or an equivalent cursor) so a mid-batch crash resumes instead of restarting.
See `references/07-background-jobs-overview.md`.

## Security Baseline

- Treat destination URLs as untrusted input. Apply full SSRF protections from
  `references/09-security-checklist.md`, including redirect re-validation and
  response size caps.
- Re-validate the destination at send time, not only at create time.
- Prefer immutable destination URLs after create; retargeting issues a new
  secret.
- Sign outbound payloads (HMAC signature + timestamp headers).
- Whitelist subscribable events at the model layer.
- Require admin-level authorization for webhook management endpoints.

## Tenant Safety

- Keep webhook records and delivery queries tenant-scoped.
- Ensure event fan-out cannot leak cross-tenant payloads or URLs.
- When rendering links inside payloads, use tenant-correct URL options
  (`script_name` / account prefix) matching the app's tenancy scheme.

## Operational Hygiene

- Cap stored response bodies.
- Recurring cleanup of old delivery rows by retention policy.
- Surface delivery history in admin UI when the product needs it.
- Isolate webhook work on its own queue.

## Red Flags

- Fire-and-forget HTTP with no persisted delivery trail.
- Retrying destination failures the same way as code errors.
- Mutable destination URLs without rotating secrets.
- No circuit breaker against dead endpoints.
- Unbounded reads of destination responses.
- Missing tenant scoping on create, fan-out, or lookup.
- Hand-written migration/installer files for webhook tables — generate them.
