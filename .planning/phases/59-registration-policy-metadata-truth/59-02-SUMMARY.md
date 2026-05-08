---
phase: 59-registration-policy-metadata-truth
plan: 02
subsystem: admin
tags: [phoenix, liveview, dcr, private_key_jwt, jwks_uri, oauth]
requires:
  - phase: 59-registration-policy-metadata-truth
    provides: DCR policy truth and Phase 59 registration posture context
provides:
  - Derived admin truth for DCR `private_key_jwt` self-registration support
  - Read-only DCR UI copy describing effective JWT assertion signing algorithms
  - Read-only client detail posture for `private_key_jwt` and `jwks_uri` clients
affects: [phase-59, admin-ui, dcr, discovery-truth]
tech-stack:
  added: []
  patterns: [derived-admin-policy-truth, read-only-security-posture-copy]
key-files:
  created: []
  modified:
    - lib/lockspire/admin/server_policy.ex
    - lib/lockspire/web/live/admin/policies_live/dcr.ex
    - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/admin/server_policy_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
key-decisions:
  - "Derived `private_key_jwt` admin truth from `ServerPolicy` plus `SecurityProfile.allowed_signing_algorithms/1` instead of adding a new persisted algorithm plane."
  - "Kept Phase 59 client posture read-only by surfacing configured `jwks_uri` and effective algorithms without introducing edit or fetch actions."
patterns-established:
  - "Admin policy truth should be computed from runtime policy sources, not duplicated in UI strings."
  - "Security-sensitive client posture in admin remains explanatory until later phases prove the underlying verifier/fetch behavior."
requirements-completed: [REG-03]
duration: 8min
completed: 2026-05-06
---

# Phase 59 Plan 02: Registration Policy Metadata Truth Summary

**Derived `private_key_jwt` registration truth from server policy and exposed read-only JWT/JWKS posture in Lockspire's admin DCR and client views**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-06T18:44:00Z
- **Completed:** 2026-05-06T18:51:54Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added one admin helper that computes whether self-registered clients may use `private_key_jwt` and which assertion signing algorithms the current issuer posture allows.
- Updated the DCR policy LiveView to explain the supported `private_key_jwt` + `jwks`/`jwks_uri` slice without creating a new key-management workflow.
- Updated the client detail LiveView to show read-only posture for `private_key_jwt` clients, including configured `jwks_uri` and effective assertion algorithms.

## Task Commits

1. **Task 1: Add a derived admin truth helper for `private_key_jwt` policy** - `429354e` (`feat`)
2. **Task 2: Surface narrow policy truth in DCR and client admin views** - `333d14b` (`feat`)

**Blocking verification fix:** `7d7d1b0` (`fix`)

## Files Created/Modified

- `lib/lockspire/admin/server_policy.ex` - added the derived `private_key_jwt` registration truth helper.
- `lib/lockspire/web/live/admin/policies_live/dcr.ex` - assigned derived JWT posture into the DCR LiveView.
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` - rendered explanatory `private_key_jwt` and algorithm posture copy.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - rendered read-only JWT client assertion key posture for `private_key_jwt` clients.
- `test/lockspire/admin/server_policy_test.exs` - covered allowlist and security-profile algorithm derivation.
- `test/lockspire/web/live/admin/policies_live/dcr_test.exs` - covered DCR UI truth text.
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - covered read-only `private_key_jwt` / `jwks_uri` posture.
- `lib/lockspire/config.ex` - restored the missing `rar_types_supported/0` helper needed for warning-free compilation.
- `lib/lockspire/protocol/introspection.ex` - removed invalid struct-key pattern matches that blocked compilation.
- `mix.lock` - locked missing test dependencies required by the repo.

## Decisions Made

- Derived signing-algorithm truth from the existing security-profile runtime helper instead of introducing an operator-edited crypto allowlist.
- Kept client-level visibility read-only and explanatory, matching the Phase 59 boundary that defers key workflows and remote fetch actions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Locked missing test dependencies**
- **Found during:** Task 1 verification
- **Issue:** `mix test` could not start because `stream_data` and `jcs` were missing from `mix.lock`.
- **Fix:** Ran `mix deps.get` and committed the updated lockfile.
- **Files modified:** `mix.lock`
- **Verification:** Both plan test commands proceeded past dependency resolution.
- **Committed in:** `7d7d1b0`

**2. [Rule 3 - Blocking] Restored a missing config helper required by discovery**
- **Found during:** Task 1 verification
- **Issue:** `Lockspire.Protocol.Discovery` called `Lockspire.Config.rar_types_supported/0`, which did not exist and triggered a warning that failed `--warnings-as-errors`.
- **Fix:** Added `Lockspire.Config.rar_types_supported/0` as a config getter.
- **Files modified:** `lib/lockspire/config.ex`
- **Verification:** Warning-free compilation under both plan test commands.
- **Committed in:** `7d7d1b0`

**3. [Rule 3 - Blocking] Removed invalid struct-key matches in introspection fallback**
- **Found during:** Task 1 verification
- **Issue:** `Lockspire.Protocol.Introspection` matched on nonexistent `Token.consent_grant_id` and `ConsentGrant.authorization_details` struct keys, causing compile failure.
- **Fix:** Switched that fallback to dynamic `Map.get/2` access so compilation no longer depends on undeclared struct fields.
- **Files modified:** `lib/lockspire/protocol/introspection.ex`
- **Verification:** Both plan test commands compiled and passed.
- **Committed in:** `7d7d1b0`

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** All deviations were prerequisite fixes for executing the planned work under warning-free test verification. No product-scope drift was introduced.

## Issues Encountered

- The client admin test initially tried to mutate an immutable auth method. The test was corrected to register a dedicated `private_key_jwt` client instead, which matches the Phase 59 read-only posture boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Admin/operator truth for the `private_key_jwt` registration slice is now derived and repo-proven.
- Phase 60 can build guarded remote JWKS retrieval on top of truthful UI posture without expanding the admin surface.

## Self-Check: PASSED

- Found summary file at `.planning/phases/59-registration-policy-metadata-truth/59-02-SUMMARY.md`
- Verified commits `7d7d1b0`, `429354e`, and `333d14b` exist in git history
