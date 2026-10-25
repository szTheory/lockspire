---
phase: "176"
slug: "dedicated-verifier-custody-compatible-runtime"
status: blocked
threats_open: 3
asvs_level: 1
created: "2026-10-25"
---

# Phase 176 — Security

Independent audit: 19/22 planned threats closed; three high blocking threats remain. The initial passing CI did not exercise the four confirmed mechanisms in `176-SECURITY-FINDINGS.md`. No risk acceptance or completed-security claim.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-176-01 | Tampering | ClientSecretVerifier seal/open | high | mitigate | Independent AAD vectors bind purpose/version/key/client and exact tag in both tasks | closed — independent auditor control/test evidence |
| T-176-02 | Denial of service | Envelope parser | high | mitigate | Predecode encoded bound, decoded/structural bounds and canonical encoding in Task 2 | open — see initial findings |
| T-176-03 | Information disclosure | New crypto/context errors | high | mitigate | Redacted Inspect, allowlisted atoms, exception containment and sentinels from introduction | closed — independent auditor control/test evidence |
| T-176-SC | Tampering | Package installs | high | mitigate | No new dependency/install task; preserve mix.exs/mix.lock dependency declarations; legitimacy gate and blocking human checkpoint required for any later approved assumed/suspect package | closed — independent auditor control/test evidence |
| T-176-04 | Elevation of privilege | Config context | high | mitigate | Exact states, no invalid fallback, complete override validation and explicit activation tests | open — see initial findings |
| T-176-05 | Information disclosure | Startup diagnostic/context | high | mitigate | Allowlisted reasons, redacted Inspect and sentinel capture in both tasks | closed — independent auditor control/test evidence |
| T-176-06 | Denial of service | Application startup/hash auth | high | mitigate | Retain invalid state non-raising; actual persisted Basic/post auth remains available | open — see initial findings |
| T-176-07 | Tampering | Direct registration | high | mitigate | Select final ID before generate; reload/hash/open and cross-client substitution proof | closed — independent auditor control/test evidence |
| T-176-08 | Denial of service | Hash-only helper | medium | mitigate | Direct hash-only generation with absent/invalid custody and endpoint tests | closed — independent auditor control/test evidence |
| T-176-09 | Information disclosure | Material/helper failures | high | mitigate | Fixed reason-only exceptions, existing error-list mapping, no plaintext persistence or diagnostics | closed — independent auditor control/test evidence |
| T-176-10 | Elevation of privilege | Age/legacy policy | high | mitigate | Original finite deadlines, future rejection, equality distinction and no authentication mutation | closed — independent auditor control/test evidence |
| T-176-11 | Tampering | Legacy metadata decode/preparation | high | mitigate | Authenticated public decrypt, safe terms, strict shape/finite-age/hash agreement and unchanged unsupported inputs | closed — independent auditor control/test evidence |
| T-176-12 | Information disclosure | Legacy and age failures | high | mitigate | Frozen atoms only; new unit/caller sentinel capture without raw terms/material | closed — independent auditor control/test evidence |
| T-176-13 | Tampering | DCR identity/material | high | mitigate | Final ID before generation, persisted reload/hash/open and typed no-write failure | closed — independent auditor control/test evidence |
| T-176-14 | Tampering | Operator rotation/persistence | high | mitigate | Existing locked selected-store lifecycle; pair/audit rollback tests and unchanged fields | closed — independent auditor control/test evidence |
| T-176-15 | Information disclosure | Writer response/errors/audit | high | mitigate | Only existing one-time handoff; bounded error fields and sentinel assertions on new paths | closed — independent auditor control/test evidence |
| T-176-16 | Spoofing | Endpoint JWT matrix | high | mitigate | Real endpoint HS256/identity/audience/JTI negatives and unchanged method/profile gates | closed — independent auditor control/test evidence |
| T-176-17 | Elevation of privilege | Guarded issuance | high | mitigate | Ciphertext-only mutation rejects; no token/grant success; consumed/fresh JTI regression | closed — independent auditor control/test evidence |
| T-176-18 | Information disclosure | Protocol and auth diagnostics | high | mitigate | Missing/unavailable allowlist and sentinel capture across newly introduced failures | closed — independent auditor control/test evidence |
| T-176-19 | Denial of service | Rolling activation/rollback | high | mitigate | Actual old-reader incompatibility tests and explicit compatible-reader/key retention guide | closed — independent auditor control/test evidence |
| T-176-20 | Repudiation | Runtime acceptance record | medium | mitigate | Exact tested SHA, command exits, stable case refs and preserved frozen digests | closed — independent auditor control/test evidence |
| T-176-21 | Elevation of privilege | Operational guidance | high | mitigate | Local proof limits, host-owned readiness and later proof ownership remain explicit | closed — independent auditor control/test evidence |

## Accepted Risks Log

No accepted risks. The three open threats require implementation corrections.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-25 | 22 | 19 | 3 | Independent gsd-security-auditor |

## Sign-Off

Pending corrective implementation, focused regressions, fresh candidate evidence and independent re-audit. Historical audit findings are preserved in `176-SECURITY-FINDINGS.md`.
