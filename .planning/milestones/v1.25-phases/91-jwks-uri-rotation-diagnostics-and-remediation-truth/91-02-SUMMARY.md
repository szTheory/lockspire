---
phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth
plan: 02
subsystem: admin
tags: [jwks, diagnostics, admin, mix-task, support-truth]
requires: [91-01]
provides:
  - dedicated remote JWKS doctor command for runtime incidents
  - shared admin client-detail remote JWKS summary
  - explicit boundary between install verification and runtime remote JWKS diagnosis
affects: [91-03, support-truth, operator-surfaces]
tech-stack:
  added: []
  patterns: [shared diagnostics summary model, admin-consumes-runtime-truth]
key-files:
  created:
    - lib/mix/tasks/lockspire.doctor.remote_jwks.ex
    - test/mix/tasks/lockspire_doctor_remote_jwks_test.exs
  modified:
    - lib/lockspire/diagnostics/remote_jwks.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/admin/clients_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
key-decisions:
  - "Doctor and admin now render the same shared remote-JWKS summary model instead of inventing separate support vocabularies."
  - "Remote-JWKS status defaults to bounded reactive support truth and only renders a concrete incident when safe incident metadata is present on the client record."
patterns-established:
  - "Runtime support commands stay separate from install verification commands."
  - "Admin remains a consumer of shared diagnostics rather than the authority for remote-JWKS truth."
requirements-completed: [JWKS-01, JWKS-02]
duration: 24min
completed: 2026-05-25
---

# Phase 91 Plan 02: Expose Remote-JWKS Diagnostics Through Doctor And Operator Surfaces Summary

**Lockspire now ships one runtime support entrypoint and one admin summary model for remote `jwks_uri` incidents, both grounded in the shared bounded-reactive diagnostics truth from 91-01.**

## Performance

- **Duration:** 24 min
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `mix lockspire.doctor remote-jwks --client CLIENT_ID` as the dedicated runtime support entrypoint for remote-JWKS diagnosis, with calm output, one next step, and an explicit ownership split.
- Extended `Lockspire.Diagnostics.RemoteJwks` with reusable client-summary rendering so doctor output and admin UI consume the same support wording and incident model.
- Added `Lockspire.Admin.Clients.remote_jwks_summary/1` and rendered the shared summary on the admin client-detail screen for `private_key_jwt` clients using `jwks_uri`.
- Pinned the command boundary so `mix lockspire.verify` remains the install/onboarding diagnostic and the new doctor task explicitly does not cover migrations, host seams, or router wiring.

## Task Commits

1. **Task 1: Add a dedicated doctor-style remote-JWKS diagnostic command** - `445f511` (`feat`)
2. **Task 2: Expose the same remote-JWKS summary on admin client detail** - `a26dce5` (`feat`)
3. **Task 3: Prove the boundary between install verification and runtime diagnosis** - `dc6a266` (`docs`)

## Verification

- `mix test test/mix/tasks/lockspire_doctor_remote_jwks_test.exs` — PASS
- `mix test test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` — PASS
- `mix test test/mix/tasks/lockspire_doctor_remote_jwks_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` — PASS
- `rg -n "mix lockspire\\.doctor remote-jwks|mix lockspire\\.verify|Boundary:" lib/mix/tasks/lockspire.doctor.remote_jwks.ex` — PASS
- `rg -n "Remote JWKS|remote_jwks_summary|mix lockspire\\.doctor remote-jwks" lib/lockspire/web/live/admin/clients_live/show.ex` — PASS
- `rg -n "remote_jwks_summary|summarize_client" lib/lockspire/admin/clients.ex lib/lockspire/diagnostics/remote_jwks.ex` — PASS

## Decisions Made

- Remote-JWKS incident rendering is intentionally metadata-backed in this plan so the doctor/admin surfaces can consume shared truth without widening the runtime into background polling or durable incident storage.
- The default operator story for a `jwks_uri` client is “supported bounded reactive rollover,” and degraded incident copy appears only when normalized incident metadata is present.
- The new doctor command names the user-facing invocation as `mix lockspire.doctor remote-jwks` while remaining implemented as the `Mix.Tasks.Lockspire.Doctor.RemoteJwks` task module.

## Deviations from Plan

### Execution Scope

- The standard executor workflow would also update `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`, but those files were outside the user-approved write scope for this run.

### Auto-fixed Issues

- **1. [Rule 1 - Bug] Fixed remote-JWKS metadata decoding in the shared summary renderer**
  - **Found during:** Task 1 verification
  - **Issue:** Optional atom fields from metadata were being carried as `{:ok, atom}` tuples into rendered summary text.
  - **Fix:** Added atom unwrapping for optional metadata fields before building the incident struct.
  - **Files modified:** `lib/lockspire/diagnostics/remote_jwks.ex`
  - **Verification:** `mix test test/mix/tasks/lockspire_doctor_remote_jwks_test.exs`
  - **Commit:** `445f511`

- **2. [Rule 1 - Bug] Removed a new mix-task compile warning before plan completion**
  - **Found during:** Task 1 verification
  - **Issue:** The initial doctor task output used `&Mix.shell().info/1`, which produced a compile warning.
  - **Fix:** Switched to a regular anonymous function for task output and removed an unused default argument from a private helper.
  - **Files modified:** `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`, `lib/lockspire/diagnostics/remote_jwks.ex`
  - **Verification:** `mix test test/mix/tasks/lockspire_doctor_remote_jwks_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs`
  - **Commit:** `445f511`

**Total deviations:** 2 auto-fixed
**Impact on plan:** No scope or behavior drift beyond the planned surfaces. The fixes were contained to the new summary/doctor implementation.

## Known Stubs

None.

## Self-Check: PASSED

- All created and modified plan files exist on disk.
- Task commits `445f511`, `a26dce5`, and `dc6a266` exist in git history.
- Plan-level verification commands passed.
