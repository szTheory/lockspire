---
phase: 41-fapi-2-0-profile-configuration
plan: 01
subsystem: auth
tags: [fapi-2-0, security-profile, ecto, domain-model, admin-commands]

# Dependency graph
requires:
  - phase: 40-jwe-request-objects
    provides: "JWE key management and nested JWT; ServerPolicy domain struct with dpop_policy"
provides:
  - "ServerPolicy.security_profile field (:none | :fapi_2_0_security) with DB migration and Ecto schema"
  - "Client.security_profile field (:inherit | :fapi_2_0_security | :none) with DB migration and Ecto schema"
  - "SecurityProfile resolver module (resolve_effective_profile/2, allowed_signing_algorithms/1)"
  - "Admin.ServerPolicy.put_security_profile/1 with input normalization and error handling"
  - "Admin.Clients :security_profile mutable update path"
  - "Lockspire.Admin.put_security_profile/1 facade delegation"
  - "59 unit tests covering all resolution rules, round-trips, and admin command boundary"
affects:
  - "41-02 (FAPI20EnforcerPlug uses SecurityProfile.resolve_effective_profile/2)"
  - "41-03 (protocol integration uses resolver)"
  - "41-04 (admin UI LiveView renders and mutates security_profile)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SecurityProfile resolver module following ParPolicy/DpopPolicy pattern (module + Resolved struct)"
    - "Ecto.Enum text columns with explicit defaults matching DB migration string values"
    - "Admin command boundary with normalize_field_if_present validation + normalize_mutable_field normalization"

key-files:
  created:
    - lib/lockspire/protocol/security_profile.ex
    - test/lockspire/protocol/security_profile_test.exs
    - priv/repo/migrations/20260430151849_add_security_profile_to_clients_and_policies.exs
  modified:
    - lib/lockspire/domain/server_policy.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/admin/server_policy.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/admin.ex
    - test/lockspire/storage/ecto/server_policy_record_test.exs
    - test/lockspire/storage/ecto/client_record_test.exs
    - test/lockspire/admin/server_policy_test.exs
    - test/lockspire/admin/clients_test.exs

key-decisions:
  - "security_profile stored as durable Ecto.Enum text column (not app config) following dpop_policy precedent"
  - "Mixed-mode escape hatch (client :none overrides global :fapi_2_0_security) preserved per D-01 — intentional"
  - "Resolver returns %Resolved{} struct not bare atom, giving callers fapi_2_0_security? boolean flag directly"

patterns-established:
  - "SecurityProfile.Resolved struct pattern for resolver modules returning structured result (not bare atom)"
  - "Security profile enum column defaults: 'none' for server_policy, 'inherit' for clients"

requirements-completed: [FAPI-01]

# Metrics
duration: 15min
completed: 2026-05-01
---

# Phase 41 Plan 01: FAPI 2.0 Security Profile Scaffolding Summary

**Durable `security_profile` field on ServerPolicy and Client with deterministic resolver, admin command boundary, migration, and 59 unit tests covering inheritance, override, and mixed-mode escape hatch**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-01T20:37:05Z
- **Completed:** 2026-05-01T20:43:00Z
- **Tasks:** 3
- **Files modified:** 11 (3 new test files, 1 new resolver module, 1 new migration, 6 modified)

## Accomplishments
- Verified and committed pre-existing scaffolding: domain structs, Ecto schemas, migration, admin command boundary, and resolver module all matched expected shape from CONTEXT.md locked decisions
- Created 9 unit tests for SecurityProfile resolver covering all 8 plan behaviors plus bonus case for unknown map keys
- Added 7 Ecto schema tests (3 server policy, 4 client record) verifying changeset shape, round-trips, and invalid value rejection — including the critical `update_changeset/2` whitelist check for `:security_profile`
- Added 7 admin command boundary tests (4 server policy, 3 client) verifying persistence, string normalization, error shapes, no-clobber behavior, and facade delegation

## Task Commits

1. **Task 1: Ratify SecurityProfile resolver and domain field additions** - `4995a8a` (feat)
2. **Task 2: Verify migration, Ecto schema casts, and repository round-trip** - `f7f867b` (feat)
3. **Task 3: Verify admin command boundary** - `a0cc3ac` (feat)

