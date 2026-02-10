# Performance Caching And DB

## Query Performance

- Eliminate N+1 queries.
- Add or refine indexes for real query paths.
- Use relation composition over ad hoc SQL when possible.
- Use explicit SQL only when measured performance requires it.

## Caching Strategy

- Apply caching at the right layer: HTTP, fragment, computed data.
- Keep cache keys and invalidation rules explicit.
- Avoid user-specific cache leaks.

## Background Throughput

- Offload expensive operations to jobs.
- Bound batch sizes and memory usage.
- Measure queue latency and failure rates.

## Deployment Considerations

- Tune Puma and DB pools together.
- Verify production-like performance before broad rollout.
