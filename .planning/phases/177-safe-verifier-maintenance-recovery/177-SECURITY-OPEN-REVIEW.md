---
phase: "177"
slug: "safe-verifier-maintenance-recovery"
status: open_threats
threats_open: 1
threats_total: 29
threats_closed: 28
asvs_level: 1
block_on: high
audited_source: "75988f427bc244d9c7a86183cbcda8bd75989c12"
created: "2026-10-26"
---

# Phase 177 — Security

Independent typed `gsd-security-auditor` verified all 29 declared mitigations against actual source and behavioral tests. ASVS L1 presence audit; 26 high and 3 medium threats closed, with no blocking or non-blocking open threats. The orchestrator persists this report from the auditor’s structured SECURED return.

## Trust Boundaries

Host configuration → selected client/transaction/audit authority; untrusted envelope → authenticated custody; custody → authentication eligibility; inventory → complete local status; provisional callback → outer commit; JWT identity → current-row issuance guard; stored credentials/errors → diagnostic surfaces; task-local context → immutable startup state; local observations → host fleet/backup/rollback decisions.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-177-01 | Elevation of privilege | configured/0 | high | mitigate | lib/lockspire/storage/client_verifier_maintenance.ex:57,315 — complete selected authority and participant preflight before access; rejection spies in storage maintenance tests. | closed |
| T-177-02 | Tampering | compare_and_rewrap/5 | high | mitigate | lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex:103,147,155 — locked reload, exact hash/verifier CAS and verifier-only update; all-column preservation test. | closed |
| T-177-03 | Repudiation | outer transaction/audit | high | mitigate | lib/lockspire/storage/client_verifier_maintenance.ex:163,172 and repository/client_verifier_maintenance.ex:159 — selected outer transaction and atomic audit; changed is accepted after commit. | closed |
| T-177-SC | Tampering | package installation | high | mitigate | mix.exs:50 — phase-base diff contains no mix.exs/mix.lock/dependency changes; no new dependency selected or installed. This is the declared no-addition control, not a vulnerability scan. | closed |
| T-177-04 | Spoofing | inspect_custody/5 | high | mitigate | lib/lockspire/security/client_secret_verifier.ex:204,207,395,538 — authenticated client/purpose-bound custody, hash and age validation before classification; adversarial tests. | closed |
| T-177-05 | Elevation of privilege | migrated rewrap | high | mitigate | lib/lockspire/security/client_secret_verifier.ex:252,349,304,490 — original age serialized unchanged; independent authentication expiry; expired migrated preservation tests. | closed |
| T-177-06 | Tampering | legacy promotion | high | mitigate | lib/lockspire/security/client_secret_verifier.ex:267,531 and client_secret_verifier/legacy.ex:17,50 — authenticated finite legacy qualification and hash agreement; rejected persisted rows unchanged. | closed |
| T-177-07 | Tampering | bytewise cursor | high | mitigate | lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex:41,177,181 — identical C collation, UTF8 assertion; actual exclusive and non-ASCII paging tests. | closed |
| T-177-08 | Repudiation | report completion/readiness | high | mitigate | lib/lockspire/admin/client_verifier_maintenance.ex:132,200,544 — page shape/order/cursor validation; distinct progress and fresh complete nil-cursor readiness; malformed/partial tests. | closed |
| T-177-09 | Information disclosure | safe report | high | mitigate | lib/lockspire/admin/client_verifier_maintenance.ex:496,505,513,565 — allowlisted bounded details, encoded identities, authenticated key IDs and dropped internal cursor. | closed |
| T-177-10 | Denial of service | batch report memory | medium | mitigate | lib/lockspire/admin/client_verifier_maintenance.ex:15,83,496 — default 100, page bounds 1–500, cap 100 details and explicit truncation; count/cap tests. | closed |
| T-177-11 | Elevation of privilege | bare signing exclusions | high | mitigate | lib/lockspire/security/client_secret_verifier/operation_context.ex:12 and lib/lockspire/config.ex:363,412 — fresh signing validation and endpoint exclusions; bare subprocess reuse/failure tests. | closed |
| T-177-12 | Tampering | persistent startup context | high | mitigate | lib/lockspire/security/client_secret_verifier/operation_context.ex:11 and admin/client_verifier_maintenance.ex:118 — local resolver has no cache writes; default API startup snapshot; immutability test. | closed |
| T-177-13 | Denial of service | Repo lifecycle | high | mitigate | lib/mix/tasks/lockspire.clients.verifier.rewrap.ex:159 and lib/lockspire/install/repo_runner.ex:18,30 — computation and cleanup before rendering; temporary shutdown and live Repo/pool PID tests. | closed |
| T-177-14 | Information disclosure | CLI/errors | high | mitigate | lib/mix/tasks/lockspire.clients.verifier.rewrap.ex:33,83,200,270 — strict pre-execution arguments, fixed safe failures and bounded renderer; hostile argv tests. | closed |
| T-177-15 | Tampering | rotation/metadata races | high | mitigate | lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex:103,147,155 — locked CAS; independent PostgreSQL rotation-first, maintenance-first and metadata tests with exact blocker PIDs. | closed |
| T-177-16 | Repudiation | rollback/indeterminate commit | high | mitigate | lib/lockspire/storage/client_verifier_maintenance.ex:163,193 — reject nested reporting operations, postcommit result; provisional rollback/lost-response tests; no provisional success telemetry emission. | closed |
| T-177-17 | Denial of service | contention harness and short transactions | medium | mitigate | lib/lockspire/admin/client_verifier_maintenance.ex:423 and storage/client_verifier_maintenance.ex:163 — per-row transactions; test/support/client_verifier_maintenance_concurrency.ex:30,44,55 bounds barriers and exact-PID polling. | closed |
| T-177-18 | Elevation of privilege | guarded issuance race | high | mitigate | lib/lockspire/protocol/token_exchange/internal/client_authentication.ex:63 and grant_persistence.ex:235,294 — ciphertext fingerprint/current-row guard before redemption; real maintenance/JTI/no-effects test. | closed |
| T-177-19 | Spoofing | lost-key JWT | high | mitigate | lib/lockspire/protocol/client_auth/client_secret_jwt.ex:38 and lib/lockspire/admin/clients.ex:168 — unavailable fails closed; original restoration and existing authorized rotation recovery tests. | closed |
| T-177-20 | Tampering | recovery/lifecycle | high | mitigate | lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex:155 and lib/lockspire/domain/client.ex:183,276 — ciphertext-only maintenance and independent lifecycle; recovery preserves unrelated methods/custody/handoff. | closed |
| T-177-21 | Information disclosure | nested Inspect | high | mitigate | lib/lockspire/storage/ecto/client_record.ex:14,15,91; lib/lockspire/domain/client.ex:35; lib/lockspire/clients/registration_result.ex:13 — Ecto/domain/nested redaction and exact public shape tests. | closed |
| T-177-22 | Information disclosure | existing client SQL channels | high | mitigate | lib/lockspire/storage/ecto/repository/client_store.ex:29,42,57,67,78,97,125,147,171,203,224,276 and support.ex:43 — sensitive options on material reads/writes suppress both query channels; positive capture control. | closed |
| T-177-23 | Information disclosure | raw Postgrex/transaction diagnostics | high | mitigate | lib/lockspire/storage/ecto/repository/client_store.ex:348 and storage/client_verifier_maintenance.ex:174 — fixed Postgrex/DBConnection/transaction reasons before formatting; hostile diagnostic tests. | closed |
| T-177-24 | Information disclosure | forced failure matrix | high | mitigate | lib/lockspire/security/client_secret_verifier.ex:170; storage/client_verifier_maintenance.ex:134; admin/client_verifier_maintenance.ex:46 — safe failure boundaries; disclosure tests cover SQL control, DB errors, malformed/report, protocol, pool/CLI, schema, failed audit and success. | OPEN-blocking |
| T-177-25 | Spoofing | hostile identifiers | medium | mitigate | lib/lockspire/admin/client_verifier_maintenance.ex:513 and lib/mix/tasks/lockspire.clients.verifier.rewrap.ex:83 — bounded encoded IDs/fixed errors; newline/ESC/BEL tests. | closed |
| T-177-26 | Repudiation | operator retirement/recovery guidance | high | mitigate | lib/lockspire/admin/client_verifier_maintenance.ex:544; docs/client-secret-verifier-configuration.md:72,82 — fresh local-only condition, separate host duties and restoration/replacement consequences; executable guidance. | closed |
| T-177-27 | Repudiation | source acceptance | high | mitigate | 177-SOURCE-ACCEPTANCE.json — exact source, commands/counts/digests and failed history; independent auditor matched current CI and five failure logs; exact backend proof in concurrency support. | closed |
| T-177-28 | Tampering | frozen inputs/history/resources | high | mitigate | 177-SOURCE-ACCEPTANCE.json — independently rehashed all 13 frozen inputs; exact issuance fixture cleanup, generated env restoration and verifier cache restoration; no unknown resource cleanup. | closed |

