---
phase: 163-app-lifetime-compatible-host-storage
plan: "01"
subsystem: database
tags: [elixir, ecto, postgres, client-lifetime, dcr]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: authoritative versioning, date precision, and migration contract
provides:
  - Prefix-aware additive client lifetime storage with legacy rows marked v0
  - Explicit app eligibility evaluation and deterministic DCR lifetime snapshots
  - Programmatic app-lifetime policy validation and regression fixture adoption
affects: [163-02, 163-03, 164, 165]
actuals:
  tokens: 20857
  tasks: 3
  commits: 1
tech-stack:
  added: []
  patterns:
    - Explicit lifetime version on every persisted client constructor
    - App lifetime snapshots evaluated at whole UTC seconds
key-files:
  created:
    - priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs
    - test/integration/app_lifetime_registration_test.exs
    - test/lockspire/protocol/app_lifetime_policy_test.exs
  modified:
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/client_metadata.ex
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/clients.ex
    - lib/lockspire/protocol/dcr_policy.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - test/support/token_exchange_case.ex
    - Existing persisted-client test fixtures across integration, protocol, storage, web, admin, worker, and mix-task tests (explicit legacy v0)
key-decisions:
  - "Missing or unknown lifetime versions fail closed; domain structs do not default to legacy."
  - "Existing persisted-client test fixtures explicitly identify themselves as legacy v0."
patterns-established:
  - "New client constructors explicitly write lifetime_version 1; migration default 0 is reserved for existing rows."
  - "App eligibility uses strict current-row checks at whole UTC second precision."
requirements-completed: [] # Partial slice; phase requirements await complete consumer/upgrade proof
coverage:
  - id: D1
    description: "DCR registration persists lifetime version 1 and an app deadline through PostgreSQL, with equality expired."
    requirement: DCR-05
    verification:
      - kind: integration
        ref: "test/integration/app_lifetime_registration_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Programmatic policy persistence and DCR resolution reject invalid application lifetimes."
    requirement: DCR-14
    verification:
      - kind: integration
        ref: "test/lockspire/protocol/app_lifetime_policy_test.exs"
        status: pass
    human_judgment: false
duration: 48min
completed: 2026-10-20
status: complete
plan_head_before: 31e2704bccf35ee09a10e03a5141da24fa77c037
plan_head_after: 262e66117ac8b6d1d575e5522b6423c346e297d9
commits: 1
---

# Phase 163 Plan 01: App Lifetime-Compatible Host Storage Summary

**New DCR clients now persist explicit versioned application lifetime state, and current-row eligibility enforces whole-second UTC deadlines while legacy rows remain unlimited.**

## Performance

- **Duration:** 48 min
- **Started:** 2026-10-20
- **Completed:** 2026-10-20
- **Tasks:** 3/3
- **Files modified:** 69, including compatibility updates to persisted-client test fixtures

## Accomplishments

- Added the additive, prefix-aware PostgreSQL expansion for lifetime version and app/management deadlines; existing rows receive version 0 and historical secret timestamps remain untouched.
- Added `Client.app_eligibility/3`, strict UTC-second deadline validation, and real registration-to-PostgreSQL round-trip coverage for finite and unlimited DCR clients.
- Added deterministic registration-time snapshots, explicit v1 operator construction, app-policy validation at resolution and Ecto persistence boundaries, and no-write checks for invalid policies.

## Task Commits

Parent-owned combined implementation commit: `262e66117ac8b6d1d575e5522b6423c346e297d9` — all three tasks and explicit legacy fixture compatibility adoption. Fresh parent verification: 117 tests, 0 failures. Plan base: `31e2704bccf35ee09a10e03a5141da24fa77c037`.

## Files Created/Modified

- `lib/lockspire/domain/client.ex` - lifetime fields and app eligibility decision.
- `lib/lockspire/storage/ecto/client_record.ex` - lifetime persistence and domain mapping.
- `priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs` - additive packaged migration.
- `lib/lockspire/client_metadata.ex`, `lib/lockspire/protocol/registration.ex`, `lib/lockspire/clients.ex` - deterministic v1 constructor paths and app deadline snapshot.
- `lib/lockspire/protocol/dcr_policy.ex`, `lib/lockspire/storage/ecto/server_policy_record.ex` - duration validation.
- `test/integration/app_lifetime_registration_test.exs`, `test/lockspire/protocol/app_lifetime_policy_test.exs` - focused runtime proof.
- Existing persisted-client test fixtures across integration, protocol, storage, web, admin, worker, and mix-task tests - explicit v0 for pre-contract rows.

