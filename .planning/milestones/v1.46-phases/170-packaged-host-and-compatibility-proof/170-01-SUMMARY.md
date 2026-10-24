---
phase: 170-packaged-host-and-compatibility-proof
plan: "01"
subsystem: packaged-host
tags: [phoenix, liveview, chrome, cdp, clean-room, receipts]
requires:
  - phase: 169-install-and-upgrade-convergence
    provides: candidate package builder, disposable host installer, and compiled candidate binding
provides:
  - real Chrome/CDP tracer for a package-installed Phoenix admin host
  - strict schema-1 source/candidate/runtime-bound browser receipts
  - deterministic browser and receipt failure tests
affects: [phase-170-plan-02, phase-170-plan-03]
actuals:
  tokens: 19295
  tasks: 2
  commits: 6
plan_head_before: b405327e71491c6c7aed7ecd33802cb27beb9fea
plan_head_after: 32e8fa449414094c335655c84273bc91e4273df8
tech-stack:
  added: []
  patterns: [real-browser CDP evidence, strict allowlisted receipts, built-in Node and Python tests]
key-files:
  created:
    - scripts/acceptance/clean_room_admin_journey.py
    - scripts/acceptance/clean_room/admin_receipts.py
    - test/clean_room/provider_host/admin_proof.exs
    - test/clean_room/provider_host/admin_proof_live_view.js
    - test/browser/packaged_admin_proof.mjs
    - test/browser/packaged_admin_proof_test.mjs
    - test/clean_room/test_admin_journey.py
  modified:
    - scripts/acceptance/clean_room/build_provider.py
    - lib/lockspire/web/admin_mount.ex
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-01-red-evidence.json
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-01-red-diagnostics-evidence.json
    - .planning/phases/170-packaged-host-and-compatibility-proof/170-01-red-runtime-evidence.json
key-decisions:
  - "Use installed Chrome with its normal sandbox and observe actual assets, WebSocket joins, and DOM navigation."
  - "Validate the admin route at HTTP entry; the connected LiveView socket represents the /live WebSocket URI, not the original page path."
  - "Keep proof authority state supervised and confined to the disposable host."
patterns-established:
  - "Browser receipts contain fixed enums, counters, booleans, observed versions, and candidate digests only."
  - "RED reports are persisted and classified before the corresponding GREEN implementation commit."
requirements-completed: [HPROOF-01]
coverage:
  - id: D1
    description: "Install a candidate package into a disposable Phoenix host and prove a real authorized admin LiveView join and navigation."
    requirement: HPROOF-01
    verification:
      - kind: automated_ui
        ref: "clean_room_admin_journey.py --pair locked --mount /lockspire --scenario tracer"
        status: pass
      - kind: integration
        ref: "test/lockspire/clean_room_admin_integration_test.exs + test/lockspire/clean_room_release_source_contract_test.exs"
        status: pass
    human_judgment: false
metrics:
  duration: 114min
  completed: 2026-10-23
status: complete
---

# Phase 170 Plan 01: Packaged Host Browser Tracer Summary

**A candidate-installed Phoenix host now proves real Chrome assets, an authorized LiveView join, and clients navigation with a source- and runtime-bound receipt.**

## Performance

- **Duration:** 114 min
- **Started:** 2026-10-23T20:20:28-04:00
- **Completed:** 2026-10-23T22:14:03-04:00
- **Tasks:** 2
- **Files modified:** 13 task files, plus this summary

## Accomplishments

- Added an opt-in disposable host proof overlay with a signed staff session, CSRF-protected sign-in, current host authorization checks, static Phoenix/LiveView assets, and capability-protected loopback controls.
- Added a packaged candidate journey that runs real headless Chrome with CDP, verifies LiveView join frames and overview-to-clients navigation, observes runtime versions, and removes its owned host, database, browser profile, and run root.
- Added strict receipt validation and deterministic Node/Python coverage for successful browser evidence, candidate binding, malformed receipt values, and hostile diagnostics.
- Kept generated provider authorization deny-by-default; only the explicitly opted-in disposable proof host installs the synthetic policy.

