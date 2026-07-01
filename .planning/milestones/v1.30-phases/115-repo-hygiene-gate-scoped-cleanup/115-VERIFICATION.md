---
phase: 115-repo-hygiene-gate-scoped-cleanup
verified: 2026-06-24T18:06:54Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 115: Repo Hygiene Gate & Scoped Cleanup Verification Report

**Phase Goal:** Close v1.30 by making adoption-demo cleanup and repo hygiene explicit, scoped, and non-destructive by default.
**Verified:** 2026-06-24T18:06:54Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | CLEAN-01: stop preserves volumes. | VERIFIED | `examples/adoption_demo/bin/docker-stop` resolves `--project` / `COMPOSE_PROJECT_NAME` / default project and runs `docker compose --project-name "$project" -f examples/adoption_demo/docker-compose.yml down` with no volume deletion flag. See lines 6-18 and 56-58. Contract test covers this at `test/lockspire/adoption_demo_docker_contract_test.exs` lines 245-265. |
| 2 | CLEAN-02: reset intentionally rebuilds active project database/cache state only. | VERIFIED | `docker-reset` removes only `${project}_db_data`, `${project}_deps_volume`, and `${project}_build_volume`, lines 55-59. Contract test asserts the exact suffix set and forbids broad prune/down-volume commands, lines 222-243. |
| 3 | CLEAN-03: cleanup removes only allowlisted demo-owned resources/artifacts and is execute-gated. | VERIFIED | `docker-cleanup` defaults `execute=0`, requires `--execute`, reports candidates first, then removes only exact active-project volumes and `tmp/adoption_demo.log`, `examples/adoption_demo/_build`, `examples/adoption_demo/deps`, lines 28-43 and 71-103. Dry-run command printed candidates and did not delete. |
| 4 | HYGIENE-01: local hygiene reports demo Docker leftovers/artifacts with PASS/WARN/BLOCK. | VERIFIED | `repo_hygiene_check.sh` has `record_result` PASS/WARN/BLOCK accounting, local Docker checks, local artifact checks, and remediation strings, lines 70-82, 260-314, 416-417. Local run reported PASS for all demo-owned checks after cleanup. |
| 5 | HYGIENE-02: `--ci` hygiene is Docker-daemon-free. | VERIFIED | `repo_hygiene_check.sh` calls local Docker checks only when `MODE != ci`, lines 420-424. Contract test splits the CI branch and refutes Docker daemon inspection, lines 591-615. Fresh `bash ./scripts/maintainer/repo_hygiene_check.sh --ci` passed with 14 PASS, 0 WARN, 0 BLOCK. |
| 6 | HYGIENE-03: `tmp/admin-ui-polish/` is preserved unless explicitly named. | VERIFIED | Cleanup help/source says it is preserved and out of cleanup scope, `docker-cleanup` lines 23-24 and 86. Hygiene always records admin UI evidence as preserved, lines 309-313. Contracts assert it is present in help/source and not removed, lines 309-318 and 653-669. |
| 7 | HYGIENE-04: lifecycle proof exists and can leave no demo-owned BLOCK findings. | VERIFIED | Docs define start -> smoke -> stop -> cleanup -> hygiene, lines 139-151. Plan 03 summary records a Docker 29.5.2 local proof that start, smoke, stop, cleanup, hygiene left no demo-owned findings. Fresh local hygiene run showed no running/stopped demo containers, no active-project demo volumes, no allowlisted generated demo artifacts, and admin UI evidence preserved; unrelated repo-wide blockers remained separate. |
| 8 | SMOKE-03: CI keeps existing adoption-demo smoke and adds only deterministic Docker validation. | VERIFIED | CI release-hygiene runs `bash ./scripts/maintainer/repo_hygiene_check.sh --ci`, lines 21-30. Adoption Demo Smoke still runs host-local Phoenix and `python3 scripts/demo/adoption_smoke.py`, lines 251-267. Contract tests refute `docker compose` in CI and assert deterministic Docker validation, lines 672-705. |
| 9 | BOUNDARY-01: no protocol/admin UI/production Docker/hosted-auth broadening. | VERIFIED | Phase files modified shell/docs/tests/CI only. No `lib/mix/tasks/*cleanup*`, `*hygiene*`, `lib/lockspire/repo_hygiene.ex`, or `lib/lockspire/docker_cleanup.ex` exists. Boundary tests assert no protocol/admin behavior, packaged Docker surface, or hosted-auth support expansion, lines 707-752. |
| 10 | BOUNDARY-02: adoption demo remains repo-local proof and does not broaden public support. | VERIFIED | `docs/adoption-demo.md` states the demo is repo-local proof, not production deployment, not hosted authentication, and not support-contract expansion, lines 3-15. Contract test pins those claims, lines 726-738. |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `examples/adoption_demo/bin/docker-stop` | Stop helper preserving project volumes | VERIFIED | Exists, executable by contract, substantive, and wired in docs/tests. `gsd verify.artifacts` passed. |
| `examples/adoption_demo/bin/docker-reset` | Active-project volume reset only | VERIFIED | Existing helper remains scoped to three suffixes; tested and syntax-checked. |
| `examples/adoption_demo/bin/docker-cleanup` | Dry-run-first scoped cleanup helper | VERIFIED | Exists, executable by contract, substantive, and wired in docs/hygiene/tests. `gsd verify.artifacts` passed. |
| `scripts/maintainer/repo_hygiene_check.sh` | Local demo hygiene plus Docker-free CI hygiene | VERIFIED | Exists, substantive, syntax-checked, and run in CI workflow. `gsd verify.artifacts` passed. |
| `docs/adoption-demo.md` | Final lifecycle, hygiene, and boundary docs | VERIFIED | Contains stop/reset/cleanup/hygiene commands, lifecycle proof, CI boundary, and repo-local boundary. |
| `test/lockspire/adoption_demo_docker_contract_test.exs` | Docker/docs lifecycle contracts | VERIFIED | Focused contract suite passed. |
| `test/lockspire/release_readiness_contract_test.exs` | Hygiene, CI, and boundary contracts | VERIFIED | Focused contract suite passed. `gsd verify.artifacts` had a false negative for literal `repo-local proof`; manual review verifies equivalent boundary strings. |
| `.github/workflows/ci.yml` | Deterministic hygiene and existing adoption smoke | VERIFIED | `release-hygiene` runs `--ci`; `adoption-demo` runs Python smoke, no Docker Compose smoke. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `docker-stop` | `docker-compose.yml` | `docker compose --project-name "$project" -f examples/adoption_demo/docker-compose.yml down` | VERIFIED | Manual source check and `gsd verify.key-links` passed. |
| `docker-cleanup` | `docker-reset` | Shared active-project `db_data`, `deps_volume`, `build_volume` allowlist | VERIFIED | Manual source check and `gsd verify.key-links` passed. |
| `repo_hygiene_check.sh` | `docker-cleanup` | WARN/BLOCK remediation names scoped cleanup command | VERIFIED | Hygiene script lines 281-304 name `docker-cleanup --project $project --execute`; `gsd verify.key-links` passed. |
| `repo_hygiene_check.sh` | `.github/workflows/ci.yml` | CI release hygiene runs `--ci` | VERIFIED | Manual grep verifies workflow line 30. `gsd verify.key-links` false-negative came from escaped pattern text in PLAN. |
| `docs/adoption-demo.md` | `docker-stop` / hygiene | Docs command surface uses helpers | VERIFIED | Docs lines 56-151 name stop, cleanup, hygiene, and lifecycle commands. Escaped PLAN pattern caused a tool false negative; manual source check passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `repo_hygiene_check.sh` | Docker state and artifact path findings | Local Docker CLI label/name filters; repo path existence checks | Yes in local mode; skipped in `--ci` | VERIFIED |
| `docker-cleanup` | Cleanup candidate volumes/artifacts | Resolved active project plus static allowlists | Yes; dry run prints exact candidates | VERIFIED |
| `docs/adoption-demo.md` | Lifecycle command truth | Checked-in helper scripts and CI workflow | Yes; contract tests assert agreement | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Shell/Python syntax | `sh -n ...docker-stop && sh -n ...docker-reset && sh -n ...docker-cleanup && bash -n scripts/maintainer/repo_hygiene_check.sh && python3 -m py_compile scripts/demo/adoption_smoke.py` | Exit 0 | PASS |
| CI hygiene remains deterministic | `bash ./scripts/maintainer/repo_hygiene_check.sh --ci` | 14 PASS, 0 WARN, 0 BLOCK; exit 0 | PASS |
| Focused contracts | `mix test test/lockspire/adoption_demo_docker_contract_test.exs test/lockspire/release_readiness_contract_test.exs --seed 0` | 70 tests, 0 failures | PASS |
| Cleanup dry-run default | `examples/adoption_demo/bin/docker-cleanup --project lockspire-adoption-demo-test` | Printed exact candidate volumes/artifacts and preserved `tmp/admin-ui-polish/`; no execute | PASS |
| Local demo hygiene after cleanup | `./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci` | Demo-owned checks all PASS; command exit nonzero only for unrelated dirty tree/latest CI repo-wide blockers | PASS for Phase 115 scope |