## Accepted Risks Log

No accepted risks. No `accept` or `transfer` disposition was used to close a threat.

## Audit Evidence

The independent auditor confirmed all 32 changed source/test/doc files match audited HEAD, all 29 threat IDs have severities and dispositions, all 13 frozen digests match, and canonical CI plus all five preserved failure-log digests match the receipt. Canonical output contains 15 boundary tests, 2 properties plus 2,138 fast tests, and 260 integration tests, all zero failures with documented skips/exclusions retained. Full CI was not rerun by the auditor; no auditor files or resources were modified.

## Unregistered Flags and Limits

No summary contains a dedicated Threat Flags section and no new attack surface was registered there. E-09/VOPS-04 and E-10/VPROOF-01 remain unresolved unclassified flags; the three descriptorless prohibitions remain unverified and non-authoritative. They are not threat closures or automated passes.

Existing authorized plaintext handoff maps remain exact. Deliberate caller-owned inspection of the explicit plaintext secret map lies outside the diagnostic guarantee; nested stored client credentials remain redacted. Host instrumentation and PostgreSQL server logging remain outside Ecto query suppression. This audit claims source-level mitigation presence, with no arbitrary-store, fleet, package-installed composition, publication, delivery or main acceptance.

## Sign-Off

- [x] All 29 threats have a mitigation disposition and code evidence.
- [x] No accepted-risk waiver used.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set.

Approval: verified 2026-10-26 by independent typed security auditor.

## Security Audit 2026-10-26

| Metric | Count |
|---|---|
| Threats found | 29 |
| Closed | 29 |
| Open | 0 |

## Corrective Re-audit — T-177-24 Open

The first ASVS L1 audit missed WR-01 by checking audit key-name allowlists without verifying allowed values. Its earlier all-closed verdict is retained in `177-SECURITY-INITIAL.md` and was overstated. The corrected production validation is present, but the disclosure fixture at `test/integration/client_secret_verifier_maintenance_disclosure_test.exs:675` supplies only `maintenance_at`, so it now returns before row lock, replacement and the forced audit INSERT trigger. The passing error/no-write assertions do not establish that driver-disclosure scenario. Independent fake-Repo probe confirmed current attrs reject before lock while complete valid attrs reach the lock.

Current verdict: 28/29 threats closed; T-177-24 remains OPEN-blocking pending complete valid fixture attributes, positive trigger execution evidence, safe diagnostics and ciphertext/audit rollback assertions. Current CI 2,414/0 does not close this gap. No accepted risk or waiver is used.
