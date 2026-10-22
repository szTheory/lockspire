---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "09"
subsystem: testing
tags: [elixir, phoenix, postgres, oauth, client-lifetimes, packaged-acceptance]

requires:
  - phase: 166-end-to-end-lifetime-security-guidance-proof
    provides: Packaged provider host and custom adapter cutover proof from plan 08
provides:
  - Independent candidate-bound fresh lifetime HTTP journeys
  - Pinned-old DCR credential use, grandfathering, and current-policy HTTP promotion proof
affects: [client-lifetimes, packaged-acceptance, migration-cutover]

actuals:
  tokens: 20511
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 56ce12c9
plan_head_after: 2766cd29a98ffe647c8fcf5eab395e3c52522b91

tech-stack:
  added: []
  patterns:
    - Candidate-bound packaged HTTP acceptance across public and tenant_auth storage prefixes
    - Safe legacy credential transfer and receipt-only runtime observations

key-files:
  created:
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-09-01-RED.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-09-02-RED.json
  modified:
    - scripts/acceptance/clean_room_saas_journey.py
    - scripts/acceptance/clean_room/lifetime_receipts.py
    - scripts/acceptance/clean_room/client_lifetime_upgrade.py
    - test/acceptance/client_lifetime_receipt_test.py
    - test/acceptance/client_lifetime_upgrade_test.py
    - test/clean_room/lifetime_upgrade_scenarios.exs
    - test/integration/client_lifetime_packaged_journey_test.exs
    - test/integration/app_lifetime_packaged_upgrade_test.exs

key-decisions:
  - "Use authenticated PAR before the browser authorization flow because the packaged host's active security profile requires it."
  - "Keep v0 advisory secret dates distinct from new v1-only application and management deadline columns; explicitly replace through HTTP before authoritative lifetime policy applies."

patterns-established:
  - "Legacy cutover proof carries the pinned-old self-registered credential through the candidate's real PAR, authorization, token, and management routes."
  - "Promotion receipts assert whole-row normalization, current-policy wire deadlines, persisted audit evidence, and preservation of unrelated client authority."

requirements-completed: [DCR-15, DCR-17, DCR-18]
coverage:
  - id: D1
    description: "Packaged fresh registration, use, independent expiry, secret rotation, management replacement, and host-authorized recovery"
    requirement: DCR-15
    verification:
      - kind: integration
        ref: "test/integration/client_lifetime_packaged_journey_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pinned-old credentials remain usable with advisory secret dates and promote under current policy across both prefixes"
    requirement: DCR-17
    verification:
      - kind: integration
        ref: "test/integration/app_lifetime_packaged_upgrade_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Legacy migration checksums, old-writer cutover, candidate identity, and no-old-binary boundary remain verified"
    requirement: DCR-18
    verification:
      - kind: integration
        ref: "test/integration/app_lifetime_packaged_upgrade_test.exs"
        status: pass
    human_judgment: false

duration: 84min
completed: 2026-10-21
status: complete
---

# Phase 166 Plan 09: Packaged Fresh and Legacy Lifetime Journeys Summary

**Candidate-bound packaged HTTP journeys now prove independent fresh lifetime gates and real pinned-old credential use and promotion across both storage prefixes.**

## Performance

- **Duration:** 84 minutes
- **Started:** 2026-10-21T21:30:50-04:00
- **Completed:** 2026-10-21T22:54:31-04:00
- **Tasks:** 2
- **Files changed:** 10

## Accomplishments

- Added independent fresh HTTP scenarios for secret expiry and rotation, management PUT and host recovery, and expired/disabled applications. Receipts require real route outcomes and positive persisted audit counts.
- Exercised a DCR client and credentials created by pinned Lockspire 1.6.1 against the candidate. Its past-dated v0 secret advisory value did not block PAR, S256 authorization, login, consent, or code redemption.
- Promoted that legacy row through candidate HTTP management PUT. The receipt verifies v1 canonicalization, unlimited app lifetime, new current-policy management and secret deadlines, old-token rejection, replacement-token acceptance, audit persistence, and preservation of unrelated client authority.
- Ran the same candidate through `public` and `tenant_auth`, retaining migration checksums, old-writer drain before v1 writes, and the no-old-binary postactivation boundary.

## Task Commits

1. **Task 1 RED: fresh lifetime receipt assertions** — `a1f3bb1e` (`test`)
2. **Task 1 GREEN: fresh packaged lifetime journeys** — `b7d1e927` (`feat`)
3. **Task 2 RED: legacy HTTP upgrade receipt assertions** — `d30ba584` (`test`)
4. **Task 2 GREEN: candidate legacy HTTP promotion** — `2766cd29` (`feat`)