### Probe Execution

No phase-declared or conventional `scripts/*/tests/probe-*.sh` probes were found. Step 7c skipped.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SMOKE-03 | 115-02, 115-03 | CI keeps existing adoption-demo smoke and deterministic Docker validation only | SATISFIED | CI workflow and release-readiness contracts verified. |
| CLEAN-01 | 115-01, 115-03 | Stop command preserves volumes | SATISFIED | `docker-stop` source and contracts verified. |
| CLEAN-02 | 115-01, 115-03 | Reset rebuilds active project DB/cache only | SATISFIED | `docker-reset` source and contracts verified. |
| CLEAN-03 | 115-01, 115-03 | Cleanup removes only allowlisted demo-owned resources/artifacts | SATISFIED | `docker-cleanup` source, dry-run, docs, contracts verified. |
| HYGIENE-01 | 115-02, 115-03 | Local hygiene reports PASS/WARN/BLOCK for demo leftovers/artifacts | SATISFIED | Local hygiene source and local run verified. |
| HYGIENE-02 | 115-02, 115-03 | `--ci` does not require Docker daemon state | SATISFIED | `--ci` run passed; source gate skips local Docker helpers in CI. |
| HYGIENE-03 | 115-01, 115-02, 115-03 | Preserve `tmp/admin-ui-polish/` by default | SATISFIED | Cleanup/hygiene source, docs, and contracts verified. |
| HYGIENE-04 | 115-01, 115-02, 115-03 | Lifecycle can leave no demo-owned BLOCK findings | SATISFIED | Summary recorded Docker lifecycle proof; fresh local hygiene shows demo-owned checks PASS. |
| BOUNDARY-01 | 115-02, 115-03 | No protocol/admin UI/production Docker/hosted-auth broadening | SATISFIED | Boundary contracts and file scan verified. |
| BOUNDARY-02 | 115-02, 115-03 | Demo remains repo-local proof, not public support expansion | SATISFIED | Docs and contracts verified. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| N/A | N/A | None | N/A | `rg` scan found no TODO/FIXME/XXX/TBD/HACK/PLACEHOLDER/stub patterns in Phase 115 files. |

### Human Verification Required

None.

### Gaps Summary

No blocking gaps found. The only current local hygiene `BLOCK` results are unrelated repo-wide state: dirty working tree and latest main CI not green. Phase 115's demo-owned hygiene checks report PASS after cleanup, and deterministic source/CI contracts pass.

---

_Verified: 2026-06-24T18:06:54Z_
_Verifier: the agent (gsd-verifier)_
