---
phase: 166
plan: "12"
candidate_sha: c6bc4174675173b13c2bd1e95fba43e5f169adb4
scope_digest: a971e2dad1f8526bee667c3cec74ac18593eab2b39befda2457fe1f9bc72d16a
reviewed_at: "2026-10-22T10:43:35Z"
status: SECURED
asvs_level: 1
block_on: high
threats_closed: 25
threats_open: 0
---

# Phase 166 Independent Security Review

An independent reviewer examined the final candidate's changed protocol, storage, host integration, packaged proof, diagnostics, evidence handling and CI surfaces against the Phase 166 threat register. The reviewer was a separate agent and did not write or modify files. Verdict: **SECURED**; all 25 registered threats closed, with no source threat open.

The review scope is candidate `c6bc4174675173b13c2bd1e95fba43e5f169adb4`, digest `a971e2dad1f8526bee667c3cec74ac18593eab2b39befda2457fe1f9bc72d16a`. Its independent live-evidence confirmation is canonical CI run [39762415198](https://github.com/szTheory/lockspire/actions/runs/39762415198), all seven target-branch required contexts successful, and artifact 12418964333 with nine expected scenarios, 49 passed, zero failed/skipped, and complete cleanup. Hashes and safe counts are recorded in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json).

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
| T-166-18 | Information disclosure / Repudiation | Safe child-output boundary, real HTTP journeys and candidate-bound positive receipts. |
| T-166-19 | Repudiation | `run_test_matrix.sh:143` runs the dedicated package lane; exact nine-scenario validation passes. |
| T-166-20 | Information disclosure | CI validates the receipt pair before upload and uses a SHA-bound artifact name with 14-day retention. |
| T-166-21 | Elevation of privilege | Recovery guidance remains host-authorized and confirms the one-time reveal flow. |
| T-166-22 | Repudiation | Guidance retains adapter, legacy, cutover and offline-token limits. |
| T-166-23 | Repudiation | Final exact-candidate run, seven live required contexts, and independently validated retained receipts close the claim-integrity threat. |
| T-166-24 | Tampering / Elevation of privilege | Umbrella closure is recorded only after gates; flagged assumptions and descriptor-less prohibitions retain explicit dispositions. |
| T-166-SC | Tampering | No dependency or lockfile additions; pinned legacy identity and candidate provenance remain intact. |

## Security regression evidence

On candidate c6bc4174, the focused protocol/storage/host security selection passed **142 tests, 0 failures** using the isolated `lockspire_phase166_security` database. The fast suite passed **2 properties, 2,432 tests, 0 failures, 497 excluded, 6 skipped**. The live Fast Checks and minimum-supported Elixir/OTP contexts also passed on the same candidate; exact counts are in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json). The six skips are existing suite skips, not lifetime package scenarios; all nine required package scenarios executed without skips.

## Preserved probe dispositions

This review does not silently clear A-EDGE-16, A-EDGE-17 or A-EDGE-19, and it does not convert the two descriptor-less prohibition flags into fabricated passing checks. The independent reviewer confirmed the flags remain explicit. The three assumptions remain marked **unresolved** in the evidence map, and both prohibitions remain **flagged-unverified**. Their disposition is recorded and bounded: no tests adjacent to them are represented as automatic proof of those spec-less probe predicates. The restrictions themselves are honored by the reviewed implementation and proof record; broad datastore or internal-module support is not claimed, and stale, skipped or missing proof is not represented as assurance.

No high or critical finding remains open. This review is limited to the stated candidate and threat register; any later product/package/documentation/CI-input change requires affected verification and a new candidate-bound review.
