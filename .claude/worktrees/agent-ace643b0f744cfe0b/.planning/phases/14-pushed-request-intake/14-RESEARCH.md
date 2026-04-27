# Phase 14: Pushed Request Intake - Research

**Researched:** 2026-04-24
**Domain:** OAuth 2.0 Pushed Authorization Requests (PAR) intake in an embedded Phoenix/Elixir authorization server
**Confidence:** HIGH

## User Constraints

- No `CONTEXT.md` exists for this phase, so planning must treat `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/research/SUMMARY.md`, and `AGENTS.md` as the authoritative scope inputs. [VERIFIED: gsd-sdk init.phase-op] [VERIFIED: codebase grep]
- Phase 14 is limited to `PAR-01`: a dedicated PAR endpoint, reuse of Lockspire's supported direct-call client authentication rules, and issuance of server-owned `request_uri` plus `expires_in`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Phase 14 does not include `/authorize` consumption of `request_uri`, truthful discovery publication, JAR-by-value, generic external `request_uri` support, device flow, or dynamic client registration. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: AGENTS.md]
- Lockspire must stay an embedded companion library with strong internal boundaries between protocol core, storage, Plug/Phoenix integration, and host seams. [VERIFIED: AGENTS.md]
- Security defaults that remain binding here are exact-match redirect URI validation, PKCE S256 by default, hashed client secrets at rest, no implicit flow, and strong redaction in logs and operator surfaces. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/redaction.ex]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PAR-01 | OAuth clients can submit a pushed authorization request to a dedicated PAR endpoint using Lockspire's supported direct-call client authentication rules and receive a server-issued `request_uri` plus `expires_in`. [VERIFIED: .planning/REQUIREMENTS.md] | Use a dedicated `POST` PAR controller and protocol module, authenticate with `Lockspire.Protocol.ClientAuth`, validate pushed parameters with the same rules as `/authorize`, persist a client-bound expiring request record, and return `201` JSON with `request_uri` and `expires_in`. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
</phase_requirements>

## Summary

Phase 14 should add PAR as a narrow back-channel intake surface, not as a second authorization flow. The standard requires an HTTPS `POST` endpoint that authenticates the client the same way as the token endpoint, rejects any incoming `request_uri`, validates the pushed parameters as if they had been sent to `/authorize`, and returns `201 Created` with JSON `request_uri` and `expires_in`. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]

Lockspire already has most of the pieces needed for that shape. `Lockspire.Protocol.ClientAuth` centralizes supported direct client authentication methods, `/authorize` validation already enforces exact redirect URI matching, scope checks, `response_type=code`, nonce rules, and PKCE S256, and the repo already favors durable short-lived state in Ecto tables for interactions and tokens instead of process memory. [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs]

