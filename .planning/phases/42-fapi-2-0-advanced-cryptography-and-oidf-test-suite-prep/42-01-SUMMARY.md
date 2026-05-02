---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 01
subsystem: auth
tags: [oauth, oidc, fapi, jwk, signing-keys, phoenix, ecto]
requires:
  - phase: 41-fapi-2-0-profile-configuration
    provides: security-profile resolution and mixed-mode FAPI posture
provides:
  - canonical ES256/PS256-only FAPI signing policy
  - fail-fast admin key activation and generation gates
  - profile-aware publishable and active signing-key selection
affects: [jar, id-token, jwks, discovery, dpop, admin]
tech-stack:
  added: []
  patterns: [protocol-owned signing policy truth, profile-aware key filtering]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/security_profile.ex
    - lib/lockspire/security/policy.ex
    - lib/lockspire/admin/keys.ex
    - lib/lockspire/storage/key_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/protocol/security_profile_test.exs
    - test/lockspire/protocol/security_policy_test.exs
    - test/lockspire/admin/keys_test.exs
key-decisions:
  - "SecurityProfile.allowed_signing_algorithms/1 is the single FAPI signing allow-list and returns only ES256 and PS256 for :fapi_2_0_security."
  - "Repository publishable and active signing-key selectors accept a security_profile option and filter legacy rows in memory with Policy.validate_key_compliance/2."
patterns-established:
  - "Profile-aware key lifecycle seams: admin and repository code must take the resolved security profile and reject non-compliant signing posture before runtime use."
  - "Typed remediation errors: operator-facing activation failures wrap raw compliance reasons with concrete next-step guidance."
requirements-completed: [FAPI-04]
duration: 5min
completed: 2026-05-02
---

# Phase 42: Plan 01 Summary

**Canonical FAPI signing policy now resolves to ES256/PS256 only, with admin and repository key lifecycle seams blocking legacy or weak signing keys from FAPI-effective runtime use**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-02T01:40:20Z
- **Completed:** 2026-05-02T01:45:27Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Narrowed the protocol-owned FAPI signing truth to `ES256` and `PS256` and pinned it with focused protocol tests.
- Added key compliance helpers that reject `RS256`, `EdDSA`, weak RSA keys, and unsupported curves under FAPI-effective posture.
- Made admin key generation, activation, and repository publishable/active selection profile-aware so legacy signing rows stay durable without leaking into FAPI runtime paths.

## Task Commits

Each task was committed atomically:

1. **Task 1: Narrow the canonical FAPI algorithm truth and compliance helpers** - `b5f3a9c` (`feat`)
2. **Task 2: Enforce fail-fast FAPI key posture in admin and repository seams** - `2ae38ff` (`feat`)

**Plan metadata:** This summary is committed separately after the task commits.

## Files Created/Modified
- `lib/lockspire/protocol/security_profile.ex` - Reduced the FAPI signing allow-list to `ES256`/`PS256`.
- `lib/lockspire/security/policy.ex` - Added reusable key compliance checks for FAPI algorithm and strength enforcement.
- `lib/lockspire/admin/keys.ex` - Defaulted FAPI signing key generation to compliant material and wrapped activation failures with operator remediation guidance.
- `lib/lockspire/storage/key_store.ex` - Expanded the signing-key contract to accept profile-aware selection options.
- `lib/lockspire/storage/ecto/repository.ex` - Filtered publishable and active signing-key selection by effective security profile.
- `test/lockspire/protocol/security_profile_test.exs` - Pinned the narrowed canonical algorithm list.
- `test/lockspire/protocol/security_policy_test.exs` - Pinned typed compliance outcomes for non-compliant algorithms and weak key material.
- `test/lockspire/admin/keys_test.exs` - Covered FAPI-aware generation, activation rejection, and selector filtering behavior.

## Decisions Made
- Canonical FAPI signing truth remains protocol-owned in `SecurityProfile` so later runtime and publication plans can consume one source of truth.
- Profile-aware repository selectors filter domain keys after load rather than adding schema-level quarantine state, preserving mixed-mode durable storage.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered
- The initial executor stalled after Task 1 and did not write `42-01-SUMMARY.md`; the remaining Task 2 slice and summary were completed directly against the current repo state.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Wave 1 now provides the canonical signing policy and key-lifecycle guardrails required by Plans 02, 03, 05, 06, and 07.
- Remaining phase work can assume FAPI-effective signing selection never returns legacy `RS256` or `EdDSA` keys.

---
*Phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep*
*Completed: 2026-05-02*
