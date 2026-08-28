---
phase: 134-architecture-topology
plan: 01
subsystem: client-registration
tags: [oauth, oidc, dcr, architecture, lifecycle]
dependency_graph:
  requires: [client-registration-shape, repository-audit-transaction]
  provides: [neutral-client-metadata, neutral-client-lifecycle]
  affects: [direct-registration, dynamic-client-registration]
tech_stack:
  added: []
  patterns: [neutral-intent-validation, atomic-audited-persistence, facade-contract-preservation]
key_files:
  created:
    - lib/lockspire/client_metadata.ex
    - lib/lockspire/client_lifecycle.ex
    - test/lockspire/client_lifecycle_test.exs
  modified:
    - lib/lockspire/clients.ex
    - lib/lockspire/protocol/registration.ex
    - test/lockspire/clients_test.exs
decisions:
  - DCR policy, RFC error mapping, IAT/RAT generation, and telemetry remain in Registration; neutral modules receive only resolved metadata and actor facts.
  - Direct registration preserves its required allowed_scopes contract while using the same Shape validator and lifecycle persistence seam.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 134 Plan 01: Neutral Client Metadata and Lifecycle Summary

Direct and dynamic client registration now share neutral metadata validation and lifecycle persistence without changing their boundary-specific result contracts.

## Completed Work

- Added `Lockspire.ClientMetadata` for dependency-neutral Shape validation, DCR client construction, logout metadata rules, PKCE construction floor, and FAPI readiness facts.
- Added `Lockspire.ClientLifecycle`, which owns DCR's single `Repository.transact_with_audit/2` create operation and direct-client persistence delegation.
- Rewired `Lockspire.Protocol.Registration` away from all `Lockspire.Admin` references for DCR creation, logout validation, and FAPI readiness.
- Kept direct registration's `RegistrationResult`, one-time plaintext confidential secret, public-client no-secret behavior, and required-scope validation intact.
- Characterized the direct-required-scope versus DCR-optional-scope distinction while retaining the existing DCR audit-attribution and public registration contracts.

## Verification

- `mix compile --warnings-as-errors`
- `mix test test/lockspire/client_lifecycle_test.exs test/lockspire/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/dcr_audit_attribution_test.exs` — 70 tests, 0 failures
- `rg -n "Lockspire\\.Admin|Admin\\.Clients" lib/lockspire/protocol/registration.ex` — no production references

## TDD Gate Compliance

- RED: `1743101` establishes the neutral lifecycle call before its module existed.
- GREEN: `4d3e59c` adds the neutral modules and routes DCR/direct persistence through them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved exact logout-validation ordering and semantics after extraction.**
- **Found during:** Task 1 focused DCR contract run.
- **Issue:** The initial neutral implementation treated backchannel logout like frontchannel origin validation and surfaced a session-required error before the strict boolean error.
- **Fix:** Matched the existing rules: only frontchannel requires redirect-origin parity, and strict boolean errors remain first.
- **Files modified:** `lib/lockspire/client_metadata.ex`
- **Commit:** `4d3e59c`

**2. [Rule 1 - Bug] Removed unused extracted helpers to retain warnings-as-errors compatibility.**
- **Found during:** Task 1 compile verification.
- **Fix:** Deleted the superseded DCR construction helpers from `Registration` after their responsibility moved to `ClientMetadata`.
- **Files modified:** `lib/lockspire/protocol/registration.ex`
- **Commit:** `4d3e59c`

## Known Stubs

None.

## Self-Check: PASSED

- Neutral metadata and lifecycle modules exist and are committed in `4d3e59c`.
- TDD characterization commit `1743101`, compatibility characterization `781821a`, and documentation correction `01158b0` exist.
