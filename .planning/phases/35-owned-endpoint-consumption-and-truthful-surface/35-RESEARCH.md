# Phase 35: Owned Endpoint Consumption and Truthful Surface - Research

**Researched:** 2026-04-28
**Domain:** DPoP-bound protected-resource consumption, OIDC discovery truth, and client token-mode configuration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `userinfo` must support both bearer and DPoP access, but any access token with durable
  DPoP binding state in `Token.cnf` is accepted only through the DPoP authentication scheme:
  `Authorization: DPoP <access_token>` plus a `DPoP` proof header.
- **D-02:** A DPoP-bound access token presented as `Authorization: Bearer ...` must be rejected
  rather than silently downgraded to bearer behavior on Lockspire-owned endpoints.
- **D-03:** Bearer-mode access tokens remain supported on `userinfo` exactly as they work today so
  existing clients stay unchanged unless they explicitly opt into DPoP mode.
- **D-04:** `userinfo` remains a Lockspire-owned protected-resource surface only. Do not broaden
  Phase 35 into generic host-resource validation helpers.
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
- **D-09:** Discovery should advertise only the shipped DPoP slice and only once the repo-owned
  endpoint surface supports it: DPoP token requests plus Lockspire-owned `userinfo` consumption.
- **D-10:** Discovery metadata should add `dpop_signing_alg_values_supported`, sourced from the
  actual DPoP validator allowlist rather than a hand-maintained docs-only list.
- **D-11:** Docs and support-surface copy must stay explicit that Lockspire proves DPoP only on
  the endpoints it owns in-repo; generic host protected-resource middleware remains out of scope.
- **D-12:** Release/support contract tests should remain the enforcement backstop for DPoP claims
  so public wording cannot drift ahead of repo proof.
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
- **D-18:** `userinfo` should return standards-shaped authentication failures rather than inventing
  provider-specific DPoP errors for this phase.
- **D-19:** When authentication is missing, malformed, or mismatched for a DPoP-bound token,
  `userinfo` should challenge in a way that reflects DPoP capability and acceptable algorithms,
  while keeping bearer-mode failures truthful for bearer clients.

### Claude's Discretion

- Exact internal module/file shape for shared protected-resource DPoP validation may be chosen
  during planning as long as protocol logic stays centralized and controllers stay thin.
- Exact split between shared helper functions and `userinfo`-specific orchestration may be chosen
  during planning if it avoids duplicating token-endpoint DPoP logic.
- Exact wording of docs/test assertions may evolve during planning so long as the support contract
  remains narrow and repo-truthful.

### Deferred Ideas (OUT OF SCOPE)

- Generic host-app protected-resource middleware or helper plugs for DPoP-bound token validation
- DPoP nonce support
- Broader sender-constrained or "token security posture" admin consolidation
- Compatibility modes that tolerate DPoP-bound access tokens over bearer auth on Lockspire-owned
  endpoints
- Protected-resource metadata publication beyond the current discovery/support contract
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DPoP-09 | `userinfo` accepts DPoP-bound access tokens only when the accompanying proof validates against the token's stored binding state. [VERIFIED: .planning/REQUIREMENTS.md] | Extend `Lockspire.Protocol.Userinfo` into a token-mode-aware protected-resource orchestrator that branches on durable `Token.cnf`, requires `Authorization: DPoP` plus `DPoP` header for bound tokens, validates `ath`, and records replay via the existing replay store seam. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] [VERIFIED: lib/lockspire/domain/token.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
| DPoP-10 | Discovery metadata and support docs advertise only the shipped DPoP slice, including truthful supported proof signing algorithms and endpoint behavior. [VERIFIED: .planning/REQUIREMENTS.md] | Keep discovery route-truth based, add `dpop_signing_alg_values_supported` only when both `/token` and `/userinfo` are mounted, source algorithms from `Lockspire.Protocol.DPoP`, and update docs/release-contract tests together. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
| DPoP-11 | Operator and DCR flows can explicitly configure client token mode for bearer vs DPoP without repo-internal edits. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing durable enums in `ServerPolicy` and `Client`, mirror the PAR admin workflow for global/client DPoP controls, and map RFC 9449 `dpop_bound_access_tokens` into `client.dpop_policy` on DCR register/read/update paths. [VERIFIED: lib/lockspire/domain/client.ex] [VERIFIED: lib/lockspire/domain/server_policy.ex] [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: lib/lockspire/admin/server_policy.ex] [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/protocol/registration_management.ex] [VERIFIED: lib/lockspire/web/registration_json.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep Lockspire as an embedded companion library inside a host Phoenix app; do not turn this phase into standalone auth-service behavior. [VERIFIED: AGENTS.md]
- Preserve strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam narrow: account resolution, claims, login redirects, branding, and product policy remain host-owned. [VERIFIED: AGENTS.md]
- Preserve secure defaults already locked for the project: PKCE S256 by default, exact redirect URI matching, single-use short-lived authorization codes, refresh rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]

