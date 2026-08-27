---
phase: 133-clean-room-saas-journey
plan: 03
subsystem: clean-room confidential client
tags: [oauth, oidc, dpop, pkce, acceptance]
provides:
  - isolated client builder with package provenance validation
  - durable one-time authorization transactions
  - fixed bearer and DPoP client route profiles
  - encrypted P-256 DPoP key ownership and OIDC claim guards
status: complete
---

# Phase 133 Plan 03: Confidential Client Security Spine Summary

The clean-room confidential client now has a reproducible, isolated database-backed authorization transaction spine with S256 PKCE, fixed server-selected profiles, and DPoP key ownership.

## Accomplishments

- Added a fresh-child builder which copies and provenance-checks the unpacked Lockspire package before resolving the locked child dependency graph.
- Added durable state, nonce, verifier, challenge, callback, expiry, and terminal-consumption transaction fields with a compare-and-set pending-to-consumed transition.
- Added distinct bearer and DPoP start/callback routes, fixed client identities, encrypted P-256 private-key material, and no request-selected credentials.
- Added fixture-local OIDC metadata/claim checks and endpoint-specific DPoP proof construction using authenticated Plug crypto encryption.

## Verification

- Passed: `python3 scripts/acceptance/clean_room/build_client.py --test oauth_transaction`
- Passed: `python3 scripts/acceptance/clean_room/build_client.py --test oauth_callback`
- Passed: `python3 scripts/acceptance/clean_room/build_client.py --test oidc_verifier`
- Passed: `python3 scripts/acceptance/clean_room/build_client.py --test dpop_client`

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 3 - Build isolation]** The locked dependency provenance probe originally compiled configuration before the per-run database URL existed. The fixture now passes that URL through the provenance check, ensuring migrations and tests use the identical isolated database.
2. **[Rule 3 - Migration discovery]** The initial migration filename was not timestamped, so Ecto did not discover it. It now uses the conventional versioned filename.
3. **[Rule 3 - Compatibility]** The client builder applies the same narrowly fail-closed, child-local JOSE 1.11.12/Elixir 1.19 compatibility adapter already proven by the package-clean provider fixture.

## Self-Check: PASSED

- Task commits `95bdcc8`, `d5c0096`, and `9a6de07` exist.
- Client builder, durable schema, transaction service, DPoP service, OIDC verifier, routes, and focused tests exist.
