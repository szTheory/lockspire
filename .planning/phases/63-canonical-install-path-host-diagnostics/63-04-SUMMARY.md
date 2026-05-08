---
phase: 63
plan: 63-04
subsystem: docs-and-host-proof
tags:
  - docs
  - support-contract
  - generated-host
  - onboarding
key-files:
  modified:
    - docs/install-and-onboard.md
    - docs/sigra-companion-host.md
    - docs/ecosystem-overview.md
    - docs/supported-surface.md
    - priv/templates/lockspire.install/fapi_smoke_e2e_test.exs
    - test/integration/install_generator_test.exs
    - test/integration/phase6_onboarding_e2e_test.exs
    - test/lockspire/release_readiness_contract_test.exs
metrics:
  tasks_completed: 2
  tasks_total: 2
---

# Phase 63 Plan 04 Summary

## Execution Results

- Updated the onboarding and support-contract docs so they now describe one canonical Phoenix install path, `mix lockspire.verify`, and manifest-scoped `mix lockspire.upgrade`.
- Kept Sigra positioned as the recommended companion only, without adding compile-time coupling or a second install topology.
- Moved the generated FAPI smoke template onto the generated host endpoint surface.
- Refactored the canonical onboarding E2E proof so discovery, authorize, consent completion, token exchange, and JWKS all run through `GeneratedHostAppWeb.Endpoint` and the mounted host router.
- Extended release-readiness checks so repo docs must continue to name the verify/upgrade contract and the one-path onboarding story.

## Verification

- `mix test test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs test/integration/phase6_onboarding_e2e_test.exs`
- `mix test test/lockspire/release_readiness_contract_test.exs`

## Deviations from Plan

None.

## Self-Check: PASSED
