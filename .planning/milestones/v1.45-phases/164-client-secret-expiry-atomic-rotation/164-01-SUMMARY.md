---
phase: 164-client-secret-expiry-atomic-rotation
plan: "01"
subsystem: auth
tags: [oauth, dcr, client-secret, expiry, ecto, postgres]
requires:
  - phase: 163
    provides: Client lifetime adapter, migration and isolated PostgreSQL test configuration
provides:
  - Strict shared-secret eligibility and effective deadline domain helpers
  - Bounded server secret-lifetime policy validation at persistence and registration use
  - Method/version-aware DCR secret expiry metadata for success, read and update responses
affects: [164-02, 164-03, 164-04, 164-05, 164-06, client-secret-authentication, registration-metadata]
actuals:
  tokens: 8269
  tasks: 3
  commits: 9
plan_head_before: a1a55de0a931c641fbe176e5c3f9c4737aa62b9d
plan_head_after: ebcce49d52b2b9b1902e87cf447a9e8b413318dd
tech-stack:
  added: []
  patterns:
    - Validate original domain policy values before Ecto numeric casting
    - Compute and serialize secret deadlines from versioned, method-aware domain state
key-files:
  created:
    - test/integration/client_secret_lifetime_registration_test.exs
    - test/lockspire/protocol/client_secret_lifetime_policy_test.exs
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-01-01-red-evidence.json
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-01-02-red-evidence.json
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-01-03-red-evidence.json
  modified:
    - lib/lockspire/domain/client.ex
    - lib/lockspire/client_metadata.ex
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/dcr_policy.ex
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - lib/lockspire/web/registration_json.ex
    - test/lockspire/web/registration_json_test.exs
    - test/lockspire/web/controllers/registration_controller_test.exs
key-decisions:
  - "Treat malformed host secret-lifetime policy as server_error, separate from registrant metadata errors."
  - "Strip atom- and string-keyed raw secret metadata before writing the effective response fields."
requirements-completed: []
coverage:
  - id: D1
    description: "DCR issues a finite secret deadline that matches durable storage and wire metadata, and Basic auth rejects at equality."
    verification:
      - kind: integration
        ref: "test/integration/client_secret_lifetime_registration_test.exs#DCR stores, advertises, and enforces the finite Basic secret deadline"
        status: pass
      - kind: unit
        ref: "test/lockspire/protocol/client_app_authentication_test.exs#all supported authentication methods reject app expiry at equality"
        status: pass
    human_judgment: false
  - id: D2
    description: "Secret lifetime policy accepts only nil or bounded integers at writes and use, while bad configuration produces server_error without client writes."
    verification:
      - kind: integration
        ref: "test/lockspire/protocol/client_secret_lifetime_policy_test.exs and test/lockspire/web/controllers/registration_controller_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Success, read and update registration payloads expose only effective method/version-aware deadlines and never raw secret metadata."
    verification:
      - kind: integration
        ref: "test/lockspire/web/registration_json_test.exs and test/integration/client_secret_lifetime_registration_test.exs"
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-10-21
status: complete
---

# Phase 164 Plan 01: Client Secret Expiry and Atomic Rotation Summary

**DCR secret issuance now snapshots a strict finite deadline, enforces it at the Basic authentication boundary, and reports only truthful effective expiry metadata.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-10-21T13:47:44Z
- **Completed:** 2026-10-21T14:04:41Z
- **Tasks:** 3
- **Files modified:** 15, including three committed RED evidence records

## Accomplishments

- Added strict secret eligibility, effective-deadline and issuance-deadline helpers; DCR issuance and Basic authentication use the same stored deadline.
- Validated the original secret policy value at persistence and DCR resolution boundaries. Invalid host policy maps to `server_error`, and registration does not write a client.
- Made registration success/read/update serializers respect auth method and lifetime version, including unlimited nil/zero, legacy v0, policy-edit stability, and raw metadata removal.

## Task Commits

1. **Task 1 RED: finite Basic deadline tracer** - `e6e48f26` (test)
2. **Task 1 GREEN: enforce finite DCR shared-secret expiry** - `64057b09` (feat)
3. **Task 2 RED: invalid secret policy boundaries** - `09599c41` (test)
4. **Task 2 GREEN: validate DCR secret lifetime policy** - `5a8f7097` (fix)
5. **Task 3 RED: metadata and lifetime edge cases** - `1f971701` (test)
6. **Task 3 GREEN: strip advisory secret metadata** - `b059cb8d` (fix)
7. **Integrated auth-test closure: separate app and secret expiry assertions** - `ebcce49d` (test)

Plan metadata commits: `8a07ff05` (summary), `770a9344` (STATE/ROADMAP progress); this summary refresh is committed separately.

## Files Created/Modified