## Task Commits

1. **Task 1: Install the candidate and navigate one real connected browser session** — `208e5383` (`feat(170-01): prove packaged admin journey in Chrome`)
2. **Task 2: Make the tracer fail safely and retain existing host behavior** — RED `0bf871f3`, GREEN `31249602`; additional RED `81790951` and `45a10d1c`, GREEN `32e8fa44`.

## Files Created/Modified

- `scripts/acceptance/clean_room_admin_journey.py` — isolated candidate build, host lifecycle, browser invocation, and safe receipt writing.
- `scripts/acceptance/clean_room/admin_receipts.py` — strict receipt schema, source/candidate binding, observed-version formats, and atomic writes.
- `scripts/acceptance/clean_room/build_provider.py` — proof-only host overlay, selected mount configuration, asset serving, and proof-state supervision.
- `test/clean_room/provider_host/admin_proof.exs` — host authority, proof controls, login, route authorization, and root layout.
- `test/clean_room/provider_host/admin_proof_live_view.js` — real Phoenix LiveSocket bootstrap.
- `test/browser/packaged_admin_proof.mjs` and `test/browser/packaged_admin_proof_test.mjs` — real Chrome/CDP journey and deterministic Node helper tests.
- `test/clean_room/test_admin_journey.py` — receipt, identity, cleanup, malformed-input, and hostile-diagnostic tests.
- `lib/lockspire/web/admin_mount.ex` and `test/lockspire/web/live/admin/admin_route_integration_test.exs` — retain mount-path validation at the initial HTTP entry and cover the connected-socket path case.
- `.planning/phases/170-packaged-host-and-compatibility-proof/170-01-red-*.json` — captured, machine-validated TDD RED reports and semantic assessments.

## Verification

- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 python3 scripts/acceptance/clean_room_admin_journey.py --pair locked --mount /lockspire --scenario tracer --receipt .artifacts/phase170/tracer.json` — **passed** with 2 assets, 2 WebSocket handshakes, 1 successful join, 1 navigation, and all five host observations true. All four owned cleanup checks passed. Browser scenario duration: 643 ms.
- The final receipt validated with `python3 scripts/acceptance/clean_room/admin_receipts.py --check .artifacts/phase170/tracer.json` and the observed run ID, source revision, candidate archive/tree digests, locked pair, mount, and tracer scenario set — **receipt validated**.
- `node --test test/browser/packaged_admin_proof_test.mjs` — **4 passed**.
- `NO_COLOR=1 python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` — **9 passed**.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/clean_room_admin_integration_test.exs test/lockspire/clean_room_release_source_contract_test.exs` — **7 passed**.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` — **24 passed**.
- `node --check`, Python `py_compile`, and `git diff --check` — **passed**.

The final receipt observed Phoenix 1.8.13, LiveView 1.2.10, Elixir 1.20.4, OTP 29, Node 26.10.0, and Chrome 155.0.8059.85. Candidate package version was 1.6.1, archive SHA-256 `fffabfde990f69fea6f70336abe345ac36c76c954bdcb7fa051f91681e465e9c`, and tree SHA-256 `7d77bd1801f950024ccfe3e1ce5b6a0dd7bac891d923ea1933c8dc55ca8cc944`. The source was dirty during proof; the receipt records that fact and binds source revision `32e8fa449414094c335655c84273bc91e4273df8`.

## TDD Gate Compliance

- **RED `0bf871f3` → GREEN `31249602`:** 7-case Python run; the target assertion showed an unhashable scenario ID raised `TypeError` instead of safe validation. `check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- **RED `81790951` → GREEN `32e8fa44`:** 8-case Python run; the target assertion identified the missing strict allowlist for nested browser diagnostics. `check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- **RED `45a10d1c` → GREEN `32e8fa44`:** 9-case Python run; the target assertion showed arbitrary child-provided runtime strings were accepted into receipts. `check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Final deterministic suites passed with exact counts: Node 4 and Python 9.

