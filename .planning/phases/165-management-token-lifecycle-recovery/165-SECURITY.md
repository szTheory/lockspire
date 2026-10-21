---
phase: "165"
slug: "management-token-lifecycle-recovery"
status: verified
threats_open: 0
threats_total: 19
threats_closed: 19
asvs_level: 1
block_on: high
created: "2026-10-21"
---

# Phase 165 — Security

## Trust Boundaries

Bearer/URL/body to locked current client; host policy to issuance; durable state to JSON; stale snapshots to transactional writers; confirmed host recovery to one-time plaintext; lifecycle events to observers; guidance/test selection to operational decisions.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|---|---|---|---|---|---|---|
| T-165-01 | Spoofing / Elevation | with_current_client | high | mitigate | Locked-current row/hash/active checks and post-preparation clock; strict domain expiry; access tests and 10 PostgreSQL race tests. | closed |
| T-165-02 | Information disclosure | RegistrationJSON | high | mitigate | RegistrationJSON strips atom/string credential aliases and serializes effective persisted numeric deadlines; JSON/access tests. | closed |
| T-165-03 | Information disclosure / Denial | controller lookup/errors | medium | mitigate | 63041a41 defers metadata errors until final-clock management eligibility; expired invalid-body PUT receives 401 invalid_token; fresh auditor 68/0. | closed |
| T-165-SC | Tampering | package installs | high | mitigate | No installations; dependency manifests/lockfiles unchanged against ee7f8d2c, independently rechecked. | closed |
| T-165-04 | Tampering / Elevation | management duration policy | high | mitigate | Typed bounds validated in ServerPolicyRecord, DCRPolicy and Client; persistence/form/admin/no-issuance policy matrix. | closed |
| T-165-05 | Tampering | build_dcr_client/4 and wire expiry | high | mitigate | One issuance instant and provenance-selected management deadline in Registration/ClientMetadata/Client; issuance and serialization matrix. | closed |
| T-165-06 | Tampering / Spoofing | PUT body and extensions | high | mitigate | Path/body separated; locked-row preparation validates identity, forbidden fields, current secret and extension echoes; fresh request/protocol tests. | closed |
| T-165-07 | Tampering / Elevation | replacement writer | high | mitigate | ClientStore merges intended deltas into locked current state with fingerprint guard; promotion and mutation race preservation tests. | closed |
| T-165-08 | Information disclosure / Repudiation | PUT commit/audit | high | mitigate | Replacement/hash/deadline/metadata and required audit share transaction; plaintext returned after success; rollback matrix. | closed |
| T-165-09 | Elevation | host recovery | high | mitigate | No public recovery route; generated host mount uses host-owned require_operator; confirmation/current fingerprint and route boundary checks. | closed |
| T-165-10 | Tampering | recovery and v0 promotion | high | mitigate | Host recovery preserves enabled/app/secret state; whole-row v0 canonicalization and unrelated v1 deadlines tested. | closed |
| T-165-11 | Tampering / Repudiation | adapters and required audit | high | mitigate | Required audit and writer share transaction; executed dropped-field/split-authority controls and forced write/audit rollback. | closed |
| T-165-12 | Spoofing / Elevation | blocked GET/PUT/DELETE | high | mitigate | Client-wait tests prove exact pg_blocking_pids and post-wait expiry/current hash decisions (10 blocker schedules). | closed |
| T-165-13 | Tampering / Elevation | competing replacements | high | mitigate | Replacement races prove one winner, no overlap, stale rejection and refreshed retry (5 blocker schedules). | closed |
| T-165-14 | Tampering / Repudiation | concurrent secret/disable/write/audit | high | mitigate | Mutation races prove concurrent secret/disable preservation and rollback (9 blocker schedules). | closed |
| T-165-15 | Information disclosure / Repudiation | lifecycle observability | high | mitigate | Positive finite-operation event counts, host/self actors and sensitive-value redaction across telemetry/audits/logs/errors; fresh auditor batch. | closed |
| T-165-16 | Elevation / Information disclosure | host task and guidance | high | mitigate | Mounted confirmation/one-time reveal, failure/acknowledgement/navigation clearing and host/public boundaries; vocabulary/hint tests. | closed |
| T-165-17 | Elevation / Information disclosure | published guidance | medium | mitigate | 2c88994b clarifies recovery never changes app expiry and expired-app PUT remains 403 registration_expired; guidance/recovery tests. | closed |
| T-165-18 | Repudiation | validation evidence | high | mitigate | Fresh normal changed-test batch217/0, combined21/0, PG34/0, fast2properties2412tests0failures484excluded6skipped; auditor corroboration68/0 and races10/0. | closed |

Shared T-165-SC is deduplicated across seven plans. All 19 unique planned threats were independently checked; all are mitigated. No unrestricted new-threat scan was performed.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-21 | 19 | 17 | 2 medium | gsd-security-auditor, initial independent audit |
| 2026-10-21 | 19 | 19 | 0 | gsd-security-auditor, correction re-verification |

Initial T-165-03 and T-165-17 findings were corrected in 63041a41 and 2c88994b. Fresh auditor checks after correction: 68 focused tests / 0 failures and 10 PostgreSQL race tests / 0 failures, all 24 blocker schedules exercised. Before correction, explicit PostgreSQL/conformance selection passed 34/0 and the unaffected focused selection passed 202/0. Final broad corrective evidence is recorded in 165-VALIDATION.md and 165-REGRESSION-FIX-SUMMARY.md.

ASVS L1 checks registered mitigations. Arbitrary third-party adapters and a deployed host's staff authorization policy remain outside this audit; generated host guard wiring is verified separately from the unguarded test fixture.

## Sign-Off

- [x] All threats have a disposition and verified mitigation
- [x] No accepted risks
- [x] threats_open: 0 confirmed
- [x] status: verified

Approval: verified 2026-10-21

## Final Correction Impact Check

The security auditor rechecked e1883472 after CR-01 closure. All 19 mitigations remain closed, no accepted risks. Fresh normal Mix batch: 55 tests, 0 failures (access/request/protocol/app-state and PostgreSQL client-wait suites). Confirmed credential 401 → expired-app PUT 403 → eligible-app metadata 400, preparation before the final clock, and unchanged GET/DELETE exceptions. Final broader gates at 581f48cd: changed tests218/0, combined21/0, explicitPG34/0, fast2properties2413tests0failures485excluded6skipped. No dependency manifest/lockfile changes.
