# Background Jobs Overview

## Backend Detection

Read in this order:
1. `config.active_job.queue_adapter`
2. `Gemfile`
3. runtime/deploy worker commands

If backend is unclear, ask before implementing backend-specific behavior.

## Cross-Backend Job Design

- Keep jobs idempotent.
- Keep arguments serializable and stable.
- Keep retries intentional and bounded.
- Keep transactions and enqueue timing safe.
- Keep observability explicit (structured logs + failures).

## Backend-Specific Routing

- If adapter is `:good_job`, load `references/07a-background-jobs-good_job.md`.
- If adapter is `:solid_queue`, load `references/07b-background-jobs-solid_queue.md`.
