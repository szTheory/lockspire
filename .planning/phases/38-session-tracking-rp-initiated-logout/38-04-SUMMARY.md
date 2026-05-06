---
phase: 38-session-tracking-rp-initiated-logout
plan: "04"
subsystem: discovery-admin-generator
tags: [oidc, discovery, admin, liveview, generator, logout]

requires:
  - phase: 38-02
    provides: sid persistence and revoke_by_sid support
  - phase: 38-03
    provides: mounted end_session endpoint and logout flow

provides:
  - Discovery metadata for `end_session_endpoint`
  - Discovery logout support flags set to false for Phase 38
  - Client admin persistence and editing for `post_logout_redirect_uris`
  - Token admin visibility for stored sid values
  - Generator seam for `redirect_for_logout/2`

affects:
  - 39

tech-stack:
  added: []
  patterns:
    - "Discovery only advertises mounted Lockspire-owned endpoints"
    - "Admin surfaces expose sid and post-logout URIs without adding revoke-session UI"
    - "Generator mirrors the host seam introduced in Plan 03"

key-files:
  modified:
    - lib/lockspire/protocol/discovery.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/web/live/admin/tokens_live/show.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - priv/templates/lockspire.install/account_resolver.ex
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
    - test/lockspire/admin/clients_test.exs
    - test/lockspire/web/live/admin/tokens_live_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs

requirements-completed:
  - SLO-01
  - SLO-02

duration: 1 session
completed: 2026-04-29
---

# Phase 38 Plan 04: Discovery, Admin, and Generator Summary

**Completed the operator-facing Phase 38 work: discovery publishes logout metadata, admin UI exposes `sid` and `post_logout_redirect_uris`, and the install template includes the host logout seam.**

## Accomplishments

- Discovery now publishes `end_session_endpoint` and the truthful Phase 38 flags `backchannel_logout_supported: false` and `frontchannel_logout_supported: false`.
- Fixed the persistence gap in `ClientRecord.update_changeset/2` so `post_logout_redirect_uris` saves correctly.
- Added token detail display for session IDs with a legacy fallback of `Not recorded`.
- Added client show/edit support for `post_logout_redirect_uris`, including the dedicated `:logout_uris` mode and route.
- Updated the install template account resolver with a `redirect_for_logout/2` stub.

## Verification

- `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs --no-color` -> 0 failures

## Notes

- Phase 38 remains view-only for sessions in admin UI; operator-triggered session revocation is still handled in Phase 39.

---
*Phase: 38-session-tracking-rp-initiated-logout*
*Completed: 2026-04-29*
