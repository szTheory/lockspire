# Phase 57: RAR Introspection & Verification - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose the granted, normalized RAR payload to introspection callers without bloating tokens, and prove the behavior end to end across the existing host-owned consent flow. This phase is about truthful introspection behavior and executable verification, not new RAR type semantics, not a new consent-rendering framework, and not milestone-wide conformance expansion.

</domain>

<decisions>
## Implementation Decisions

### Introspection payload shape
- **D-01:** `/introspection` will return the stored **normalized granted** `authorization_details` array taken from the bound `ConsentGrant`, not raw request input and not token-embedded JSON. This preserves Phase 56's validator output as the durable truth.
- **D-02:** The default response shape is the **full normalized granted array**, not a reduced Lockspire-owned projection and not omission-by-default. This matches RFC 9396's introspection example and keeps the phase honest to `RAR-04`.
- **D-03:** Phase 57 will **not** add a new host-facing projection/configuration seam yet. Keep the public surface narrow for this phase. Implementation should still isolate formatting behind a small internal boundary so a future caller-aware filter/override can be added without reworking the core join path.
- **D-04:** Inactive introspection responses remain unchanged: return only `active: false` with no additional RAR data, consistent with RFC 7662 privacy guidance.

### Token semantics
- **D-05:** Active introspection responses for both lifecycle token types Lockspire already supports here, `:access_token` and `:refresh_token`, will include the same granted `authorization_details` payload when a `consent_grant_id` is present.
- **D-06:** The semantic guardrail is `token_type`, not divergent payload shape. For access tokens, `authorization_details` represents the resource authorization carried by the token. For refresh tokens, it represents the durable granted authorization context bound to the refresh family and reused on rotation.
- **D-07:** No new per-token-type config knob in Phase 57. Current Lockspire introspection is already client-bound and opaque-token oriented; adding policy branching now would create more surface area than value.

### Verification strategy
- **D-08:** Phase 57 verification uses the repo's established three-layer pattern:
  1. focused protocol tests for introspection shaping and grant lookup,
  2. endpoint/controller tests for HTTP behavior,
  3. one golden-path integration test proving PAR/authorize -> consent -> token issuance -> introspection.
- **D-09:** Add **narrow** regression assertions for refresh rotation and FAPI-compatible RAR usage, but do not build a new combinatorial matrix. This phase proves the new seam; it does not re-certify the milestone.
- **D-10:** Verification must explicitly prove Success Criterion 2 from ROADMAP: tokens stay compact and introspection recovers RAR by reference through `consent_grant_id`, rather than by stuffing full RAR JSON into token records or token material.

### Consent surface boundary
- **D-11:** Phase 57 requires **structural** consent-surface proof only. The host-facing consent flow must visibly receive generic RAR data in a host-consumable shape, but Lockspire does not take ownership of per-type semantic rendering or policy wording in this phase.
- **D-12:** Acceptable proof is generic display/assertion of RAR presence, type, and/or normalized summary through the existing consent path. Do not introduce a type-aware renderer registry, semantic formatter behavior, or built-in domain-specific copy in v1.14.
- **D-13:** The end-to-end proof must show that the data approved through the consent path is the same normalized granted payload later returned by introspection.

### Decisioning style for downstream agents
- **D-14:** Downstream research/planning/execution should default to **strong recommendations with sensible defaults chosen proactively**, rather than surfacing broad option sets back to the user.
- **D-15:** Only escalate questions back to the user when the decision is genuinely high-impact on product shape, security posture, or public API. Minor implementation tradeoffs should be resolved by agents in the direction of least surprise, tight boundaries, strong DX, and truthful docs/tests.

### the agent's Discretion
- Internal naming for the consent-grant lookup/helper used by introspection.
- Whether the protocol layer fetches the `ConsentGrant` directly through the token store or via a small repository helper, as long as boundaries remain clear and planning justifies the seam.
- Exact generic consent-surface assertion format for tests, provided it stays structural and host-owned.

</decisions>

<specifics>
## Specific Ideas

