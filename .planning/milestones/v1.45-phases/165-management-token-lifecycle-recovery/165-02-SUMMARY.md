---
phase: 165-management-token-lifecycle-recovery
plan: "02"
subsystem: auth
tags: [oauth, oidc, phoenix, ecto, postgres, dynamic-client-registration]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Management lifetime bounds and finite/unlimited semantics
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: DCR provenance, issuance-time, and lifetime validation patterns
  - phase: 165-01
    provides: Effective management deadline serialization and current-row management access
provides:
  - Provenance-aware management_deadline/3 with explicit policy and state errors
  - Issuance-time management deadline snapshots and effective response extensions
  - Matching management duration bounds at persistence and policy resolution
  - Real persistence, admin, registration, serialization, and HTTP regression coverage
affects: [dynamic-client-registration, management-token-lifecycle, server-policy]
actuals:
  tokens: 7329
  tasks: 2
  commits: 4
  plan_head_before: 7dc327a918745955a21594c42e906d9b06b8e30d
  plan_head_after: 68ee727816c43b80d289c99584d45677aaf0aa06
tech-stack:
  added: []
  patterns:
    - Management deadlines snapshot one truncated UTC issuance instant and only self-registered provenance
    - Typed policy validation runs before Ecto coercion at both persistence and registration resolution
key-files:
  created:
    - test/integration/management_token_lifetime_registration_test.exs
    - test/lockspire/protocol/management_token_lifetime_policy_test.exs
    - .planning/phases/165-management-token-lifecycle-recovery/165-02-01-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-02-02-red-evidence.json
  modified:
    - lib/lockspire/domain/client.ex
    - lib/lockspire/client_metadata.ex
    - lib/lockspire/protocol/dcr_policy.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - test/lockspire/web/registration_json_test.exs
key-decisions:
  - "Management expiry depends on self-registration provenance, regardless of shared-secret, public-key, public, or mTLS authentication method."
  - "Reject malformed typed policy values before Ecto can coerce numeric strings; only nil and bounded non-negative integers are valid."
  - "Keep management policy form text conversion in PolicyForm and pass its cast integer or nil through the admin API."
requirements-completed: [DCR-10]
coverage:
  - id: D1
    description: Management duration is snapshotted at issuance and advertised as a server-owned finite or unlimited extension.
    requirement: DCR-10
    verification:
      - kind: integration
        ref: test/integration/management_token_lifetime_registration_test.exs
        status: pass
      - kind: unit
        ref: test/lockspire/web/registration_json_test.exs
        status: pass
    human_judgment: true
    rationale: The plan's deterministic spec-less DCR-10 probe remains unclassified and requires independent verification.
  - id: D2
    description: Management duration policy has identical typed bounds at form, persistence, admin, resolver, domain, and registration HTTP boundaries.
    requirement: DCR-10
    verification:
      - kind: integration
        ref: test/lockspire/protocol/management_token_lifetime_policy_test.exs
        status: pass
      - kind: integration
        ref: test/lockspire/storage/ecto/server_policy_record_test.exs
        status: pass
      - kind: unit
        ref: test/lockspire/protocol/dcr_policy_test.exs
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-10-21
status: complete
---

# Phase 165 Plan 02: Management Token Policy Summary

**DCR registration now snapshots a provenance-aware management-token deadline and rejects invalid duration policy at persistence and use boundaries.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-21T17:55:42Z
- **Completed:** 2026-10-21T18:00:32Z
- **Tasks:** 2
- **Files modified:** 9, including two RED-evidence records

## Accomplishments

- Persisted a finite management deadline from the existing `credentials.issued_at`; nil and zero remain unlimited. Registration and management responses serialize the effective deadline as Unix seconds or `0`.
- Kept DCR management deadlines tied to self-registration provenance across shared-secret, public, public-key, and mTLS auth methods. GET, policy edits, and token lookup preserve the stored deadline.
- Enforced the same nil-or-integer `0..2147483647` contract in domain calculation, DCR resolution, Ecto changesets, admin writes, and form-cast persistence. Malformed in-memory and stored policy returns a redacted server error without issuance writes.

## Task Commits

