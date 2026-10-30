# Phase 178 Delivery Security Delta — c465 / attempt 2 — 2026-10-29

**Reviewer:** Codex security auditor `/root/e7ad_evidence_audit`
**Verdict:** OPEN_THREATS
**Scope:** T-178-31/32/35/36; ASVS Level 1; blocking threshold high.
**Scoped threats_open:** 1.

This is a fresh assessment of reviewed head `c465f2b8156c2f17db82910452dbcdf16aa8353b`, actual checkout `3c7bd2ade7dfe0f8b8a29e6f7ae4dd9965e8dbee`, and CI `40954208717` attempt 2. It does not inherit candidate closure from the earlier f962 attempt. The accepted E7AD source review and resolved implementation findings remain attributable to their original author and source.

| Threat | Severity | Disposition | Status | Verified evidence |
|---|---|---|---|---|
| T-178-31 — Candidate identity | high | mitigate | CLOSED | `verifier_delivery.py:971` and `:1082` validate source acceptance, covered blobs, Git shape, authoritative workflow attempt, PR association, merge ref and GitHub commit relationships. Candidate SHA `7eae83d326385d854994b22909ff8d450e1796af97df5efdddfa6820b3e4e025` and observation SHA `a3c7ba2af93d12ed306fd731bce4bca4bbf2e894762eab36a4ce0084b22dca5f` bind the actual checkout, tree `57df3f8ec0fcfb69ca647fdc2793ab3df84f5b4c`, ordered base/head parents, and all 1,079 covered-input relations. The native candidate checker passed at head c465. |
| T-178-32 — Hosted graph/artifacts | high | mitigate | CLOSED | `verifier_delivery.py:1334` requires the authoritative complete seven-job graph, exact run/attempt, artifact ownership, hosted archive digests, strict raw receipt partitions and runtime profiles. Gates SHA `11e68b0742985705235f25b0424e62504941f3f2d073a266d064244cbb9c2284` and terminal observation SHA `2f9fa1c3cb81cf8fd5d92c56626b0c5ad75cec08fc89e468b1c2145f24b9d0e9` record seven successful attempt-2 jobs. Locked artifact 12935811315 and floor artifact 12935791386 match their job upload proofs and hosted digests. Native validation accepted 14/33 and 12/31 receipts/cases, totaling 26/64 with zero failures. Failed earlier attempts remain preserved. |
| T-178-35 — Integration/main boundary | high | mitigate | CLOSED — pending premerge boundary | `verifier_delivery.py:1462` enforces the pending handoff branch, owner/action fields, null main references and absence of a main receipt. Native handoff validation returned `accepted_main=false`, `integration_status=pending`. D-19 permits this explicit premerge boundary. Actual integration, accepted main, merge and publication remain unasserted and require their own authorization and evidence. |
| T-178-36 — Audit/flag lifecycle | high | mitigate | OPEN — blocking | Genuine canonical milestone audit and final phase verification remain pending. Historical failures, unknown predicates and closure limitations, E-09/E-10, E02, generic edges, descriptorless prohibitions and null/non-authoritative verification flags must retain their original dispositions through those assessments. Candidate success does not close this obligation. |

## Native execution and custody

The exact statically accepted attempt-2 checker `c05f87d5175227ee52b28ef01ab8ca17fe21c1fb90a15f4f8e3720a6f1226e1a` completed original execution 34027 with exit 0. Result SHA `cc8b78ac28351f59af6a1c1501627d99cd58ceb00d75814c516126ce83d95b90` records successful candidate and handoff stages.

Independent read-only post-audit verified 80 distinct original custody tokens closed, six temporary roots retained, nine phase records unchanged by digest and mode, and protected root archive unchanged. No application, source test or PostgreSQL execution was started by this validation.

Locked ZIP SHA: `2b102097ea2a8f4f42b5bf72d015b4775b803ab252bdda51a1170fed0d53a180`.
Floor ZIP SHA: `49e8756d998a3314b963a327b8e060b6d7bdf281d9bd21fd01f151170d99cf13`.

Both hosted partitions identify runner 3c7bd2a and package source E7AD, archive `eea947dd6a734b60bd502b4d202ecc9cfa7cc7adbdf05bf21d30fa7830f9209c`, tree `01285ffcc1ef607ebefe39ff02bbf08f50bb0ac44127cef1cd05dbc324bce10b`.

**Unregistered flags:** None identified in this bounded delta.

The prior global OPEN_THREATS4 assessment remains an unchanged historical assessment pending explicit final reconciliation. This delta closes three scoped delivery obligations and leaves T-178-36 blocking; it grants no global closure or new remote authorization. Refresh stale attempt-progress handoff/status text before final audit.
