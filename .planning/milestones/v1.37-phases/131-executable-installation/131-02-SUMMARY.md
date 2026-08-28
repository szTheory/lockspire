---
phase: 131-executable-installation
plan: "02"
subsystem: installation
tags: [ecto, migrations, installer, filesystem, security]
requires: []
provides:
  - deterministic-migration-preflight
  - byte-identical-idempotent-migration-apply
affects: [131-04, installation, upgrade]
tech_stack:
  added: []
  patterns: [read-only inventory preflight, checksum collision detection, exclusive host file creation]
key_files:
  created:
    - lib/lockspire/install/migrations.ex
    - test/lockspire/install/migrations_test.exs
  modified: []
decisions:
  - Migration planning validates the entire packaged and host inventory before it creates any host migration directory or file.
  - Approved plans are revalidated and copied with exclusive file creation so a changed source or newly appearing host file cannot be overwritten.
metrics:
  duration: 4m
  completed: 2026-08-26
  tasks_completed: 2
  files_changed: 2
status: complete
---

# Phase 131 Plan 02: Safe Migration Delivery Summary

Lockspire now provides a deterministic migration preflight and byte-identical, no-overwrite copier for installation and upgrade orchestration.

## Tasks Completed

1. **Specify the complete migration preflight matrix** — Added isolated temporary-directory coverage for fresh files, byte-identical repeats, content/version/name collisions, malformed package names, and a late collision proving no partial host copy occurs. Implemented `Lockspire.Install.Migrations.plan/1` with deterministic source and host inventory checks using `Manifest.checksum/1`.
2. **Apply only an approved migration plan byte-for-byte** — Added `apply/1`, which validates the plan again before creating the destination directory, uses exclusive writes for missing files only, preserves unchanged files, and returns a stable manifest-ready inventory.

## Verification

- `mix test test/lockspire/install/migrations_test.exs` — 11 tests passed.
- `mix compile --warnings-as-errors` — passed.
- `mix format --check-formatted lib/lockspire/install/migrations.ex test/lockspire/install/migrations_test.exs` — passed.

The named ASVS T-131-05 and T-131-06 evidence is green: the test suite covers exact content, version, and name collisions plus a late collision with no earlier destination mutation.

## Commits

- `3952b82` — `test(131-02): specify migration preflight matrix`
- `4dc96b9` — `feat(131-02): preflight packaged migrations`
- `42c6491` — `test(131-02): prove approved migration application`
- `6d97320` — `style(131-02): format migration installer`

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 2 - Race-safe application] Revalidated approved plans immediately before mutation**
   - **Found during:** Task 2
   - **Issue:** A file could change or appear after a successful read-only preflight; a normal copy operation could then overwrite a host migration.
   - **Fix:** Re-check source checksums and destination state before directory creation, then create copied files with exclusive-write mode.
   - **Files modified:** `lib/lockspire/install/migrations.ex`, `test/lockspire/install/migrations_test.exs`
   - **Verification:** The isolated suite proves changed packaged bytes and a newly appearing host migration both fail without overwrite.
   - **Commit:** `4dc96b9`, `42c6491`

**Total deviations:** 1 auto-fixed (Rule 2). **Impact:** The package-to-host trust boundary remains no-overwrite even if the filesystem changes between preflight and apply.

## Self-Check: PASSED

- The migration service and its isolated filesystem test suite exist and are committed.
- All four task commits are present in git history.
- No stubs, skipped tests, or unrun plan verification remain.
