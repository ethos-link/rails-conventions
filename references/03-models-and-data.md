# Models And Data

## Active Record Patterns

- Declare associations clearly with `dependent` behavior.
- Add validations for invariants that belong in app logic.
- Add DB constraints and indexes for integrity and performance.
- Prefer scopes for query composition with business semantics.

## Migration Rules

- Add indexes for lookup and join columns.
- Use foreign keys for referential integrity.
- Backfill data safely for large tables (batch updates).
- Avoid referencing app models in irreversible data migrations when future compatibility is at risk.

## Data Modeling

- Consider "state as records" when historical metadata matters.
- Use enum/state representations that preserve readability.
- Use write-time computations when they reduce expensive read paths.

## Query Safety

- Use eager loading to prevent N+1 (`includes`, `preload`, `eager_load`).
- Use parameterized query APIs; avoid interpolated SQL.
- Measure heavy queries with logs/EXPLAIN before and after changes.
