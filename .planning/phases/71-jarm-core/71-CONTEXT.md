# Phase 71: JARM Core - Context

**Gathered:** 2026-05-07
**Status:** Captured after execution

<domain>
## Phase Boundary

Phase 71 adds JARM core support for the existing authorization-code surface: accept `response_mode=jwt` plus `.jwt` composite modes, sign authorization responses as JWTs, inject the issuer to prevent mix-up attacks, and publish truthful discovery metadata for the shipped JARM slice. This phase does not broaden Lockspire into hybrid/implicit flow support, JARM encryption, or FAPI 2.0 Message Signing strict enforcement.

</domain>

<decisions>
## Implementation Decisions

### Decisioning posture

- **D-01:** Downstream work for this phase should follow a research-first, recommendation-heavy posture. Prefer one coherent recommendation bundle over broad option menus, and escalate only for decisions that materially affect public API shape, security posture, support truth, or embedded-library boundaries.

### JARM signing posture

- **D-02:** Ship JARM as a compatibility-first feature for the normal OIDC surface rather than as an early FAPI-only capability.
- **D-03:** Keep JARM signing posture derived from existing effective policy sources: client metadata plus `SecurityProfile`. Do not introduce a second crypto-policy plane just for JARM.
- **D-04:** When stricter security posture is active, Lockspire should naturally converge on the profile-approved signing algorithms. Mandatory Message Signing strictness remains a later enforcement concern, not a Phase 71 compatibility break.

### `response_mode=jwt` semantics

- **D-05:** Keep bare `response_mode=jwt` as the standard JARM shorthand, resolved only within currently supported `response_type`s.
- **D-06:** For the current Lockspire surface, `response_type=code` is the only supported flow, so bare `jwt` resolves to `query.jwt`.
- **D-07:** Support for `fragment.jwt` and `form_post.jwt` on the authorization-code path is acceptable and truthful, but it must not imply hybrid or implicit flow support.
- **D-08:** Phase 71 documentation, tests, and support claims must state explicitly that JARM is implemented only for the authorization-code path in v1.19.

### JARM JWT claim contract

- **D-09:** Phase 71 should be framed as a narrow signed wrapper over the existing authorization response payload, not as a stricter JWT contract than the phase can truthfully enforce.
- **D-10:** The stable guaranteed JARM claim contract for this phase is: the authorization response parameters for the success or error path, plus the required JARM claims `iss`, `aud`, and `exp`.
- **D-11:** Do not lock in `iat`, `jti`, `nbf`, custom purpose claims, or replay-oriented semantics in Phase 71. Those would over-specify the contract ahead of the encryption and strict-mode phases.

### Discovery truthfulness

- **D-12:** Discovery metadata for JARM should follow the same truth model as the rest of Lockspire discovery: advertise what the mounted authorization surface can actually produce under the current effective runtime capability, not the maximum feature set the codebase could theoretically support.
- **D-13:** `response_modes_supported` and `authorization_signing_alg_values_supported` should come from one shared capability source tied to the authorization surface and effective signing posture.
- **D-14:** Do not statically advertise the full JARM mode set merely because the library contains a JARM code path. Metadata drives client behavior and must remain a runtime contract.

### DX and support posture

- **D-15:** Preserve great relying-party DX by accepting standard JARM shorthand and broad baseline interoperability, while keeping support claims narrow and explicit about the current flow matrix.
- **D-16:** Preserve great host-app DX by keeping protocol truth inside Lockspire. Host apps should not own JARM algorithm policy, metadata truth, or flow-specific response-mode interpretation.

### the agent's Discretion

- Exact helper and predicate names for shared JARM capability truth.
- Exact wording in docs and discovery tests, as long as it remains explicit that Phase 71 is authorization-code-only.
- Whether discovery signer-readiness is based only on effective algorithm posture or additionally on active-key availability at publication time, provided the published contract remains truthful and least-surprising.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle for Phase 71 is:
  - broad but truthful JARM support now,
  - stronger Message Signing enforcement later,
  - no second crypto-policy plane,
  - no over-promised claim contract,
  - no metadata overclaiming.
- Ecosystem lessons that should shape this phase:
  - Mature servers separate baseline feature enablement from stricter profiles instead of surprising normal clients with high-assurance defaults.
  - Discovery metadata is operational truth, not marketing copy; clients really do auto-negotiate from it.
  - Repurposing bare `response_mode=jwt` into a non-standard Lockspire-only synonym would be a future footgun.
  - Adding extra JWT claims early can accidentally imply stronger semantics than the server actually enforces.
