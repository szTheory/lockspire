---
phase: 153
review: 153-REVIEW.md
recorded: 2026-10-15
---

# Phase 153 Code Review Disposition

| Finding | Severity | Disposition | Notes |
|---------|----------|-------------|-------|
| WR-01 | warning | fixed | `TokensLive.Show` now answers `revoke_token`/`revoke_family` events with the recoverable revocation error when no valid token is loaded, instead of raising on `Admin.revoke_token(nil, ...)`. Covered in `tokens_live_test.exs` (malformed-ID test). |
| WR-02 | warning | accepted | Source-reading contract tests match the project's existing design-system proof style (`css_assertions.ex`, `route_assertions.ex`). The planning-doc route matrix test, the most brittle of them, was removed on this branch. |
| WR-03 | warning | deferred | `adoption_smoke.py` asserts against synthetic demo seed data by design; it runs only in the Adoption Demo Smoke job. Revisit if the seed changes. |
| WR-04 | warning | fixed (partial) | "Client created" → "App created" (retired in PRODUCT.md); DPoP help no longer says "above". The "Used after replacement" status label and the "Used again at" timestamp label describe different things and stay as they are. |
| IN-01 | info | accepted | `revoked_by: "operator"` matches the admin audit actor used elsewhere; host actor identity is out of scope. |
| IN-02 | info | deferred | Duplicate-submit on app creation is Phase 151 territory (client creation page); not changed in this close-out. |