- `lib/lockspire/domain/client.ex` - strict secret eligibility and lifetime helper interfaces.
- `lib/lockspire/client_metadata.ex` - snapshots a validated secret deadline at DCR issuance.
- `lib/lockspire/protocol/client_auth.ex` - rejects shared-secret authentication at the exact expiry instant.
- `lib/lockspire/protocol/dcr_policy.ex`, `lib/lockspire/protocol/registration.ex`, and `lib/lockspire/storage/ecto/server_policy_record.ex` - validate secret policy and distinguish server configuration errors.
- `lib/lockspire/web/registration_json.ex` - emits method/version-aware expiry and removes raw atom/string secret metadata.
- `test/integration/client_secret_lifetime_registration_test.exs`, `test/lockspire/protocol/client_secret_lifetime_policy_test.exs`, `test/lockspire/web/registration_json_test.exs`, and `test/lockspire/web/controllers/registration_controller_test.exs` - registration, policy, controller and serialization coverage.
- `164-01-01-red-evidence.json`, `164-01-02-red-evidence.json`, and `164-01-03-red-evidence.json` - captured RED reports; each passed `gsd_run check tdd-red-evidence` with `RED_EVIDENCE_OK` before its GREEN change.

## Decisions Made

- Invalid secret policy is a host configuration failure and returns `server_error`; client metadata errors keep their existing classification.
- The serializer removes both string and atom raw secret metadata keys before adding authoritative effective values.
- `nil` and zero remain unlimited. Direct/operator provenance does not inherit the DCR secret policy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed raw string-keyed secret metadata from registration responses**
- **Found during:** Task 3
- **Issue:** The shared serializer removed only the atom-keyed advisory expiry field, allowing a string-keyed metadata value to coexist with the computed authoritative expiry. It could also preserve a raw metadata `client_secret` on read/update.
- **Fix:** Remove atom- and string-keyed `client_secret_expires_at` and `client_secret` before serializing effective values.
- **Files modified:** `lib/lockspire/web/registration_json.ex`, `test/lockspire/web/registration_json_test.exs`
- **Verification:** The targeted RED failed on the leaked string-keyed expiry; the final serializer suite passed 13 tests.
- **Committed in:** `b059cb8d`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Closed a response-integrity and plaintext exposure path directly in the planned serializer boundary.

## Verification

All Mix commands used the pinned Elixir/OTP versions, task-local Mix and Hex homes, and the dedicated `lockspire_phase164_validation` database.

- `mix test test/integration/client_secret_lifetime_registration_test.exs --max-failures 1 --timeout 55000` — **3 tests, 0 failures**.
- `mix test test/lockspire/protocol/client_secret_lifetime_policy_test.exs test/lockspire/web/controllers/registration_controller_test.exs --max-failures 1 --timeout 55000` — **15 tests, 0 failures**.
- `mix test test/integration/client_secret_lifetime_registration_test.exs test/lockspire/web/registration_json_test.exs --max-failures 1 --timeout 55000` — **13 tests, 0 failures**.
- `mix test test/lockspire/protocol/client_app_authentication_test.exs --max-failures 1 --timeout 55000` — **8 tests, 0 failures**.
- `mix test.setup` on the dedicated `lockspire_phase164_validation` database — storage and migrations present.
- `mix test.fast` — **2 properties, 2302 tests, 0 failures, 406 excluded, 6 skipped**.

Tasks used per-task RED/GREEN cycles. The plan is not described as strict phase-wide TDD. The tracer feedback gate passed before expansion.

## Issues Encountered

- The controller's existing error body includes an optional `error_description`; the regression asserts the stable `server_error` code and 500 status rather than requiring that optional field to be absent.
- The integrated suite's app-expiry test also set a past secret deadline, so the correct secret-expired result masked its app-expiry assertion. The fixture now leaves secret expiry unlimited to test app expiry in isolation; a separate Basic assertion now expects `client_secret_expired` at its expired boundary.
- The plan's flagged `EDGE-DCR-07` deterministic edge-classifier assumption remains unresolved. This plan implemented concrete cases from D-01 through D-04 and D-15; it did not infer broader requirement coverage.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 01 establishes registration, policy and metadata behavior. Later Phase 164 plans still own the remaining authentication and atomic-rotation paths. Full normal-suite and independent PostgreSQL race verification remain assigned to plan 164-06. Management-token lifetime enforcement remains outside this plan and belongs to Phase 165.

---
*Phase: 164-client-secret-expiry-atomic-rotation*
*Completed: 2026-10-21*

## Self-Check: PASSED

- Summary file exists at the required path.
- All seven task and regression-closure commits are ancestors of the current branch head.
- Original `.planning/state.json` backup remains byte-identical and unstaged.
