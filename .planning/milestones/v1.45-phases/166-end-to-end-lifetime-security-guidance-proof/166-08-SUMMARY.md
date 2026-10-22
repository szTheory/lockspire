---
phase: end-to-end-lifetime-security-guidance-proof
plan: "08"
subsystem: auth/testing
tags: [elixir, ecto, postgresql, clean-room, client-lifetime]
requires:
  - phase: 166-02
    provides: Narrow lifetime selectors and safe default adapter composition
  - phase: 166-07
    provides: Packaged journey redaction and telemetry receipt foundations
provides:
  - Named host-owned PostgreSQL ClientStore and TransactionStore adapter example
  - Exact package-shipped ExUnit example executed in the candidate host
  - Custom packaged HTTP and independent durable rollback receipt scenarios
affects: [166-09, client-lifetime-docs, clean-room-acceptance]
actuals:
  tokens: 14968
  tasks: 2
  commits: 4
plan_head_before: 93e9ea7a52274a765db6f6f49d23fcfdef308ef1
plan_head_after: 324c4b6ecaece999cfd2a550b8232b0e9edd7aff
tech-stack:
  added: []
  patterns:
    - Named host adapter delegates through public ClientStore, TransactionStore and Repository seams
    - Packaged Markdown ExUnit is extracted verbatim and run against the host PostgreSQL schema
    - Late rollback is checked after completion through an independent PostgreSQL backend
key-files:
  created:
    - docs/examples/client-lifetime-adapter.md
    - test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex
    - test/acceptance/client_lifetime_receipt_test.py
    - test/acceptance/client_lifetime_boundary_test.py
  modified:
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room/package_input.py
    - scripts/acceptance/clean_room/lifetime_receipts.py
    - scripts/acceptance/clean_room_saas_journey.py
    - test/integration/client_lifetime_packaged_journey_test.exs
    - test/acceptance/client_lifetime_package_identity_test.py
key-decisions:
  - "The host wrapper composes the public default Repository and rewrites only the selected client and transaction participants."
  - "The receipt accepts only the three required custom outcomes and rejects missing observations or skipped scenarios."
requirements-completed: []
coverage:
  - id: D1
    description: "A named adapter is selected through normal host configuration and the exact packaged ExUnit example runs alongside real registration, S256 token issuance and management replacement."
    verification:
      - kind: integration
        ref: "test/integration/client_lifetime_packaged_journey_test.exs#custom packaged host journey"
        status: pass
      - kind: unit
        ref: "test/acceptance/client_lifetime_boundary_test.py (4 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Late client replacement and grant/token/audit failures leave durable state unchanged when read from distinct PostgreSQL backends."
    verification:
      - kind: integration
        ref: "client_lifetime_packaged_journey_test.exs; custom.shared_rollback (2/2), independent observer true"
        status: pass
      - kind: unit
        ref: "test/acceptance/client_lifetime_receipt_test.py (3 tests)"
        status: pass
    human_judgment: false
duration: 27min
completed: 2026-10-21
status: complete
---

# Phase 166 Plan 08: Packaged host lifetime adapter proof

**A clean-room Phoenix host now executes a named PostgreSQL lifetime adapter and its packaged ExUnit example through registration, issuance, replacement, rollback and fail-closed state checks.**

## Performance

- **Duration:** 27 minutes
- **Started:** 2026-10-22T01:02:41Z
- **Completed:** 2026-10-22T01:29:18Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `CleanRoomProvider.LifetimeClientStore`, selected through the normal `client_store` and `transaction_store` configuration and delegating only through documented public seams.
- Shipped one copyable ExUnit/Ecto module in Markdown and executed that exact code from the packaged candidate against the host PostgreSQL schema. Its four tests cover the configured authority, current-row guards, replacement rollback, issuance rollback and unsupported lifetime-state rejection.
- Exercised successful DCR registration, S256 token issuance and management credential replacement over production HTTP. The custom receipt recorded 31/31 executed checks passed, including 27 adapter callbacks, two independent rollback observations and one unsupported-state result; zero failures or skips. Cleanup recorded stopped processes, removed databases and removed temporary roots.
- Kept the boundary audit restrictive with four positive/negative controls, and added receipt validation controls for absent observations, missing scenarios and skipped required outcomes.

