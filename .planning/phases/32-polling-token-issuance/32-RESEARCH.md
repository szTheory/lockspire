# Phase 32: polling-token-issuance - Research

**Researched:** 2026-04-28 [VERIFIED: system date]
**Domain:** OAuth 2.0 Device Authorization Grant polling, token issuance, and durable backpressure in Phoenix/Ecto [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: codebase grep]
**Confidence:** MEDIUM [VERIFIED: research synthesis]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions [VERIFIED: 32-CONTEXT.md, verbatim copy below]

#### Token Endpoint Topology

- **D-01:** Phase 32 extends the existing `/token` endpoint and `Lockspire.Protocol.TokenExchange`
  surface rather than introducing a separate device-only controller or a parallel issuance stack.
- **D-02:** Device polling should feel like "a different grant validator feeding the same durable
  token machinery" already used by authorization code and refresh-token exchange, not like a
  second-class token contract.
- **D-03:** Planner should prefer extracting shared issuance helpers where useful, but preserve the
  existing thin-controller pattern: Plug/Phoenix adapters stay small, while protocol/storage layers
  own grant semantics, race-safety, and issuance rules.

#### Polling Policy and Backpressure

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

#### Success Response Shape

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

#### Public Error Contract

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

#### Atomic Issuance and Lifecycle Safety

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

#### Discovery, Docs, and Support Contract

- **D-24:** Phase 32 should update discovery truth so `grant_types_supported` reflects device flow
  once the `/token` route actually supports it.
- **D-25:** Docs and tests should teach device clients the calm happy path:
  - poll at the advertised interval
  - back off when `slow_down` is returned
  - stop on terminal errors
  - expect the normal OAuth/OIDC token response on success
- **D-26:** Executable proof matters here. Planner should bias toward protocol, controller, storage,
  and integration tests over prose-only confidence claims.

#### Workflow Preference

- **D-27:** Shift decision pressure left for this phase and similar future work: for low- and
  medium-impact implementation details, downstream agents should choose the most coherent
  recommendation and proceed without re-asking. Escalate only for genuinely high-impact
  product-boundary, support-contract, or protocol-safety decisions.

### Claude's Discretion [VERIFIED: 32-CONTEXT.md, verbatim copy below]

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

### Deferred Ideas (OUT OF SCOPE) [VERIFIED: 32-CONTEXT.md]

None explicitly listed in `32-CONTEXT.md`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEV-07 | Implement `POST /token` support for `grant_type=urn:ietf:params:oauth:grant-type:device_code`. [VERIFIED: .planning/REQUIREMENTS.md] | Add a device-code branch inside `Lockspire.Protocol.TokenExchange.exchange/1`, reuse existing `/token` controller and `TokenJSON`, and authenticate clients using the same `ClientAuth` path already used for other grants. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628] |
| DEV-08 | Handle `authorization_pending`, `slow_down`, and token issuance on the `/token` endpoint. [VERIFIED: .planning/REQUIREMENTS.md] | RFC 8628 requires `authorization_pending` for still-pending requests, `slow_down` for continued polling with a +5 second increase, and standard token success when approved. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] |
| DEV-09 | Enforce polling intervals and prevent database crush via efficient Ecto queries. [VERIFIED: .planning/REQUIREMENTS.md] | Use durable per-record poll state plus row-level locks and transactions in the repository layer, following current `transition_device_authorization/3` and token redemption precedents. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
</phase_requirements>

## Summary

Phase 32 should be planned as an extension of Lockspire’s existing `/token` path, not as a new delivery surface. The current repo already has the right thin-controller shape: `Lockspire.Web.TokenController` delegates to `Lockspire.Protocol.TokenExchange`, and `TokenExchange` already owns client authentication, public/private error shaping, token persistence, refresh issuance, `id_token` issuance, and telemetry. [VERIFIED: codebase grep]

The missing work is in three places. First, `TokenExchange.exchange/1` currently only accepts `authorization_code` and `refresh_token`, so device polling is not wired at all. Second, the device-authorization record currently stores lifecycle state but no durable polling window or effective interval, which means RFC 8628 `slow_down` semantics cannot yet be enforced across nodes. Third, `/device/code` currently does not return an `interval` field even though RFC 8628 says clients must default to 5 seconds when absent and the phase context has locked an explicit `interval: 5` response. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628]

The highest-risk planning item is atomic issuance. The successful device poll needs to move one approved authorization to a consumed terminal state and persist the resulting access token family in one transaction, so exactly one poll wins and stale retries collapse to `invalid_grant`. The repo already uses `FOR UPDATE` locks and `Repo.transact/1` patterns for authorization-code redemption and verification-state transitions; Phase 32 should extend those patterns rather than introduce in-memory coordination or a second issuance pipeline. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

**Primary recommendation:** Plan Phase 32 as one vertical slice spanning migration + repository API + `TokenExchange` grant branch + discovery/tests, with all polling/backpressure truth stored durably on the device-authorization row and all success responses built through the existing token machinery. [VERIFIED: research synthesis]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Accept device-code polls on `POST /token` | API / Backend | Frontend Server (SSR) | The mounted Phoenix controller is thin, but grant parsing, client auth, and protocol responses belong in `TokenExchange`. [VERIFIED: codebase grep] |
| Enforce polling interval and sticky `slow_down` | Database / Storage | API / Backend | RFC 8628 behavior must survive process restarts and multi-node deployment, so the durable device-authorization row owns the timing truth while protocol code interprets it. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: codebase grep] |
| Atomic approved-to-consumed issuance | Database / Storage | API / Backend | Single-winner semantics require a transaction plus row lock around state transition and token persistence. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Public token JSON and HTTP error mapping | API / Backend | Frontend Server (SSR) | Existing `TokenJSON` and controller cache/auth-challenge behavior already own the HTTP contract. [VERIFIED: codebase grep] |
| Discovery metadata updates | API / Backend | — | `Lockspire.Protocol.Discovery` computes the published metadata and already owns `grant_types_supported`. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` (published 2026-03-05) [VERIFIED: hex.pm API] | Mounted `/token`, `/device/code`, and discovery endpoints. [VERIFIED: codebase grep] | The phase fits the existing thin-controller router/controller pattern; no new HTTP layer is needed. [VERIFIED: codebase grep] |
| Ecto SQL | `3.13.5` (published 2026-03-03) [VERIFIED: hex.pm API] | Transactions, row locks, and record persistence. [VERIFIED: codebase grep] | Current repo patterns already use `lock("FOR UPDATE")` and transactional state transitions, which match the phase’s race-safety needs. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| PostgreSQL | `14+` [VERIFIED: AGENTS.md] | Durable poll-window state and cross-node serialization. [VERIFIED: codebase grep] | The project has already chosen Postgres-backed device state and Phase 32 explicitly rejects in-memory backpressure truth. [VERIFIED: 32-CONTEXT.md] |
| JOSE | `1.11.12` (published 2025-11-20) [VERIFIED: hex.pm API] | Existing `id_token` signing path. [VERIFIED: codebase grep] | Device-flow success should reuse the same OIDC issuance machinery instead of inventing a parallel signer. [VERIFIED: 32-CONTEXT.md] [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveView | `1.1.28` (published 2026-03-27) [VERIFIED: hex.pm API] | Already used elsewhere in Lockspire, but not a required part of Phase 32. [VERIFIED: codebase grep] | Only relevant if docs/examples need to reference host UX continuity from Phase 31. [VERIFIED: research synthesis] |
| OpenTelemetry API | `1.5.0` (published 2025-10-17) [VERIFIED: hex.pm API] | Existing observability surface for token success/failure telemetry. [VERIFIED: codebase grep] | Use when adding device-grant issuance and failure events so the new path remains consistent with current token observability. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `TokenExchange` | A device-only token controller/protocol stack | Rejected because it would fork the token contract, duplicate client auth/error logic, and break the locked “shared issuance core” decision. [VERIFIED: 32-CONTEXT.md] [VERIFIED: codebase grep] |
| Durable poll state in Postgres | ETS/Agent/in-memory counters | Rejected because RFC 8628 backpressure must remain correct across nodes and deploys, and the project has already chosen durable Postgres-backed state. [VERIFIED: 32-CONTEXT.md] |
| Shared token success builder | Hand-built device success JSON | Rejected because `TokenExchange.Success` and `TokenJSON` already define the canonical response shape, including optional `refresh_token` and `id_token`. [VERIFIED: codebase grep] |

**Installation:** No new dependencies are required for this phase; use the existing project dependencies with `mix deps.get`. [VERIFIED: codebase grep]

**Version verification:** Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, JOSE `1.11.12`, and OpenTelemetry API `1.5.0` were verified against the Hex package API in this session. [VERIFIED: hex.pm API]

## Architecture Patterns

### System Architecture Diagram

Recommended data flow for Phase 32: device polls the existing `/token` route, protocol code authenticates the client and loads the device-authorization row, repository code decides whether the row is pending/too-early/approved/terminal under lock, and successful approval reuses the existing token issuance stack before returning the standard token JSON. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628]

```text
Device Client
  |
  | POST /token
  | grant_type=device_code + device_code + client auth
  v