## Summary

Phase 35 should be planned as three narrow extensions of existing seams, not as a new DPoP subsystem. `Lockspire.Protocol.Userinfo` is currently bearer-only and only parses `Authorization: Bearer ...`; `Lockspire.Web.UserinfoController` is a thin adapter; `Lockspire.Protocol.TokenEndpointDPoP` already centralizes proof validation, URI canonicalization, and replay recording for `/token`; `Lockspire.Protocol.Discovery` already publishes route-truth metadata; and DPoP policy enums already exist on both `Client` and `ServerPolicy`. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/domain/client.ex] [VERIFIED: lib/lockspire/domain/server_policy.ex]

RFC 9449 makes the protected-resource part of this phase non-optional: DPoP-protected resource requests must include both the DPoP proof and the access token, the proof must include a valid `ath`, DPoP-bound access tokens use the `DPoP` authorization scheme, and the resource server must deny access unless the proof checks and token binding checks all succeed. The same RFC also registers `dpop_signing_alg_values_supported` for authorization-server metadata and `dpop_bound_access_tokens` for dynamic client registration metadata. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]

The largest repo risk is semantic drift across surfaces, not cryptography. Today the codebase has no `ath` handling, no `Authorization: DPoP` parsing on `userinfo`, no discovery publication of DPoP algorithms, no DCR mapping for `dpop_bound_access_tokens`, and no admin DPoP LiveView parallel to the shipped PAR policy pattern. That makes the roadmap split clean and implementation-ready: `35-01` userinfo protected-resource enforcement, `35-02` discovery/docs/release-contract truth, and `35-03` operator+DCR token-mode configuration. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/web/live/admin/policies_live/par.ex] [VERIFIED: .planning/ROADMAP.md]

