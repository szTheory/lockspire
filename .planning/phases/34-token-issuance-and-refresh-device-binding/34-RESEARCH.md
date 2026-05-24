# Phase 34: Token Issuance and Refresh/Device Binding - Research

**Researched:** 2026-04-28
**Domain:** DPoP-bound token issuance, refresh-token rotation, and device-code redemption in an embedded Phoenix OAuth/OIDC server
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- Separate DPoP binding tables or key-history models beyond `Token.cnf` — out of scope for this
  milestone slice
- Compatibility modes that bind only refresh tokens while keeping access-token responses publicly
  `Bearer` — deferred unless real adopter pressure proves they are necessary
- Custom provider-specific DPoP public error taxonomy — rejected for v1.7
- Generic host-app protected-resource middleware for DPoP validation outside Lockspire-owned
  endpoints — explicitly deferred to future sender-constrained depth
- Formalizing the "shift low/medium-impact choices left" preference into broader GSD defaults or
  user profile/config outside this phase's context work
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DPoP-05 | `POST /token` supports DPoP-bound authorization-code exchange for DPoP-mode clients and returns truthful DPoP token responses. [VERIFIED: .planning/REQUIREMENTS.md] | Centralize DPoP policy resolution and proof handling in `TokenExchange`, construct `cnf` once, and return `token_type: "DPoP"` from the shared success contract. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/dpop_policy.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| DPoP-06 | DPoP-bound access tokens persist confirmation (`cnf`) state that is sufficient for later validation on Lockspire-owned endpoints. [VERIFIED: .planning/REQUIREMENTS.md] | Use existing durable `Token.cnf` / `TokenRecord.cnf` as the canonical `jkt` carrier for access and refresh tokens. [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| DPoP-07 | Refresh-token exchange preserves DPoP binding semantics and rejects refresh attempts that present the wrong proof key or no valid proof. [VERIFIED: .planning/REQUIREMENTS.md] | Add an atomic repository-backed binding check to refresh rotation so the expected `cnf.jkt` is compared before child tokens are persisted, while public errors stay `invalid_grant`. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| DPoP-08 | Device-code exchange supports DPoP mode for public and CLI-oriented clients without widening the host-owned verification seam. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the same issuance context for device-code redemption and bind the key at the winning `/token` request, not in host verification state. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep Lockspire as an embedded companion library inside a host Phoenix app; do not turn this phase into standalone auth-service behavior. [VERIFIED: AGENTS.md]
- Preserve strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam narrow: account resolution, claims, login redirects, branding, and product policy remain host-owned. [VERIFIED: AGENTS.md]
- Preserve secure defaults already locked for the project: PKCE S256 by default, exact redirect URI matching, single-use short-lived authorization codes, refresh rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]

## Summary

Phase 34 should be planned as one extension of the existing token lifecycle, not as “DPoP mode” built beside it. The repo already has the right primitives: `TokenExchange` is the shared grant router, `RefreshExchange` already owns family-wide rotation and reuse handling, `Lockspire.Protocol.DPoP` yields a validated proof plus `jkt`, `Lockspire.Protocol.DpopPolicy` resolves effective bearer-vs-DPoP mode, and `Token.cnf` / `TokenRecord.cnf` already persist durable confirmation state. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/dpop_policy.ex] [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex]

RFC 9449 requires a valid DPoP proof on token requests that want DPoP-bound tokens, requires `token_type: "DPoP"` in those access-token responses, and requires refresh-token binding validation for public clients when the refresh token was issued from a DPoP token request. It also leaves the refresh-token binding implementation details to the authorization server, which fits Lockspire’s decision to store `cnf.jkt` directly on opaque tokens rather than inventing an interoperable token format or sidecar table. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]

The main planning risk is not cryptography. It is semantic drift across grants: one branch returning `Bearer`, another forgetting `cnf`, refresh rotation comparing the proof key outside the transaction, or device flow caching DPoP state in approval records. Plan Phase 34 around one small issuance context, one truthful success contract, and one storage-owned atomic refresh check. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

