---
phase: "28"
plan: "03"
subsystem: Admin UI
tags:
  - client-admin
  - rat-rotation
  - dcr-provenance
dependency_graph:
  requires:
    - 28-02
  provides:
    - Operator client provenance filter
    - Operator copy-once RAT rotation UI
  affects:
    - lib/lockspire/web/live/admin/clients_live/index.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/router.ex
tech_stack:
  added: []
  patterns:
    - URL-driven faceted filtering (Phoenix.LiveView URL params)
    - Copy-once plaintext display
key_files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/clients_live/index.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/router.ex
    - test/lockspire/web/live/admin/clients_live_test.exs
decisions:
  - "Inlined the copy-once RAT rotation panel in ClientsLive.Show rather than creating a new Component, mirroring existing inline components and reducing indirection."
  - "Reused the IAT minting and secret rotation pattern: requiring explicit confirmation checkbox to rotate, and an explicit button click to clear the state/screen of the plaintext token."
metrics:
  duration: 15m
  tasks: 3
  files_changed: 4
---

# Phase 28 Plan 03: Client Admin RAT Rotation Summary

Client inventory UI now correctly filters clients by their provenance (operator vs self-registered), and operators have an explicit, secure workflow to force-rotate a self-registered client's Registration Access Token (RAT) using a copy-once explicit clear mechanism.

## Completed Tasks

1. Added `provenance` faceted filter on `ClientsLive.Index` and visual badge distinguishing operator-created vs self-registered clients.
2. Added `Rotate Registration Access Token (RAT)` logic and template elements conditionally rendered on `ClientsLive.Show` for self-registered clients, utilizing `Protocol.RegistrationManagement.rotate_registration_access_token/1`.
3. Extended `ClientsLiveTest` to assert that the provenance filter correctly narrows the client list and that the copy-once RAT rotation safely renders and clears the plaintext upon explicit user action.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED