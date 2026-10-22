---
phase: 166
plan: "12"
candidate_sha: 0bd4070d862c53cb3e8dfc4d1cf25535b232aaed
scope_digest: b31c7b93d873a6828d9ef07f034919225ffa9a1491a4145840c8595c8ef42903
reviewed_at: "2026-10-22T12:29:25Z"
status: SECURED
asvs_level: 1
block_on: high
threats_closed: 25
threats_open: 0
---

# Phase 166 Independent Security Review

A separate security auditor reviewed candidate `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`, including the selected-prefix CLI fix, maintainer evidence link, and reused-host boundary audit with regression controls. Verdict: **SECURED**; all 25 registered threats closed, with no source or blocking evidence threat open.

The review scope digest is `b31c7b93d873a6828d9ef07f034919225ffa9a1491a4145840c8595c8ef42903`, the SHA256 of the binary diff from prior reviewed candidate `99a55e2e74b9f2ce7d16ad9ba170ba60dc5be556` through `0bd4070d862c53cb3e8dfc4d1cf25535b232aaed`. The reviewer independently retrieved canonical CI run [39776185275](https://github.com/szTheory/lockspire/actions/runs/39776185275), all seven live `main` required contexts, and artifact 12424668494. Its receipt has nine expected scenarios, 49 passed, zero failed/skipped, and complete cleanup. Hashes and safe counts are recorded in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json).

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
| T-166-15 | Elevation of privilege | `build_provider.py:317` audits a reused host after candidate verification and before resolver or compile Mix commands; `client_lifetime_boundary_test.py:82` and `:119` verify order and rejection of forbidden reused sources. Exact adapter-reference checks remain at `build_provider.py:212`. |
| T-166-16 | Tampering | Packaged example injects actual audit failures and checks durable state through distinct PostgreSQL observers. |
| T-166-17 | Elevation of privilege | `client_lifetime_upgrade.py:529` drains old writers before v1; canonical promotion assertions pass. |
| T-166-18 | Information disclosure / Repudiation | `client_lifetime_upgrade.py:816` and `:839` validate the exact selected prefix set before receipt rendering; safe child-output boundary and production HTTP journeys remain. |
| T-166-19 | Repudiation | `run_test_matrix.sh:143` runs the dedicated package lane; current run 39776185275 validates all nine scenarios with positive, non-skipped counts. |
| T-166-20 | Information disclosure | CI validates the receipt pair before upload and uses a SHA-bound artifact name with 14-day retention. |
| T-166-21 | Elevation of privilege | Recovery guidance remains host-authorized and confirms the one-time reveal flow. |
| T-166-22 | Repudiation | Guidance retains adapter, legacy, cutover and offline-token limits. |
| T-166-23 | Repudiation | Independent re-review retrieved run 39776185275, confirmed all seven live branch-protection contexts on the exact candidate, and validated artifact 12424668494 and its receipt pair. |
| T-166-24 | Tampering / Elevation of privilege | The final record follows the reuse-path mitigation, current exact-candidate CI and package receipt, and independent review. Probe/prohibition flags remain explicit. |
| T-166-SC | Tampering | No dependency or lockfile additions; pinned legacy identity and candidate provenance remain intact. |

## Security regression evidence

The selected-prefix CLI regression passes in the focused acceptance suite. The reused-host boundary regression observes `audit_boundary` before the resolver probe and rejects a forbidden reused router before Mix; all **40 lifetime Python acceptance tests pass**. Current Fast Checks passed **2 properties, 1,935 tests, 0 failures, 497 excluded, 6 skipped**; minimum-supported passed **2 properties, 2,432 tests, 0 failures, 497 excluded, 6 skipped**; broad integration passed **494 tests, 0 failures, 1,940 excluded**. The dedicated package lane passed **3 tests** and executed all nine required scenarios without skips. Exact current counts and identities are in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json).

## Preserved probe dispositions

The refreshed review does not silently clear A-EDGE-16, A-EDGE-17 or A-EDGE-19, and it does not convert the two descriptor-less prohibition flags into fabricated passing checks. The independent reviewer confirmed the flags remain explicit. The three assumptions remain marked **unresolved** in the evidence map, and both prohibitions remain **flagged-unverified**. Their disposition is recorded and bounded: no tests adjacent to them are represented as automatic proof of those spec-less probe predicates. The restrictions themselves are honored by the reviewed implementation and proof record; broad datastore or internal-module support is not claimed, and stale, skipped or missing proof is not represented as assurance.

The first documentation candidate `99a55e2e` passed CI but its independent review opened T-166-15 and the dependent T-166-24. The reuse-path audit was added before Mix can inspect the child, and the final reviewer verified compiled-marker present/absent paths, forbidden-source rejection, and fresh-install ordering. No high or critical finding remains open. Candidates c6, f68, and 99a55 remain historical; only run 39776185275 and artifact 12424668494 establish the current exact-candidate gates. The three edge probes remain `unresolved`, and both descriptor-less prohibitions remain `flagged-unverified`. Any later product/package/documentation/CI-input change requires affected verification and a new candidate-bound review.
