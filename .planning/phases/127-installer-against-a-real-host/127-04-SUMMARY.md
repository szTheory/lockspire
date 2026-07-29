---
phase: 127-installer-against-a-real-host
plan: 04
subsystem: installer
tags: [mix-generator, oban, cachex, ecto-migrations, install-instructions]

# Dependency graph
requires:
  - phase: 126-adopter-path-walk-defect-ledger
    provides: "ADOPT-D05, ADOPT-D06, ADOPT-D07 defect entries naming the installer-half fixes this plan closes"
provides:
  - "instructions/1 next steps naming the host application-tree wiring (included_applications, extra_applications, three supervision children ordered after the host's Repo)"
  - "instructions/1 next steps naming the three-stage key lifecycle (generate_key/1, publish_key/2, activate_key/2) and stating that publication alone cannot sign"
  - "All four in-scope mix ecto.migrate remediation/instruction sites (install.ex instructions plus verify.ex's pending, storage-prefix, oban-prefix, and up-to-date remediation strings) now name the release-safe --migrations-path switch"
  - "Lockspire.Install.Verify.evaluate_supervision_children/3 -- a read-only check reporting whether Lockspire's Oban, JWKS cache, and key cache supervision children are running, wired into mix lockspire.verify"
affects: [installer-instructions, verify-diagnostics, documented-wiring-truth]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure decision function (evaluate_supervision_children/3) separated from live process lookups (Oban.whereis/1, Cachex.size/1, Process.whereis/1) so OK/error rendering is unit-testable without starting or stopping the host's supervision tree"
    - "Shared migrations_path/0 helper in verify.ex, reused across migration_state/1 and all four remediation-string builders instead of restating Application.app_dir(:lockspire, \"priv/repo/migrations\") per site"
    - "Occurrence-level ExUnit negative-lookahead regex assertion (refute output =~ ~r/ecto\\.migrate(?!\\s+--migrations-path)/) to catch a bare ecto.migrate mention sharing a line with a corrected one -- the exact hole a line-granular shell grep cannot close"

key-files:
  created:
    - test/lockspire/install/install_instructions_test.exs
  modified:
    - lib/lockspire/generators/install.ex
    - lib/lockspire/install/verify.ex
    - lib/mix/tasks/lockspire.verify.ex

key-decisions:
  - "Kept defp instructions/1 private (not made public) to satisfy the plan's own awk-region acceptance criteria, which literally greps for the string \"defp instructions\" -- the test instead captures stdout by calling Install.run/1 against a disposable, non-existent scratch tmp directory (cleaned up via on_exit), exercising the real Mix.shell().info(instructions(assigns)) codepath rather than reaching into a private function."
  - "Extracted Lockspire.Install.Verify.evaluate_supervision_children/3 as a public, pure function taking three booleans rather than testing the live-process check end-to-end, so the OK and missing-children error paths are both directly unit-testable without stopping Lockspire's own already-running Oban/Cachex/KeyCache children mid test-suite."
  - "Fixed all four in-scope migrate remediation sites in verify.ex (pending, storage-prefix, oban-prefix, up-to-date), not just the two CONTEXT named plus RESEARCH's Pitfall-10 third site -- the storage-prefix and oban-prefix clauses' \"Run Lockspire migrations with config ...\" wording implied a bare command too, per the plan's own action text."

requirements-completed: [INSTALL-01]