**Primary recommendation:** Reuse `Lockspire.Protocol.DPoP` plus a small shared protected-resource helper for proof validation, add one exported algorithm source for discovery/challenges, and map all admin/DCR token-mode state through the existing durable `dpop_policy` enums rather than metadata blobs or host middleware. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: lib/lockspire/admin/server_policy.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Parse `Authorization` scheme and `DPoP` header on `GET /userinfo` | API / Backend | — | The controller should stay a thin Phoenix adapter that forwards request context to protocol code, following the current `userinfo` and `/token` patterns. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] |
| Validate protected-resource DPoP proof (`typ`, `alg`, `htm`, `htu`, `iat`, `jti`, `ath`) | API / Backend | Database / Storage | Proof semantics belong in protocol code; replay acceptance remains repository-backed. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
| Determine bearer vs DPoP mode for `userinfo` from durable token state | API / Backend | Database / Storage | Phase 35 explicitly locks mode resolution to `Token.cnf`, not mutable policy lookup alone. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] [VERIFIED: lib/lockspire/domain/token.ex] |
| Publish truthful discovery metadata and DPoP algorithm support | API / Backend | — | `Lockspire.Protocol.Discovery` already owns truth-based metadata assembly from mounted routes and config. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/protocol/discovery_test.exs] |
| Persist and mutate server/client token mode | Database / Storage | API / Backend | Durable `dpop_policy` enums already live on the singleton server-policy row and client rows. [VERIFIED: lib/lockspire/domain/server_policy.ex] [VERIFIED: lib/lockspire/domain/client.ex] |
| Expose global/client token-mode controls to operators | Frontend Server (SSR) | API / Backend | LiveView admin pages are already the repo-standard operator surface for global policy and per-client overrides. [VERIFIED: lib/lockspire/web/live/admin/policies_live/par.ex] [VERIFIED: lib/lockspire/web/live/admin/clients_live/show.ex] |
| Accept and emit RFC 9449 DCR token-mode metadata | API / Backend | Database / Storage | Registration and registration-management protocol modules already own DCR intake/update/read semantics. [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/protocol/registration_management.ex] [VERIFIED: lib/lockspire/web/registration_json.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.5` [VERIFIED: AGENTS.md] | Thin HTTP/controller and LiveView delivery surface for `userinfo`, discovery, and admin pages. [VERIFIED: AGENTS.md] | Phase 35 extends existing mounted endpoints and LiveView policy screens rather than adding a new service. [VERIFIED: lib/lockspire/web/router.ex] |
| Phoenix LiveView | `1.1.28` [VERIFIED: AGENTS.md] | Global and per-client operator configuration UI. [VERIFIED: AGENTS.md] | The shipped PAR policy workflow is already the narrow UX precedent for DPoP policy. [VERIFIED: lib/lockspire/web/live/admin/policies_live/par.ex] [VERIFIED: lib/lockspire/web/live/admin/clients_live/form_component.ex] |
| Ecto SQL | `3.13.5` [VERIFIED: AGENTS.md] | Durable access-token `cnf` truth, replay storage, server policy, and client policy persistence. [VERIFIED: AGENTS.md] | Phase 35 depends on durable token/client/server-policy state rather than transport-only inference. [VERIFIED: lib/lockspire/domain/token.ex] [VERIFIED: lib/lockspire/domain/client.ex] [VERIFIED: lib/lockspire/domain/server_policy.ex] |
| JOSE | `1.11.12` [VERIFIED: mix.lock] | DPoP proof verification and JWK thumbprints. [VERIFIED: lib/lockspire/protocol/dpop.ex] | The repo already uses JOSE for all DPoP proof work; Phase 35 should not add another crypto seam. [VERIFIED: lib/lockspire/protocol/dpop.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| PostgreSQL | `14+` [VERIFIED: AGENTS.md] | Durable replay and token binding state. [VERIFIED: AGENTS.md] | Use for replay rejection and token/client/server-policy truth across restarts and nodes. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] |
| ExUnit | `1.19.5` [VERIFIED: elixir --version] | Controller, protocol, LiveView, and release-contract proof. [VERIFIED: test/test_helper.exs] | Use for all three Phase 35 plans; the repo already has protocol, web, live, integration, and contract test lanes. [VERIFIED: rg --files test] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One protocol-owned protected-resource helper shared by `userinfo` | Controller-local DPoP parsing in `UserinfoController` | Rejected because the repo keeps HTTP adapters thin and already centralizes DPoP validation in protocol code. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] |
| Existing durable `dpop_policy` enums on `ServerPolicy` and `Client` | Storing token-mode intent in `client.metadata` JSON | Rejected by locked decision D-13 and by current enum validation/update seams already proven in tests. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: test/lockspire/admin/clients_test.exs] |
| `Registration`/`RegistrationManagement` mapping RFC metadata to `dpop_policy` | Leaving `dpop_bound_access_tokens` in metadata JSON only | Rejected because read/update/write behavior would drift and repo-internal edits would still be required to change effective token mode. [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/protocol/registration_management.ex] [VERIFIED: lib/lockspire/web/registration_json.ex] |

**Installation:** No new dependency is required for Phase 35; use the existing Phoenix/LiveView/Ecto/JOSE stack already pinned in the project. [VERIFIED: AGENTS.md] [VERIFIED: mix.lock]

**Version verification:** This phase reuses project-pinned stack versions rather than introducing a new package. Phoenix `1.8.5`, LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, and JOSE `1.11.12` were verified from repo/runtime context in this session. [VERIFIED: AGENTS.md] [VERIFIED: mix.lock] [VERIFIED: elixir --version]

## Architecture Patterns

### System Architecture Diagram

```text
GET /userinfo
  |
  | Authorization: Bearer <token>      OR      Authorization: DPoP <token>
  | DPoP: <proof JWT>                          (required only for bound tokens)
  v
UserinfoController
  |
  | auth header + dpop header + method + canonical userinfo URI + repo opts
  v
Userinfo protocol
  |
  +--> parse auth scheme
  +--> fetch active access token by opaque hash
  +--> inspect token.cnf
        |
        +--> cnf absent ------------> bearer path (existing behavior)
        |
        +--> cnf["jkt"] present ----> DPoP path
              |
              +--> validate proof fundamentals
              +--> validate ath against raw access token
              +--> compare proof.jkt to token.cnf.jkt
              +--> record replay use
  |
  +--> resolve host claims
  +--> build scope-bounded userinfo response
  v
200 JSON or standards-shaped 401/400 challenge

/.well-known/openid-configuration
  |
  v
Discovery protocol
  |
  +--> mounted route truth
  +--> registration-policy truth
  +--> DPoP algorithm truth from validator allowlist
  v
truthful metadata + docs/release-contract alignment

/admin + /register
  |
  +--> LiveView global/client policy screens
  +--> DCR register/update/read JSON
  v
server_policy.dpop_policy + client.dpop_policy durable truth
```

### Recommended Project Structure

```text
lib/
├── lockspire/protocol/
│   ├── userinfo.ex                    # protected-resource orchestration
│   ├── dpop.ex                        # canonical proof validator + exported algorithm list
│   ├── token_endpoint_dpop.ex         # replay/URI/helpers worth reusing
│   ├── discovery.ex                   # route-truth metadata builder
│   ├── registration.ex                # DCR create-path metadata mapping
│   └── registration_management.ex     # DCR read/update-path metadata mapping
├── lockspire/web/controllers/
│   ├── userinfo_controller.ex         # thin adapter, auth-header extraction
│   └── discovery_controller.ex        # unchanged thin adapter
└── lockspire/web/live/admin/
    ├── policies_live/dpop.ex          # new global DPoP policy page
    └── clients_live/                  # add per-client DPoP override route/form

test/
├── lockspire/protocol/userinfo_test.exs
├── lockspire/web/userinfo_controller_test.exs
├── lockspire/protocol/discovery_test.exs
├── lockspire/web/discovery_controller_test.exs
├── lockspire/web/live/admin/policies_live/dpop_test.exs
├── lockspire/web/live/admin/clients_live_test.exs
└── lockspire/protocol/registration*_test.exs
```

### Pattern 1: Make `userinfo` Token-Mode Aware from Durable `cnf`
**What:** Fetch the opaque access token first, then branch by `token.cnf`: bearer path for `nil`, DPoP path for `%{"jkt" => ...}`. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/domain/token.ex]
**When to use:** Any Lockspire-owned protected-resource surface that consumes opaque access tokens in this milestone. [VERIFIED: .planning/ROADMAP.md]
**Use:** This preserves bearer defaults while preventing DPoP-bound tokens from silently authenticating as bearer. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]

**Example:**
```elixir
# Source: repo seam + RFC 9449 protected-resource rules
with {:ok, scheme, raw_token} <- parse_authorization(request),
     {:ok, %Token{} = token} <- fetch_access_token(raw_token, request) do
  case token.cnf do
    %{"jkt" => _expected_jkt} -> validate_dpop_userinfo_request(scheme, raw_token, token, request)
    _ -> validate_bearer_userinfo_request(scheme, token)
  end
end
```

### Pattern 2: Export DPoP Algorithm Truth Once and Reuse It
**What:** Add a small exported function from `Lockspire.Protocol.DPoP` for the supported algorithm allowlist, then consume it from discovery metadata and `WWW-Authenticate` challenge construction. [VERIFIED: lib/lockspire/protocol/dpop.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
**When to use:** Discovery publication and DPoP protected-resource challenges. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]
**Use:** This avoids one list in code for validation and a second drifting list in discovery/docs/challenges. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex]

**Example:**
```elixir
# Source: RFC 9449 Section 5.1 + current repo discovery builder
metadata =
  if dpop_surface_shipped?(endpoint_metadata) do
    Map.put(base_metadata, "dpop_signing_alg_values_supported", DPoP.signing_alg_values_supported())
  else
    base_metadata
  end
```

### Pattern 3: Mirror PAR for Admin, Mirror RFC 9449 for DCR
**What:** Add a global `/admin/policies/dpop` page plus per-client edit route, and map DCR `dpop_bound_access_tokens` onto `client.dpop_policy` for create/read/update. [VERIFIED: lib/lockspire/web/live/admin/policies_live/par.ex] [VERIFIED: lib/lockspire/web/live/admin/clients_live/form_component.ex] [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/web/registration_json.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
**When to use:** Operator-managed policy rollout and self-registered client configuration. [VERIFIED: .planning/ROADMAP.md]
**Use:** One durable truth model prevents admin and DCR from describing different token-mode state for the same client. [VERIFIED: lib/lockspire/domain/client.ex] [VERIFIED: lib/lockspire/admin/clients.ex]

### Anti-Patterns to Avoid
- **Bearer downgrade of bound tokens:** Reject `Authorization: Bearer` for tokens with `cnf.jkt`; do not silently accept them on `userinfo`. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
- **Controller-owned DPoP logic:** Keep parsing/validation out of `UserinfoController`; the protocol layer should stay the correctness owner. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex]
- **Hand-maintained DPoP metadata lists:** Do not hard-code discovery algorithms separately from the validator. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex]
- **DCR metadata blobs as policy truth:** `dpop_bound_access_tokens` must change `client.dpop_policy`, not just `client.metadata`. [VERIFIED: lib/lockspire/domain/client.ex] [VERIFIED: lib/lockspire/protocol/registration.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Protected-resource proof validation | A second JWT/JOSE checker just for `userinfo` | `Lockspire.Protocol.DPoP` plus a thin protected-resource wrapper for `ath` and token-binding checks [VERIFIED: lib/lockspire/protocol/dpop.ex] | The hard parts already exist; Phase 35 only adds resource-specific checks and challenge behavior. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
| DPoP algorithm advertisement | A discovery-only allowlist constant | Export the actual validator allowlist from `Lockspire.Protocol.DPoP` [VERIFIED: lib/lockspire/protocol/dpop.ex] | Validation truth and discovery truth must stay coupled. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
| Client token-mode persistence | New JSON metadata conventions | Existing `:bearer | :dpop | :inherit` enums on server/client state [VERIFIED: lib/lockspire/domain/server_policy.ex] [VERIFIED: lib/lockspire/domain/client.ex] | The repo already validates and persists these values cleanly. [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: lib/lockspire/admin/server_policy.ex] |
| DCR token-mode exposure | Provider-specific registration fields | RFC 9449 `dpop_bound_access_tokens` [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] | Keeps the public surface standards-shaped and predictable for clients. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] |
| Generic protected-resource middleware | Host-app DPoP plug/helpers | Lockspire-owned `userinfo` only in this phase [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] | Broadening here would violate the embedded-library boundary and roadmap scope. [VERIFIED: AGENTS.md] |

**Key insight:** The repo already solved token issuance truth in Phase 34. Phase 35’s job is to consume that durable truth consistently on owned surfaces and surface it honestly in metadata, docs, admin, and DCR APIs. [VERIFIED: .planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

## Common Pitfalls

### Pitfall 1: Accepting Bound Tokens Through the Bearer Scheme
**What goes wrong:** A DPoP-bound token with `cnf.jkt` is accepted as `Authorization: Bearer ...` because the code only checks token existence. [VERIFIED: lib/lockspire/protocol/userinfo.ex]
**Why it happens:** Current `userinfo` is bearer-only and does not inspect `Token.cnf`. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/domain/token.ex]
**How to avoid:** Fetch the token first, branch on durable `cnf`, and require the DPoP auth scheme plus proof for bound tokens. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]
**Warning signs:** Tests only cover missing bearer token and happy-path bearer claims; no DPoP-mode negative-path cases exist yet. [VERIFIED: test/lockspire/web/userinfo_controller_test.exs]

### Pitfall 2: Reusing Token-Endpoint Validation Without Adding `ath`
**What goes wrong:** `userinfo` verifies signature, `htm`, `htu`, freshness, and replay, but still accepts a proof not bound to the presented access token value. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
**Why it happens:** `Lockspire.Protocol.DPoP` currently validates `htm`, `htu`, `iat`, and `jti`, but there is no `ath` helper or protected-resource wrapper yet. [VERIFIED: lib/lockspire/protocol/dpop.ex]
**How to avoid:** Add a protected-resource validation layer that hashes the raw opaque token and compares it to proof `ath` before claim resolution. [VERIFIED: lib/lockspire/protocol/token_formatter.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
**Warning signs:** New code calls `DPoP.validate_proof/2` directly from `userinfo` and immediately proceeds to claims without an access-token hash check. [VERIFIED: lib/lockspire/protocol/dpop.ex]

### Pitfall 3: Publishing DPoP Metadata Before Both Owned Surfaces Exist
**What goes wrong:** Discovery advertises DPoP capability because `/token` supports it, even if `userinfo` and docs still do not. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]
**Why it happens:** `Lockspire.Protocol.Discovery` already merges metadata from mounted-route truth, but it has no DPoP surface gate yet. [VERIFIED: lib/lockspire/protocol/discovery.ex]
**How to avoid:** Gate `dpop_signing_alg_values_supported` on the exact shipped DPoP slice for this milestone: token requests plus Lockspire-owned `userinfo`. [VERIFIED: .planning/ROADMAP.md] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
**Warning signs:** Discovery changes land without matching `userinfo` controller/protocol tests and docs/contract-test updates in the same wave. [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

### Pitfall 4: DCR Create/Read/Update Drift
**What goes wrong:** Registration create accepts `dpop_bound_access_tokens`, but read/update omit it, or admin changes `dpop_policy` while DCR responses still reflect stale metadata. [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/protocol/registration_management.ex] [VERIFIED: lib/lockspire/web/registration_json.ex]
**Why it happens:** Current DCR code only preserves `client_uri` in extension metadata and does not derive DPoP metadata from `client.dpop_policy`. [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: lib/lockspire/protocol/registration_management.ex] [VERIFIED: lib/lockspire/web/registration_json.ex]
**How to avoid:** Treat `dpop_bound_access_tokens` as first-class mapped state on create, read, and update. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
**Warning signs:** Tests cover DCR metadata only through `client_uri` or generic metadata, not token-mode fields. [VERIFIED: test/lockspire/web/registration_json_test.exs]

### Pitfall 5: Docs and Contract Tests Lag Repo Truth
**What goes wrong:** Public copy claims more or less than the repo actually proves, and the release-contract tests do not catch the exact DPoP wording. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] [VERIFIED: docs/supported-surface.md] [VERIFIED: SECURITY.md]
**Why it happens:** Current release-contract coverage is oriented around prior milestones and does not mention DPoP yet. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]
**How to avoid:** Update docs and the release-contract backstop together in `35-02`, with wording limited to token-endpoint DPoP plus Lockspire-owned `userinfo`. [VERIFIED: .planning/ROADMAP.md]
**Warning signs:** `docs/supported-surface.md` or `SECURITY.md` changes without corresponding assertions in `test/lockspire/release_readiness_contract_test.exs`. [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Code Examples

Verified patterns from official sources and existing repo seams:

### Protected-Resource DPoP Validation
```elixir
# Source: RFC 9449 Sections 4.3 and 7.1 + existing Lockspire DPoP/token seams
with {:ok, "DPoP", raw_token} <- parse_dpop_authorization(request),
     {:ok, %Token{} = token} <- fetch_active_access_token(raw_token, request),
     %{"jkt" => expected_jkt} <- token.cnf,
     {:ok, proof} <- DPoP.validate_proof(proof_jwt, method: "GET", target_uri: userinfo_uri(), now: now, max_age: 300, clock_skew: 30),
     :ok <- validate_ath(proof.claims, raw_token),
     :ok <- ensure_jkt_matches(expected_jkt, proof.jkt),
     :ok <- record_replay_use(proof, request) do
  resolve_claims(token)
end
```

### Truth-Based Discovery Merge
```elixir
# Source: existing Discovery.openid_configuration/0 pattern + RFC 9449 metadata
endpoint_metadata = mounted_endpoint_metadata()

base =
  %{
    "issuer" => Config.issuer!(),
    "grant_types_supported" => grant_types_supported(endpoint_metadata)
  }
  |> Map.merge(endpoint_metadata)

if Map.has_key?(endpoint_metadata, "token_endpoint") and
     Map.has_key?(endpoint_metadata, "userinfo_endpoint") do
  Map.put(base, "dpop_signing_alg_values_supported", DPoP.signing_alg_values_supported())
else
  base
end
```

### DCR Mapping for `dpop_bound_access_tokens`
```elixir
# Source: RFC 9449 Section 5.2 + current Registration / RegistrationJSON seams
defp dpop_policy_from_metadata(%{"dpop_bound_access_tokens" => true}), do: :dpop
defp dpop_policy_from_metadata(_metadata), do: :bearer

client = %Client{client | dpop_policy: dpop_policy_from_metadata(metadata)}

payload =
  base_payload(client)
  |> Map.put(:dpop_bound_access_tokens, client.dpop_policy == :dpop)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Bearer-only opaque token consumption on `userinfo` [VERIFIED: lib/lockspire/protocol/userinfo.ex] | DPoP-bound tokens must use the `DPoP` auth scheme plus proof with `ath` on protected-resource requests. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] | RFC 9449, September 2023 [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] | Phase 35 must treat `userinfo` as a real DPoP protected resource, not a bearer exception. [VERIFIED: .planning/ROADMAP.md] |
