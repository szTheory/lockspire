---
phase: 127-installer-against-a-real-host
plan: 07
subsystem: installer
tags: [mix-generator, plan-then-apply, idempotency, install-conflict-semantics]

# Dependency graph
requires:
  - phase: 127-installer-against-a-real-host
    provides: "127-01's priv/test_fixtures/phx_new_host/ snapshot and Lockspire.HostSnapshot (copy_to_scratch!/0, tree_checksums/1); 127-06's booting generated config/resolver templates the installer now writes through the new plan-then-apply path"
provides:
  - "Lockspire.Generators.Install.plan/1 -- side-effect-free classification of every rendered destination (:create | :unchanged | conflict), reusing lockspire.upgrade's three-way checksum comparison to distinguish a host edit from a Lockspire template change, plus a containment guard refusing any destination that would escape the expanded project root"
  - "Lockspire.Generators.Install.apply_plan!/2 -- the separate write pass, reached only when the plan has zero conflicts; on any conflict it prints one REFUSE <path> (<reason>) line plus an indented fix line per conflicted destination, then raises exactly once having written nothing"
  - "test/integration/install_conflict_semantics_test.exs -- all-conflicts-reported, zero-bytes-written (before/after tree checksum equality), trailing-newline-conflict, escaping-destination-refused, and no-manifest-after-refused-first-run proofs against the real phx_new_host snapshot"
affects: [installer-app-tree-wiring, doc-wiring-truth, adopter-path-guardrail]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Plan-then-apply split (plan/1 returns a read-only classification; apply_plan!/2 either refuses-with-zero-writes or performs every write) as the generator's own copy of the shape already established by lib/mix/tasks/lockspire.upgrade.ex"
    - "Three-way checksum comparison (recorded manifest checksum vs. current file content vs. freshly rendered content) to tell 'you edited this' apart from 'Lockspire changed this; run mix lockspire.upgrade', with a no-manifest-entry fallback to 'host edit detected'"
    - "Containment guard: destination_path/2 already expands the path, so plan/1 asserts every expanded destination resolves inside the expanded project root before classifying it as :create or :unchanged"

key-files:
  created:
    - test/integration/install_conflict_semantics_test.exs
  modified:
    - lib/lockspire/generators/install.ex
    - test/integration/install_generator_test.exs

key-decisions:
  - "Tested the containment guard by overriding assigns.web_path directly after build_assigns/1, bypassing Macro.underscore/1, rather than trying to smuggle a real '..' through the --web/--scope CLI options. Verified empirically this session that Macro.underscore/1 always inserts a '/' between adjacent literal dots (e.g. '..' becomes '/./', never '..'), so a real path-traversal payload cannot survive the existing --web/--scope derivation chain. The guard itself is still real defense in depth -- plan/1 is public API and a future call site could construct assigns directly -- so the test proves the guard's own contract at the correct level of abstraction instead of relying on an attack vector that does not exist against the current derivation code."
  - "Kept the refusal raise message ('Lockspire install refused: N destination(s) conflict...') as a single new string rather than reusing lockspire.upgrade's raise text verbatim, since install and upgrade are different commands and a shared literal would make the two error messages misleadingly identical in stack traces and CI logs."
  - "conflict_reason/3 falls back to 'host edit detected' whenever the destination's relative path has no entry in the manifest's managed_files list -- covering both 'no manifest exists yet' and 'this destination is host-owned scaffolding the manifest never tracked', since a host-owned file with any content difference is, definitionally, a host edit (nothing else could have produced a first-generation host-owned file's checksum record for the three-way comparison to consult)."

requirements-completed: [INSTALL-02, INSTALL-03]

