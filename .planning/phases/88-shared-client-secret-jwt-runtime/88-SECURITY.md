---
phase: 88
slug: shared-client-secret-jwt-runtime
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-25
---

# Phase 88 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Shared direct-client auth runtime | Lockspire-owned OAuth direct-client surfaces authenticate through `Lockspire.Protocol.ClientAuth.authenticate/3` and must resolve JWT assertions from stored client state without endpoint-local fallbacks. | Client assertions, `client_id`, registered auth method, verifier dispatch outcome |
| Secret material lifecycle | Confidential-client secret issuance and rotation must preserve hashed-at-rest password-style auth while enabling symmetric JWT verification through sealed verifier material only. | Raw client secret at issuance time, stored secret hash, sealed verifier material |
| Security-profile and surface scope | `client_secret_jwt` must remain a narrow runtime slice: `HS256` only, denied under FAPI-effective profiles, and excluded from unsupported surfaces such as `POST /par` until broader support truth is added. | Auth-method allowlists, signing algorithm policy, endpoint surface gates |
| Telemetry and durable audit | Runtime failures must expose only stable support-safe metadata and must never leak raw assertions, decoded JWT content, or secret-derived material. | Reason codes, `client_id`, auth method, replay/audit events |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-88-01 | Spoofing | `lib/lockspire/protocol/client_auth.ex` | mitigate | JWT bearer assertions parse as `:jwt_client_assertion`, resolve only after client lookup, and fail closed on registered-method mismatch with no fallback to basic, post, or asymmetric JWT. Evidence: `lib/lockspire/protocol/client_auth.ex`, `test/lockspire/protocol/client_auth_test.exs`, `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`. | closed |
| T-88-02 | Tampering | Shared direct-client surface scope | mitigate | The symmetric JWT slice is route-local and explicitly excludes unsupported surfaces; representative proof keeps `POST /par` out of scope and verifies only the shipped direct-client endpoints. Evidence: `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`, `.planning/phases/88-01-SUMMARY.md`, `.planning/phases/88-03-SUMMARY.md`. | closed |
| T-88-03 | Information Disclosure | Secret storage and persistence | mitigate | Confidential-client secret lifecycle stores the existing `client_secret_hash` plus sealed `client_secret_jwt_verifier_encrypted` material, with unseal gated by `secret_key_base`; no raw secret is persisted at rest. Evidence: `lib/lockspire/security/policy.ex`, `lib/lockspire/storage/ecto/client_record.ex`, `priv/repo/migrations/20260525120000_add_client_secret_jwt_verifier_material_to_lockspire_clients.exs`, `test/lockspire/storage/ecto/client_record_test.exs`, `test/lockspire/storage/repository_test.exs`. | closed |
| T-88-04 | Tampering | `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` | mitigate | The symmetric verifier accepts `HS256` only, rejects other algorithms including `alg=none`, and denies `client_secret_jwt` outright under FAPI-effective profiles. Evidence: `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`, `lib/lockspire/protocol/security_profile.ex`, `test/lockspire/protocol/client_auth_test.exs`, `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`. | closed |
| T-88-05 | Replay | JWT assertion validation and replay store | mitigate | Signature verification precedes claim validation, claim validation precedes replay recording, and replay detection uses `jti` plus bounded expiration after verified claims only. Evidence: `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`, `test/lockspire/protocol/client_auth_test.exs`. | closed |
| T-88-06 | Information Disclosure | Telemetry and durable audit metadata | mitigate | Failure metadata is restricted to safe fields such as `client_id`, `auth_method`, and `reason_code`, while redaction strips `client_assertion`, secret hashes, and sealed verifier material from telemetry and audit payloads. Evidence: `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`, `lib/lockspire/redaction.ex`, `test/lockspire/audit/event_test.exs`, `test/lockspire/protocol/client_auth_test.exs`. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 6 | 6 | 0 | Codex `gsd-secure-phase` |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
