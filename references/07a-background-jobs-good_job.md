# GoodJob Profile

Use this profile when `good_job` is the active adapter.

## Configuration Checks

- Confirm `gem "good_job"` in `Gemfile`.
- Confirm `config.active_job.queue_adapter = :good_job`.
- Confirm worker process command and environment config.

## Operational Practices

- Use GoodJob concurrency controls when needed.
- Use cron/scheduler only when operations team expects it.
- Track retries and discarded jobs with clear logging.
- Protect high-value queues with explicit prioritization.

## Implementation Guidance

- Keep jobs backend-agnostic unless feature needs GoodJob-specific APIs.
- Isolate backend-specific behavior behind configuration/adapter checks.
- Add tests for enqueue behavior and retry/discard paths.