| Hand-maintained capability wording in docs | Route-truth metadata plus release-contract-tested support claims. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Lockspire phases 15, 19, 27, and 31 established the pattern. [VERIFIED: .planning/PROJECT.md] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] | Phase 35 should extend the existing truth-based publication model, not invent a DPoP-specific docs process. [VERIFIED: .planning/ROADMAP.md] |
| Provider-specific token-mode metadata | RFC 9449 `dpop_bound_access_tokens` for DCR clients. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] | RFC 9449, September 2023 [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] | Phase 35 can expose DPoP mode cleanly without widening the public API shape. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] |

**Deprecated/outdated:**
- Bearer-only `userinfo` assumptions for all access tokens are outdated once `Token.cnf.jkt` is present. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/domain/token.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]
- A docs-only DPoP algorithm list would be outdated by design because the validator already owns the true allowlist. [VERIFIED: lib/lockspire/protocol/dpop.ex]

## Assumptions Log

All claims in this research were verified or cited — no user confirmation needed.

## Open Questions (RESOLVED)

1. **Should `userinfo` return dual `WWW-Authenticate` challenges or only `DPoP` when a bound token is missing proof?**
   - What we know: RFC 9449 allows `DPoP` challenges and notes that a resource supporting both bearer and DPoP may return multiple challenges; current Lockspire `userinfo` only returns a single Bearer challenge. [VERIFIED: lib/lockspire/web/controllers/userinfo_controller.ex] [CITED: https://datatracker.ietf.org/doc/html/rfc9449]
   - Resolved: Keep Phase 35 narrow by returning a DPoP challenge for bound-token failures and preserving the current Bearer challenge for unbound-token failures. Do not add dual challenges in this phase because the repo has no existing mixed-challenge helper and the narrower split is already consistent with the phase context. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]

