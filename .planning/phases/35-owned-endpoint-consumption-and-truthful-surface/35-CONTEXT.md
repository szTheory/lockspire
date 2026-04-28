# Phase 35: Owned Endpoint Consumption and Truthful Surface - Context

**Gathered:** 2026-04-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the Lockspire-owned protected-resource and support surfaces agree with the shipped DPoP
slice by adding DPoP-aware `userinfo` enforcement, truthful discovery/support-surface claims,
and explicit operator/DCR client-token-mode configuration without widening beyond Lockspire-owned
endpoints and policy seams.

After this phase: DPoP-bound access tokens are consumable on the Lockspire-owned `userinfo`
surface only when accompanied by a valid proof bound to the token's durable `cnf` state;
discovery and docs advertise exactly the repo-proven DPoP surface and no more; and both
operators and dynamic registration clients can place a client into bearer or DPoP mode without
repo-internal edits.

**Explicitly out of scope this phase:**
- Generic host-app protected-resource middleware or helper plugs for DPoP validation outside
  Lockspire-owned endpoints
- Nonce support or other deeper DPoP ecosystem breadth not already in the current milestone
- End-to-end auth-code/device DPoP scenario proof, introspection truth, and milestone closure
  work (Phase 36)
- Broader sender-constrained abstractions or a combined "all token policies" operator console
  beyond the narrow DPoP slice
</domain>

<decisions>
## Implementation Decisions

### Userinfo Authentication Contract

- **D-01:** `userinfo` must support both bearer and DPoP access, but any access token with durable
  DPoP binding state in `Token.cnf` is accepted only through the DPoP authentication scheme:
  `Authorization: DPoP <access_token>` plus a `DPoP` proof header.
- **D-02:** A DPoP-bound access token presented as `Authorization: Bearer ...` must be rejected
  rather than silently downgraded to bearer behavior on Lockspire-owned endpoints.
- **D-03:** Bearer-mode access tokens remain supported on `userinfo` exactly as they work today so
  existing clients stay unchanged unless they explicitly opt into DPoP mode.
- **D-04:** `userinfo` remains a Lockspire-owned protected-resource surface only. Do not broaden
  Phase 35 into generic host-resource validation helpers.

### DPoP Validation Topology

- **D-05:** Reuse the existing protocol-owned DPoP validation model for `userinfo` rather than
  inventing a controller-local or endpoint-specific proof parser. The controller should stay a
  thin adapter.
- **D-06:** `userinfo` DPoP validation must check the same protocol fundamentals already enforced
  on `/token`: signed proof, `typ`, acceptable `alg`, `htm`, canonicalized `htu`, freshness, and
  replay recording via the durable replay store.
- **D-07:** Because `userinfo` is a protected-resource request, the DPoP proof must also require
  and validate `ath` against the presented access token value, in addition to matching the proof
  key to the token's stored `cnf.jkt`.
- **D-08:** The `userinfo` implementation should resolve token mode from durable token state
  (`Token.cnf`) and enforce the proof requirement there, not from mutable client policy lookups
  alone.

### Discovery and Support-Surface Truth

- **D-09:** Discovery should advertise only the shipped DPoP slice and only once the repo-owned
  endpoint surface supports it: DPoP token requests plus Lockspire-owned `userinfo` consumption.
- **D-10:** Discovery metadata should add `dpop_signing_alg_values_supported`, sourced from the
  actual DPoP validator allowlist rather than a hand-maintained docs-only list.
- **D-11:** Docs and support-surface copy must stay explicit that Lockspire proves DPoP only on
  the endpoints it owns in-repo; generic host protected-resource middleware remains out of scope.
- **D-12:** Release/support contract tests should remain the enforcement backstop for DPoP claims
  so public wording cannot drift ahead of repo proof.

### Operator and DCR Configuration

- **D-13:** Preserve the existing durable enum model for DPoP policy:
  server policy stays `:bearer | :dpop`, client policy stays `:inherit | :bearer | :dpop`. Do not
  move DPoP mode into arbitrary metadata blobs.
