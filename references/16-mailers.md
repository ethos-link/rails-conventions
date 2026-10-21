# Mailers

- Generate mailers with Rails, then adapt the output to the application's
  layout, partial, translation, and delivery conventions.
- Reuse shared mailer partials and layouts. Follow the host's supported email
  styling/inlining pipeline instead of introducing a dependency by default.
- Configure delivery queues according to the application's latency and worker
  topology; do not hard-code a queue name into reusable guidance.
- Add or update the matching preview under `test/mailers/previews/` when adding
  or changing an action. Exercise important states with deterministic data;
  previews must not send mail or trigger provider side effects.
- Cover product recipients, tenant binding, and consequential content at the
  owning layer. Use the application's installed mailer test helpers; do not
  duplicate Rails delivery plumbing tests.

Consult the version-matched [Action Mailer guide](https://guides.rubyonrails.org/v8.1/action_mailer_basics.html)
before adding helpers for previews, delivery callbacks, rendering, or queueing.
