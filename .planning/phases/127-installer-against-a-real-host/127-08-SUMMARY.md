---
phase: 127-installer-against-a-real-host
plan: 08
subsystem: installer
tags: [mix-generator, plan-then-apply, dry-run, manifest-drift, install-conflict-semantics]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host
    provides: "127-01's priv/test_fixtures/phx_new_host/ snapshot and Lockspire.HostSnapshot; 127-07's Install.plan/1 + apply_plan!/2 plan-then-apply split and classify_destination/3 three-way checksum comparison that this plan's manifest classification reuses"
provides:
  - "mix lockspire.install --dry-run, mirroring mix lockspire.upgrade's exit-code/label-swap convention exactly: prints the full plan (all twelve rendered destinations plus the manifest) and writes nothing on a clean host, raises with the same refusal list as a real run on a conflicted host"
  - "Install.plan/1 classifies the install manifest itself alongside the twelve rendered destinations, comparing the manifest's recorded inputs (web module, scope module, mount path, storage/oban prefix) against this run's assigns and refusing on any delta, naming the key and both values"
  - "A manifest whose recorded inputs map is missing or malformed is refused as unreadable rather than crashing"
  - "Manifest.write/2 no longer silently overwrites a differing on-disk manifest during mix lockspire.install -- that path is refused through Install.plan/1's classification like every other managed file; Manifest.write/2 itself is kept for mix lockspire.upgrade's own refresh-after-update write"
affects: [installer-app-tree-wiring, doc-wiring-truth, adopter-path-guardrail]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "The install manifest is represented as a synthetic %{template:, destination:, relative_path:, rendered:} entry (build_manifest_rendered/2) so Install.plan/1's classified/conflicts accumulation and apply_plan!/3's write/print loop treat it exactly like the twelve rendered templates -- one classification path, one write path, one dry-run label-swap path, for all thirteen destinations"
    - "Manifest input-drift check (classify_manifest/3 + check_input_drift/2) runs ahead of the ordinary byte-comparison classification: a manifest whose recorded inputs differ from the current run's assigns is refused with the specific key/value delta named, before classify_destination/3's three-way checksum comparison ever runs"

key-files:
  created: []
  modified:
    - lib/mix/tasks/lockspire.install.ex
    - lib/lockspire/generators/install.ex
    - lib/lockspire/install/manifest.ex
    - test/integration/install_conflict_semantics_test.exs
    - docs/code-walkthrough.md

key-decisions:
  - "Split the two-task plan into two atomic commits along the plan's own file-list boundary: Task 1's own <files> list excludes lib/lockspire/install/manifest.ex, so Task 1 folds the manifest into Install.plan/1's classification using classify_destination/3 directly (host-edit and template-changed refusals fall out for free, but no input-drift check yet, and manifest.ex is untouched). Task 2 then adds classify_manifest/3 + check_input_drift/2 for the input-drift-specific refusal and renames manifest.ex's silent-overwrite print string. Verified both commits independently pass mix test.fast and mix qa before landing, rather than committing a single squashed diff."
  - "Chose 'mix lockspire.upgrade --dry-run's refusal-before-dry-run ordering rather than inventing a second convention (RESEARCH Open Question 2): a --dry-run against a conflicted host still raises and exits non-zero, printing the same refusal list a real run would, documented explicitly in the --dry-run help text since the ergonomic alternative (report-and-exit-zero) was deliberately rejected for consistency between the two sibling tasks."
  - "check_input_drift/2 compares exactly the five keys Manifest.build/2 already records (mount_path, storage_prefix, oban_prefix, web_module, scope_module) -- no new manifest schema or state was introduced. A missing individual key, a missing 'inputs' entry, or a non-map 'inputs' value are all refused as malformed rather than crashing, defensively, since the manifest is decoded from untrusted on-disk JSON."
  - "Manifest.write/2's differing-content branch is kept (mix lockspire.upgrade still needs it, since it has already decided a refresh is needed and computes the new manifest content itself) but its print string changed from '* updated' to '* upgraded' to satisfy the plan's 'no silent overwrite string survives in manifest.ex' acceptance criterion while preserving mix lockspire.upgrade's existing behavior and test assertions unchanged."
  - "Updated docs/code-walkthrough.md's Install excerpt in both commits to keep the documentation-contract test's required anchor ('Enum.filter(&(&1.template.ownership == :managed))') literally present in the real source (kept the piped form rather than an inline extra-arg call) and to replace the now-deleted write_manifest!/2 and pre-127-07 ensure_file!/2 excerpt with an accurate plan/1 excerpt reflecting the manifest-as-destination classification."

