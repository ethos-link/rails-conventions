# Background Jobs Overview

## Backend Detection

Read in this order:

1. `config.active_job.queue_adapter`
2. `Gemfile` gems (`good_job`, `solid_queue`, others)
3. runtime/deploy worker commands

If backend is unclear, ask before implementing backend-specific behavior. Do not migrate queue backend implicitly.

## Cross-Backend Job Design

- Keep jobs idempotent.
- Keep arguments serializable and stable.
- Prefer stable scalar IDs when deleted records, tenant boundaries, or retries
  make GlobalID deserialization risky.
- Keep retries intentional and bounded.
- Keep transactions and enqueue timing safe.
- A retry must not duplicate charges, emails, state transitions, or external
  writes unless the domain explicitly allows it.

## `_later` and `_now` Convention

Run async operations in shallow job classes. The job should usually delegate
the actual work back to a domain model or model-adjacent PORO instead of owning
business logic itself.

When a model method enqueues a job that invokes another method on that same
class, use `_later` for the async version and `_now` for the synchronous
version:

```ruby
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later
  end

  def relay_later
    Event::RelayJob.perform_later(self)
  end

  def relay_now
    # ...
  end
end

class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

The `_later` method is the enqueueing API. The `_now` method performs the
synchronous work and is what the job invokes.

## Shallow Jobs

Jobs should be shallow — they delegate to model methods:

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(notifiable)
    notifiable.notify_recipients
  end
end
```

## HTTP Integration Rules

When calling external services from jobs or code:

### Always Set Timeouts

```ruby
# Bad — blocks up to 60 seconds (default)
Net::HTTP.get(URI("https://api.example.com/data"))

# Good — explicit timeouts
uri = URI("https://api.example.com/data")
http = Net::HTTP.new(uri.host, uri.port)
http.open_timeout = 5
http.read_timeout = 5
http.request(Net::HTTP::Get.new(uri))

# Better — use Faraday with timeouts
conn = Faraday.new(url: "https://api.example.com") do |f|
  f.options.timeout = 5
  f.options.open_timeout = 2
end
```

### Explicit Exception Handling

Never use bare `rescue` or `rescue nil` for HTTP calls. Handle specific errors:

```ruby
# Bad — hides all errors
def send_to_api(data)
  ApiClient.post("/webhook", data)
rescue
  nil
end

# Good — explicit error classes
HTTP_ERRORS = [
  Timeout::Error, Errno::ECONNRESET, Net::HTTPBadResponse,
  Net::ProtocolError, SocketError, Errno::ECONNREFUSED
].freeze

def send_to_api(data)
  ApiClient.post("/webhook", data)
rescue *HTTP_ERRORS => e
  ErrorTracker.notify(e)
  nil
end
```

### Background Non-Critical Calls

Do not make synchronous API calls in request cycles. Background them:

```ruby
# Bad — blocks request
def create
  @webhook = Webhook.create!(webhook_params)
  ExternalService.notify(@webhook)  # slow, blocks
end

# Good — background the call
def create
  @webhook = Webhook.create!(webhook_params)
  WebhookNotifyJob.perform_later(@webhook)
end
```

## Error Handling

### Transient Errors — Retry

Retry network and temporary errors with polynomial backoff:

```ruby
module SmtpDeliveryErrorHandling
  extend ActiveSupport::Concern

  included do
    retry_on Net::OpenTimeout, Net::ReadTimeout, Socket::ResolutionError,
      wait: :polynomially_longer

    retry_on Net::SMTPServerBusy, wait: :polynomially_longer  # 4xx = temporary
  end
end
```

Keep retry windows bounded and visible in logs or error reporting. Do not retry
validation failures or permanent provider rejections.

### Permanent Failures — Swallow Gracefully

Do not fail the job for unrecoverable errors. Log at info level:

```ruby
module SmtpDeliveryErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from Net::SMTPSyntaxError do |error|
      case error.message
      when /\A501 5\.1\.3/  # Bad email address
        Sentry.capture_exception error, level: :info
      else
        raise
      end
    end
  end
end
```

## Transaction Safety

Set `enqueue_after_transaction_commit` to prevent jobs from running before data exists:

```ruby
# In initializer
ActiveJob::Base.enqueue_after_transaction_commit = true
```

When enqueueing is part of a state transition, the state write and enqueue
decision must be transaction-safe. Prefer `after_commit`, Rails transactional
enqueueing, or an explicit outbox-style persisted event over callbacks that can
fire before rollback.

## Tenant Context In Jobs

Request-scoped `Current` attributes are not available when a job runs.

- Capture tenant/account (and any other required ambient context) at enqueue
  time as serializable IDs or GlobalIDs.
- Restore that context around `perform` (for example
  `Current.set(account: account) { ... }` or the app's existing helper).
- Recurring jobs that touch tenant data must iterate tenants explicitly rather
  than assuming a current account.

```ruby
class ApplicationJob < ActiveJob::Base
  around_enqueue do |job, block|
    job.account_id ||= Current.account&.id
    block.call
  end

  around_perform do |job, block|
    if job.account_id
      Current.set(account: Account.find(job.account_id), &block)
    else
      block.call
    end
  end
end
```

Adapt to the app's existing job/tenant helpers when present. Do not invent a
parallel Current system.

## Crash-Safe Fan-Out

For long iterations (webhook fan-out, broadcasts, backfills), prefer cursor-based
progress over one giant loop that restarts from zero after a crash.

When the Rails version and Active Job setup support it, use
`ActiveJob::Continuable` with `step` + cursor advancement. Otherwise use an
explicit cursor column or keyed progress record. Either way:

- Resume from the last successful cursor.
- Keep each step idempotent.
- Avoid holding a single multi-minute transaction across the whole fan-out.

```ruby
class DeliverWebhooksJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(event)
    step :deliver do |step|
      event.matching_webhooks.find_each(start: step.cursor) do |webhook|
        event.deliveries.create!(webhook: webhook)
        step.advance!(from: webhook.id)
      end
    end
  end
end
```

Verify Continuable availability against the app's Rails version before using it.
If unavailable, implement an equivalent cursor pattern — do not pretend the API
exists.

## Stagger Recurring Jobs

Prevent resource spikes by offsetting schedules:

```yaml
# Bad — all at :00
job_a: every hour at minute 0
job_b: every hour at minute 0

# Good — staggered
job_a: every hour at minute 12
job_b: every hour at minute 50
```

## Maintenance Jobs

- Clean finished jobs periodically.
- Clean orphaned data (expired links, unused tags, old deliveries).

## Backend-Specific Routing

- If adapter is `:good_job`, load `references/07a-background-jobs-good_job.md`.
- If adapter is `:solid_queue`, load `references/07b-background-jobs-solid_queue.md`.
