---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "01"
subsystem: testing
tags: [python, elixir, postgres, oauth, pkce]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed lifetime semantics and 69 normative contract cases
  - phase: 163-app-lifetime-compatible-host-storage
    provides: App lifetime implementation and focused evidence
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: Shared-secret expiry and atomic rotation
  - phase: 165-management-token-lifecycle-recovery
    provides: Management-token lifecycle and host recovery
provides:
  - A packaged-host DCR registration and S256 authorization-code tracer over production HTTP routes
  - A bounded receipt schema that validates candidate identity, positive observations, counts, and cleanup
  - A 69-case map linking Phase 162 contracts to inherited evidence, pending reruns, and the new tracer
affects: [phase-166-packaged-proof, phase-166-evidence-map, clean-room-acceptance]
actuals:
  tokens: 23745
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 6b826f659f9cadcbef91ef36c79b3df34996b091
plan_head_after: d6c161aa690ab552effcd79f1738a8c83be2ae39
tech-stack:
  added: []
  patterns: [allowlisted execution receipts, candidate archive and tree identity, packaged production-route tracer]
key-files:
  created:
    - scripts/acceptance/clean_room/lifetime_receipts.py
    - test/integration/client_lifetime_packaged_journey_test.exs
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-EVIDENCE-MAP.json
  modified:
    - scripts/acceptance/clean_room_saas_journey.py
key-decisions:
  - "Configure open registration and exact loopback allowlists only inside the isolated packaged host so the HTTP journey exercises public DCR and S256 routes without adding a product clock or public route."
  - "Bind receipt evidence to the source revision, a freshly built archive digest, and the unpacked candidate tree digest; keep the receipt limited to allowlisted observations and aggregate counts."
  - "Mark all inherited contract rows pending final-candidate rerun; the new tracer receipt proves registration and code redemption only, not lifetime durations or broader Phase 166 requirements."
patterns-established:
  - "A packaged proof runner can select a provider-only DCR leg while preserving the existing runner modes and cleanup boundary."
  - "Receipt validation requires the exact scenario set, positive executed and passed counts, reconciled totals, and observed cleanup."
requirements-completed: []
coverage: []
duration: 13min
completed: 2026-10-21
status: complete
---

# Phase 166 Plan 01: End-to-End Lifetime, Security & Guidance Proof Summary

**A freshly built Lockspire candidate registered a public client and redeemed its S256 authorization code through a packaged Phoenix host’s production HTTP routes; the traceability map keeps all 69 contract cases and future proof obligations explicit.**

## Performance

- **Duration:** Approximately 13 minutes (four tracer attempts; the final run completed in 30.9 seconds).
- **Started:** 2026-10-21T23:54:00Z (approximate; execution start was not timestamped separately).
- **Completed:** 2026-10-22T00:06:48Z.
- **Tasks:** 2/2.
- **Files modified:** 4.

## Accomplishments

- Added `--only dcr_lifetime`, which builds and installs one candidate in an isolated provider host, registers a new public client through the advertised DCR endpoint, and completes login, consent, S256 authorization, and token redemption through production routes.
- Added a strict allowlisted receipt writer/checker. The passed `fresh.register_use` receipt reports registration HTTP 201, token HTTP 200, an issued access token, S256, counts of 1 executed / 1 passed / 0 failed / 0 skipped, and successful process/database/temp-root cleanup.
- Mapped all 69 Phase 162 cases to actual inherited test modules and commands. The map distinguishes pending final-candidate reruns from this tracer’s narrower observed evidence, includes all DCR-15–19 IDs, and preserves the three flagged assumptions and two unverified prohibitions.

## Verification

- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` — **1 test, 0 failures**. The wrapper also checked the candidate-bound receipt and cleanup observations.
- The tracer receipt recorded 1 executed / 1 passed / 0 failed / 0 skipped required scenarios. No skipped scenario passed as evidence; other test files were outside this selected invocation and are not counted as executed.
- Plan map assertion — **69/69 contract case IDs**, all five requirement IDs, all referenced files present, probe count equality `9 = 6 + 3`, and both prohibitions retained.
- `python3 -m py_compile scripts/acceptance/clean_room_saas_journey.py scripts/acceptance/clean_room/lifetime_receipts.py` and `git diff --check` passed.

The tracer does not assert actual lifetime duration values, race behavior, fresh/legacy/custom-store expansion, final CI, security review, or guidance. Those remain pending for their assigned Phase 166 plans; the evidence map keeps the inherited cases marked for final-candidate rerun.

## Task Commits

1. **166-01-01: Register and use one candidate through the packaged production HTTP stack** — `cb1df27d` (`feat`).
2. **166-01-02: Map fixed cases and inherited proof without manufacturing new suites** — `d6c161aa` (`docs`).

**Plan metadata:** To be recorded in the plan-summary commit.

## Files Created/Modified

- `scripts/acceptance/clean_room_saas_journey.py` — packaged DCR scenario, candidate archive/tree identity, receipt options, and provider-only lifecycle.
- `scripts/acceptance/clean_room/lifetime_receipts.py` — allowlisted receipt serialization and positive-count/cleanup validation.
- `test/integration/client_lifetime_packaged_journey_test.exs` — active bounded integration wrapper for the real package and HTTP journey.
- `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-EVIDENCE-MAP.json` — inherited/new evidence map and pending probe obligations.

## Decisions Made

- Kept setup policy and loopback allowlists inside the isolated host process; no public protocol route or clock control was added.
- Used a freshly generated package archive digest plus the actual unpacked package tree digest to identify the candidate used by the provider host.
- Kept the contract map as a traceability assertion: passing prior-phase tests and the new tracer do not by themselves close the broader requirements.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the new DCR tracer’s fixture and HTTP request handling**
- **Found during:** Task 1.
- **Issue:** The first implementation attempted to change persisted policy while the host listener already owned its port, submitted an unsupported caller-supplied `client_id`, and encoded DCR metadata as form data rather than JSON. Public token redemption also needed `client_id` in its request body.
- **Fix:** Moved isolated policy setup before listener startup, configured only the allowed loopback metadata axes, let DCR assign the client ID, sent JSON to registration, and included the assigned ID at the public token endpoint.
- **Files modified:** `scripts/acceptance/clean_room_saas_journey.py`.
- **Verification:** The final exact packaged integration command passed with 1/0 tests and the receipt validated positive counts and cleanup.
- **Committed in:** `cb1df27d`.

**Total deviations:** 1 auto-fixed bug. **Impact:** Required corrections to make the planned real HTTP journey execute; no scope expansion.

## Issues Encountered

Three early end-to-end runs stopped before issuing a token and produced no passing receipt: the setup/listener port collision, invalid DCR metadata, and form-encoded registration. A subsequent run reached token redemption but omitted the public client ID. All were corrected before the successful tracer run. Diagnostics expose only normalized OAuth error identifiers and field/reason names.

## User Setup Required

None - the packaged integration test uses the repository’s configured local PostgreSQL test setup and toolchain.

## Next Phase Readiness

Plan 166-02 can consume the receipt interface and add stale-candidate identity negatives. The complete Phase 162 contract, final-candidate reruns, PostgreSQL schedules, custom adapter proof, CI, security review, and guidance remain open.

## Self-Check: PASSED

- All four task artifacts and this summary exist.
- Both task commits are ancestors of the current branch HEAD.
- The 69-case map and requirement-union verifier passed again after summary creation.
- `git diff --check` passed.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-21*
