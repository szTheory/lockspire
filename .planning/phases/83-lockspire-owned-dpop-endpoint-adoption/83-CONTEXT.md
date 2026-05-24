# Phase 83: Lockspire-owned DPoP Endpoint Adoption - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 83 adopts the shared DPoP nonce primitive on the Lockspire-owned HTTP surfaces that already own DPoP validation today: the authorization-server `/token` surface and the Lockspire-owned protected-resource `/userinfo` surface. The goal is to make nonce challenge and retry behavior a truthful, least-surprise part of the existing DPoP contract without widening Lockspire into generic gateway middleware, new operator policy, or a broader protected-resource product.

This phase is about endpoint adoption and proof on Lockspire-owned surfaces. It does not close generated-host protected-route nonce retry proof, broad supported-surface wording, or milestone closure; those remain in Phase 84.

</domain>

<decisions>
## Implementation Decisions

### Authorization-server `/token` nonce contract

- **D-01:** Treat DPoP nonce challenge and retry as the default authorization-server contract for every Lockspire-owned `/token` DPoP path that already validates through `Lockspire.Protocol.TokenEndpointDPoP`, not as an auth-code-only special case.
- **D-02:** Covered `/token` paths for Phase 83 are:
  - authorization code
  - device code
  - CIBA token redemption
  - refresh token exchange when the stored binding or active security profile actually requires DPoP
- **D-03:** RFC 8693 token exchange is explicitly out of Phase 83 nonce-support claims until that path adopts the same DPoP validation seam.
- **D-04:** Preserve existing missing-proof behavior on `/token`: missing required DPoP proof remains `invalid_dpop_proof`; `use_dpop_nonce` is reserved for requests where a DPoP proof is present but its nonce is missing or invalid.
- **D-05:** `/token` nonce failures must stay RFC 9449-shaped:
  - HTTP `400`
  - OAuth error `use_dpop_nonce`
  - `DPoP-Nonce` response header
  - retry succeeds when the fresh proof includes the supplied authorization-server nonce and all existing DPoP checks still pass
- **D-06:** Do not fork nonce behavior by grant type. One validator seam and one transport contract are the intended least-surprise shape.

### Protected-resource `/userinfo` nonce contract

- **D-07:** `/userinfo` adopts the same protected-resource nonce contract as the shipped host Phoenix plug pipeline at the semantic level.
- **D-08:** Protected-resource nonce failures must stay RFC 9449-shaped:
  - HTTP `401`
  - `WWW-Authenticate: DPoP ... error="use_dpop_nonce"`
  - `DPoP-Nonce` response header
  - retry succeeds when the fresh proof includes the supplied resource-server nonce and all existing DPoP checks still pass
- **D-09:** Preserve existing protected-resource semantics:
  - nonce failures remain authentication retry challenges, not authorization failures
  - `401` vs `403` behavior must not drift
  - `403` remains reserved for insufficient-scope outcomes
- **D-10:** `/userinfo` and the host plug pipeline should share one protected-resource DPoP nonce rule set. Surface-local presentation details such as `realm` text may differ, but public semantics must not.
- **D-11:** `Lockspire.Protocol.ProtectedResourceDPoP` remains the single protocol seam for resource-server nonce retry outcomes across `/userinfo` now and host plug adoption later.

### Test and proof boundary

- **D-12:** Phase 83 proof should be protocol-heavy and adapter-thin.
- **D-13:** Keep exhaustive negative-path coverage where the core logic lives:
  - replay
  - `ath`
  - proof/key binding
  - nonce purpose separation
  - MTLS coexistence
  - bearer compatibility
  - wrong authorization scheme
- **D-14:** Controller tests for `/token` and `/userinfo` should prove the public wire contract that protocol tests cannot prove on their own:
  - exact `400` vs `401`
  - OAuth/WWW-Authenticate error shape
  - `DPoP-Nonce` emission
  - retry acceptance
- **D-15:** Do not duplicate the full protocol negative matrix at the controller layer unless the regression is adapter-specific.
- **D-16:** Generated-host nonce retry end-to-end proof belongs in Phase 84 milestone closure, not Phase 83.

