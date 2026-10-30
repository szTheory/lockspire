# Phase 172: Authorization Responses — Context

**Gathered:** 2026-10-24 (assumptions mode, auto)
**Status:** Ready for planning

<domain>
## Phase Boundary

Correct only qualified A171-003: an otherwise valid OIDC authorization-code request with unsupported response_mode must receive HTTP 400 without OAuth Error Response parameters or a callback redirect. Carry A171-001/002 exact-redirect and callback-state evidence and A171-004/005/006 silent-authentication/freshness evidence forward. Keep host account/session authority, supported modes and strict-signing rules. Phase 173 owns P171-005; Phase 174 owns combined packaged proof and delivery.
</domain>

<decisions>
## Implementation Decisions

### Required outcome and scope
- **D-01:** Use the settled OIDC Core 3.1.2.6 outcome: HTTP 400, no Location and no structured OAuth Error Response parameters for unsupported response_mode. Existing escaped human-readable first-party error text is allowed; this is not an OAuth redirect/JSON/form response to the client.
- **D-02:** Select only A171-003 for correction. Reuse the other five authorization cases and their existing owners; do not manufacture additional corrections, flows, mode support, admin copy or host account/session policy.

### Existing protocol and delivery contracts
- **D-03:** Prefer classifying an unsupported binary mode as the existing browser error at the protocol boundary and delivering it through the existing thin controller/HTML path. Avoid a controller-only reason exception or a new error/rendering abstraction. This technical default is selected under delegated authority; preserve the existing error contract, static description and redaction.
- **D-04:** Preserve default/supported/query/JWT mode behavior and the distinct strict_message_signing_requires_jarm rejection. Preserve PAR's backchannel HTTP 400 OAuth JSON representation: validate_pushed already normalizes browser and redirect classifications to the same error. Verify the relevant existing shared-path tests; add only a material uncovered assertion if needed.

### Regression and evidence
- **D-05:** Put the durable regression in the existing authorization-controller suite through Lockspire.Web.Router. Use the exact otherwise-valid OIDC condition: registered callback, authorization code, openid/email, nonce, state, valid S256 and unsupported binary mode. Prove actual RED before the correction and GREEN afterward; do not assert the old 302 as expected behavior. A valid query-mode control follows the existing fixture's normal host-owned handoff, without changing host policy to manufacture a control.
- **D-06:** Keep regression proof source-bound in Phase 172 summary/verification: actual commands, code revision, regression-file identity and before/after results. The older phase-local probe remains historical qualification evidence and is not relabeled as a successful run at new source.
- **D-07:** Declare ownership of the canonical Phase 171 ledger for the intentional regression-file and Phase 172 roadmap-selector changes. Review those diffs, update only affected manifest identities and aggregate digest with the existing old/new/source/reason audit pattern, and run the existing ledger contract. Preserve cases, original source identities, original receipt/probe bytes, frozen timestamp and qualification SHA. No blanket hash refresh or new evidence framework.

### Dependencies and implementation discretion
- **D-08:** Add no dependency, framework, public API, migration, input refresh or external profile run. Use existing ExUnit, OTP/Phoenix primitives and private helpers. Choose the smallest coherent internal change; strict formatting, lint and focused relevant checks must pass before completion.

### Delegated discretion
All assumptions were Confident or Likely. Auto mode selected the recommended protocol-boundary approach within the user's explicit autonomous-unblock/follow-recommendations authority. This is recorded agent maintainer judgment, not fabricated human confirmation. Escalate an actually new product boundary, public API, security posture or support decision if evidence requires one. No such decision was identified.

### Folded Todos
None; the phase matching query returned no pending matches.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents must read these before planning or implementation:

- `.planning/ROADMAP.md` — Phase 172 boundary and dependency order.
- `.planning/REQUIREMENTS.md` — AUTHR-01, AUTHR-02, AUTHR-03 and acceptance rules.
- `.planning/METHODOLOGY.md` — decisive evidence-based defaults and narrow host seam.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-VERIFICATION.md` — passed 10/10 qualification, not correction acceptance.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` — A171-003, reused authorization cases and frozen manifest/audits.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-DECISIONS.md` — settled source-attributed expectations and limits.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json` — actual controlled counterexample, not a new regression run.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-LEARNINGS.md` — preserve observations and isolate proof from manifest drift.
- `docs/supported-surface.md` — claimed supported behavior.
- `lib/lockspire/protocol/authorization_request.ex` — error classification and pushed normalization.
- `lib/lockspire/web/controllers/authorize_controller.ex` — browser/redirect delivery.
- `lib/lockspire/web/controllers/authorize_html.ex` — existing escaped first-party error body.
- `test/lockspire/web/authorize_controller_test.exs` — durable HTTP regression owner.
- `test/lockspire/protocol/authorization_request_test.exs` — supported/default/strict mode proof.
- `test/integration/phase37_protocol_strictness_e2e_test.exs` — existing callback and silent-authentication evidence.
- `test/lockspire/qualification_ledger_contract_test.exs` — current file hash/selector contract.
- https://openid.net/specs/openid-connect-core-1_0.html#AuthError — OIDC Core 3.1.2.6.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
AuthorizationRequest already distinguishes browser and redirect errors; the browser helper clears callback/state. AuthorizeController already renders a first-party HTTP 400 HTML page with escaped text. The controller suite calls the real router. Existing S256/client/config fixtures and qualified source-host tests provide the needed control and regression patterns.

### Established Patterns
The unsupported-mode branch currently returns redirect_error and is delivered as HTTP 302. Supported raw modes rejected by strict signing are a different branch and must retain their established outcome. validate_pushed converts either error disposition to its existing backchannel error representation.

### Integration Points
The controller test helper currently defaults to profile/email without nonce, so the exact OIDC regression must override those inputs explicitly. The Phase 171 manifest hashes whole current regression files and a Phase 172/173 roadmap selector. Existing audited selective refreshes are required for intentional additions; original case/probe observations retain their old source identities and results.
</code_context>

<specifics>
## Specific Ideas

Prefer small auditable local code over another dependency. Use one standards-grounded correction with real RED/GREEN and carry proven behavior forward. Current process-local runtime is Elixir 1.19.5 / OTP 28.5; the owned disposable test database is lockspire_171_main_20261024b. Do not use the shared historical test database or rerun main acceptance for test/metadata edits.
</specifics>

<deferred>
## Deferred Ideas

P171-005 pushed-scope authority is Phase 173. Packaged-host proof, combined candidate/CI gates and delivery are Phase 174. External profiles remain optional/unlaunched until separately selected preparation; no automatic overlap/interruption guarantee or certification is added. SEC-01 and other future milestone candidates retain their existing triggers.

### Reviewed Todos
None matched; no scope was folded from unrelated maintenance.
</deferred>
