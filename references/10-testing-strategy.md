# Testing Strategy

## Match Existing Framework

- Use existing project framework (Minitest or RSpec).
- Match local style for fixtures/factories and helpers.

## Minimum Coverage For Feature Work

- Model/business behavior tests.
- Request/controller integration tests.
- Job enqueue/execution tests.
- System tests for critical user flows when UI changes.

## Test Quality

- Prefer deterministic data and explicit assertions.
- Avoid over-mocking core domain behavior.
- Cover failure paths, authorization edges, and invalid input.
