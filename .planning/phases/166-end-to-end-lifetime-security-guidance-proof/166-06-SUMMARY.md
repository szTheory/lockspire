---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "06"
subsystem: auth
tags: [elixir, oauth, dcr, postgres, storage]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed lifetime states, promotion semantics and shared transaction requirements
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: Secret rotation and atomic lifetime persistence
  - phase: 165-management-token-lifecycle-recovery
    provides: Management recovery lifecycle and rollback behavior
  - phase: 166-05
    provides: User-approved client_store and transaction_store selectors
provides:
  - Registration and management lifecycle operations use the configured client/transaction composition
  - Shared authority validation checks selected client/transaction modules and built-in PostgreSQL token, grant and audit peers
  - Invalid storage configuration is rejected before consuming a single-use registration token
  - Selected secret rotation, host recovery and late audit rollback have routed or durable integration proof
affects: [phase-166-custom-store-proof, client-lifetime-guidance]
actuals:
  tokens: 9099
  tasks: 2
  commits: 4
commits: 4
plan_head_before: ec81d54649c93cb40d061a7bf0df9aaa909569bb
plan_head_after: 4f1da8cdfec0234f27b0973b44895eef2de943b5
tech-stack:
  added: []
  patterns:
    - Validate the configured client and transaction stores once at the lifecycle boundary before reads or writes
    - Keep transaction authority on the selected transaction store while token, grant and audit participants remain built-in Repository adapters
    - Permit legacy v0 advisory dates through management promotion; reject malformed authoritative v1 and unknown versions
key-files:
  created:
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-06-01-RED-EVIDENCE.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-06-02-RED-EVIDENCE.json
  modified:
    - lib/lockspire/client_lifecycle.ex
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/storage/client_lifetime.ex
    - lib/lockspire/web/controllers/registration_controller.ex
    - test/integration/client_lifetime_selected_store_test.exs
key-decisions:
  - Keep client registration and guarded management on the approved selected client/transaction stores, with existing Repository-backed protocol, grant and audit peers.
  - Validate storage composition before redeeming an initial access token; configuration failure must not consume durable credentials.
requirements-completed: [DCR-17, DCR-18]
coverage:
  - id: D1
    description: Configured client and transaction callbacks participate in registration, management GET/PUT/DELETE, secret rotation and host recovery.
    requirement: DCR-17
    verification:
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#configured stores own registration and routed management lifecycle
        status: pass
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#selected secret rotation and host recovery use configured callbacks
        status: pass
    human_judgment: false
  - id: D2
    description: Invalid composition is rejected before mutation, and a late audit failure leaves selected client and durable audit/token observations unchanged.
    requirement: DCR-18
    verification:
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#invalid selected composition fails before consuming an initial access token
        status: pass
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#late audit failure rolls selected DCR replacement back durably
        status: pass
    human_judgment: false
  - id: D3
    description: Recovery rejects unknown lifetime versions while preserving legacy v0 advisory-date promotion and current-row guards.
    requirement: DCR-18
    verification:
      - kind: integration
        ref: test/integration/client_lifetime_selected_store_test.exs#host recovery rejects an unknown lifetime version without changing the row
        status: pass
      - kind: integration
        ref: test/integration/management_token_lifetime_update_test.exs#explicit v0 management replacement clears advisory dates and promotes the current row
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-10-22
status: complete
---

# Phase 166 Plan 06: Selected Client Lifecycle Storage Summary

**DCR registration, management, secret rotation and recovery now use the same validated client/transaction composition, with existing PostgreSQL grant, token and audit peers.**

## Performance

- **Duration:** Approximately 7 minutes.
- **Started:** 2026-10-22T00:44:30Z.
- **Completed:** 2026-10-22T00:51:23Z.
- **Tasks:** 2/2.
- **Files changed:** 8 plan files; three parent-owned planning state files remain unstaged and unchanged by this executor.

## Accomplishments

- Added `ClientLifetime.configured/0` as an internal adapter that validates selected client and transaction callbacks, the v1 client lifetime declaration, matching authority, and actual selected-client/transaction plus built-in PostgreSQL token, grant and audit participants.
- Routed DCR persistence, registration-access-token lookup, current-row locks, management replacement/deletion, shared-secret rotation and host recovery through the selected composition. Audit, token, grant and policy persistence remain on the built-in Repository peers.
- Kept endpoint error envelopes and current-row checks. Legacy v0 advisory timestamps can still be promoted and cleared; malformed v1 state and unknown versions fail closed.
- Moved selection validation ahead of initial access token redemption so invalid configuration cannot consume a credential before registration fails.
- Proved a deliberately late audit failure rolls the selected management replacement back, with unchanged client, audit and token observations and no success response.

## Verification

Elixir 1.18.4 / OTP 27.3.4.15 and the dedicated PostgreSQL database were used.

