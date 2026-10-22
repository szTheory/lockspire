---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "03"
subsystem: testing
tags: [elixir, postgres, dcr, oauth, lifetime-boundaries]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed lifetime boundary and management case contract
  - phase: 163-app-lifetime-compatible-host-storage
    provides: App lifetime enforcement and injectable protocol clocks
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: Shared-secret expiry and rotation
  - phase: 165-management-token-lifecycle-recovery
    provides: Management token expiry and host recovery
provides:
  - Integrated proof that secret rotation and management recovery preserve unrelated deadlines
  - Nonmasking app-expiry, expired-secret, disabled-state, read, update, delete, and enablement interactions
  - Candidate-bound focused test counts and case references for this plan's deterministic boundary evidence
affects: [phase-166-final-proof, dcr-lifetime-evidence]
actuals:
  tokens: 4899
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 280a92cacf6941272714f90350e658b73bacb3d7
plan_head_after: d3a42e5b6c54cba391a6c38a61ea2e623cf0eaa1
tech-stack:
  added: []
  patterns: [fixed protocol clocks, independent durable client rows, measured case-linked evidence]
key-files:
  created:
    - test/integration/client_lifetime_interactions_test.exs
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-BOUNDARY-EVIDENCE.json
  modified: []
key-decisions:
  - "Keep protocol time controls inside existing test and protocol interfaces; no public route, header, dependency or production clock was added."
  - "Use separate persisted clients and credential deadlines so an expired secret cannot mask app-management boundary outcomes."
  - "Record the 32 successful test invocations as a sum across overlapping selections, not as a unique test count."
patterns-established:
  - "Compose secret rotation, management recovery and app expiry with the existing injected protocol clocks and persisted rows."
  - "Keep focused evidence candidate-bound and disclose that local boundary runs do not establish package, CI or review gates."
requirements-completed: [DCR-15, DCR-18]
coverage:
  - id: D1
    description: "Independent lifetime renewal and nonmasking app-expiry interactions across registration, rotation, recovery, read, update, delete, disable and enable."
    requirement: DCR-15
    verification:
      - kind: integration
        ref: test/integration/client_lifetime_interactions_test.exs#independent app and management gates
        status: pass
      - kind: integration
        ref: test/integration/client_lifetime_interactions_test.exs#replacement events renew only their own snapshot
        status: pass
    human_judgment: false
  - id: D2
    description: "Measured focused local evidence for policy boundaries, credential authentication, rejected redemption, and online/offline token limits."
    requirement: DCR-18
    verification:
      - kind: integration
        ref: .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-BOUNDARY-EVIDENCE.json
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-10-22
status: complete
---

# Phase 166 Plan 03: Independent Lifetime Interaction Proof Summary

**Focused integration tests prove that credential replacement preserves unrelated lifetime deadlines and that expired app, secret, and management gates remain independent at their exact boundaries.**

## Performance

- **Duration:** Approximately 5 minutes.
- **Started:** Approximately 2026-10-22T00:13:00Z.
- **Completed:** 2026-10-22T00:17:44Z.
- **Tasks:** 2/2.
- **Files modified:** 3 (two created artifacts and this summary).

## Accomplishments

- Registered a client under app/secret/management durations 60/10/20 at the injected second 100, then changed the prospective policy and proved secret rotation at 107 changes only the secret deadline and host recovery at 125 changes only the management deadline.
- Proved the expired secret at 110 does not mask app equality at 160: a recovered management credential can read and delete the enabled expired app, while PUT returns `registration_expired` without changing the row. Disablement still denies management; enabling does not clear the app deadline.
- Reran the focused policy/auth/JWT selection and added the existing code-redemption and online-consumer selections. The evidence records 32 successful test invocations across three overlapping commands, with 0 failures, 0 excluded tests, and 0 skipped tests.

## Verification

- `mix test.setup` with the inherited Elixir 1.18.4/OTP 27.3.4.15 environment and `lockspire_phase165_validation` database — migrations already up.
- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --include integration test/integration/client_lifetime_interactions_test.exs --max-failures 1 --timeout 55000` — **2 tests, 0 failures, 0 excluded, 0 skipped**; measured command duration 1 second.
- Prescribed combined policy/auth/JWT/interactions selection from Task 2 — **19 tests, 0 failures, 0 excluded, 0 skipped**; measured command duration 1 second.
- Additional `app_lifetime_code_redemption_test.exs`, `app_lifetime_online_consumers_test.exs`, and `client_secret_lifetime_jwt_boundary_test.exs` selection — **11 tests, 0 failures, 0 excluded, 0 skipped**; measured command duration 1 second. It retains evidence for rejected code redemption preserving the grant, current online checks, offline JWT limitations, and independent assertion/replay boundaries.
- Boundary evidence JSON validation confirmed all IDs exist in the Phase 162 contract, the candidate revision matches the tested source commit, and recorded totals reconcile. `git diff --check` passed.

The local deterministic runs do not prove packaged HTTP lifetime duration behavior, live required CI, or independent security review. Those gates remain with later Phase 166 plans. No public time control or runtime change was introduced.

## Task Commits

1. **166-03-01: Expose independent equality gates and prospective renewal interactions** — `442a41b1` (`test`).
2. **Task 1 contract-label correction** — `3ea8e3c2` (`fix`).
3. **Task 1 fixed case references and formatting** — `3adbdedc` (`test`).
4. **166-03-02: Rerun focused boundary and security intersections with honest counts** — `d3a42e5b` (`docs`).

**Plan metadata:** To be recorded in the plan-summary commit.

## Files Created

- `test/integration/client_lifetime_interactions_test.exs` — Fixed-clock interactions for independent snapshots, recovery, equality, and enablement.
- `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-BOUNDARY-EVIDENCE.json` — Candidate-bound commands, fixed contract cases, positive counts, exclusions, skips, and evidence limits.

## Decisions Made

- Kept proof limited to existing injected protocol clocks and persisted test rows. HTTP code-redemption and online/offline cases reuse their focused suites rather than duplicating their complete assertions in the new integration module.
- Counted repeated test selections as invocations and documented overlap instead of presenting the sum as a unique-test total.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test evidence correction] Replaced a locally invented test label with fixed Phase 162 case identifiers**
- **Found during:** Task 1.
- **Issue:** An early interaction label was not a fixed case ID, which could misstate contract traceability.
- **Fix:** Restricted test labels to established C-POL, C-APP, and C-MGMT IDs and formatted the test file.
- **Files modified:** `test/integration/client_lifetime_interactions_test.exs`.
- **Verification:** The standalone and combined selected suites passed after the final test-source commit.
- **Committed in:** `3ea8e3c2`, `3adbdedc`.

**Total deviations:** 1 evidence correction. **Impact:** Traceability is exact; no protocol or production scope was added.

## Issues Encountered

The sandbox initially denied direct `.git` index writes. The authorized task commits completed after an explicit sandbox escalation; no other working-tree changes were staged.

## User Setup Required

None - the focused integration tests use the repository's configured PostgreSQL test database.

## Next Phase Readiness

Plan 166-03 is complete. The independent, candidate-bound proof is ready for later Phase 166 package, CI, security-review, and requirements aggregation; it does not close those broader gates.

## Self-Check: PASSED

- The integration test and boundary evidence JSON exist.
- Task commits `442a41b1`, `3ea8e3c2`, `3adbdedc`, and `d3a42e5b` are ancestors of the tested candidate revision and current plan head.
- The documented standalone, combined, and supplemental focused commands passed with positive test counts.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-22*