**Primary recommendation:** Add a protocol-owned issuance context carrying effective DPoP mode, validated proof, `jkt`, derived `cnf`, and public `token_type`, then thread that single context through auth-code issuance, refresh rotation, and device redemption while keeping persistence and compare-and-write logic in the repository. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Extract `DPoP` header, HTTP method, and canonical token-endpoint URI from the request | API / Backend | — | The current Phoenix controller is a thin adapter and should stay responsible only for gathering request context and passing it inward. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| Resolve effective bearer-vs-DPoP mode and validate/replay-check proofs | API / Backend | Database / Storage | Policy resolution and proof semantics are already protocol-owned, while replay acceptance is already repository-backed. [VERIFIED: lib/lockspire/protocol/dpop_policy.ex] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Build `cnf`, choose truthful `token_type`, and fan out to access/refresh persistence | API / Backend | Database / Storage | This is shared token-endpoint correctness, not transport logic; the protocol layer should decide the token semantics once and hand concrete token structs to storage. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/domain/token.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| Persist durable binding truth on access and refresh tokens | Database / Storage | API / Backend | `Token.cnf` is already durable in the domain/schema model and is the locked canonical carrier for this phase. [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| Compare presented proof key to stored refresh-token binding during rotation | Database / Storage | API / Backend | The refresh-family mutation already happens inside repository transactions and must remain atomic with the compare-and-write path. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] |
| Preserve device-flow host seam and bind only at winning token redemption | API / Backend | Database / Storage | Device approval remains host-owned; the token endpoint already consumes approved device authorizations and should attach DPoP at that point only. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` (published 2026-03-05) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Thin `/token` controller and router surface. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] | The phase extends the existing mounted token endpoint instead of adding a second DPoP delivery surface. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| Ecto SQL | `3.13.5` (published 2026-03-03) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Durable token persistence, row locks, and transactional refresh rotation. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | The repo already uses Ecto transactions for single-winner redemption and family revocation; Phase 34 should reuse that discipline. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| JOSE | `1.11.12` (published 2025-11-20) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Validated DPoP proof parsing and JWK thumbprints. [VERIFIED: lib/lockspire/protocol/dpop.ex] | Phase 33 already established JOSE as the proof-validation seam, so Phase 34 should consume its `jkt` output instead of adding new crypto dependencies. [VERIFIED: lib/lockspire/protocol/dpop.ex] |
| PostgreSQL | `14+` [VERIFIED: AGENTS.md] | Durable token and replay truth across nodes and restarts. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] | DPoP binding and refresh-family rotation must remain durable and atomic, not process-local. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| OpenTelemetry API | `1.5.0` (published 2025-10-17) [VERIFIED: mix.lock] [VERIFIED: hex.pm API] | Phase-appropriate observability for DPoP issuance success/failure and refresh-binding mismatches. [VERIFIED: mix.exs] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] | Use existing telemetry/audit seams instead of inventing a parallel DPoP event bus. [VERIFIED: AGENTS.md] |
| ExUnit / Mix test aliases | Elixir `1.19.5`, Mix `1.19.5` [VERIFIED: elixir --version] [VERIFIED: mix --version] | Repo-standard protocol, repository, controller, and integration verification. [VERIFIED: mix.exs] [VERIFIED: rg --files test] | Use when extending token, refresh, and device proofs for DPoP behavior. [VERIFIED: .planning/ROADMAP.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared issuance context in `TokenExchange` / `RefreshExchange` | Per-grant DPoP-specific exchange modules | Rejected because the repo already converges auth-code and device issuance through shared helpers, and the phase context explicitly forbids a parallel subsystem. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| `Token.cnf` as the only durable binding carrier | Separate DPoP binding table or sidecar record | Rejected by locked decision D-02 and unnecessary because the token domain/schema already persist `cnf`. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] |
| Storage-owned atomic compare-and-write for refresh binding | Protocol-side fetch/compare followed by later rotation write | Rejected because refresh rotation already lives in a single repository transaction and Phase 34 needs the binding check to be atomic with family mutation. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] |

**Installation:** No new dependency is required for Phase 34. Use the existing Phoenix/Ecto/JOSE/OpenTelemetry stack already pinned in `mix.exs` and `mix.lock`. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

**Version verification:** Current project-relevant releases were checked in this session via Hex API: Phoenix `1.8.5` (2026-03-05), Ecto SQL `3.13.5` (2026-03-03), JOSE `1.11.12` (2025-11-20), and OpenTelemetry API `1.5.0` (2025-10-17). [VERIFIED: hex.pm API]

## Architecture Patterns

### System Architecture Diagram

```text
HTTP client
  |
  | POST /token
  | Authorization: ...
  | DPoP: <compact JWT>   (optional unless effective policy requires it)
  v
