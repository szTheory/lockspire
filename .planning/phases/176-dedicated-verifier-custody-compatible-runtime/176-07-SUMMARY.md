---
phase: 176-dedicated-verifier-custody-compatible-runtime
plan: "07"
subsystem: testing
tags: [elixir, oauth, client-secret-jwt, rollout, runtime-acceptance]
requires:
  - phase: 175-accepted-baseline-verifier-compatibility-contract
    provides: Frozen compatibility baseline and stable case inventory
  - phase: 176-dedicated-verifier-custody-compatible-runtime
    provides: Dedicated verifier readers, writers, key/config support
provides:
  - Local staged-activation and old-code rollback-boundary tests
  - Host-facing verifier configuration and rollout guide linked from the JWT host guide
  - Source-bound runtime acceptance record for 22 owner-176 cases and pending owner-177/178 cases
affects: [phase-177-verifier-maintenance, phase-178-package-delivery]
actuals:
  tokens: 13320
  tasks: 2
  commits: 7
tech-stack:
  added: []
  patterns: [reader-first activation, real legacy and dedicated ciphertext transition checks]
key-files:
  created:
    - test/lockspire/security/client_secret_verifier_rollout_test.exs
    - docs/client-secret-verifier-configuration.md
    - .planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-RUNTIME-ACCEPTANCE.json
  modified:
    - docs/client-secret-jwt-host-guide.md
    - mix.exs
    - test/support/architecture/public_compatibility_manifest.ex
    - test/lockspire/compatibility_baseline_contract_test.exs
key-decisions:
  - "Prove the transition with actual old and new decoders, while keeping staging keys inactive until explicitly selected for writes."
  - "Record the full candidate gate and local limits as runtime evidence; fleet readiness and later-phase work remain pending."
patterns-established:
  - "Rollout tests use generated ciphertext and the historical decoder to make the rollback boundary observable."
requirements-completed: [SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, VUP-01, VUP-02]
coverage:
  - id: D1
    description: Staged activation, legacy compatibility, and post-write old-code incompatibility are exercised with real verifier outputs.
    requirement: SEC-03
    verification:
      - kind: unit
        ref: test/lockspire/security/client_secret_verifier_rollout_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Host teams can find the exact verifier configuration and rollout sequence.
    requirement: SEC-04
    verification:
      - kind: other
        ref: mix docs.verify
        status: pass
    human_judgment: false
  - id: D3
    description: Runtime evidence is source-bound and keeps frozen inputs and future-owner scopes explicit.
    verification:
      - kind: other
        ref: .planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-RUNTIME-ACCEPTANCE.json
        status: pass
    human_judgment: true
    rationale: Local tests do not establish fleet readiness, maintenance completion, package delivery, or publication authority.
duration: 34min
completed: 2026-10-25
status: complete
plan_head_before: d86049e9db354d390b847252aaa4196434804d5a
plan_head_after: cac96d09a9228d728b71846843912e58d529848e
commits: 7
---

# Phase 176 Plan 07: Runtime Rollout Acceptance Summary

Real verifier ciphertext now demonstrates reader-first staging, dedicated-write activation, and the point after which old code cannot read newly written dedicated data. The host guide and source-bound acceptance record preserve the operational limits.

## Performance

- **Duration:** about 34 minutes
- **Started:** 2026-10-25T22:38:50Z (approximate; first task activity)
- **Completed:** 2026-10-25T23:12:01Z
- **Tasks:** 2/2
- **Files modified:** 13

## Accomplishments

- Added rollout coverage for absent/staged configuration, reader-first deployment, allow/reject legacy writes, retained old keys, and switchback behavior. It checks legacy output with the historical decoder and proves dedicated ciphertext stays unreadable to old code after write-mode switchback.
- Added the exact runtime configuration and rollout guide, linked it from the existing JWT host guide, and included it in ExDoc navigation.
- Recorded all 22 owner-176 case outcomes against the passing candidate `mix ci` run at `b8cd395dd25ac0918678553aad042e8fd8f05d3c`. The literal 13-input frozen-hash verification passed. Owner-177 and owner-178 work remains pending; the three unclassified edges and three prohibition flags remain explicitly unresolved or unverified.
- Full candidate CI passed: 2 properties, 2,097 fast tests (0 failures, 6 skipped, 530 excluded), 231 integration tests (0 failures, 46 excluded), Credo across 703 source files, docs warnings-as-errors, dependency audit, and package build. The run used the selected Elixir/OTP pair, `ERL_FLAGS='+S 4'`, and the task-owned database. Test selection and concurrency assertions were unchanged.

## Task Commits

