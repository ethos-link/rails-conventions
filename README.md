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

## Validate and package

Run the bundled validation script first:

```bash
ruby scripts/validate_skill.rb
```

You can use [`agent_skills`](https://github.com/rubyonai/agent_skills) for standard validation and packaging.

```bash
# install CLI
gem install agent_skills

# validate
agent-skills validate ./skills/rails-conventions

# package
agent-skills pack ./skills/rails-conventions

# inspect metadata
agent-skills info ./skills/rails-conventions
```

## Example trigger

Use this skill when a request sounds like:

```text
Implement a new billing webhook endpoint in this Rails app, matching existing conventions and tests.
```

## References

- Agent Skills spec: <https://agentskills.io>
- `agent_skills` CLI: <https://github.com/rubyonai/agent_skills>
- Heavily inspired by: <https://github.com/marckohlbrugge/unofficial-37signals-coding-style-guide>

## License

MIT.

## About

Made by the team at [Ethos Link](https://www.ethos-link.com) — practical software for growing businesses. We build tools for hospitality operators who need clear workflows, fast onboarding, and real human support.

We also build [Reviato](https://www.reviato.com), “Capture. Interpret. Act.”.
Turn guest feedback into clear next steps for your team. Collect private appraisals, spot patterns across reviews, and act before small issues turn into public ones.
