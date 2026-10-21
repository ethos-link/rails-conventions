# Code Quality Gates

Use these thresholds as review signals, not mechanical extraction rules. Apply
them during code review and as a self-check before finalizing changes.

## Class Size

| Metric | Review signal | Response |
|--------|-------|---------------------|
| Lines | Review above 200 | Check cohesion; extract only a stable responsibility |
| Public methods | Review above 15 | Check whether the public API mixes responsibilities |
| Private methods | Review above 7 | Simplify first; extract only when the new object has a stable responsibility |
| Responsibilities | 1 | If you cannot describe the class in one sentence, it has too many responsibilities |

## Method Size

| Metric | Review signal | Response |
|--------|-------|---------------------|
| Lines | Review above 20 | Simplify; extract only when a named method clarifies behavior |
| Nesting levels | Review above 2 | Simplify branches or name cohesive inner logic |
| Abstraction levels | 1 | Do not mix high-level orchestration with low-level details in the same method |

```ruby
# Bad: the containing object repeats each article's publication workflow.
def publish
  if approved?
    articles.each do |article|
      if article.ready?
        article.update!(published_at: Time.current)
        article.announce_later
      end
    end
  end
end

# Good: scope selects the records; each article owns its publication contract.
def publish
  if approved?
    articles.ready.find_each(&:publish)
  end
end
```

This example assumes the existing `Article#publish` owns the state transition
and announcement. Move the behavior there only when that ownership is justified;
do not create a forwarding method merely to shorten the containing method.

## Parameter Count

| Metric | Review signal | Response |
|--------|-------|---------------------|
| Positional arguments | Review above 2 | Prefer keywords or an existing domain object |

```ruby
# Bad — too many positional args
def completion_notification(first_name, last_name, email, phone, company)
  # ...
end

# Good — keyword args with defaults
def completion_notification(email:, first_name:, last_name: nil, phone: nil, company: nil)
  # ...
end

# Also good — existing domain object
def completion_notification(notification)
  # ...
end
```

Keyword arguments improve call-site clarity but do not remove overall API
complexity; review large keyword lists too. Prefer keyword arguments for Ruby
APIs. Pass an existing domain object when one already owns the data. Create a value object only when it has behavior,
validation, or a stable domain name; do not create DTOs merely to group
arguments.

## Concern Size

| Metric | Review signal | Response |
|--------|-------|---------------------|
| Lines | Review above 150 | Check capability cohesion; do not split merely by size |
| Responsibility | 1 capability | If the concern mixes unrelated behavior, split it |

## Detection Quick Reference

Use these patterns to find review candidates; confirm context before reporting
a violation. Size and argument-count matches are signals, not failures:

| Candidate | Search Pattern | Files |
|-----------|---------------|-------|
| Large class | `wc -l` > 200 | `app/models/`, `app/controllers/` |
| Long method | Methods > 20 lines | `app/models/`, `app/controllers/` |
| Too many params | `def ... (a, b, c, d, ...)` | `app/` |
| Query in controller | `.where`, `.order`, `.joins` chains | `app/controllers/` |
| Query in view | `<% Model.find`, `<% Model.where` | `app/views/` |
| Session objects | `session[.*] = @` (non-scalar) | `app/controllers/` |
| 3+ dot chains | `@\w+\.\w+\.\w+\.` | `app/views/`, `app/controllers/` |
| Bare rescue | `rescue\s*$`, `rescue nil` | `app/` |
| SQL in Ruby | `.all.select`, `.all.map`, `.all.reject` | `app/models/`, `app/controllers/` |
| Silent failure | `\.save\b` (without `!`) in jobs | `app/jobs/`, domain POROs |
| Unnecessary layer | `class .*Service`, methods that only forward a call | Changed Ruby files and their callers |
| Hidden contract error | `respond_to?`, `.try`, `&.`, `allow_nil`, broad `rescue` | Changed Ruby files; trace optionality and error handling |
| Narrating comment | Read comments beside the operation they describe | Changed code and tests |
| Parallel domain terms | Compare new names with the domain terminology document | Changed params, models, serializers, and tests |
| Invented generated file | Inspect added files and the actual generator invocation | New migrations, installers, controllers, jobs, mailers |
| Obsolete compatibility | Version branches, aliases, or old entry points with no supported callers | Changed internal APIs; preserve rollout/public contracts |

## Self-Check Before Finalizing

Run through this checklist before completing any implementation task:

1. Classes own cohesive responsibilities; review large classes and wide APIs.
2. Methods read clearly; review long methods without mechanical extraction.
3. No query logic in controllers or views.
4. Bang methods used in jobs and orchestration code.
5. No 3+ dot chains in views.
6. No bare `rescue` or `rescue nil`.
7. Migrations do not reference application models.
8. External HTTP calls have explicit timeouts.
9. Necessary tests ship with the changed behavior at its owning layer.
10. No runtime debug prints or breakpoints are committed.
11. New names follow `STYLE.md` across code, params, translations, and storage.
12. Native API discovery is complete for new infrastructure (see `SKILL.md`).
13. The final task diff has passed `SKILL.md`'s Final Diff Review against `STYLE.md`;
    any legitimate exception is explained by a concrete supported contract.

## Evidence Standard For Review

For a correctness or security finding, show a reachable input or state, the
relevant caller-to-failure path, and its observable consequence. Inspect callers,
constraints, and installed library contracts beyond the diff before recommending
new guards, retries, wrappers, or abstractions. If reachability cannot be
established, label the concern as a hypothesis rather than a demonstrated bug.

Separate required fixes from optional design suggestions and dismiss incorrect
findings with a concrete reason. Agreement between reviewers or bots does not
replace tracing the path; a single demonstrated security failure remains
important. Do not churn working code solely because a reviewer prefers another
shape. Evaluate maintainability findings against a concrete ownership, reader,
or change-cost problem, not just a threshold or missing abstraction.

For repeated agent mistakes, use the structural-correction guidance in
`references/15-maintenance-and-documentation.md` before adding another rule.

## Local Verification

Run the smallest existing checks that cover the change. Documentation-only
changes require diff review and `git diff --check`, not application tests. For
broad changes or merge preparation, run the repository's required full gate.
Do not invent universal lint/build commands; discover the project's tooling.
Report actual checks and limitations without claiming an undefined compliance
percentage. Commit-message requirements belong to the repository's Git policy.

Before extracting, ask whether the new object has a stable name, responsibility,
and public API. If extraction only hides complexity, simplify the original code
first.
