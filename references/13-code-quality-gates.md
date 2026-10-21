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
# Bad — 3 nesting levels, mixed abstractions
def process
  if valid?
    items.each do |item|
      if item.active?
        item.update!(status: :processed)
        ExternalService.notify(item)
      end
    end
  end
end

# Good — extracted, single abstraction per method
def process
  if valid?
    active_items.each { |item| process_item(item) }
  end
end

private

def active_items
  items.select(&:active?)
end

def process_item(item)
  item.update!(status: :processed)
  ExternalService.notify(item)
end
```

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

| Violation | Search Pattern | Files |
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
| Silent failure | `\.save\b` (without `!`) in jobs | `app/jobs/`, `app/services/` |

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