## Task Commits

1. **Task 1 RED:** `25c395fc` — boundary audit controls.
2. **Task 1 implementation:** `3ed0ade2` — packaged host adapter and custom journey.
3. **Task 2 RED:** `089a31eb` — rollback receipt assertions.
4. **Task 2 implementation:** `324c4b6e` — complete custom receipt validation.

## Verification

- `python3 -m unittest discover -s test/acceptance -p 'client_lifetime_*_test.py' -v` — 23 passed.
- `env ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase165_validation mix test --only integration test/integration/client_lifetime_packaged_journey_test.exs --max-failures 1 --timeout 900000` — 2 passed, 0 failed (64.4 seconds).
- Direct custom packaged journey — receipt verified with 3 required scenarios and aggregate counts `executed=31, passed=31, failed=0, skipped=0`; cleanup booleans all true.
- `git diff --check` — passed.

## Files Created/Modified

- `test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex` — host-owned adapter with shared PostgreSQL transaction authority and safe callback markers.
- `docs/examples/client-lifetime-adapter.md` — copyable packaged example, including separate-session rollback observation.
- `scripts/acceptance/clean_room_saas_journey.py` — custom leg selection, production route replacement, packaged test execution and receipt outcomes.
- `scripts/acceptance/clean_room/build_provider.py` — exact adapter audit exception and custom host config.
- `scripts/acceptance/clean_room/lifetime_receipts.py` — fail-closed custom scenario and observation checks.
- `scripts/acceptance/clean_room/package_input.py` — strict candidate verification for the actual Mix build path.
- `test/acceptance/client_lifetime_boundary_test.py`, `test/acceptance/client_lifetime_package_identity_test.py`, and `test/acceptance/client_lifetime_receipt_test.py` — boundary, provenance and receipt checks.
- `test/integration/client_lifetime_packaged_journey_test.exs` — packaged fresh/custom journey assertions.

## Decisions Made

- The adapter keeps the default repository as the authority and changes only the selected client and transaction participants to the named host module.
- Custom receipts require all three outcomes (`custom.issue_replace`, `custom.shared_rollback`, `custom.unsupported`) and exact positive observation fields.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Canonicalized the temporary Mix build path before candidate compilation**
- **Found during:** Task 1
- **Issue:** On macOS, the host path entered through `/var/...` while Mix resolved the vendored source through `/private/var/...`, creating a broken relative `priv` symlink. The candidate provenance check correctly refused to bind it.
- **Fix:** Resolve the exact environment-specific `MIX_BUILD_PATH` before compiling; candidate symlink validation remains strict.
- **Files modified:** `scripts/acceptance/clean_room/package_input.py`, `test/acceptance/client_lifetime_package_identity_test.py`
- **Verification:** Packaged fresh/custom journeys passed with candidate provenance verified.
- **Committed in:** `3ed0ade2`

**2. [Rule 1 - Bug] Passed the custom leg explicitly to its scenario builder**
- **Found during:** Task 1
- **Issue:** The runner’s parent process does not inherit environment changes made only to the provider child, so a successful custom journey was initially labeled as fresh in its receipt.
- **Fix:** Pass the selected leg as an explicit argument to the scenario builder.
- **Files modified:** `scripts/acceptance/clean_room_saas_journey.py`
- **Verification:** Custom receipt validation and both packaged integration legs passed.
- **Committed in:** `3ed0ade2`

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking issue). Both were necessary to execute the packaged proof with correct provenance and receipt identity.

## Issues Encountered

The candidate’s PostgreSQL tables use the host-configured schema prefix. The example now quotes that prefix for direct observer reads and trigger setup, so the same example works with prefixed and unprefixed schemas.

## User Setup Required

None - no external service configuration required beyond the documented disposable PostgreSQL database.

## Next Phase Readiness

Plan 08 proves the fresh and custom adapter slices. The broader fresh/legacy expansion remains pending Plan 09 as directed; no phase-wide requirements were marked complete here.

---
*Phase: end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-21*

## Self-Check: PASSED

All 11 plan files and evidence artifact exist; all four task commits are ancestors of the plan head. `git diff --check` passes.