TokenController
  |
  v
TokenExchange.exchange/1
  |
  +--> ClientAuth.authenticate
  |
  +--> Device grant branch
         |
         v
     Repository transaction
         |
         +--> load device authorization row FOR UPDATE
         |
         +--> decision:
               - not found / wrong client / consumed -> invalid_grant
               - expired -> expired_token
               - denied -> access_denied
               - pending but too early -> advance poll window + slow_down
               - pending and allowed -> authorization_pending
               - approved -> consume row + persist tokens atomically
                                      |
                                      v
                              shared token builders
                              + refresh policy
                              + optional id_token
                                      |
                                      v
                                 TokenJSON
                                      |
                                      v
                               JSON response
```

### Recommended Project Structure

```text
lib/
├── lockspire/protocol/
│   ├── token_exchange.ex              # add device-code grant routing and shared helpers
│   ├── device_authorization.ex        # advertise interval: 5 from /device/code
│   └── discovery.ex                   # publish device grant support truthfully
├── lockspire/storage/
│   ├── device_authorization_store.ex  # extend behavior for poll/consume operations
│   └── ecto/
│       ├── device_authorization_record.ex  # add durable poll-state fields
│       └── repository.ex              # transaction + row-lock logic
└── lockspire/web/controllers/
    ├── token_controller.ex            # stays thin
    └── token_json.ex                  # reuse canonical success/error shape

priv/repo/migrations/
└── *_device_authorization_polling*.exs  # add poll-window columns/indexes

