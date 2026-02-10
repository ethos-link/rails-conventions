---
name: rails-conventions
description: Rails 8.x application architecture, implementation, and review guidance for production codebases. Use when building or reviewing Ruby on Rails 8 features across models, controllers, routes, Hotwire, jobs, APIs, performance, security, and testing. Trigger for requests mentioning Rails 8, Active Record, Active Job, GoodJob, Solid Queue, Turbo/Stimulus, REST resources, migrations, code quality, naming, and production readiness.
license: MIT
compatibility: Compatible with any agent runtime that supports the Agent Skills SKILL.md convention and optional references directory loading.
metadata:
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

- Baseline Rails 8 defaults and upgrade constraints: `references/01-baseline-rails-8.md`
- Naming, layering, and code organization: `references/02-naming-and-structure.md`
- Active Record, migrations, and data modeling: `references/03-models-and-data.md`
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
- Optional 37signals-inspired style profile: `references/12-37signals-inspired-profile.md`

## Output Contract

For implementation tasks, produce:

1. Required schema changes with migrations.
2. Model/controller/view/job code following local conventions.
3. Tests matching local framework.
4. Brief risk notes (security, performance, rollout concerns).

For review tasks, prioritize:

1. Correctness and behavioral regressions.
2. Security and data integrity.
3. Performance and operability.
4. Test gaps.
