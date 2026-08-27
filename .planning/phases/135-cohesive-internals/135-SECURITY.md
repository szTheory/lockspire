---
phase: 135
slug: cohesive-internals
status: secured
threats_total: 28
threats_closed: 28
threats_open: 0
asvs_level: 2
block_on: high
created: 2026-08-27
---

# Phase 135 — Security Audit

## SECURED

**Threats Closed:** 28/28  
**ASVS Level:** 2

The final audit covers the aggregate Ecto split, explicit token dependencies,
focused grant collaborators, and the remediation performed after initial
verification found incomplete ownership. A ten-connection PostgreSQL race proves
exactly one authorization-code redemption commits. Semantic AST fitness now
rejects the legacy/global dependency, persistence, audit, telemetry, and issuance
ownership patterns that previously remained in `GrantSupport`.

## Threat Register

| Threats | Area | Severity | Result | Evidence |
|---|---|---:|---|---|
| T-135-01..05 | Code/refresh redemption, DCR audit, Ecto secrecy | critical/high | closed | Ten independent code contenders produce one winner; DCR invalid-audit rollback and sensitive query-option tests pass. |
| T-135-06..10 | PAR, interactions, device/CIBA polling, replay | critical/high | closed | Aggregate-owned locked transitions, durable unique replay boundaries, pruning, and redaction suites pass. |
| T-135-11..14 | Refresh families and signing-key lifecycle | critical/high | closed | Locked family-wide reuse containment, key publish/activate/retire transactions, and private-material stripping pass. |
| T-135-15..17 | Explicit dependencies and safe results | critical/high | closed | `LegacyOptions` is the sole adapter; typed capability groups fail before mutation; neutral safe-error compatibility remains executable. |
| T-135-18..20 | Authentication, resource narrowing, polling | critical | closed | Focused collaborators preserve the complete auth-method, invalid-target, and device/CIBA outcome matrices. |
| T-135-21..24 | Issuance, persistence, audit, telemetry | critical/high | closed | `TokenIssuer`, `GrantPersistence`, and `GrantObservability` own their complete responsibilities with token, rollback, attribution, and redaction proof. |
| T-135-25..28 | Fitness, compatibility, QA, final evidence | high/medium | closed | Synthetic semantic AST violations fail; literal public compatibility, zero cycles, full tests, QA, docs, and final-tree evidence pass. |

## Verification

- Ten independent PostgreSQL redemption connections: one success and nine
  `:already_redeemed` outcomes.
- Re-verification: 5/5 COH requirements satisfied.
- Focused security evidence: 43 tests, 0 failures.
- `mix qa.architecture`: 13 tests, 0 failures; `No cycles found`.
- Final isolated gate: 1,392 fast tests and 284 integration tests, 0 failures.
- No unregistered threat flags were found in Phase 135 summaries.

**threats_open:** 0
