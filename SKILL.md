---
name: rails-conventions
description: Rails 8.x application architecture, implementation, and review guidance for production codebases. Use when building or reviewing Ruby on Rails 8 features across models, controllers, routes, Hotwire, jobs, APIs, performance, security, and testing. Trigger for requests mentioning Rails 8, Active Record, Active Job, GoodJob, Solid Queue, Turbo/Stimulus, REST resources, migrations, code quality, naming, and production readiness.
license: MIT
compatibility: Compatible with any agent runtime that supports the Agent Skills SKILL.md convention and optional references directory loading.
metadata:
  version: 1.0.0
  ethos_link.company: Ethos Link
  ethos_link.company_url: https://www.ethos-link.com
  ethos_link.product: Reviato
  ethos_link.product_url: https://www.reviato.com
  ethos_link.maintainer: ethos-link
  ethos_link.contact_url: https://www.ethos-link.com/contact/
---

# Rails Convention Engineer

Follow this workflow and load only the references needed for the task.

## Execution Workflow

1. Inspect the codebase before proposing changes.
2. Match existing conventions unless the user requests a migration.
3. Use Rails conventions and plain Ruby first.
4. Prefer small, reversible changes with tests.
5. Report tradeoffs explicitly when choosing architecture.
6. Verify version-sensitive APIs against official Rails or gem docs before
   changing guidance or introducing new APIs.

## Non-Negotiable Rails Defaults

Rails applications should look like Rails applications. Prefer the framework's
native resource, model, controller, job, mailer, and view boundaries before
introducing extra architectural layers. Avoid architecture borrowed from other
ecosystems when Rails already has a direct convention for the problem.

Official Rails guides, official gem documentation, and established local app
conventions outrank style profiles. Use 37signals-inspired guidance as taste
guidance, not as authority over the current app or current Rails APIs.

Classes and modules must earn their place. Choose the fewest concepts, files,
and lines of code that keep the behavior clear. Do not add wrappers, aliases,
facades, or parallel abstractions whose main purpose is naming, indirection, or
making tests easier.

Keep one owner per behavior and one owner per definition. Prompts, schemas,
enums, constants, validation rules, normalization logic, and domain terminology
must each have a canonical home.

Every Rails project should maintain a domain terminology document, usually
`docs/domain-terms.md`, and link it from the README or equivalent contributor
entrypoint. The document should define canonical domain terms, deprecated terms,
and naming rules for code, routes, params, APIs, persisted fields, and docs.

## Mandatory Codebase Scan

Always read these files first when available:

- `Gemfile`
- `config/application.rb`
- `config/routes.rb`
- `config/environments/*.rb` (at least current target env)
- `app/models/` (2-5 representative models)
- `app/controllers/` (2-5 representative controllers)
- `test/` or `spec/`
- process/deploy entrypoints (`Procfile*`, `bin/jobs`, `config/deploy*.yml`, CI config)

Record and follow observed patterns:

- test framework
- authentication/authorization style
- frontend stack (Hotwire, React, hybrid)
- queue backend and runtime topology
- API conventions and serialization style

## Background Job Backend Policy

Never assume Solid Queue just because the app is Rails 8.

Detect backend in this order:

1. `config.active_job.queue_adapter`
2. `Gemfile` gems (`good_job`, `solid_queue`, others)
3. worker runtime commands and deployment wiring

Apply these rules:

- If `good_job` is active, keep `good_job` conventions.
- If `solid_queue` is active, keep `solid_queue` conventions.
- If both gems exist, treat the configured adapter as authoritative.
- Do not migrate queue backend implicitly as part of unrelated tasks.
- Write backend-agnostic `ApplicationJob` code unless backend features are explicitly requested.

## Reference Routing

Load references based on the task:

- Code style, formatting, naming conventions, and fail-fast policy: `STYLE.md`
- Baseline Rails 8 defaults and upgrade constraints: `references/01-baseline-rails-8.md`
- Naming, layering, and code organization: `references/02-naming-and-structure.md`
- Active Record, migrations, and data modeling: `references/03-models-and-data.md`
- PostgreSQL-specific Active Record features: `references/03a-active-record-postgresql.md`
- Controllers, params, and request flow: `references/04-controllers-and-params.md`
- REST resources and routes: `references/05-routes-rest-and-resources.md`
- Hotwire, Turbo, and Stimulus patterns: `references/06-hotwire-turbo-stimulus.md`
- Job architecture and adapter detection: `references/07-background-jobs-overview.md`
- GoodJob-specific patterns: `references/07a-background-jobs-good_job.md`
- Solid Queue-specific patterns: `references/07b-background-jobs-solid_queue.md`
- Performance and caching strategy: `references/08-performance-caching-and-db.md`
- Security review checklist: `references/09-security-checklist.md`
- Test strategy and quality gates: `references/10-testing-strategy.md`
- API-only and mixed-mode API patterns: `references/11-api-mode-and-serialization.md`
- 37signals-inspired style profile: `references/12-37signals-inspired-profile.md`
- Code quality thresholds and detection patterns: `references/13-code-quality-gates.md`

## Task Routing

| Task | Load |
|------|------|
| Ruby style, naming, method order, fail-fast | `STYLE.md`, `references/13-code-quality-gates.md` |
| New model, migration, data invariant, parser | `references/03-models-and-data.md`, `references/03a-active-record-postgresql.md`, `references/10-testing-strategy.md` |
| Controller params, authz, sessions, responses | `references/04-controllers-and-params.md`, `references/09-security-checklist.md`, `references/10-testing-strategy.md` |
| Routes or custom actions | `references/05-routes-rest-and-resources.md`, `references/04-controllers-and-params.md` |
| Hotwire, Turbo, Stimulus | `references/06-hotwire-turbo-stimulus.md`, `references/10-testing-strategy.md` |
| Background jobs | `references/07-background-jobs-overview.md`, adapter-specific `07a` or `07b`, `references/10-testing-strategy.md` |
| API endpoint or serializer | `references/11-api-mode-and-serialization.md`, `references/04-controllers-and-params.md`, `references/09-security-checklist.md` |
| Performance, cache, query work | `references/08-performance-caching-and-db.md`, `references/03-models-and-data.md` |
| Architecture or object boundary | `references/02-naming-and-structure.md`, `references/12-37signals-inspired-profile.md` |

## Authentication Patterns

Existing authentication and local naming are authoritative. For greenfield Rails
8.1 applications, prefer the built-in authentication generator. Do not rename an
existing auth domain for style alone.

When implementing custom auth:

- Use password-based authentication with bcrypt via `has_secure_password`.
- Use magic link codes (not full magic link URLs) for account confirmation and email verification.
- For greenfield account-based apps, consider `Identity` (global email-based),
  `User` (per-account membership), and `Session`.
- Rate limit authentication endpoints aggressively.
- Store sessions via signed cookies with `httponly` and `same_site: :lax`.

## Output Contract

For implementation tasks, produce:

1. Required schema changes with migrations.
2. Model/controller/view/job code following local conventions.
3. Tests matching local framework.
4. Brief risk notes (security, performance, rollout concerns).
5. Source notes for version-sensitive APIs when current docs were checked.

For review tasks, prioritize:

1. Correctness and behavioral regressions.
2. Security and data integrity.
3. Performance and operability.
4. Test gaps.
