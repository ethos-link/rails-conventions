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
- Active Record modeling and migration discipline
- Controllers, params, and response semantics
- REST/resource-focused routing
- Hotwire/Turbo/Stimulus patterns
- Background jobs (adapter detection + backend-specific guidance)
- Performance and caching strategy
- Security checklist
- Testing strategy (Minitest/RSpec alignment)
- API and serialization conventions
- Optional 37signals-inspired profile

## Validate and package

This skill relies on [`agent_skills`](https://github.com/rubyonai/agent_skills) for standard validation and packaging.

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

## Notes

- Runtime-agnostic by design: any agent runtime that supports `SKILL.md`-based skills can use it.
- Metadata for Ethos Link and Reviato is stored in `SKILL.md` frontmatter via optional spec fields.
- Keep it file-based in Git so teams can review and adapt it easily.

## References

- Agent Skills spec: <https://agentskills.io>
- `agent_skills` CLI: <https://github.com/rubyonai/agent_skills>
- Heavily inspired by: <https://github.com/marckohlbrugge/unofficial-37signals-coding-style-guide>

## License

MIT.

## About

Made by the team at [Ethos Link](https://www.ethos-link.com) — practical software for growing businesses. We build tools for hospitality and retail teams who don’t have time for complicated setups: plain-language insights, fast onboarding, and real human support so you can get clear insights, take action, and move on.

We also build [Reviato](https://www.reviato.com), “More stars. Less hassle.”.
Reviato helps restaurants, hotels, clinics, vets and other local businesses collect and analyse customer reviews, highlights recurring themes, and turns feedback into actionable next steps.
