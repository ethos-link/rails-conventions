# Performance Caching And DB

## Query Performance

- Eliminate N+1 queries with `includes`, `preload`, or explicit joins based on
  the query shape.
- Add or refine indexes for real query paths.
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