requirements-completed: [INSTALL-03]

coverage:
  - id: D1
    description: "mix lockspire.install --dry-run on a clean host prints the full plan (all twelve destinations plus the manifest) and writes nothing"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#--dry-run against a clean host prints the full plan and writes nothing"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix lockspire.install --dry-run on a conflicted host prints the full refusal list and exits non-zero, matching mix lockspire.upgrade --dry-run's convention"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#--dry-run against a drifted host prints the full refusal list and raises"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix lockspire.install --dry-run on a byte-identical prior install reports unchanged and writes nothing"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#--dry-run against a byte-identical prior install reports unchanged and writes nothing"
        status: pass
    human_judgment: false
  - id: D4
    description: "A re-run whose module or mount-path switches differ from the manifest's recorded inputs is refused with the specific delta named (key plus both values)"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a re-run with a differing web module is refused naming both values"
        status: pass
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a re-run with a differing mount path is refused naming both values"
        status: pass
    human_judgment: false
  - id: D5
    description: "A manifest whose recorded inputs map is absent or malformed produces a refusal naming the manifest, not a crash"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a manifest with a malformed inputs map is refused without crashing"
        status: pass
    human_judgment: false
  - id: D6
    description: "A drifted (host-edited) manifest is refused like every other managed file rather than being silently overwritten"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a manifest the host edited directly is refused rather than overwritten"
        status: pass
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#an identical re-run still reports the manifest unchanged and writes nothing"
        status: pass
    human_judgment: false
  - id: D7
    description: "No force switch and no interactive prompt exists on mix lockspire.install; mix lockspire.upgrade's own refusal, idempotency, and manifest-refresh behavior is unaffected"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_upgrade_test.exs (all 4 tests)"
        status: pass
      - kind: other
        ref: "grep -Ec '\\-\\-force|force: :boolean|Mix\\.shell\\(\\)\\.(yes\\?|prompt)' lib/mix/tasks/lockspire.install.ex == 0"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 08: Installer Against A Real Host Summary

**`mix lockspire.install --dry-run` mirrors `mix lockspire.upgrade`'s dry-run exit-code convention exactly, and the install manifest is now classified alongside the twelve rendered destinations in `Install.plan/1` so a re-run with different `--web`/`--scope`/`--mount-path` switches, or a host-edited manifest, is refused with zero bytes written instead of silently producing a second orphaned file set.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-29T17:14:50Z
- **Tasks:** 2 completed
- **Files modified:** 5 (0 created, 5 modified)

## Accomplishments