**Primary recommendation:** Implement Phase 14 as a new protocol-owned PAR intake path with a dedicated pushed-request domain/store and Phoenix controller, reusing `ClientAuth` plus authorization-request validation, and keep `/authorize` resolution, single-use consumption, and discovery publication in Phase 15. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PAR HTTP intake (`POST` form body, JSON success/error response) | API / Backend | Frontend Server (Phoenix controller adapter) | PAR is a direct client-to-authorization-server API surface, and Lockspire's controllers are intentionally thin delivery adapters over protocol modules. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: lib/lockspire/web/controllers/authorize_controller.ex] |
| Direct client authentication reuse | API / Backend | Database / Storage | RFC 9126 applies token-endpoint client authentication rules to PAR, and Lockspire already resolves client credentials against durable client records via `ClientAuth`. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Pushed request validation | API / Backend | Database / Storage | PAR validation is authorization-request validation done before browser interaction, which matches Lockspire's existing protocol-validator ownership. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| Durable `request_uri` issuance and expiry | Database / Storage | API / Backend | The request reference must be opaque, client-bound, and expiring, which belongs in durable persistence rather than controller or process memory. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/PROJECT.md] [VERIFIED: priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs] |
| Future `/authorize` resolution and single-use enforcement | API / Backend | Database / Storage | RFC 9126 says the returned `request_uri` is a single-use reference for the later authorization request, but roadmap scope places that consumption in Phase 15, not Phase 14. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/ROADMAP.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` | Primary runtime and Mix tooling for the project test/build path. [VERIFIED: local toolchain] | The repo pins `~> 1.18` and the installed toolchain is newer-compatible, so no stack expansion is needed for PAR. [VERIFIED: mix.exs] [VERIFIED: local toolchain] |
| Phoenix | `1.8.5` | Mountable router and thin controller adapters for Lockspire web endpoints. [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Existing token, revocation, introspection, and authorize endpoints already follow the adapter pattern PAR should reuse. [VERIFIED: lib/lockspire/web/router.ex] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] |
| Ecto SQL | `3.13.5` | Durable persistence and transactional repository boundary. [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Lockspire already uses Ecto-backed durable state for clients, interactions, consent, tokens, and audit rows, which matches PAR's need for expiring request references. [VERIFIED: lib/lockspire/storage/ecto/repository.ex] [VERIFIED: priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs] |
| PostgreSQL | `14.17` locally, project target `14+` | Backing store for short-lived-but-durable protocol state and tests. [VERIFIED: local toolchain] [VERIFIED: AGENTS.md] | Phase 14 does not need another storage engine or cache; the project already treats Postgres as the default durable truth path. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | `1.4.4` | JSON encoding for PAR success and error bodies. [VERIFIED: mix.lock] | Use for the new controller JSON view/response helpers, matching existing token/introspection/revocation responses. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] |
| JOSE | `1.11.12` | Existing crypto/JWT support in the repo. [VERIFIED: mix.lock] | Do not involve JOSE in Phase 14 unless the scope is explicitly expanded to JAR or JWT client assertions beyond current support. [VERIFIED: .planning/REQUIREMENTS.md] |
| `Lockspire.Protocol.ClientAuth` | in-repo module | Shared direct client authentication for OAuth lifecycle surfaces. [VERIFIED: lib/lockspire/protocol/client_auth.ex] | Use this instead of a PAR-specific auth parser so supported methods and `WWW-Authenticate` semantics stay aligned with token-like direct endpoints. [VERIFIED: lib/lockspire/protocol/client_auth.ex] [CITED: https://www.rfc-editor.org/rfc/rfc6749.txt] |
| `Lockspire.Protocol.AuthorizationRequest` | in-repo module | Existing `/authorize` request validation rules. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] | Refactor or wrap this validator so PAR can reuse the same redirect URI, scope, response type, nonce, PKCE, and unsupported-parameter rules while deferring `request_uri` acceptance to Phase 15. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: .planning/ROADMAP.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Dedicated pushed-request table/domain | Reuse `lockspire_tokens` | Reusing tokens blurs semantics because a PAR record is not a token grant, does not belong to token lifecycle APIs, and should not inherit token-specific fields or issuance behavior. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/storage/ecto/token_record.ex] |
| Dedicated pushed-request table/domain | Reuse `lockspire_interactions` | Interactions represent browser/login/consent workflow state, while Phase 14 occurs before browser handoff and before an interaction exists. [VERIFIED: lib/lockspire/domain/interaction.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| Existing in-repo auth and validation seams | PAR-specific authentication and validation stack | That would duplicate policy and risk drift from the already-tested direct client auth and authorization-request rules. [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: test/lockspire/protocol/authorization_request_test.exs] |

**Installation:**
```bash
mix deps.get
```

No new Hex dependency is required for Phase 14. [VERIFIED: mix.exs] [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

**Version verification:** Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, Oban `2.21.1`, JOSE `1.11.12`, Jason `1.4.4`, and PostgreSQL `14.17` were verified from `mix.exs`, `mix.lock`, and the local toolchain during this research session. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: local toolchain]

## Architecture Patterns

### System Architecture Diagram

```text
OAuth Client
  |
  | POST /par (application/x-www-form-urlencoded + direct client auth)
  v
Phoenix PAR Controller
  |
  | extracts Authorization header + params
  v
