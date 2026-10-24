# Pitfalls Research

**Milestone:** v1.45 DCR Lifetime Enforcement
**Researched:** 2026-10-20
**Confidence:** HIGH for demonstrated current gaps and standards constraints; risk scenarios require implementation tests.

## Critical Pitfalls

| Failure mode | Warning sign | Prevention and owner |
|---|---|---|
| Deployed clients immediately rejected after upgrade | Legacy date is treated as authoritative without provenance | Phase 162 selects legacy handling and activation; implementation proves upgrade fixtures |
| Management credentials expire with no recovery | Timeout copied from ordinary access tokens | Phase 162 reconciles RFC 7592 section 5 and authorized recovery |
| Unlimited marker confused with duration | Zero becomes creation-time expiry accidentally | Phase 162 separate policy input from wire metadata; test unset/zero/positive |
| One auth variant bypasses expiry | Basic/post checked but secret JWT or public clients omitted | Shared eligibility and endpoint inventory; preserve assertion-expiry/replay checks |
| Rotation leaves stale date or resurrects old credentials | Hash/date writes split, or stale pre-lock authorization trusted | Atomic replacement and locked current-state checks; race tests |
| Worker lag creates an acceptance window | Expiry depends on prune schedule | Request-time checks; workers only implement separately chosen lifecycle cleanup |
| Schema works only in library tests | Fresh generator or custom store lacks fields | Generated-host, upgrade and custom-store contract proofs |
| Claims exceed actual invalidation | Offline JWTs described as instantly revoked | Specify validation/caching limits and host/resource-server responsibilities |
| Diagnostic output discloses credentials | Raw error structs or database params exposed | Fixed errors, redaction matcher and existing sensitive persistence conventions |

## Boundary and Recovery Checklist

- Before, exactly at and after finite expiry; unset/zero and non-secret cases.
- Policy edited after issuance; rotation under changed policy; disabled and expired states.
- Management read/update/delete, token replacement and privileged recovery.
- Auth-versus-expiry, auth-versus-disable, rotation-versus-rotation and failed-write rollback races.
- Legacy ambiguous rows; new rows; restart; fresh schema; mixed deployment/rollback contract; custom stores.
- Honest JSON dates, UI terminology and no cleartext secret/token in retained evidence.

## Scope Control

No dependency sweep, cleanup of historical planning exceptions or signing-key encryption redesign. Preserve PKCE S256, exact redirects, hashed credentials, single-use codes, refresh-family reuse revocation, algorithm restrictions and redaction. Every implementation phase needs regression evidence; the final review must cover all changed protocol/storage/host surfaces.

## Sources

[Existing source audit](../../milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md), [RFC 7591 section 3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1), [RFC 7592 sections 2 and 5](https://www.rfc-editor.org/rfc/rfc7592.html#section-5), [RFC 7662 section 4](https://www.rfc-editor.org/rfc/rfc7662.html#section-4).
