# GoodJob Profile

Use this profile when `good_job` is the active adapter.

## Configuration Checks

- Confirm `gem "good_job"` in `Gemfile`.
- Confirm `config.active_job.queue_adapter = :good_job`.
- Confirm the worker runtime command and process topology.
- Confirm GoodJob migrations are current. For upgrades, assert
  `GoodJob.migrated?` in the test suite when the app preserves GoodJob tables.

## Operational Practices

- Keep queue health visible with GoodJob's dashboard, health checks, or app
  monitoring.
- Clean preserved job records on a documented schedule when
  `GoodJob.preserve_job_records` is enabled.
- Use GoodJob concurrency extensions only for jobs that need per-key execution
  limits. Keep the key stable and tenant-aware.
- Keep cron/recurring work version-controlled and owned by a domain job or
  model API.
- Watch Postgres connection pool pressure. GoodJob is multithreaded and shares
  database capacity with the app unless deployed separately.

## Implementation Guidance

- Keep jobs written against Active Job unless GoodJob-specific behavior is
  required.
- Keep enqueue points transaction-safe.
- Keep queue names intentional and documented.
- Treat batch APIs as orchestration tools. Keep mutable batch properties small,
  serializable, and safe if callback jobs run concurrently.