PAR Protocol Module
  |
  +--> ClientAuth.authenticate(...)
  |       |
  |       v
  |    Client Store / Repository
  |
  +--> Authorization request validator
  |       |
  |       v
  |    Client policy + redirect/scope/PKCE checks
  |
  +--> PAR request builder
          |
          +--> secure random request_uri reference
          +--> durable pushed-request store (client_id + params + expires_at)
          v
       Repository transaction
          |
          v
HTTP 201 JSON
{request_uri, expires_in}
```

This flow keeps HTTP transport thin, policy in protocol modules, and durable request-reference truth in storage. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/storage/ecto/repository.ex]

### Recommended Project Structure

```text
lib/
├── lockspire/domain/pushed_authorization_request.ex      # PAR request reference state
├── lockspire/protocol/pushed_authorization_request.ex    # Auth + validation + issuance lifecycle
├── lockspire/storage/pushed_authorization_request_store.ex # Store contract
├── lockspire/storage/ecto/pushed_authorization_request_record.ex # Ecto schema
└── lockspire/web/controllers/pushed_authorization_request_controller.ex # Thin POST /par adapter

priv/repo/migrations/
└── *_create_lockspire_pushed_authorization_requests.exs  # durable table + indexes

test/lockspire/protocol/
└── pushed_authorization_request_test.exs                 # protocol success and negative paths

