---
phase: 39-automated-rp-logout-propagation
plan: "02"
subsystem: auth
tags: [oidc, dcr, clients, ecto, phoenix, logout]
requires:
  - phase: 39-01
    provides: Wave 0 logout propagation coverage and truthful discovery stubs
provides:
  - Typed client logout propagation fields stored outside metadata
  - Strict operator validation for logout propagation URIs and session coupling
  - DCR rejection for unsupported Phase 39 logout metadata keys
affects: [phase-39, admin-clients, dynamic-client-registration, logout-propagation]
tech-stack:
  added: []
  patterns:
    - typed durable client logout fields
    - offline logout URI validation
    - unsupported_in_slice DCR rejection gates
key-files:
  created:
    - priv/repo/migrations/20260429193000_add_logout_propagation_fields_to_lockspire_clients.exs
  modified:
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/clients.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/protocol/registration.ex
    - test/lockspire/admin/clients_test.exs
    - test/lockspire/protocol/registration_test.exs
key-decisions:
  - "Logout propagation fields remain typed client state with URI presence as the only opt-in."
  - "Operator validation stays offline and field-specific, including front-channel same-origin checks against registered redirect URIs."
  - "Phase 39 DCR keeps logout metadata explicitly unsupported instead of silently ignoring it."
patterns-established:
  - "Admin client updates normalize logout URI and session-required params before persistence."
  - "DCR unsupported logout fields reject early with invalid_client_metadata/unsupported_in_slice."
requirements-completed: [SLO-03, SLO-04]
duration: 7m
completed: 2026-04-29
---

# Phase 39 Plan 02: Typed client logout fields, strict operator validation, and narrow DCR truth

**Client logout propagation now persists as typed fields with strict operator validation, while DCR explicitly rejects the unsupported Phase 39 logout metadata surface.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-29T19:03:00Z
- **Completed:** 2026-04-29T19:09:40Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Added four first-class client logout propagation fields to the domain model and Ecto record with durable defaults.
- Enforced operator-side validation for absolute URIs, fragment rejection, `*_session_required` coupling, normalization, and front-channel same-origin checks.
- Rejected all four Phase 39 logout metadata keys from DCR using the existing `unsupported_in_slice` error posture.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend client/domain records with typed logout fields** - `9d6d04e` (`feat`)
2. **Task 2: Enforce operator validation for logout metadata** - `e6d8d5b` (`feat`)
3. **Task 3: Reject Phase 39 logout fields from DCR intake** - `8447d92` (`feat`)

TDD RED commit:

1. **Task 1 RED: failing typed logout field coverage** - `61cc744` (`test`)

## Files Created/Modified
- `priv/repo/migrations/20260429193000_add_logout_propagation_fields_to_lockspire_clients.exs` - Adds durable client columns for the four logout propagation fields.
- `lib/lockspire/domain/client.ex` - Extends the typed client shape with back-channel and front-channel logout fields.
- `lib/lockspire/storage/ecto/client_record.ex` - Persists and loads the new logout fields through the Ecto schema and changesets.
- `lib/lockspire/clients.ex` - Adds logout URI validation helpers and front-channel origin matching.
- `lib/lockspire/admin/clients.ex` - Makes the logout fields mutable, normalizes boolean/string params, and enforces field-specific validation.
- `lib/lockspire/protocol/registration.ex` - Rejects the four unsupported Phase 39 logout metadata keys from DCR intake.
- `test/lockspire/admin/clients_test.exs` - Covers typed field round-trips and operator validation/error cases.
- `test/lockspire/protocol/registration_test.exs` - Covers `unsupported_in_slice` rejection for each logout metadata key.

## Decisions Made

- Kept logout propagation configuration out of `metadata` so later Phase 39 slices can rely on truthful, typed client state.
- Used the existing redirect-URI parser as the base for logout URI validation to preserve exact absolute-URI and fragment discipline.
- Matched DCR rejection behavior to the existing `jwks_uri` unsupported-field path rather than inventing a new error shape.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the missing client-table migration for typed logout fields**
- **Found during:** Task 1 (Extend client/domain records with typed logout fields)
- **Issue:** The plan-owned files added schema fields, but `lockspire_clients` had no matching columns, so all client persistence tests failed with `undefined_column`.
- **Fix:** Added a narrow additive migration for the four logout propagation columns and ran `MIX_ENV=test mix test.setup` before rerunning verification.
- **Files modified:** `priv/repo/migrations/20260429193000_add_logout_propagation_fields_to_lockspire_clients.exs`
- **Verification:** `MIX_ENV=test mix test.setup`; `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs`
- **Committed in:** `9d6d04e`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary compile/test plumbing only. No surface-area broadening beyond the typed client fields required by the plan.

## Issues Encountered

- The plan’s listed verification commands use `mix test ... -x`, but this Mix version does not support the `-x` flag. Equivalent file-scoped `mix test` commands were used instead.
- The test environment required `MIX_ENV=test mix test.setup` after adding the new migration so the database schema matched the new typed fields.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Client logout propagation state is now durable and truthful for later repository, worker, discovery, and UI slices.
- DCR remains intentionally narrower than the operator surface, so future Phase 39 work can add runtime/logout propagation behavior without widening registration intake accidentally.

## Verification

- `MIX_ENV=test mix test.setup` — passed; applied `20260429193000_add_logout_propagation_fields_to_lockspire_clients`.
- `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs` — passed.
- `MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs` — passed.
- `MIX_ENV=test mix test test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs` — passed.
- Plan command note: `MIX_ENV=test mix test ... -x` failed before execution because this Mix version reports `-x` as an unknown option.

## Self-Check: PASSED

- Found summary file: `.planning/phases/39-automated-rp-logout-propagation/39-02-SUMMARY.md`
- Found commits: `61cc744`, `9d6d04e`, `e6d8d5b`, `8447d92`