TokenController
  |
  | params + auth header + DPoP header + request method + canonical token endpoint URI
  v
TokenExchange
  |
  +--> ClientAuth.authenticate(...)
  |
  +--> DpopPolicy.resolve_effective_policy(server_policy, client)
  |
  +--> DPoP preflight
        |
        +--> DPoP.validate_proof(...)
        +--> Repository.record_dpop_proof(...)
        +--> issuance_context = %{mode, validated_proof, jkt, cnf, token_type}
  |
  +--> Grant branch
        |
        +--> authorization_code --> shared builders --> persist code redemption + tokens
        +--> refresh_token -----> RefreshExchange ------> atomic binding check + rotation
        +--> device_code -------> shared builders --> consume approved device auth + tokens
  |
  +--> Success contract
        |
        +--> token_type = "DPoP" or "Bearer"
        +--> access token response
        +--> telemetry + audit
  v
Durable token state
  |
  +--> access_token.cnf["jkt"]
  +--> refresh_token.cnf["jkt"]
  +--> family rotation / revocation truth
```

### Recommended Project Structure

```text
lib/
├── lockspire/web/controllers/
│   └── token_controller.ex          # collect DPoP header + canonical request context
├── lockspire/protocol/
│   ├── token_exchange.ex            # auth-code + device issuance context owner
│   ├── refresh_exchange.ex          # refresh binding enforcement + rotation owner
│   ├── dpop.ex                      # validated proof + jkt
│   ├── dpop_policy.ex               # effective bearer vs DPoP policy
│   └── discovery.ex                 # canonical token endpoint URI precedent
├── lockspire/domain/
│   └── token.ex                     # durable cnf carrier
└── lockspire/storage/
    ├── token_store.ex               # extend atomic refresh rotation contract if needed
    └── ecto/repository.ex           # lock + compare + persist in one transaction

test/
├── lockspire/protocol/token_exchange_test.exs
├── lockspire/protocol/refresh_exchange_test.exs
├── lockspire/web/token_controller_test.exs
└── integration/phase32_device_flow_token_exchange_e2e_test.exs
```

### Pattern 1: Add One Issuance Context, Not One `if dpop` per Grant
**What:** Build one internal context after client auth and DPoP preflight, then pass it into token builders and persistence helpers for auth-code, refresh, and device redemption. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
**When to use:** Any `/token` path that can issue or rotate tokens. [VERIFIED: .planning/ROADMAP.md]
**Use:** Carry at least effective mode, validated proof, `jkt`, derived `cnf`, and public `token_type` so the contract is chosen once. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]

**Example:**
```elixir
# Source: RFC 9449 token endpoint + current repo token builders
issuance = %{
  dpop_required?: resolved_policy.dpop_required?,
  proof: validated_proof,
  jkt: validated_proof && validated_proof.jkt,
  cnf: validated_proof && %{"jkt" => validated_proof.jkt},
  token_type: if(validated_proof, do: "DPoP", else: "Bearer")
}

{access_token, raw_access_token} =
  build_access_token(client, grant_token, issued_at, formatted_refresh_token, issuance, request)
```

### Pattern 2: Persist `cnf.jkt` on the Same Token Records That Already Carry Family State
**What:** Write the same `cnf` structure to access and refresh tokens when the issuance context is DPoP-bound. [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
**When to use:** Auth-code issuance, device redemption, and refresh rotation child-token persistence. [VERIFIED: .planning/ROADMAP.md]
**Use:** Keep the binding data on the token rows so later `userinfo`, introspection, and audits can read one durable truth source. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]

### Pattern 3: Make Refresh Binding Check Part of the Rotation Transaction
**What:** The repository must compare the presented proof key to the stored refresh-token `cnf.jkt` before persisting rotated children or revoking the family. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: lib/lockspire/storage/token_store.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
**When to use:** `refresh_token` grant for effective DPoP-mode public and CLI-oriented clients. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
**Use:** Return a private reason like `:refresh_dpop_key_mismatch`, but collapse the public response to `invalid_grant`. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]

**Example:**
```elixir
# Source: RFC 9449 Section 5 + current repository rotate_refresh_token pattern
@callback rotate_refresh_token(
  token_hash,
  client_id,
  rotated_at,
  refresh_token,
  access_token,
  opts \\ []
) ::
  {:ok, %{presented_refresh_token: Token.t(), refresh_token: Token.t(), access_token: Token.t()}}
  | {:error, :refresh_dpop_key_mismatch | term()}

