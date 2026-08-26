---
phase: 132-public-api-and-resource-server-truth
plan: 04
subsystem: resource-server-documentation
tags: [oauth, oidc, phoenix, dpop, documentation, compatibility]
requires:
  - phase: 132-public-api-and-resource-server-truth
    provides: AccessToken readers, capability-aware registration, durable DPoP default
provides:
  - Canonical resource-server guide tied to generated host examples
  - Explicit host authorization ownership after Lockspire protocol enforcement
  - Additive v1.37 migration guidance and bounded release drift contracts
affects: [133-clean-room-saas-journey, resource-server-hosts, release-readiness]
tech-stack:
  added: []
  patterns:
    - Generated examples call semantic AccessToken readers instead of parsing raw claims
    - Protocol enforcement and host product authorization are independent decisions
    - Public documentation behavior is guarded by focused release contracts
key-files:
  created:
    - docs/upgrading/v1.37.md
  modified:
    - docs/protect-phoenix-api-routes.md
    - docs/supported-surface.md
    - priv/templates/lockspire.install/router.ex
    - test/support/generated_host_app_web/controllers/protected_api_controller.ex
    - test/integration/install_generator_test.exs
    - test/lockspire/release/support_surface_contract_test.exs
    - test/lockspire/release_readiness_contract_test.exs
key-decisions:
  - "The configured Lockspire repository is the ordinary durable DPoP replay default; custom stores are optional advanced overrides."
  - "Generated controllers use only additive AccessToken readers for standard protocol facts while raw claims remain a compatibility and extension path."
  - "Lockspire establishes protocol validity, scope, audience, and sender constraints; the host separately owns tenant, object, billing, product, response, and rate-limit policy."
requirements-completed: [API-01, API-02, API-03, API-04]
status: complete
---

# Phase 132 Plan 04: Resource-Server Truth Summary

**The canonical guide, generated host fixture, migration guide, and release contracts now tell one executable, additive resource-server story.**

## Accomplishments

- Removed the custom replay-store prerequisite from every canonical protected-route recipe while preserving a clearly marked advanced override and the configured repository default.
- Replaced raw-claim parsing in the generated protected controller with the five public `AccessToken` readers and made a separate host-owned authorization decision observable as both allow and deny behavior.
- Added v1.37 migration guidance for additive semantic readers, raw-claims compatibility, DPoP storage defaults, and constrained registration shapes.
- Pinned the guide, generated template, registration bounds, authorization boundary, and release test inventory with focused semantic drift checks.

## Task Commits

1. **Task 1: Align the canonical guide and generated protected pipeline** — `8e0a05a`
2. **Task 2: Execute semantic readers and the host authorization boundary** — `a5f6c65`
3. **Task 3: Lock supported-surface and v1.x migration truth against drift** — `9ad76af`

## Verification

- `mix test test/lockspire/release/support_surface_contract_test.exs test/lockspire/release_readiness_contract_test.exs test/integration/install_generator_test.exs` — passed (41 tests).
- `mix test --include integration test/integration/phase81_generated_host_route_protection_e2e_test.exs test/integration/install_generator_test.exs test/lockspire/access_token_test.exs` — passed (25 tests).
- `mix test --include integration test/integration/protected_resource_dpop_default_store_test.exs` — passed (2 tests).
- `mix docs.verify` — passed.
- `mix compile --warnings-as-errors` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical proof] Extended the existing generated protected-route integration proof.**
- **Found during:** Task 2
- **Issue:** The plan-required signed request and host-policy denial already belonged to the established generated-route E2E suite, rather than only to generator rendering tests.
- **Fix:** Updated that existing suite alongside the fixture response contract, proving semantic-reader output and a post-protocol host denial with a verified JWT.
- **Files modified:** `test/integration/phase81_generated_host_route_protection_e2e_test.exs`
- **Commit:** `a5f6c65`

## Known Stubs

None.

## Self-Check: PASSED

- Canonical guide, upgrade guide, generated template, fixture controller, and release contracts exist.
- Commits `8e0a05a`, `a5f6c65`, and `9ad76af` exist in git history.
- Fresh focused tests, docs verification, and warnings-as-errors compilation passed.
