# Phase 34: Token Issuance and Refresh/Device Binding - Context

**Gathered:** 2026-04-28 (assumptions mode + advisor research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Thread DPoP through Lockspire's existing `/token` grant paths so authorization-code exchange,
refresh-token rotation, and device-code redemption can issue and rotate DPoP-bound tokens
truthfully without breaking the bearer-default posture or widening the host-owned verification
seam.

After this phase: DPoP for public and CLI-oriented clients behaves like an additive,
policy-controlled extension of the shared token pipeline rather than a parallel token subsystem.
Bearer clients remain unchanged by default; DPoP-mode clients get durable binding truth, shared
refresh semantics, and truthful token responses.

**Explicitly out of scope this phase:**
- `userinfo`-side DPoP consumption and owned protected-resource enforcement (Phase 35)
- Discovery/DCR/admin surface truth for DPoP configuration (Phase 35)
- End-to-end milestone proof, introspection truth, and milestone closure work (Phase 36)
- Separate host-app protected-resource middleware or any widening of the embedded-library shape
- Custom provider-specific public error families beyond RFC-shaped OAuth/DPoP behavior
</domain>

<decisions>
## Implementation Decisions

### Durable Binding State

- **D-01:** Persist DPoP binding as durable `cnf.jkt` state on **both** access tokens and refresh
  tokens for DPoP-bound flows. Treat that binding as token-family truth, not as a response-only
  flag or an access-token-only detail.
- **D-02:** Do **not** add a separate DPoP binding table or sidecar binding record in Phase 34.
  The existing `Token.cnf` seam is the canonical binding carrier for this milestone.
- **D-03:** Do **not** rely on transient proof context or indirect reconstruction for binding
  semantics. Phase 34 must keep DPoP truth durable across nodes, restarts, audits, and later
  owned-surface validation work.
- **D-04:** Device flow binds the DPoP key at the winning `/token` redemption request, not during
  the host-owned `/verify` approval seam. This preserves the existing host boundary.

### Enforcement Topology

- **D-05:** Keep Phoenix/Plug delivery adapters thin. The controller should gather HTTP request
  context and pass it inward; it should not become the primary owner of DPoP policy or binding
  semantics.
- **D-06:** Centralize effective DPoP policy resolution, proof validation/preflight, replay-use
  recording, `token_type` selection, and `cnf` construction in protocol-owned token-endpoint code.
- **D-07:** Grant-specific rules may differ only where the prior artifact differs:
  - authorization-code exchange decides whether DPoP is required for this client/policy and issues
    bound tokens when present
  - refresh-token exchange must compare the presented proof key to the stored refresh-token binding
  - device-code exchange should reuse the same issuance path after polling resolves approval
- **D-08:** Repository/storage code remains the owner of durable compare-and-write behavior,
  especially refresh-family rotation/reuse and atomic persistence checks, but it is **not** the
  primary owner of HTTP proof parsing or effective policy decisions.

### Shared Issuance Pipeline

- **D-09:** Thread DPoP through the existing shared issuance pipeline rather than creating
  DPoP-specific exchange modules per grant. Preserve one token lifecycle model for bearer and DPoP.
- **D-10:** Use a small internal issuance context object for shared builders/persistence instead of
  sprinkling ad hoc `if dpop` booleans through multiple grant branches.
- **D-11:** Shared access-token builders should persist `cnf` and return the truthful public
  token-type result for DPoP-mode exchanges without forking the broader token success contract.
- **D-12:** Refresh rotation stays one family-wide mechanism. For DPoP-bound public and
  CLI-oriented clients, the presented refresh token must be redeemed only when the proof is bound
  to the expected key, and rotated child tokens must carry the same binding forward.
- **D-13:** Do not store DPoP binding in device-authorization approval state or invent a
  device-specific DPoP issuance path. Device flow remains "another route into the same durable
  token system."

### Public Contract and Error Semantics

- **D-14:** Successful DPoP-bound token responses must return `token_type: "DPoP"`. Bearer-mode
  clients remain `token_type: "Bearer"` and otherwise unchanged.
- **D-15:** Reserve public `invalid_dpop_proof` for proof-object and proof-presentation failures:
  missing proof when required, malformed proof, bad signature, invalid `htm`, invalid `htu`,
  stale/future proof, missing required claims, or replayed proof.
- **D-16:** When a refresh token is itself invalid for the presented proof key, collapse that
  public result to `invalid_grant` while preserving private/internal reason codes for telemetry,
  auditability, and support diagnosis.
- **D-17:** Do **not** keep `token_type: "Bearer"` for DPoP-bound access tokens as a compatibility
  shortcut in this phase. That would make the preview support contract less truthful.
- **D-18:** Do **not** introduce custom provider-specific DPoP public errors in Phase 34. Keep the
  public contract standards-shaped and keep fine-grained diagnostics private.

### Workflow Preference

- **D-19:** Downstream GSD agents should choose the most coherent recommendation and proceed for
  low- and medium-impact implementation details by default. Escalate only for genuinely
  high-impact product-boundary, protocol-truth, or support-contract decisions.
- **D-20:** The preference in D-19 applies to this phase and similar subsequent phases unless a
  decision would materially widen Lockspire's public surface, alter security posture, or create
  long-lived support obligations.

### the agent's Discretion

- Exact shape/name of the internal DPoP issuance context may be chosen during planning if it keeps
  the pipeline coherent and testable.
- Exact repository API boundaries for atomic refresh binding checks may be chosen during planning
  as long as storage remains a persistence seam rather than a second protocol engine.
- Exact private reason-code vocabulary for refresh binding mismatch may be chosen during planning
  if the public contract remains `invalid_grant`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and carry-forward constraints

- `.planning/ROADMAP.md` — Phase 34 goal, dependency on Phase 33, and success criteria for auth
  code, refresh, device, and truthful DPoP token responses
- `.planning/REQUIREMENTS.md` — DPoP-05, DPoP-06, DPoP-07, DPoP-08
- `.planning/PROJECT.md` — embedded-library shape, truthful preview posture, durable-storage bias,
  and narrow host seam
- `.planning/STATE.md` — already-locked v1.7 milestone decisions and the current Phase 34 focus

### Prior phase decisions that constrain this phase

- `.planning/phases/32-polling-token-issuance/32-CONTEXT.md` — device flow must remain a
  first-class route into the shared token machinery, not a side path
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-01-SUMMARY.md` — proof validator
  and thumbprint output ready for Phase 34 consumption
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-02-SUMMARY.md` — replay-state
  preflight seam and explicit note that binding/`token_type` work belongs in Phase 34
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-03-SUMMARY.md` — explicit
  durable policy state and effective bearer-vs-DPoP resolution
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-RESEARCH.md` — prior DPoP
  research, RFC grounding, and carry-forward token-binding guidance
- `.planning/phases/33-dpop-proof-validation-and-replay-state/33-PATTERNS.md` — existing `cnf`
  persistence seam and pattern guidance against inventing a separate binding store

### Existing implementation surface to extend

- `lib/lockspire/web/controllers/token_controller.ex` — thin `/token` adapter precedent
- `lib/lockspire/web/controllers/token_json.ex` — canonical token success/error JSON surface
- `lib/lockspire/protocol/token_exchange.ex` — shared token exchange routing, auth-code/device
  issuance, DPoP preflight seam, and success/error shaping
- `lib/lockspire/protocol/refresh_exchange.ex` — refresh rotation and family-wide revocation logic
- `lib/lockspire/protocol/dpop.ex` — validated proof shape, `jkt`, JOSE verification, claim checks
- `lib/lockspire/protocol/dpop_policy.ex` — effective DPoP policy resolution
- `lib/lockspire/domain/token.ex` — durable `cnf` carrier and token-family fields
- `lib/lockspire/storage/ecto/token_record.ex` — Ecto persistence for `cnf`
- `lib/lockspire/storage/ecto/repository.ex` — token redemption, refresh rotation, and transaction
  patterns

### Existing proofs to preserve and extend

- `test/lockspire/protocol/token_exchange_test.exs` — auth-code + device token-path proof and
  existing DPoP preflight tests
- `test/lockspire/protocol/refresh_exchange_test.exs` — refresh rotation/reuse proof to extend for
  DPoP binding semantics
- `test/lockspire/web/token_controller_test.exs` — HTTP contract truth for `/token`
- `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` — existing device flow
  end-to-end proof and host seam constraints
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.DPoP` already returns validated proofs plus the computed `jkt`, which is the
  natural input into Phase 34 binding state.
- `Lockspire.Protocol.DpopPolicy` already resolves bearer-vs-DPoP mode explicitly, which means
  Phase 34 should consume policy rather than invent another enablement switch.
- `Lockspire.Domain.Token` and `Lockspire.Storage.Ecto.TokenRecord` already persist `cnf`, so the
  codebase has a durable binding carrier without needing new token-side storage concepts.
- `TokenExchange` already converges authorization-code and device-code issuance through shared token
  builders; `RefreshExchange` already owns family-wide refresh lifecycle semantics.

### Established Patterns

- Thin Phoenix/Plug adapters with protocol modules owning correctness.
- Durable Postgres/Ecto truth over process-local or transport-only state.
- Shared token lifecycle behavior across grant types rather than separate issuance stacks.
- Standards-shaped public contracts with richer internal reason codes and audit/telemetry details.

### Integration Points

- `TokenController` should pass enough HTTP context for protocol-owned DPoP evaluation but remain
  thin.
- `TokenExchange` is the right choke point for auth-code and device-code DPoP issuance semantics.
- `RefreshExchange` is the right protocol-owned place to compare presented proof binding against the
  stored refresh token, while repository transactions preserve atomicity.
- `TokenJSON` and token success structs must become truthful for DPoP without changing bearer-mode
  clients.
</code_context>

<specifics>
## Specific Ideas

- Emulate the shape used by successful provider libraries and servers: thin adapters, central token
  endpoint logic, and shared token context rather than per-grant DPoP issuers. OpenIddict, Spring
  Authorization Server, and `oidc-provider` are the architectural direction to learn from here.
- Learn from mature systems that keep sender-constrained refresh semantics durable for public/CLI
  clients but avoid widening that into overbuilt sidecar state or proprietary public errors.
- Key footguns to avoid:
  - access-token-only binding truth that leaves refresh semantics implicit
  - controller/Plug-owned DPoP policy that couples correctness to mount order or transport shape
  - per-grant DPoP branches that drift on `token_type`, `cnf`, audit, or refresh reuse behavior
  - compatibility shortcuts that keep DPoP-bound access tokens publicly labeled as bearer
- User preference locked for downstream GSD work:
  - prefer coherent decisive defaults
  - escalate only very high-impact product, protocol, or support-surface calls
</specifics>

<deferred>
## Deferred Ideas

- Separate DPoP binding tables or key-history models beyond `Token.cnf` — out of scope for this
  milestone slice
- Compatibility modes that bind only refresh tokens while keeping access-token responses publicly
  `Bearer` — deferred unless real adopter pressure proves they are necessary
- Custom provider-specific DPoP public error taxonomy — rejected for v1.7
- Generic host-app protected-resource middleware for DPoP validation outside Lockspire-owned
  endpoints — explicitly deferred to future sender-constrained depth
- Formalizing the "shift low/medium-impact choices left" preference into broader GSD defaults or
  user profile/config outside this phase's context work
</deferred>

---

*Phase: 34-token-issuance-and-refresh-device-binding*
*Context gathered: 2026-04-28*
