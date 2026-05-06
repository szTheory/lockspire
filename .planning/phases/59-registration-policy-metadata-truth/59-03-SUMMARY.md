---
phase: 59
plan: 59-03
subsystem: discovery
tags:
  - discovery
  - oauth
  - oidc
  - private_key_jwt
  - metadata
requirements:
  - META-01
  - META-02
key_files:
  created: []
  modified:
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/discovery.ex
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
decisions:
  - Publish endpoint auth metadata from one shared direct-client-auth capability source and narrow it per endpoint inside `Lockspire.Protocol.Discovery`.
  - Publish JWT client-auth signing algorithms only when `private_key_jwt` is actually advertised for that endpoint.
  - Keep introspection metadata narrower than token and revocation until runtime behavior changes in a later phase.
commits:
  - 4078a15
  - da8be5e
---

# Phase 59 Plan 03: Registration Policy Metadata Truth Summary

Aligned Lockspire's discovery document with the current runtime truth of the direct-client authentication surface.

## Completed Work

- Added failing discovery protocol and controller contract tests that pinned:
  - token, revocation, and introspection auth-method publication,
  - omission of revocation/introspection metadata when those routes are unmounted,
  - signing-algorithm publication only where `private_key_jwt` is published.
- Added a shared `ClientAuth.supported_auth_method_names/0` helper so discovery metadata no longer duplicates the direct-client auth capability list.
- Refactored `Lockspire.Protocol.Discovery` to:
  - derive token endpoint auth metadata from the shared `ClientAuth` seam,
  - derive revocation metadata from the same shared capability plus mounted-route truth,
  - narrow introspection metadata to the endpoint's current runtime limitation,
  - publish endpoint-specific JWT client-auth signing algorithms from `SecurityProfile.allowed_signing_algorithms/1` only when `private_key_jwt` is actually advertised.
- Stabilized the owned discovery protocol test fixture by restoring and explicitly setting `:rar_types_supported` alongside the existing RAR validator setup.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs`
- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`

Both commands passed after the discovery metadata refactor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Repaired owned RAR discovery test fixture state**
- **Found during:** Plan verification
- **Issue:** Existing RAR discovery assertions in the owned protocol test file configured `:rar_validators`, while the helper under test read `:rar_types_supported`, causing an unrelated failure inside the plan's verification target.
- **Fix:** Restored and explicitly set `:rar_types_supported` in `test/lockspire/protocol/discovery_test.exs` alongside the existing validator setup.
- **Files modified:** `test/lockspire/protocol/discovery_test.exs`
- **Impact on plan:** Kept the verification target stable without widening the implementation surface beyond the plan-owned discovery files.

## Known Stubs

- None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/59-registration-policy-metadata-truth/59-03-SUMMARY.md`
- Commit `4078a15` exists in git history
- Commit `da8be5e` exists in git history
