---
phase: 178-packaged-upgrade-proof-delivery-handoff
reviewed: 2026-10-29
reviewer_identity: "Codex security auditor /root/e7ad_evidence_audit"
verdict: SECURED
scope: declared_phase178_premerge_threat_mitigations
register_authored_at_plan_time: true
asvs_level: 1
block_on: high
threats_total: 37
threats_closed: 37
threats_open: 0
threats_open_nonblocking: 0
accepted_risks: []
unregistered_flags: []
reviewed_source_revision: e7ad5e67b7c6d00f97ce347b2576b671ddafd811
reviewed_head_revision: c465f2b8156c2f17db82910452dbcdf16aa8353b
executed_hosted_checkout: 3c7bd2ade7dfe0f8b8a29e6f7ae4dd9965e8dbee
hosted_run_id: "40954208717"
hosted_run_attempt: 2
---

# Phase 178 Final Security Assessment — Premerge

## SECURED

**Reviewer:** Codex security auditor `/root/e7ad_evidence_audit`  
**Threats closed:** 37/37  
**ASVS Level:** 1  
**Blocking threshold:** high  
**Blocking open threats:** 0  
**Non-blocking open threats:** 0  
**Accepted risks:** None.

This is the fresh global reconciliation of the 37 distinct threats authored in Plans 01–12: T-178-01 through T-178-36 and T-178-SC. Every disposition is `mitigate`; 36 threats are high severity and T-178-22 is medium. No severity was missing or silently omitted.

This assessment verifies the declared mechanisms and their applicable acceptance evidence. It is not a general vulnerability scan, an assurance about arbitrary host instrumentation, or accepted-main certification. The auditor made no file changes and ran no application, database, test, native-validator, Git or remote operation during this final reconciliation.

## Identity and inherited review applicability

- Qualified source and local package runner: `e7ad5e67b7c6d00f97ce347b2576b671ddafd811`.
- Source tree: `6562e38ea613cf1c9b8651da3bd647d764fb4c0e`.
- Selected closure: 1,079 files; canonical digest `010613c567019f5dbca057ea5b749038ec54ae273467a17f87520bac76835b1f`.
- Reviewed/published metadata head: `c465f2b8156c2f17db82910452dbcdf16aa8353b`.
- Actual hosted checkout: `3c7bd2ade7dfe0f8b8a29e6f7ae4dd9965e8dbee`.
- Hosted checkout tree: `57df3f8ec0fcfb69ca647fdc2793ab3df84f5b4c`.
- Ordered checkout parents: `[173059a166e9ade0f5f57c9980b7b2400a98538c, c465f2b8156c2f17db82910452dbcdf16aa8353b]`.
- Candidate archive: `eea947dd6a734b60bd502b4d202ecc9cfa7cc7adbdf05bf21d30fa7830f9209c`.
- Candidate extracted tree: `01285ffcc1ef607ebefe39ff02bbf08f50bb0ac44127cef1cd05dbc324bce10b`.

Read-only rehashing during this assessment confirmed every selected working file and all four immutable E7AD review pins:

| Record | SHA-256 |
|---|---|
| Source review | `7e35a20eb1eae1a118c4a553350609a42c39036402b7089d5ccf69c3fb569510` |
| Security source review | `c64676218ae201a2f7f642b1f130cda3abbc76bb6deac66a3f34a7ebadc40bdd` |
| Integration source review | `aec3cf8820976a7b16ea8b1f7307df1008e358f1eac99403c6acc38aa7badf02` |
| Independent review packet | `8961dc1c4583f6c30c2af0168254a17db73e0978fba8463b7ca69b1f997abb93` |

The E7AD source-security report’s 17 resolved findings and four deferred delivery obligations retain their original author, source and judgment. Earlier accepted mechanism reviews remain applicable through the preserved review chain and current selected-byte bindings. This report supplies the later-owner judgments; it does not edit or restamp those source reviews.

## Threat Verification

All rows below are `mitigate` dispositions. CLOSED refers to the declared bounded mitigation and applicable premerge acceptance boundary.

