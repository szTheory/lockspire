---
phase: 166
plan: "12"
candidate_sha: f68c7f0f47cb957ed8dc31b35cc78fd612eeb1ea
scope_digest: 3fd1cbc9cf04b2dbf212049399a10159ad16e1f370e9df5277b39ca4f3cee4f4
reviewed_at: "2026-10-22T11:14:28Z"
status: SECURED
asvs_level: 1
block_on: high
threats_closed: 25
threats_open: 0
---

# Phase 166 Independent Security Review

A separate security auditor reviewed candidate `f68c7f0f47cb957ed8dc31b35cc78fd612eeb1ea`, including the selected-prefix CLI fix and regression, and independently refreshed the CI and receipt gates after run completion. Verdict: **SECURED**; all 25 registered threats closed, with no source or blocking evidence threat open.

The review scope digest is `3fd1cbc9cf04b2dbf212049399a10159ad16e1f370e9df5277b39ca4f3cee4f4`, the SHA256 of the binary diff from the prior reviewed candidate `c6bc4174675173b13c2bd1e95fba43e5f169adb4` through `f68c7f0f47cb957ed8dc31b35cc78fd612eeb1ea`. The reviewer independently retrieved canonical CI run [39766614548](https://github.com/szTheory/lockspire/actions/runs/39766614548), all seven target-branch required contexts, and artifact 12420254180. The artifact has nine expected scenarios, 49 passed, zero failed/skipped, and complete cleanup. Hashes and safe counts are recorded in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json).

## Threat dispositions

Every row below is severity high, disposition mitigate, status closed. Evidence paths refer to the reviewed candidate.

| Threat | Category | Evidence and disposition |
|---|---|---|
| T-166-01 | Spoofing / Tampering | `package_input.py:191` binds package identity; `clean_room_saas_journey.py:497` exercises production HTTP registration. |
| T-166-02 | Repudiation | `lifetime_receipts.py:94` requires positive counts; final evidence map records candidate-bound statuses. |
| T-166-03 | Tampering | `package_input.py:270` checks vendor, resolver and compiled identities. |
| T-166-04 | Repudiation | `lifetime_receipts.py:256` enforces identity agreement across proof legs. |
| T-166-05 | Elevation of privilege | `client_lifetime_interactions_test.exs:108` checks independent lifetime gates. |
| T-166-06 | Tampering | `client_lifetime_interactions_test.exs:61` checks unrelated deadlines and redemption rollback. |
| T-166-07 | Elevation of privilege | `client_lifetime_grant_wait_test.exs:94` observes blocking; `grant_persistence.ex:367` rechecks authority after wait. |
| T-166-08 | Tampering | Separate secret-rotation and management-replacement race/rollback suites preserve atomicity. |
| T-166-09 | Elevation of privilege | `client_lifetime.ex:84` and `dependencies.ex:84` validate selected participants. |
| T-166-10 | Tampering | Narrow shared-authority selectors and PostgreSQL-delegating support boundary are documented and tested. |
| T-166-11 | Tampering / Elevation of privilege | `registration_management.ex:395` checks configured lookup, current-row fingerprint and time. |
| T-166-12 | Tampering | Selected transaction use and durable late-audit rollback are tested in `client_lifetime_selected_store_test.exs:128`. |
| T-166-13 | Information disclosure | `dcr_telemetry_redaction_test.exs:164` deliberately fails safely; redaction helper at `:813`. |
| T-166-14 | Information disclosure / Repudiation | `client_lifetime_upgrade.py:846` summarizes exceptions safely; `build_provider.py:363` excludes installer output. |
| T-166-15 | Elevation of privilege | `build_provider.py:212` permits only the exact token/named-adapter exception; independent bypass probes reject alternatives. |
| T-166-16 | Tampering | Packaged example injects actual audit failures and checks durable state through distinct PostgreSQL observers. |
| T-166-17 | Elevation of privilege | `client_lifetime_upgrade.py:529` drains old writers before v1; canonical promotion assertions pass. |
| T-166-18 | Information disclosure / Repudiation | `client_lifetime_upgrade.py:816` and `:839` validate the exact selected prefix set before receipt rendering; safe child-output boundary and production HTTP journeys remain. |
| T-166-19 | Repudiation | `run_test_matrix.sh:143` runs the dedicated package lane; current run 39766614548 validates all nine scenarios with positive, non-skipped counts. |
| T-166-20 | Information disclosure | CI validates the receipt pair before upload and uses a SHA-bound artifact name with 14-day retention. |
| T-166-21 | Elevation of privilege | Recovery guidance remains host-authorized and confirms the one-time reveal flow. |
| T-166-22 | Repudiation | Guidance retains adapter, legacy, cutover and offline-token limits. |
| T-166-23 | Repudiation | Independent re-review retrieved run 39766614548, confirmed all seven branch-protection contexts on the exact candidate and validated retained artifact 12420254180. |
| T-166-24 | Tampering / Elevation of privilege | Updated completion record follows current exact-candidate integration/package receipt, required CI and review; probe/prohibition flags remain explicit. |
| T-166-SC | Tampering | No dependency or lockfile additions; pinned legacy identity and candidate provenance remain intact. |

## Security regression evidence

On the prior source candidate, the focused protocol/storage/host regression selection passed **142 tests, 0 failures** on an isolated database. The final candidate f68 additionally passed the new CLI regression (3 tests, 0 failures); the independent audit also ran the 38-test lifetime Python acceptance selection with 0 failures. Final Fast Checks passed **2 properties, 1,935 tests, 0 failures, 497 excluded, 6 skipped**; the minimum-supported lane passed **2 properties, 2,432 tests, 0 failures, 497 excluded, 6 skipped**. All seven required contexts passed, and all nine required package scenarios executed without skips. Exact current counts and identities are in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json).

## Preserved probe dispositions

The refreshed review does not silently clear A-EDGE-16, A-EDGE-17 or A-EDGE-19, and it does not convert the two descriptor-less prohibition flags into fabricated passing checks. The independent reviewer confirmed the flags remain explicit. The three assumptions remain marked **unresolved** in the evidence map, and both prohibitions remain **flagged-unverified**. Their disposition is recorded and bounded: no tests adjacent to them are represented as automatic proof of those spec-less probe predicates. The restrictions themselves are honored by the reviewed implementation and proof record; broad datastore or internal-module support is not claimed, and stale, skipped or missing proof is not represented as assurance.

No high or critical finding remains open. The prior c6 run remains historical; only run 39766614548 and artifact 12420254180 establish the refreshed exact-candidate gates. This review is limited to candidate f68 and the stated threat register; any later product/package/documentation/CI-input change requires affected verification and a new candidate-bound review.
