---
phase: "174"
slug: "packaged-proof-delivery-handoff"
status: verified
threats_found: 17
threats_closed: 17
threats_open: 0
asvs_level: 1
block_on: high
created: "2026-10-25"
---

# Phase 174 — Security

The independent `gsd-security-auditor` verified the complete authored register: sixteen numbered threats and one deduplicated shared supply-chain entry. All seventeen mitigations are closed; no risk was accepted to close the gate. Full review covered `6c4381920af749807ea7bfa591ef3a49f91f6fb3` through `c26b6effc6ce73dd03caeb85302b1b7e377a96a0`; focused recheck at `80b34a93e2fac61811329b7c5d9be254acb9e96b` closed the final freshness finding. This is ASVS L1 scoped mitigation verification, not certification.

## Trust boundaries

Archive→vendor/resolver/compiled host; HTTP/persisted values→redacted receipt; run-owned cleanup→retained maintainer resources; historical ledger→current proof join; verifier inputs→fingerprint; candidate→canonical hosted CI; reviewed PR→protected main.

## Threat register

| Threat ID | Category | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|
| T-174-01 | Tampering | high | mitigate | One PackageIdentity crosses archive, vendor, resolution and compiled checks before HTTP; journey:2037,2062,2074,2079; build_provider:520,584; package_input:308,568. | closed |
| T-174-02 | Tampering | high | mitigate | External digest/source binding, exact selections, fields and typed positive counts; selected_receipts:108,121,140,156; behavioral mutations plus source-CI bridge. | closed |
| T-174-03 | Information disclosure | high | mitigate | Secret registration, bounded projections, redaction/sentinel scans and safe failure summary; journey:75,382,485,391,2172,2179; redaction:134. | closed |
| T-174-04 | Elevation of privilege | high | mitigate | Fixed synthetic identities and owned integer-only host files; session_controller:26,42; fetched host session account_resolver:9; strict signed auth_time at journey:652,795,819. | closed |
| T-174-05 | Denial of service | high | mitigate | Root markers/false-owner test, random databases/ports and marked cleanup; journey:125,135,340,291,231,2194,2216; mandatory receipt cleanup facts. | closed |
| T-174-06 | Tampering | high | mitigate | Independent valid controls, exact callback/state, HTML400/no Location/no OAuth fields; journey:644,705,720,738,746. | closed |
| T-174-07 | Tampering / Elevation of privilege | high | mitigate | Required PAR/S256/replay, independent foreign-client burn, live/expired reference controls and stored authority equality; journey:547,832,896,924,968. | closed |
| T-174-08 | Information disclosure | high | mitigate | Private child observer emits exactly five equality facts, no raw persisted values or new product route; journey:573,597,1209. | closed |
| T-174-09 | Repudiation | medium | mitigate | Actual role-owned reviews/input hashes and retained judgment flags; supported-surface:236,247 distinguishes proof, floor advisories and public limits. | closed |
| T-174-10 | Tampering | high | mitigate | Only guidance and171-03 manifest entries selectively audited; canonical cases/old audit prefix preserved; ledger:1917,1926; original receipt SHA unchanged. | closed |
| T-174-11 | Repudiation | high | mitigate | All63 frozen hashes and source-owner hashes match; exact receipt/index validated, no result/self hash cycle; separate executed source identities preserved. | closed |
| T-174-12 | Spoofing / Repudiation | high | mitigate | Proper affected verifier owners reassessed final operations append; SDK171/172/173 passed/current; derivative audit hashes match final reports. See closure below. | closed |
| T-174-13 | Spoofing / Tampering | high | mitigate | Actual03:13:29Z snapshot; full local mixci exit0 at ec6361d9840f2adfda85116d72fec0efe9065c6c; canonical ci.yml40156252600 attempt2 latest paginated graph exactly7 successful jobs; first failure retained. | closed |
| T-174-14 | Elevation of privilege / Repudiation | high | mitigate | PR140 remains open with explicit blocked handoff and next action; main receipt absent; existing train and synchronized-main CI/Release-no-publish protections preserved. | closed |
| T-174-15 | Denial of service / Tampering | high | mitigate | Actual retained worktree identities/unique history/custody/actions recorded; cleanup restricted to newly marked run-owned resources; demo data and unknown databases preserved. | closed |
| T-174-16 | Repudiation | high | mitigate | Proper scoped five-item lifecycle review precedes resolved/judgment transitions; exact prior plan identities/flags preserved; no mechanical or human confirmation fabricated. | closed |
| T-174-SC | Tampering | high | mitigate | No new dependency/lockfile/workflow/product API/schema/migration; existing locked package resolution, install legitimacy and publication authority preserved. | closed |

Source abbreviations name `scripts/acceptance/clean_room_saas_journey.py`, `scripts/acceptance/clean_room/{build_provider,package_input,selected_receipts,redaction}.py`, and the two `test/clean_room/provider_host/lib/` host fixture files. Evidence records are the phase INPUT-FREEZE, SOURCE-PROOF, PACKAGE-PROOF, PROOF-INDEX, CANDIDATE-GATES, DELIVERY and DISPOSITIONS artifacts.

