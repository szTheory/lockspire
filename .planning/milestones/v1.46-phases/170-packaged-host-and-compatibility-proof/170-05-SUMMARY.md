---
phase: 170-packaged-host-and-compatibility-proof
plan: "05"
subsystem: packaged-host-proof
tags: [phoenix, liveview, chrome, cdp, compatibility, acceptance]
requires:
  - phase: 170-04
    provides: Bounded pair wrapper, strict safe receipts, and required CI job wiring.
provides:
  - Maintainer commands and evidence limits for the locked and exact-floor proof pairs.
  - Final six-cell package/browser acceptance matrix and per-criterion UAT closure ledger.
  - Regression guardrails that permit safe Phoenix LiveView link-state metadata while retaining OAuth-state checks.
affects: [phase-170-verification, maintainer-docs, compatibility-proof]
actuals:
  tokens: 7612
  tasks: 2
  commits: 2
plan_head_before: 2bf1fdc2375cee6b3853ee24677a82b6f557388d
plan_head_after: e96536ac04076da2ca2967fefc7c9f7797ac3276
commits: 2
tech-stack:
  added: []
  patterns:
    - Separate exact dependency lifecycle evidence from real browser/CDP transport receipts.
    - Bind each acceptance claim to source, candidate archive/tree, pair, mount, scenario set, and cleanup evidence.
key-files:
  created:
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-ACCEPTANCE.md
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-UAT.md
  modified:
    - docs/supported-surface.md
    - docs/maintainer-release.md
    - test/lockspire/documentation_contract_test.exs
    - test/lockspire/host_integration_ci_contract_test.exs
    - test/lockspire/web/live/admin/interactions_live_test.exs
    - test/lockspire/web/live/admin/device_authorizations_live_test.exs
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-VALIDATION.md
key-decisions:
  - Keep local Elixir/OTP observations distinct from CI BEAM and PostgreSQL expectations; no remote job was observed.
  - Preserve host-owned identity/policy and the unconditional generated authorization deny default; synthetic authority remains in the disposable proof host.
  - Exclude only Phoenix's `data-phx-link-state` navigation mode from protocol field-name scans; keep raw-state and token sentinel assertions.
patterns-established:
  - Record each phase requirement, roadmap criterion, prohibition, and unclassified assumption separately with source, method, result, and limits.
requirements-completed: [HPROOF-01, HPROOF-02, HPROOF-03]
coverage:
  - id: D1
    description: Maintainers can run the exact locked and floor packaged proof using the canonical documented commands.
    requirement: HPROOF-01
    verification:
      - kind: integration
        ref: .planning/phases/170-packaged-host-and-compatibility-proof/170-ACCEPTANCE.md (six validated package/browser cells)
        status: pass
      - kind: unit
        ref: test/lockspire/documentation_contract_test.exs (9 passed)
        status: pass
    human_judgment: false
  - id: D2
    description: Both exact dependency pairs have current lifecycle and packaged browser evidence at all three mounts.
    requirement: HPROOF-02
    verification:
      - kind: integration
        ref: .artifacts/phase170/final-locked and .artifacts/phase170/final-floor (43 and 44 lifecycle tests; 3 × 16 browser cases per pair)
        status: pass
    human_judgment: false
  - id: D3
    description: Required workflow wiring and safe receipt failure paths are contract-tested without claiming hosted execution.
    requirement: HPROOF-03
    verification:
      - kind: unit
        ref: test/lockspire/host_integration_ci_contract_test.exs (included in 13 focused tests)
        status: pass
      - kind: integration
        ref: scripts/ci/run_host_integration_proof.sh local locked/floor executions; no remote run observed
        status: pass
    human_judgment: false
duration: "~3h 41m"
completed: 2026-10-24
status: complete
---

# Phase 170 Plan 05: Final Compatibility Evidence Summary

**Locked and exact-floor packaged host proofs are documented and recorded across all six mount/version cells, with local evidence clearly separated from CI expectations.**

## Performance

- **Duration:** approximately 3h 41m.
- **Started:** approximately 2026-10-24T03:42:00Z.
- **Completed:** 2026-10-24T07:23:25Z.
- **Tasks:** 2/2.
- **Files modified:** 9.

## Accomplishments

- Documented exact `locked` and `floor` wrapper commands, tool and database prerequisites, receipt behavior, and evidence boundaries in the supported-surface and maintainer release guides.
- Recorded six current browser matrix cells. The locked run passed 43 lifecycle tests and all 16 browser cases at each of three mounts in 137 seconds; the floor run passed 44 lifecycle tests and all 16 cases at each mount in 138 seconds.
- Recorded exact candidate hashes, source revisions, actual local Phoenix/LiveView/Elixir/OTP/Node/Chrome versions, expected CI runtimes, and the fact that no remote workflow was observed in [170-ACCEPTANCE.md](170-ACCEPTANCE.md).
- Closed HPROOF-01/02/03, the four roadmap success criteria, the five plan-level criteria, and both explicit prohibitions with individual evidence and limits in [170-UAT.md](170-UAT.md). A-170-01 and A-170-02 remain unclassified; no extra predicate or result was invented.
- Passed the final fresh-database broad suite: 2,027 passed (2 properties, 2,025 tests), 6 skipped, and 497 excluded. The six skipped and 497 excluded are existing suite selection outcomes; this plan introduced no skipped test.