test/
├── lockspire/protocol/                # new device-grant protocol tests
├── lockspire/storage/ecto/            # new repository race/backpressure tests
├── lockspire/web/controllers/         # token/discovery contract tests
└── integration/                       # end-to-end device flow after approval
```

### Pattern 1: Grant Router Feeding Shared Issuance Core
**What:** Extend `TokenExchange.exchange/1` with a device-code branch that validates RFC 8628 request parameters, authenticates the client with existing `ClientAuth`, and hands off to shared token builders instead of bypassing them. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628]
**When to use:** Use for every successful device-flow redemption and for all token-endpoint error responses. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: codebase grep]
**Example:**
```typescript
// Source: https://datatracker.ietf.org/doc/html/rfc8628
// grant_type=urn:ietf:params:oauth:grant-type:device_code
// device_code=...
// client_id=...
```

### Pattern 2: Row-Locked Poll Evaluation
**What:** Put the pending/too-early/approved/terminal decision inside one repository transaction that locks the device-authorization row, evaluates time/state, and either updates poll metadata or persists tokens. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
**When to use:** Use for every device-code poll that reaches protocol storage, especially where two pollers can race or approval can land concurrently. [VERIFIED: research synthesis]
**Example:**
```elixir
// Source: https://hexdocs.pm/ecto/Ecto.Query.html
DeviceAuthorizationRecord
|> where([authorization], authorization.verification_handle == ^handle)
|> lock("FOR UPDATE")
```

### Pattern 3: Discovery Follows Mounted Truth
**What:** Update `grant_types_supported` and add `device_authorization_endpoint` only when the corresponding routes are truly mounted and supported. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [CITED: https://datatracker.ietf.org/doc/html/rfc8414]
**When to use:** Use when Phase 32 makes device polling production-real rather than aspirational. [VERIFIED: research synthesis]
**Example:**
```elixir
// Source: https://datatracker.ietf.org/doc/html/rfc8414
%{
  "grant_types_supported" => [...],
  "device_authorization_endpoint" => issuer_url
}
```

### Anti-Patterns to Avoid
- **Separate device token contract:** Do not create a device-only success struct or JSON renderer; reuse `TokenExchange.Success` and `TokenJSON`. [VERIFIED: codebase grep] [VERIFIED: 32-CONTEXT.md]
- **Process-local backpressure:** Do not use ETS, `Process.put`, or Plug assigns for polling cadence truth. [VERIFIED: 32-CONTEXT.md]
- **Pre-read then write without a lock:** A read-then-branch-then-update flow without `FOR UPDATE` will race under concurrent polls or approve/poll overlap. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html]
- **Leaky public error taxonomy:** Do not expose internal reasons like “already consumed” or “client mismatch” as separate public OAuth errors. [VERIFIED: 32-CONTEXT.md] [CITED: https://datatracker.ietf.org/doc/html/rfc8628]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token success/error JSON | A bespoke device-flow response encoder | `Lockspire.Protocol.TokenExchange.Success` + `Lockspire.Web.TokenJSON` [VERIFIED: codebase grep] | The repo already has the canonical token contract and Phase 32 must remain consistent with it. [VERIFIED: 32-CONTEXT.md] |
| Concurrency control | Ad hoc mutexes or node-local timers | Ecto transaction + `lock("FOR UPDATE")` on the device-authorization row [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] | This is the project’s existing race-safety pattern and works across nodes. [VERIFIED: codebase grep] |
| Refresh issuance policy | A new device-specific refresh decision tree | Existing `issue_refresh_token?/2` path and shared token persistence [VERIFIED: codebase grep] | The phase context locks refresh issuance to the same policy posture as existing grants. [VERIFIED: 32-CONTEXT.md] |
| OIDC signing | A device-specific JWT signer | Existing `Lockspire.Protocol.IdToken` path [VERIFIED: codebase grep] | Reuse reduces drift and preserves the established signing-key and claims resolution contract. [VERIFIED: codebase grep] |

**Key insight:** The complexity in this phase is not request parsing; it is durable state transition correctness under polling races, so planner effort should go into repository semantics and proof tests rather than new endpoint scaffolding. [VERIFIED: research synthesis]

## Common Pitfalls

### Pitfall 1: Forgetting to Advertise or Enforce the Poll Interval
**What goes wrong:** Clients poll immediately or too often because `/device/code` omits `interval` and `/token` has no durable cadence enforcement. [VERIFIED: codebase grep]
**Why it happens:** `DeviceAuthorization.Success` has an `interval` field, but `authorize/1` currently does not populate it and the existing tests do not assert it. [VERIFIED: codebase grep]
**How to avoid:** Add `interval: 5` to `/device/code`, persist poll-window state on the device-authorization row, and test both happy-path pending polls and too-early polls. [VERIFIED: 32-CONTEXT.md] [CITED: https://datatracker.ietf.org/doc/html/rfc8628]
**Warning signs:** Discovery/docs say device flow is supported, but `/device/code` bodies still lack `interval` or repeated polls never return `slow_down`. [VERIFIED: research synthesis]

### Pitfall 2: Double Issuance on Approved Poll Races
**What goes wrong:** Two pollers win and mint two access tokens or a stale repeat poll succeeds after the first redemption. [VERIFIED: research synthesis]
**Why it happens:** Approval and token issuance are currently separate concerns, and there is no device-specific consume-and-persist transaction yet. [VERIFIED: codebase grep]
**How to avoid:** Add a repository operation that locks the row, validates terminal state, transitions `:approved -> :consumed`, and persists tokens inside one transaction. [VERIFIED: 32-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
**Warning signs:** More than one access token is stored for one device authorization, or replay polls after success do not return `invalid_grant`. [VERIFIED: research synthesis]

### Pitfall 3: Losing OIDC Context on Device Approval
**What goes wrong:** Approved `openid` device requests either cannot mint an `id_token` or mint one without enough context to be defensible. [VERIFIED: codebase grep] [VERIFIED: 32-CONTEXT.md]
**Why it happens:** Current device-authorization rows store `subject_id` and scopes, but current code-flow `id_token` issuance pulls nonce and interaction context from `Interaction`, which device flow does not currently have. [VERIFIED: codebase grep]
**How to avoid:** Plan explicit durable OIDC issuance context for device flow before implementation begins, and treat this as a schema/API concern, not a last-minute formatter tweak. [VERIFIED: 32-CONTEXT.md]
**Warning signs:** Device-flow tests can issue access tokens but need special-case logic to skip `id_token` or fabricate missing claims context. [VERIFIED: research synthesis]

### Pitfall 4: Publishing Discovery Ahead of Reality
**What goes wrong:** Discovery advertises device grant support before `/token` actually accepts the device-code grant, or omits `device_authorization_endpoint` even though `/device/code` is mounted. [VERIFIED: codebase grep]
**Why it happens:** `Discovery` currently publishes `grant_types_supported` as only `authorization_code` and `refresh_token`, and tests explicitly refute `device_authorization_endpoint`. [VERIFIED: codebase grep]
**How to avoid:** Change discovery and its tests in the same slice as the `/token` implementation and keep route truth as the source of metadata. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [CITED: https://datatracker.ietf.org/doc/html/rfc8414]
**Warning signs:** Discovery tests and docs need special caveats like “device flow partially supported.” [VERIFIED: research synthesis]

## Code Examples

Verified patterns from official sources:

### Row-Level Locking Around a Mutable Authorization Row
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Query.html
from(u in User, where: u.id == ^current_user, lock: "FOR SHARE NOWAIT")
```

