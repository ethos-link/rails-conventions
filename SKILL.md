---
name: rails-conventions
description: Modern Ruby and Rails application architecture, implementation, and review guidance for production codebases. Use when building or reviewing Ruby on Rails 8 features across models, controllers, routes, Hotwire, jobs, APIs, performance, security, and testing. Trigger for requests mentioning Rails 8, Active Record, Active Job, GoodJob, Solid Queue, Turbo/Stimulus, REST resources, migrations, code quality, naming, and production readiness.
license: MIT
compatibility: Compatible with any agent runtime that supports the Agent Skills SKILL.md convention and optional references directory loading.
metadata:
  version: 1.2.0
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
3. Check existing app, Ruby, Rails, and installed gem APIs before adding custom
   code. Follow the native API discovery gate below.
4. Define the observable result and cheapest adequate check before changing
   behavior. For bugs, follow `references/17-debugging-and-verification.md`.
5. Work in small, reversible units. Verify each coherent unit before building
   on it; reuse existing generators and automation before writing a new tool.
6. Report tradeoffs explicitly when choosing architecture.
7. Verify version-sensitive APIs against official Ruby, Rails, or gem docs before
   changing guidance or introducing new APIs.
8. Create generator-owned files only by running the generator — never invent them.

Proceed with authorized, reversible work using facts discoverable from the repo
and runtime. Ask for unresolved product decisions or required approval; keep
independent work moving while those decisions are pending. Classify failed
checks before changing code, and report unavailable or inconclusive evidence
explicitly. Repository deployment and other approval boundaries remain binding.

## Runtime Baseline And Native API Discovery

Ruby 4.0 and Rails 8.1 are the minimum baseline for new applications and upgrade
work. Select current stable releases at or above that baseline from official
release pages; exclude previews, release candidates, and unreleased main-branch
APIs. Keep exact versions in the project's runtime configuration and lockfile.
Load `references/01-baseline-rails-8.md` for runtime or compatibility decisions.

For existing applications, establish the pinned Ruby, Rails, and relevant gem
versions before implementation. Use modern supported APIs available in those
versions. If below the baseline, report the gap and keep runtime upgrades a
separate explicit scope; do not silently upgrade or introduce unsupported APIs.

Before adding a helper, wrapper, concern, utility, extension, dependency, or
compatibility implementation:

1. Search the app and installed libraries for an existing owner of the behavior.
2. Check Ruby core/stdlib, Active Support, and the relevant Rails/gem APIs for
   the required behavior, including APIs introduced before the current release.
   Inspect installed source or version-matched official docs; do not rely on
   memory or unversioned documentation alone.
3. Reuse the native API directly when its contract fits. Local examples guide
   composition and formatting; they do not justify duplicating a supported API
   or copying deprecated framework patterns into new code.
4. Add custom code only for a demonstrated contract gap. Explain that gap and
   the API considered in the review handoff. Do not wrap a native call merely
   to rename it, and do not add feature-detection fallbacks for versions the
   project does not support.

During review, search for equivalent native APIs before accepting newly added
infrastructure code. Verify behavior and relevant edge cases, not just matching
method names. Newer APIs are preferred when they simplify the implementation and
preserve its contract; novelty alone is not a reason to rewrite working code.

## Non-Negotiable Rails Defaults

Rails applications should look like Rails applications. Prefer the framework's
native resource, model, controller, job, mailer, and view boundaries before
introducing extra architectural layers. Avoid architecture borrowed from other
ecosystems when Rails already has a direct convention for the problem.

Official Rails guides, official gem documentation, and established local app
conventions outrank style profiles. Follow the repository's configured formatter
and linter for layout; do not add suppression comments or change lint rules
solely to satisfy this skill's style examples. Use 37signals-inspired guidance as taste
guidance, not as authority over the current app or current Rails APIs.

Classes and modules must earn their place. Choose the fewest concepts, files,
and lines of code that keep the behavior clear. Do not add wrappers, aliases,
facades, or parallel abstractions whose main purpose is naming, indirection, or
making tests easier.

Keep one owner per behavior and one owner per definition. Prompts, schemas,
enums, constants, validation rules, normalization logic, and domain terminology
must each have a canonical home.

Identifier names must state ownership. `id` and `uuid` are owned by the local
application. `eid` means an identifier owned by another application or provider
and stored locally. Never alias a local `id` or `uuid` as `eid`. Use a qualified
name such as `place_eid`, `listing_eid`, or `review_eid` when a record can carry
identifiers from more than one external owner. A local identifier becomes an
`*_eid` only in the consuming system, never in its owning system.

Every Rails project should maintain a domain terminology document, usually
`docs/domain-terms.md`, and link it from the README or equivalent contributor
entrypoint. The document should define canonical domain terms, deprecated terms,
and naming rules for code, routes, params, APIs, persisted fields, and docs.

## Generator-Owned Files

Never hand-write files that Rails or a gem installer is supposed to generate.
Invented timestamps, installer stubs, and guessed schema dumps cause drift and
broken deploys.

Run the generator (or installer task) and then edit the result:

