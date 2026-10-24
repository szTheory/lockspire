# Phase 173: Conditional PAR & Profile Boundaries — Context

**Gathered:** 2026-10-24
**Status:** Ready for planning
**Mode:** Assumptions, automatic continuation under delegated user authority

<domain>
## Phase Boundary

Correct only P171-005's reproduced rejection of conflicting outer scope for a valid pushed request. Carry forward existing client binding, expiry, one-use, required-PAR and source-host issuer/discovery proof. Phase 172 passed 11/11; accepted implementation base remains fe38beee and the current milestone branch is separate. Packaged proof, combined candidate gates and delivery remain Phase 174.
</domain>

<decisions>
## Implementation Decisions

### Protocol authority

- **D-01:** A real valid pushed request with stored `scope=openid email` and conflicting outer `scope=profile` reaches consent with exactly pushed scopes, pushed state and pushed nonce. Ignore outer authorization parameters without union or override. RFC 9126 section 4 incorporates RFC 9101's authority rules; Phase 171 settled this reference chain. Preserve plain form-encoded PAR; do not add signed-request-object/JWT requirements.
- **D-02:** Use the existing protocol resolution boundary. The stored request already reconstructs a fresh parameter map; remove the blanket rejection that prevents reaching that boundary rather than introducing a merge, controller exception, new abstraction or response framework. Reconcile the existing protocol test that expects blanket `request_uri_conflict`. Preserve the distinct `request` plus `request_uri` collision rejection.
- **D-03:** Preserve current client lookup/eligibility, policy resolution, reference validation, client binding, expiry, locked one-use consumption and existing wrong-client burn behavior. Validate stored parameters under current policy before host handoff; outer PKCE, redirect, scopes, state or nonce must not modify pushed authority. Preserve required-PAR and host account/session/login ownership.

### Regression and preserved proof

- **D-04:** Put the durable exact P171-005 regression in the existing Phase 15 PAR integration owner. Perform real PAR POSTs, use a reference-only positive control first and a separately pushed reference for the conflicting-scope candidate. The control cannot consume the candidate's one-use reference. Require exact relative consent-route recognition and persisted interaction equality for client, pushed scopes, state and nonce; do not rely only on redirect status or a path substring.
- **D-05:** Demonstrate actual normative RED at the current qualified behavior before the correction and GREEN afterward with the same durable test. Setup, database, scope, missing nonce or replay failures do not establish RED. Record commands, source/file identities and actual output in Phase 173 summary/verification. Preserve the old Phase 171 probe as historical counterexample evidence.
- **D-06:** Reuse existing P171-001/002/003 lifecycle, P171-004 required-PAR and P171-006 configured issuer/discovery owners. Verify shared authorization/strict/PKCE and Phase 172 response-mode behavior against the selected change. Add only materially uncovered assertions needed to guard the selected boundary; do not invent additional corrections or a broad PAR feature project.

### Evidence and execution limits

- **D-07:** Declare canonical Phase 171 ledger ownership for intentional existing regression-file changes and the Phase 172–173 roadmap selector. Audit only actual reviewed identities and ordered aggregate digest using existing append-only old/new/source/reason records. Preserve cases, original source/observation identities, receipts/probes, frozen timestamp and qualification SHA. Planning and completion metadata can each alter the selector; reconcile deliberately. Covered report changes require the verifier owner to regenerate, never blind restamping.
- **D-08:** No dependency, framework, public API, schema/migration, input refresh, new flow, host-policy change or admin/UI copy. Reuse existing Elixir/Phoenix/ExUnit/private helpers, strict formatting/lint and focused integration/contract checks. Runtime/owned DB: Elixir 1.19.5, OTP 28.5, lockspire_171_main_20261024b through process-local environment.
- **D-09:** External provider-origin/TLS/proxy/browser profiles remain unavailable, unlaunched, supplemental and non-certifying. Reuse source-host metadata proof without claiming external reachability. Do not install profile inputs or turn this phase into infrastructure preparation. Packaged-host proof, combined acceptance/CI and delivery remain Phase 174.

### the agent's Discretion

All five assumptions were Confident. The executing maintainer selected the narrow existing-boundary recommendation under the user's explicit authority to unblock, follow recommendations and keep going. This records agent judgment, not fabricated human confirmation. A new product/API/security/support boundary would require explicit resolution; none was identified. Stop additional research when it no longer changes a consequential decision or test.

### Folded Todos

None selected.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` Phase 173 and `.planning/REQUIREMENTS.md` PARB-01/02/03.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` P171-005 and existing-proof owners; `171-QUALIFICATION-DECISIONS.md`, original receipt/probe and `171-LEARNINGS.md`.
- `.planning/phases/172-authorization-responses/172-CONTEXT.md`, `172-01-SUMMARY.md`, `172-LEARNINGS.md`, `172-VERIFICATION.md`.
- `AGENTS.md`, `.planning/METHODOLOGY.md`, `.planning/PROJECT.md` and `docs/supported-surface.md`.
- [RFC 9126 section 4](https://www.rfc-editor.org/rfc/rfc9126.html#section-4), [RFC 9101 section 5](https://www.rfc-editor.org/rfc/rfc9101.html#section-5) and [section 6.3](https://www.rfc-editor.org/rfc/rfc9101.html#section-6.3), already verified in Phase 171; no new normative uncertainty.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `AuthorizationRequest.resolve_authorization_params/2` rejects outer conflicts before reference validation/consumption; `pushed_request_to_params/1` already creates stored-only authorization parameters.
- Existing Ecto pushed-request store locks/deletes references before binding/expiry checks. Preserve its lifecycle rather than redesigning storage.
- Phase 15 integration provides real PAR requests, authenticated host resolver and PKCE flow. Phase 171's historical probe demonstrates independent references and exact consent-route/interaction inspection.

### Established Patterns

- Existing `authorization_request_test.exs` blanket conflict expectation must change with the corrected boundary; keep its separate request-object collision owner.
- Existing protocol/PAR/controller/discovery owners cover retained lifecycle, strict signing, metadata and callback behavior.
- Selective qualification manifest audits preserve source-bound history. A test file is a whole-byte input; completion metadata is also included by the roadmap selector.

### Integration Points

Protocol validation resolves stored authority before the normal controller/host handoff. Accounts, sessions and consent presentation remain host-owned. No new endpoint or configuration is added.
</code_context>

<specifics>
## Specific Ideas

Carry the Phase 172 lessons forward: valid controls before candidates, assert observable response contracts, correct SDK Next/resume fields, review mutable metadata hashes explicitly, and distinguish historical observations from new-source proof. Prefer a few existing primitives over a dependency.
</specifics>

<deferred>
## Deferred Ideas

Phase 174 packaged proof/candidate/CI/delivery. Optional external profiles and any automatic overlap/interruption guarantees. Future SEC-01, KMS, storage-scale and unrelated auth work retain their existing owners/triggers.

### Reviewed Todos (not folded)

No matching selected Phase 173 todo was identified.
</deferred>
