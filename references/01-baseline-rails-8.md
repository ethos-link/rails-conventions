# Runtime Baseline And Framework APIs

## Version Policy

- Require Ruby 4.0+ and Rails 8.1+ for new applications and upgrade targets.
- Use current stable releases, verified from the official
  [Ruby releases](https://www.ruby-lang.org/en/downloads/releases/) and
  [Rails releases](https://rubyonrails.org/category/releases) pages. Do not pin
  patch versions in skill prose or assume a newer major release is compatible.
- Existing apps execute against their pinned versions. Read runtime files,
  `Gemfile.lock`, and `config.load_defaults`; report gaps without silently
  upgrading or changing framework defaults during unrelated work.
- Verify the selected Ruby/Rails combination and dependency compatibility.
  Keep upgrades explicit, including required configuration and regression checks.

## Native APIs Before Custom Code

Apply the discovery gate in `SKILL.md` to new infrastructure and its review.
Search by the required behavior, not only the proposed helper's name. Useful
areas to inspect include:

- Ruby `Enumerable`, `Hash`, `String`, `Data`, and standard libraries before
  adding collection, normalization, value-object, or parsing utilities.
- Active Support normalization, time, instrumentation, delegation, and caching
  APIs before adding application-wide helpers.
- Active Record querying, batching, associations, atomic writes, and database
  constraints before building custom persistence machinery.
- Action Controller structured params and rate limiting before adding parsing
  or throttling layers; Action View helpers and strict locals before wrappers.
- Active Job retry, transactional enqueueing, and continuations before bespoke
  job orchestration; inspect the active adapter's guarantees too.
- Installed Turbo, Stimulus, and shared-library contracts before custom client
  lifecycle or component behavior.

This is a search map, not a requirement to use every feature or load every
library. Require a version-matched API contract and behavior appropriate to the
problem. For example, `params.expect` was introduced in Rails 8.0 and is
available throughout this skill's Rails baseline; do not add a local substitute.
See the [Rails 8.0 release notes](https://guides.rubyonrails.org/8_0_release_notes.html#action-pack-notable-changes).

## Framework Configuration

- Read `config.load_defaults`; a newer gem does not activate every newer default.
- Detect queue adapter, cache store, Action Cable adapter, and asset stack.
- Follow configured backends rather than assuming generator defaults.
- Scope the mandatory codebase scan to the task: documentation-only edits do
  not require reading unrelated application models or deployment entrypoints.