| Threat ID | Category | Severity | Status | Verified mitigation and evidence |
|---|---|---|---|---|
| T-178-01 | Tampering | high | CLOSED | `package_input.py:750,870,928,986,1007` validates source owner, tracked state, archive/tree, installed vendor/resolution and compiled identity. Frozen/source acceptance and fresh package receipts bind E7AD to the measured archive/tree. |
| T-178-02 | Repudiation | high | CLOSED | `verifier_receipts.py:349,413` rejects unknown/duplicate cells, wrong runner, invalid run identities, zero execution and incorrect stable case mappings. `verifier_delivery.py:433` additionally authenticates the original receipt bytes. |
| T-178-03 | Information disclosure | high | CLOSED | Scenario producers register sensitive material before capture and apply finite receipt validation before writes. `verifier_transactions.py` retains fixed failure categories and output counts/digests instead of child diagnostics. Disclosure producer safe-channel checks and strict nested schemas preserve the durable-output boundary. |
| T-178-04 | Elevation of privilege | high | CLOSED | `verifier_core.py:375` exercises unsupported, mismatched and participant-mismatched maintenance declarations and requires rejection with zero inventory/fetch/write callbacks. The selected delegated-store witness remains connected to actual maintenance authority. |
| T-178-05 | Tampering | high | CLOSED | `verifier_core.py:153–194` separates preview/apply from a fresh beginning-to-end check and rejects unknown material. Recovery `complete_check_ready?/0` requires completed scan with no failed, pending or uninspected rows. |
| T-178-06 | Information disclosure | high | CLOSED | `verifier_core.py:321` captures bounded CLI results, redacts and checks safe output, and validates explicit statuses. Finite core receipts and installed CLI results preserve the report boundary. |
| T-178-07 | Tampering | high | CLOSED | `verifier_receipts.py:553–575,632` enforces accepted-source/public identities, exact provenance fields and pinned source proofs. Rollout independently builds/authenticates its predecessor; the Hex 2.6 predecessor requalification remains separately attributable. |
| T-178-08 | Tampering | high | CLOSED | `verifier_rollout.py:200–249` requires observed old-process drain before dedicated activation, durable dedicated-row controls, compatible rollback reads and isolated old-code rejection. Current strict receipts require these observations. |
| T-178-09 | Repudiation | high | CLOSED | Rollout limits public control to its declared selection and keeps it distinct from accepted-source upgrade proof. Candidate/gate histories retain failed attempts and their original identities without mixing them into the successful attempt. |
| T-178-10 | Spoofing | high | CLOSED | `verifier_endpoints.py:470,521,540` invokes installed HTTP authentication and negative algorithm/issuer/audience controls, plus same-assertion replay rejection. The selected five-endpoint and credential-lifecycle cases are required by current receipt validation. |
| T-178-11 | Elevation of privilege | high | CLOSED | Endpoint producer and receipt contracts require explicit unsupported PAR and both FAPI-profile rejection controls. `verifier_endpoints.py:564` performs the FAPI exclusions rather than inferring them from ordinary token success. |
| T-178-12 | Repudiation | high | CLOSED | `verifier_endpoints.py:126–193` assembles and starts a release, invokes live RPC and checks loaded module location/digest and startup context. Fixed RPC descriptions and independent package/runtime owner authority prevent arbitrary descriptive substitutes. |
| T-178-13 | Tampering | high | CLOSED | `verifier_transactions.ex:44,103,383,427` obtains actual backend identities and `pg_blocking_pids`, exercises both contention orders and inspects authoritative durable state. Installed contention receipts preserve the executed witnesses. |
| T-178-14 | Tampering | high | CLOSED | `verifier_transactions.ex:173,440` installs a reached audit-INSERT failure witness using a sequence, then requires unchanged ciphertext and absent committed audit. It does not substitute an earlier generic error for the INSERT witness. |
| T-178-15 | Repudiation | high | CLOSED | `verifier_transactions.ex:208,244–275` separately verifies provisional outer rollback, nested-report rejection and a real top-level `:apply` whose successful report follows changed durable ciphertext and committed audit. The former dry-run-only mechanism is not used. |
| T-178-16 | Tampering | high | CLOSED | `verifier_recovery.ex:44–52,355` compares hash, partner-secret validity, unrelated fields and authenticated age evidence. The selected source owners and installed receipt binding preserve exact age/deadline semantics without granting a fresh lifetime. |
| T-178-17 | Tampering | high | CLOSED | Recovery repeat/interruption observations and `simulated_unavailable_reconciles?/1` require retained committed effects, no duplicate changes and a separate complete fresh check. Indeterminate results are not labelled rollback. |
| T-178-18 | Elevation of privilege | high | CLOSED | `verifier_recovery.ex:105–284` correlates the real HTTP request/current-row guard, committed independent maintenance, stale request and same-JTI replay with durable effects, then requires fresh-JTI success. |
| T-178-19 | Spoofing | high | CLOSED | Recovery producer/host cases distinguish restoration of the original valid key from authorized existing credential replacement and retain separate HTTP consequences. No automatic partner-secret replacement or age extension is inferred. |
| T-178-20 | Information disclosure | high | CLOSED | `verifier_disclosure.py:75,147,195–289,366` registers material/private handoffs before processing, checks success and failure channels and requires nonzero control coverage with zero leaks. Current process/reference/phase attribution remains exact. |
| T-178-21 | Information disclosure | high | CLOSED | `verifier_receipts.py:507` and independent receipt-owner validation enforce finite nested fields, authenticated package/runtime strings and exact invocation descriptions before copying raw bytes. Disclosure numeric facts reject booleans, floats, negatives and oversized values before affirmative predicates. |
| T-178-22 | Repudiation | medium | CLOSED | Disclosure guidance and Plan 07 evidence retain the owned-channel/source-proof boundary and explicit host/server instrumentation limitations. No arbitrary-host logging certification is claimed. |
| T-178-23 | Repudiation | high | CLOSED | `verifier_delivery.py:433–541` binds each raw scope/pair/store/case/count/run identity to its indexed cell and requires the exact 26-receipt/64-case matrix. Fresh union and hosted pair validation both accepted the complete partition set. |
| T-178-24 | Tampering | high | CLOSED | Wrapper validates narrow CI/final paths and caller pins before mutation and isolates explicit fake mode. `package_input.py:167,336,400` implements authenticated ownership admission and gated target activation before execution; wrapper teardown reconciles registered sessions. |
| T-178-25 | Repudiation | high | CLOSED | CI provisions its job-owned frozen manifest and explicitly selects it. Wrapper and uploaded-artifact consumers validate original safe raw copies, context pins, actual runtime profiles and checkout/package identities. Actual attempt-2 current/minimum partitions passed independently. |
| T-178-26 | Elevation of privilege | high | CLOSED | Verifier configuration and host guidance retain host ownership of fleet readiness, retained keys, rollback, backups and authorized credential recovery. Local custody proof is explicitly limited to the selected store/package. |
| T-178-27 | Repudiation | high | CLOSED | `docs/maintainer-release.md:37–57` separates premerge review, integration, exact synchronized-main acceptance and publication. Current guidance is bound by the accepted source review and verified installed behavior. |
| T-178-28 | Repudiation | high | CLOSED | `verifier_delivery.py:87` and `verifier_input_closure.py` derive the bounded tracked closure. Freeze/source/candidate checks compare selected paths and blobs across actual identities. Read-only rehash confirmed all 1,079 current selected files. |
| T-178-29 | Repudiation | high | CLOSED | `validate_reviews()` binds original author, reviewed revision, complete scope, report bytes and classified findings. `_owned_source_manifest()` validates actual successful canonical stages and cleanup before source acceptance. Three immutable E7AD review lanes and fresh source guard evidence are present. |
| T-178-30 | Tampering | high | CLOSED | Source acceptance requires the exact three nonzero successful canonical suites and complete strict package result. E7AD records actual 2,463 tests/zero failures/two properties and fresh local 26/64/zero; earlier source failures remain preserved. |
| T-178-31 | Repudiation | high | CLOSED | `_check_candidate_identity()` and `_observe_candidate_identity()` validate actual head, synthetic tree/ordered parents, PR merge ref, authoritative run association and all 1,079 covered blob relationships. Fresh native validation accepted c465/3c7bd2a/attempt 2; no f962 closure was promoted. |
| T-178-32 | Repudiation | high | CLOSED | `_check_candidate()` authenticates all seven successful jobs from CI40954208717 attempt 2, both owner-job uploads, hosted archive digests and strict raw partitions. Native acceptance returned locked14/33 and floor12/31, totaling26/64. |
| T-178-33 | Elevation of privilege | high | CLOSED | Actual push/body and one-rerun approvals are separately recorded as executed and consumed. Handoff and release guidance preserve pending integration/main and separate merge/publication authority. This assessment performs and authorizes no remote mutation. |
| T-178-34 | Tampering | high | CLOSED | Original custody records, gated session admission, source guard target/creation/OID checks and retained-data dispositions constrain cleanup to proven ownership. Independent post-audits verified new owned closures and preservation; unknown historical resources and limitations remain untouched. |
| T-178-35 | Elevation of privilege | high | CLOSED — premerge branch | `_check_handoff()` enforces explicit pending integration/main, owner/action, null main references and absent main receipt. Native handoff validation passed that branch. D-19 permits it; actual integration and accepted-main helper execution remain pending. |
| T-178-36 | Repudiation | high | CLOSED | Genuine canonical `v1.48-MILESTONE-AUDIT.md`, independent `v1.48-INTEGRATION-CHECK.md`, final 4/4 Phase178 goal verification and the 18-ID evidence ledger now exist. Their actual contents retain original failed attempts, flags, unknown predicates and custody limits. This independent assessment explicitly reconciles the global register rather than inferring closure from checkboxes or candidate success. |
| T-178-SC | Tampering | high | CLOSED | Accepted source reviews retain the no-new-runtime-dependency boundary. Source/package, predecessor and public-control owner checks remain implemented; archive/tree/source and selected lock/runtime identities are independently authenticated before acceptance. |