## Verification

- Locked wrapper: passed in 137 seconds, 43 lifecycle tests, three mounts × 16 cases; all receipt identity and cleanup checks passed.
- Floor wrapper: passed in 138 seconds, 44 lifecycle tests, three mounts × 16 cases; actual Phoenix 1.8.5 / LiveView 1.1.28 confirmed.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/documentation_contract_test.exs` — 9 passed.
- `node --test test/browser/packaged_admin_proof_test.mjs` — 7 passed.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` — 28 passed.
- Fresh-database interactions/device authorization guardrail suites — 21 passed after the narrow false-positive correction.
- `asdf exec mix test test/lockspire/host_integration_ci_contract_test.exs test/lockspire/documentation_contract_test.exs` — 13 passed.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` — passed.
- `LOCKSPIRE_TEST_DB_NAME=lockspire_phase170_plan05_final_20261024 HEX_HOME=/private/tmp/lockspire-phase170-hex-home ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` — 2,027 passed; exit 0.
- `git diff --check acda9da47b141978a2a05c2ac795058257f93888` — passed.
- No hosted CI run was dispatched or observed. The actual local BEAM was Elixir 1.20.4 / OTP 29; CI expectations remain Elixir 1.19.5 / OTP 28 with PostgreSQL 16 for locked, and Elixir 1.18.4 / OTP 27 with PostgreSQL 14 for floor.

## Task Commits

1. **Task 1: Document exact proof commands and evidence interpretation** — `c7fcdb37`.
2. **Task 2: Refresh acceptance evidence and close the criterion ledger** — `e96536ac`.

## Files Created/Modified

- `docs/supported-surface.md` — current package/browser/runtime support evidence and limits.
- `docs/maintainer-release.md` — exact pair commands, prerequisites, and safe receipt interpretation.
- `test/lockspire/documentation_contract_test.exs` — durable command and wrapper-link contract.
- `test/lockspire/web/live/admin/interactions_live_test.exs` — field-context redaction assertion allowing only safe LiveView link metadata.
- `test/lockspire/web/live/admin/device_authorizations_live_test.exs` — same narrow field-context assertion.
- `test/lockspire/host_integration_ci_contract_test.exs` — formatter-only cleanup of a phase-owned contract test.
- `170-ACCEPTANCE.md`, `170-UAT.md`, and `170-VALIDATION.md` — final six-cell evidence, individual closure ledger, and actual validation results.

## Decisions Made

- Pair lifecycle receipts and browser receipts stay distinct and carry the exact tested source/package/runtime identities.
- A local pass establishes the recorded local scope only; it does not establish a remote CI result.
- Host policy, account identity, login, layout, and branding remain owned by adopters; generated authorization still denies access by default.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test guard false positive] Permit safe Phoenix navigation metadata in protocol field checks**
- **Found during:** Task 2.
- **Issue:** The broad `state=` pattern matched Phoenix's `data-phx-link-state="push"` / `"replace"` attribute after Plan 02 changed existing admin links to native LiveView navigation. This was navigation metadata, not OAuth state exposure.
- **Fix:** Remove only the exact safe framework attribute before checking protocol field-name context. Existing raw-state, nonce, token, and other sentinel assertions remain active.
- **Files modified:** `test/lockspire/web/live/admin/interactions_live_test.exs`, `test/lockspire/web/live/admin/device_authorizations_live_test.exs`.
- **Verification:** Both affected suites passed 21 tests on a fresh database; the full fresh-database `mix test.fast` passed 2,027 checks.
- **Committed in:** `e96536ac`.

**2. [Rule 1 - Formatting] Format the phase-owned CI contract test**
- **Found during:** Task 2.
- **Issue:** The required whole-project formatter check found long assertions in the Plan 04 CI contract test, which was created in this same phase.
- **Fix:** Ran `mix format` on that test file only; no behavior changed.
- **Files modified:** `test/lockspire/host_integration_ci_contract_test.exs`.
- **Verification:** Whole-project `mix format --check-formatted` and focused CI/documentation contract tests passed.
- **Committed in:** `e96536ac`.

**Total deviations:** 2 auto-fixed (2 Rule 1).
**Impact on plan:** Both fixes were required for accurate existing regression checks; no product behavior or remote workflow changed.

## Issues Encountered

- An initial broad run reused the shared test database and showed row-count failures; the isolated Hex cache fixed separate release-test access errors. A final run with a fresh dedicated test DB and writable task-specific `HEX_HOME` passed.
- The final checkouts remain locally marked dirty because `.planning/state.json` was deliberately preserved byte-for-byte from the supplied snapshot.

## User Setup Required

None. No external service configuration or remote action was performed.

## Next Phase Readiness

- Phase-level security, code-review, and goal verification remain for the orchestrator. Do not infer a hosted CI result from the local evidence.
- Both exact local pairs and the final six-cell browser matrix are ready for phase verification.

## Known Stubs

None found in files created or modified by this plan.

## Self-Check: PASSED

- All key files and the summary exist on disk.
- Task commits `c7fcdb37` and `e96536ac` are ancestors of the plan head.
- The persisted plan ledger measures exactly 2 task commits before the summary commit.

---
*Phase: 170-packaged-host-and-compatibility-proof*
*Completed: 2026-10-24*
