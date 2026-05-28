# 37signals Inspired Profile

Use this profile as taste guidance, not as authority over official Rails docs
or local app conventions. If this profile conflicts with Rails guides, official
gem docs, app conventions, or explicit project instructions, follow the
stricter current rule.

## Principles

- Vanilla Rails is plenty. Prefer native Rails boundaries before new layers.
- Keep controllers thin and let models expose intention-revealing APIs.
- Model web endpoints as CRUD operations on resources.
- Fix root causes instead of adding wrappers, aliases, or compatibility layers.
- Prefer write-time ownership over repeated read-time inference.
- Extract only after real pressure. The third repetition usually reveals the
  boundary.
- Prefer state records over booleans when actor, time, reason, or history
  matters.
- Put critical invariants in the database with constraints and indexes.

## Canonical References

- Architecture, naming, concerns, POROs: `references/02-naming-and-structure.md`
- Models, state records, data handling: `references/03-models-and-data.md`
- Controller params and `params.expect`: `references/04-controllers-and-params.md`
- CRUD routing: `references/05-routes-rest-and-resources.md`
- Background jobs: `references/07-background-jobs-overview.md`
- Code quality thresholds: `references/13-code-quality-gates.md`

## Cautions

- Do not force these patterns into apps with different explicit constraints.
- Do not migrate style-only code without a user request or clear behavioral
  benefit.
- Validate version-sensitive APIs against official Rails guides before applying
  this profile.