- **D-14:** The operator surface should mirror the existing PAR pattern: a narrow global DPoP
  policy page plus a client-level override workflow, rather than a broader "sender-constrained
  tokens" control plane.
- **D-15:** Dynamic Client Registration should expose DPoP through RFC 9449
  `dpop_bound_access_tokens` metadata and map it into explicit durable client policy.
- **D-16:** For DCR clients, `dpop_bound_access_tokens: true` persists client policy `:dpop`;
  `false` or omission persists explicit `:bearer` for that self-registered client instead of
  leaving the client on `:inherit`.
- **D-17:** Admin and DCR paths must be able to switch clients between bearer and DPoP mode
  without repo-internal edits, but rollout remains explicit and narrow rather than silently
  changing existing operator-managed bearer clients.

### Public Error and Challenge Semantics

- **D-18:** `userinfo` should return standards-shaped authentication failures rather than inventing
  provider-specific DPoP errors for this phase.
- **D-19:** When authentication is missing, malformed, or mismatched for a DPoP-bound token,
  `userinfo` should challenge in a way that reflects DPoP capability and acceptable algorithms,
  while keeping bearer-mode failures truthful for bearer clients.

### the agent's Discretion

- Exact internal module/file shape for shared protected-resource DPoP validation may be chosen
  during planning as long as protocol logic stays centralized and controllers stay thin.
- Exact split between shared helper functions and `userinfo`-specific orchestration may be chosen
  during planning if it avoids duplicating token-endpoint DPoP logic.
- Exact wording of docs/test assertions may evolve during planning so long as the support contract
  remains narrow and repo-truthful.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements

- `.planning/ROADMAP.md` — Phase 35 goal, dependencies, and success criteria for owned-surface
  DPoP consumption, discovery truth, and admin/DCR configuration
- `.planning/REQUIREMENTS.md` — DPoP-09, DPoP-10, DPoP-11
- `.planning/PROJECT.md` — embedded-library boundaries, truthful preview posture, and narrow host
  seam
- `.planning/STATE.md` — accumulated v1.7 DPoP decisions through Phase 34

### Prior phase decisions that constrain this phase

- `.planning/phases/26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co/26-CONTEXT.md`
  — DCR truth pattern, operator/DCR ownership boundaries, and standards-shaped registration
  semantics
- `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md` — durable `cnf`
  binding decisions, truthful `token_type: "DPoP"`, and the explicit deferral of owned-surface
  consumption/discovery/admin truth to Phase 35

### Existing implementation surface to extend

- `lib/lockspire/protocol/userinfo.ex` — current bearer-only userinfo protocol seam
- `lib/lockspire/web/controllers/userinfo_controller.ex` — thin `userinfo` delivery adapter to
  preserve
- `lib/lockspire/protocol/dpop.ex` — canonical proof decoding/validation and allowed signing
  algorithms
- `lib/lockspire/protocol/token_endpoint_dpop.ex` — shared DPoP context, replay use recording,
  canonical URI handling, and existing proof-validation topology
- `lib/lockspire/protocol/discovery.ex` — truth-based discovery builder
- `lib/lockspire/web/controllers/discovery_controller.ex` — thin discovery adapter
- `lib/lockspire/protocol/registration.ex` — DCR metadata intake seam to extend for
  `dpop_bound_access_tokens`
- `lib/lockspire/protocol/registration_management.ex` — DCR update/read path to keep aligned with
  client policy truth
- `lib/lockspire/admin/clients.ex` — durable client update validation and mutable `dpop_policy`
  seam
- `lib/lockspire/admin/server_policy.ex` — durable global DPoP policy seam
- `lib/lockspire/domain/token.ex` — durable `cnf` binding carrier for access tokens
- `lib/lockspire/domain/client.ex` — durable client DPoP policy enum
- `lib/lockspire/domain/server_policy.ex` — durable server DPoP policy enum

### Existing tests and docs to preserve/extend