coverage:
  - id: D1
    description: "instructions/1 names the host application-tree wiring (included_applications, extra_applications :oban/:cachex, three supervision children ordered after the host's Repo) and states Lockspire never modifies mix.exs or application.ex itself"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/lockspire/install/install_instructions_test.exs#instructions/1 (installer next steps) names the host application-tree wiring the walk proved is required"
        status: pass
    human_judgment: false
  - id: D2
    description: "instructions/1 names all three key-lifecycle stages (generate_key/1, publish_key/2, activate_key/2) and states that publication alone is not sufficient to sign"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/lockspire/install/install_instructions_test.exs#instructions/1 (installer next steps) names all three key-lifecycle stages and states publication is not sufficient to sign"
        status: pass
    human_judgment: false
  - id: D3
    description: "All in-scope mix ecto.migrate remediation/instruction sites name the release-safe --migrations-path switch; no site prescribes a bare migrate command"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/lockspire/install/install_instructions_test.exs#instructions/1 (installer next steps) does not prescribe a bare migrate command anywhere in the printed steps"
        status: pass
      - kind: unit
        ref: "test/lockspire/install/install_instructions_test.exs#verify.ex migration remediation strings all migrate remediation sites name the migrations-path switch, not a bare invocation"
        status: pass
    human_judgment: false
  - id: D4
    description: "mix lockspire.verify reports whether Lockspire's supervision children (Oban, JWKS cache, key cache) are actually running, read-only, and names the missing ones with a fix pointing at application.ex ordered after the host's Repo"
    requirement: "INSTALL-01"
    verification:
      - kind: unit
        ref: "test/lockspire/install/install_instructions_test.exs#Verify supervision-children check reports OK naming all three children when everything is running"
        status: pass
      - kind: unit
        ref: "test/lockspire/install/install_instructions_test.exs#Verify supervision-children check reports the missing children by name and points at application.ex ordered after Repo"
        status: pass
      - kind: integration
        ref: "test/lockspire/install/install_instructions_test.exs#Verify supervision-children check run/1 includes a supervision check that passes while Lockspire's own children boot"
        status: pass
    human_judgment: false
  - id: D5
    description: "The installer still writes nothing into the host's mix.exs or application.ex -- zero injection preserved"
    requirement: "INSTALL-01"
    verification:
      - kind: other
        ref: "grep -En 'File\\.write|File\\.cp|File\\.rm' lib/lockspire/generators/install.ex -- no new write path outside the twelve rendered destinations and the manifest"
        status: pass
    human_judgment: false

# Metrics
duration: 30min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 04: Installer Against A Real Host Summary

**`instructions/1` now names the host application-tree wiring and the three-stage key lifecycle by function, all four in-scope `mix ecto.migrate` remediation sites name the release-safe `--migrations-path` switch, and `mix lockspire.verify` gained a read-only supervision-children check.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-07-29T13:39:39Z
- **Tasks:** 2 completed
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Closed the installer half of ADOPT-D05: `instructions/1`'s numbered next-steps now name `included_applications: [:lockspire]`, the `:oban`/`:cachex` `extra_applications` additions, and Lockspire's three supervision children (the Oban child from `Lockspire.Oban.runtime_config!/0`, the `:lockspire_jwks_cache` Cachex child, and `Lockspire.KeyCache`) ordered after the host's own Repo -- while stating explicitly that Lockspire never touches the host's `mix.exs` or `application.ex` itself.
- Closed the installer half of ADOPT-D06: `instructions/1` now names all three key-lifecycle calls by name and arity (`Lockspire.Admin.generate_key/1`, `publish_key/2`, `activate_key/2`) as genuinely separate stages, stating that a published key still cannot sign until activated -- the finding the walk only surfaced on a first real token exchange.
- Closed ADOPT-D07 across all four in-scope sites, not just the three named by CONTEXT/RESEARCH's Pitfall 10: the installer's migrate step, `verify.ex`'s pending-migrations error, its up-to-date ongoing advice, and (going beyond the plan's explicit list) the storage-prefix and oban-prefix remediation clauses whose "Run Lockspire migrations with config ..." wording also implied a bare command. All five now name `--migrations-path` derived from `Application.app_dir(:lockspire, "priv/repo/migrations")` via a shared `migrations_path/0` helper.
- Added `Lockspire.Install.Verify.evaluate_supervision_children/3`, a read-only check wired into `mix lockspire.verify` that observes `Oban.whereis/1`, `Cachex.size/1`, and `Process.whereis/1` for Lockspire's three supervision children and reports missing ones by name with a fix pointing at the host's `application.ex` child list, ordered after the host's Repo. Documented as check 6 in `mix lockspire.verify --help`.
- Added `test/lockspire/install/install_instructions_test.exs`, pinning every instruction/remediation behavior above and asserting the no-bare-migrate-command negative at the substring level (`refute output =~ ~r/ecto\.migrate(?!\s+--migrations-path)/`) rather than only via a line-granular shell grep -- this occurrence-level check caught a real authoring bug (see Deviations).

## Task Commits

1. **Task 1: Name the host wiring, the key lifecycle, and the real migrate invocation in the installer's next steps** - `d131820` (feat, TDD test+implementation together)
2. **Task 2: Correct the verifier's migration remediation and report whether Lockspire's children are running** - `cc44075` (fix, TDD test+implementation together)

