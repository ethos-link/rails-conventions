# API Mode And Serialization

## API Surface

- Keep API contracts explicit and stable.
- Follow local serialization conventions before adding a new serializer layer.
- Do not expose raw model attributes by default.
- Return only fields the client contract owns.
- Keep authentication and authorization at the request/resource boundary.
- Keep error shapes consistent across endpoints.

## Serialization

- Prefer explicit serializers, partials, or `as_json` methods based on local
  convention.
- Keep serialization close to the boundary. Do not push presentation-only API
  shape into core domain models unless that is already the local convention.
- Do not leak internal IDs, tokens, metadata, or provider payloads unless they
  are part of the public contract.
- Use ISO 8601 timestamps and stable enum/string values.

## Writes

- Use `params.expect` for required structured params in Rails 8.1+.
- Make unsafe writes idempotent when clients can retry.
- Use database constraints for invariants that must survive concurrent writes.
- Wrap multi-record writes in transactions.
- Return clear status codes: `201 Created`, `202 Accepted`, `204 No Content`,
  `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, and
  `422 Unprocessable Entity`.

## Collections

- Paginate or cap collection endpoints.
- Define ordering explicitly.
- Avoid unbounded includes or nested serialization.
- Keep filters and sort keys documented.

## Versioning

Do not add versioning until there is a real compatibility need. When versioning
is needed, version the external contract, not internal model names.
