---
phase: 132
slug: public-api-and-resource-server-truth
status: verified
threats_total: 16
threats_closed: 16
threats_open: 0
asvs_level: 1
created: 2026-08-27
---

# Phase 132 — Security

> ASVS L1 threat contract for public token interpretation, client registration, DPoP replay persistence, and resource-server guidance.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Signed token ↔ verified semantic API | Untrusted JWT claims become normalized host-readable protocol facts only after verification. | Subject, scope, audience, expiry, confirmation claims |
| Client metadata ↔ registration persistence | Operator/direct and DCR inputs share capability/key validation before repository writes. | Redirects, grants, response types, auth method, JWKS/JWKS URI |
| Protected request ↔ replay repository | A verified DPoP proof must be durably recorded exactly once through the configured repo or a compatible explicit store. | Proof thumbprint, JTI/replay key, expiry |
| Lockspire protocol policy ↔ host business policy | Lockspire verifies token and route constraints; host code independently decides tenant/product access. | Normalized token semantics and host authorization result |
| Documentation/generated examples ↔ supported API | Executable examples must name real functions and preserve the same security boundary as runtime code. | Public API names, pipeline order, configuration guidance |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-132-01 | Elevation of privilege | Audience/scope readers | high | mitigate | Share atomic normalization with verifier; preserve exact audience bytes and reject any malformed list member. | closed |
| T-132-02 | Spoofing | Confirmation reader | high | mitigate | Allowlist only DPoP JKT and mTLS `x5t#S256` binding values. | closed |
| T-132-03 | Information disclosure | Confirmation reader | medium | mitigate | Build a new allowlisted map and discard arbitrary or malformed `cnf` members. | closed |
| T-132-04 | Spoofing / elevation | Registration shape | high | mitigate | Require redirects for authorization-code or `code` capability and retain exact runtime URI membership. | closed |
| T-132-05 | Spoofing | `private_key_jwt` registration | high | mitigate | Require confidential client, one safe key source, nonempty parseable public JWKS, and compatible algorithm. | closed |
| T-132-06 | SSRF | Remote JWKS intake | high | mitigate | Accept HTTPS JWKS URIs only; retain guarded no-redirect runtime fetcher controls. | closed |
| T-132-07 | Information disclosure | Registration errors | medium | mitigate | Return field/reason/detail diagnostics only and prove submitted key material stays absent. | closed |
| T-132-08 | Repudiation | Direct registration | medium | mitigate | Emit deterministic success/rejection telemetry with safe field/reason metadata. | closed |
| T-132-09 | Spoofing | DPoP replay default | high | mitigate | Omit absent Plug override and resolve absent/nil to configured Ecto repository; persist then reject duplicate proof. | closed |
| T-132-10 | Tampering | DPoP store failure | high | mitigate | Map storage errors to invalid proof with no fallback acceptance. | closed |
| T-132-11 | Elevation of privilege | Custom replay store | high | mitigate | Reject incompatible modules at Plug init and fail closed on invalid, failing, or raising stores. | closed |
| T-132-12 | Denial of service | Replay persistence | medium | mitigate | Prune expired rows, bound proof age, and use unique-conflict handling. | closed |
| T-132-13 | Elevation of privilege | Generated protected API | high | mitigate | Make host authorization a distinct post-token decision with executable 200 allow and 403 deny proof. | closed |
| T-132-14 | Spoofing | Resource-server guide | high | mitigate | Document configured-repository replay as the default and custom injection as advanced-only. | closed |
| T-132-15 | Tampering | Docs/generated drift | high | mitigate | Exercise rendered fixture behavior and enforce release/docs contract tests against exact public APIs. | closed |
| T-132-16 | Information disclosure | Examples/migration guide | medium | mitigate | Prefer semantic readers, retain raw claims as compatibility-only, and never emit token/proof/key material. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-27 | 16 | 16 | 0 | `gsd-security-auditor` ASVS L1 audit after review and Nyquist repairs |

Evidence recorded by the independent auditor:

- Core AccessToken, verifier, registration, DPoP, and protocol matrix: 267 tests, 0 failures.
- Durable replay, generated-host behavior, and documentation/release contracts: 57 tests, 0 failures.
- `mix docs.verify` and `mix compile --warnings-as-errors`: passed after `e48bcb8`.

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks require an Accepted Risks Log entry.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-08-27