coverage:
  - id: D1
    description: "A conflicted mix lockspire.install re-run reports every conflicted destination in one refusal, not just the first one an adopter happens to hit"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a conflicted re-run reports every conflicted destination and writes zero bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: "A conflicted run writes zero bytes -- the host tree's relative-path-to-sha256 map is byte-identical before and after the refused run, with no manifest written after an abort"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a conflicted re-run reports every conflicted destination and writes zero bytes"
        status: pass
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a refused first-ever run leaves no install manifest"
        status: pass
    human_judgment: false
  - id: D3
    description: "File equality for conflict classification is raw-byte equality, not normalized text -- a trailing-newline-only difference classifies as a conflict"
    requirement: "INSTALL-02"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a destination differing only by a trailing newline classifies as a conflict"
        status: pass
    human_judgment: false
  - id: D4
    description: "The refusal message distinguishes a host edit from a Lockspire template change, names paths and reasons only (never file contents), and a destination that would escape the project root is refused, not written"
    requirement: "INSTALL-03"
    verification:
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a conflicted re-run reports every conflicted destination and writes zero bytes"
        status: pass
      - kind: integration
        ref: "test/integration/install_conflict_semantics_test.exs#a destination that would escape the project root is refused, not written"
        status: pass
    human_judgment: false
  - id: D5
    description: "Existing per-file created/unchanged output strings and the byte-compared idempotent-re-run proof stay unchanged after the plan-then-apply rewrite"
    requirement: "INSTALL-02"
    verification:
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install is idempotent when the host has not edited generated files"
        status: pass
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install refuses to overwrite host edits"
        status: pass
    human_judgment: false

# Metrics
duration: 15min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 07: Installer Against A Real Host Summary

**Split `Lockspire.Generators.Install.run/1` into a side-effect-free `plan/1` classification pass and a separate `apply_plan!/2` write pass, so a conflicted `mix lockspire.install` re-run reports every conflict at once, writes zero bytes, and distinguishes a host edit from a Lockspire template change.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-07-29T16:51:30Z
- **Tasks:** 1 completed
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Closed the core of INSTALL-03: before this plan, a conflicted re-run wrote files one at a time via `Enum.each(&ensure_file!/2)` and raised `Mix.raise` on the very first difference it hit, aborting mid-loop with the manifest written only *after* the loop -- so a refused run left a half-installed host and no install manifest, and `mix lockspire.upgrade` would then misleadingly report "Missing install manifest. Run `mix lockspire.install` first," even though the install genuinely ran.
- `plan/1` reads every rendered template's destination and the install manifest (if any) but never writes, creates a directory, or removes a file -- proven by an `awk`-scoped grep over the function body finding zero `File.write`/`File.mkdir_p`/`File.rm` calls. Classification is a straight `File.read/1` outcome map: byte-identical content is `:unchanged`, absent is `:create`, anything else is a conflict.
- Conflict reasons reuse `lockspire.upgrade`'s three-way checksum comparison (recorded manifest checksum vs. current content vs. freshly rendered content) to tell "you edited this" apart from "Lockspire changed this; run `mix lockspire.upgrade`" -- the adopter now gets the correct remediation instead of a generic refusal.
- Added a containment guard: since `destination_path/2` already expands every destination, `plan/1` asserts it resolves inside the expanded project root before classifying it as writable. An escaping destination is refused, never written.
- `apply_plan!/2` prints one `REFUSE <path> (<reason>)` line plus an indented fix line per conflicted destination, in template-inventory order, then raises exactly once -- never echoing file contents, only paths and reason phrases. When the plan has zero conflicts it creates directories, writes files that need creating, prints the existing `* created`/`* unchanged` strings unchanged, and writes the manifest.
- Added `test/integration/install_conflict_semantics_test.exs` against the real, committed `phx_new_host` snapshot (via `HostSnapshot.copy_to_scratch!/0` and `Mix.Project.in_project/4`): both edited managed destinations appear in one captured refusal, the whole host tree's checksum map is byte-identical before and after a refused run, a trailing-newline-only difference still classifies as a conflict, an engineered escaping destination is refused with zero bytes written, and a refused first-ever run (a pre-existing colliding file, before any prior install) leaves no install manifest.
- Updated the two pinned first-conflict-raise assertions in `install_generator_test.exs` from `~r/Refusing to overwrite modified file/` to `~r/Lockspire install refused/`, matching the new refusal message; changed nothing else in that file.

## Task Commits