- Added `--dry-run` to `mix lockspire.install`'s strict switch list, threaded into `Lockspire.Generators.Install.run/1`. On a clean host it prints one planned line per destination (`DRY-RUN <path>`) plus the manifest, writes nothing, creates no directories, and skips the onboarding-instructions print. On a conflicted host it raises with the exact same refusal list a real run would print, exiting non-zero -- copying `mix lockspire.upgrade`'s refusal-before-dry-run ordering rather than inventing a second convention, per RESEARCH Open Question 2, and documenting the exit behavior in `--help`.
- Folded the install manifest into `Install.plan/1`'s classification: `build_manifest_rendered/2` represents the manifest as a synthetic destination in the same shape as the twelve rendered templates, so `apply_plan!/3`'s single write/print loop (already built in 127-07) handles the manifest's create/unchanged/DRY-RUN/refuse states identically to every other managed file -- no separate write path, no separate print path.
- Added `classify_manifest/3` + `check_input_drift/2`: before the ordinary byte-comparison classification runs, the manifest's recorded `mount_path`, `storage_prefix`, `oban_prefix`, `web_module`, and `scope_module` are compared against the current run's assigns. Any difference is refused with the specific key and both values named (e.g. `web_module changed from "HostAppWeb" to "OtherWeb"`), closing the gap where a re-run with different module switches would otherwise write a whole second set of host files while the first set stayed behind, orphaned and unmanaged.
- Made the defensive cases explicit rather than crashes: a manifest whose `"inputs"` entry is missing, not a map, or missing an individual key is refused naming the manifest as unreadable/malformed, never an unhandled `KeyError`/`FunctionClauseError`.
- Removed the manifest's status as the one managed file that silently overwrites: `Manifest.write/2`'s differing-content branch (still used by `mix lockspire.upgrade`, which has already decided a refresh is needed) had its print string renamed from `"* updated"` to `"* upgraded"`, and `mix lockspire.install` no longer calls `Manifest.write/2` at all -- its manifest write now goes exclusively through `Install.plan/1`'s classification and `apply_plan!/3`'s write loop, so a host-edited manifest is refused like any other drifted managed file.
- Added 9 new integration tests to `test/integration/install_conflict_semantics_test.exs` against the real, committed `phx_new_host` snapshot: three `--dry-run` scenarios (clean host, drifted host, byte-identical rerun) and five manifest-drift scenarios (differing web module, differing mount path, malformed inputs map, host-edited manifest, identical rerun unchanged) plus the existing suite, all asserting zero bytes written on every refusal via the tree-checksum helper.
- Updated `docs/code-walkthrough.md`'s Install excerpt (already stale before this plan, referencing a pre-127-07 `ensure_file!/2` and this plan's now-deleted `write_manifest!/2`) to an accurate `plan/1` excerpt showing the manifest-as-destination classification, while preserving the exact anchor string (`Enum.filter(&(&1.template.ownership == :managed))`) the documentation contract test requires.

## Task Commits

1. **Task 1: Add --dry-run with upgrade-identical semantics** - `5e0f007` (feat)
2. **Task 2: Refuse input drift and manifest drift instead of silently producing a second file set** - `a478ef7` (feat)