1. **Task 1: Exercise staged activation and publish bounded runtime guidance** - `5776d8dd`, `4df6d76d`, `78670563`, `3645e728`, `82b7b1ad`, `b8cd395d`
2. **Task 2: Record the full candidate acceptance evidence** - `cac96d09`

Each change was committed atomically with repository hooks. The candidate-gate reruns and fixes are itemized in the runtime acceptance JSON.

## Files Created/Modified

- `test/lockspire/security/client_secret_verifier_rollout_test.exs` - Real legacy/dedicated writer and decoder transition checks.
- `docs/client-secret-verifier-configuration.md` - Configuration grammar, envelope and age behavior, errors, and deployment sequence.
- `docs/client-secret-jwt-host-guide.md` and `mix.exs` - Reachable host-guide link and ExDoc navigation.
- `lib/lockspire/clients.ex`, `lib/lockspire/clients/secret_material.ex`, `lib/lockspire/security/client_secret_verifier/context.ex`, `test/integration/client_secret_verifier_direct_writer_test.exs` - Narrow candidate Credo fixes.
- `test/support/architecture/public_compatibility_manifest.ex` and `test/lockspire/compatibility_baseline_contract_test.exs` - Declare the four already-planned internal Config helper extensions without changing the literal historical baseline.
- `test/lockspire/web/live/admin/clients_live_test.exs` - Assert current typed form-error behavior instead of obsolete exception logging.
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-RUNTIME-ACCEPTANCE.json` - Candidate command results, case mapping, frozen-input outcome, and limits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Candidate guard regression] Declared the four existing internal Config helper extensions.**
- **Found during:** Task 2 candidate gate.
- **Issue:** The compatibility API guard rejected already-planned `@doc false` Config helpers because the extension manifest and its exact expectation omitted them.
- **Fix:** Added the four helper entries to the extension manifest and its guard expectation; the frozen historical baseline remained literal and unchanged. Both support files are outside the 13 frozen inputs.
- **Verification:** Candidate CI passed; frozen-input verification returned success.
- **Committed in:** `78670563`.

**2. [Rule 1 - Candidate lint issues] Cleared four Credo findings in Phase 176 touched code and tests.**
- **Found during:** Task 2 candidate gate.
- **Fix:** Applied behavior-preserving control-flow and complexity cleanups.
- **Files modified:** `lib/lockspire/clients.ex`, `lib/lockspire/clients/secret_material.ex`, `lib/lockspire/security/client_secret_verifier/context.ex`, `test/integration/client_secret_verifier_direct_writer_test.exs`.
- **Verification:** Scoped Credo passed; full candidate CI passed.
- **Committed in:** `3645e728`.

**3. [Rule 3 - Documentation gate] Registered the new guide with ExDoc.**
- **Found during:** Task 2 candidate gate.
- **Issue:** The host guide linked to a page missing from the ExDoc extras/navigation.
- **Fix:** Added the guide to the extras list and Integrate navigation.
- **Verification:** `mix docs.verify` and full candidate CI passed.
- **Committed in:** `82b7b1ad`.

**4. [Rule 1 - Stale assertion] Updated the empty-key admin test to match typed form errors.**
- **Found during:** Task 2 candidate gate.
- **Issue:** The test expected exception logging even though the current typed error path renders a form error and does not log an exception.
- **Fix:** Asserted the visible form error and absence of the obsolete log.
- **Verification:** Focused admin tests passed (29 tests); final full candidate CI passed.
- **Committed in:** `b8cd395d`.

**Total deviations:** 4 auto-fixed candidate-gate issues. All were narrow fixes in the owning surface; no dependency, schema, signing-byte, or supported-surface change was made.

## Issues Encountered

Earlier candidate runs exposed formatting, compatibility-manifest, lint, documentation, sandbox Git metadata, PostgreSQL connection, and stale assertion failures. The full history and exit outcomes are preserved in the acceptance JSON. The final full gate passed; a transient PostgreSQL `too_many_connections` warning remained, while both test stages completed without failures.

## User Setup Required

None.

## Next Phase Readiness

Local runtime configuration and the old-code rollback boundary have executable evidence. Phase 177 still owns maintenance, fleet readiness, retirement, recovery, and disclosure evidence; Phase 178 still owns package delivery. No fleet-readiness, backup, quiescence, rollback-safety, accepted-main, or publication claim is made here.

## Self-Check: PASSED

- Runtime acceptance JSON exists and parses; it names the tested SHA and records 22 owner-176 cases.
- The literal frozen-input and runtime-result verification command passed with exit 0.
- Task commits are present in the branch history; measured plan commit count and final head are recorded in the frontmatter.

---
*Phase: 176-dedicated-verifier-custody-compatible-runtime*
*Completed: 2026-10-25*
