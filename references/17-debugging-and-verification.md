# Debugging And Verification

## Diagnose Before Patching

1. State the intended result, observed failure, and smallest useful reproduction.
   Use the affected entry point when the fault depends on routing, assets, Turbo,
   queueing, authorization, or library composition. A model test alone cannot
   establish that a broken host workflow is repaired.
2. Trace the first incorrect decision or state transition. Inspect relevant
   callers, persisted state, logs, and installed library behavior. Use temporary
   instrumentation when needed; remove debug output before handoff. Distinguish
   a legitimate state that needs handling from an invalid state produced earlier.
3. State a hypothesis and an observation that could disprove it. Make the smallest
   change supported by that observation, then rerun the relevant check. Remove
   changes motivated by rejected hypotheses without discarding unrelated work.
4. Follow the regression-proof guidance in `references/10-testing-strategy.md`.
   Verify the original failure at the cheapest adequate layer and recheck the
   affected integration boundary when that boundary contributed to the defect.

If two attempted fixes based on the same assumption fail the same check, stop
patching. Write the shared assumption in temporary notes, identify a measurement
or reproduction that distinguishes it from an alternative, and test it before
another fix. Do not increase sleeps, retries, timeouts, or nil guards merely to
hide the original symptom. A justified resilience policy needs its own contract.

A production-only failure may not reproduce locally. Report what was attempted,
what evidence is missing, and which behavior remains unverified. Do not weaken
assertions or claim a repair solely because a nearby test passes.

## Verify The Relevant Boundary

Use the real installed library at the boundary being proved; control external
providers through existing test adapters, WebMock, or VCR. Assert the observable
result and essential side effects. Avoid internal setters, test-only endpoints,
or stubbing the library operation to bypass the workflow.

For host-level changes, exercise one representative affected workflow through
its real entry point. Reuse existing tests or local verification instructions.
A request, job, or model integration test is sufficient when it proves the
boundary; use a browser when browser behavior is the risk. Keep launch, seed,
authentication, and feature-specific recipes in the consuming repository. Do not
introduce another browser matrix or require live external services.

Before driving a running app, confirm the instance, relevant version, readiness,
and prerequisites. After a surprising failure, diagnose or reset run-owned state
before repeating the drive. Clean up only processes and scratch state the run
created; preserve evidence in ignored temporary or private storage.

Classify the result before choosing the next action:

- Product failure: the intended path ran and violated its contract. Fix its owner.
- Harness failure: the driver or observation was wrong. Repair the check and rerun;
  do not change correct product behavior to satisfy it.
- Unavailable prerequisite: credentials, seed state, service, or permission is
  missing. Report the blocked path and continue independent authorized work.
- Inconclusive: the observation cannot establish the result. Improve the check;
  an inconclusive result is not a pass.

Report successful evidence as verified only for the behavior actually exercised.
None of these steps authorize deployments, new dependencies, data mutations, or
other actions outside the task's existing permissions.