## Freshness finding and closure

The initial full audit closed16/17 and left T-174-12 open/high: typed SDK checks found171/172 stale only because the final operations append changed174-DISPOSITIONS. A proper `gsd-verifier` reassessed both reports, preserved source/ledger/lifecycle/original RED/GREEN evidence, and justified excluding only that growing downstream derivative note from earlier covered inputs. Stable evidence remains covered (49inputs for171;17for172). Each report retains the scoped judgment evidence narratively. No source test, package or CI was rerun or relabeled for this metadata delta.

The security auditor independently confirmed all171/172/173 statuses passed/current and audit/report hashes matched. Final fingerprints:171 `v3:sha256:74c2de9f60f02a1816fda253eddfd6e5f6e2afaef2a9473f5ba2b1c01adb157a`;172 `v3:sha256:d3bc5c424e8a4aa8a7df1c80987cbeb7567ddb9e82aec551b72478f9170edf3b`. The audit references reports one-way; prior reports do not fingerprint the derivative audit.

## Accepted risks and limits

No accepted threat dispositions. Nine non-authoritative judgment recommendations remain separately counted171/172/173/174=3/2/2/2, with four current and three inherited generic assumptions unresolved. The final goal verifier still owns post-snapshot STATE/VALIDATION/completion applicability review; this security verdict does not claim a new execution of the earlier strict snapshot.

Nonblocking test-strength observation: the test named another-valid-receipt substitution mutates control_status to204, itself invalid under the schema. It does not positively establish substitution of an otherwise valid alternative. External digest enforcement exists before JSON decoding; the auditor found no missing mitigation. This limitation is preserved for code-review disposition.

The first hosted floor-browser failure remains recorded with its lost inner diagnostic; the authorized failed-job rerun succeeded at the same SHA. Local exact-floor proof is supplemental. PR140 is unmerged, no fresh main receipt exists, publication is unselected, and loopback proof establishes no public TLS/proxy/browser reachability or external profile/certification result. The auditor made no implementation writes or runtime executions.

## Historical Plan 02 scoped audit

The following preserved report covers only its original four dispositions and is not the full-phase verdict above.

# Phase 174 Plan 02 — Security

Independent GSD `gsd-security-auditor` review at ASVS Level 1 found no blocking
high or critical issue. The initial scoped audit closed T-174-07, T-174-08,
and T-174-SC; it reported T-174-09 as medium and non-blocking until the actual
review evidence and scoped judgment lifecycle were recorded. After the two
Phase 174 prohibition entries were updated and `174-DISPOSITIONS.md` was
written, the auditor performed a focused recheck and closed T-174-09.

## Reviewed source inputs

The scoped committed source range was baseline
`b29326b120b84df87c021818f6acbcd5aac4f75c` through source HEAD
`5f3fc9b39c096d8355cbba6ade5f5e7a73ca7061`. All four implementation/guidance
files matched that HEAD. Their SHA-256 values were independently compared by
the auditor:

| Input | SHA-256 |
|---|---|
| `docs/supported-surface.md` | `2cd32dee2d0bf1bcc301c26afeea634698e7b0b4a44ee55cf15204705d6f4471` |
| `scripts/acceptance/clean_room/selected_receipts.py` | `cf3d5254b39934e2d60c61b8deacbd8f8055b90406693cac8efff7a2a235b52b` |
| `scripts/acceptance/clean_room_saas_journey.py` | `1fa47489d1c4d2a7a081e629dd14b47cb831be4b96bdd21f12d22d92e43a2af3` |
| `test/acceptance/selected_receipt_test.py` | `9ff26cbbb50a58abda71e520555a124b775fb8d25370732f3ceec3d4ba665e59` |
| `174-02-PLAN.md` | `529279a6f5bb4f9048483f83b1de81cafb484fbee361c046b7cbbfbf6a5aa3a8` |
| `174-REVIEW.md` | `21e0fcd8a4f9efb7a9cdff2e2b769de1e5eed86349213ba923ff968b383b937e` |

The code review recorded in `174-REVIEW.md` has zero findings at source HEAD
`5f3fc9b39c096d8355cbba6ade5f5e7a73ca7061`; its prior duplicate-JSON-key
warning was fixed with recursive `object_pairs_hook` rejection and root/nested
negative tests. The auditor's initial review of the judgment lifecycle also
identified the working-tree versions of `174-01-PLAN.md` and
`174-DISPOSITIONS.md` as separate uncommitted inputs. The focused recheck
independently verified both entries, their flags, and their non-authoritative
status before the final lifecycle report was assembled.

## Threat register

