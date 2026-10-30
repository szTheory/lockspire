---
phase: "176"
slug: "dedicated-verifier-custody-compatible-runtime"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-25"
---

# Phase 176 — Security

Independent re-audit: 22/22 planned threats closed on corrected source `71627f27cdd996cba37122af86a033474e6cd1ff`; zero blocking or non-blocking open threats. The original 19/22 result and all four confirmed mechanisms remain in `176-SECURITY-FINDINGS.md`. No risk acceptance was needed.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-176-01 | Tampering | ClientSecretVerifier seal/open | high | mitigate | Independent AAD vectors bind purpose/version/key/client and exact tag in both tasks | closed — independent auditor control/test evidence |
| T-176-02 | Denial of service | Envelope parser | high | mitigate | Predecode encoded bound, decoded/structural bounds and canonical encoding in Task 2 | closed — independently reproduced correction; see re-audit evidence below |
| T-176-03 | Information disclosure | New crypto/context errors | high | mitigate | Redacted Inspect, allowlisted atoms, exception containment and sentinels from introduction | closed — independent auditor control/test evidence |
| T-176-SC | Tampering | Package installs | high | mitigate | No new dependency/install task; preserve mix.exs/mix.lock dependency declarations; legitimacy gate and blocking human checkpoint required for any later approved assumed/suspect package | closed — independent auditor control/test evidence |
| T-176-04 | Elevation of privilege | Config context | high | mitigate | Exact states, no invalid fallback, complete override validation and explicit activation tests | closed — independently reproduced correction; see re-audit evidence below |
| T-176-05 | Information disclosure | Startup diagnostic/context | high | mitigate | Allowlisted reasons, redacted Inspect and sentinel capture in both tasks | closed — independent auditor control/test evidence |
| T-176-06 | Denial of service | Application startup/hash auth | high | mitigate | Retain invalid state non-raising; actual persisted Basic/post auth remains available | closed — independently reproduced correction; see re-audit evidence below |
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

No accepted risks. The three initial open threats were corrected and independently verified.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-25 | 22 | 19 | 3 | Initial independent gsd-security-auditor |
| 2026-10-25 | 22 | 22 | 0 | Independent gsd-security-auditor re-audit of 71627f27 |

## Sign-Off

Verified 2026-10-25. The auditor recompiled corrected modules in memory and independently exercised SF-01 through SF-04. It confirmed all29scoped product files match the corrected candidate and all13frozen input digests match. Historical findings remain preserved. This report covers the planned Phase176register; it does not claim later maintenance/package/fleet/main/publication outcomes.


## Independent Re-Audit Evidence

| Finding / threat | Verified mechanism and evidence |
|---|---|
| SF-01 / T-176-04 | `lib/lockspire/application.ex:52` reads canonical ClientSecretVerifier settings. Actual startup probes cover absent/invalid/staged/dedicated allow/reject; Context-only settings stay absent. Regression: `test/lockspire/config_client_secret_verifier_test.exs:128`. |
| SF-02 / T-176-04 | `lib/lockspire/security/client_secret_verifier/context.ex:98` requires exact IDs/map agreement and validated values. Nine independently probed malformed/hidden/forbidden variants reject through Config/facade; valid overrides remain supported. Regression: config test line154. |
| SF-03 / T-176-06 | Context validation contains improper options/keys at lines129,160,186. Actual startup retains invalid state; Basic/post auth remains available. Persisted regression: `test/integration/client_secret_verifier_configuration_test.exs:53`. |
| SF-04 / T-176-02 | `lib/lockspire/security/client_secret_verifier.ex:291` bounds both authenticated plaintext variants. Independent native maximum/+1/+16 and migrated maximum/+1 vectors produce expected results. Regression: `test/lockspire/security/client_secret_verifier_test.exs:185`. |

Other19controls were rechecked against the source and tests named by their planned register: AEAD/AAD/IV/tag, safe error/inspection boundaries, no dependency additions, final-ID writers/hash-only independence, authenticated legacy metadata and finite deadlines, transaction/audit rollback, HS256/endpoint/JTI/fingerprint behavior, truthful rollout and source/frozen-input identity. No broad CI repeat was performed by the auditor. Its successful-log review found26focusedtests and2102fast+231integrationtests, zero failures. Earlier environmental failures and isolated PostgreSQL connection messages remain recorded.

## Reporting Limits

Six original summaries omit a Threat Flags heading; Summary06 explicitly says none. Omission was treated as reporting incompleteness, never as control evidence. E02/E14/E15 and three descriptor-less prohibition flags remain flagged unresolved/unverified; none was counted as an observed pass. Phase177 comprehensive disclosure/maintenance and Phase178 packages remain pending.
