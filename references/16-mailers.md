# Mailers

- Generate mailers with Rails, then adapt the output to the application's
  layout, partial, translation, and delivery conventions.
- Reuse shared mailer partials and layouts. Follow the host's supported email
  styling/inlining pipeline instead of introducing a dependency by default.
- Configure delivery queues according to the application's latency and worker
  topology; do not hard-code a queue name into reusable guidance.
- Every application mailer action that sends email must have a working preview
  under `test/mailers/previews/`, including authentication, transactional,
  operational and internal notification emails. Add missing previews when
  auditing an existing mailer, and update previews with action changes.
- Use deterministic synthetic data and the real mailer action in previews.
  Never issue authentication codes, mutate application records, deliver mail or
  call providers while constructing a preview. Cover important content states
  without depending on whichever production-like record happens to exist.
- Verify preview coverage against the application's mailer actions and render
  every preview without delivery. Assert meaningful recipients and content;
  preview file existence alone does not establish that it works.
- Cover product recipients, tenant binding, and consequential content at the
  owning layer. Use the application's installed mailer test helpers; do not
  duplicate Rails delivery plumbing tests.

Consult the version-matched [Action Mailer guide](https://guides.rubyonrails.org/v8.1/action_mailer_basics.html)
before adding helpers for previews, delivery callbacks, rendering, or queueing.

## Local Development Delivery

Follow the Nuntio development pattern: add `letter_opener` to the development
Gemfile group, set `config.action_mailer.delivery_method = :letter_opener`,
enable deliveries and raise delivery errors in `config/environments/development.rb`.
Use `config.after_initialize` to set
`ActionMailer::MailDeliveryJob.queue_adapter = :inline` in development so
`deliver_later` opens local mail without a worker. Leave other jobs and the
production queue adapter unchanged. Inspect custom mail delivery jobs before
assuming the default class owns the app's deliveries. Suppress local email-body
logging with `config.action_mailer.logger = nil` and delivery-job argument logging
with `ActionMailer::MailDeliveryJob.log_arguments = false` so codes passed as
mailer arguments do not leak into development logs.

Sign-in and verification codes remain random, expiring and single use in every
environment. Open the actual local email to obtain a development code; do not
add a fixed code, an environment-specific verification bypass, or secret logging.
Preserve the host's code length and authentication rules. Tests retain the test
mail delivery adapter and must never open a browser or send SMTP mail.

Previews at `/rails/mailers` show synthetic email content; they do not issue a
usable sign-in code. Verify local `deliver_later` delivery separately from preview
rendering, and keep production preview access disabled.
