# Phase 32: Polling & Token Issuance - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Finish the OAuth 2.0 Device Authorization Grant polling path on Lockspire's existing `/token`
endpoint so devices can poll with
`grant_type=urn:ietf:params:oauth:grant-type:device_code`, receive standards-shaped pending and
terminal errors, and get the normal Lockspire token response once the Phase 31 host-owned
verification seam marks the device authorization approved.

After this phase: device flow behaves like another first-class route into Lockspire's durable token
system rather than a one-off side path. The host-owned `/verify` seam remains unchanged; this phase
only finishes the device-side polling and issuance contract.

**Explicitly out of scope this phase:**
- Lockspire-owned verification UI or any widening of the Phase 31 host seam
- Built-in host-side `/token` gateway/rate-limiter product surface beyond normal protocol behavior
- New grant families or broader CIAM capabilities outside RFC 8628 polling
- Device-flow-specific bespoke public error names or nonstandard token response shapes

Requirements covered by this phase: **DEV-07, DEV-08, DEV-09**.
</domain>

<decisions>
## Implementation Decisions

### Token Endpoint Topology

- **D-01:** Phase 32 extends the existing `/token` endpoint and `Lockspire.Protocol.TokenExchange`
  surface rather than introducing a separate device-only controller or a parallel issuance stack.
- **D-02:** Device polling should feel like "a different grant validator feeding the same durable
  token machinery" already used by authorization code and refresh-token exchange, not like a
  second-class token contract.
- **D-03:** Planner should prefer extracting shared issuance helpers where useful, but preserve the
  existing thin-controller pattern: Plug/Phoenix adapters stay small, while protocol/storage layers
  own grant semantics, race-safety, and issuance rules.

### Polling Policy and Backpressure

- **D-04:** Lockspire should use a standards-shaped base polling interval of **5 seconds** for
  device flow and return that value from `/device/code` as `interval`.
- **D-05:** Lockspire should enforce `slow_down` as a **durable per-device-code sticky interval
  increase of +5 seconds for each too-early poll**, matching RFC 8628 semantics rather than
  inventing exponential or opaque punishment rules.
- **D-06:** Backpressure truth belongs to the durable device-authorization record in Postgres/Ecto,
  not to in-memory state or a Plug-only heuristic. The working target is to store enough polling
  state to evaluate "too early" atomically across nodes and deploys.
- **D-07:** The likely durable shape is a per-record next-allowed-poll timestamp plus the effective
  interval seconds (or an equivalent representation). Planner may choose exact field names, but the
  semantics are locked.
- **D-08:** On an early poll, Lockspire should atomically advance the allowed poll window and return
  `slow_down`. On a compliant poll for a still-pending request, it should return
  `authorization_pending`.
- **D-09:** Any coarse outer `/token` rate limiting by client/IP is **defense in depth only** and
  remains outside protocol truth. Lockspire may document or emit telemetry that helps hosts add it,
  but Phase 32 should not make it the primary enforcement mechanism.
- **D-10:** If Lockspire includes an `interval` field on `slow_down` responses, treat it as a small
  documented compatibility/DX extension rather than a new public error model.

### Success Response Shape

- **D-11:** A successful device-flow poll should reuse Lockspire's normal token response shape:
  `access_token`, `token_type`, `expires_in`, `scope`, plus optional `refresh_token`, plus
  optional `id_token` when `openid` was approved and the request qualifies as OIDC.
- **D-12:** Device flow is a first-class OAuth/OIDC grant in Lockspire, not an OAuth-only carveout.
  Do **not** intentionally omit `id_token` when `openid` is in scope.
- **D-13:** Refresh-token issuance should stay governed by the same policy posture already used in
  Lockspire: issue refresh tokens only when client policy and approved scopes allow it. Device-flow
  success alone must not imply refresh-token issuance.
- **D-14:** Planner should maximize reuse of the existing token JSON contract, access-token issuance,
  refresh rotation, and signing-key/claims resolution machinery instead of cloning a separate device
  issuance pipeline.
- **D-15:** Device-flow approval state must preserve enough durable context for correct post-approval
  issuance. At minimum, downstream work should account for subject binding and any additional OIDC
  context needed to safely decide whether `id_token` issuance is valid for this slice.

### Public Error Contract

- **D-16:** Keep the public token-endpoint contract **RFC-tight**. Prefer standard OAuth/device-flow
  error names over provider-specific custom names.