test/lockspire/web/
└── pushed_authorization_request_controller_test.exs      # endpoint contract
```

This structure preserves Lockspire's existing boundaries between domain, protocol, storage, and Phoenix delivery. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: lib/lockspire/storage/token_store.ex]

### Pattern 1: Thin Controller, Protocol-Owned PAR Lifecycle

**What:** The controller should only extract request headers/body, call a protocol module, then translate success/error into HTTP status and JSON. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: lib/lockspire/web/controllers/revocation_controller.ex]

**When to use:** Always for the new PAR endpoint. This matches existing endpoint design and keeps PAR rules testable without Phoenix plumbing. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: test/lockspire/web/token_controller_test.exs]

**Example:**
```elixir
# Source pattern: lib/lockspire/web/controllers/token_controller.ex
def create(conn, params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  case Lockspire.Protocol.PushedAuthorizationRequest.push(%{
         params: params,
         authorization: authorization,
         opts: [client_store: Repository, pushed_request_store: Repository]
       }) do
    {:ok, success} ->
      conn
      |> put_resp_header("cache-control", "no-cache, no-store")
      |> put_status(:created)
      |> json(%{"request_uri" => success.request_uri, "expires_in" => success.expires_in})

    {:error, error} ->
      conn
      |> put_resp_header("cache-control", "no-cache, no-store")
      |> maybe_put_www_authenticate(error)
      |> put_status(error.status)
      |> json(%{"error" => error.error, "error_description" => error.error_description})
  end
end
```

### Pattern 2: Validate Before Persisting

**What:** Authenticate the client, reject illegal PAR-only input such as incoming `request_uri`, run the same authorization-request validation rules used by `/authorize`, and only then write a pushed-request record. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

**When to use:** For every PAR submission, especially because Phase 14 success criteria forbid partial request state on invalid submissions. [VERIFIED: .planning/ROADMAP.md]

**Example:**
```elixir
# Source pattern: RFC 9126 Section 2 + existing authorization validator
with {:ok, client} <- ClientAuth.authenticate(params, authorization, client_store: store),
     :ok <- reject_request_uri_param(params),
     {:ok, validated} <- AuthorizationRequest.validate_pushed(params, client),
     {:ok, record} <- pushed_request_store.put_pushed_request(build_record(validated, client, now)) do
  {:ok, %{request_uri: record.request_uri, expires_in: expires_in}}
end
```

### Pattern 3: Dedicated Durable PAR Store

**What:** Create a pushed-request store contract and Ecto record with at least `request_uri`, `request_uri_hash` or unique reference, `client_id`, pushed params needed for later `/authorize` resolution, `expires_at`, and timestamps. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs]

**When to use:** Immediately in Phase 14, because the returned `request_uri` must be durable enough to survive the interval between PAR intake and later `/authorize` use. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/PROJECT.md]

**Example:**
```elixir
# Source pattern: lib/lockspire/storage/token_store.ex + lib/lockspire/storage/interaction_store.ex
@callback put_pushed_request(PushedAuthorizationRequest.t()) ::
            {:ok, PushedAuthorizationRequest.t()} | {:error, term()}

@callback fetch_active_pushed_request(String.t()) ::
            {:ok, PushedAuthorizationRequest.t() | nil} | {:error, term()}
```

### Anti-Patterns to Avoid

- **Do not accept `request_uri` on the PAR endpoint:** RFC 9126 requires rejecting it, and Lockspire currently also rejects `request_uri` on the browser `/authorize` validator until Phase 15 teaches consumption. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]
- **Do not persist invalid submissions:** The phase success criteria explicitly reject partial request state on invalid PAR input. [VERIFIED: .planning/ROADMAP.md]
- **Do not encode full authorization state inside the returned `request_uri`:** RFC 9126 treats it as a single-use reference, not a client-visible portable request object. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]
- **Do not relax exact redirect matching just because PAR can allow it:** RFC 9126 permits relaxation for authenticated clients, but Lockspire's project security defaults say exact-match redirect URI validation remains a preserved invariant. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]
- **Do not collapse PAR state into process memory or ETS-only caches:** the project chose durable Ecto/Postgres truth for operational clarity and protocol correctness. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Direct client authentication | A new PAR-only Basic/body auth parser | `Lockspire.Protocol.ClientAuth.authenticate/3` | The RFC says PAR uses token-endpoint auth rules, and the existing module already enforces supported methods, mixed-auth rejection, and `invalid_client` semantics. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/client_auth.ex] |
| Authorization parameter validation | Controller-local param checks | Shared authorization-request validation logic refactored for PAR reuse | Redirect URI, scope, nonce, PKCE, and unsupported-parameter policy already exist and are tested. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] [VERIFIED: test/lockspire/protocol/authorization_request_test.exs] |
| Opaque reference generation | Predictable IDs, timestamps, or database sequence exposure | `:crypto.strong_rand_bytes` + URL-safe encoding, optionally prefixed with `urn:ietf:params:oauth:request_uri:` | RFC 9126 requires a cryptographically strong unpredictable component. Lockspire already uses this pattern for opaque codes and tokens. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/token_formatter.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |
| PAR persistence | Reusing token or interaction rows opportunistically | A dedicated pushed-request domain/store/table | Tokens and interactions have different lifecycle semantics and fields, which would make later single-use enforcement and cleanup harder to reason about. [VERIFIED: lib/lockspire/storage/token_store.ex] [VERIFIED: lib/lockspire/domain/interaction.ex] |

**Key insight:** The dangerous part of PAR is not the HTTP route; it is keeping the pushed request policy identical to `/authorize` while issuing an opaque, client-bound, durable reference that cannot be guessed or partially created on failure. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/lockspire/protocol/client_auth.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

## Common Pitfalls

### Pitfall 1: Solving Phase 15 Inside Phase 14

**What goes wrong:** The implementation tries to add `/authorize?request_uri=...` consumption, single-use invalidation, and truthful discovery publication during intake work. [VERIFIED: .planning/ROADMAP.md]

**Why it happens:** PAR is one RFC, but the roadmap deliberately split intake from consumption and discovery truth. [VERIFIED: .planning/ROADMAP.md]

**How to avoid:** Limit Phase 14 to storing the validated pushed request plus returning `request_uri` and `expires_in`; leave resolution and one-time consumption enforcement to Phase 15. [VERIFIED: .planning/ROADMAP.md]

**Warning signs:** Any Phase 14 diff touching `Lockspire.Protocol.Discovery` or teaching `AuthorizationRequest` to accept `request_uri` at `/authorize` time is probably scope creep. [VERIFIED: lib/lockspire/protocol/discovery.ex] [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

### Pitfall 2: Duplicating Validation Rules

**What goes wrong:** PAR accepts parameters the browser path would reject, or rejects parameters the browser path would accept. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]

**Why it happens:** The team writes a second validator instead of reusing or extracting the existing authorization-request validator. [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

**How to avoid:** Extract shared validation helpers so PAR and `/authorize` both depend on the same redirect URI, scope, nonce, response type, and PKCE checks. [VERIFIED: lib/lockspire/protocol/authorization_request.ex]

**Warning signs:** Parallel validation codepaths start carrying separate scope or PKCE tests. [VERIFIED: test/lockspire/protocol/authorization_request_test.exs]

### Pitfall 3: Treating `request_uri` as a Portable Payload

**What goes wrong:** The server returns a reference that embeds raw request data or is guessable. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]

**Why it happens:** Predictable identifiers or payload-bearing references can look simpler than a durable opaque lookup.

**How to avoid:** Return an opaque random reference and keep the pushed request data server-side in Postgres. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/PROJECT.md]

**Warning signs:** Reviewers can infer the client, redirect URI, or scopes by looking at the returned `request_uri`. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]

### Pitfall 4: Wrong Error Semantics for Client Auth Failures

**What goes wrong:** Header-based auth failures return `400` without `WWW-Authenticate`, or mixed-auth cases create inconsistent error bodies. [CITED: https://www.rfc-editor.org/rfc/rfc6749.txt]

**Why it happens:** The new endpoint bypasses `ClientAuth` or does not mirror token-like error handling. [VERIFIED: lib/lockspire/protocol/client_auth.ex]

**How to avoid:** Reuse `ClientAuth` and set `WWW-Authenticate` when `invalid_client` is returned for Authorization-header attempts. [VERIFIED: lib/lockspire/protocol/client_auth.ex] [CITED: https://www.rfc-editor.org/rfc/rfc6749.txt]

**Warning signs:** PAR controller tests diverge from token/introspection/revocation controller patterns. [VERIFIED: lib/lockspire/web/controllers/token_controller.ex] [VERIFIED: lib/lockspire/web/controllers/introspection_controller.ex] [VERIFIED: lib/lockspire/web/controllers/revocation_controller.ex]

## Code Examples

Verified patterns from official sources and current repo seams:

### PAR Success Shape
```http
# Source: RFC 9126 Section 2.2
HTTP/1.1 201 Created
Content-Type: application/json
Cache-Control: no-cache, no-store

{
  "request_uri": "urn:ietf:params:oauth:request_uri:opaque-reference",
  "expires_in": 60
}
```

### Shared Direct Client Auth Reuse
```elixir
# Source: lib/lockspire/protocol/client_auth.ex
authorization = List.first(get_req_header(conn, "authorization"))

with {:ok, client} <-
       ClientAuth.authenticate(params, authorization, client_store: Repository) do
  # continue PAR validation and persistence
end
```

### Secure Opaque Reference Generation
```elixir
# Source pattern: lib/lockspire/protocol/token_formatter.ex
reference =
  32
  |> :crypto.strong_rand_bytes()
  |> Base.url_encode64(padding: false)

request_uri = "urn:ietf:params:oauth:request_uri:" <> reference
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Front-channel authorization request carries all parameters through the browser | Back-channel PAR `POST` stores the request and passes only a server-issued `request_uri` through the browser | RFC 9126, 2021 [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] | Reduces front-channel leakage and lets the server authenticate/validate before user interaction. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] |
| Looser redirect URI matching was historically tolerated in parts of OAuth 2.0 | Exact redirect matching is the project default, and RFC 9126 only permits relaxation as an option for authenticated clients | OAuth security BCP era, reflected in RFC 9126 Section 2.4 [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] | Lockspire should keep exact-match redirect validation even after PAR lands. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| Ad hoc endpoint-specific auth handling | Shared direct endpoint auth module reused across token-like API surfaces | Existing Lockspire architecture [VERIFIED: lib/lockspire/protocol/client_auth.ex] | PAR can land with less policy drift and less new negative-path logic. [VERIFIED: lib/lockspire/protocol/client_auth.ex] |

