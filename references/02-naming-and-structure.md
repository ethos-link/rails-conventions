# Naming And Structure

## Naming

- Use domain language (`Closure`, `Publication`, `Membership`) over technical names.
- Prefer positive predicates (`active?`) over negative (`not_deleted?`).
- Keep method names explicit; avoid hidden behavior.

## Layering

- Keep controllers thin and orchestration-focused.
- Keep domain behavior in models and POROs.
- Extract concerns for shared, cohesive behavior.
- Extract service objects only when complexity justifies them.

## File Organization

- Keep resource-aligned controllers and routes.
- Group reusable logic under `app/models/concerns/` and `app/controllers/concerns/`.
- Keep migrations additive and reversible where practical.

## Decision Heuristic

- Prefer direct code first.
- Abstract after repeated duplication with clear boundaries.
- Avoid indirection that hides business rules.