- **D-17:** Public mapping target:
  - pending and allowed to keep polling -> `authorization_pending`
  - polled too quickly -> `slow_down`
  - user explicitly denied in the host verification seam -> `access_denied`
  - expired before successful redemption -> `expired_token`
  - unknown `device_code`, mismatched client binding, already-consumed code, stale repeat poll after
    success, or other invalid terminal presentation -> `invalid_grant`
  - bad client authentication remains `invalid_client`
- **D-18:** Keep HTTP semantics aligned with existing token behavior: token endpoint errors remain
  `400` except `invalid_client`, which stays `401` with the normal auth challenge behavior.
- **D-19:** Preserve rich **private** reason codes and telemetry/audit signals even when the public
  error surface collapses multiple terminal cases into `invalid_grant`.
- **D-20:** Do not invent user-friendly custom public errors like `incorrect_device_code`,
  `authorization_declined`, or other hosted-provider-specific names for v1. Those increase client
  coupling and leak too much state for an embedded library surface.

### Atomic Issuance and Lifecycle Safety

- **D-21:** Token issuance from device polling must be **single-winner and atomic**. The working
  target is an atomic transition from `:approved` to `:consumed` coupled to token persistence so a
  poll race cannot mint two successful token responses from one approved device authorization.
- **D-22:** Planner should treat these races as first-class cases:
  - two devices/threads polling the same `device_code`
  - poll arriving while approval is being written
  - replay polling after a winning redemption
  - polling after denial or expiry
- **D-23:** Existing Ecto transaction and row-locking patterns in `Repository` are the intended
  precedent. Prefer Postgres-backed race safety over process-local coordination.

### Discovery, Docs, and Support Contract

- **D-24:** Phase 32 should update discovery truth so `grant_types_supported` reflects device flow
  once the `/token` route actually supports it.
- **D-25:** Docs and tests should teach device clients the calm happy path:
  - poll at the advertised interval
  - back off when `slow_down` is returned
  - stop on terminal errors
  - expect the normal OAuth/OIDC token response on success
- **D-26:** Executable proof matters here. Planner should bias toward protocol, controller, storage,
  and integration tests over prose-only confidence claims.

### Workflow Preference

- **D-27:** Shift decision pressure left for this phase and similar future work: for low- and
  medium-impact implementation details, downstream agents should choose the most coherent
  recommendation and proceed without re-asking. Escalate only for genuinely high-impact
  product-boundary, support-contract, or protocol-safety decisions.

### the agent's Discretion

- Exact module/function extraction strategy inside `TokenExchange` may be chosen during planning as
  long as device flow remains a first-class path into shared issuance code rather than a forked
  token contract.
- Exact names for durable polling-state fields may be chosen during planning if they preserve the
  locked semantics above.
- Whether the `slow_down` response includes an updated `interval` field may be decided in planning
  as a small documented extension; if included, keep the public error name standards-shaped.
- Planner may decide the most maintainable way to preserve or reconstruct any OIDC-specific issuance
  context needed for device flow, but must not silently degrade `openid` requests into an
  OAuth-only response contract.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and carry-forward constraints

- `.planning/ROADMAP.md` — Phase 32 goal, dependency on Phase 31, and success criteria for pending,
  `slow_down`, and token issuance behavior
- `.planning/REQUIREMENTS.md` — DEV-07, DEV-08, DEV-09
- `.planning/PROJECT.md` — embedded-library shape, secure defaults, host-owned seams, and release
  truthfulness
- `.planning/STATE.md` — already-locked device-flow milestone decisions and execution posture
- `.planning/phases/31-host-owned-verification-ui-seam/31-CONTEXT.md` — host-owned verification
  seam, explicit actor binding, approval/denial lifecycle, and anti-phishing decisions

### Existing token and device-flow implementation surface

- `lib/lockspire/web/controllers/token_controller.ex` — thin `/token` adapter precedent
- `lib/lockspire/protocol/token_exchange.ex` — existing grant routing, success/error structs, auth
  code exchange, refresh exchange integration, and issuance helpers
- `lib/lockspire/web/controllers/token_json.ex` — canonical token success/error JSON contract
- `lib/lockspire/protocol/device_authorization.ex` — current `/device/code` response shape including
  `interval`
- `lib/lockspire/protocol/device_verification.ex` — current lookup/approve/deny seam and device
  authorization lifecycle assumptions
- `lib/lockspire/domain/device_authorization.ex` — durable lifecycle states and domain model
- `lib/lockspire/storage/device_authorization_store.ex` — current storage boundary to extend
- `lib/lockspire/storage/ecto/device_authorization_record.ex` — current durable record shape
- `lib/lockspire/storage/ecto/repository.ex` — row-locking, transitions, and transaction patterns
  to mirror for poll/consume race safety