- Migrations: `bin/rails generate migration ...` / `bin/rails g model ...`
- Mailers, jobs, controllers, scaffolds: the matching `bin/rails g ...`
- Auth: `bin/rails generate authentication` when that is the app's path
- Queue/cache/cable installers: the gem or Rails install task
  (`solid_queue:install`, `good_job:install`, and equivalents)
- App/framework config seeds created by installers (`db/*_schema.rb`,
  `config/queue.yml`, binstubs such as `bin/jobs`) when the app does not
  already have them

After generating, adapt the file to local conventions. Do not invent migration
version numbers or timestamps. Do not recreate installer output from memory
when the installer exists. If a generator cannot be run in this environment,
say so and provide the exact command for the user — do not fabricate the file.

## Mandatory Codebase Scan

For application implementation or review, read the relevant files below first
when available. Documentation-only edits need only their affected authorities:

- runtime version files (`.tool-versions`, `.ruby-version`, or equivalent)
- `Gemfile` and `Gemfile.lock`
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
- Inbound/outbound webhooks and delivery reliability: `references/14-webhooks.md`
- Maintained documentation, Rake tasks, and one-off cleanup: `references/15-maintenance-and-documentation.md`
- Mailer composition, delivery configuration, and previews: `references/16-mailers.md`
- Bug diagnosis, repeated failed fixes, and verification boundaries: `references/17-debugging-and-verification.md`
- Evaluating changes to this skill with realistic tasks: `references/18-skill-evaluation.md`

## Task Routing

| Task | Load |
|------|------|
| Bug, regression, or repeated failed fix | `references/17-debugging-and-verification.md`, `references/10-testing-strategy.md` |
| Broad rename, sweep, or refactor | `references/15-maintenance-and-documentation.md`, `references/10-testing-strategy.md` |
| Changing this skill's behavioral guidance | `references/18-skill-evaluation.md` |
| Runtime baseline, upgrades, native API discovery | `references/01-baseline-rails-8.md` |
| Documentation, maintenance, Rake tasks, one-off repair | `references/15-maintenance-and-documentation.md` |
| Mailers | `references/16-mailers.md`, `references/10-testing-strategy.md` |
| Ruby style, naming, method order, fail-fast | `STYLE.md`, `references/13-code-quality-gates.md` |
| New model, migration, data invariant, parser | `references/03-models-and-data.md`, `references/03a-active-record-postgresql.md`, `references/10-testing-strategy.md` |
| Controller params, authz, sessions, responses | `references/04-controllers-and-params.md`, `references/09-security-checklist.md`, `references/10-testing-strategy.md` |
| Routes or custom actions | `references/05-routes-rest-and-resources.md`, `references/04-controllers-and-params.md` |
| Hotwire, Turbo, Stimulus | `references/06-hotwire-turbo-stimulus.md`, `references/10-testing-strategy.md` |
| Background jobs | `references/07-background-jobs-overview.md`, adapter-specific `07a` or `07b`, `references/10-testing-strategy.md` |
| Webhooks (inbound or outbound) | `references/14-webhooks.md`, `references/09-security-checklist.md`, `references/07-background-jobs-overview.md`, `references/10-testing-strategy.md` |
| API endpoint or serializer | `references/11-api-mode-and-serialization.md`, `references/04-controllers-and-params.md`, `references/09-security-checklist.md` |
| Performance, cache, query work | `references/08-performance-caching-and-db.md`, `references/03-models-and-data.md` |
| Architecture or object boundary | `references/02-naming-and-structure.md`, `references/12-37signals-inspired-profile.md` |

## Authentication Patterns

Existing authentication and local naming are authoritative. For greenfield Rails
applications on the runtime baseline, prefer the built-in authentication
generator. Do not rename an existing auth domain for style alone.

When implementing custom auth:

- Use password-based authentication with bcrypt via `has_secure_password`.
- Use magic link codes (not full magic link URLs) for account confirmation and email verification.
- For greenfield account-based apps, consider `Identity` (global email-based),
  `User` (per-account membership), and `Session`.
- Rate limit authentication endpoints aggressively.
- Store sessions via signed cookies with `httponly` and `same_site: :lax`.

## Output Contract

For implementation tasks, produce:

1. Required schema changes via generated migrations (see Generator-Owned Files).
2. Model/controller/view/job code following local conventions.
3. Tests matching local framework, split by responsibility (see
   `references/10-testing-strategy.md`).
4. Brief risk notes (security, performance, rollout concerns).
5. Native APIs reused, or the demonstrated gap requiring custom infrastructure;
   include version-matched source notes for version-sensitive choices.
6. Checks actually run and the behavior each proves. For bug fixes, identify the
   failing-before and passing-after evidence, or explain the reproduction gap.
   Distinguish verified, failed, unavailable, and inconclusive outcomes.

For review tasks, prioritize:

1. Correctness and behavioral regressions.
2. Security and data integrity.
3. Performance and operability.
4. Test gaps and correct ownership of coverage.
5. Naming across changed languages and boundaries; native API reuse.

Apply the evidence standard in `references/13-code-quality-gates.md`; reviewers'
agreement is a signal, not proof. Report findings with locations, reachable
execution paths, and consequences. Assess reliability,
scalability, and operational failure paths where the change creates risk. Use
explicit acceptance criteria rather than an undefined compliance percentage.
