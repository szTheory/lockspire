# v1.23 Research: Features

## Table Stakes

- Self-service clients can register back-channel logout metadata during `POST /register`.
- Self-service clients can read the stored metadata through RFC 7592 management reads.
- Self-service clients can replace the stored metadata through RFC 7592 management updates.
- Validation rejects malformed or unsupported logout metadata with standard DCR error responses.

## Differentiators

- Preserve Lockspire's support-truth split: durable back-channel support, best-effort front-channel support.
- Keep operator/admin provenance and self-service management consistent instead of creating two competing truth models.
- Keep public docs explicit that DCR manages existing logout propagation settings; it does not broaden the product into federation or remote success guarantees.

## Anti-Features

- Do not add `post_logout_redirect_uris` to this milestone; that capability already exists separately and should remain conceptually distinct from logout propagation metadata.
- Do not add discovery or certification claims beyond what the shipped logout surfaces already prove.
- Do not auto-normalize ambiguous URLs or relax exactness for RP-managed endpoints.

## Complexity Notes

- The hardest part is not persistence; the fields already exist.
- The main risks are validator drift, JSON response omissions, and docs/support-truth regressions.
- Management update semantics should stay full-replace, matching the current RFC 7592 slice.