_Note: Both tasks are marked `tdd="true"` in the plan. Given the private-visibility constraint on `defp instructions/1` (required by the plan's own awk-region acceptance criteria) and the shared test file spanning both tasks, tests and implementation were authored and verified together within each task rather than as separate RED-then-GREEN commits. Each commit's tests were confirmed to exercise real behavior -- notably, the negative-assertion test in Task 1 caught and drove a fix for a real authoring bug before commit (see Deviations)._

## Files Created/Modified

- `lib/lockspire/generators/install.ex` - `instructions/1` extended with the app-tree wiring step, the key-lifecycle step, and a rewritten migrate step naming `--migrations-path`
- `lib/lockspire/install/verify.ex` - `evaluate_supervision_children/3` (public, pure), `supervision_children_check/0` wired into `run/1`, `migrations_path/0` helper, and all four migrate remediation strings corrected
- `lib/mix/tasks/lockspire.verify.ex` - `--help` text documents the new supervision-children check as step 6
- `test/lockspire/install/install_instructions_test.exs` - new file pinning instruction text, remediation strings, and supervision-check behavior

## Decisions Made

- Kept `defp instructions/1` private per the plan's own awk-region acceptance criteria (which greps for the literal string `"defp instructions"`); the test captures output by calling `Install.run/1` against a disposable scratch tmp directory instead of reaching into the private function.
- Extracted `evaluate_supervision_children/3` as a public, pure boolean-in/Check-result-out function so both the OK and missing-children paths are directly unit-testable without stopping Lockspire's own live Oban/Cachex/KeyCache children mid test-suite (they boot automatically via `Lockspire.Application` during `mix test`).
- Fixed all four in-scope verify.ex remediation sites (not just the two CONTEXT named), extending the storage-prefix and oban-prefix clauses to also name `--migrations-path` per the plan's own action text ("extend those to name the switch too if the wording implies a bare command").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Own test caught a real authoring bug: a second, unguarded `ecto.migrate` mention on the same instruction line**
- **Found during:** Task 1, first test run
- **Issue:** The first draft of the migrate step's explanatory sentence read "...The host's own bare `mix ecto.migrate` runs none of Lockspire's migrations..." -- a second, bare mention of `ecto.migrate` sharing the same heredoc line as the corrected `mix ecto.migrate --migrations-path ...` invocation. The plan's own line-granular shell grep fence could not see this (both mentions collapse to one line, and the line as a whole contains `migrations-path`), but the ExUnit negative-lookahead regex assertion (`refute output =~ ~r/ecto\.migrate(?!\s+--migrations-path)/`) correctly flagged it -- exactly the scenario the plan's action text called out this test as needing to catch.
- **Fix:** Reworded the explanatory sentence to say "A bare migrate command runs none of Lockspire's migrations..." instead of repeating the literal `ecto.migrate` token.
- **Files modified:** `lib/lockspire/generators/install.ex`
- **Verification:** `mix test test/lockspire/install/install_instructions_test.exs`, re-ran the awk/grep acceptance-criteria pipeline manually
- **Committed in:** `d131820` (part of Task 1 commit)

**2. [Rule 2 - Missing Critical] Documented the new supervision-children check in `mix lockspire.verify --help`**
- **Found during:** Task 2
- **Issue:** The plan did not explicitly require updating the Mix task's `--help` text, but it enumerates the 5 existing checks by number; leaving out the 6th would make the help text silently stale relative to actual verifier behavior.
- **Fix:** Added a 6th numbered line documenting the supervision-children check.
- **Files modified:** `lib/mix/tasks/lockspire.verify.ex`
- **Verification:** `mix lockspire.verify --help` exits 0 and lists the new check; `mix format --check-formatted`
- **Committed in:** `cc44075` (part of Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug caught by the test itself, 1 Rule 2 documentation completeness)
**Impact on plan:** Both auto-fixes were necessary for correctness and documentation truth. No scope creep -- no Mix task, no new public module, and the installer still writes nothing into the host's `mix.exs` or `application.ex`.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The installer and verifier halves of ADOPT-D05, ADOPT-D06, and ADOPT-D07 are closed. `docs/install-and-onboard.md:108`'s bare `mix ecto.migrate` guide text (the fourth occurrence Pitfall 10 names) is explicitly out of scope for this plan and belongs to Phase 128 (Documented Wiring Truth).
- `Lockspire.Install.Verify.evaluate_supervision_children/3` is now available as a public, pure decision function any later plan can reuse for additional supervision-readiness reporting without re-deriving the Oban/Cachex/KeyCache lookup pattern.
- No blockers. `mix test.fast` (1294 tests, 0 failures), `mix qa` (format, compile --warnings-as-errors, credo --strict, sobelow), and the plan's full `<verification>` command set are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 4 created/modified source files confirmed present on disk; both task commits (`d131820`, `cc44075`) confirmed in `git log --oneline --all`.