- `lib/lockspire/protocol/discovery.ex` — discovery truth logic that must reflect device-flow grant
  support
- `lib/lockspire/web/router.ex` — mounted route truth for `/device/code` and `/token`

### Existing proofs and docs to preserve

- `test/lockspire/web/token_controller_test.exs` — existing `/token` contract and cache-header
  proof
- `test/lockspire/protocol/device_authorization_test.exs` — current device authorization success
  shape and `interval` behavior
- `test/lockspire/protocol/device_verification_test.exs` — current device lifecycle and approval
  seam proof
- `test/integration/phase31_generated_host_verification_e2e_test.exs` — host verification behavior
  and lifecycle transitions
- `docs/device-flow-host-guide.md` — anti-phishing posture and host-owned verification contract
- `docs/install-and-onboard.md` — generated seam and onboarding/support contract that later docs
  must stay coherent with

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `TokenExchange.Success` and `TokenJSON` already define the canonical successful `/token` response
  shape. Device flow should reuse that contract instead of introducing a second token response
  family.
- `TokenExchange` already owns client authentication, error shaping, token persistence, refresh
  issuance, `id_token` issuance, and observability patterns that planning should reuse.
- `DeviceAuthorization` and `DeviceVerification` already give device flow a durable state machine
  and explicit approval seam; the remaining work is to connect polling to that state safely.
- `Repository.transition_device_authorization/3` and the surrounding lock/transaction patterns are
  the obvious precedent for race-safe device polling and consume semantics.

### Established Patterns

- Lockspire keeps Plug/Phoenix delivery adapters thin and pushes correctness into protocol/storage
  code.
- Public OAuth/OIDC error contracts stay small and standards-shaped while richer internal reason
  codes and audits remain private.
- Durable Postgres-backed state is preferred over process-local or infra-heavy coordination.
- Discovery/support claims follow repo truth; once device polling ships, grant support metadata and
  docs should change in lockstep with executable proof.

### Integration Points

- Device polling should plug into `TokenExchange.exchange/1` as another supported `grant_type`.
- Device approval must bridge into the same token-storage and signing-key paths already used by
  authorization code and refresh-token flows.
- Discovery truth in `Lockspire.Protocol.Discovery` will need to publish device-flow grant support
  coherently with the `/token` route behavior.
- Tests should likely span protocol-only proof, controller mapping, repository race-safety, and an
  end-to-end device flow from `/device/code` through host verification to `/token`.

</code_context>

<specifics>
## Specific Ideas

- Coherent target architecture:
  - `/device/code` advertises `interval: 5`
  - `/token` accepts `grant_type=urn:ietf:params:oauth:grant-type:device_code`
  - pending compliant polls return `authorization_pending`
  - early polls return `slow_down` and durably widen the next wait window by 5 seconds
  - approved requests win exactly once and reuse the normal Lockspire token response contract
  - stale repeats after success collapse to `invalid_grant`
- External lessons worth carrying forward:
  - Standards and popular servers consistently treat device flow as a normal token endpoint success
    path, not a special response family.
  - Mature ecosystems expect additive `slow_down`, not custom exponential punishment with opaque
    semantics.
  - Hosted-provider docs often drift when they invent custom device-flow errors; Lockspire should
    avoid that footgun and stay RFC-shaped publicly.
  - The main engineering risk is not payload breadth but atomic issuance and durable polling state.
- DX priorities for this phase:
  - generic OAuth/OIDC clients should work without special Lockspire-only behavior
  - host apps should not need Redis or another extra system just to get safe device polling
  - implementers should see one mental model for token success across auth code, refresh token, and
    device flow
  - documentation should explain exactly when to keep polling, when to back off, and when to stop
- Footguns to avoid:
  - Plug-only or ETS-only throttling state
  - nonstandard public error names for invalid codes or denial
  - public distinction between unknown vs consumed vs mismatched device codes
  - separate device-only token response shape
  - poll/approve/consume races that can double-issue tokens

</specifics>

<deferred>
## Deferred Ideas

- Mandatory built-in outer `/token` rate-limiting helpers or distributed abuse-control primitives
  beyond protocol backpressure
- Provider-style custom device-flow error taxonomies for first-party-only clients
- Broader device-flow policy surfaces such as per-client configurable backoff algorithms or device
  UX customization beyond the current narrow RFC 8628 slice
- Any intentional narrowing of device flow into an OAuth-only, non-OIDC grant surface

</deferred>

---

*Phase: 32-polling-token-issuance*
*Context gathered: 2026-04-28*
