---
phase: 166
plan: "12"
candidate_sha: f8dd7712af7f3ef906305db549c6312284339dba
scope_digest: b532945e284ccef309358a4fa19153a68d87caecec524aadea8719a855495fb8
reviewed_at: "2026-10-22T17:10:55Z"
status: SECURED
asvs_level: 1
block_on: high
threats_closed: 25
threats_open: 0
---

# Phase 166 Independent Security Review

A separate typed security auditor independently revalidated the four-file delta from prior candidate 0bd4070d to frozen candidate `f8dd7712af7f3ef906305db549c6312284339dba`, retaining unchanged verified controls. Verdict: **SECURED**, 25/25 planned high-severity mitigations closed, 0 open. This is a bounded ASVS L1 delta review, not a new unrestricted scan.

The review scope digest `b532945e284ccef309358a4fa19153a68d87caecec524aadea8719a855495fb8` is SHA-256 of the full binary diff `git diff --binary 0bd4070d862c53cb3e8dfc4d1cf25535b232aaed f8dd7712af7f3ef906305db549c6312284339dba`. Product/source changes are limited to the final RFC clock guard, its public-facade regression, the corrected upgrade-guide proof paragraph and its existing assertions. Workspace HEAD is a planning-only descendant; source inputs match frozen f8 exactly.

The auditor independently retrieved [CI39816801430](https://github.com/szTheory/lockspire/actions/runs/39816801430), confirmed all seven live strict `main` required contexts succeeded on exact f8, and downloaded artifact12444105217. Its ZIP SHA-256 is `d10554b6ebf835fcecae73e7e17a5e485211b142250ecfb9e92509bc45dbfd1e`; allowlisted files matched the retained capture byte-for-byte and independently passed `validate_ci_receipts(expected_source_revision=f8...)`: nine scenarios, 49 executed/passed, 0 failed/skipped, all cleanup true. Safe candidate/archive/tree/receipt/validation hashes are in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json). The previous 0bd verdict is preserved verbatim in [the historical security snapshot](166-SECURITY-0bd4070d-HISTORY.md).

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
| T-166-07 | Elevation of privilege | Final RFC clock is validated after input-token locks at `grant_persistence.ex:24-27,118-124`, before eligibility, signing and writes; the public-facade regression asserts controlled failure and no token/audit mutation. |
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
| T-166-19 | Repudiation | Dedicated package lane at `run_test_matrix.sh:143` ran in current CI39816801430; all nine scenarios have positive 49/49 passed counts with no failure/skip. |
| T-166-20 | Information disclosure | CI validates the receipt pair before upload and uses a SHA-bound artifact name with 14-day retention. |
| T-166-21 | Elevation of privilege | Recovery guidance remains host-authorized and confirms the one-time reveal flow. |
| T-166-22 | Repudiation | Changed guide explicitly labels its earlier candidate proof and later correction; adapter, legacy, cutover, offline and unresolved-probe limits remain. Replacement current proof is independently verified here. |
| T-166-23 | Repudiation | Auditor independently retrieved CI39816801430, all seven live strict main required contexts on exact f8, artifact12444105217 and matching validated receipt pair. |
| T-166-24 | Tampering / Elevation of privilege | The final record follows the reuse-path mitigation, current exact-candidate CI and package receipt, and independent review. Probe/prohibition flags remain explicit. |
| T-166-SC | Tampering | No dependency or lockfile additions; pinned legacy identity and candidate provenance remain intact. |


## Current regression and package evidence

Current Fast Checks: 2 properties, 1936 tests, 0 failures, 497 excluded, 6 skipped. Minimum-supported: 2 properties, 2433 tests, 0 failures, 497 excluded, 6 skipped. Broad integration: 494 tests, 0 failures, 1941 excluded. Dedicated package lane: 3 tests, 0 failures; nine required scenarios and 49 checks passed, none failed/skipped, process/database/temp-root cleanup all true. Current focused receipts include post-guard 27/0, root's RFC/guidance 19/0, and separate Phase165 84/0 lifecycle/PG/conformance plus70/0 recovery/UI/guidance selections. Those local receipts were reused, not rerun by this auditor; the exact-candidate CI/package proof above is freshly observed.

## Preserved limits and history

A-EDGE-16/17/19 remain **unresolved** and prohibition-1/2 remain **flagged-unverified**. No predicate or passing descriptor was invented. Historical TDD limitations are unchanged. There are no unregistered flags in the twelve summaries and no accepted-risk override or new dependency. The earlier 0bd CI39776185275/artifact12424668494 and preceding candidates remain historical. Only current run39816801430/artifact12444105217 and this scoped review establish the f8 final gates. No raw child logs or credential-bearing payload was committed.