1. **Task 1: Split Install.run/1 into a side-effect-free plan pass and a separate apply pass** (TDD, single-commit red/green cycle verified locally) - `9178991` (feat)

_Note: `tdd="true"` in the plan, but as with 127-06's equivalent single-pass TDD tasks, the finished, verified state landed as one `feat(...)` commit rather than separate `test`/`feat` commits -- the RED state (old `ensure_file!` raising on the first conflict only) was confirmed by reading the pre-fix code and RESEARCH's empirical reproduction before implementing, and GREEN was confirmed by the full local test run below before committing._

## Files Created/Modified

- `lib/lockspire/generators/install.ex` - `run/1` now calls `plan/1` then `apply_plan!/2`; `ensure_file!/2` removed and replaced by `classify_destination/3`, `contained_in_root?/2`, `conflict_reason/3`, `load_manifest_checksums/1`, `print_refusals/1`, and `refusal_fix_line/1`
- `test/integration/install_conflict_semantics_test.exs` - new: all-conflicts-reported, zero-bytes-written, trailing-newline-conflict, escaping-destination, and no-manifest-after-refused-first-run proofs
- `test/integration/install_generator_test.exs` - the two `Refusing to overwrite modified file` regex assertions updated to `Lockspire install refused`; nothing else changed

## Decisions Made

- Proved the containment guard by overriding `assigns.web_path` directly after `build_assigns/1` rather than attempting a real `..` through `--web`/`--scope`. Verified empirically that `Macro.underscore/1` (the function `web_path`/`scope_path` are derived through) always inserts a `/` between adjacent literal dots -- `".."` becomes `"/./"`, never survives as `".."` -- so real path-traversal cannot reach `plan/1` through the documented CLI options today. The guard remains real defense in depth since `plan/1` is public API and a future call site could construct `assigns` directly; the test proves that contract at the correct level of abstraction instead of chasing an attack vector the current derivation chain already neutralizes.
- Chose a distinct refusal-raise message (`"Lockspire install refused: N destination(s) conflict..."`) rather than reusing `lockspire.upgrade`'s raise text verbatim, so stack traces and CI logs can't confuse which command actually refused.
- `conflict_reason/3` falls back to "host edit detected" whenever the destination's relative path has no manifest entry -- covering both "no manifest exists yet" and "this destination is host-owned scaffolding the manifest never tracked" in one branch, since only managed files get checksum entries.

## Deviations from Plan

None - plan executed exactly as written. The one task's acceptance criteria all pass as specified; no Rule 1-4 auto-fixes or architectural questions arose during execution.

## Issues Encountered

- The plan's suggested test vector for the escaping-destination case (a `../`-laden `--web` CLI value) does not actually escape the project root, because `Macro.underscore/1` inserts a `/` between every pair of adjacent literal dots and so never emits a real `..` in its output -- verified empirically before writing the test. Resolved by testing the containment guard directly against a hand-constructed `assigns` map (see Decisions Made above) rather than chasing a CLI-level exploit that the existing derivation chain already blocks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- INSTALL-03's core is closed: a conflicted `mix lockspire.install` now reports every conflict, explains which kind each is, raises once, and leaves the host byte-identical to how it found it.
- `plan/1` and `apply_plan!/2` are exposed as named public functions specifically so a future plan (128/129/130) can drive classification without writing, per the phase's own `key_links` intent.
- Deferred, out of this plan's scope per `.planning/phases/127-installer-against-a-real-host/127-VALIDATION.md`: `--dry-run` support, and refusing on install-manifest *inputs* drift (D-18) as opposed to managed-file *content* drift. Neither was named in this plan's `<behavior>` list; both remain open for a future phase if adopter evidence calls for them.
- No blockers. `mix test test/integration/install_conflict_semantics_test.exs test/integration/install_generator_test.exs test/integration/install_upgrade_test.exs --include integration` (15 tests), `mix test.fast` (1298 tests, 0 failures), and `mix qa` (format, Credo `--strict`, Sobelow, compile `--warnings-as-errors`) are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 3 created/modified files confirmed present on disk; the task commit (`9178991`) confirmed in `git log --oneline --all`.