- Task 166-06-01 command: `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/integration/client_lifetime_selected_store_test.exs test/integration/management_token_lifetime_access_test.exs test/integration/management_token_lifetime_update_test.exs --max-failures 1 --timeout 55000` — **16 tests, 0 failures; no skips reported.** ExUnit did not report a separate excluded count for the included integration selection.
- Task 166-06-02 command: `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/integration/client_lifetime_selected_store_test.exs test/integration/client_secret_lifetime_rotation_test.exs test/integration/management_token_lifetime_recovery_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs --max-failures 1 --timeout 55000` — **24 tests, 0 failures; no skips reported.** ExUnit did not report a separate excluded count for the included integration selection.
- `mix format` on all modified Elixir files and `git diff --check` passed.
- Both RED evidence records passed `gsd-tools check tdd-red-evidence` with `RED_EVIDENCE_OK`. The first targeted route run established that configured registration returned 201 without the selected callback; the second established that invalid selection consumed the IAT before returning an error. The first raw console capture was sanitized to omit the generated response-body credentials; its TAP adaptation preserves the exact target assertion and result.
- RED/GREEN task commits are present: task 1 `9e72f55a` / `8bb4aee0`; task 2 `4bbe2f69` / `4f1da8cd`.

## Task Commits

1. **166-06-01 RED: selected DCR storage participation** — `9e72f55a` (`test`).
2. **166-06-01 GREEN: route DCR lifecycle through selected stores** — `8bb4aee0` (`feat`).
3. **166-06-02 RED: validate storage before IAT redemption** — `4bbe2f69` (`test`).
4. **166-06-02 GREEN: validate stores before IAT redemption** — `4f1da8cd` (`fix`).

## Decisions Made

- Use one internal validated composition at the registration and management boundaries. Host-selected client and transaction modules remain the only new selectors; internal dependency adapters stay private.
- Preserve built-in PostgreSQL token, grant and audit participants as named in the shared transaction authority.
- Treat v0 timestamps as advisory during host recovery and replacement. Validate unknown versions and authoritative v1 fields, then let credential replacement perform the existing whole-row v0 promotion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reject invalid storage before redeeming an initial access token**
- **Found during:** Task 166-06-02.
- **Issue:** Composition validation occurred inside persistence, after registration had already marked the single-use IAT as consumed.
- **Fix:** Validate the configured composition at the start of registration and return a server error before IAT redemption.
- **Files modified:** `lib/lockspire/protocol/registration.ex`, `test/integration/client_lifetime_selected_store_test.exs`.
- **Verification:** RED proved the IAT was consumed; GREEN passed the same targeted test with `used_at` still nil and the complete task 2 suite at 24 tests / 0 failures.
- **Committed in:** `4f1da8cd`.

**2. [Rule 1 - Bug] Preserve v0 advisory-date promotion in management**
- **Found during:** Task 166-01 verification.
- **Issue:** Applying the strict lifetime validator to locked management rows rejected legacy v0 rows with advisory dates, preventing the planned canonicalizing PUT.
- **Fix:** Keep existing `Client` eligibility as the management guard, allow v0 advisory dates through recovery for promotion, and continue rejecting unknown versions and malformed v1 data.
- **Files modified:** `lib/lockspire/protocol/registration_management.ex`, `test/integration/client_lifetime_selected_store_test.exs`.
- **Verification:** The full task 1 and task 2 suites passed, including the explicit v0 promotion regression.
- **Committed in:** `4f1da8cd`.

**Total deviations:** 2 auto-fixed bugs. **Impact:** Both changes preserve the fixed lifetime contract and prevent credential loss or legacy lockout.

## TDD Gate Compliance

- Task 166-06-01 has a classifier-validated RED assertion and separate RED/GREEN commits. The task's selected secret rotation and recovery call sites were routed in the same production commit because they share `ClientLifecycle` and `RegistrationManagement`; task 166-06-02 adds dedicated callback, rollback and recovery evidence for those paths.
- Task 166-06-02 has its own classifier-validated RED/GREEN pair for the newly found IAT mutation-order defect.
- No REFACTOR commit was needed.

## Issues Encountered

- The first targeted task 2 test run found a fixture omission (the admin rotation API requires explicit actor type); the test was corrected before accepting verification.
- A task 1 suite initially caught the v0 advisory-date regression described above. The implementation was corrected before final task verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The selected composition is ready for the independent packaged host proof in 166-08. This plan proves local routed behavior and rollback on the configured PostgreSQL-delegating test adapter; it does not claim package-included or independent durable-observer proof.

## Self-Check: PASSED

- All planned source and integration test files exist; the two RED evidence files exist and classify as `RED_EVIDENCE_OK`.
- Commits `9e72f55a`, `8bb4aee0`, `4bbe2f69` and `4f1da8cd` are ancestors of `HEAD`.
- `git rev-list --count ec81d54649c93cb40d061a7bf0df9aaa909569bb..4f1da8cdfec0234f27b0973b44895eef2de943b5` measured **4 task commits**. The plan's `actuals.tokens` is `9099` (36,397 changed-diff characters divided by four).
- Both plan verification commands passed with 16/0 and 24/0 tests/failures. Formatting and whitespace checks passed.
- The user-owned `.planning/STATE.md`, `.planning/state.json` and `.planning/ROADMAP.md` edits were not included in any plan commit.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-22*
