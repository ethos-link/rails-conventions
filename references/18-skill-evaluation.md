# Evaluating This Skill

Use this reference when changing guidance that is meant to alter agent behavior.
Structural validation alone checks packaging and references, not engineering
judgment. Scale behavioral checks to the changed guidance; wording-only edits
need diff review, not a new multi-agent experiment.

## Compare Observable Outcomes

Choose a small realistic task that exposes the decision being changed. Define
success criteria before running it and keep the grader's expected decisions out
of the task prompt. Give the worker an ordinary product or bug request, relevant
repo instructions, and enough runnable context; do not tell it which skill rule
or preferred solution is being evaluated.

When claiming improvement over earlier guidance, compare that revision with the
candidate using the same task, starting files, runtime, model/effort, permissions,
and tool access in separate disposable workspaces. Keep each workspace's skill
copy isolated so a baseline worker cannot read the candidate. Record these
conditions and any unavoidable differences. For a narrow confidence check,
running only the candidate is acceptable, but it cannot establish improvement.

Inspect the changed code and actual tool results: native API use, assertions,
failing/passing runs, preservation of contracts, and unnecessary new machinery.
A worker saying it complied is not evidence. If a separate reviewer is available
and authorized, show it outputs under neutral labels without identifying the
variant. Review evidence yourself and resolve disagreements against the contract;
model agreement is not a correctness oracle.

## Task Families

Select only families affected by the change. Put concrete runnable data and the
expected contract into each fixture; the descriptions below are not complete
execution prompts.

- Native API reuse: a pinned Rails app needs structured parameter validation or
  another capability already provided by the installed framework. Check actual
  implementation and discovery evidence for an unnecessary substitute.
- Final diff review: a narrow Ruby/Rails change tempts a forwarding-only
  `*Service` class or a `respond_to?` fallback around a required collaborator.
  Judge the final patch and caller contracts for redundant layers and hidden
  failures, along with preserved legitimate optional behavior. A claim to have
  run a cleanup skill is not evidence.
- Regression sensitivity: a model/PORO incorrectly totals quantities, suppresses
  an effect, or repeats a transition while a weak existing test passes. Check the
  new test against original and repaired behavior, and assess its contract.
- Failed diagnosis: provide two unsuccessful changes and their actual failing
  observations, with a shared assumption an experiment can distinguish. Check
  the next action against evidence rather than its explanation alone.
- Host integration: a passing unit test coexists with a broken route, actor
  binding, asset, or Turbo interaction. Check that verification reaches the
  affected boundary without stubbing the operation or duplicating library tests.
- Measurement: a faster comparison skips required work or reports errors. Check
  whether correctness and equivalent work are established before a speed claim.
- Repeated correction: a duplicate owner or invalid state has recurred. Check
  whether the chosen fix uses the owning API or safeguard, proves rejection, and
  avoids speculative lints or unrelated architecture changes.

Record verified, failed, unavailable, or inconclusive results with observed
behavior and limitations. One task or one successful run is a confidence check,
not evidence of a general quality or efficiency gain. Measure tool, time, or token
costs before claiming an efficiency improvement. Keep run artifacts in ignored
temporary or private storage; maintain reusable fixtures only when their ongoing
value justifies ownership. Do not commit evaluation transcripts or audit reports.
