---
phase: 170-packaged-host-and-compatibility-proof
plan: "02"
subsystem: testing
tags: [phoenix, liveview, chrome, cdp, clean-room, receipts, authorization]

requires:
  - phase: 170-packaged-host-and-compatibility-proof
    provides: Candidate package host and real-browser tracer from Plan 01
provides:
  - Exact 16-case packaged admin boundary receipts at default, nested, and root mounts
  - Real Chrome evidence for authorized navigation/reconnect, current-authority denial, and public protocol separation
  - Strict full-matrix receipt validation and supervised disposable-host authority observations
affects: [phase-170-03, phase-170-04, phase-170-05, packaged-host-proof]

actuals:
  tokens: 21868
  tasks: 2
  commits: 3
  plan_head_before: 76654caa9e15168b6aabac5baefb2fe48795a289
  plan_head_after: 9698b19631dd648e9c1193a17104ac3783828a98

tech-stack:
  added: []
  patterns: [real-browser CDP matrix, exact allowlisted case receipts, per-case authority counters]

key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/clients_live/index.ex
    - lib/lockspire/web/live/admin_layout_live.ex
    - scripts/acceptance/clean_room/admin_receipts.py
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room_admin_journey.py
    - test/browser/packaged_admin_proof.mjs
    - test/browser/packaged_admin_proof_test.mjs
    - test/clean_room/provider_host/admin_proof.exs
    - test/clean_room/test_admin_journey.py
    - test/lockspire/web/live/admin/admin_route_integration_test.exs

key-decisions:
  - "Use the same packaged host and isolated browser journey sequentially for each supported mount."
  - "Keep tracer receipts separate from the exact 16-case full receipt contract."
  - "Treat authorization as a boundary check; make no continuous-revocation or polling claim for an already connected socket."
  - "Keep A-170-01 and A-170-02 unclassified without inventing additional acceptance predicates."

patterns-established:
  - "Full receipts require every named case exactly once, typed counters, case-specific positive evidence, and cleanup success."
  - "Browser navigation and reconnect evidence comes from actual DOM actions, CDP document/socket events, and host-owned counters."

requirements-completed: [HPROOF-01]
coverage:
  - id: D1
    description: "Packaged admin operation, authorization boundaries, and public protocol access pass the complete browser matrix at all three supported mounts."
    requirement: HPROOF-01
    verification:
      - kind: e2e
        ref: ".artifacts/phase170/170-02-full-lockspire.json (16/16)"
        status: pass
      - kind: e2e
        ref: ".artifacts/phase170/170-02-full-teams-ops-identity.json (16/16)"
        status: pass
      - kind: e2e
        ref: ".artifacts/phase170/170-02-full-root.json (16/16)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact case-set, authorization-counter, and receipt-outcome validation rejects incomplete or malformed full evidence."
    requirement: HPROOF-01
    verification:
      - kind: unit
        ref: "node --test test/browser/packaged_admin_proof_test.mjs (7 passed)"
        status: pass
      - kind: unit
        ref: "python3 -m unittest discover -s test/clean_room -p test_admin_journey.py (13 passed)"
        status: pass
    human_judgment: false

duration: 50min
completed: 2026-10-24
status: complete
---

# Phase 170 Plan 02: Packaged Host Boundary Matrix Summary

**A candidate-installed Phoenix host now proves all 16 admin and public-boundary cases in real Chrome at default, nested, and root mounts.**

## Performance

- **Duration:** approximately 50 minutes; the executor start timestamp was not persisted, so this is an estimate.
- **Started:** approximately 2026-10-23T22:00:00-04:00.
- **Completed:** 2026-10-24T02:50:08Z.
- **Tasks:** 2/2.
- **Files modified:** 10.
- **Task commits:** 3, measured from the plan-head ledger.

## Accomplishments