2. **Should discovery publish DPoP metadata when `/userinfo` is mounted but DPoP is only opt-in by policy?**
   - What we know: Discovery already publishes capabilities, not per-client effective policy, and Phase 35 wants truthful advertisement of the shipped slice rather than “required for everyone” semantics. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md]
   - Resolved: Publish DPoP capability once the repo-owned surfaces support it and keep policy-specific requirement semantics in admin/DCR docs, mirroring the PAR truth pattern. Discovery stays capability-oriented; policy remains operator/client-specific. [VERIFIED: lib/lockspire/web/live/admin/policies_live/par.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix test and Phoenix app execution | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | Repo test aliases and phase verification commands | ✓ [VERIFIED: `mix --version`] | `1.19.5` / OTP 28 [VERIFIED: `mix --version`] | — |
| Node.js | Existing docs/release workflow tooling | ✓ [VERIFIED: `node --version`] | `v22.14.0` [VERIFIED: `node --version`] | — |
| npm | Existing release tooling/runtime | ✓ [VERIFIED: `npm --version`] | `11.1.0` [VERIFIED: `npm --version`] | — |
| PostgreSQL CLI | Local DB inspection/test environment | ✓ [VERIFIED: `psql --version`] | `14.17` [VERIFIED: `psql --version`] | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix test stack [VERIFIED: mix.exs] |
| Config file | `config/test.exs`, `test/test_helper.exs` [VERIFIED: rg --files] |
| Quick run command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |
| Full suite command | `mix ci` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DPoP-09 | `userinfo` accepts bearer tokens unchanged and DPoP-bound tokens only with valid bound proof, `ath`, and replay handling. [VERIFIED: .planning/REQUIREMENTS.md] | protocol + controller | `MIX_ENV=test mix test test/lockspire/protocol/userinfo_test.exs test/lockspire/web/userinfo_controller_test.exs -x` | ❌ Wave 0 |
| DPoP-10 | Discovery, support docs, and release contract advertise only the shipped DPoP slice and supported algorithms. [VERIFIED: .planning/REQUIREMENTS.md] | protocol + controller + contract | `MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs -x` | ✅ / ❌ mixed |
| DPoP-11 | Global/client admin flows and DCR register/read/update paths can configure and reflect bearer vs DPoP mode. [VERIFIED: .planning/REQUIREMENTS.md] | liveview + protocol + web | `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/web/registration_json_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test <phase-targeted files> -x` [VERIFIED: repo test layout]
- **Per wave merge:** `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs]
- **Phase gate:** `mix ci` before `/gsd-verify-work` [VERIFIED: mix.exs]

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/userinfo_test.exs` — protocol-owned DPoP/bearer branching, `ath`, and replay coverage for DPoP-09. [VERIFIED: rg --files test]
- [ ] `test/lockspire/web/live/admin/policies_live/dpop_test.exs` — global DPoP policy LiveView route and persistence proof for DPoP-11. [VERIFIED: rg --files test]
- [ ] Extend `test/lockspire/web/userinfo_controller_test.exs` — add DPoP auth-scheme, missing-proof, bad-`ath`, and bound-token-bearer-downgrade cases for DPoP-09. [VERIFIED: test/lockspire/web/userinfo_controller_test.exs]
- [ ] Extend `test/lockspire/web/live/admin/clients_live_test.exs` — add client DPoP override edit/show coverage for DPoP-11. [VERIFIED: test/lockspire/web/live/admin/clients_live_test.exs]
- [ ] Extend `test/lockspire/protocol/discovery_test.exs`, `test/lockspire/web/discovery_controller_test.exs`, and `test/lockspire/release_readiness_contract_test.exs` — add DPoP metadata/docs truth checks for DPoP-10. [VERIFIED: test/lockspire/protocol/discovery_test.exs] [VERIFIED: test/lockspire/web/discovery_controller_test.exs] [VERIFIED: test/lockspire/release_readiness_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: lib/lockspire/protocol/userinfo.ex] | Opaque token lookup plus DPoP proof validation and auth-scheme enforcement. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex] |
| V3 Session Management | no [VERIFIED: AGENTS.md] | Host app owns end-user sessions; this phase does not change that seam. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes [VERIFIED: lib/lockspire/protocol/userinfo.ex] | Scope-bounded userinfo claims plus DPoP binding checks on bound tokens. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] |
| V5 Input Validation | yes [VERIFIED: lib/lockspire/protocol/dpop.ex] | Typed claim/header checks, scheme parsing, and metadata enum validation. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/admin/clients.ex] |
| V6 Cryptography | yes [VERIFIED: lib/lockspire/protocol/dpop.ex] | JOSE signature verification, JWK thumbprints, and SHA-256 token/`ath` hashing; never hand-roll crypto. [VERIFIED: lib/lockspire/protocol/dpop.ex] [VERIFIED: lib/lockspire/protocol/token_formatter.ex] |

