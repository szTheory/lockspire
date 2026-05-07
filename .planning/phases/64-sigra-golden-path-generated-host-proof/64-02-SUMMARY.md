---
phase: 64
plan: 64-02
subsystem: onboarding-proof
tags:
  - sigra
  - onboarding
  - generated-host
  - claims
key-files:
  modified:
    - test/integration/phase6_onboarding_e2e_test.exs
    - priv/templates/lockspire.install/account_resolver.ex
    - test/integration/install_generator_test.exs
    - test/lockspire/host/claims_test.exs
metrics:
  tasks_completed: 2
  tasks_total: 2
---

# Phase 64 Plan 02 Summary

## Execution Results

- Reworked the canonical onboarding E2E so it starts unauthenticated, redirects through `/login`, preserves `return_to` and `interaction_id`, resumes the interaction, completes consent, exchanges the code, and verifies ID token plus JWKS behavior through the generated host endpoint.
- Removed the old hardcoded logged-in shortcut from the canonical proof and routed account resolution through the shared generated-host resolver seam.
- Updated the generated `--sigra-host` resolver guidance to point at `conn.assigns.current_scope.user`, preserve login-resume parameters, and keep the canonical subject and claims posture intentionally narrow.
- Added generator and claims regressions so the generated host guidance stays aligned with the executable proof.

## Verification

- `mix test test/integration/phase6_onboarding_e2e_test.exs test/integration/install_generator_test.exs test/lockspire/host/claims_test.exs`

## Deviations from Plan

None.

## Self-Check: PASSED
