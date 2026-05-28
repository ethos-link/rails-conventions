# Active Record And PostgreSQL

Use this reference when the app uses PostgreSQL or a change touches
PostgreSQL-specific data modeling, indexes, constraints, or queries.

## Datatypes

- Use normal columns for stable, queried business attributes.
- Use `jsonb` for flexible provider payloads, metadata, and sparse data whose
  shape is not stable enough for columns.
- Promote frequently queried `jsonb` keys to real columns when they become part
  of the domain contract.
- Use arrays only when the values are small, bounded, and do not need their own
  lifecycle.
- Use PostgreSQL enums only for small, stable sets. Adding values is supported;
  removing values is not simple or reversible.

## Indexes

- Add indexes for foreign keys, lookup columns, unique business keys, and common
  ordering/filtering paths.
- Use partial indexes for scoped uniqueness or hot subsets.
- Use expression indexes only when the expression is stable and the query path
  is important.
- Use GIN indexes for queried `jsonb` or array fields.
- Use included columns when they remove real index-only query pressure.
- Check query plans for high-volume paths before and after index changes.

## Constraints

- Use `NOT NULL`, foreign keys, unique indexes, and check constraints for
  invariants that must hold under concurrency.
- Use deferrable foreign keys only when the transaction semantics require
  temporarily invalid intermediate states.
- Use exclusion constraints for non-overlap rules such as reservations,
  schedules, and time ranges.
- Pair database constraints with model validations when users need friendly
  validation errors.

## UUIDs

- Follow the app's existing primary key strategy.
- Use UUIDs for public identifiers or distributed writes only when the tradeoff
  is intentional.
- Keep internal integer IDs when they are already the local convention and there
  is no public exposure concern.

## Full Text Search And Views

- Use PostgreSQL full-text search when search quality or performance requires
  database features.
- Keep search vectors and indexes owned by the model or query object that uses
  them.
- Use database views for read models when they simplify expensive joins or
  reports. Document refresh ownership for materialized views.

## Data Safety

- Keep migrations reversible where possible.
- Split schema changes and large backfills.
- Backfill large tables in batches.
- Avoid long transactions that block writes.
- Use locks deliberately and narrowly. Prefer constraints for correctness and
  locks for coordinating contested state transitions.
