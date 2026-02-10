# Baseline Rails 8

Use this baseline as a starting point, then adapt to the codebase.

## Defaults to Know

- `config.load_defaults 8.0` or `8.1` changes framework defaults.
- Rails 8 generators commonly include Propshaft, Solid Cache, Solid Cable, and Solid Queue.
- Rails 8.1 continues Rails 8.0 defaults with incremental framework updates.

## Compatibility Rules

- Prefer app conventions over generated defaults when they conflict.
- Do not force adoption of new defaults during feature work.
- Isolate upgrades/migrations into explicit technical-change tasks.

## Baseline Checks

- Confirm Rails version in `Gemfile.lock`.
- Confirm `config.load_defaults` in `config/application.rb`.
- Confirm active queue adapter in environment config.
- Confirm cache store and Action Cable adapter.
