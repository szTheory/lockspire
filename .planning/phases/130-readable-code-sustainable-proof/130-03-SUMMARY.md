---
phase: 130-readable-code-sustainable-proof
plan: "03"
subsystem: testing
tags: [exunit, oauth, oidc, token-exchange, test-architecture]
requires:
  - phase: 130-readable-code-sustainable-proof
    provides: "Shared DataCase and ConfigCase isolation from Plan 02"
provides:
  - "Capability-oriented authorization-code, device-code, CIBA/resource, and facade suites"
  - "Shared token-exchange setup and fixture vocabulary"
  - "Executable grant-routing and historical test inventory guards"
affects: [token-endpoint, authorization-code, device-code, ciba, dpop]
tech-stack:
  added: []
  patterns:
    - "Security-sensitive endpoint tests are physically partitioned by grant capability"
key-files:
  created:
    - test/support/token_exchange_case.ex
    - test/lockspire/protocol/token_exchange/authorization_code_test.exs
    - test/lockspire/protocol/token_exchange/device_code_test.exs
    - test/lockspire/protocol/token_exchange/ciba_and_resource_test.exs
  modified:
    - test/lockspire/protocol/token_exchange_test.exs
key-decisions:
  - "Preserve every historical test description and assertion while moving each scenario exactly once."
  - "Keep the root suite as an executable facade contract rather than a wrapper loader."
  - "Guard exact capability counts, unique names, public result shapes, and the five-grant routing matrix."
patterns-established:
  - "Large protocol suites share fixtures through a CaseTemplate and keep capability tests in real files."
requirements-completed: [TEST-02]
coverage:
  - id: T1
    description: "All token-exchange capability and delegation tests pass together without inventory loss."
    requirement: TEST-02
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/token_exchange"
        status: pass
      - kind: static-analysis
        ref: "mix dialyzer --format short"
        status: pass
    human_judgment: false
duration: "18m"
completed: 2026-08-26
status: complete
---

# Phase 130 Plan 03: Token Exchange Capability Split Summary

**The 2,294-line token endpoint monolith is now four capability-oriented suites backed by one shared, isolated fixture case.**

## Accomplishments

- Moved all authorization-code, device-code, CIBA/resource, and facade scenarios into real capability files without `Code.require_file` wrappers or duplicate execution.
- Reused `Lockspire.DataCase` through `Lockspire.TokenExchangeCase`, centralizing sandbox ownership, application configuration restoration, telemetry capture, signing keys, clients, grant records, DPoP proofs, token decoding, and audit helpers.
- Added executable facade contracts for public entry points, stable success/error struct fields, and the complete authorization-code/refresh/device/CIBA/RFC 8693 routing matrix.
- Added an inventory guard that enforces per-file test counts, globally unique test descriptions, a 39-test total, and wrapper-free source.

## Inventory

| Inventory | Before | After |
|---|---:|---:|
| Root suite lines | 2,294 | 133 |
| Historical tests | 36 | 36 |
| Total tests including new guards | 36 | 39 |
| Assertion/refutation calls | 191 | 204 |
| Shared fixture definitions | Embedded in monolith | 1 `Lockspire.TokenExchangeCase` |

### Complete old-to-new mapping

Every historical test retained its exact description, so the old-to-new mapping is executable by name. A source comparison confirms the sorted historical names match exactly.

- `authorization_code_test.exs` — 20 tests: issuance formats, resource audience, OIDC ID token/auth time, DPoP/nonce/replay, refresh issuance, Basic auth encoding, durable audit, PKCE, expiry, client, and redirect failures.
- `device_code_test.exs` — 10 tests: polling states, expiry, redemption, DPoP/nonce, resource defaults, bearer mode, replay/audit, refresh/ID-token policy, and client mismatch.
- `ciba_and_resource_test.exs` — 4 tests: CIBA DPoP nonce, CIBA resource/default audiences, and cross-grant resource rejection.
- `token_exchange_test.exs` — 2 retained facade tests plus 3 new public-surface, routing-matrix, and inventory guards.

## Verification

- `MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/token_exchange` — PASS, `44 tests, 0 failures` (39 split-suite tests plus 5 existing delegation tests).
- Historical test-name diff — PASS, exact 36-name match.
- `MIX_ENV=test mix compile --warnings-as-errors` — PASS.
- `mix format --check-formatted ...` — PASS for all five owned files.
- `mix credo --strict ...` — PASS, no issues across all five owned files.
- `mix dialyzer --format short` — PASS, `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`.
- Focused `mix test --cover` executes all 44 tests successfully and reports 11.90% of the entire application; Mix exits nonzero because a focused subset cannot meet the repository-wide 73% whole-suite floor.

## Deviations from Plan

- Added three facade/inventory guard tests. This raises the suite from 36 to 39 tests while preserving every historical assertion.
- Repository-wide `mix qa` is currently blocked by the sibling `test/support/admin_contract_helpers.ex` long-quote Credo finding; the strict Credo run scoped to all files owned by this plan passes.

## Issues Encountered

- Moving tests exposed module-relative references to the old nested `Resolver` and `PlainMethodTokenStore`; the shared case now uses fully qualified test-support modules.
- Test startup retains the existing non-blocking KeyCache refresh log before the test-owned Repo starts.

## User Setup Required

None.

## Next Phase Readiness

Token endpoint behavior is navigable by grant capability, all security-sensitive historical cases remain executable, and future additions have one shared fixture vocabulary and an enforced facade routing inventory.

---
*Phase: 130-readable-code-sustainable-proof*
*Completed: 2026-08-26*
