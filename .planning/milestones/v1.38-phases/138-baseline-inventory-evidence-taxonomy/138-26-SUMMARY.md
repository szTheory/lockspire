---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "26"
subsystem: release-maintenance
tags: [git-worktrees, nul-transport, atomic-publication, dependency-preflight, path-safety]
requires:
  - phase: 138-25
    provides: Corrected immutable baseline collection and fail-closed currentness relation.
provides:
  - Delimiter-safe Git worktree observation through validated structured rows and final-boundary encoding.
  - Invocation-relative canonical output targeting preserved through locking and no-follow atomic replacement.
  - Deterministic git, python3, and jq preflight before collection or relation observation.
affects: [138-27, phase-139, phase-140, repository-reconciliation]
actuals:
  tokens: 5844
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [NUL-delimited Git porcelain, JSON-object evidence rows, caller-bound canonical targets, observation-before-preflight prohibition]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-26-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Worktree porcelain is consumed with -z and carried as validated JSON objects; path bytes are encoded only when rendering Markdown."
  - "Relative output paths are resolved once against the physical invocation directory before changing to the repository root."
  - "git, python3, and jq are mandatory startup dependencies for both collection and relation modes."
patterns-established:
  - "Untrusted path-bearing Git records use NUL field boundaries and named structured fields instead of tab/newline shell strings."
  - "Publication owns one canonical absolute target from caller resolution through locking, identity verification, rename, and cleanup."
requirements-completed: [BASE-01, BASE-02]
coverage:
  - id: D1
    description: Real linked worktrees with tab and newline path bytes each retain one exact stable proposal-only row.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs#baseline inventory collector preserves hostile worktree path boundaries"
        status: pass
    human_judgment: false
  - id: D2
    description: Relative replacement targets resolve against caller cwd while former re-rooted neighbors remain byte-identical.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "phase138_path_gap nested name.md and ../name.md process fixtures"
        status: pass
    human_judgment: false
  - id: D3
    description: Missing jq fails with a named diagnostic before collection or relation source work and target mutation.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "phase138_path_gap PATH-isolated collection and relation fixtures"
        status: pass
    human_judgment: false
duration: 1h 8m
completed: 2026-09-10
status: complete
---

# Phase 138 Plan 26: Path-Safe Worktree and Publication Boundaries Summary

**NUL-delimited worktree evidence, caller-bound canonical publication targets, and deterministic dependency preflight close the collector's first filesystem-boundary gaps.**

## Performance

- **Duration:** 1 hour 8 minutes
- **Started:** 2026-09-10T14:11:00Z
- **Completed:** 2026-09-10T15:19:02Z
- **Tasks:** 2/2
- **Files modified:** 3 production/test files plus this summary

## Accomplishments

- Replaced newline/tab worktree transport with `git worktree list --porcelain -z`, explicit record parsing, validated JSON objects, deterministic structured sorting, and final-boundary Markdown normalization.
- Proved actual linked worktrees containing tab and newline path bytes retain exact path-derived Git object IDs, one 12-field row each, proposal-only disposition, and a complete receipt.
- Bound `--output` to the physical invocation directory before repository-root Git work so `name.md` and `../name.md` replace only the caller-named canonical target.
- Moved mandatory `git`, `python3`, and `jq` checks ahead of relation or collection observation, locking, and target changes with deterministic named diagnostics.

## Task Commits

1. **Task 1 RED: expose hostile worktree path corruption** — `5b0c246f` (test)
2. **Task 1 GREEN: preserve worktree path record boundaries** — `106d9159` (fix)
3. **Task 2 RED: expose caller path and preflight gaps** — `d8813b04` (test)
4. **Task 2 GREEN: bind output and preflight dependencies** — `18f9459b` (fix)
5. **Compatibility correction: retain fail-closed worktree diagnostics** — `8060cc6a` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — consumes NUL-delimited worktree porcelain into validated JSON rows, resolves output paths against caller cwd, and preflights mandatory tools before observation.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds the focused `:phase138_path_gap` process-contract entry point.
- `test/support/lockspire/release_proof/package_assertions.ex` — builds real delimiter-bearing linked worktrees, nested caller replacement fixtures, malformed transport cases, and PATH-isolated no-jq checks.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-26-SUMMARY.md` — records TDD gates, verification evidence, decisions, and gap outcomes.

## Decisions Made

- Used Git's native `--porcelain -z` contract rather than attempting to decode quoted newline-oriented output.
- Used JSON objects as the internal worktree row shape so field cardinality and names are validated independently of rendered delimiters.
- Preserved exact raw path identity for hashing while retaining the existing centralized display normalization at the Markdown boundary.
- Kept one canonical absolute output target after caller-relative resolution; no alternate relative identity participates in locking or cleanup.

## Verification

| Gate | Result |
| --- | --- |
| Focused `phase138_path_gap` contract | 1 test, 0 failures; 30 excluded |
| Existing stable-ID failure contract | 1 test, 0 failures; 30 excluded |
| Existing current evidence-integrity contract | 1 test, 0 failures; 30 excluded |
| Existing maintained hostile-path contract | 1 test, 0 failures; 30 excluded |
| Full repository-hygiene contract | 31 tests, 0 failures in 401.8 seconds |
| `bash -n scripts/maintainer/baseline_inventory.sh` | exit 0 |

## Gap Outcomes

| Gap | Outcome |
| --- | --- |
| Tab/newline worktree paths split or corrupt rows | Closed with NUL parsing, structured validation, exact stable IDs, and real-repository proof. |
| Malformed worktree transport can look complete | Closed; malformed, unterminated, invalid-SHA, ID-failed, or structured-write failures mark the worktree receipt and aggregate partial. |
| Relative `--replace` is re-rooted after `cd` | Closed; target resolution occurs against physical invocation cwd and neighboring/former targets retain exact bytes. |
| `jq` absence is discovered after source work | Closed; collection and relation modes fail before Git/Python execution, locks, or target mutation. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Compatibility] Preserved named stable-ID failure evidence for unterminated structured records**

- **Found during:** Full repository-hygiene verification after Task 2.
- **Issue:** The first NUL parser did not process an unterminated final field, so a fixture that combined malformed termination with an ID failure retained only the malformed limitation.
- **Fix:** Process the final unterminated field while still marking the stanza malformed, retain both named failure causes, and terminate valid object-format fixture stanzas explicitly.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Stable-ID failure, current evidence-integrity, focused path-gap, and full repository-hygiene contracts pass.
- **Committed in:** `8060cc6a`

---

**Total deviations:** 1 auto-fixed (Rule 1 compatibility)
**Impact on plan:** The correction preserves existing fail-visible diagnostic guarantees without expanding scope.

## Issues Encountered

- An initial broad test run overlapped a source-file edit and one Bash process read a transient partial script. That run was discarded; the clean rerun completed with 31 tests and 0 failures.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 138-27 can harden later relation/republication behavior on top of delimiter-safe worktree identity and caller-bound publication.
- No blockers remain; no ledger, schema, sidecar, runtime module, Mix task, public API, or gitignored evidence mirror was added.

## Self-Check: PASSED

- All three planned source/test files exist.
- All five task and compatibility commits exist in Git history.
- Focused, compatibility, full-suite, and shell syntax verifications passed.
- The pre-existing `138-VERIFICATION.md` modification remains untouched and uncommitted.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-10*