**Deprecated/outdated:**

- Treating PAR as a reason to add generic external `request_uri` or JAR-by-value support in the same phase is outdated relative to this milestone's deliberately narrow wedge. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs` will be the right quick-run command once the new test files exist. [ASSUMED] | Validation Architecture | Low. The planner may need to rename the files or adjust the command to the final module/file names. |
| A2 | `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/storage/repository_test.exs` will be the right negative-path command split once the new test files exist. [ASSUMED] | Validation Architecture | Low. Only the exact file selection may change. |

## Open Questions

1. **What `expires_in` should Lockspire ship for PAR in v1.2?**
   - What we know: RFC 9126 says the lifetime is at the server's discretion and is typically short, for example 5-600 seconds. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]
   - What's unclear: The project docs do not yet lock a concrete default such as 60 or 90 seconds. [VERIFIED: codebase grep]
   - Recommendation: Pick a boring fixed default in Phase 14, expose it internally as protocol config if needed later, and keep it short enough that stale references expire quickly without forcing flaky browser round-trips. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]

2. **Should the store keep both plaintext `request_uri` and a hashed lookup key?**
   - What we know: Lockspire hashes opaque tokens before durable lookup, but the RFC only requires unpredictability and client binding for PAR references. [VERIFIED: lib/lockspire/protocol/token_formatter.ex] [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]
   - What's unclear: The project has not yet established whether PAR references should follow the token-hash-at-rest pattern or whether plaintext URNs are acceptable because they are shorter-lived and not reused as bearer credentials. [VERIFIED: codebase grep]
   - Recommendation: Decide this during planning. A hashed lookup key is more aligned with Lockspire's existing opaque-token posture, but it adds one more transform and test surface. [VERIFIED: lib/lockspire/protocol/token_formatter.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Compile, tests, migrations | ✓ [VERIFIED: local toolchain] | `Elixir 1.19.5`, `Mix 1.19.5` [VERIFIED: local toolchain] | — |
