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
- Keep retries intentional and bounded.
- Keep transactions and enqueue timing safe.

## `_later` and `_now` Convention

When a model method enqueues a job that invokes another method on that same class, use `_later` for the async version. The synchronous method uses `_now` or the plain name:

```ruby
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later
  end

  # Called by the job — the actual work
  def relay_now
    # ...
  end

  private
    # Enqueues the job
    def relay_later
      Event::RelayJob.perform_later(self)
    end
end

class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

The `_later` method is usually private and called from callbacks. The plain method name is the public API that the job invokes.

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
