# Solid Queue Profile

Use this profile when `solid_queue` is the active adapter.

## Configuration Checks

- Confirm `gem "solid_queue"` in `Gemfile`.
- Confirm `config.active_job.queue_adapter = :solid_queue`.
- Confirm queue DB setup and worker runtime process.

## Operational Practices

- Keep queue database health monitored.
- Tune worker/thread settings according to DB and CPU limits.
- Keep recurring tasks explicit and version-controlled.

## Implementation Guidance

- Keep jobs backend-agnostic unless Solid Queue-specific behavior is required.
- Keep enqueue points transaction-safe.
- Keep queue names intentional and documented.
