# Security Checklist

## XSS Prevention

Always escape before marking as `html_safe`. Escape in helpers, not views.

```ruby
# Bad
"<span>#{user_input}</span>".html_safe

# Good
"<span>#{h(user_input)}</span>".html_safe
```

## CSRF Protection

### Do Not HTTP Cache Pages With Forms

CSRF tokens get stale on cached pages, causing 422 errors on form submit.

### Sec-Fetch-Site Header

Use the browser's `Sec-Fetch-Site` header as an additional CSRF check alongside traditional tokens:

```ruby
module RequestForgeryProtection
  extend ActiveSupport::Concern

  private
    def verified_request?
      super || safe_fetch_site?
    end

    def safe_fetch_site?
      %w[same-origin same-site].include?(
        request.headers["Sec-Fetch-Site"]&.downcase
      )
    end
end
```

Add `Sec-Fetch-Site` to the Vary header for proper caching.

## SSRF Protection

For webhooks and any user-provided URLs:

- Resolve DNS once, pin the IP.
- Block private networks: loopback (127.0.0.0/8), private (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16), link-local (169.254.0.0/16).
- Validate at creation time AND request time.

## Content Security Policy

```ruby
config.content_security_policy do |policy|
  policy.script_src :self
  policy.style_src :self, :unsafe_inline
  policy.base_uri :none
  policy.form_action :self
  policy.frame_ancestors :self
  policy.report_uri ENV["CSP_REPORT_URI"] if ENV["CSP_REPORT_URI"]
end
```

Use nonce-based script loading for importmap support.

## Rate Limiting

Use Rails built-in rate limiting for sensitive endpoints:

```ruby
# Authentication
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Try again later." }
end

# Email sending
class Memberships::EmailAddressesController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create
end
```

**When to rate limit**: authentication actions, email sending endpoints, external API calls, resource creation endpoints.

## Authn/Authz

- Authenticate user/session context early.
- Authorize at resource/action boundaries.
- Deny by default when permission is unclear.
- Controller checks permission; model defines what permission means.

```ruby
# Controller concern
module Authorization
  extend ActiveSupport::Concern

  private
    def ensure_can_administer
      head :forbidden unless Current.user.admin?
    end
end

# Model
class User < ApplicationRecord
  def can_administer_card?(card)
    admin? || card.creator == self
  end
end
```

## Multi-Tenancy

- Scope broadcasts by account to prevent cross-tenant leaks.
- Disconnect deactivated users from ActionCable.

## Command Injection

Never interpolate user input into shell commands. Use the array form:

```ruby
# DANGEROUS
system("convert #{params[:file]}")
`ls #{user_input}`
exec("command #{args}")

# Safe — array form, no shell interpolation
system("convert", params[:file])
```

## Path Traversal

Never interpolate user input into file paths. Validate with `File.basename`:

```ruby
# DANGEROUS
send_file(params[:filename])
File.read(params[:path])

# Safe — basename prevents directory traversal
basename = File.basename(params[:filename])
safe_path = Rails.root.join("uploads", basename)
send_file(safe_path) if File.exist?(safe_path)
```

## Insecure Direct Object References (IDOR)

Always scope queries to the current user. Never fetch by raw ID without authorization:

```ruby
# DANGEROUS — any user can see any document
def show
  @document = Document.find(params[:id])
end

# Safe — scoped to current user
def show
  @document = current_user.documents.find(params[:id])
end
```

## Open Redirects

Never redirect to user-provided URLs without validation:

```ruby
# DANGEROUS
redirect_to params[:return_to]
redirect_to request.referer

# Safe — validate or use allowlist
ALLOWED_REDIRECTS = %w[/dashboard /profile /settings]
redirect_to ALLOWED_REDIRECTS.include?(params[:return_to]) ? params[:return_to] : root_path
```

## Data And Infra

- Store secrets in credentials or environment, never in code.
- Use CSRF protection for browser flows.
- Enforce secure cookie/session settings in production.
- Use parameterized queries to prevent injection.
- Set strict timeouts for outbound requests.
- Validate webhook signatures and replay protection.

## ActionText / Rich Text

- Configure sanitizer in `after_initialize` (eager loading bypasses config otherwise).
- Use `skip_pipeline: true` for external image URLs.