## T-178-36 final lifecycle judgment

The genuine audit aggregates the approved four-phase scope, existing independent phase verification, all 18 requirement owners and five integration flows. The independent Phase178 verifier now finds all four roadmap truths and all three Phase178 requirements satisfied. Its remaining `human_needed` item assigns this independent security-owner judgment; it identifies no missing runtime behavior.

I independently reviewed that report and the canonical audit, integration assessment, requirement ledger, dated handoff/custody records, executed validation map and milestone arc. All 18 requirement dispositions are distinct and complete at their stated boundaries. VDELIV-02 is satisfied at the permitted pending-main premerge boundary, not by asserting accepted main.

The source review’s four deferred obligations are now resolved by fresh evidence and judgments:
- T-178-31: actual candidate identity.
- T-178-32: complete same-attempt hosted graph and artifacts.
- T-178-35: enforced truthful pending-main handoff.
- T-178-36: actual audit, final goal verification and preserved flag lifecycle.

The original full-register report, subsequent implementation reviews, E7AD source review with four deferred owners, prior f962 delta and fresh c465 delta remain historical authored judgments. This new assessment supersedes their current global open count through explicit reconciliation; it does not rewrite their original findings or dates.

## Executed evidence and custody boundary

The actual native attempt-2 checker completed original execution34027 with exit0. Result SHA `cc8b78ac28351f59af6a1c1501627d99cd58ceb00d75814c516126ce83d95b90` records successful candidate and handoff stages at c465.

