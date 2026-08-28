---
phase: 132-public-api-and-resource-server-truth
plan: 02
subsystem: api
tags: [oauth, oidc, dcr, client-registration, validation]
requires:
  - phase: 131-executable-installation
    provides: executable embedded-host installation baseline
provides:
  - One dependency-light capability validator for direct and dynamic client registration.
  - Persisted OIDC, device-only, and private_key_jwt client shapes with redirect and key safety.
affects: [132-04, 133-clean-room-saas-journey, 134-dependency-topology]
tech-stack:
  added: []
  patterns: [neutral registration-shape validation with boundary-specific error adapters]
key-files:
  created: [lib/lockspire/client_registration/shape.ex]
  modified: [lib/lockspire/clients.ex, lib/lockspire/protocol/registration.ex, lib/lockspire/protocol/dcr_policy.ex]
key-decisions:
  - "Redirects are required by authorization-code/code capability, never merely by registration entry point."
  - "openid is a built-in OIDC scope, while DCR policy still governs every non-built-in scope and capability."
  - "private_key_jwt persists exactly one validated key source and emits field/reason diagnostics without key material."
patterns-established:
  - "Shared shape validators return neutral field/reason issues; public facades translate them into their existing contracts."
requirements-completed: [API-02]
coverage:
  - id: D1
    description: Direct registration persists OIDC, device-only, and private_key_jwt client shapes safely.
    requirement: API-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/clients_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: DCR shares capability checks and retains exact redirect enforcement.
    requirement: API-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/controllers/registration_controller_test.exs
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-08-26
status: complete
---

# Phase 132 Plan 02: Shared Client Registration Shape Summary

**Direct and dynamic registration now share capability-aware OIDC, redirect, and private-key validation while retaining their own durable result and error contracts.**

## Accomplishments

- Added a pure `Lockspire.ClientRegistration.Shape` collaborator for grant/response coherence, redirect capability, built-in OIDC scopes, and safe key-source validation.
- Made direct registration persist valid OIDC, redirectless device-only, inline-JWKS, and HTTPS-JWKS-URI client shapes; code-capable forms still require valid redirects.
- Routed DCR through the shared validator after policy resolution, preserving FAPI/logout/encryption checks and typed `Registration.Error` translation.
- Kept runtime exact redirect membership unchanged and covered it in the combined protocol verification run.

## Task Commits

1. **Task 1: Register OIDC and device-only clients through the direct facade** — `2e4917e` (feat)
2. **Task 2: Persist safe private_key_jwt key material through direct registration** — `2e4917e` (feat)
3. **Task 3: Route DCR through the same capability matrix and retain exact redirect enforcement** — `c441dd9` (feat)

## Files Created/Modified

- `lib/lockspire/client_registration/shape.ex` — neutral registration capability validator.
- `lib/lockspire/clients.ex` — direct adapter, coherent defaults, and persisted key material.
- `lib/lockspire/protocol/registration.ex` — DCR adapter retaining its policy and error boundary.
- `lib/lockspire/protocol/dcr_policy.ex` — built-in `openid` remains available independently of host scope configuration.
- `test/lockspire/clients_test.exs` — persisted direct registration and key-source matrix.
- `test/lockspire/protocol/registration_test.exs` — DCR device-only/openid and redirectless-code negative matrix.

## Decisions Made

- A redirectless exception exists only for clients with neither the authorization-code grant nor a `code` response type.
- `jwks_uri` must be HTTPS and private-key clients must have exactly one usable key source; no raw key material enters errors or registration telemetry.
- DCR resolves its operator policy before delegating common shape validation, preserving its FAPI and endpoint-specific controls.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Made `openid` built in at the DCR policy boundary.**
- **Found during:** Task 3
- **Issue:** The DCR policy intersection would reject `openid` if an operator's host scope allowlist omitted it, contradicting the built-in OIDC capability contract.
- **Fix:** Included `openid` in the effective DCR scope envelope while preserving policy checks for all other scopes.
- **Files modified:** `lib/lockspire/protocol/dcr_policy.ex`
- **Verification:** Combined DCR/direct capability suite passes.
- **Committed in:** `c441dd9`

**Total deviations:** 1 auto-fixed (Rule 2).

## Verification

- `mix compile --warnings-as-errors` — passed
- `mix test test/lockspire/clients_test.exs` — passed (10 tests)
- `mix test test/lockspire/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/controllers/registration_controller_test.exs` — passed (162 tests)

## Self-Check: PASSED

- Created validator exists at `lib/lockspire/client_registration/shape.ex`.
- Task commits `2e4917e` and `c441dd9` exist in git history.

## Next Phase Readiness

The clean-room SaaS journey can register the advertised client shapes through either supported boundary without taking ownership of host policy or broadening Phase 134 topology work.