| Threat ID | Category | Severity | Disposition | Mitigation evidence | Status |
|---|---|---:|---|---|---|
| T-174-07 | Tampering / Elevation of privilege | high | mitigate | `clean_room_saas_journey.py` uses S256 on real PAR intake; exercises required-PAR direct rejection, pushed consent/code exchange and replay rejection; owner control precedes a separate foreign-client/burn candidate; a live neighbor precedes the expired reference; P171-005 uses an independent reference-only control before a distinct outer-scope candidate and checks the persisted client, ordered scopes, state and nonce. `selected_receipts.py` enforces exact observation fields, true facts, and lifecycle status codes. | closed |
| T-174-08 | Information disclosure | high | mitigate | The private host-command seam receives expected values in process environment and emits only allowlisted equality booleans. Receipt fields are exact and typed. Verifier, state, nonce, PAR references, interaction IDs, codes and tokens are registered with the existing redactor; successful receipt validation requires redaction and run-owned cleanup. The diff adds no product route. | closed |
| T-174-09 | Repudiation | medium | mitigate | The source review binds exact input hashes and distinguishes local package evidence from CI, accepted main, publication and external profiles. `174-DISPOSITIONS.md` records both original/final prohibition lifecycle states, scoped evidence, limits and retained flags; the auditor's focused recheck verified `resolved`/`judgment` on each entry and both required non-authoritative flags. | closed |
| T-174-SC | Tampering / dependency use | high | mitigate | The reviewed committed range changes only harness, receipt validator/tests and support guidance. No dependency, lockfile, package selection, installer, framework, product API, schema, or migration changed; no install was required. This closes the declared no-new-dependency mitigation, not dependency security generally. | closed |

## Judgment flags and inherited history

Exactly two Phase 174 prohibition entries now retain the flag
`unverified-prohibition — human review recommended`. Their lifecycle is
`resolved` with `verification: judgment` after scoped review. These are
non-authoritative agent judgments; they are not human confirmation, mechanical
enforcement, or universal proof. Their original statements remain visible in
`174-01-PLAN.md` and their provenance is in `174-DISPOSITIONS.md`.

The two inherited Phase 173 judgment flags remain separate and unchanged in
`173-DISPOSITIONS.md` and `173-01-SUMMARY.md`. This audit does not upgrade their
authority.

## Evidence limits

The auditor performed static ASVS L1 pattern/call verification, committed-range
inspection, SHA-256 comparison, and `git diff --check` for the exact source
range; the whitespace check passed. The security role did not run tests, a
package journey, CI, external profiles, publication, or delivery operations.

The package receipt available during that audit was
`.artifacts/phase174/par.json`, SHA-256
`5b9b4945f36345fb80edb11ef7c1f579b93d408c2f453e213b3a256c3ec8c6a0`; it
recorded 12 executed/12 passed with cleanup and redaction true, bound to prior
source revision `ca74dfe3af194fe61111ddc5f907dd0d2f067f10` and archive digest
`ed16245dcd73c9f3d0a5542ca8ed16c6f02497ba5413cc282a9ae04a33b1e039`. The
auditor treated it as historical local package evidence, not proof of audited
HEAD, candidate CI, accepted-main status, or publication. The final Plan 02
summary records the current-source proof separately.

No external issuer/TLS/proxy/browser reachability or OIDF/FAPI certification
claim is made. External profiles remain unavailable, unlaunched, supplemental,
and non-certifying. No unregistered attack surface was identified within the
bounded reviewed diff.

**Final focused audit status:** SECURED — 4/4 threats closed, `threats_open: 0`.

## Security Audit 2026-10-25

| Metric | Count |
|---|---|
| Threats found | 17 |
| Closed | 17 |
| Open | 0 |

## Focused recheck after valid receipt substitution repair

Independent security recheck at `52c0123fc33c32f86cd94eba1ef4489dba8f2228` retained all17 mitigation dispositions closed, with zero open threats. T-174-02's test-strength note is now closed: commit `a00f0d0a8e4cc276403b5f5dccf37bb63f900458` first accepts a schema-valid303 alternate with the same source/case/binding, then requires the original external digest to reject it specifically. Python16/16 and source-CI bridge7/7 passed; independent full-source re-review is clean. No production/parser/runner/fixture/criteria change occurred.

T-174-11/12 recheck confirmed63/63 current hashes, all recorded132 source-owner hashes, actual12/12 package receipt at source `73bb46811f4b76b2372b4af2b4e21aaf42893ac1` and receipt SHA `9ec9de15ccdb3522a6dd179da1f58e8d700e2502e8885782899152700e900844`, and current passed171/172/173 owner statuses. Proof-index SHA is `fefc13619dda61b0617cc2fad445f887652edaba42ffaad5d988cb43650e8fb8`. Earlier identities/verdicts above are historical, not relabeled.

T-174-13's exact-candidate controls remain present, but the repaired test postdates candidate ec6361d and its green CI. Replacement-candidate local and canonical hosted execution remains pending and is mandatory for DELIV-01. This security check does not satisfy that requirement. The auditor made no writes or runtime executions.