### Architecture and DX guardrails

- **D-17:** Prefer one shared challenge-rendering rule/helper for DPoP nonce responses where that reduces drift between `/userinfo` and the host plug pipeline.
- **D-18:** Keep host responsibilities narrow. Nonce issuance, validation, typed failure reasons, and retry semantics remain Lockspire-owned protocol truth, not host-app policy.
- **D-19:** Preserve support-truth narrowness. Phase 83 implementation and tests should only claim the surfaces actually covered by the current validator seams and repo proof.
- **D-20:** Downstream GSD work for this phase should follow the project’s research-first decisive-default methodology:
  - resolve medium-value implementation, helper-shape, and test-layout decisions autonomously
  - escalate only if a choice would materially affect product boundary, public API shape, security posture, support claims, or hard-to-reverse strategic direction

### the agent's Discretion

- Exact helper names and module placement for shared DPoP challenge rendering, provided protocol ownership and public semantics remain intact.
- Exact split of protocol vs controller assertions, provided Phase 83 stays protocol-heavy and preserves one thin HTTP contract proof per owned surface.
- Whether refresh-path nonce coverage is proved at protocol level only or also with one narrow HTTP-level assertion, provided support claims remain truthful.
- Small presentation-local differences such as `realm` text, as long as they do not change status codes, error codes, nonce headers, or retry semantics.

</decisions>

<specifics>
## Specific Ideas

- Treat the `/token` recommendation as “uniform by validation seam, narrow by support truth”:
  - one authorization-server nonce contract for current Lockspire-owned DPoP token paths
  - explicit exclusion for RFC 8693 token exchange until separately adopted
- Treat the `/userinfo` recommendation as “semantic parity with presentation-local flexibility”:
  - same protected-resource retry contract as the host plug pipeline
  - no requirement for byte-for-byte identical `realm` strings
- Favor the Lockspire design lineage already established elsewhere:
  - Doorkeeper-level host DX and narrow seams
  - node-oidc-provider/OpenIddict-style protocol-core seriousness and centralized validator behavior
- Keep retry behavior browser-friendly by preserving `Access-Control-Expose-Headers` handling for `DPoP-Nonce` on nonce-challenge responses.
- Keep documentation truth narrow in implementation planning: Phase 83 closes owned-surface behavior first; broader supported-surface and generated-host proof wording remains Phase 84 work.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and methodology
- `.planning/ROADMAP.md` — Phase 83 scope split and planned proof boundaries
- `.planning/REQUIREMENTS.md` — `NONCE-AS-*`, `NONCE-RS-*`, and `NONCE-TRUTH-*` requirements
- `.planning/PROJECT.md` — embedded-library boundary, DPoP milestone thesis, and product constraints
- `.planning/STATE.md` — current milestone transition state
- `.planning/METHODOLOGY.md` — assumption-first recommendation mode, research-first decisive defaults, and high-threshold escalation

### Upstream phase context
- `.planning/phases/80-sender-constraining-integration/80-CONTEXT.md` — host plug pipeline boundary and sender-constraint composition
- `.planning/phases/82-shared-dpop-nonce-primitive/82-CONTEXT.md` — shared nonce primitive, purpose separation, and typed validator failures

### Current code seams
- `lib/lockspire/protocol/dpop.ex` — shared proof validator and nonce validation composition point
- `lib/lockspire/protocol/dpop_nonce.ex` — shared nonce issue/validate primitive
- `lib/lockspire/protocol/token_endpoint_dpop.ex` — authorization-server DPoP validation seam for `/token`
- `lib/lockspire/protocol/token_exchange.ex` — auth-code, device-code, and CIBA `/token` orchestration
- `lib/lockspire/protocol/refresh_exchange.ex` — refresh-token DPoP validation path
- `lib/lockspire/protocol/rfc8693_exchange.ex` — explicit out-of-scope `/token` exchange path for Phase 83 support claims
- `lib/lockspire/protocol/protected_resource_dpop.ex` — protected-resource DPoP validation seam for `/userinfo`
- `lib/lockspire/protocol/userinfo.ex` — Lockspire-owned protected-resource orchestration
- `lib/lockspire/web/controllers/token_controller.ex` — `/token` HTTP error and nonce-header adapter
- `lib/lockspire/web/controllers/userinfo_controller.ex` — `/userinfo` HTTP challenge and nonce-header adapter
- `lib/lockspire/plug/enforce_sender_constraints.ex` — host plug sender-constraint integration seam
- `lib/lockspire/plug/require_token.ex` — strict host plug `401`/`403` boundary and nonce-header rendering