Independent post-audit verified 80 distinct original custody tokens closed, six temporary roots retained, nine phase records unchanged during that execution and the protected root tar intact. The validator started no application, source tests or PostgreSQL.

The actual same-attempt package artifacts are:
- Locked12935811315, SHA `2b102097ea2a8f4f42b5bf72d015b4775b803ab252bdda51a1170fed0d53a180`.
- Floor12935791386, SHA `49e8756d998a3314b963a327b8e060b6d7bdf281d9bd21fd01f151170d99cf13`.

Both bind hosted runner3c7bd2a to E7AD package source and the authenticated archive/tree. Earlier EC92 lifetime47checks/9scenarios, SaaS5groups and96installed-host scenarios retain their original source/runtime identities and apply only through measured package-byte continuity. They were not rerun or restamped E7AD.

## Preserved limitations and follow-up

- E02/E14/E15, E09/E10, generic/spec-less edges, descriptorless prohibitions, null verification and non-authoritative classifications retain their original status and any original human-review recommendation. Closing declared mitigations does not pass or dismiss those observations.
- Historical synthetic-secret disclosures, wrong-target database incidents, failed source/wrapper/CI attempts, unknown predicates and closure limitations, C98 attribution limits, retracted judgments and root-tar restoration history—including the unknown pre-overwrite inode—remain disclosed and unwaived.
- Attempt1 failures and the prior cancelled run contribute no jobs or artifacts to accepted attempt2.
- Phase178 formal Nyquist coverage remains NOT-VALIDATED/TODO; the frozen draft and false compliance bits remain unchanged. The executed supplement records actual commands and threat owners. This report invents no probe or Nyquist compliance result. The formal coverage TODO is non-blocking for this declared-mitigation assessment because no concrete missing mitigation or failed required runtime outcome was established.
- Integration and accepted main remain pending; no Phase178 main receipt exists. The next milestone’s implementation and publication remain outside this acceptance.
- Before final audit pinning, correct its corrupted candidate-projection hyperlink to the existing `178-11-CANDIDATE-VALIDATION-c465f2b8-attempt2.json`. Direct inspection verified the actual projection; this is an editorial pointer correction, not missing execution evidence. Preserve earlier audit snapshots.

**Unregistered flags:** None identified within the declared mitigation review. No blind scan for new vulnerabilities was performed.

**threats_open: 0**

This assessment supplies the independent security judgment required by final verification. Phase/audit bookkeeping may now reconcile that actual judgment. It grants no merge, main-acceptance, rerun or publication authorization.