- The best coherent Phase 57 posture is: **full normalized granted payload by default, compact tokens by reference, no new public config knobs yet, structural consent proof only, and a single honest golden E2E plus narrow regressions**.
- Prior-art lesson to keep: successful providers expose durable grant truth and keep tokens compact; they do **not** force every deployment into one opinionated consent UI model.
- Prior-art footgun to avoid: adding a projection/filter knob before the base behavior is proven tends to widen public surface and produce inconsistent operator behavior across hosts.
- Prior-art footgun to avoid: treating RAR support as “stored somewhere” without proving that the host consent path and introspection path can actually consume the data.
- User workflow preference for GSD: recommendation-heavy guidance should be shifted left. Prefer coherent defaults and one strong proposed path unless a tradeoff is materially consequential.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Specs / standards
- `RFC 9396` §9.2, §11.1, §11.2 — introspection example, deployment-specific shaping allowance, and minimal implementation guidance.
- `RFC 7662` §2.2 and §5 — introspection response extensibility and privacy/minimization guidance.

### Lockspire planning artifacts
- `.planning/ROADMAP.md` §"Phase 57: RAR Introspection & Verification" — goal and success criteria for this phase.
- `.planning/REQUIREMENTS.md` — `RAR-04`, `V-01`, and `V-02`.
- `.planning/PROJECT.md` — embedded-library shape, host-owned UI/policy seam, secure-by-default posture.
- `.planning/STATE.md` — current milestone position and phase focus.
- `.planning/phases/56-rar-domain-validation-storage/56-CONTEXT.md` — storage, normalization, fingerprinting, and consent-grant linkage already locked by the previous phase.

### Lockspire codebase
- `lib/lockspire/protocol/introspection.ex` — current active/inactive response shaping and caller model.
- `lib/lockspire/protocol/authorization_flow.ex` — interaction/consent/grant threading and `authorization_details` persistence.
- `lib/lockspire/protocol/refresh_exchange.ex` — refresh-family propagation path.
- `lib/lockspire/protocol/authorization_request.ex` — normalized RAR validation entrypoint from prior phases.
- `test/lockspire/protocol/introspection_test.exs` — protocol-level introspection coverage to extend.
- `test/lockspire/web/introspection_controller_test.exs` — endpoint-level introspection coverage to extend.
- `test/integration/phase56_rar_validation_storage_e2e_test.exs` — reusable RAR gold-path fixture and proof base for this phase.
- `test/integration/phase43_fapi_milestone_e2e_test.exs` — existing FAPI proof to keep Phase 57 regressions narrow against.
- `lib/lockspire/web/live/consent_live.ex` and `test/lockspire/web/live/consent_live_test.exs` — current consent-surface boundary and generic host-facing assertions.
- `docs/install-and-onboard.md` and `docs/ecosystem-overview.md` — host-owned interaction/consent seam contract.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Protocol.Introspection` already has a compact response formatter and inactive-response privacy behavior; Phase 57 extends this rather than introducing a parallel endpoint path.
- `ConsentGrant.authorization_details` and `Token.consent_grant_id` already provide the durable join target established in Phase 56.
- `RefreshExchange` already preserves `consent_grant_id` across rotation, which makes refresh-token introspection recoverable without token bloat.
- `phase56_rar_validation_storage_e2e_test.exs` already proves normalized RAR persistence from PAR through grant issuance and rotation; Phase 57 should build on this instead of creating a brand-new fixture universe.

### Established Patterns
- Lockspire prefers narrow protocol modules with explicit branching over wide configuration surfaces.
- The repo's test shape is layered: protocol tests for core logic, `ConnTest` coverage for endpoint truth, and milestone/phase E2E tests for executable proof.
- Host-owned UX seams stay generic and generated; Lockspire avoids owning product semantics when the host app should control them.

### Integration Points
- Introspection needs a grant lookup path from the active token record to the consent grant's normalized `authorization_details`.
- The golden E2E should reuse existing PAR/authorize/consent/token helpers and end by calling `/introspect`.
- Consent proof should attach to the existing generic consent path, not a new RAR-specialized UI framework.

</code_context>

<deferred>
## Deferred Ideas

- Host-facing introspection projection/filter seam for caller-aware RAR shaping.
- Per-introspecting-client or per-resource-server RAR filtering policy.
- Semantic/type-aware consent rendering hooks or generator-backed RAR consent presenters.
- Broader FAPI/RAR combinatorial test matrix and certification-style hardening.
- Discovery/docs/public API work for RAR metadata and custom consent guidance belongs to Phase 58.

</deferred>

---

*Phase: 57-rar-introspection-and-verification*
*Context gathered: 2026-05-06*