### Proof and public contract
- `test/lockspire/protocol/token_endpoint_dpop_test.exs` — protocol-level token-endpoint nonce and DPoP proof coverage
- `test/lockspire/protocol/protected_resource_dpop_test.exs` — protocol-level protected-resource nonce and DPoP proof coverage
- `test/lockspire/web/token_controller_test.exs` — `/token` HTTP retry contract proof
- `test/lockspire/web/userinfo_controller_test.exs` — `/userinfo` HTTP challenge contract proof
- `test/lockspire/plug/enforce_sender_constraints_test.exs` — host plug sender-constraint typed-error coverage
- `test/lockspire/plug/require_token_test.exs` — host plug strict challenge rendering and nonce header proof
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` — prior generated-host protected-route proof pattern, reserved for Phase 84 nonce closure
- `docs/supported-surface.md` — canonical public support contract that later docs work must stay truthful against
- `docs/protect-phoenix-api-routes.md` — shipped host protected-route nonce contract and guide

### Prompt corpus
- `prompts/lockspire-oauth-oidc-implementation-playbook.md` — intended protocol/storage/web split and design lineage
- `prompts/lockspire-elixir-oss-library-practices.md` — explicit runtime config, child-spec, and small-public-API library ergonomics
- `prompts/lockspire-host-app-integration-seam.md` — explicit host seam boundary and protocol ownership
- `prompts/lockspire-security-posture-and-threat-model.md` — secure-by-default posture and release-blocking negative-path expectations
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — ecosystem precedent, DX lessons, and scope-discipline rationale

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.TokenEndpointDPoP`: already centralizes authorization-server DPoP proof validation, nonce failure mapping, and replay handling for owned `/token` flows.
- `Lockspire.Protocol.ProtectedResourceDPoP`: already centralizes resource-server DPoP proof validation, nonce failure mapping, `ath`, and binding checks.
- `Lockspire.Web.TokenController` and `Lockspire.Web.UserinfoController`: already expose `DPoP-Nonce` headers and perform thin transport adaptation.
- `Lockspire.Plug.EnforceSenderConstraints` plus `Lockspire.Plug.RequireToken`: already establish the intended host plug split between soft sender validation and one strict challenge boundary.

### Established Patterns

- Lockspire prefers protocol-owned validation seams with thin Phoenix/Plug adapters rather than per-endpoint reimplementation.
- Typed internal failure reasons are the standard path from protocol core to truthful public responses.
- Repo-native proof is layered:
  - protocol/unit tests for deep logic
  - controller/plug tests for HTTP contract and adapter behavior
  - targeted integration/E2E only where the support contract claims a shipped end-to-end surface

### Integration Points

- `/token` adoption should concentrate in `TokenEndpointDPoP`, with grant orchestrators inheriting the contract through existing shared paths.
- `/userinfo` adoption should concentrate in `ProtectedResourceDPoP`, with controller rendering kept thin and aligned with the host plug contract.
- Any shared nonce-challenge rendering helper should be inserted carefully so it reduces drift without collapsing authorization-server and resource-server status-code differences.

</code_context>

<deferred>
## Deferred Ideas

- RFC 8693 token-exchange DPoP nonce support
- Generated-host protected-route nonce retry end-to-end proof
- Supported-surface, route-guide, and release-truth wording updates for nonce-backed host routes
- Broader third-party issuer or generic gateway protected-resource middleware claims
- Additional operator or client policy knobs for nonce issuance cadence or enforcement mode

</deferred>

---

*Phase: 83-lockspire-owned-dpop-endpoint-adoption*
*Context gathered: 2026-05-24*