# opts example:
# [expected_jkt: issuance.jkt, dpop_required?: issuance.dpop_required?]
```

### Pattern 4: Bind Device Flow at `/token`, Not in Approval State
**What:** The winning polling redemption request supplies the proof key, and the shared token-issuance path attaches the durable binding then. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/token_exchange.ex]
**When to use:** Device-code exchange only after `record_device_poll/3` reports `:approved_ready`. [VERIFIED: lib/lockspire/protocol/token_exchange.ex]
**Use:** Do not mutate device authorization approval rows to store `jkt`; keep the host verification seam unchanged. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]

### Anti-Patterns to Avoid
- **Parallel DPoP exchange modules:** They will drift on `token_type`, `cnf`, telemetry, and refresh semantics. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
- **Response-only DPoP truth:** Returning `"DPoP"` without durable `cnf.jkt` breaks later `userinfo` and introspection work. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: lib/lockspire/domain/token.ex]
- **Controller-owned DPoP policy decisions:** `TokenController` is currently thin and should not become the policy engine. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex]
- **Read/compare/write refresh binding outside the transaction:** It invites split-brain rotation outcomes and family-state drift. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
- **Storing device DPoP state in approval records:** That widens the host seam Phase 32 explicitly preserved. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DPoP-specific token subsystem | Separate auth-code, refresh, and device exchangers just for DPoP | One issuance context threaded through `TokenExchange` and `RefreshExchange` [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] | The repo already uses shared token lifecycle code, and the phase context locks that pattern in. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| Binding store | Dedicated DPoP binding table | `Token.cnf` / `TokenRecord.cnf` [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] | Existing token rows already persist the exact confirmation payload Phase 35 and Phase 36 will need. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| Compatibility token typing | “Always return `Bearer` for now” | Truthful `token_type: "DPoP"` when access tokens are DPoP-bound [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | RFC 9449 says the token response must signal DPoP binding explicitly. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] |
| Custom refresh-binding public errors | Provider-specific OAuth errors like `dpop_key_mismatch` | Public `invalid_grant` plus private reason codes and telemetry [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] | The repo’s support-contract posture is standards-shaped public errors with richer internal diagnostics. [VERIFIED: AGENTS.md] |
| Device-flow DPoP prebinding | Proof key stored during `/verify` | Bind at winning `/token` redemption request [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] | Keeps host verification UI and subject-approval ownership unchanged. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md] |

**Key insight:** The hard part of this phase is not “how to calculate `jkt`”; that already exists. The hard part is making one durable token-family truth survive auth-code issuance, refresh rotation, and device redemption without splitting correctness across controller code, protocol code, and storage code. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

## Common Pitfalls

### Pitfall 1: Returning `Bearer` for DPoP-Bound Access Tokens
**What goes wrong:** The server issues a DPoP-bound token but reports `token_type: "Bearer"`, so clients and later Lockspire-owned surfaces cannot tell whether the token is sender-constrained. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
**Why it happens:** Current success builders hardcode `"Bearer"` through `formatted_token_type/0`. [VERIFIED: lib/lockspire/protocol/token_exchange.ex]
**How to avoid:** Move token-type selection into the shared issuance context and derive the response contract from effective DPoP mode once. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
**Warning signs:** Tests assert replay protection but still expect `"Bearer"` on DPoP-mode success. [VERIFIED: test/lockspire/protocol/token_exchange_test.exs]

### Pitfall 2: Persisting `cnf` on Access Tokens but Not Refresh Tokens
**What goes wrong:** Refresh rotation loses durable binding truth, so the next refresh request cannot prove it is using the right key. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
**Why it happens:** Current refresh token builders and rotated child-token builders do not carry `cnf` forward. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**How to avoid:** Treat `cnf` as token-family state and copy it to initial refresh tokens plus rotated children. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
**Warning signs:** Access-token tests pass, but refresh rotation tests never assert `cnf` on the presented or rotated refresh token. [VERIFIED: test/lockspire/protocol/refresh_exchange_test.exs]

### Pitfall 3: Checking Refresh Binding Outside the Rotation Transaction
**What goes wrong:** A key mismatch can be detected after another process has already rotated the family, or a mismatch can race with reuse detection and produce inconsistent audit/telemetry. [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**Why it happens:** The protocol layer fetches the refresh token, compares `jkt`, and only later calls the store to mutate state. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex]
**How to avoid:** Extend the repository rotation contract so it receives the expected binding and decides mismatch vs reuse vs success while holding the row lock. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]
**Warning signs:** Planner tasks describe “fetch token, compare key, then rotate” as separate steps.

### Pitfall 4: Binding Device Flow During Host Verification
**What goes wrong:** The host seam starts carrying protocol-owned DPoP state, and device approvals become coupled to a particular proof key before the winning token request exists. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md]
**Why it happens:** It is tempting to treat approval state like an authorization code record and stash DPoP binding there.
**How to avoid:** Continue to let device approval only establish subject and lifecycle state; attach `cnf` when `/token` wins redemption. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
**Warning signs:** New device-authorization fields mention `jkt`, `cnf`, or proof key history. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]

### Pitfall 5: Splitting DPoP Enablement Across Multiple Ad Hoc Switches
**What goes wrong:** One grant path requires a proof while another path silently falls back to bearer because each branch interprets policy independently. [VERIFIED: lib/lockspire/protocol/dpop_policy.ex]
**Why it happens:** The controller, token exchange, and refresh exchange each add their own “is DPoP enabled?” logic.
**How to avoid:** Always resolve effective policy from `DpopPolicy` first and let downstream code consume that result. [VERIFIED: lib/lockspire/protocol/dpop_policy.ex]
**Warning signs:** New code branches on `client.dpop_policy` or server policy fields directly instead of taking a resolved policy/result struct. [VERIFIED: lib/lockspire/protocol/dpop_policy.ex]

## Code Examples

Verified patterns for this repo:

### Truthful `cnf` Construction
```elixir
# Source: RFC 9449 Section 6.1
# Source: current repo durable token seam in lib/lockspire/domain/token.ex
defp confirmation_for(nil), do: nil
defp confirmation_for(%Lockspire.Protocol.DPoP{jkt: jkt}), do: %{"jkt" => jkt}
```

### Shared Access-Token Builder with DPoP Context
```elixir
# Source: current repo builder shape in lib/lockspire/protocol/token_exchange.ex
%Token{
  token_hash: formatted_access_token.token_hash,
  token_type: :access_token,
  family_id: family_id,
  client_id: client.client_id,
  account_id: grant_token.account_id,
  interaction_id: grant_token.interaction_id,
  scopes: grant_token.scopes,
  audience: grant_token.audience,
  cnf: issuance.cnf,
  issued_at: issued_at,
  expires_at: DateTime.add(issued_at, @access_token_ttl, :second)
}
```

### Storage-Owned Refresh Binding Check
```elixir
# Source: RFC 9449 refresh-token binding requirement
# Source: current repo rotate_refresh_token transaction in lib/lockspire/storage/ecto/repository.ex
cond do
  dpop_required? and get_in(record.cnf || %{}, ["jkt"]) != expected_jkt ->
    {:error, :refresh_dpop_key_mismatch}

  not is_nil(record.redeemed_at) or not is_nil(record.revoked_at) ->
    {:error, :reuse_detected}

  true ->
    # revoke presented token, store rotated refresh, store rotated access
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat DPoP as a proof-validation preflight only | Treat DPoP as durable token-binding truth carried in `cnf.jkt` and surfaced by `token_type: "DPoP"` [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | RFC 9449 (2023) and Lockspire Phase 33 groundwork (2026-04-28) [VERIFIED: .planning/STATE.md] | Access tokens, refresh tokens, and later `userinfo` / introspection work now share one durable binding model. [VERIFIED: .planning/ROADMAP.md] |
| Public-client refresh tokens treated like ordinary bearer refresh tokens | Public-client refresh tokens obtained with DPoP must be bound to the same proof key and revalidated on refresh [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | RFC 9449 (2023) | Refresh rotation needs an atomic expected-key check, not just family reuse detection. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Full end-to-end auth-code binding assumed mandatory | RFC 9449 makes `dpop_jkt` authorization-request binding optional [CITED: https://datatracker.ietf.org/doc/html/rfc9449] | RFC 9449 (2023) | Phase 34 can stay focused on `/token` issuance semantics without widening Phase 34 into authorization-request plumbing. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |

**Deprecated/outdated:**
- Returning `Bearer` for a DPoP-bound access token when the client expects sender-constrained protection is outdated and not standards-truthful. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- Access-token-only binding truth is outdated for public-client refresh flows because RFC 9449 requires refresh binding validation too. [CITED: https://datatracker.ietf.org/doc/html/rfc9449]

## Assumptions Log

All claims in this research were verified or cited in this session; no user-confirmation assumptions remain.

## Open Questions (RESOLVED)

1. **How should the repository contract expose refresh-key mismatch without turning storage into a second protocol engine?**
   - What we know: current `TokenStore.rotate_refresh_token/5` already owns the atomic family mutation boundary, and the phase context explicitly wants storage to own durable compare-and-write behavior. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md]
   - What's unclear: whether planning should extend the callback arity, add an options keyword, or add a second repository helper used only by `RefreshExchange`. [VERIFIED: lib/lockspire/storage/token_store.ex]
   - **RESOLVED:** extend the existing rotation callback with one narrow binding argument, `expected_cnf`, shaped as `nil | %{"jkt" => binary}`. This keeps refresh compare-and-write behavior inside the existing store interface and repository transaction, preserves storage as a persistence boundary instead of a second protocol engine, and gives `RefreshExchange` one typed mismatch outcome to collapse publicly to `invalid_grant`. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-02-PLAN.md]

2. **Should auth-code and device issuance share one helper that builds both access and refresh token structs from the issuance context?**
   - What we know: current auth-code and device paths already duplicate the refresh-token creation pattern and hardcode bearer token type separately. [VERIFIED: lib/lockspire/protocol/token_exchange.ex]
   - What's unclear: whether the cleanest Phase 34 plan is a small shared builder extraction in `TokenExchange` or a slightly richer persistence helper. [VERIFIED: lib/lockspire/protocol/token_exchange.ex]
   - **RESOLVED:** plan a small shared builder/context extraction in `TokenExchange` early in `34-01`, with one internal `issuance_context` carrying exact keys `:mode`, `:proof`, `:jkt`, `:cnf`, and `:token_type`. Auth-code and device redemption both use that context so `cnf` persistence and public token-type truth are chosen once and reused, rather than patched into two branches independently. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-01-PLAN.md] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-03-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix compile/test execution | ✓ [VERIFIED: elixir --version] | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Phase test and verification commands | ✓ [VERIFIED: mix --version] | `1.19.5` [VERIFIED: mix --version] | — |
| PostgreSQL | Ecto-backed token/replay/device state and test database | ✓ [VERIFIED: pg_isready] | client `14.17` [VERIFIED: psql --version] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: pg_isready]

