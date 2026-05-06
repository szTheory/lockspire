---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 05
subsystem: "Publication Surfaces"
tags: [fapi-2-0, discovery, jwks, dpop]
dependency_graph:
  requires: [01, 02, 07]
  provides: [truthful-publication]
  affects: [lib/lockspire/protocol/discovery.ex, lib/lockspire/protocol/jwks.ex, lib/lockspire/web/controllers/userinfo_controller.ex]
tech_stack:
  added: []
  patterns: [canonical-policy-resolution, dynamic-algorithm-metadata]
key_files:
  created: []
  modified:
    - lib/lockspire/protocol/discovery.ex
    - lib/lockspire/protocol/jwks.ex
    - lib/lockspire/web/controllers/userinfo_controller.ex
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
    - test/lockspire/web/jwks_controller_test.exs
    - test/lockspire/web/userinfo_controller_test.exs
decisions:
  - "Discovery and JWKS metadata now advertise only the algorithms actually supported by the resolved FAPI runtime profile."
  - "DPoP WWW-Authenticate challenge header derives its acceptable algorithms directly from the validator configuration."
metrics:
  duration: "15m"
  completed_date: "2026-05-02"
---
# Phase 42 Plan 05: Align discovery, JWKS, and DPoP publication with runtime truth Summary

Discovery, JWKS, and DPoP challenge metadata now publish only the signing algorithms truly supported by the resolved FAPI profile.

## Key Changes
- Updated `Discovery` to resolve allowed signing algorithms through `SecurityProfile.Resolved`.
- Updated `JWKS` publication to filter out non-compliant keys when under FAPI mode.
- Updated `UserinfoController` to generate DPoP challenges using the validator's canonical algorithm allow-list.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None

## Self-Check: PASSED