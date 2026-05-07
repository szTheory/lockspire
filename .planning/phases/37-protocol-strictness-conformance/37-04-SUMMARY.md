---
phase: 37-protocol-strictness-conformance
plan: 4
subsystem: testing
tags: [oidf, conformance, integration-test, shell, github-actions, mix-alias, historical]

# Dependency graph
requires:
  - phase: 37-01
    provides: integer auth_time emission, DPoP strictness preservation
  - phase: 37-02
    provides: prompt=none hard gate, max_age/auth_time parsing, exact redirect enforcement
  - phase: 37-03
    provides: durable interaction auth_time, silent auth via durable freshness, auth_time in token exchange

provides:
  - Historical record of the Phase 37 strictness integration proof and OIDF harness wiring
  - Historical inventory of the skipped external-lane artifact bundle under `.artifacts/conformance/phase37`
  - Chronology for how the repo-native integration lane and optional external lane were originally packaged

affects:
  - phase 66 conformance-debt retirement
  - historical audit trail for Phase 37

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Repo-native integration tests ahead of external OIDF suite (historical wiring)
    - Two-lane conformance: integration proof lane vs. hosted maintainer suite
    - Mix alias for orchestrating integration proof + external suite sequentially
    - SKIP_SUITE env var for Docker-less local/worktree execution
    - Contract tests locking conformance wiring to executable proof

key-files:
  created:
    - test/integration/phase37_protocol_strictness_e2e_test.exs
    - scripts/conformance/run_phase37_suite.sh
    - scripts/conformance/phase37-plan.json
    - docs/maintainer-conformance.md
    - .github/workflows/oidf-conformance.yml
    - .artifacts/conformance/phase37/phase37-plan.json
    - .artifacts/conformance/phase37/run-summary.json
    - .artifacts/conformance/phase37/artifact-files.txt
  modified:
    - mix.exs (conformance.phase37 alias)
    - docs/supported-surface.md (Phase 37 strictness slice documented)
    - test/lockspire/release_readiness_contract_test.exs (Phase 37 conformance contract assertions)
    - scripts/conformance/run_phase37_suite.sh (LOCKSPIRE_PHASE37_SKIP_SUITE support)

key-decisions:
  - "Preserve this file as a historical summary rather than current completion proof for CONF-04."
  - "Treat `.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md` as the authoritative status record for the unresolved external-lane gap."
  - "Keep the skipped-suite artifact bundle for auditability, but do not present it as current conformance proof."

patterns-established:
  - "Historical conformance artifacts can remain in-repo if they are clearly demoted and linked to authoritative verification."
  - "Repo-native integration proof remains more trustworthy than preserved external-lane wiring alone."

requirements-completed: []

# Metrics
duration: 35min
completed: 2026-04-29
---

# Phase 37 Plan 4: Historical Strictness Proof and OIDF Harness Wiring Summary

**Historical record of the repo-native strictness proof lane and the originally wired, later-demoted external OIDF harness.**

## Historical Status

This summary is preserved for chronology and artifact inventory only.

Authoritative current status lives in [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md), which records that the external OIDF lane remained skipped with `LOCKSPIRE_PHASE37_SKIP_SUITE=true` and that `CONF-04` was not closed by this plan.

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-29T01:50:00Z
- **Completed:** 2026-04-29T02:05:00Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added a 5-test generated-host integration proof covering exact redirect rejection, `prompt=none`, stale `auth_time` under `max_age`, and fresh `auth_time` emission in ID tokens
- Wired `mix conformance.phase37` to run integration tests ahead of the optional external OIDF suite
- Added manual and scheduled workflow wiring plus maintainer docs for the historical external lane
- Preserved a Phase 37 artifact bundle under `.artifacts/conformance/phase37`

## Historical Outcome

- The repo-native integration proof from this plan remains useful historical implementation evidence.
- The external OIDF lane captured here is historical wiring, not authoritative completion proof.
- The checked-in artifact bundle was produced from the skip path, not a real suite run:
  `run-summary.json` records `LOCKSPIRE_PHASE37_SKIP_SUITE=true`, reports the suite as skipped, and shows `exported_files: []`.
