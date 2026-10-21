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

## Broad Changes And Repeatable Work

For a rename, sweep, or refactor, identify the behavior or contract to preserve
and a useful baseline check before changing structure. Reuse existing regression
coverage; add a focused characterization or equivalence check only for an
important uncovered contract. A formatter passing does not establish equivalence.

Complete one representative unit and verify it before expanding the change.
Process the rest in coherent batches, checking each before building on it. Batch
size follows coupling and check cost, not a mandatory test run after every file.
Search callers, string references, routes, translations, and docs where relevant.
End each delivery unit in a reviewable, usable state under the repository's Git
policy; do not introduce broken intermediate commits as a universal requirement.

Reuse generators and existing tooling first. A small codemod or rerunnable script
is useful when it lowers total implementation and verification effort. Check its
first result against the intended change and make reruns safe where needed.
Do not create a framework or script for a few straightforward edits. Keep
throwaway automation in temporary storage, remove completed one-off tools under
the cleanup policy, and retain supported reusable tools with their documented
contracts. Parallelize only genuinely independent work when delegation is
available and authorized; a deterministic tool often costs less than hand-edited
fan-out. Keep outputs scoped and inspect changed artifacts directly.

## Recurring Corrections

When the same mistake recurs, identify its concrete failure class and owning
layer before adding another agent instruction. Prefer, in order:

1. An existing native API or a single authoritative implementation that removes
   the duplicate path.
2. A database constraint, canonical schema, shared component contract, or existing
   lint rule that can reject the invalid state at its owner.
3. A focused behavior regression, or a narrowly scoped custom check when existing
   enforcement cannot express the rule and its maintenance cost is justified.
4. Prose for decisions that still require human or agent judgment.

Prove a new safeguard rejects a representative known-bad case and accepts the
valid case. For checks on a legacy codebase, avoid unrelated cleanup by applying
them to newly introduced violations where appropriate. Errors should explain the
supported alternative. Do not add broad text-matching bans to infer semantic
problems such as all possible duplicate framework APIs, dependencies solely for
rule enforcement, or blanket suppression comments. Respect repository approval
requirements for schema, security, and dependency changes.

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
