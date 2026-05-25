---
phase: 90
plan: 1
subsystem: docs
tags: [docs, support-truth, client-secret-jwt]
provides:
  - Canonical public support truth for the shipped `client_secret_jwt` slice
  - Dedicated host guidance for the narrow symmetric JWT direct-client posture
  - Onboarding and DCR docs that defer back to one canonical support contract
affects: [docs, onboarding, dcr]
key-files:
  created:
    - docs/client-secret-jwt-host-guide.md
  modified:
    - docs/supported-surface.md
    - docs/install-and-onboard.md
    - docs/dynamic-registration.md
requirements-completed: [META-02]
completed: 2026-05-25
---

# Phase 90 Plan 1 Summary

**Public docs now describe one truthful, narrow `client_secret_jwt` story instead of leaving the symmetric JWT slice either unsupported or underspecified.**

## Accomplishments

- Updated `docs/supported-surface.md` so the canonical contract publishes the shipped direct-client `client_secret_jwt` slice, its `HS256` and issuer-string `aud` posture, its `POST /par` exclusion, and its FAPI non-claim.
- Added `docs/client-secret-jwt-host-guide.md` as a sibling to the existing `private_key_jwt` guide with the narrow registration, assertion, endpoint-scope, non-goal, and host-owned responsibility story.
- Updated onboarding and DCR guidance to point back to the canonical support contract and dedicated guide instead of creating a second auth-method matrix.

## Task Commits

1. **Task 90-01-01: correct canonical support contract** - `10e9642`
2. **Task 90-01-02: add dedicated host guide** - `a004750`
3. **Task 90-01-03: align onboarding and DCR docs** - `43e5bc7`

## Verification

- `mix docs.verify`
- `rg -n "client_secret_jwt|HS256|issuer-string|FAPI|generic JWT client-auth support outside the Lockspire-owned direct-client surfaces" docs/supported-surface.md`
- `rg -n "token_endpoint_auth_method=client_secret_jwt|token_endpoint_auth_signing_alg=HS256|POST /par|HS384|HS512|FAPI|host app still owns" docs/client-secret-jwt-host-guide.md`
- `rg -n "client-secret-jwt-host-guide.md|token_endpoint_auth_method=client_secret_jwt|token_endpoint_auth_signing_alg=HS256|confidential" docs/install-and-onboard.md docs/dynamic-registration.md`

## Deviations from Plan

- Task edits were applied in one documentation pass and then committed back out at task boundaries. The resulting content matches the planned file split and passed the required verification gates.

## Next Phase Readiness

- Release-contract and discovery/runtime proof can now pin the exact support-truth language without inventing a second support source.