**Missing dependencies with fallback:**
- None. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: pg_isready]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix on Elixir `1.19.5` [VERIFIED: mix.exs] [VERIFIED: mix --version] |
| Config file | `mix.exs` aliases and `test/test_helper.exs` [VERIFIED: mix.exs] [VERIFIED: test/test_helper.exs] |
| Quick run command | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/web/token_controller_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs -x` [VERIFIED: mix.exs] [VERIFIED: rg --files test] |
| Full suite command | `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DPoP-05 | DPoP-mode auth-code exchange validates proof, persists `cnf`, and returns `token_type: "DPoP"` | protocol + controller | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/web/token_controller_test.exs -x` | ✅ [VERIFIED: rg --files test] |
| DPoP-06 | Access and refresh tokens persist durable `cnf.jkt` suitable for later owned-surface validation | protocol + repository | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs -x` | ✅ [VERIFIED: rg --files test] |
| DPoP-07 | Refresh rotation rejects missing/wrong proof key and preserves atomic family semantics | protocol + repository | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/refresh_exchange_test.exs -x` | ✅ [VERIFIED: rg --files test] |
| DPoP-08 | Device-code redemption in DPoP mode binds at `/token` without changing host verification behavior | protocol + integration | `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs -x` | ✅ [VERIFIED: rg --files test] |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs -x` [VERIFIED: mix.exs]
- **Per wave merge:** `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/web/token_controller_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs` [VERIFIED: mix.exs]
- **Phase gate:** `MIX_ENV=test mix test.fast && MIX_ENV=test mix test.integration` [VERIFIED: mix.exs]