## Files Created/Modified
- `lib/lockspire/protocol/security_profile.ex` - SecurityProfile resolver with resolve_effective_profile/2 and allowed_signing_algorithms/1
- `lib/lockspire/domain/server_policy.ex` - Added security_profile: :none | :fapi_2_0_security field
- `lib/lockspire/domain/client.ex` - Added security_profile: :inherit | :fapi_2_0_security | :none field
- `priv/repo/migrations/20260430151849_add_security_profile_to_clients_and_policies.exs` - Text column with DB defaults
- `lib/lockspire/storage/ecto/server_policy_record.ex` - Ecto.Enum field, changeset cast, validate_required, to_domain
- `lib/lockspire/storage/ecto/client_record.ex` - Ecto.Enum field in changeset, update_changeset, to_domain
- `lib/lockspire/admin/server_policy.ex` - put_security_profile/1 with normalize_security_profile/1
- `lib/lockspire/admin/clients.ex` - :security_profile in @mutable_fields, validate_security_profile_if_present/1
- `lib/lockspire/admin.ex` - defdelegate put_security_profile/1, to: ServerPolicy
- `test/lockspire/protocol/security_profile_test.exs` - 9 unit tests for resolver
- `test/lockspire/storage/ecto/server_policy_record_test.exs` - 3 new Ecto tests
- `test/lockspire/storage/ecto/client_record_test.exs` - 4 new Ecto tests
- `test/lockspire/admin/server_policy_test.exs` - 4 new admin tests
- `test/lockspire/admin/clients_test.exs` - 3 new admin tests

## Decisions Made
- The `Ecto.Changeset.cast/3` direct test pattern was used for Test 3 (server policy invalid value) rather than wrapping a struct in changeset/2, since the typed struct cannot hold an invalid string value
- Test 6 for client record (update_changeset with string form) performs a full DB round-trip to confirm the field truly persists, not just that the changeset is valid

## Deviations from Plan

None — plan executed exactly as written. All pre-existing scaffolding matched the expected shape from CONTEXT.md locked decisions. No fixes were required to source files.

## Deferred Issues (Out-of-Scope Pre-existing Failures)

The following test failures exist in the working tree from pre-existing uncommitted scaffolding that predates this plan. They are documented in `deferred-items.md` and NOT caused by plan 41-01 changes:

1. `DPoPTest` — `validate_proof/2` rejects alg=none: expects `:invalid_signature`, gets `:unsupported_signing_algorithm` (from uncommitted `dpop.ex` changes)
2. `JarTest` — Multiple `verify_signature/2` test isolation failures when run with full suite
3. `Admin.KeysTest` — `generate_key creates new keys for specific use` (uncommitted `keys.ex` changes)
4. `ReleaseReadinessContractTest` — Conformance wiring test failure
5. `SecurityPolicyTest` — Unsupported runtime posture reason atoms

All 5 test targets defined in this plan (`security_profile_test`, `server_policy_record_test`, `client_record_test`, `admin/server_policy_test`, `admin/clients_test`) pass with **59 tests, 0 failures**.

## Issues Encountered
None for the plan-targeted scope.

## Next Phase Readiness
- SecurityProfile resolver is stable and tested — plan 41-02 (FAPI20EnforcerPlug) can call `SecurityProfile.resolve_effective_profile/2` with confidence
- Admin.put_security_profile/1 is wired through the facade — plan 41-04 (Admin UI) can call it from LiveView
- Migration is applied to test DB; dev DB migration should be run before plan 41-02 integration tests

## Self-Check: PASSED

- `lib/lockspire/protocol/security_profile.ex` - FOUND
- `test/lockspire/protocol/security_profile_test.exs` - FOUND
- `priv/repo/migrations/20260430151849_add_security_profile_to_clients_and_policies.exs` - FOUND
- `.planning/phases/41-fapi-2-0-profile-configuration/41-01-SUMMARY.md` - FOUND
- Commit `4995a8a` - FOUND
- Commit `f7f867b` - FOUND
- Commit `a0cc3ac` - FOUND
- No unexpected file deletions in plan commits

---
*Phase: 41-fapi-2-0-profile-configuration*
*Completed: 2026-05-01*
