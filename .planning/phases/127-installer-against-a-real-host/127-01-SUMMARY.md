---
phase: 127-installer-against-a-real-host
plan: 01
subsystem: installer
tags: [mix-generator, phx-new, in_project, ecto, integration-test]

# Dependency graph
requires:
  - phase: 126-adopter-path-walk-defect-ledger
    provides: "tmp/adopter-walk/host_app/ real phx.new 1.8.9 + phx.gen.auth output used as the snapshot capture source, plus the ADOPT-D-series findings this phase closes"
provides:
  - "priv/test_fixtures/phx_new_host/ — committed, trimmed mix phx.new 1.8.9 + phx.gen.auth host snapshot (mix.exs, config/, application.ex, repo.ex, router.ex, endpoint.ex)"
  - "Lockspire.HostSnapshot test-support module (copy_to_scratch!/0, tree_checksums/1) for scratch-dir-safe host-fixture tests"
  - "test/integration/install_host_interaction_test.exs — Mix.Project.in_project/4 host-resolution proof with no --web/--scope flags"
  - "Install manifest version field sourced from Lockspire's own Application.spec, not the pushed Mix project"
affects: [installer-conflict-semantics, router-template-macro, config-template, install-instructions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mix.Project.in_project/4 as the in-process host-resolution lever for generator proofs (no subprocess, no deps fetch, no compile)"
    - "Scratch-copy-before-write pattern (Lockspire.HostSnapshot.copy_to_scratch!/0) for any test that runs a generator against a committed fixture tree, keeping git status --porcelain clean"

key-files:
  created:
    - priv/test_fixtures/phx_new_host/mix.exs
    - priv/test_fixtures/phx_new_host/config/config.exs
    - priv/test_fixtures/phx_new_host/config/dev.exs
    - priv/test_fixtures/phx_new_host/config/test.exs
    - priv/test_fixtures/phx_new_host/lib/host_app/application.ex
    - priv/test_fixtures/phx_new_host/lib/host_app/repo.ex
    - priv/test_fixtures/phx_new_host/lib/host_app_web/router.ex
    - priv/test_fixtures/phx_new_host/lib/host_app_web/endpoint.ex
    - priv/test_fixtures/phx_new_host/README.md
    - test/support/lockspire/host_snapshot.ex
    - test/integration/install_host_interaction_test.exs
  modified:
    - lib/lockspire/install/manifest.ex
    - test/integration/install_generator_test.exs

key-decisions:
  - "Stripped all Phase 126 walk-installed Lockspire wiring (mix.exs local-path dependency, included_applications, extra_applications additions, application.ex supervision children, router.ex import/routes/pipelines, config.exs import_config) from the committed snapshot so it represents a genuine pre-install phx.new + phx.gen.auth host, not a post-walk-wired one. The installer never reads or writes these files (D-08/D-26 zero-injection), so this had no bearing on test correctness, but leaving a local machine-specific absolute path (the {:lockspire, path: ...} dependency) in a committed fixture was a real defect regardless of test behavior."
  - "Replaced all generated secret_key_base and signing_salt literals across config/*.exs and endpoint.ex with obvious placeholder tokens, extending the plan's explicit config/*.exs stripping instruction to endpoint.ex's session-options signing_salt for consistency with T-127-10's intent (no generated secret literal enters priv/test_fixtures/, regardless of file)."
  - "TDD RED for the manifest-version fix lives entirely in install_host_interaction_test.exs, not install_generator_test.exs — under File.cd! the Mix project is never pushed, so install_generator_test.exs's own manifest[\"version\"] already equals Lockspire's version even before the fix, making that assertion non-tautological-but-not-RED. Confirmed empirically before implementing the fix."

requirements-completed: [INSTALL-01, INSTALL-02]

coverage:
  - id: D1
    description: "mix lockspire.install resolves app name, web module, router module, scope module, and repo module from a real, committed mix phx.new host via Mix.Project.in_project/4 with no --web/--scope flags, including negative controls against library-name leakage and the empty-tree/all-twelve-destinations-plus-manifest proof"
    requirement: "INSTALL-01"
    verification:
      - kind: integration
        ref: "test/integration/install_host_interaction_test.exs#resolves app name, web module, router module, scope module, and repo module from the host with no module flags"
        status: pass
      - kind: integration
        ref: "test/integration/install_host_interaction_test.exs#installing into a host with no prior Lockspire output creates every destination directory and file"
        status: pass
    human_judgment: false
  - id: D2
    description: "Install manifest version field is sourced from Lockspire's own Application.spec rather than the pushed Mix project's config, so it no longer reports the host app's version"
    requirement: "INSTALL-02"
    verification:
      - kind: integration
        ref: "test/integration/install_host_interaction_test.exs#the install manifest records Lockspire's own version, not the pushed host project's"
        status: pass
      - kind: integration
        ref: "test/integration/install_generator_test.exs#mix lockspire.install writes the host-owned integration files"
        status: pass
    human_judgment: false

# Metrics
duration: 40min
completed: 2026-07-29
status: complete
---

# Phase 127 Plan 01: Installer Against A Real Host Summary

**`mix lockspire.install` now runs against a committed, trimmed `mix phx.new 1.8.9` host snapshot via `Mix.Project.in_project/4` with no module flags, proving app/web/router/scope/repo resolution from the real host and correcting the install manifest's version field to track Lockspire, not the host.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-07-29T12:57:28Z
- **Tasks:** 2 completed
- **Files modified:** 13 (11 created, 2 modified)

## Accomplishments

- Killed the host-resolution tautology in `install_generator_test.exs:363-368`: the new proof pushes a real, committed `mix phx.new` host through `Mix.Project.in_project/4` with **no** `--web`/`--scope` flags and asserts the `repo:` line — previously unasserted anywhere — resolves to `HostApp.Repo`, not a value the test itself supplied.
- Committed `priv/test_fixtures/phx_new_host/` — a trimmed, real `mix phx.new 1.8.9` + `phx.gen.auth` host captured from the Phase 126 walk, with all walk-installed Lockspire wiring and generated secrets stripped, documented provenance and refresh procedure, and verified placement outside `mix format`, `credo --strict`, `mix test`'s default glob, `elixirc_paths(:test)`, and `mix hex.build`'s package files.
- Added `Lockspire.HostSnapshot` (`copy_to_scratch!/0`, `tree_checksums/1`) so any test exercising the installer against the committed snapshot writes only into a scratch copy — `git status --porcelain` stays empty after the full run.
- Added negative controls (no `Lockspire.Repo`, no `lib/lockspire/` directory) and the empty-tree proof (all twelve managed destinations plus the manifest absent before the run, present after).
- Fixed the install manifest's `"version"` field: it was reading `Mix.Project.config()[:version]`, which answers about whichever project is pushed — in real adopter installs, the host, not Lockspire. Verified against the Phase 126 walk host (`0.1.0` in the manifest while Lockspire is `1.4.0`). Now sourced from `Application.spec(:lockspire, :vsn)`, which cannot report a foreign project's version.
- Followed full RED/GREEN/TDD discipline for the manifest fix: added a failing assertion in `install_host_interaction_test.exs` first (confirmed it failed with `"0.1.0" != "1.4.0"`), committed it as a `test(...)` commit, then implemented the fix and confirmed green.

## Task Commits

1. **Task 1: End-to-end — install into a real generated Phoenix host, one path only** - `b9832b2` (feat)
2. **Task 2: Record Lockspire's own version in the install manifest** (TDD):
   - RED - `cf316d1` (test)
   - GREEN - `77d5ad9` (feat)
   - formatter fixup - `6767a3c` (style)

_Note: Task 2 required a follow-up `style` commit because the initial GREEN-phase assertion tripped `mix format --check-formatted`, which `mix qa` runs. Fixed and reverified before considering the task done._

## Files Created/Modified

- `priv/test_fixtures/phx_new_host/mix.exs` - real `mix phx.new host_app --database postgres` project definition, walk-specific wiring stripped
- `priv/test_fixtures/phx_new_host/config/{config,dev,test}.exs` - captured config with secrets/salts replaced by placeholders
- `priv/test_fixtures/phx_new_host/lib/host_app/{application,repo}.ex` - captured OTP application and Ecto repo, walk-installed supervision children removed
- `priv/test_fixtures/phx_new_host/lib/host_app_web/{router,endpoint}.ex` - captured Phoenix router/endpoint, walk-installed Lockspire routes/pipelines removed
- `priv/test_fixtures/phx_new_host/README.md` - capture provenance, exclusion scopes, stripped-wiring rationale, refresh procedure
- `test/support/lockspire/host_snapshot.ex` - `Lockspire.HostSnapshot.copy_to_scratch!/0` and `tree_checksums/1`
- `test/integration/install_host_interaction_test.exs` - `@moduletag :integration` host-resolution, empty-tree, and manifest-version proofs
- `lib/lockspire/install/manifest.ex` - `"version"` now sourced from `Application.spec(:lockspire, :vsn)`
- `test/integration/install_generator_test.exs` - manifest version assertion rewritten against an independently-derived value plus a shape assertion

## Decisions Made

- Stripped Phase 126 walk-installed wiring from the committed snapshot (see `key-decisions` above) so the fixture honestly represents a pre-install host, and to avoid committing a local machine-specific absolute path.
- Extended the plan's secret-stripping instruction from "config/*.exs" to also cover `endpoint.ex`'s hardcoded `signing_salt`, consistent with T-127-10's intent.
- Confirmed empirically (rather than assumed) that `install_generator_test.exs`'s manifest-version assertion cannot serve as the TDD RED test, since `File.cd!` never pushes a foreign project and so that file's own manifest already equals Lockspire's version before any fix. RED lives in `install_host_interaction_test.exs`, the only place `Mix.Project.in_project/4` actually pushes a different project's version.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/2 - Correctness/Security] Stripped walk-installed Lockspire wiring and a local absolute path from the committed snapshot**
- **Found during:** Task 1
- **Issue:** The plan's stated capture source, `tmp/adopter-walk/host_app/`, is the Phase 126 walk's *post*-install state — its `mix.exs` carries a `{:lockspire, path: "/Users/jon/projects/lockspire/.claude/worktrees/demo-404-and-disconnect"}` dependency (a machine-local absolute path that must never be committed), `included_applications`/`extra_applications` additions, and its `application.ex`/`router.ex`/`config.exs` carry Lockspire supervision children, routes, pipelines, and an `import_config` line the installer itself would generate. Committing this as-is would misrepresent the snapshot as a pristine pre-install host and leak a local dev path into the repo.
- **Fix:** Stripped all walk-added wiring back to genuine `mix phx.new` + `phx.gen.auth` output before committing; documented every removal and the rationale in the fixture's README.
- **Files modified:** all eight captured files under `priv/test_fixtures/phx_new_host/`, `priv/test_fixtures/phx_new_host/README.md`
- **Verification:** `mix test test/integration/install_host_interaction_test.exs --include integration`, `mix hex.build`, `mix qa`, `git status --porcelain`
- **Committed in:** `b9832b2` (part of Task 1 commit)