- Readers evaluating whether `CONF-04` was actually satisfied should use [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md), which marks the requirement as unresolved in Phase 37.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add repo-native strictness integration proof** (TDD RED) - `160247d` (test)
2. **Task 1: Add repo-native strictness integration proof** (TDD GREEN) - `63f767d` (feat)
3. **Task 2: Wire the two-lane OIDF conformance harness** - `5de2a24` (feat)
4. **Task 2: Wire the two-lane OIDF conformance harness** (fix/stabilize) - `d256da1` (fix)
5. **Task 3: Capture phase 37 strictness proof artifacts** - `4b6664c` (feat)

## Files Created/Modified

- `test/integration/phase37_protocol_strictness_e2e_test.exs` - 5-test E2E integration proof for prompt=none, max_age, auth_time, and redirect strictness
- `scripts/conformance/run_phase37_suite.sh` - Docker-first harness entrypoint with historical `LOCKSPIRE_PHASE37_SKIP_SUITE=true` support
- `scripts/conformance/phase37-plan.json` - OIDF plan subset for the external lane
- `docs/maintainer-conformance.md` - Maintainer workflow and prerequisites for the historical lane
- `docs/supported-surface.md` - Phase 37 strictness slice documented
- `mix.exs` - `conformance.phase37` alias wiring integration test plus harness script
- `.github/workflows/oidf-conformance.yml` - Manual and scheduled external-lane workflow
- `test/lockspire/release_readiness_contract_test.exs` - Conformance lane contract assertions
- `.artifacts/conformance/phase37/phase37-plan.json` - Historical plan copy in the artifact bundle
- `.artifacts/conformance/phase37/run-summary.json` - Historical skipped-suite run summary
- `.artifacts/conformance/phase37/artifact-files.txt` - Historical artifact index

## Decisions Made

- Integration tests were treated as the repo-native center of gravity for strictness proof
- `mix conformance.phase37` was designed to run integration tests before the slower external suite
- The external lane was kept outside PR CI and exposed through manual and scheduled workflow paths
- This summary is now explicitly historical, with authoritative verification deferred to [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `LOCKSPIRE_PHASE37_SKIP_SUITE=true` mode to the harness script**
- **Found during:** Task 3 (Run the repo-native OIDF lane and capture proof artifacts)
- **Issue:** Docker daemon unavailable in the worktree execution environment
- **Fix:** Added a skip path that creates the artifact structure and exits cleanly without running the external suite
- **Files modified:** `scripts/conformance/run_phase37_suite.sh`
- **Verification:** `bash -n scripts/conformance/run_phase37_suite.sh` passed; `LOCKSPIRE_PHASE37_SKIP_SUITE=true MIX_ENV=test mix conformance.phase37` exited 0 with integration tests passing and artifacts saved
- **Committed in:** `4b6664c`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The repo-native integration lane was captured successfully, but the external OIDF lane remained historical skipped-lane wiring rather than completion proof.

## Issues Encountered

- A later verification pass found that the saved artifact bundle came from skip mode and did not satisfy `CONF-04`; see [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md)
- The same verification pass recorded a separate test-database pollution issue caused by the harness key insertion path; this summary preserves the original chronology but is not the authoritative status record for that gap

## Known Stubs

- `.artifacts/conformance/phase37/run-summary.json` is a historical skip-mode artifact, not proof of a real OIDF suite run

## Threat Flags

None - this file is historical documentation only and now explicitly avoids widening current support claims.

## Self-Check

This historical summary points to [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md) for authoritative status and no longer claims `CONF-04` completion.

## Self-Check: PASSED

## Next Phase Readiness

- The implementation chronology from Plan 4 remains preserved for auditability
- Current truth about the unresolved external-lane gap should be taken from [37-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/37-protocol-strictness-conformance/37-VERIFICATION.md), not from this historical summary

---
*Phase: 37-protocol-strictness-conformance*
*Completed: 2026-04-29*