Use the same Ecto lock primitive with `FOR UPDATE` on the device-authorization row before deciding pending/slow_down/approved/terminal behavior. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [VERIFIED: codebase grep]

### Transaction With Explicit Rollback
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
Repo.transact(fn ->
  if invalid_condition?() do
    Repo.rollback(:invalid_state)
  end
  {:ok, :done}
end)
```

This matches Lockspire’s existing repository style for state transitions and token redemption. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat device polling as a one-off side channel with ad hoc timing | Treat device polling as a first-class token-endpoint grant with RFC-defined errors and durable backpressure. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] | RFC 8628 standardized this in August 2019. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] | Generic device clients interoperate better and hosts avoid provider-specific coupling. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] |
| In-memory throttling for “please slow down” semantics | Per-record sticky interval increases stored durably and enforced transactionally. [VERIFIED: 32-CONTEXT.md] | This project locked the durable approach in Phase 32 context on 2026-04-28. [VERIFIED: 32-CONTEXT.md] | Backpressure remains correct across nodes, deploys, and retries. [VERIFIED: research synthesis] |
| Discovery documents that only list auth-code and refresh grants | Discovery that also lists the device-code grant and `device_authorization_endpoint` once support is real. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [CITED: https://datatracker.ietf.org/doc/html/rfc8414] | Needed as soon as Phase 32 completes. [VERIFIED: research synthesis] | Docs, SDKs, and dynamic clients get truthful metadata. [CITED: https://datatracker.ietf.org/doc/html/rfc8414] |

**Deprecated/outdated:**
- Publishing custom public device-flow errors is outdated for this phase because RFC 8628 already defines the poll/terminal error vocabulary the project has chosen to preserve. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: 32-CONTEXT.md]
- Advertising partial device support in discovery is outdated once `/device/code` and `/token` are both implemented, because the metadata should reflect mounted truth rather than aspiration. [CITED: https://datatracker.ietf.org/doc/html/rfc8414] [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Device-flow OIDC support may require storing an optional `nonce` or equivalent replay-binding context if host/client contracts expect nonce validation on returned `id_token`s. [ASSUMED] | Common Pitfalls | Planner could under-scope schema changes and discover late that `id_token` issuance lacks required context. |

## Open Questions

1. **What durable OIDC context does device flow need beyond `subject_id` and scopes?**
   - What we know: Current code-flow `id_token` issuance depends on `Interaction.nonce`, claims resolution, and a signing key, while the device-authorization row currently stores only lifecycle state, subject binding, and scopes. [VERIFIED: codebase grep]
   - What's unclear: Whether the planner should introduce a stored `nonce`, some smaller OIDC context record, or a documented rule that `id_token` is only issued when the device request carried enough context. [ASSUMED]
   - Recommendation: Treat this as Wave 0 schema/API design, not a later integration fix. [VERIFIED: research synthesis]

2. **Should `slow_down` include an `interval` field?**
   - What we know: RFC 8628 defines the error name and sticky +5 behavior, but Phase 32 leaves the extra `interval` field as a discretionary DX extension. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: 32-CONTEXT.md]
   - What's unclear: Whether Lockspire wants the client-facing convenience strongly enough to standardize and document it now. [VERIFIED: 32-CONTEXT.md]
   - Recommendation: Keep it out unless tests/docs show a concrete interoperability benefit, because the public contract is cleaner without it. [VERIFIED: research synthesis]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, tests, compilation | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Dependency info, test aliases | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL server | Ecto sandbox/integration tests | ✓ [VERIFIED: `pg_isready`] | accepting on `5432` [VERIFIED: `pg_isready`] | — |
| PostgreSQL CLI | Direct DB inspection if needed | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |
| Node.js | Hex API/Context7 fallback tooling used during research | ✓ [VERIFIED: `node --version`] | `v22.14.0` [VERIFIED: `node --version`] | — |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None found. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix/Ecto integration tests. [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/device_polling_test.exs test/lockspire/storage/ecto/repository_device_authorization_test.exs test/lockspire/web/token_controller_test.exs -x` [VERIFIED: research synthesis] |
| Full suite command | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` [VERIFIED: mix.exs aliases] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEV-07 | `/token` accepts `grant_type=device_code` and authenticates/binds the client correctly. [VERIFIED: .planning/REQUIREMENTS.md] | protocol + controller | `MIX_ENV=test mix test test/lockspire/protocol/device_polling_test.exs test/lockspire/web/token_controller_test.exs -x` [VERIFIED: research synthesis] | ❌ Wave 0 |
| DEV-08 | Pending polls return `authorization_pending`, early polls return `slow_down`, approved polls return normal token JSON, and stale replays return terminal errors. [VERIFIED: .planning/REQUIREMENTS.md] | protocol + integration | `MIX_ENV=test mix test test/lockspire/protocol/device_polling_test.exs test/integration/phase32_device_polling_e2e_test.exs -x` [VERIFIED: research synthesis] | ❌ Wave 0 |
| DEV-09 | Poll cadence is enforced durably and efficiently under repeated or concurrent polling. [VERIFIED: .planning/REQUIREMENTS.md] | repository + integration | `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_device_authorization_polling_test.exs test/integration/phase32_device_polling_e2e_test.exs -x` [VERIFIED: research synthesis] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/device_polling_test.exs test/lockspire/web/token_controller_test.exs -x` [VERIFIED: research synthesis]
- **Per wave merge:** `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs aliases]
- **Phase gate:** `MIX_ENV=test mix test.integration` plus the new phase-specific targeted tests green before `/gsd-verify-work`. [VERIFIED: mix.exs aliases] [VERIFIED: research synthesis]

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/device_polling_test.exs` — covers DEV-07 and DEV-08 device-grant protocol branching. [VERIFIED: codebase grep]
- [ ] `test/lockspire/storage/ecto/repository_device_authorization_polling_test.exs` — covers DEV-09 durable poll windows, sticky interval increases, and consume races. [VERIFIED: research synthesis]
- [ ] `test/integration/phase32_device_polling_e2e_test.exs` — covers `/device/code -> /verify -> /token` end-to-end success and terminal behavior. [VERIFIED: research synthesis]
- [ ] Extend `test/lockspire/web/discovery_controller_test.exs` — current test still asserts `grant_types_supported == ["authorization_code", "refresh_token"]` and refutes `device_authorization_endpoint`. [VERIFIED: codebase grep]
- [ ] Extend `test/lockspire/protocol/device_authorization_test.exs` and `test/lockspire/web/controllers/device_authorization_controller_test.exs` — current tests do not assert `interval`. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: research synthesis] | Reuse existing `ClientAuth` handling for public and confidential clients on the token endpoint. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628] |
| V3 Session Management | no [VERIFIED: research synthesis] | Host-user session handling stays in the Phase 31 verification seam, not this phase. [VERIFIED: 32-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: research synthesis] | Bind each device code to the issuing client and collapse mismatches to `invalid_grant`. [VERIFIED: 32-CONTEXT.md] [CITED: https://datatracker.ietf.org/doc/html/rfc6749] |
| V5 Input Validation | yes [VERIFIED: research synthesis] | Normalize and validate `grant_type`, `device_code`, and client credentials before any state transition. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: codebase grep] |
| V6 Cryptography | yes [VERIFIED: research synthesis] | Keep using hashed-at-rest codes, JOSE signing for `id_token`, and no custom crypto. [VERIFIED: codebase grep] [VERIFIED: AGENTS.md] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Polling storm against `/token` | Denial of Service | RFC 8628 interval enforcement plus sticky `slow_down` backed by durable row state; optional outer host rate limiting only as defense in depth. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: 32-CONTEXT.md] |
| Device-code replay after approval | Tampering | Single transaction that consumes the approved row and persists tokens exactly once; stale repeats return `invalid_grant`. [VERIFIED: 32-CONTEXT.md] [VERIFIED: codebase grep] |
| Client-binding mismatch on poll | Spoofing | Authenticate the client and compare the presented client to the device authorization’s `client_id`. [CITED: https://datatracker.ietf.org/doc/html/rfc8628] [VERIFIED: 32-CONTEXT.md] |
| Error-detail leakage about denied/consumed/nonexistent codes | Information Disclosure | Keep public errors RFC-shaped and record richer reason codes only in telemetry/audit streams. [VERIFIED: 32-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `32-CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, and current `lib/`/`test/` files - phase constraints, existing architecture, and current gaps. [VERIFIED: codebase grep]
- RFC 8628 - polling behavior, error semantics, default interval, and discovery metadata registration: https://datatracker.ietf.org/doc/html/rfc8628 [CITED: https://datatracker.ietf.org/doc/html/rfc8628]
- RFC 6749 - token success/error response rules, `invalid_client`, and `invalid_grant`: https://datatracker.ietf.org/doc/html/rfc6749 [CITED: https://datatracker.ietf.org/doc/html/rfc6749]
- RFC 8414 - `grant_types_supported` metadata semantics: https://datatracker.ietf.org/doc/html/rfc8414 [CITED: https://datatracker.ietf.org/doc/html/rfc8414]
- Ecto docs - row locks and transactions: https://hexdocs.pm/ecto/Ecto.Query.html and https://hexdocs.pm/ecto/Ecto.Repo.html [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Hex package API - verified package versions and publish dates for Phoenix, Phoenix LiveView, Ecto SQL, JOSE, and OpenTelemetry API. [VERIFIED: hex.pm API]

### Secondary (MEDIUM confidence)
- OpenID Connect Core 1.0 - code-flow ID Token validation and nonce-if-sent behavior: https://openid.net/specs/openid-connect-core-1_0-18.html [CITED: https://openid.net/specs/openid-connect-core-1_0-18.html]
- Context7 CLI fallback for Ecto transaction/locking examples. [CITED: https://context7.com/elixir-ecto/ecto/llms.txt]

### Tertiary (LOW confidence)
- None. [VERIFIED: research synthesis]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The phase reuses already-installed project dependencies and their versions were verified directly against Hex in this session. [VERIFIED: hex.pm API]
- Architecture: HIGH - The repo already exposes the exact extension points this phase needs, and RFC 8628 gives clear polling semantics. [VERIFIED: codebase grep] [CITED: https://datatracker.ietf.org/doc/html/rfc8628]
- Pitfalls: MEDIUM - Most risks are directly visible in current code, but the OIDC device-flow context story still contains one explicit assumption. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-04-28 [VERIFIED: system date]
**Valid until:** 2026-05-28 for repo-specific findings; re-check standards-adjacent package versions and ecosystem guidance after that date. [VERIFIED: research synthesis]