## Decisions Made

- Missing and unknown lifetime versions are invalid server state; the domain struct remains nil by default so callers cannot silently opt into the legacy mode.
- Legacy persisted-client tests now state version 0 explicitly. This preserves the migration semantics without adding a production fallback.
- DCR metadata reapplication can receive an empty resolved policy map, so app expiry lookup uses an optional map field and leaves existing behavior intact when no policy is supplied.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Compatibility] Marked pre-contract persisted-client test fixtures explicitly as v0**
- **Found during:** Full-suite verification
- **Issue:** Existing tests constructed historical clients without a lifetime version, which the new required persistence field correctly rejected.
- **Fix:** Added explicit `lifetime_version: 0` to 120 direct repository fixtures, Ecto client-record fixtures, one DCR persistence fixture, and the shared token-exchange fixture. Kept missing/unknown-version negative cases and the empty `%Client{}` default assertion unchanged.
- **Files modified:** Existing test fixtures in integration, protocol, storage, web, admin, worker, and mix-task test trees; `test/support/token_exchange_case.ex`.
- **Verification:** Representative regression group passed (116 tests, 0 failures).
- **Committed in:** 262e66117ac8b6d1d575e5522b6423c346e297d9

**2. [Rule 1 - Bug] Kept DCR metadata reapplication compatible with absent resolved policy**
- **Found during:** Task 1
- **Issue:** `apply_dcr_metadata/2` calls the DCR builder with an empty resolved map, and direct field access raised `KeyError` after adding app-lifetime policy lookup.
- **Fix:** Read the optional duration with `Map.get/2`; no policy value continues to mean no app deadline.
- **Files modified:** `lib/lockspire/client_metadata.ex`.
- **Verification:** Focused registration and DCR policy tests passed (4 tests, 0 failures).
- **Committed in:** 262e66117ac8b6d1d575e5522b6423c346e297d9

**Total deviations:** 2 auto-fixed. Both preserve the selected contract; no dependency or Phase 164/165 behavior was added.

## Verification

- `mix test.setup` - passed; TestRepo storage was present and migrations were already up.
- `MIX_ENV=test mix test test/integration/app_lifetime_registration_test.exs test/lockspire/protocol/dcr_policy_invariant_test.exs test/lockspire/protocol/app_lifetime_policy_test.exs --max-failures 1` - passed, 4 tests, 0 failures.
- `MIX_ENV=test mix test test/integration/app_lifetime_registration_test.exs test/lockspire/protocol/app_lifetime_policy_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/admin/clients_test.exs test/lockspire/storage/ecto/client_record_test.exs --max-failures 1` - passed, 116 tests, 0 failures.
- `git diff --check` - passed.
- Baseline `mix test.fast` before fixture adoption completed with 2206 tests, 366 failures, 325 excluded, and 6 skipped. The dominant failures were missing-version legacy fixtures; 66 ReleaseArtifactChainContractTest failures could not resolve the `mix` executable in their subprocess environment. The orchestrator directed that no further broad run be started before parent-side fresh verification; the in-flight final attempt was stopped before producing a result.

## TDD Gate Compliance

- Task 1 RED: real registration reached PostgreSQL, then readback failed with `KeyError :lifetime_version`; GREEN: focused integration path round-tripped v1 and its deadline.
- Task 2 RED: invalid policy boundary cases were not rejected and DCR metadata reapplication crashed on an empty resolved map; GREEN: policy errors/no-write assertions and the optional-policy path passed.
- Task 3 RED: Ecto permissive casting accepted boolean `true` for the app duration; GREEN: raw value validation rejected invalid types/ranges while boundary values persisted and resolved.

## Issues Encountered

- The full-suite gate has not been rerun after legacy-fixture adoption. The baseline also showed 66 unrelated release-chain subprocess failures due to `mix` not being available on their subprocess PATH; parent-side fresh verification should report the final suite result.
- No production migration changes historical secret expiration values.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 01 storage and constructor foundations are implemented and focused tests pass. Plan 02 may attach the current-row eligibility decision to protocol consumers; management/RAT expiry remains outside this plan.

## Self-Check: PASSED

- Confirmed both new test files and the migration exist.
- Implementation commit `262e66117ac8b6d1d575e5522b6423c346e297d9` exists; measured implementation commits: 1.

---
*Phase: 163-app-lifetime-compatible-host-storage*
*Completed: 2026-10-20*