### Known Threat Patterns for Lockspire's Phase 35 Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DPoP-bound token replayed with bearer auth | Spoofing | Require `Authorization: DPoP` and reject bearer downgrade for tokens with `cnf.jkt`. [VERIFIED: .planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md] |
| Proof replay on `userinfo` | Tampering | Reuse durable replay store recording on the protected-resource path. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] |
| Access-token substitution without `ath` | Tampering | Hash the raw presented access token and compare it to proof `ath`. [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt] [VERIFIED: lib/lockspire/protocol/token_formatter.ex] |
| Discovery/doc overclaiming beyond mounted behavior | Repudiation | Gate metadata on route truth and enforce support wording in release-contract tests. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| Admin/DCR policy drift | Elevation of Privilege | Keep one durable enum model and one set of validation rules for both operator and DCR paths. [VERIFIED: lib/lockspire/admin/clients.ex] [VERIFIED: lib/lockspire/protocol/registration.ex] |

## Sources

### Primary (HIGH confidence)
- https://www.rfc-editor.org/rfc/rfc9449.txt - protected-resource DPoP rules, `ath`, `DPoP` auth scheme, `dpop_signing_alg_values_supported`, and `dpop_bound_access_tokens`.
- https://openid.net/specs/openid-connect-discovery-1_0.html - OIDC discovery document requirements and `userinfo_endpoint` metadata.
- `lib/lockspire/protocol/userinfo.ex` - current bearer-only userinfo protocol seam.
- `lib/lockspire/web/controllers/userinfo_controller.ex` - current `userinfo` controller challenge behavior.
- `lib/lockspire/protocol/dpop.ex` - canonical DPoP validator and algorithm allowlist source.
- `lib/lockspire/protocol/token_endpoint_dpop.ex` - replay recording, URI handling, and existing DPoP orchestration.
- `lib/lockspire/protocol/discovery.ex` - current truth-based discovery builder.
- `lib/lockspire/protocol/registration.ex`, `lib/lockspire/protocol/registration_management.ex`, `lib/lockspire/web/registration_json.ex` - current DCR create/read/update surfaces and metadata behavior.
- `lib/lockspire/admin/clients.ex`, `lib/lockspire/admin/server_policy.ex`, `lib/lockspire/web/live/admin/policies_live/par.ex`, `lib/lockspire/web/live/admin/clients_live/form_component.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex` - durable DPoP policy seams and admin UX precedents.

