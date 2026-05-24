# Phase 82: Shared DPoP Nonce Primitive - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 82 adds one shared DPoP nonce primitive and the narrow validator seam that later token-endpoint, userinfo, and host-plug flows can consume. The goal is to introduce nonce issuance and proof validation once, with explicit authorization-server vs resource-server separation, without widening Lockspire into a generic nonce service, replay product, or operator-managed policy surface.

This phase stops at the primitive and typed protocol outcomes. It does not close the public HTTP retry contract on `/token`, `/userinfo`, or the shipped host plug pipeline; those are handled in later phases.

</domain>

<decisions>
## Implementation Decisions

### Shared primitive shape

- **D-01:** Add one protocol-owned nonce primitive module rather than separate token-endpoint and resource-endpoint nonce implementations.
- **D-02:** Keep the primitive stateless and host-local by deriving/verifying nonce values from `secret_key_base`; do not add a database table, ETS cache, or operator-managed nonce store in v1.22.
- **D-03:** Model nonce issuance with explicit purpose separation:
  - `:authorization_server`
  - `:resource_server`
- **D-04:** Purpose separation must be encoded into the nonce payload itself so a nonce minted for one surface class is never accepted by the other.
- **D-05:** Nonce values must remain unpredictable and self-contained so downstream flows can issue retry nonces without a new persistence dependency.

### Validator integration

- **D-06:** `Lockspire.Protocol.DPoP.validate_proof/2` remains the single proof-validation seam; nonce checking should compose into that existing pipeline rather than creating a second proof validator.
- **D-07:** Nonce enforcement stays opt-in per caller via explicit validation options; bearer and legacy DPoP paths that do not request nonce validation should remain unchanged.
- **D-08:** The validator should expose typed internal failure reasons for nonce problems:
  - `:missing_dpop_nonce`
  - `:invalid_dpop_nonce`
- **D-09:** Missing nonce and invalid/stale/wrong-purpose nonce collapse to separate typed internal reasons, not ad hoc strings or endpoint-specific tuples.
- **D-10:** Nonce max-age should stay caller-configurable through validation opts so authorization-server and resource-server callers can share the same primitive without new global policy.

### Product and support boundary

- **D-11:** Phase 82 must not add new admin controls, DCR metadata, discovery metadata, or host configuration knobs for nonce behavior.
- **D-12:** Phase 82 must not widen into protected-resource HTTP challenge rendering, generated-host route proof, or support-truth docs beyond what is strictly required to wire the primitive into the validator seam.
- **D-13:** Keep all nonce work redaction-safe:
  - no logging of raw nonce values
  - no full proof dumps
  - no secret-key material leakage through errors

### Deferred to later phases

- **D-14:** Mapping nonce failures to `/token` `400 use_dpop_nonce` responses is a downstream adoption concern, not the core primitive itself.
- **D-15:** Mapping nonce failures to `/userinfo` and host-plug `401` DPoP challenges is a downstream adoption concern, not the core primitive itself.
- **D-16:** End-to-end proof across generated-host route protection belongs in later milestone phases after the primitive is stable.

### the agent's Discretion

- Exact signed payload shape inside the nonce token, provided purpose separation and unpredictability are preserved.
- Exact helper names and internal function boundaries between `DPoPNonce` and `DPoP`.
- Exact test split between dedicated nonce tests and proof-validator regression coverage.

</decisions>

<specifics>
## Specific Ideas

- Keep the primitive parallel to other Lockspire protocol helpers: one narrow module with explicit issue/validate entrypoints and no transport concerns.
- Reuse the existing DPoP validation call graph so later token and protected-resource code only needs to pass `nonce_purpose:` plus `secret_key_base`.
- Bias Phase 82 test proof toward unit and protocol tests, not controller/browser proof.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope
- `.planning/ROADMAP.md` — Phase 82 goal and current plan split
- `.planning/REQUIREMENTS.md` — `NONCE-CORE-*`, `NONCE-AS-*`, and `NONCE-RS-*` requirements
- `.planning/PROJECT.md` — embedded-library boundary and v1.22 milestone thesis
- `.planning/STATE.md` — current milestone status

### Upstream DPoP and sender-constraint work
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-RESEARCH.md` — original shared DPoP validator seam
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-01-PLAN.md` — proof-validator plan shape and typed failure precedent
- `.planning/phases/80-sender-constraining-integration/80-CONTEXT.md` — protected-resource pipeline boundary and sender-constraint composition

### Current code seams
- `lib/lockspire/protocol/dpop.ex` — shared proof validator where nonce checks should compose
- `lib/lockspire/protocol/token_endpoint_dpop.ex` — token-endpoint DPoP validation consumer
- `lib/lockspire/protocol/protected_resource_dpop.ex` — protected-resource DPoP validation consumer
- `lib/lockspire/protocol/token_exchange.ex` — token pipeline integration point
- `lib/lockspire/protocol/userinfo.ex` — Lockspire-owned protected-resource consumer
- `lib/lockspire/web/controllers/token_controller.ex` — `/token` error/header adapter
- `lib/lockspire/web/controllers/userinfo_controller.ex` — `/userinfo` challenge/header adapter

### Current proof files
- `test/lockspire/protocol/dpop_test.exs` — shared validator proof
- `test/lockspire/protocol/token_endpoint_dpop_test.exs` — token-endpoint DPoP protocol proof
- `test/lockspire/protocol/protected_resource_dpop_test.exs` — protected-resource DPoP protocol proof
- `test/lockspire/web/token_controller_test.exs` — `/token` transport proof
- `test/lockspire/web/userinfo_controller_test.exs` — `/userinfo` transport proof

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.DPoP` already owns the canonical proof decode, JOSE verification, `htm`/`htu`/`iat`/`jti` checks, and typed failure results.
- Token-endpoint and protected-resource DPoP flows already adapt typed validator failures into endpoint-specific OAuth/DPoP errors.
- `secret_key_base` is already a known host seam on Lockspire-owned HTTP surfaces, making it the natural signing root for a stateless nonce primitive.

### Established Patterns

- Lockspire prefers one protocol core module plus thin adapters over per-endpoint reimplementation.
- Internal failure reasons are typed atoms that later callers map into truthful public responses.
- Later plans should preserve exact-match, narrow-surface, no-new-policy defaults.

### Integration Points

- Phase 82 planning should center on:
  - `DPoPNonce` issue/validate helpers
  - `DPoP.validate_proof/2` nonce opt-in
  - typed nonce failure propagation
  - protocol-level proof that purpose separation works

</code_context>

<deferred>
## Deferred Ideas

- Durable nonce storage or replay-aware nonce registries
- Admin/operator policy knobs for enabling or tuning nonce support
- Discovery metadata changes beyond later truthful-surface work
- Generated-host end-to-end nonce retry proof
- Broader protected-resource or generic gateway nonce middleware claims

</deferred>