- Strong DX for this slice means:
  - JARM-aware clients can send the standard shorthand and get expected behavior.
  - Host Phoenix apps do not need to reason about JARM internals beyond normal client metadata and policy posture.
  - Future Phases 72 and 74 can tighten confidentiality and enforcement without rewriting the basic contract.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning artifacts
- `.planning/PROJECT.md` — embedded-library boundary, milestone goal, and release/support posture
- `.planning/REQUIREMENTS.md` — `JARM-01` and `JARM-02`
- `.planning/ROADMAP.md` — Phase 71 goal and success criteria
- `.planning/STATE.md` — current milestone position
- `.planning/METHODOLOGY.md` — research-first, decisive-default, high-threshold-escalation posture

### Prior phase context
- `.planning/phases/41-fapi-2-0-profile-configuration/41-CONTEXT.md` — effective security-profile posture and strict-enforcement precedent
- `.planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md` — one shared capability source, metadata truth, and no second crypto-policy plane
- `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` — shared algorithm-truth and least-surprise verifier posture that should inform later Message Signing work

### Phase-local artifacts
- `.planning/phases/71-jarm-core/RESEARCH.md` — original phase research and JARM delivery shape
- `.planning/phases/71-jarm-core/ASSUMPTIONS.md` — original assumptions and early risk framing
- `.planning/phases/71-jarm-core/71-01-SUMMARY.md` — signer implementation summary
- `.planning/phases/71-jarm-core/71-02-SUMMARY.md` — authorization-flow and discovery integration summary

### Code and tests
- `lib/lockspire/protocol/jarm.ex` — JARM signing utility and current claim shape
- `lib/lockspire/protocol/authorization_request.ex` — response-mode validation and bare `jwt` resolution
- `lib/lockspire/protocol/authorization_flow.ex` — JARM redirect formatting and authorization response wrapping
- `lib/lockspire/protocol/discovery.ex` — JARM metadata publication and algorithm advertisement
- `lib/lockspire/protocol/security_profile.ex` — effective algorithm posture source
- `lib/lockspire/web/controllers/authorize_controller.ex` — authorization redirect and browser/error delivery behavior
- `test/lockspire/protocol/jarm_test.exs` — JARM claim and signing coverage
- `test/lockspire/protocol/authorization_request_test.exs` — response-mode validation and defaulting coverage
- `test/lockspire/protocol/discovery_test.exs` — metadata truth coverage

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.SecurityProfile` already provides the right source of effective algorithm posture.
- `Lockspire.Protocol.Discovery` already contains the repo’s central truth-based metadata pattern and should remain the only publication point for JARM discovery state.
- `Lockspire.Protocol.AuthorizationRequest` already implements response-type-aware response-mode resolution and is the right boundary for bare `jwt` semantics.
- `Lockspire.Protocol.AuthorizationFlow` already owns redirect formatting and is the correct place to keep JARM delivery-mode behavior coupled to the authorization result.

### Established Patterns

- Lockspire prefers durable protocol state plus derived runtime behavior over parallel ad hoc policy knobs.
- Controllers are thin delivery adapters; protocol modules own correctness and security behavior.
- Discovery metadata is expected to follow mounted/runtime truth, not future intent.
- Strict FAPI behavior is introduced as explicit profile enforcement, not as a hidden tightening of baseline OIDC capability.

### Integration Points

- Future JARM hardening should stay centered on `AuthorizationRequest`, `AuthorizationFlow`, `Jarm`, `Discovery`, and `SecurityProfile`.
- Phase 72 should consume this context as the baseline when adding nested encryption and extended metadata.
- Phase 74 should consume this context when deciding what becomes mandatory under Message Signing strict mode versus what remains general JARM interoperability behavior.

</code_context>

<deferred>
## Deferred Ideas

- JARM encryption and nested JWE response handling — Phase 72
- Any stronger or mandatory Message Signing enforcement posture — Phase 74
- Hybrid or implicit flow support
- Expanded JARM claim contract such as `iat`, `jti`, `nbf`, or replay-linked semantics
- Any second operator-configurable crypto-policy surface just for JARM

</deferred>

---

*Phase: 71-jarm-core*
*Context gathered: 2026-05-07*
