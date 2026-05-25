---
phase: 90
slug: support-truth-and-milestone-closure
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-25
---

# Phase 90 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Public support contract | Public docs must describe only the shipped `client_secret_jwt` slice and must not widen the Lockspire product contract. | Public support claims, auth-method scope, non-claims, host responsibility guidance |
| Repo-native proof surfaces | Release-contract tests, discovery tests, and representative runtime tests must pin the same narrow support facts claimed by the docs. | Discovery metadata, endpoint-scope claims, FAPI posture, runtime behavior assertions |
| Milestone closeout evidence | Maintainers and auditors rely on phase UAT and validation artifacts to verify what shipped now versus what remains deferred. | Verification commands, pass/fail evidence, deferred-work statements |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-90-01 | Tampering | `docs/supported-surface.md` | mitigate | Canonical support contract now publishes the shipped `client_secret_jwt` direct-client slice, `HS256`-only posture, issuer-string `aud`, required `jti`, replay protection, `POST /par` exclusion, and FAPI non-claim. Evidence: `docs/supported-surface.md`, `mix docs.verify`, `.planning/phases/90-01-SUMMARY.md`. | closed |
| T-90-02 | Tampering | `docs/client-secret-jwt-host-guide.md` | mitigate | Dedicated host guide constrains scope to confidential clients on Lockspire-owned direct-client endpoints, denies `HS384`, `HS512`, `POST /par`, FAPI, and mTLS-equivalence claims, and preserves host-owned responsibilities. Evidence: `docs/client-secret-jwt-host-guide.md`, `mix docs.verify`, `.planning/phases/90-01-SUMMARY.md`. | closed |
| T-90-03 | Tampering | Onboarding and DCR docs | mitigate | `docs/install-and-onboard.md` and `docs/dynamic-registration.md` link back to the canonical support contract and encode the explicit `client_secret_jwt` plus `HS256` metadata shape without creating a second support matrix. Evidence: `docs/install-and-onboard.md`, `docs/dynamic-registration.md`, `mix docs.verify`, `.planning/phases/90-01-SUMMARY.md`. | closed |
| T-90-04 | Tampering | Release/docs contract proof | mitigate | `test/support/client_secret_jwt_support_truth.ex` and `test/lockspire/release_readiness_contract_test.exs` pin the narrow support facts semantically so future doc drift fails in CI. Evidence: `mix test test/lockspire/release_readiness_contract_test.exs`, `.planning/phases/90-02-SUMMARY.md`, `.planning/phases/90-support-truth-and-milestone-closure/90-UAT.md`. | closed |
| T-90-05 | Tampering | Support-truth test design | mitigate | Shared semantic helper avoids brittle prose snapshots while still asserting direct-client scope, `HS256`, issuer-string `aud`, `POST /par` exclusion, and no FAPI or mTLS equivalence claims. Evidence: `test/support/client_secret_jwt_support_truth.ex`, `mix test test/lockspire/release_readiness_contract_test.exs`. | closed |
| T-90-06 | Tampering | Discovery and runtime proof surfaces | mitigate | Discovery and representative runtime tests keep `client_secret_jwt` route-local, exclude `POST /par`, and suppress the symmetric slice under FAPI posture. Evidence: `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`, `test/lockspire/protocol/discovery_test.exs`, `test/lockspire/web/discovery_controller_test.exs`, `mix test test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`, `.planning/phases/90-02-SUMMARY.md`. | closed |
| T-90-07 | Tampering | `docs/maintainer-release.md` | mitigate | Maintainer release guidance now explicitly defers public truth to `docs/supported-surface.md` and acknowledges only the shipped narrow `client_secret_jwt` slice. Evidence: `docs/maintainer-release.md`, `mix docs.verify`, `mix test test/lockspire/release_readiness_contract_test.exs`, `.planning/phases/90-03-SUMMARY.md`. | closed |
| T-90-08 | Repudiation | Phase closeout evidence | mitigate | Phase-local UAT artifact records the exact verification commands and marks the closeout evidence chain complete across docs, release contract, discovery, runtime, and full regression runs. Evidence: `.planning/phases/90-support-truth-and-milestone-closure/90-UAT.md`, `.planning/phases/90-03-SUMMARY.md`. | closed |
| T-90-09 | Repudiation | Deferred-work boundary | mitigate | `90-UAT.md` names `AUTH-FUT-01` and `SUPPORT-FUT-01` explicitly so broader symmetric JWT controls and advanced operator diagnostics are not implied as shipped Phase 90 support. Evidence: `.planning/phases/90-support-truth-and-milestone-closure/90-UAT.md`, `.planning/phases/90-03-SUMMARY.md`, `.planning/REQUIREMENTS.md`. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 9 | 9 | 0 | Codex `gsd-secure-phase` |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