## Verification

- `python3 -m py_compile scripts/acceptance/clean_room/client_lifetime_upgrade.py scripts/acceptance/clean_room_saas_journey.py` — passed.
- `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_receipt_test.py' -v` — 5 tests passed.
- `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_upgrade_test.py' -v` — 2 tests passed.
- `mix test --only integration test/integration/app_lifetime_packaged_upgrade_test.exs --max-failures 1 --timeout 900000` — 1 test passed; receipt assertions covered both prefixes.
- `mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` — 2 tests passed, including the fresh packaged host and shipped custom-adapter leg.
- Combined plan command for both integration files — 3 tests passed, 0 failures.
- Both RED records passed `gsd_run check tdd-red-evidence` with `RED_EVIDENCE_OK`; their target tests failed on the intended missing-receipt assertions. GREEN runs passed.
- No skipped scenarios or added dependencies. Ten temporary debug roots containing task-owned test credentials were removed after verification.

## TDD Gate Compliance

- **Task 1 RED:** `166-09-01-RED.json` records `test_fresh_lifetime_scenarios_require_real_route_outcomes_and_positive_events` failing because a zero event count was accepted. The evidence classifier returned `RED_EVIDENCE_OK`; GREEN is the paired `b7d1e927` commit.
- **Task 2 RED:** `166-09-02-RED.json` records `test_legacy_prefix_requires_http_use_promotion_and_state_preservation` failing because the validator accepted a receipt with no runtime HTTP evidence. The evidence classifier returned `RED_EVIDENCE_OK`; GREEN is the paired `2766cd29` commit.
- No separate refactor commit was needed after the passing packaged journeys.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Count persisted host-disable audit events in the fresh receipt**
- **Found during:** Task 1
- **Issue:** The receipt used a placeholder count and did not prove that host-owned disable setup persisted an audit event.
- **Fix:** Counted the client's stored audit events before and after the host disable action and recorded the positive delta.
- **Files modified:** `scripts/acceptance/clean_room_saas_journey.py`
- **Verification:** Fresh packaged journey integration passed, including actual positive audit-count assertions.
- **Committed in:** `b7d1e927`

**2. [Rule 1 - Bug] Validate legacy HTTP receipts against actual PAR and promotion outcomes**
- **Found during:** Task 2
- **Issue:** Legacy receipts represented historical rows but did not prove an old credential worked on candidate HTTP routes or was explicitly replaced.
- **Fix:** Added pinned-old DCR credential transfer, candidate PAR and S256 browser flow, current-policy management PUT, whole-row preservation checks, secret rotation, and receipt validation.
- **Files modified:** `scripts/acceptance/clean_room/client_lifetime_upgrade.py`, `test/acceptance/client_lifetime_upgrade_test.py`, `test/clean_room/lifetime_upgrade_scenarios.exs`, `test/integration/app_lifetime_packaged_upgrade_test.exs`
- **Verification:** Packaged upgrade integration passed both prefixes and validated the resulting receipt.
- **Committed in:** `2766cd29`

**3. [Rule 1 - Bug] Align audit SQL with each configured storage prefix**
- **Found during:** Task 2
- **Issue:** The upgrade assertion queried a hard-coded schema rather than the active prefix.
- **Fix:** Validated the configured schema identifier and queried audit events in that schema.
- **Files modified:** `scripts/acceptance/clean_room/client_lifetime_upgrade.py`
- **Verification:** Packaged upgrade integration passed for `public` and `tenant_auth`.
- **Committed in:** `2766cd29`

## Issues Encountered

- The host's security profile requires PAR, so the legacy proof now uses authenticated PAR before the browser flow.
- A v0 row cannot carry v1-only application or management deadlines. The fixture keeps the expired secret date as historical advisory data and leaves the new management deadline nil until candidate HTTP replacement canonicalizes the row.
- The secret verifier is credential-derived and may rotate with the client secret; preservation checks instead target the unrelated management authority, identity, enabled state, redirect URIs, scopes, grants, and authentication policy.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Packaged fresh and upgrade acceptance now cover real route behavior for the lifetime contract. Deterministic equality-boundary behavior remains covered by injectable-clock tests.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-21*

## Self-Check: PASSED

- Summary file written at the planned path.
- Both RED evidence records and all four task commits exist in the current branch history.
- Required acceptance, packaged integration, and RED-evidence checks passed.
- Pre-existing `.planning/STATE.md`, `.planning/state.json`, and `.planning/ROADMAP.md` edits were left untouched.