### Secondary (MEDIUM confidence)
- `test/lockspire/web/userinfo_controller_test.exs`, `test/lockspire/web/discovery_controller_test.exs`, `test/lockspire/web/live/admin/clients_live_test.exs`, `test/lockspire/protocol/discovery_test.exs`, and `test/lockspire/release_readiness_contract_test.exs` - current proof boundaries and drift fences.
- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-CONTEXT.md`, `.planning/phases/34-token-issuance-and-refresh-device-binding/34-CONTEXT.md`, `.planning/phases/34-token-issuance-and-refresh-device-binding/34-RESEARCH.md` - milestone scope, prior locked decisions, and sequencing.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new library choice is required; the phase extends already-pinned Phoenix/LiveView/Ecto/JOSE seams. [VERIFIED: AGENTS.md] [VERIFIED: mix.lock]
- Architecture: HIGH - the repo already has clear boundaries for protocol, discovery, DCR, storage, and LiveView admin, and the roadmap split maps directly onto them. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/protocol/registration.ex] [VERIFIED: .planning/ROADMAP.md]
- Pitfalls: HIGH - the main failure modes are directly visible in the current repo gaps and in RFC 9449 protected-resource requirements. [VERIFIED: lib/lockspire/protocol/userinfo.ex] [VERIFIED: lib/lockspire/protocol/dpop.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9449.txt]

**Research date:** 2026-04-28
**Valid until:** 2026-05-28