### Wave 0 Gaps
- None in framework setup. Existing ExUnit, repo sandbox, and integration harnesses already cover the phase surface; the work is to add new DPoP cases to existing files. [VERIFIED: mix.exs] [VERIFIED: rg --files test]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: lib/lockspire/protocol/token_exchange.ex] | Existing `ClientAuth` plus DPoP proof validation for token requests. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex] |
| V3 Session Management | no [VERIFIED: .planning/ROADMAP.md] | Phase 34 does not introduce browser session state. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes [VERIFIED: .planning/REQUIREMENTS.md] | Refresh-token family ownership, client binding, and DPoP proof-key binding checks. [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| V5 Input Validation | yes [VERIFIED: lib/lockspire/protocol/dpop.ex] | Typed claim/header validation, exact redirect URI checks, and PKCE verifier checks. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] |
| V6 Cryptography | yes [VERIFIED: lib/lockspire/protocol/dpop.ex] | JOSE verification and JWK thumbprints; never hand-roll proof verification or thumbprint logic. [VERIFIED: lib/lockspire/protocol/dpop.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DPoP proof replay at `/token` | Tampering | Reuse existing repository-backed replay store before issuance. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Wrong-key refresh redemption | Spoofing | Compare presented `jkt` to stored refresh-token `cnf.jkt` inside the rotation transaction and return public `invalid_grant`. [CITED: https://datatracker.ietf.org/doc/html/rfc9449] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |
| Drift between public response and durable token state | Repudiation | Derive `token_type` and `cnf` from one issuance context and assert both in tests. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [VERIFIED: lib/lockspire/protocol/token_exchange.ex] |
| Family-state corruption under concurrent refresh attempts | Tampering | Keep compare, revoke, rotate, and child persistence in one repository-owned transaction with row locking. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Host seam widening through device-flow DPoP prebinding | Elevation of Privilege | Bind only at token redemption; keep `/verify` state unchanged. [VERIFIED: .planning/phases/32-polling-token-issuance/32-CONTEXT.md] [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- https://datatracker.ietf.org/doc/html/rfc9449 - token-endpoint DPoP proof requirements, truthful `token_type`, refresh-token binding semantics, `cnf.jkt`, introspection truth, and optional `dpop_jkt`.
- `AGENTS.md` - project boundaries, security defaults, and locked stack versions.
- `mix.exs` and `mix.lock` - installed dependencies, versions, and test aliases.
- `lib/lockspire/protocol/token_exchange.ex` - current shared issuance, DPoP preflight, device redemption, and success/error shaping.
- `lib/lockspire/protocol/refresh_exchange.ex` - current refresh rotation owner and telemetry/audit contract.
- `lib/lockspire/protocol/dpop.ex` - validated proof and `jkt` output.
- `lib/lockspire/protocol/dpop_policy.ex` - effective DPoP policy resolver.
- `lib/lockspire/domain/token.ex`, `lib/lockspire/storage/ecto/token_record.ex`, `lib/lockspire/storage/ecto/repository.ex`, and `lib/lockspire/storage/token_store.ex` - durable `cnf` seam and atomic storage patterns.
- `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md`, `.planning/phases/32-polling-token-issuance/32-CONTEXT.md`, `.planning/phases/33-dpop-proof-validation-and-replay-state/33-RESEARCH.md`, `.planning/phases/33-dpop-proof-validation-and-replay-state/33-01-SUMMARY.md`, `.planning/phases/33-dpop-proof-validation-and-replay-state/33-02-SUMMARY.md`, `.planning/phases/33-dpop-proof-validation-and-replay-state/33-03-SUMMARY.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` - locked scope, prior decisions, and success criteria.

### Secondary (MEDIUM confidence)
- https://docs.spring.io/spring-authorization-server/reference/overview.html - current ecosystem confirmation that mature embedded/server frameworks treat DPoP-bound access tokens as a token-endpoint capability on the standard grant surface.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase uses the already-installed Phoenix/Ecto/JOSE stack and those versions were verified in `mix.lock` plus Hex API. [VERIFIED: mix.lock] [VERIFIED: hex.pm API]
- Architecture: HIGH - the relevant module seams already exist in the codebase, and RFC 9449 maps cleanly onto them. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
- Pitfalls: HIGH - each pitfall is grounded either in current code hardcoding/duplication or in RFC 9449’s mandatory behavior. [VERIFIED: lib/lockspire/protocol/token_exchange.ex] [VERIFIED: lib/lockspire/protocol/refresh_exchange.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
