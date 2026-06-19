<p align="center">
  <strong>rails-conventions</strong>
</p>

<h1 align="center">A practical Rails skill for teams that value consistency</h1>

<p align="center">
  Build and review Rails 8 code by matching the codebase you already have,
  not by forcing generic patterns that don’t fit your app.
</p>

<p align="center">
  <a href="./SKILL.md">SKILL.md</a> ·
  <a href="./references">References</a>
</p>

---

## What this skill helps with

`rails-conventions` is for real production work in Rails codebases where consistency matters.

It guides agents to:

- inspect local patterns first (models, controllers, routes, tests, deploy setup)
- keep naming and architecture aligned with existing conventions
- write backend-aware job code (`good_job` or `solid_queue`) without assumptions
- catch risks early in security, performance, and test coverage

## Coverage

- Rails 8 baseline and compatibility constraints
- Naming, layering, and code organization
- Active Record modeling, PostgreSQL features, and migration discipline
- Controllers, params, and response semantics
- REST/resource-focused routing
- Hotwire/Turbo/Stimulus patterns
- Background jobs (adapter detection + backend-specific guidance)
- Performance and caching strategy
- Security checklist
- Testing strategy (Minitest and Minitest::Mock)
- API and serialization conventions
- Optional 37signals-inspired profile

## Validate, install, and update

Run the bundled validation script before publishing changes:

```bash
ruby scripts/validate_skill.rb
```

Install or update the skill with [`skills`](https://www.npmjs.com/package/skills):

```bash
# install from source
npx skills add git@github.com:ethos-link/rails-conventions.git --skill rails-conventions

# update an existing install
npx skills update rails-conventions
```

## Forward-test prompts

Use these prompts to check that the skill triggers correctly and loads only the
references needed for the task:

```text
Implement a new billing webhook endpoint in this Rails app, matching existing conventions and tests.
```

```text
Review this Rails 8 pull request for production readiness, focusing on naming, data integrity, security, and missing tests.
```

```text
This Rails app uses GoodJob. Add a background job for exporting account reports without changing the queue backend.
```

## References

- Agent Skills spec: <https://agentskills.io>
- Heavily inspired by: <https://github.com/marckohlbrugge/unofficial-37signals-coding-style-guide>

## License

MIT.

## About

Made by the team at [Ethos Link](https://www.ethos-link.com) — practical software for growing businesses. We build tools for hospitality operators who need clear workflows, fast onboarding, and real human support.

We also build [Reviato](https://www.reviato.com), “Capture. Interpret. Act.”.
Turn guest feedback into clear next steps for your team. Collect private appraisals, spot patterns across reviews, and act before small issues turn into public ones.
