---
phase: 115-repo-hygiene-gate-scoped-cleanup
plan: 02
subsystem: tooling
tags: [repo-hygiene, docker, adoption-demo, ci, exunit]

requires:
  - phase: 115-repo-hygiene-gate-scoped-cleanup
    provides: Plan 01 adoption demo docker-stop and docker-cleanup lifecycle helpers
provides:
  - local adoption demo Docker and generated-artifact hygiene reporting
  - Docker-free deterministic CI source contracts for cleanup and smoke boundaries
  - release-readiness contracts for Phase 115 hygiene and public-surface boundaries
affects: [phase-115, release-hygiene, adoption-demo, ci]

tech-stack:
  added: []
  patterns:
    - Bash repo hygiene helpers with local-vs-CI mode separation
    - ExUnit source contracts for maintainer script boundaries

key-files:
  created:
    - .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-02-SUMMARY.md
  modified:
    - scripts/maintainer/repo_hygiene_check.sh
    - test/lockspire/release_readiness_contract_test.exs

key-decisions:
  - "Local hygiene accepts --project and resolves active project from --project, COMPOSE_PROJECT_NAME, then lockspire-adoption-demo."
  - "CI hygiene remains daemon-free and validates checked-in cleanup, reset, smoke, and public-surface contracts only."
  - "Demo Docker leftovers and generated artifacts are reported with PASS/WARN/BLOCK without deleting resources."

patterns-established:
  - "Docker daemon inspection is isolated to local_demo_docker_hygiene_checks and skipped entirely in --ci mode."
  - "Repo hygiene output names exact remediation commands for active-project demo leftovers."

requirements-completed: [SMOKE-03, HYGIENE-01, HYGIENE-02, HYGIENE-03, HYGIENE-04, BOUNDARY-01, BOUNDARY-02]

duration: 5min
completed: 2026-06-24
status: complete
---

# Phase 115 Plan 02: Repo Hygiene Gate Summary

**Local adoption-demo hygiene now reports scoped Docker leftovers and generated artifacts, while CI proves cleanup and smoke boundaries without daemon access.**

## Performance

- **Duration:** 5min
- **Started:** 2026-06-24T17:52:00Z
- **Completed:** 2026-06-24T17:56:45Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments

- Added release-readiness contracts for Phase 115 local-vs-CI hygiene, `--project` precedence, Docker cleanup boundaries, generated artifact preservation, and no public-surface expansion.
- Extended `scripts/maintainer/repo_hygiene_check.sh` with `--project`, local Docker state reporting, local generated-artifact reporting, and exact remediation strings for `docker-stop` and `docker-cleanup --execute`.
- Added deterministic `--ci` source contracts for lifecycle helper allowlists, dry-run cleanup, smoke wrapper delegation, reset scope, and repo-local support boundaries.

## Task Commits

1. **Task 1: Add RED hygiene and boundary contracts** - `f012f5c` (test)
2. **Task 2: Implement local Docker and artifact hygiene checks** - `41fb3fd` (feat)
3. **Task 3 RED: Add deterministic CI source-contract tests** - `ed43e65` (test)
4. **Task 3 GREEN: Add deterministic CI source-contract checks** - `0653eca` (feat)

## Files Created/Modified

- `scripts/maintainer/repo_hygiene_check.sh` - Added active-project argument parsing, local demo Docker/artifact hygiene checks, and deterministic CI source contracts.
- `test/lockspire/release_readiness_contract_test.exs` - Added Phase 115 release-readiness contracts for hygiene behavior, CI boundaries, smoke proof, and public-surface limits.
- `.planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-02-SUMMARY.md` - Plan execution summary.

## Decisions Made

- Kept Docker daemon calls out of `--ci`; CI checks only checked-in shell, workflow, and smoke source facts.
- Classified running active-project containers as `BLOCK`, stopped containers/volumes/artifacts as triage findings, and Docker unavailable locally as `WARN`.
- Preserved `tmp/admin-ui-polish/` as useful admin UI evidence outside default cleanup scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Contract] Removed contradictory public-surface assertion wording**
- **Found during:** Task 3
- **Issue:** The new RED contract required the exact phrase `production Docker packaging` in the hygiene script while an existing boundary contract forbade that phrase in the same file.
- **Fix:** Reworded the new source contract to assert `packaged Docker surface`, preserving the boundary without embedding a forbidden public-claim phrase.
- **Files modified:** `test/lockspire/release_readiness_contract_test.exs`, `scripts/maintainer/repo_hygiene_check.sh`
- **Verification:** `mix test test/lockspire/release_readiness_contract_test.exs --seed 0`
- **Committed in:** `0653eca`

**Total deviations:** 1 auto-fixed.
**Impact on plan:** No scope expansion; the correction removed contradictory wording while keeping the intended boundary proof.

## Issues Encountered

- `./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci` exited nonzero because existing local hygiene checks reported a dirty working tree and latest main CI not green. The dirty state includes the unrelated pre-existing `.gitignore` modification, which was left untouched and uncommitted as required.
- The same local command showed the new demo hygiene behavior: no running/stopped active-project containers, WARN for existing active-project volumes, WARN for allowlisted generated artifacts, and PASS for preserved `tmp/admin-ui-polish/`.
- The focused ExUnit run logs the existing KeyCache/TestRepo startup message, but the suite passes.

## Verification

- `bash -n scripts/maintainer/repo_hygiene_check.sh` - passed.
- `bash ./scripts/maintainer/repo_hygiene_check.sh --ci` - passed with 14 PASS, 0 WARN, 0 BLOCK.
- `mix test test/lockspire/release_readiness_contract_test.exs --seed 0` - passed, 41 tests, 0 failures.
- `./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci` - demo hygiene checks ran, but command exited nonzero due unrelated broader local blockers described above.

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

No new unplanned threat surface. The planned local shell-to-Docker inspection surface is isolated from CI mode, uses Compose project labels for reporting, names exact active-project remediation commands, and avoids printing secrets.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can align docs and final lifecycle proof on top of the committed hygiene checks. The unrelated `.gitignore` modification remains unmodified and uncommitted.

## Self-Check: PASSED

- Found `scripts/maintainer/repo_hygiene_check.sh`.
- Found `test/lockspire/release_readiness_contract_test.exs`.
- Found `.planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-02-SUMMARY.md`.
- Verified commits `f012f5c`, `41fb3fd`, `ed43e65`, and `0653eca` in git history.
- Confirmed `.gitignore` was not staged or committed by this plan.

---
*Phase: 115-repo-hygiene-gate-scoped-cleanup*
*Completed: 2026-06-24*