- `test/lockspire/web/userinfo_controller_test.exs` — current userinfo HTTP contract
- `test/lockspire/web/discovery_controller_test.exs` — discovery metadata truth assertions
- `test/lockspire/release_readiness_contract_test.exs` — public support/docs contract backstop
- `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` — current DPoP device proof
  and truthful `token_type` precedent
- `lib/lockspire/web/live/admin/policies_live/par.ex` — narrow global policy UX precedent
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` — client override workflow
  precedent
- `lib/lockspire/web/live/admin/clients_live/show.ex` — client detail/edit route precedent
- `test/lockspire/web/live/admin/policies_live/par_test.exs` — global policy page test precedent
- `test/lockspire/web/live/admin/clients_live_test.exs` — client override/edit workflow test
  precedent
- `docs/supported-surface.md` — canonical preview support contract

### Specification authority

- `RFC 9449` — DPoP authorization-server metadata (`dpop_signing_alg_values_supported`), client
  metadata (`dpop_bound_access_tokens`), and protected-resource DPoP validation requirements

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.DPoP` already owns JOSE validation, thumbprints, URI normalization, and the
  allowed DPoP signing algorithm set.
- `Lockspire.Protocol.TokenEndpointDPoP` already centralizes proof enforcement, replay use
  recording, canonical endpoint URI construction, and DPoP/bearer issuance context.
- `Lockspire.Domain.Token.cnf` already persists the durable `jkt` binding needed for `userinfo`
  protected-resource checks.
- `Lockspire.Admin.Clients` and `Lockspire.Admin.ServerPolicy` already validate and persist DPoP
  policy enums, so admin/DCR work can extend existing seams rather than invent new storage.
- The LiveView admin surface already has a narrow policy-editing pattern for PAR that can be
  mirrored for DPoP with less UI drift.

### Established Patterns

- Thin Phoenix/Plug adapters over protocol-owned correctness.
- Durable Ecto/Postgres truth over transport-only or process-local state.
- Standards-shaped public contracts and challenge/error behavior with richer internal reason codes.
- Truth-based discovery/docs guarded by release-contract tests.
- Narrow operator workflows that expose one concrete policy surface at a time rather than a broad
  generalized control plane.

### Integration Points

- `userinfo_controller.ex` should collect auth headers and pass them to protocol code, but should
  not become the primary owner of DPoP validation.
- `userinfo.ex` is the natural protocol seam to evolve from bearer-only lookup into token-mode
  aware protected-resource enforcement.
- `discovery.ex` should publish DPoP metadata from real mounted behavior and validator truth.
- `registration.ex` and `registration_management.ex` are the DCR seams that need to understand
  `dpop_bound_access_tokens` and preserve alignment with `Client.dpop_policy`.
- LiveView admin routes under `/admin/policies/*` and `/admin/clients/*` are the established UX
  slots for global and per-client DPoP controls.
</code_context>

<specifics>
## Specific Ideas

- Treat Lockspire-owned `userinfo` as a real protected resource for DPoP purposes, not as a
  bearer-only exception to the sender-constrained model.
- Prefer reusing the token-endpoint DPoP machinery where possible, but adapt it for protected
  resource semantics by requiring `ath` and validating against the presented access token value.
- Keep the operator experience intentionally parallel to PAR: one global DPoP policy page and one
  client override flow are enough for this slice.
- For DCR, use RFC-native `dpop_bound_access_tokens` rather than Lockspire-specific metadata so
  the phase stays truthful to the public surface it is adding.
</specifics>

<deferred>
## Deferred Ideas

- Generic host-app protected-resource middleware or helper plugs for DPoP-bound token validation
- DPoP nonce support
- Broader sender-constrained or "token security posture" admin consolidation
- Compatibility modes that tolerate DPoP-bound access tokens over bearer auth on Lockspire-owned
  endpoints
- Protected-resource metadata publication beyond the current discovery/support contract

None — analysis stayed within phase scope.
</deferred>

---

*Phase: 35-owned-endpoint-consumption-and-truthful-surface*
*Context gathered: 2026-04-28*
