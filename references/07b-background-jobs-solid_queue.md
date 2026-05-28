# Solid Queue Profile

Use this profile when `solid_queue` is the active adapter.

## Configuration Checks

- Confirm `gem "solid_queue"` in `Gemfile`.
- Confirm `config.active_job.queue_adapter = :solid_queue`.
- Confirm queue database configuration and `db/queue_schema.rb`.
- Confirm the worker runtime command, usually `bin/jobs`.
- Confirm `config/queue.yml` and any recurring task config are deployed.

## Operational Practices

- Rails 8 configures Solid Queue by default for new apps, but existing apps may
  use another adapter. Treat the configured adapter as authoritative.
- Keep queue database health monitored. Solid Queue uses database polling and
  row locking, so queue load competes with database capacity.
- Tune worker threads, processes, polling, and dispatchers according to database
  and CPU limits.
- Prefer exact queue names. Wildcard queue names can increase polling cost on
  large SQLite or PostgreSQL queue tables.
- Keep recurring tasks explicit and version-controlled.
- Understand enqueue errors. Solid Queue can raise adapter-specific enqueue
  errors when Active Record writes fail.

## Concurrency Controls

- Use `limits_concurrency` only when the domain needs per-key execution limits.
- Choose a stable, tenant-aware key.
- Set a duration long enough to cover expected job runtime.
- Decide whether conflicts should block or discard based on domain semantics.

## Implementation Guidance

- Keep jobs backend-agnostic unless Solid Queue-specific behavior is required.
- Keep enqueue points transaction-safe.
- Keep queue names intentional and documented.
- For small apps, running jobs beside the web process can be fine. For higher
  load, separate workers from web processes and size database connections
  intentionally.