1. **Task 1 RED:** `0a5bf838` (test) — cover management lifetime issuance.
2. **Task 1 GREEN:** `d54f7f4b` (feat) — snapshot DCR management-token lifetime.
3. **Task 2 RED:** `98aa0d1d` (test) — reject invalid management-token policy.
4. **Task 2 GREEN:** `68ee7278` (feat) — validate management duration policy.

Both RED records passed `gsd_run check tdd-red-evidence` with `RED_EVIDENCE_OK`; each named test failed on its intended policy or persisted-deadline assertion before the GREEN implementation.

## Files Created/Modified

- `lib/lockspire/domain/client.ex` — validated, provenance-aware management deadline calculation.
- `lib/lockspire/client_metadata.ex` — DCR expiry snapshot and auth-method preservation for TLS client authentication.
- `lib/lockspire/protocol/dcr_policy.ex` — management duration validation at registration use.
- `lib/lockspire/storage/ecto/server_policy_record.ex` — original typed value validation before persistence.
- `test/integration/management_token_lifetime_registration_test.exs` — registration-to-storage-to-response proof, including GET and non-secret auth methods.
- `test/lockspire/protocol/management_token_lifetime_policy_test.exs` — real policy persistence/admin, form, domain, registration, and router rejection matrix.
- `test/lockspire/web/registration_json_test.exs` — finite/unlimited server-owned extension and metadata-alias checks.
- Two `.planning/phases/165-management-token-lifecycle-recovery/165-02-*-red-evidence.json` files — machine-validated TDD RED reports.

## Decisions Made

- Validate duration input as its original typed value before accepting Ecto casting; a string such as `"1"` is invalid through programmatic policy APIs.
- Compute the stored deadline from the existing issuance instant and apply DCR policy based on provenance, not secret applicability.
- Preserve the existing PolicyForm conversion boundary for HTML numeric and blank values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve mTLS DCR authentication methods during registration**
- **Found during:** Task 1 (Issue and advertise finite or unlimited management credentials)
- **Issue:** The existing metadata atomizer mapped `tls_client_auth` and `self_signed_tls_client_auth` to `client_secret_basic`, despite those methods having no shared secret.
- **Fix:** Added explicit mappings for both supported mTLS methods and covered registration with them in the lifecycle matrix.
- **Files modified:** `lib/lockspire/client_metadata.ex`, `test/integration/management_token_lifetime_registration_test.exs`
- **Verification:** The focused issuance/serializer suite passed with 15 tests and no failures.
- **Committed in:** `d54f7f4b`.

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** The correction was required to prove management lifecycle behavior independently of shared-secret authentication while preserving the requested auth method.

## Verification

- Task 1 command: `mix test test/integration/management_token_lifetime_registration_test.exs test/lockspire/web/registration_json_test.exs --max-failures 1 --timeout 55000` — **15 tests, 0 failures**.
- Task 2 command: `mix test test/lockspire/protocol/management_token_lifetime_policy_test.exs test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/protocol/dcr_policy_test.exs test/integration/management_token_lifetime_registration_test.exs --max-failures 1 --timeout 55000` — **35 tests, 0 failures**.
- `mix format` passed for all changed source and test files; `git diff --check` passed.
- Both TDD RED-evidence records were accepted by the classifier. The router regression observed HTTP 500 `server_error`, no invalid-token challenge, no credential disclosure, and no client or success-audit writes.

## Issues Encountered

- The first invalid-state serializer assertion initially observed the earlier client-secret validation error. The test was narrowed to assert the required server error class without assuming which invalid lifetime field is checked first.
- A test attempted to construct an incomplete `%DateTime{}` and failed compilation; it was corrected to pass an invalid time value through the public domain API and assert the explicit state error.
- The roadmap progress SDK did not recognize this phase's detailed plan checklist. The plan checkbox and progress row were updated directly to 2/7, and the requirements coverage count was refreshed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can use the validated management deadline helper and matching persistence/use guards. The deterministic spec-less DCR-10 probe remains explicitly unresolved for independent verification, as required by the plan assumption.

## Self-Check: PASSED

- Plan source and test artifacts exist; no stub, TODO, FIXME, or placeholder patterns were found in the changed source and test files.
- All four task commits are ancestors of the current plan head; measured plan commits: 4.
- Both focused verification commands pass with the recorded positive test counts.
- The original `.planning/state.json` bytes match `/private/tmp/lockspire-phase165-original-state.json` and remain unstaged.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
