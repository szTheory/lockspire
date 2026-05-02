# Requirements: Lockspire

**Defined:** 2026-04-29
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1 Requirements

### Active

**v1.10 FAPI 2.0 Security Profile Readiness**
- **FAPI-01:** (Config) Provide a single `security_profile: :fapi_2_0_security` option to enable strict mode globally or per-client.
- **FAPI-02:** (Enforcement) Reject requests that do not use PAR when the profile is active.
- **FAPI-03:** (Sender Constraining) Reject token requests and `userinfo` access without DPoP (or mTLS) when the profile is active.
- **FAPI-04:** (Cryptography) Restrict allowed signing algorithms to `PS256` or `ES256` under the profile, rejecting `RS256` and weak curves.
- **FAPI-05:** (Redirects) Strictly enforce exact redirect URI matching with zero tolerance for trailing slash or query parameter variations.
- **FAPI-06:** (Discovery) Expose FAPI 2.0 compliance in the `.well-known/openid-configuration` metadata.

## v2 Requirements

*(None)*

## Out of Scope

| Feature | Reason |
|---------|--------|
| Implicit Flow / Form Post | Deprecated by OAuth 2.1 due to token leakage; explicitly banned by FAPI 2.0. |
| Stateful OP Sessions in Core | Host app must own the web session; Lockspire relies on a handoff seam. |
| Custom Logout Protocols | Stick to OIDC Back-Channel Logout to ensure interoperability. |
| mTLS Client Authentication | Deferred in favor of DPoP. Terminating mTLS at the Phoenix/Plug boundary via reverse proxies hurts embedded-library ergonomics. |
| FAPI 1.0 Advanced | Skipped in favor of the modernized FAPI 2.0 Security Profile, which allows DPoP and simplifies JARM. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FAPI-01 | Phase 41 | complete (Plans 41-01, 41-03, 41-04) |
| FAPI-02 | Phase 41 | complete (Plans 41-02, 41-04) |
| FAPI-03 | Phase 41 | complete (Plans 41-02, 41-04) |
| FAPI-04 | Phase 42 | open |
| FAPI-05 | Phase 43 | open |
| FAPI-06 | Phase 43 | open |

**Coverage:**
- v1 requirements: 6 total
- Mapped to phases: 6
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-29*
*Last updated: 2026-05-01 after Phase 42 revision iteration 2 traceability sync*
