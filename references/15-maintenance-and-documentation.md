# Maintenance And Documentation

## Maintained Documentation

Document current behavior, supported commands, contracts, and active work.
Keep change rationale in commit messages according to the repository's Git
policy; report completed verification in the review handoff or PR. Do not
commit execution journals, incident completion reports, production run IDs,
before/after database exports, ephemeral paths, or standalone audit results.
Keep operational artifacts in ignored temporary or private storage.

Plans describe remaining work and acceptance criteria. Remove completed plans
and fold lasting instructions into maintained feature documentation. Preserve
required changelogs, upgrade notes, and supported contract specifications.

## Rake Tasks And One-Off Repairs

Keep Rake tasks as thin orchestration over the domain or infrastructure owner.
Put temporary operational tasks under `oneoff` (for example
`oneoff:accounts:cleanup`) so cleanup candidates are visible in task listings.
Keep long-running repairs outside deployment migrations. Follow existing
operational safety and authorization boundaries; these conventions do not
authorize executing repairs or deploying.

When a one-off repair is complete, remove its task, implementation, dedicated
tests, incident inventory, packaging exceptions, and executable instructions
together. Preserve reusable recovery operations and permanent safeguards.
Update callers, links, and upgrade instructions in the same cleanup. Do not
replace deleted historical reports with cleanup or retirement reports.