## Decisions Made

- The browser test observes native CDP transport and actual page navigation. It does not synthesize Phoenix frames or treat an open socket as a successful join.
- HTTP route entry remains the mount-alignment boundary. The connected LiveView socket carries the WebSocket URI and cannot reliably repeat validation against the original page path.
- Proof authority state runs under the disposable host supervisor so request and LiveView processes cannot reset its observations.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Avoid the invalid connected-socket mount-path lookup**
- **Found during:** Task 1
- **Issue:** `AdminMount.on_mount/4` attempted to route-match a nil path from the connected socket and raised `FunctionClauseError` after real LiveView connection.
- **Fix:** Kept the real path check in `AdminMount.call/2`, which runs on the original HTTP request before LiveView issues its signed static token; removed only the duplicate WebSocket mount lookup.
- **Files modified:** `lib/lockspire/web/admin_mount.ex`, `test/lockspire/web/live/admin/admin_route_integration_test.exs`
- **Verification:** Final browser tracer and focused 24-test admin route integration suite passed.
- **Committed in:** `208e5383`

**2. [Rule 1 - Bug] Correct proof-host Phoenix/Plug and LiveView contracts**
- **Found during:** Task 1
- **Issue:** The synthetic login response lacked an HTML content type, the HTTP Plug used LiveView socket assignment, and the LiveView session callback had the wrong arity.
- **Fix:** Served the login form as HTML, used `Plug.Conn.assign/3` in the Plug and `Phoenix.Component.assign/3` in the hook, and defined the session callback with arity one.
- **Files modified:** `test/clean_room/provider_host/admin_proof.exs`
- **Verification:** Real Chrome login, overview render, and LiveView mount passed.
- **Committed in:** `208e5383`

**3. [Rule 2 - Missing Critical Functionality] Supervise the proof authority Agent**
- **Found during:** Task 1
- **Issue:** Starting the Agent from a short-lived request linked it to that request, resetting authorization observations before the receipt was read.
- **Fix:** Added the Store as a child only in the opt-in disposable proof host.
- **Files modified:** `scripts/acceptance/clean_room/build_provider.py`, `test/clean_room/provider_host/admin_proof.exs`
- **Verification:** Receipt recorded positive authorized HTTP and connected-hook counters across the full browser journey.
- **Committed in:** `208e5383`

**4. [Rule 1 - Bug] Bound malformed receipt and browser diagnostic values**
- **Found during:** Task 2
- **Issue:** Unhashable JSON values raised `TypeError`; nested browser dictionaries and runtime strings could be copied into diagnostics or receipts without allowlisting.
- **Fix:** Type-checked enum values, bounded diagnostic fields to fixed enums/counts/booleans, and required runtime strings to match observed version formats.
- **Files modified:** `scripts/acceptance/clean_room/admin_receipts.py`, `scripts/acceptance/clean_room_admin_journey.py`
- **Verification:** RED/GREEN Python tests and strict receipt validation passed; injected sentinel values were omitted.
- **Committed in:** `31249602`, `32e8fa44`

**Total deviations:** 4 auto-fixed (3 Rule 1, 1 Rule 2).
**Impact on plan:** Fixes were required to complete the actual browser path and keep retained evidence safe. No library dependency, publication, or remote write was added.

## Issues Encountered

- Chrome could not start in the default filesystem sandbox. The tracer ran with the installed browser’s normal sandbox through the authorized escalation path; no `--no-sandbox` option was used.
- The first page assertion expected stale copy (`Registered apps`); it was aligned with the actual clients page heading (`Apps`).

## User Setup Required

None.

## Next Phase Readiness

Plan 02 can extend the proven tracer to nested/root mounts and authorization denial/reconnect scenarios. The receipt and browser helpers now enforce source, candidate, runtime, cleanup, and output boundaries.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All six task commits are ancestors of the current HEAD.

---
*Phase: 170-packaged-host-and-compatibility-proof*
*Completed: 2026-10-23*