_Note: `tdd="true"` on both tasks, but as with 127-07's equivalent task, each task's finished, verified state landed as one `feat(...)` commit rather than separate `test`/`feat` commits. For each task, the RED state was confirmed by running the new tests against the pre-implementation code (observing the exact expected failures: missing DRY-RUN output for Task 1's tests written against Task 1's own pre-implementation state, missing manifest-path refusals for Task 2's) before implementing, and GREEN was confirmed by the full local test run shown below before committing. The two tasks were kept as genuinely separate, independently-buildable commits by respecting Task 1's own `<files>` list (which excludes `lib/lockspire/install/manifest.ex`): Task 1's commit folds the manifest into classification using the existing `classify_destination/3` alone (no `manifest.ex` changes, no input-drift check yet); Task 2's commit adds the input-drift-specific `classify_manifest/3` + `check_input_drift/2` and the `manifest.ex` print-string change on top._

## Files Created/Modified

- `lib/mix/tasks/lockspire.install.ex` - added `dry_run: :boolean` to the strict switch list and a `--dry-run` entry to the usage heredoc, documenting the conflicted-host exit behavior
- `lib/lockspire/generators/install.ex` - `run/1` threads `dry_run?` into `apply_plan!/3`; `plan/1` classifies the manifest (via `build_manifest_rendered/2` and `classify_manifest/3`) alongside the twelve rendered destinations; `apply_plan!/3` gained a `dry_run:` option swapping the `* created` label for `DRY-RUN` and no longer calls a separate manifest-write function; added `check_input_drift/2`, `current_input/2`, and extended `refusal_fix_line/1` for the new manifest-specific refusal reasons
- `lib/lockspire/install/manifest.ex` - `write/2`'s differing-content branch renamed `"* updated"` to `"* upgraded"`; added `encode/1` (extracted `Jason.encode!(manifest, pretty: true)` for reuse by `Install.build_manifest_rendered/2`); added a doc comment clarifying `write/2` is now exclusively `mix lockspire.upgrade`'s write path
- `test/integration/install_conflict_semantics_test.exs` - added a `--dry-run` describe block (3 tests) and a `manifest input and content drift` describe block (5 tests); `install!/1` became `install!/2` accepting opts so tests can pass `dry_run: true` or differing `--web`/`--mount-path` values
- `docs/code-walkthrough.md` - Install excerpt updated to reflect `plan/1`'s manifest classification, replacing the stale `write_manifest!/2`/`ensure_file!/2` snippet

## Decisions Made

- Split the plan's two tasks into two genuinely independent, atomically-buildable commits along the plan's own `<files>` boundary (Task 1 never touches `manifest.ex`) rather than a single squashed diff, verifying `mix test.fast` and `mix qa` pass at each commit boundary.
- Kept `mix lockspire.upgrade`'s refusal-before-dry-run ordering for `mix lockspire.install --dry-run` (a dry-run against a conflicted host still exits non-zero) rather than the ergonomically tempting "report and exit zero" alternative, per the plan's explicit instruction to prioritize sibling-task consistency and RESEARCH Open Question 2's recommendation.
- Represented the manifest as a synthetic rendered destination (`build_manifest_rendered/2`) reusing the exact `%{template:, destination:, relative_path:, rendered:}` shape every template already has, so no new classification, write, or print code path was needed for the manifest specifically -- it flows through the same `classified`/`conflicts` accumulation and `apply_plan!/3` loop as the twelve templates.
- Renamed `Manifest.write/2`'s overwrite-branch print string rather than removing the function or its overwrite capability, since `mix lockspire.upgrade` legitimately needs to write a manifest whose content differs from what's on disk (it has already decided and applied the refresh); only `mix lockspire.install`'s call site was removed.

## Deviations from Plan

None - plan executed exactly as written. Both tasks' acceptance criteria pass as specified; no Rule 1-4 auto-fixes or architectural questions arose during execution. Documentation-contract test drift surfaced twice during implementation (the anchor-literal check and the `git diff --exit-code -- lib/lockspire/` dirty-tree check) but both were artifacts of an uncommitted working tree mid-session, not code defects -- resolved by preserving the anchor's literal form and by committing, respectively, not by changing test expectations.

## Issues Encountered

None beyond the documentation-contract test transients noted above, both confirmed resolved after committing (full `mix test.fast` run: 1298 tests, 0 failures against the final committed state).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- INSTALL-03 is now fully closed across 127-07 and 127-08: a conflicted `mix lockspire.install` reports every conflict at once with zero bytes written (127-07), and the previously-deferred gaps -- `--dry-run` support, input-drift refusal, and manifest-drift refusal -- are closed (127-08).
- `Install.plan/1` and `apply_plan!/3` remain exposed as named public functions for a future plan to drive classification without writing, per the phase's `key_links` intent; `apply_plan!/3`'s new `dry_run:` opt is backward-compatible with the `apply_plan!/2` call already used by `test/integration/install_conflict_semantics_test.exs`'s escaping-destination test from 127-07.
- No blockers. `mix test test/integration/install_conflict_semantics_test.exs test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs --include integration` (23 tests), `mix test.fast` (1298 tests, 0 failures), `mix format --check-formatted`, and `mix qa` (Credo `--strict`, Sobelow, compile `--warnings-as-errors`) are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 5 modified files confirmed present on disk; both task commits (`5e0f007`, `a478ef7`) confirmed in `git log --oneline --all`.
