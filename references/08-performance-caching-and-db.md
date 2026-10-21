# Performance Caching And DB

## Query Performance

- Eliminate N+1 queries with `includes`, `preload`, or explicit joins based on
  the query shape.
- Require a measured slow query before adding a performance index. Record the
  query shape, representative timing, and plan; verify the result after indexing.
  Unique indexes required for data integrity are exempt. A foreign key alone
  does not justify an unmeasured performance index on its referencing columns.
- Use relation composition over ad hoc SQL when possible.
- Use explicit SQL only when measured performance or database features require
  it.
- Use SQL aggregation (`count`, `sum`, `minimum`, `maximum`) instead of loading
  collections into Ruby.
- Use `find_each` or `in_batches` for large collections.
- Avoid unbounded lists in controllers, APIs, and views. Paginate or cap result
  sets.
- Check query plans for risky indexes, joins, reports, and high-volume paths.

## Caching

- Give each cached value one owner and one invalidation path.
- Prefer Rails cache keys and `touch: true` association chains for fragment
  invalidation.
- Do not memoize Active Record relations across request, tenant, or user
  boundaries.
- Cache derived/read-model data only when its source of truth and invalidation
  path are explicit.
- Do not HTTP-cache pages that contain CSRF-protected forms.

## Data Over Ruby

Do in SQL what SQL does best: filtering, joining, grouping, ordering, and
aggregating. Load records into Ruby when object behavior, callbacks, or view
presentation requires objects.

## Measurement

- Prefer a measured fix over speculative indexing or caching.
- For user-facing slow paths, capture before/after query counts, response time,
  or job runtime.
- Do not add caching to hide missing indexes, N+1 queries, or inefficient data
  ownership.

Before acting on a speedup, read the measurement path and confirm the intended
work happens inside the measured interval. Verify correct outputs and count
failures, retries, and non-success responses; skipped work and fast rejections
are not performance improvements.

Compare representative data, Ruby/Rails versions, runtime configuration, worker
and connection limits, and equivalent warm/cold cache conditions. Observe
competing machine load. Profile separately from reported timing when profiling
affects the measurement, and identify the bottleneck the proposed change targets.

For a decision between alternatives, repeat and interleave before/after runs
when practical. Report units, sample count, variability, conditions, and the
relevant end-to-end effect. A quick single-run estimate may be useful when labeled
as such; do not turn it into a reliable ranking or a production-capacity claim.
If noise obscures the difference, a side did not perform equivalent work, or the
observation cannot explain the claimed gain, report the comparison as inconclusive.
Stop when the measured goal is met; do not add speculative optimization layers.
