---
phase: 136-static-analysis-and-sustainable-proof
audited: 2026-08-27
status: SECURED
asvs_level: 2
threats_closed: 33
threats_open: 0
---

# Phase 136 Security Audit

**Verdict: SECURED — 33/33 plan-authored threats are mitigated; no unregistered threat flags remain.**

Current-HEAD audit evidence included 185 focused security/quality tests, the focused runtime-noise contract, and `mix qa.dialyzer` with 0 errors, 0 skipped, and 0 unnecessary skips.

| Threat | Severity | Verified mitigation |
|---|---:|---|
| T-136-01 | high | Structured source-directive classifier and synthetic fixtures. |
| T-136-02 | medium | Exact structured diagnostic parsing. |
| T-136-03 | high | DCR telemetry redaction proof remains executable. |
| T-136-04 | critical | DPoP signature, method/URI, time, nonce, and thumbprint verification plus negative tests. |
| T-136-05 | critical | Durable unique replay persistence and rejection. |
| T-136-06 | high | Typed DPoP failures with redaction coverage. |
| T-136-07 | critical | Inline request-object conflict and precedence rejection. |
| T-136-08 | critical | Strict JAR key/signature and issuer/audience validation. |
| T-136-09 | high | External request-object and JWKS retrieval remain refused. |
| T-136-10 | high | Rendered/source raw-material denylist. |
| T-136-11 | high | Host guard plus read-only unsupported-action proof. |
| T-136-12 | medium | Capability proof has no macro, history, or count constructs. |
| T-136-13 | critical | Explicit plaintext and raw-secret denial assertions. |
| T-136-14 | medium | Synthetic architecture-regression predicates. |
| T-136-15 | high | Hex input and forbidden-artifact checks. |
| T-136-16 | high | Current capability-oriented release proof. |
| T-136-17 | medium | Embedded-host and no-hosted-service documentation assertions. |
| T-136-18 | high | Lifecycle persistence and audit atomicity. |
| T-136-19 | critical | Hashed and secret-safe DCR/telemetry assertions. |
| T-136-20 | high | Audit rollback and emission evidence. |
| T-136-21 | critical | Five-flow token facade preserves token, audit, telemetry, and replay behavior. |
| T-136-22 | critical | Atomic refresh-family revocation and reuse proof. |
| T-136-23 | high | Neutral typed errors plus telemetry redaction. |
| T-136-24 | high | Controller/admin rendering and raw-value denial coverage. |
| T-136-25 | high | Installer preflight and exclusive-write integration coverage. |
| T-136-26 | medium | Dialyzer is zero-warning with no skips or ignore baseline. |
| T-136-27 | high | KeyCache retry defers only before repository readiness. |
| T-136-28 | high | Ready-repository failure remains sanitized and observable. |
| T-136-29 | critical | Runtime checker redacts output and rejects routine noise. |
| T-136-30 | high | Synthetic violations and empty-current-tree predicates. |
| T-136-31 | high | Exact composite convergence command and independent component evidence. |
| T-136-32 | critical | DPoP, JAR/request-object, and five-grant characterization pass. |
| T-136-33 | critical | Admin/release redaction and successful-run noise proof pass. |

## Primary Evidence

- `test/lockspire/quality/*_quality_baseline_test.exs`
- `test/lockspire/architecture_fitness_test.exs`
- `test/lockspire/protocol/{dpop,jar,request_object}_test.exs`
- `test/lockspire/protocol/token_exchange/characterization_test.exs`
- `test/lockspire/storage/repository_atomicity_test.exs`
- `test/lockspire/protocol/dcr_telemetry_redaction_test.exs`
- `test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs`
- `scripts/ci/check_test_runtime_noise.sh`

## Accepted and Open Risk

None recorded for Phase 136.