**2. [Rule 1 - Bug] Extended secret/salt stripping beyond the plan's literal `config/*.exs` scope**
- **Found during:** Task 1
- **Issue:** The plan's action text names only `config/*.exs` for secret stripping, but `lib/host_app_web/endpoint.ex`'s `@session_options` also carries a generated `signing_salt` literal.
- **Fix:** Replaced it with the same obvious-placeholder convention used for the other secrets.
- **Files modified:** `priv/test_fixtures/phx_new_host/lib/host_app_web/endpoint.ex`
- **Committed in:** `b9832b2` (part of Task 1 commit)

**3. [Rule 1 - Bug] `mix format` violation in the GREEN-phase manifest assertion**
- **Found during:** Task 2, post-GREEN `mix qa` run
- **Issue:** `Application.spec(:lockspire, :vsn) |> List.to_string()` wrapped in redundant parens tripped `mix format --check-formatted`.
- **Fix:** Removed the redundant parens.
- **Files modified:** `test/integration/install_generator_test.exs`
- **Verification:** `mix format --check-formatted`, `mix qa`
- **Committed in:** `6767a3c`

---

**Total deviations:** 3 auto-fixed (2 Rule 1/2 correctness+security, 1 Rule 1 formatter bug)
**Impact on plan:** All auto-fixes were necessary for the fixture to honestly represent what it claims to be, to avoid committing a machine-local path, and to keep `mix qa` green. No scope creep — Tasks 3 (router macro), 4 (config template), and the remaining `127-0N` plans are untouched.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `priv/test_fixtures/phx_new_host/` and `Lockspire.HostSnapshot` are now available for plan 127-07 (zero-bytes-written proof) and any later plan needing a real host to exercise the installer against.
- The router macro rewrite (D-08/D-09/D-10/D-11/D-12), config template fixes (D-13/D-14), plan-then-apply conflict semantics (D-16 through D-20), and the remaining point fixes (D-21 through D-27) are unstarted — this plan's proof currently exercises today's heredoc-based router template and today's `Enum.each`-based single-pass install. Later plans in this phase will need to keep `install_host_interaction_test.exs`'s assertions in sync as those templates change shape.
- No blockers. `mix test.fast`, `mix test.integration`, `mix qa`, and `mix hex.build` are all green with a clean `git status --porcelain`.

---
*Phase: 127-installer-against-a-real-host*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 13 created/modified files confirmed present on disk; all 4 task commits (`b9832b2`, `cf316d1`, `77d5ad9`, `6767a3c`) confirmed in `git log --oneline --all`.
