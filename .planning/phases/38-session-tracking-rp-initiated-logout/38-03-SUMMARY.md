---
phase: 38-session-tracking-rp-initiated-logout
plan: "03"
subsystem: logout
tags: [oidc, logout, end-session, rp-initiated-logout, controller, phoenix]

requires:
  - phase: 38-01
    provides: Phase 38 test contract and validation cases
  - phase: 38-02
    provides: sid persistence, revoke_by_sid/1, and ID token sid claim

provides:
  - Lockspire.Protocol.EndSession.validate/1
  - Config.logout_path/0 and Lockspire.logout_path/0 startup validation
  - AccountResolver.redirect_for_logout/2 optional host seam
  - GET/POST /end_session and GET /end_session/complete routes
  - Signed return_to completion flow via Phoenix.Token
  - Lockspire-owned logged-out HTML page

affects:
  - 38-04
  - 39

tech-stack:
  added: []
  patterns:
    - "Protocol-owned validation in EndSession keeps controller thin"
    - "Phoenix.Token handoff carries sid/post_logout_redirect_uri/state across host logout"
    - "Invalid completion token is treated as logout success so the user is never stranded"

key-files:
  created:
    - lib/lockspire/protocol/end_session.ex
    - lib/lockspire/web/controllers/end_session_controller.ex
    - lib/lockspire/web/controllers/end_session_html.ex
    - lib/lockspire/web/controllers/end_session_html/logged_out.html.heex
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire.ex
    - lib/lockspire/host/account_resolver.ex
    - lib/lockspire/web/router.ex
    - test/lockspire/protocol/end_session_test.exs
    - test/lockspire/web/end_session_controller_test.exs
    - test/integration/phase38_session_logout_e2e_test.exs

requirements-completed:
  - SLO-02

duration: 1 session
completed: 2026-04-29
---

# Phase 38 Plan 03: RP-Initiated Logout Protocol and Controller Summary

**Implemented the full RP-initiated logout surface: `/end_session` validation, host logout handoff, signed completion, session-token revocation, and the logged-out fallback page.**

## Accomplishments

- Added `Lockspire.Protocol.EndSession` with signature validation for `id_token_hint`, expiry-tolerant hint handling, exact-match `post_logout_redirect_uri` checks, and `client_id`/`aud` mismatch rejection.
- Added `Config.logout_path/0`, exposed it through `Lockspire.logout_path/0`, and extended `AccountResolver` with optional `redirect_for_logout/2`.
- Added `Lockspire.Web.EndSessionController` and router wiring for `GET /end_session`, `POST /end_session`, and `GET /end_session/complete`.
- Implemented Phoenix.Token-based `return_to` transport so the host clears its session first, then Lockspire completes revocation and redirect.
- Replaced the Wave 0 skipped protocol, controller, and integration stubs with working Phase 38 coverage.

## Verification

- `mix test test/lockspire/protocol/end_session_test.exs test/lockspire/web/end_session_controller_test.exs test/integration/phase38_session_logout_e2e_test.exs --no-color` -> 0 failures

## Notes

- Completion intentionally succeeds even when the signed `return_to` token is invalid or missing; the user still lands on the logged-out page.
- The integration test now proves `sid` generation, token denormalization, and end-to-end logout without depending on the full token exchange pipeline.

---
*Phase: 38-session-tracking-rp-initiated-logout*
*Completed: 2026-04-29*