- Extended the packaged browser proof to cover the exact cases `allowed_entry`, `assets`, `live_navigation`, `params_patch`, `detail_task`, `allowed_reconnect`, `anonymous_http_denied`, `nonstaff_http_denied`, `cached_join_denied`, `reconnect_denied`, `params_denied`, `public_session_denied`, `consent_session_denied`, `public_discovery`, `public_jwks`, and `public_protocol_error`.
- Ran each matrix sequentially against the installed candidate at `/lockspire`, `/teams/ops/identity`, and `/`. All three receipts contain 16 passed cases and report process, database, browser profile, and run-root cleanup as successful.
- Bound the final receipts to source revision `9698b19631dd648e9c1193a17104ac3783828a98`, candidate version `1.6.1`, archive SHA-256 `418060d9b6a786a0272fb02085da3d757100431005a81beb4d74fdd4a4d805cb`, and tree SHA-256 `aa9213a0eb1be4ca98a94f1fb388fe99a388ccdf8ca67c401d3130c89277face`. All three runs used the same identity and `locked` runtime pair.
- Observed Phoenix `1.8.13`, LiveView `1.2.10`, Elixir `1.20.4`, OTP `29`, Node `26.10.0`, and Chrome `155.0.8059.85` in each receipt. Browser case durations summed to 2.226 s, 2.225 s, and 2.216 s respectively.
- Fixed admin sidebar and client-detail links that caused full-document reloads instead of native LiveView navigation. The positive matrix now checks the destination, content, and connected host observation; reconnect uses the real `LiveSocket.disconnect()` and `.connect()` calls.
- Added separate host-owned public and consent LiveViews, supervised mutable authority state, and counters that show denial before protected callbacks or data markers. Public discovery, JWKS, and protocol-error requests run anonymously and record zero staff checks.

## Verification

- `node --check test/browser/packaged_admin_proof.mjs` — passed.
- `node --test test/browser/packaged_admin_proof_test.mjs` — 7 passed.
- `NO_COLOR=1 python3 -m unittest discover -s test/clean_room -p test_admin_journey.py` — 13 passed.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted test/clean_room/provider_host/admin_proof.exs` — passed.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` — 24 passed.
- Each full-matrix command used real Chrome with normal sandboxing and a locked candidate package:
  - `python3 scripts/acceptance/clean_room_admin_journey.py --pair locked --mount /lockspire --scenario full --receipt .artifacts/phase170/170-02-full-lockspire.json` — 16/16 passed.
  - `python3 scripts/acceptance/clean_room_admin_journey.py --pair locked --mount /teams/ops/identity --scenario full --receipt .artifacts/phase170/170-02-full-teams-ops-identity.json` — 16/16 passed.
  - `python3 scripts/acceptance/clean_room_admin_journey.py --pair locked --mount / --scenario full --receipt .artifacts/phase170/170-02-full-root.json` — 16/16 passed.

### TDD Gate Compliance