| PostgreSQL CLI | Test DB visibility and local validation | ✓ [VERIFIED: local toolchain] | `14.17` [VERIFIED: local toolchain] | — |
| Phoenix/Ecto deps | Runtime and test patterns already in repo | ✓ [VERIFIED: mix.lock] | `phoenix 1.8.5`, `ecto_sql 3.13.5` [VERIFIED: mix.lock] | — |

**Missing dependencies with no fallback:**

- None found during research. [VERIFIED: local toolchain]

**Missing dependencies with fallback:**

- None found during research. [VERIFIED: local toolchain]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` with Ecto SQL Sandbox-backed integration tests. [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] [VERIFIED: local toolchain] |
| Config file | [`test/test_helper.exs`](/Users/jon/projects/lockspire/test/test_helper.exs), [`config/test.exs`](/Users/jon/projects/lockspire/config/test.exs) |
| Quick run command | `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs` [ASSUMED] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PAR-01 | Valid PAR submission returns `201` with opaque `request_uri` and `expires_in`, using supported direct client auth. [VERIFIED: .planning/REQUIREMENTS.md] | protocol + controller integration | `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs` [ASSUMED] | ❌ Wave 0 |
| PAR-01 | Invalid PAR submission rejects mixed auth, bad redirect URI, missing PKCE, incoming `request_uri`, and unknown client without durable partial state. [VERIFIED: .planning/ROADMAP.md] [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] | protocol + repository integration | `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/storage/repository_test.exs` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/web/pushed_authorization_request_controller_test.exs` [ASSUMED]
- **Per wave merge:** `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green plus the new PAR protocol/controller tests before `/gsd-verify-work`. [VERIFIED: .planning/PROJECT.md]

### Wave 0 Gaps

- [ ] `test/lockspire/protocol/pushed_authorization_request_test.exs` - covers PAR-01 protocol success and negative paths. [VERIFIED: codebase grep]
- [ ] `test/lockspire/web/pushed_authorization_request_controller_test.exs` - covers HTTP contract, cache headers, and `WWW-Authenticate` behavior. [VERIFIED: codebase grep]
- [ ] `priv/repo/migrations/*_create_lockspire_pushed_authorization_requests.exs` - adds durable schema for PAR references. [VERIFIED: codebase grep]
- [ ] `lib/lockspire/storage/pushed_authorization_request_store.ex` - formal storage contract. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: .planning/REQUIREMENTS.md] | Reuse `Lockspire.Protocol.ClientAuth` and existing supported direct auth methods. [VERIFIED: lib/lockspire/protocol/client_auth.ex] |
| V3 Session Management | no [VERIFIED: AGENTS.md] | Host app owns end-user session/login UX; PAR intake is a client-to-server direct call. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] | Bind each `request_uri` to the posting client and later reject wrong-client use. Phase 14 stores the binding; Phase 15 consumes it. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: .planning/ROADMAP.md] |
| V5 Input Validation | yes [VERIFIED: lib/lockspire/protocol/authorization_request.ex] | Reuse authorization-request validation for redirect URI, scopes, response type, nonce, PKCE, and unsupported params. [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| V6 Cryptography | yes [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] | Generate the opaque request reference with `:crypto.strong_rand_bytes`; never hand-roll predictable IDs. [VERIFIED: lib/lockspire/protocol/token_formatter.ex] [VERIFIED: lib/lockspire/protocol/authorization_flow.ex] |

### Known Threat Patterns for Phoenix + OAuth PAR

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Client impersonation through forged PAR submission | Spoofing | Require the same direct client auth rules as token endpoint requests and return `invalid_client` correctly. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/client_auth.ex] |
| Redirect URI abuse | Tampering | Keep exact-match redirect URI validation from the existing authorization validator. [VERIFIED: AGENTS.md] [VERIFIED: lib/lockspire/protocol/authorization_request.ex] |
| Guessable or enumerable `request_uri` | Information Disclosure / Elevation of Privilege | Use cryptographically strong random references and store only server-side request data. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/protocol/token_formatter.ex] |
| Partial-state creation on invalid requests | Tampering | Validate before writing and wrap writes in repository transactions when side effects expand. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/lockspire/storage/ecto/repository.ex] |
| Sensitive request metadata leaking into logs/telemetry | Information Disclosure | Keep telemetry/audit metadata redacted and avoid emitting raw secrets or full opaque values. [VERIFIED: lib/lockspire/observability.ex] [VERIFIED: lib/lockspire/redaction.ex] |

## Sources

### Primary (HIGH confidence)

- RFC 9126 - OAuth 2.0 Pushed Authorization Requests - checked endpoint rules, success/error response shape, `request_uri` generation requirements, client binding, expiry guidance, and later single-use expectations. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt]
- RFC 6749 - OAuth 2.0 Authorization Framework - checked `invalid_client` and `WWW-Authenticate` semantics reused by PAR through token-endpoint auth rules. [CITED: https://www.rfc-editor.org/rfc/rfc6749.txt]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/research/SUMMARY.md`, `AGENTS.md` - checked phase scope, milestone boundaries, embedded-library constraints, and security defaults. [VERIFIED: codebase grep]
- `lib/lockspire/protocol/client_auth.ex`, `lib/lockspire/protocol/authorization_request.ex`, `lib/lockspire/web/controllers/token_controller.ex`, `lib/lockspire/storage/ecto/repository.ex`, `priv/repo/migrations/20260422000100_create_lockspire_core_tables.exs` - checked current auth, validation, thin-controller, and durable-storage patterns to reuse. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- RFC 8414 - OAuth 2.0 Authorization Server Metadata - checked current metadata registry context for later discovery work and parity with existing Lockspire discovery fields. [CITED: https://www.rfc-editor.org/rfc/rfc8414.txt]

### Tertiary (LOW confidence)

- None. All implementation-critical claims in this research were verified from official specs or the current repo. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - Phase 14 can stay on the existing Phoenix/Ecto/Postgres stack with no new dependency decision. [VERIFIED: mix.exs] [VERIFIED: mix.lock]
- Architecture: HIGH - The repo already demonstrates the controller/protocol/storage split that PAR should follow, and RFC 9126 is explicit about intake behavior. [CITED: https://www.rfc-editor.org/rfc/rfc9126.txt] [VERIFIED: lib/lockspire/web/controllers/token_controller.ex]
- Pitfalls: MEDIUM - The main risks are clear from scope boundaries and spec language, but hashed-at-rest treatment for PAR references still needs a project decision. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: lib/lockspire/protocol/token_formatter.ex]

**Research date:** 2026-04-24
**Valid until:** 2026-05-24
