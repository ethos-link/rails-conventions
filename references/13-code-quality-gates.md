# Code Quality Gates

Use these thresholds to keep generated code within healthy bounds. Apply during code review and as a self-check before finalizing changes.

## Class Size

| Metric | Limit | Action When Exceeded |
|--------|-------|---------------------|
| Lines | < 200 | Extract concerns, POROs, or sub-classes |
| Public methods | < 15 | Split responsibilities into separate classes |
| Private methods | < 7 | Extract private logic into a PORO |
| Responsibilities | 1 | If you cannot describe the class in one sentence, it has too many responsibilities |

## Method Size

| Metric | Limit | Action When Exceeded |
|--------|-------|---------------------|
| Lines | < 10 preferred, < 20 hard limit | Extract method |
| Nesting levels | < 2 | Extract inner logic into named methods |
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
  return unless valid?
  active_items.each { |item| process_item(item) }
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

| Metric | Limit | Action When Exceeded |
|--------|-------|---------------------|
| Method arguments | < 3 | Extract parameter object or use keyword arguments with defaults |

```ruby
# Bad — too many positional args
def completion_notification(first_name, last_name, email, phone, company)
  # ...
end

# Good — keyword args with defaults
def completion_notification(email:, first_name:, last_name: nil, phone: nil, company: nil)
  # ...
end

# Also good — parameter object
def completion_notification(notification_params)
  # ...
end
```

## Concern Size

| Metric | Limit | Action When Exceeded |
|--------|-------|---------------------|
| Lines | 50–150 | Split into more focused concerns |
| Responsibility | 1 capability | If the concern mixes unrelated behavior, split it |

## Detection Quick Reference

Use these patterns to identify violations in existing code:

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

1. Class sizes within limits (< 200 lines, < 15 public methods).
2. Method sizes within limits (< 10 lines preferred).
3. No query logic in controllers or views.
4. Bang methods used in jobs and services.
5. No 3+ dot chains in views.
6. No bare `rescue` or `rescue nil`.
7. Migrations do not reference application models.
8. External HTTP calls have explicit timeouts.
9. Tests ship with the feature.