- **RED:** Commit `451c26ff` added `test_full_receipt_accepts_all_sixteen_named_boundary_cases`. The 11-test Python run failed at that assertion because the validator rejected the recognized full case set. `.artifacts/phase170/170-02-task2-red.json` records the complete report and semantic assessment; `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- **GREEN:** Commit `9698b196` implemented the exact full receipt contract and host/browser matrix. The final Node and Python suites passed, and all three installed-package browser runs passed 16/16.
- **REFACTOR:** None required.

## Task Commits

1. **Task 1: Run the complete connected journey at a nested mount and preserve root** — `80c02936` (`fix`).
2. **Task 2 RED: Require exact full browser case receipts** — `451c26ff` (`test`).
3. **Task 2 GREEN: Prove packaged admin boundary compatibility** — `9698b196` (`feat`).

## Decisions Made

- Keep the tracer case contract and full 16-case contract explicit and separate; exact identity, uniqueness, counters, observations, and cleanup are validated before a receipt is accepted.
- Reset host authority and browser cookies between cases. Public protocol scenarios begin from a same-origin unauthenticated host page and never share an admin login state.
- Treat denied redirects as allowed document transitions when authorization rejects a native params update; acceptance is the fresh denial and unchanged protected callback count.
- A successful boundary check proves behavior at that boundary. It does not promise immediate revocation of an already connected LiveView or introduce continuous policy polling.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve native LiveView navigation in production admin links**
- **Found during:** Task 1.
- **Issue:** The real nested browser journey showed sidebar and client-detail links performing full-document reloads, so the tracer could not prove same-session navigation.
- **Fix:** Switched those links to Phoenix LiveView `navigate` and added a regression assertion for no document reload.
- **Files modified:** `lib/lockspire/web/live/admin/clients_live/index.ex`, `lib/lockspire/web/live/admin_layout_live.ex`, and the admin route integration test.
- **Verification:** Real nested tracer passed and the focused route suite passed 24/24.
- **Committed in:** `80c02936`.

**2. [Rule 3 - Blocking issue] Pass the selected mount path into host overlays**
- **Found during:** Task 2.
- **Issue:** The generated fixture did not consistently scope its proof routes to the selected root or nested mount.
- **Fix:** Threaded the normalized mount path through overlay generation so mounted admin, public, and consent routes agree.
- **Files modified:** `scripts/acceptance/clean_room/build_provider.py`.
- **Verification:** Full matrices passed at `/lockspire`, `/teams/ops/identity`, and `/`.
- **Committed in:** `9698b196`.

**3. [Rule 1 - Bug] Keep full-matrix evidence schema-valid and case-specific**
- **Found during:** Task 2.
- **Issue:** One reconnect observation passed a boolean to a helper expecting observation names, and a failed run demoted all passing cases to failed in the receipt.
- **Fix:** Assigned the reconnect result to its boolean field and preserved each observed case outcome independently of the matrix-level outcome; added a regression test.
- **Files modified:** `test/browser/packaged_admin_proof.mjs`, `scripts/acceptance/clean_room_admin_journey.py`, `test/clean_room/test_admin_journey.py`.
- **Verification:** 7 Node tests, 13 Python tests, and all three full receipts passed.
- **Committed in:** `9698b196`.

**4. [Rule 1 - Test harness bug] Exercise public routes from the real host origin**
- **Found during:** Task 2.
- **Issue:** Fetching public endpoints from `about:blank` used an opaque origin and raised browser evaluation errors; the denied-params probe also incorrectly required a security redirect to preserve the document loader.
- **Fix:** Load the unauthenticated host login page before public requests and accept the expected fresh document transition after denied params while still requiring denial counters and no protected callback.
- **Files modified:** `test/browser/packaged_admin_proof.mjs`.
- **Verification:** All public status/shape checks and denied-params cases passed in the three full receipts.
- **Committed in:** `9698b196`.

**Total deviations:** 4 auto-fixed issues (3 Rule 1, 1 Rule 3). All were required to prove the planned behavior; no new dependency or architectural change was introduced.

## Issues Encountered

- During execution, the strict receipt correctly rejected an extra observation key, and the first public fetches exposed the browser's opaque-origin behavior. Both were corrected in the harness and rerun against the actual host. No production authorization-seam failure remained.
- The focused Elixir test emitted existing compile/type warnings in unrelated modules; the test suite completed successfully with 24 passed.

## Scope and Limits

- The browser matrix proves current authorization on HTTP entry, LiveView join/rejoin, params transition, and cross-session entry. It does not prove continuous reauthorization or immediate disconnect after policy changes on an already connected socket.
- Runtime-floor checks and required CI evidence belong to Plans 03 and 04. This plan's receipts prove the current locked pair only.
- Assumptions A-170-01 and A-170-02 remain unclassified as directed; this plan added no extra probe or acceptance predicate. No prior-phase closure was reopened.
- No known stubs or new production security surfaces were introduced. Proof controls are confined to the disposable host and protected by its local capability check.

## User Setup Required

None.

## Next Phase Readiness

Plan 03 can reuse the exact full case IDs, receipt validator, disposable host authority controls, and real browser matrix for the supported runtime floor. The current locked-pair evidence is source- and candidate-bound at `9698b196`.

## Self-Check: PASSED

- All three full receipts exist, validate against the full scenario set, contain 16 passed cases, and report successful cleanup.
- Task commits `80c02936`, `451c26ff`, and `9698b196` are ancestors of the plan head recorded above.
- The unrelated `.planning/state.json` bytes match `/private/tmp/lockspire-phase170-original-state.json` and remain unstaged.

---
*Phase: 170-packaged-host-and-compatibility-proof*
*Completed: 2026-10-24*
