---
phase: 15
slug: authorization-consumption-and-truthful-surface
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 15 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| OAuth client -> `/authorize` | Untrusted browser input can present stale, replayed, wrong-client, or ambiguous PAR references. | `client_id`, `request_uri`, auth request params |
| Protocol -> repository | PAR validation depends on a durable consume-once decision rather than controller-local state. | hashed `request_uri`, stored PAR row |
| Public metadata/docs -> integrator expectations | Discovery and docs define what operators and clients believe Lockspire supports. | supported-surface claims, endpoint metadata |
| Test harness -> public surface | Repo-owned tests are the enforcement point for runtime and documentation truth. | browser responses, discovery JSON, checked-in docs |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-15-01 | T | `lib/lockspire/storage/ecto/repository.ex` | mitigate | `consume_pushed_authorization_request/2` locks the PAR row with `FOR UPDATE` before consume, preventing replay races. Evidence: [repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:201), [authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:175) | closed |
| T-15-02 | S | `lib/lockspire/protocol/authorization_request.ex` | mitigate | Only Lockspire-issued `request_uri` values are accepted and the presenting `client_id` must match the stored PAR binding. Evidence: [authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:123), [authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:295) | closed |
| T-15-03 | T | `lib/lockspire/protocol/authorization_request.ex` | mitigate | Mixed raw authorization params are rejected when `request_uri` is present, preserving one source of truth. Evidence: [authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:337), [authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:320) | closed |
| T-15-04 | I | `lib/lockspire/storage/pushed_authorization_request_store.ex` | mitigate | The durable store contract remains keyed by hashed `request_uri`; protocol tests confirm no plaintext `request_uri` persistence is required for lookup. Evidence: [pushed_authorization_request_store.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/pushed_authorization_request_store.ex:1), [pushed_authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/pushed_authorization_request_test.exs:91) | closed |
| T-15-05 | I | `lib/lockspire/protocol/discovery.ex` | mitigate | Discovery publishes only `pushed_authorization_request_endpoint` for PAR and continues omitting broader request-object metadata. Evidence: [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:8), [discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:30) | closed |
| T-15-06 | R | `docs/supported-surface.md` | mitigate | The public support matrix states the narrow PAR slice explicitly, making the claim auditable against repo behavior. Evidence: [15-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/15-authorization-consumption-and-truthful-surface/15-VERIFICATION.md:25), [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:191) | closed |
| T-15-07 | E | `README.md` / `SECURITY.md` | mitigate | Preview posture and embedded-library boundaries remain explicit, preventing silent broadening into hosted-auth or CIAM claims. Evidence: [15-VERIFICATION.md](/Users/jon/projects/lockspire/.planning/phases/15-authorization-consumption-and-truthful-surface/15-VERIFICATION.md:26), [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:230) | closed |
| T-15-08 | T | `test/lockspire/web/authorize_controller_test.exs` | mitigate | Browser-path tests pin expiry, replay, and wrong-client failures so consumed PAR references cannot silently reopen. Evidence: [authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:244) | closed |
| T-15-09 | R | `test/integration/phase15_par_authorization_e2e_test.exs` | mitigate | An end-to-end `/par -> /authorize -> /token` proof demonstrates the shipped PAR slice and replay rejection under live flow conditions. Evidence: [phase15_par_authorization_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase15_par_authorization_e2e_test.exs:88) | closed |
| T-15-10 | I | `test/lockspire/web/discovery_controller_test.exs` / `test/lockspire/release_readiness_contract_test.exs` | mitigate | Discovery keys and support wording are pinned by repo-owned tests so unsupported claims cannot drift in unnoticed. Evidence: [discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:30), [release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:191) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-24 | 10 | 10 | 0 | Codex |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-24
