---
phase: 131-executable-installation
plan: "04"
subsystem: installation
tags: [ecto, migrations, installer, filesystem, security]
requires:
  - phase: 131-02
    provides: deterministic migration preflight and byte-identical migration application
  - phase: 131-03
    provides: executable generated-host installation coverage
provides:
  - immutable all-artifact install and upgrade operation plans
  - migration inventory audited in backward-compatible install manifests
  - public lifecycle proof for collision-safe migration delivery
affects: [installation, upgrade, generated-host, release-readiness]
tech-stack:
  added: []
  patterns: [combined filesystem preflight, process-scoped test migration source, manifest-last mutation]
key-files:
  created:
    - lib/lockspire/install/operation_plan.ex
  modified:
    - lib/lockspire/install/migrations.ex
    - lib/lockspire/install/manifest.ex
    - lib/lockspire/generators/install.ex
    - lib/mix/tasks/lockspire.upgrade.ex
    - test/integration/install_upgrade_test.exs
key-decisions:
  - "Install and upgrade render and validate managed files plus the complete migration inventory before either artifact class mutates the host tree."
  - "Manifest migration entries are audit-only; legacy manifests remain valid and filesystem preflight retains overwrite authority."
  - "The package migration fixture seam is process-scoped, test-only, and restored after each public lifecycle test."
requirements-completed: [INST-03]
coverage:
  - id: D1
    description: "Fresh installs and upgrades use one immutable all-artifact plan and write the manifest only after safe migration and scaffold application."
    requirement: INST-03
    verification:
      - kind: integration
        ref: "mix test test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Legacy manifests, repeat installs, additive upgrades, dry runs, and managed or migration collision snapshots retain host ownership and zero-mutation behavior."
    requirement: INST-03
    verification:
      - kind: integration
        ref: "test/integration/install_upgrade_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Installer-compatible generated-host behavior remains executable after migration delivery is introduced."
    requirement: INST-03
    verification:
      - kind: integration
        ref: "mix test test/integration/install_generator_test.exs"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-26
status: complete
---

# Phase 131 Plan 04: Atomic Install and Upgrade Summary

**Install and upgrade now approve one immutable plan across generated scaffolding, packaged migrations, and the final manifest before writing a host project.**

## Performance

- **Duration:** 18 min
- **Tasks:** 2/2
- **Files modified:** 7

## Accomplishments

- Added deterministic, string-keyed migration audit metadata to current manifests while retaining successful reads of v1.x manifests that omit it.
- Added `Lockspire.Install.OperationPlan`, which holds all rendered scaffold operations, migration operations, and the manifest payload behind one preflight/apply boundary.
- Routed public install and upgrade commands through the combined plan, including a process-scoped test-only migration-root seam for actual lifecycle proof.
- Proved fresh/repeat installs, additive upgrades, legacy manifests, dry runs, managed collisions, migration collisions, and late upgrade collisions leave unsafe host trees unchanged.

## Task Commits

1. **Task 1: Extend the install manifest with an old-compatible migration audit** — `119a6d4` (`feat`)
2. **Task 2: Execute one immutable all-artifact plan through public install and upgrade** — `fb16fcd` (`feat`)
3. **Static-analysis follow-up** — `e8773e8` (`refactor`)
4. **Documentation-contract follow-up** — recorded with this summary update (`docs`)

## Verification

- `mix test test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` — passed (22 tests).
- `mix test test/integration/install_generator_test.exs test/lockspire/install/migrations_test.exs test/integration/install_upgrade_test.exs` — passed (31 tests).
- `mix compile --warnings-as-errors` — passed.
- `mix qa` — passed: formatting, compilation, Credo, and Sobelow. Sobelow retains its existing no-router informational warning but reported a successful scan.
- `mix test test/lockspire/documentation_contract_test.exs` — passed (5 tests).
- `mix docs.verify` — passed.
- `mix test.fast --max-failures 1` — passed (1,313 tests; 252 integration tests excluded).

The named ASVS high-severity evidence for T-131-14, T-131-15, and T-131-16 is green through the public lifecycle collision and legacy-metadata tests.

## Decisions Made

- A manifest is an audit record, never an overwrite grant; migration safety is always recalculated from packaged and host files.
- The manifest is written last, after all validated migration and scaffold operations have applied successfully.
- Public commands retain familiar managed-file status output while migrations explicitly report `COPY` or `UNCHANGED`; dry runs report from the same approved plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Fixture cleanup] Reset generated-host migration directories between installer tests.**

- **Found during:** Task 2
- **Issue:** The existing generated-host reset helper did not remove new copied migrations, leaving test artifacts in the repository fixture after installer coverage ran.
- **Fix:** Added `priv/` cleanup to the existing reset helper.
- **Files modified:** `test/integration/install_generator_test.exs`
- **Verification:** The 31-test installer suite passes with no generated fixture files left untracked.
- **Committed in:** `fb16fcd`

**2. [Rule 1 - Static-analysis compatibility] Reduced new reporting complexity and documented the existing migration revalidation boundary.**

- **Found during:** Task 2
- **Issue:** `mix qa` flagged the new report helper and the exhaustive migration race validator for Credo cyclomatic-complexity review.
- **Fix:** Extracted report helpers and documented the intentionally exhaustive source/destination revalidation branch with a narrow Credo suppression.
- **Files modified:** `lib/lockspire/install/operation_plan.ex`, `lib/lockspire/install/migrations.ex`
- **Verification:** `mix qa` passes.
- **Committed in:** `e8773e8`

**3. [Rule 1 - Documentation-contract repair] Replaced the obsolete scaffold-only walkthrough with the immutable all-artifact boundary.**

- **Found during:** Wave 2 cumulative documentation gate
- **Issue:** The code walkthrough and its contract test still anchored the removed `write_manifest!/2` implementation, so documentation described a scaffold-only mutation flow that no longer exists.
- **Fix:** Documented `OperationPlan.build/4` and `apply/1`, including migration preflight, rendered-file validation, manifest-last ordering, and audit-only legacy-manifest behavior; moved the contract anchor to the real migration-plan preflight expression.
- **Files modified:** `docs/code-walkthrough.md`, `test/lockspire/documentation_contract_test.exs`
- **Verification:** Focused documentation contract, generated docs verification, and the fast suite all pass.

**Total deviations:** 3 auto-fixed (2 Rule 1, 1 Rule 3). **Impact:** The walkthrough now protects the same atomic host-tree boundary that the runtime enforces.

## Known Stubs

None.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration is required.

## Next Phase Readiness

The embedded installer now has an atomic, audited migration delivery path and public lifecycle proof suitable for the remaining executable-installation verification work.

## Self-Check: PASSED

- `lib/lockspire/install/operation_plan.ex` exists and is committed.
- Task commits `119a6d4`, `fb16fcd`, and `e8773e8` exist in git history.
- The current walkthrough anchor resolves to the immutable operation-plan preflight and all required tests, docs, and quality checks passed.
