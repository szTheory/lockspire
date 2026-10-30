> Later-source context: the delta below assesses published Hf962/C92 only. New E7AD control changes passed local qualification and remain unpublished; the next candidate/checkout and hosted graph require fresh observations. Its earlier identity-only closure must not be promoted to that future candidate. Canonical global OPEN_THREATS4 remains unchanged.

# Phase 178 Delivery Security Delta — 2026-10-29

**Reviewer:** Codex security auditor `/root/correction_security`  
**Verdict:** OPEN_THREATS  
**Scope:** T-178-31/32/35/36 only; ASVS Level 1, blocking threshold high.  
**Scoped threats_open:** 2.

The accepted EC92 source review and its unchanged resolved findings are inherited. This review performed no source/runtime requalification, API probes, or file writes. The immutable source security report and canonical register remain unchanged.

| Threat | Severity | Disposition | Status | Evidence / remaining gate |
|---|---|---|---|---|
| T-178-31 — Candidate identity | high | mitigate | **CLOSED — identity only** | Candidate `ffa15b8e…`, observation `d5730485…`, and native identity-validation receipt `429891a3…` bind reviewed head `f962fce4…`, executed checkout `b3271847…`, tree `5421a819…`, ordered base/head parents, run `40927824424` attempt 1, and 1,079 covered-input relations. Actual `_check_candidate_identity` / `_observe_candidate_identity` enforce Git and authoritative hosted relationships. This closes no job/artifact claim. |
| T-178-32 — Hosted graph/artifacts | high | mitigate | **OPEN — blocking** | `_check_candidate` implements authoritative seven-job and same-attempt artifact/digest/raw-partition validation. Complete successful execution remains pending: partial jobs and the floor ZIP alone cannot establish the required seven jobs and locked/floor 26-receipt, 64-case result. |
| T-178-35 — Integration/main boundary | high | mitigate | **CLOSED — pending premerge boundary** | `178-HANDOFF.json` explicitly records pending integration/main, owner and next action, null main references, and no main receipt. `_check_handoff` enforces this pending branch and guards accepted-main claims separately. Context D-19 permits this truthful premerge handoff; actual integration/main acceptance remains pending and no merge authority is inferred. |
| T-178-36 — Audit/flag lifecycle | high | mitigate | **OPEN — blocking** | Custody, reconciliation, 18 requirement dispositions and delivery integration audit preserve original failures, C98 attribution limits, E-09/E-10, E02 and non-authoritative/null-verification flags. The genuine canonical milestone audit and final phase verification remain pending. The delivery integration report explicitly excludes those claims. |

Package/source remains `ec92cca096edd4d9d9efd2d5f128889346de4c35`, closure digest `a1d8fcc089314dd56aa2f75135116b56ceac374766cc2b788c4aac1ee2a3501a`.

**Unregistered flags:** None identified in this bounded delta.

Final delivery reconciliation awaits the complete native candidate receipt and genuine audit/verification outcomes. No global security closure, accepted main, publication authority, or new remote authorization is asserted.
