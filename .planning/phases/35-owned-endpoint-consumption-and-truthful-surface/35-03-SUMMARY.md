---
phase: 35-owned-endpoint-consumption-and-truthful-surface
plan: "03"
subsystem: auth
tags: [dpop, dcr, admin, liveview, oidc, phoenix]
requires:
  - phase: 35-owned-endpoint-consumption-and-truthful-surface
    provides: DPoP-aware userinfo enforcement and truthful DPoP discovery support surface boundaries
provides:
  - RFC 9449 dpop_bound_access_tokens mapping for self-registered clients
  - Global DPoP admin policy page with inherit/bearer/dpop client override summary
  - Existing client edit workflow support for inherit, bearer, and DPoP overrides
affects: [36-01, 36-02, discovery, docs, admin]
tech-stack:
  added: []
  patterns:
    - Self-registered DCR clients persist explicit bearer or dpop policy from RFC metadata instead of inheriting server policy
    - DPoP admin controls mirror the existing narrow PAR workflow rather than expanding into a generalized token-policy console
key-files:
  created:
    - lib/lockspire/web/live/admin/policies_live/dpop.ex
    - test/lockspire/web/live/admin/policies_live/dpop_test.exs
  modified:
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/web/registration_json.ex
    - lib/lockspire/web/router.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/protocol/registration_test.exs
    - test/lockspire/protocol/registration_management_test.exs
    - test/lockspire/web/registration_json_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs
key-decisions:
  - "Self-registered clients now resolve omitted or false dpop_bound_access_tokens to explicit bearer policy instead of inheriting future server defaults."
  - "The DPoP operator surface stays intentionally parallel to PAR: one global policy page plus the existing client edit workflow."
patterns-established:
  - "Registration and registration-management map RFC 9449 metadata directly into durable client.dpop_policy and derive response truth from that same field."
  - "Client edit metadata forms can safely carry DPoP policy overrides alongside existing mutable fields without adding a second client-policy route."
requirements-completed: [DPoP-11]
duration: 4min
completed: 2026-04-28
---

# Phase 35 Plan 03: Owned Endpoint Consumption and Truthful Surface Summary

**RFC 9449 DPoP client metadata round-trip with durable bearer-vs-DPoP truth and a narrow admin policy surface that mirrors PAR**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T19:37:00Z
- **Completed:** 2026-04-28T19:41:35Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- Dynamic Client Registration now maps `dpop_bound_access_tokens` into durable `client.dpop_policy` on create and update, and registration responses expose the same RFC 9449 field from stored truth.
- Self-registered clients no longer silently inherit future server DPoP defaults when they omit the field; omission and `false` both become explicit bearer clients.
- Operators now have a narrow `/admin/policies/dpop` LiveView plus a DPoP selector in the existing client edit workflow for `inherit`, `bearer`, and `dpop`.

## Task Commits

1. **Task 1: Extend DCR create/read/update to honor RFC 9449 `dpop_bound_access_tokens`** - `56e8d35` (test), `7e0ff32` (feat)
2. **Task 2: Mirror PAR admin patterns for global and client DPoP policy UX** - `75d7370` (test), `2f61db1` (feat)

## Files Created/Modified
- `lib/lockspire/protocol/registration.ex` - Persists explicit `:bearer` or `:dpop` for self-registered clients from inbound RFC metadata.
- `lib/lockspire/protocol/registration_management.ex` - Applies the same DPoP policy mapping during RFC 7592 updates.
- `lib/lockspire/web/registration_json.ex` - Returns `dpop_bound_access_tokens` from durable client policy truth.
- `lib/lockspire/web/router.ex` - Mounts the new `/admin/policies/dpop` operator page.
- `lib/lockspire/web/live/admin/policies_live/dpop.ex` - Adds the narrow global DPoP policy page and client override summary counts.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - Adds the client edit selector for `inherit`, `bearer`, and `dpop`.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Threads the selected DPoP override through the existing safe edit save path.
- `test/lockspire/protocol/registration_test.exs` - Covers DCR create-path persistence for true, false, and omitted RFC metadata.
- `test/lockspire/protocol/registration_management_test.exs` - Covers DCR update-path persistence for bearer and DPoP client modes.
- `test/lockspire/web/registration_json_test.exs` - Covers DCR response truth for bearer and DPoP clients.
- `test/lockspire/web/live/admin/policies_live/dpop_test.exs` - Covers the DPoP route, rendering, saving, and invalid-value handling.
- `test/lockspire/web/live/admin/clients_live_test.exs` - Covers route truth plus edit-form rendering and client override persistence.

## Decisions Made
- `dpop_bound_access_tokens` omission remains explicit bearer for self-registered clients so later global DPoP rollout does not silently mutate DCR-created client behavior.
- The admin DPoP controls reuse the PAR interaction shape instead of adding a new standalone client-policy route or a broader sender-constrained management surface.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced invalid `mix test ... -x` verification commands**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** The plan’s canned Mix commands use `-x`, which the current Mix version rejects before any tests run.
- **Fix:** Verified the same file-scoped suites with plain `mix test` invocations.
- **Files modified:** `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-03-SUMMARY.md`
- **Verification:** `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/web/registration_json_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/clients_live_test.exs`
- **Committed in:** metadata commit

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification remained fully automated and equivalent in scope. No product-surface scope change.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 35 now has both owned-surface runtime enforcement and truthful operator/DCR configuration needed for the remaining discovery/docs truth work.
- Phase 36 can treat client token mode as durable repo truth for end-to-end DPoP scenarios across admin-managed and self-registered clients.

## Self-Check: PASSED
- Found summary file on disk.
- Verified task commits `56e8d35`, `7e0ff32`, `75d7370`, and `2f61db1` in git history.
