# Architecture Research

**Domain:** Embedded OAuth/OIDC authorization-server library (Phoenix/Elixir) — Lockspire v1.5 RFC 7591/7592 Dynamic Client Registration slice
**Researched:** 2026-04-25
**Confidence:** HIGH (existing-codebase observations) / HIGH (RFC 7591/7592 verified against rfc-editor.org)

This document is for the v1.5 roadmapper. It answers the integration questions in the milestone brief by mapping each new concern onto Lockspire's already-established embedded shape: protocol core under `lib/lockspire/protocol/`, durable boundary under `lib/lockspire/storage/ecto/`, admin domain under `lib/lockspire/admin/`, and host-mountable Phoenix surfaces under `lib/lockspire/web/`. The dominant move is to copy the JAR/PAR pattern (server-policy singleton + per-client override + effective-policy resolver + thin controller + admin LiveView page) one more time — not to invent a new shape.

## Standard Architecture

### System Overview (DCR concerns layered on existing Lockspire)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                       Host Phoenix App (mounts Lockspire.Web.Router)      │
└──────────────────────────────────────────────────────────────────────────┘
                                      │
┌──────────────────────────────────────────────────────────────────────────┐
│                    lib/lockspire/web/  (Phoenix/Plug surface)            │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ Router  (router.ex)                                                  │ │
│ │   /authorize  /token  /par  /revoke  /introspect  /userinfo  /jwks   │ │
│ │   /.well-known/openid-configuration                                  │ │
│ │   POST   /register             ◀── NEW (RFC 7591 intake)             │ │
│ │   GET    /register/:client_id  ◀── NEW (RFC 7592 read)               │ │
│ │   PUT    /register/:client_id  ◀── NEW (RFC 7592 update)             │ │
│ │   DELETE /register/:client_id  ◀── NEW (RFC 7592 delete)             │ │
│ │   live   /admin/policies/dcr            ◀── NEW LiveView (global)    │ │
│ │   live   /admin/clients/:id (provenance + RAT panels) ◀── EXTENDED   │ │
│ │   live   /admin/iats                    ◀── NEW (initial access toks)│ │
│ └──────────────────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────┐   ┌─────────────────────────────────────────┐│
│ │ NEW: RegistrationController  ◀── thin adapter, mirrors PAR controller││
│ └─────────────────────────┘   └─────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────────┘
                                      │
┌──────────────────────────────────────────────────────────────────────────┐
│                    lib/lockspire/protocol/  (protocol truth)             │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ EXISTING:    par_policy.ex   jar_policy.ex   discovery.ex            │ │
│ │ NEW:         registration.ex      ◀── RFC 7591 metadata pipeline     │ │
│ │              dcr_policy.ex        ◀── effective-policy resolver       │ │
│ │              registration_management.ex ◀── RFC 7592 GET/PUT/DELETE   │ │
│ │              initial_access_token.ex    ◀── IAT issue/verify/redeem   │ │
│ │              registration_access_token.ex ◀── RAT issue/verify/rotate │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
                                      │
┌──────────────────────────────────────────────────────────────────────────┐
│                    lib/lockspire/admin/  (operator boundary)             │
│  EXISTING: clients.ex  server_policy.ex                                  │
│  EXTEND:   server_policy.ex (adds put_dcr_policy/2, get_dcr_policy/0)    │
│  EXTEND:   clients.ex (read-only views over self-registered clients,    │
│              revoke + RAT-rotate operator commands; provenance filter)  │
│  NEW:      initial_access_tokens.ex (issue/list/revoke IATs)             │
│  NEW:      dcr_audit.ex (or fold into existing audit emitter)            │
└──────────────────────────────────────────────────────────────────────────┘
                                      │
┌──────────────────────────────────────────────────────────────────────────┐
│                    lib/lockspire/storage/ecto/  (durable)                │
│  EXTEND:  server_policy_record.ex  (+dcr_policy fields, see §Storage)    │
│  EXTEND:  client_record.ex         (+provenance, +registration_access_   │
│                                     token_hash, +registration_client_uri,│
│                                     +initial_access_token_id, +client_   │
│                                     id_issued_at, +client_secret_        │
│                                     expires_at)                          │
│  NEW:     initial_access_token_record.ex (lockspire_initial_access_      │
│                                           tokens table)                  │
│  NEW migrations under priv/repo/migrations/                              │
└──────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities (NEW vs EXTENDED vs REUSED)

| Component | Responsibility | NEW / EXTENDED / REUSED |
|-----------|----------------|-------------------------|
| `Lockspire.Web.RegistrationController` | Thin Plug delivery: parse JSON body / Bearer header, call protocol, render JSON. Mirrors `PushedAuthorizationRequestController`. | NEW |
| `Lockspire.Web.RegistrationManagementController` (or same controller, plural actions) | RFC 7592 GET/PUT/DELETE adapter at `/register/:client_id`. | NEW |
| `Lockspire.Web.RegistrationJSON` | Renders RFC 7591 §3.2.1 client info response and RFC 7591 §3.2.2 errors; renders RFC 7592 responses (including rotated RAT). | NEW |
| `Lockspire.Protocol.Registration` | RFC 7591 metadata normalization, policy intersection, persistence, response shaping. Internally delegates to `Lockspire.Clients.register_client/1` for the actual client creation, then post-processes (RAT issue, `client_id_issued_at`, `registration_client_uri`). | NEW (orchestration) — REUSES `Lockspire.Clients` |
| `Lockspire.Protocol.RegistrationManagement` | RFC 7592 read/update/delete logic, calls `Admin.Clients.update_client/2` and `Admin.Clients.disable_client/2` under the hood; enforces RAT auth. | NEW (orchestration) — REUSES `Admin.Clients` |
| `Lockspire.Protocol.DcrPolicy` | Effective-policy resolver mirroring `ParPolicy` / `JarPolicy`: takes `ServerPolicy.t/0` (and optionally an `InitialAccessToken.t/0` whose claims may further narrow the allowlists) and returns a `Resolved` struct used by `Registration` to bound a request. | NEW (mirrors `ParPolicy`/`JarPolicy`) |
| `Lockspire.Protocol.InitialAccessToken` | Generate, hash, verify, and burn (single-use or n-use) IATs. Stateful — backed by new `lockspire_initial_access_tokens` table. | NEW |
| `Lockspire.Protocol.RegistrationAccessToken` | Generate, hash, verify against `client_record.registration_access_token_hash`, rotate-on-PUT (and optionally on GET), revoke. Stateless modulo the hash on the client row. | NEW |
| `Lockspire.Domain.ServerPolicy` | Adds DCR fields (see §Storage). | EXTENDED (one defstruct edit + typespec) |
| `Lockspire.Domain.Client` | Adds `:provenance`, `:registration_access_token_hash`, `:registration_client_uri`, `:initial_access_token_id`, `:client_id_issued_at`, `:client_secret_expires_at`. | EXTENDED |
| `Lockspire.Domain.InitialAccessToken` | New domain struct: `id`, `token_hash`, `policy_overrides` (subset of allowlists), `expires_at`, `uses_remaining`, `issued_by`, `issued_at`, `revoked_at`. | NEW |
| `Lockspire.Storage.Ecto.ClientRecord` | Schema gains the same fields as `Domain.Client`; `to_domain/1` and changesets updated. | EXTENDED |
| `Lockspire.Storage.Ecto.ServerPolicyRecord` | Singleton schema gains DCR fields. | EXTENDED |
| `Lockspire.Storage.Ecto.InitialAccessTokenRecord` | New schema + table. | NEW |
| `Lockspire.Storage.Ecto.Repository` | Adds `register_self_service_client/2`, `rotate_registration_access_token/2`, `delete_self_registered_client/1`, `list_initial_access_tokens/1`, `redeem_initial_access_token/1` (atomic decrement). | EXTENDED |
| `Lockspire.Admin.Clients` | Gains read-only filters (`list_clients(provenance: :self_registered)`), operator-side RAT rotation, and revoke-of-self-registered-client paths. Audit emission already in place — extended with new event names. | EXTENDED |
| `Lockspire.Admin.ServerPolicy` | Adds `get_dcr_policy/0`, `put_dcr_policy/1` mirroring `put_par_policy/1` and `put_jar_policy/1`. | EXTENDED |
| `Lockspire.Admin.InitialAccessTokens` | Operator commands to issue, list, revoke IATs. | NEW (small) |
| `Lockspire.Web.Live.Admin.PoliciesLive.Dcr` | LiveView page mirroring `PoliciesLive.Par` / `PoliciesLive.Jar` for the global DCR policy (allowlists, defaults, on/off, IAT requirement). | NEW |
| `Lockspire.Web.Live.Admin.IatLive.Index` / `New` | LiveView page to list/issue/revoke initial access tokens. | NEW |
| `Lockspire.Web.Live.Admin.ClientsLive.Index` | Adds a provenance column + filter; otherwise unchanged. | EXTENDED |
| `Lockspire.Web.Live.Admin.ClientsLive.Show` | Adds a "Self-registered client" panel: provenance badge, RAT issuance metadata (no plaintext after creation), "Rotate registration access token" action, IAT used to register, audit log link. | EXTENDED |
| `Lockspire.Protocol.Discovery` | Adds `"registration_endpoint"` to the `@endpoint_paths` map; advertised only when both (a) the route is mounted AND (b) the global DCR policy is `:enabled`. | EXTENDED |

### Reuse vs. New: Justifications

- **Reuse `Lockspire.Clients.register_client/1`.** The DCR controller does not call `Repository.register_client/1` directly. `Lockspire.Clients` already implements: redirect-URI validation (scheme, host, fragment, wildcard), scope-token validation, grant/response-type allowlist, PKCE-required guarantee, hashed-secret generation, observability emission for `:client_registration_succeeded` / `:client_registration_rejected`. Re-implementing that for the public endpoint would silently fork the validation surface — exactly the integrity drift v1.5 is trying to avoid.
- **Reuse `Admin.Clients.update_client/2` and `disable_client/2` for RFC 7592 PUT/DELETE.** They already enforce immutable-fields rejection, audit-event emission inside `Repository.transact/1`, and observability — RFC 7592 PUT is a strict subset of operator update with one extra constraint (the caller is authenticated by RAT, not session). The protocol module wraps these with a "treat the requester as the actor `{type: :self_registered_client, id: client_id}`" call.
- **New `DcrPolicy`, do not extend `ParPolicy` / `JarPolicy`.** These resolvers each model a single tri-state (`:inherit | :optional | :required`). DCR policy is a struct of allowlists + defaults + bool + bool; collapsing it onto the same resolver shape would distort the existing modules. But the file layout, naming, and "`Resolved` substruct returned to callers" pattern are duplicated exactly — fast to read, fast to test.
- **Reuse the `ServerPolicy` singleton row, do not create a `DcrPolicy` table.** v1.4 (JAR) added `jar_policy` directly to `lockspire_server_policies` because policy state has been monotonically additive for one server. The DCR fields are larger (allowlists are arrays, defaults are scalars, two booleans), but they are still per-installation and singleton. A separate table would be premature normalization for a row count of 1.
- **New `lockspire_initial_access_tokens` table.** IATs are not policy — they are a multi-row credential resource with their own lifecycle (issue, redeem, revoke, expire). Stuffing them onto `ServerPolicy` or onto `lockspire_clients` would make the schema lie about cardinality.
- **Extend `client_record.ex`, do not introduce a `SelfRegisteredClientRecord`.** A self-registered client is a regular client at the protocol layer — it goes through the same `/authorize`, `/token`, `/par`, `/userinfo`, `/revoke`, `/introspect` paths. The only differences are (a) origin (`:provenance`), (b) extra credentials bound to the row (`registration_access_token_hash`, `registration_client_uri`), and (c) RFC 7591 §3.2.1 timestamps (`client_id_issued_at`, `client_secret_expires_at`). A separate record kind would force every protocol callsite to handle two shapes for no gain.

## Recommended Project Structure (deltas only)

```
lib/lockspire/
├── domain/
│   ├── client.ex                         # EXTEND: add provenance + RAT/IAT/timestamp fields
│   ├── server_policy.ex                  # EXTEND: add dcr_* fields
│   └── initial_access_token.ex           # NEW
├── storage/ecto/
│   ├── client_record.ex                  # EXTEND: schema fields, changesets, to_domain/1
│   ├── server_policy_record.ex           # EXTEND: schema fields + changeset cast list
│   ├── initial_access_token_record.ex    # NEW
│   └── repository.ex                     # EXTEND: register_self_service_client, rotate_rat,
│                                         #          delete_self_registered_client, redeem_iat
├── protocol/
│   ├── dcr_policy.ex                     # NEW: resolve_effective_policy/2 (mirrors par/jar)
│   ├── registration.ex                   # NEW: RFC 7591 intake pipeline
│   ├── registration_management.ex        # NEW: RFC 7592 read/update/delete
│   ├── initial_access_token.ex           # NEW: issue/verify/redeem
│   ├── registration_access_token.ex      # NEW: issue/verify/rotate
│   └── discovery.ex                      # EXTEND: registration_endpoint advertisement gating
├── admin/
│   ├── server_policy.ex                  # EXTEND: get_dcr_policy/0, put_dcr_policy/1
│   ├── clients.ex                        # EXTEND: provenance filter, RAT-rotate command
│   ├── initial_access_tokens.ex          # NEW: operator IAT lifecycle
│   └── dcr_audit.ex                      # NEW (small) or merged into existing emitter
├── web/
│   ├── router.ex                         # EXTEND: 4 protocol routes + 3 LiveView routes
│   ├── controllers/
│   │   ├── registration_controller.ex            # NEW
│   │   ├── registration_management_controller.ex # NEW (or actions on the same controller)
│   │   └── registration_json.ex                  # NEW
│   └── live/admin/
│       ├── clients_live/
│       │   ├── index.ex                  # EXTEND: provenance column + filter
│       │   └── show.ex                   # EXTEND: self-registered panel + RAT rotate
│       ├── policies_live/
│       │   └── dcr.ex                    # NEW (mirrors par.ex / jar.ex)
│       └── iat_live/
│           ├── index.ex                  # NEW
│           └── new.ex                    # NEW (or :new live_action on index)
└── priv/repo/migrations/
    ├── 20260427xxxxxx_add_dcr_policy_to_server_policies.exs   # NEW
    ├── 20260427xxxxxx_add_dcr_fields_to_clients.exs           # NEW
    └── 20260427xxxxxx_create_initial_access_tokens.exs        # NEW
```

### Structure Rationale

- **`protocol/registration.ex` separated from `Lockspire.Clients`.** `Lockspire.Clients` is the durable-creation API (operator-tended). The DCR pipeline adds metadata-policy enforcement, IAT redemption, RAT issuance, and an HTTP-shaped response. Keeping the new module thin and *delegating* to `Lockspire.Clients.register_client/1` preserves the existing internal invariants (PKCE forced true, `:public + :none` only, `openid` cannot be in `allowed_scopes`) without copy-paste.
- **One LiveView per global policy page.** `policies_live/par.ex` and `policies_live/jar.ex` are each tightly focused state. Continuing the pattern with `policies_live/dcr.ex` keeps the operator UI predictable. Mixing DCR controls into either of the existing pages would make the policy admin grow non-locally.
- **Per-client DCR self-service controls live on `clients_live/show.ex` under a new live_action** (e.g. `:rotate_registration_access_token`) — same pattern already used for `:rotate_secret`, `:redirects`, `:par_policy`, `:jar_policy`. This is the single biggest reuse hit.
- **IAT lives outside `clients_live/` because IATs are not clients.** They are operator-issued capabilities consumed during registration. Pre-creation surfaces should not be conflated with post-creation surfaces.

## Architectural Patterns

### Pattern 1: Effective-policy resolver (mirror PAR/JAR)

**What:** Each policy axis exposes a `Lockspire.Protocol.<Axis>Policy.resolve_effective_policy/2` that takes the singleton `ServerPolicy.t/0` and a client (or IAT, for DCR) and returns a `Resolved` substruct with `global_policy`, `client_policy`, `effective_policy`, and a boolean shortcut.

**When to use:** Any per-server policy axis that may also be narrowed at a finer scope. For DCR, the finer scope is the *initial access token* (an IAT may carry per-IAT policy_overrides — e.g. "only allow scopes `read:foo`"), not a per-client override (a self-registering client has no record to override against until creation).

**Trade-offs:** Three-way fan-in (global × IAT-overrides × inbound-request) is more nuance than PAR/JAR (two-way), but the value is exactly the trust gradient operators want from IATs. If IATs are out of scope for the first DCR phase, ship the resolver with only the global axis and add IAT narrowing later — the shape composes.

**Example (sketch):**
```elixir
defmodule Lockspire.Protocol.DcrPolicy do
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.InitialAccessToken

  defmodule Resolved do
    defstruct allowed_scopes: [],
              allowed_grant_types: [],
              allowed_response_types: [],
              allowed_redirect_uri_schemes: [],
              allowed_token_endpoint_auth_methods: [],
              default_token_endpoint_auth_method: :client_secret_basic,
              self_registration_enabled?: false,
              initial_access_token_required?: false
  end

  @spec resolve_effective_policy(ServerPolicy.t(), InitialAccessToken.t() | nil) :: Resolved.t()
  def resolve_effective_policy(%ServerPolicy{} = sp, iat) do
    # Intersect server allowlists with optional IAT policy_overrides; never widen.
  end
end
```

### Pattern 2: Thin Plug controller delegating to protocol module

**What:** `RegistrationController` does only HTTP plumbing (read body, read `Authorization` header, set cache headers, set status). All semantics live in `Lockspire.Protocol.Registration`. This mirrors `PushedAuthorizationRequestController` exactly.

**When to use:** Every new public protocol endpoint in this library. Lockspire's testability rests on protocol modules being unit-testable without `conn`/Plug fixtures.

**Trade-offs:** A second module per endpoint is unavoidable overhead but it's the same pattern that makes the existing protocol surface boring and complete in isolation.

**Example (sketch):**
```elixir
def create(conn, params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  case Registration.register(%{
         params: params,
         authorization: authorization,
         opts: [client_store: Repository, iat_store: Repository,
                policy_store: Repository, audit_store: Repository]
       }) do
    {:ok, %Registration.Success{} = success} ->
      conn |> put_cache_headers() |> put_status(:created) |> json(RegistrationJSON.success(success))

    {:error, %Registration.Error{} = error} ->
      conn |> put_cache_headers() |> put_status(error.status) |> json(RegistrationJSON.error(error))
  end
end
```

### Pattern 3: Server-policy singleton + per-client override + per-IAT narrow

**What:** Three layers of policy state, each strictly *narrowing* the layer above. Server-policy is the widest legal envelope; an IAT may carve out a smaller envelope for the requests it admits; the inbound RFC 7591 request must fit inside the intersection. After creation, the client's own metadata becomes the per-client layer used at `/authorize` / `/token`.

**When to use:** Any policy axis that needs operator-controlled defaults *plus* delegated trust. DCR is exactly this — operators want to type "yes, partner X may register clients, but only with these scopes."

**Trade-offs:** More machinery than a single global flag. The Phase-22 JAR work showed that two layers (`:inherit | :optional | :required`) is barely enough; three layers needs a unit-tested resolver from day one. Defer the IAT layer if Phase 1 of v1.5 needs to ship sooner — the resolver still composes.

### Pattern 4: Provenance, not separate record kind

**What:** Add a single `:provenance` enum field on `lockspire_clients` whose values include `:operator_created` (default for existing rows; backfilled at migration time) and `:self_registered`. All filtering and audit emission keys off this field. Self-registered clients are otherwise identical at the protocol layer.

**When to use:** When the *origin* of a record matters for governance but its *behavior at runtime* does not. Lockspire's `/authorize`, `/token`, `/par`, `/userinfo` paths must be provenance-blind by construction.

**Trade-offs:** A bool would suffice for v1.5, but an enum future-proofs for `:partner_imported`, `:software_statement`, `:upstream_idp_federated` — all of which are explicitly out of scope for v1.5 but on the roadmap horizon.

### Pattern 5: Hash-at-rest for RATs (mirror client_secret hashing)

**What:** Generate the RAT plaintext server-side, return it once in the registration response body, store only `Lockspire.Security.Policy.hash_*` of it on `client_record.registration_access_token_hash`. RFC 7592 §2.1 verification compares the bearer token against the hash. Rotation = generate a new plaintext, hash it, write the hash, return the new plaintext in the response body. This is the same shape as `Lockspire.Clients.rotate_secret_hash/0`.

**When to use:** Always. Storing RAT plaintext at rest would silently break the existing security posture.

**Trade-offs:** Loss of a RAT = client cannot self-manage (must be rescued by operator-side `Admin.Clients.rotate_registration_access_token/2`, which is exactly the surface to expose in `clients_live/show.ex`). This is the right shape — operators are the recovery path.

### Pattern 6: Feature-gated discovery advertisement

**What:** `Lockspire.Protocol.Discovery.openid_configuration/0` is already truth-aware — it advertises an endpoint only when its route is mounted. For DCR, *route-mounted* is necessary but not sufficient: the endpoint must also be *policy-enabled*. Add a second gate:

```elixir
# in discovery.ex
defp registration_advertised?(endpoint_metadata) do
  Map.has_key?(endpoint_metadata, "registration_endpoint") and
    Lockspire.Admin.ServerPolicy.dcr_enabled?()
end
```

**When to use:** For any endpoint whose runtime availability is gated by operator policy, not just by route mounting. Discovery must not advertise an endpoint that returns 403 by configuration — that is a clearer SECURITY-policy claim than "routed but disabled."

**Trade-offs:** Adds a small DB read per discovery request (or a cached-config indirection — Lockspire already has `Lockspire.Config` for similar concerns). Either is acceptable; cached-config is preferable if discovery hit rate is high.

## Data Flow

### Request Flow: RFC 7591 `POST /register`

```
[Public client / partner developer]
    │  HTTP POST /register
    │   - Body: RFC 7591 client metadata JSON
    │   - Optional: Authorization: Bearer <initial_access_token>
    ↓
[Lockspire.Web.RegistrationController.create/2]
    │  - extract Authorization header
    │  - delegate to Registration.register/1
    ↓
[Lockspire.Protocol.Registration.register/1]
    │  1. resolve global ServerPolicy
    │  2. if IAT present → InitialAccessToken.verify_and_redeem/1 (or :reject)
    │  3. DcrPolicy.resolve_effective_policy(server_policy, iat)
    │  4. validate inbound metadata against Resolved policy (intersect, never widen)
    │  5. build attrs map for Lockspire.Clients.register_client/1
    │  6. delegate persistence to Lockspire.Clients (reuses validation + audit)
    │  7. RegistrationAccessToken.issue/1 → store hash on client row
    │  8. emit :dcr_client_registered audit event (with iat_id, provenance)
    ↓
[Lockspire.Storage.Ecto.Repository]
    │  Repository.transact: register client + write RAT hash + decrement IAT uses
    ↓
[Lockspire.Web.RegistrationJSON.success/1]
    │  Render RFC 7591 §3.2.1 client info response:
    │    client_id, client_secret (if confidential), client_id_issued_at,
    │    client_secret_expires_at, registration_access_token, registration_client_uri,
    │    plus all registered metadata
    ↓
[201 Created, JSON]
```

### Request Flow: RFC 7592 `PUT /register/:client_id`

```
[Self-registered client]
    │  HTTP PUT /register/:client_id
    │   - Body: full RFC 7591 metadata (RFC 7592 PUT replaces)
    │   - Authorization: Bearer <registration_access_token>
    ↓
[Lockspire.Web.RegistrationManagementController.update/2]
    ↓
[Lockspire.Protocol.RegistrationManagement.update/1]
    │  1. fetch client by :client_id
    │  2. RegistrationAccessToken.verify(rat, client.registration_access_token_hash)
    │  3. resolve effective DCR policy (global only — IAT was a one-shot)
    │  4. validate replacement metadata (intersect with policy, reject immutable
    │     fields per existing @immutable_fields list in Admin.Clients)
    │  5. delegate to Admin.Clients.update_client/2 with actor =
    │     {type: :self_registered_client, id: client_id} (audit-friendly)
    │  6. RegistrationAccessToken.rotate/1  ← per RFC 7592 SHOULD
    │  7. write new hash, emit :dcr_client_updated audit
    ↓
[200 OK, JSON]
    │  - Same shape as POST /register response
    │  - registration_access_token contains the **new** plaintext
```

Symmetric flows for `GET /register/:client_id` (no rotation; idempotent read) and `DELETE /register/:client_id` (delegates to `Admin.Clients.disable_client/2` — *we do not hard-delete* because tokens, consents, audit history reference the client_id; semantic equivalence to RFC 7592 §2.3 deletion is preserved by setting `active=false`).

### State Management: Where each piece of state lives

```
┌─────────────────────────────────────────────────────────────────────┐
│ ServerPolicy (singleton row in lockspire_server_policies)           │
│   par_policy, jar_policy (existing) +                               │
│   dcr_self_registration_enabled, dcr_initial_access_token_required, │
│   dcr_allowed_scopes[], dcr_allowed_grant_types[],                  │
│   dcr_allowed_response_types[], dcr_allowed_redirect_uri_schemes[], │
│   dcr_allowed_token_endpoint_auth_methods[],                        │
│   dcr_default_token_endpoint_auth_method,                           │
│   dcr_default_access_token_lifetime_seconds,                        │
│   dcr_default_refresh_token_lifetime_seconds,                       │
│   dcr_registration_access_token_rotate_on_update                    │
└─────────────────────────────────────────────────────────────────────┘
                              │ (singleton; one row)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ InitialAccessToken (lockspire_initial_access_tokens)                │
│   id, token_hash (unique), policy_overrides (jsonb subset of        │
│   allowlists, narrows-only), expires_at, uses_remaining,            │
│   issued_by, issued_at, revoked_at                                  │
└─────────────────────────────────────────────────────────────────────┘
                              │ (zero-or-one redeemed at registration time)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Client (lockspire_clients) — extended                               │
│   ... (all existing fields) +                                       │
│   provenance, registration_access_token_hash,                       │
│   registration_client_uri, initial_access_token_id (FK or null),    │
│   client_id_issued_at, client_secret_expires_at                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Critical invariant:** The `registration_access_token_hash` lives on `lockspire_clients`, *not* on `lockspire_initial_access_tokens`. The IAT is consumed at registration; the RAT is the long-lived management credential. They are different objects with different lifecycles.

### Key Data Flows

1. **Registration intake (POST /register):** controller → `Registration.register/1` → `Repository.transact/1` (registers client + writes RAT hash + decrements IAT atomically) → JSON response with plaintext RAT.
2. **Registration management (GET/PUT/DELETE):** controller → `RegistrationManagement.<action>/1` → reuses `Admin.Clients.{update_client, disable_client}` for write paths. Emits the same audit events (with `actor.type = :self_registered_client`) — operator audit logs see DCR mutations natively, no second pipeline.
3. **Discovery advertisement:** discovery handler reads `ServerPolicy.dcr_self_registration_enabled?/0` and routes mounted; absence of either suppresses `registration_endpoint` from `/.well-known/openid-configuration`. Truthful by construction.
4. **Operator revocation of self-registered client:** Admin LiveView → `Admin.Clients.disable_client/2` (already exists) → existing audit event; UI shows provenance badge so operator knows what kind of client they're revoking. Add an "also revoke RAT" toggle that nulls `registration_access_token_hash`.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0–100 self-registered clients (typical install) | Singleton policy, full table scan for admin filter, no caching needed. RAT verify is one indexed `client_id` lookup + bcrypt-class hash compare. |
| 100–10k self-registered clients | Add index on `(provenance, active, inserted_at desc)` for admin LiveView pagination. Cache `ServerPolicy` in `Lockspire.Config` (already has the seam). |
| 10k+ | Rate-limit POST `/register` per remote IP / per IAT (host concern, but Lockspire should expose a Plug seam). Discovery doc caching at the HTTP layer. |

### Scaling Priorities

1. **First bottleneck:** Operator admin filter UX once self-registered clients pass ~hundreds. The provenance index + LiveView pagination addresses it.
2. **Second bottleneck:** Abuse of `POST /register`. Mitigated primarily by the `initial_access_token_required` policy bit (operator's choice) and secondarily by host-app-side rate limiting. Lockspire should *not* ship a rate limiter; it should ship a Plug seam where one mounts.

## Anti-Patterns

### Anti-Pattern 1: Forking the validation surface

**What people do:** Implement RFC 7591 metadata validation inside `Protocol.Registration` as a parallel pipeline because "the operator path and the public path have different rules."
**Why it's wrong:** They have the same protocol-correctness rules — PKCE forced, no `openid` in `allowed_scopes`, `:public` ↔ `:none` exclusivity, `:confidential` ↔ basic/post exclusivity. Forking guarantees drift between operator-created and self-registered clients.
**Do this instead:** Have `Protocol.Registration` build the same attrs map and call `Lockspire.Clients.register_client/1`. Add the *additional* DCR-specific narrowing (allowlists from `DcrPolicy.Resolved`) as a *pre-filter* on the inbound metadata, before delegation.

### Anti-Pattern 2: A separate `SelfRegisteredClientRecord` schema

**What people do:** Spin up a parallel Ecto schema for self-registered clients to avoid widening the existing one.
**Why it's wrong:** `/authorize`, `/token`, `/par`, `/introspect`, `/revoke`, `/userinfo` all lookup by `client_id` and read fields — they would now have to handle two record kinds. Every protocol module would learn about provenance. The supposedly-narrow change ripples through the whole codebase.
**Do this instead:** Add `:provenance` (and the RAT/IAT/timestamp fields) to the existing `client_record.ex`. Backfill `:operator_created` for existing rows in the migration. The protocol modules stay provenance-blind; only `Admin.Clients` and the LiveView surface read provenance.

### Anti-Pattern 3: Advertising `registration_endpoint` whenever the route is mounted

**What people do:** Mirror the existing discovery pattern verbatim — "route mounted? → advertise."
**Why it's wrong:** RFC 7591 has no defined "registration disabled" error response (verified against rfc-editor.org §3.2.2 — only `invalid_redirect_uri` / `invalid_client_metadata` / `invalid_software_statement` / `unapproved_software_statement` are defined). If discovery promises `registration_endpoint` and runtime returns HTTP 403 with a generic body, integrators will read the disabled state as a transient outage and retry. Truthful discovery is a Lockspire principle (see PROJECT.md "release trust").
**Do this instead:** Gate `registration_endpoint` advertisement on `(route mounted) AND (ServerPolicy.dcr_self_registration_enabled?)`. If policy disables DCR, return HTTP 404 from the controller (treat the endpoint as not present), matching the discovery doc. Document this contract in SECURITY.md.

### Anti-Pattern 4: Reusing `client_secret` rotation as the RAT rotation primitive

**What people do:** `Admin.Clients.rotate_client_secret/2` already exists; "we'll just point it at the RAT field."
**Why it's wrong:** The two credentials authenticate different actions (one is for `/token` calls, one is for `/register/:client_id` calls), have different rotation policies (RFC 7592 says SHOULD-rotate-on-update; client_secret rotates only on operator command), and have different visibility (operator can rotate RAT on behalf of a self-registered client they're rescuing — but that operation needs its own audit event `:registration_access_token_rotated_by_operator`).
**Do this instead:** Introduce `Admin.Clients.rotate_registration_access_token/2` and `Protocol.RegistrationAccessToken.rotate/1` as *parallel-shape* but distinct functions. Code reuse at the helper level (`Lockspire.Security.Policy.hash_*` already exists), not at the boundary level.

### Anti-Pattern 5: Putting initial-access-token state on `ServerPolicy`

**What people do:** "We already have a singleton row, just add `initial_access_tokens jsonb`."
**Why it's wrong:** IATs have per-row lifecycle (issue, redeem, expire, revoke), per-row policy overrides, per-row audit. They are not configuration. JSONB-on-singleton makes operator listing a parse step, makes uniqueness on `token_hash` impossible to enforce, and makes redemption non-atomic.
**Do this instead:** Dedicated `lockspire_initial_access_tokens` table with `unique_constraint(:token_hash)` and a `Repository.redeem_initial_access_token/1` that atomically decrements `uses_remaining` in a transaction.

### Anti-Pattern 6: Letting RFC 7592 PUT bypass the existing `@immutable_fields` rejection

**What people do:** "PUT is a full replace per RFC 7592, so we should accept anything in the body."
**Why it's wrong:** `Admin.Clients` correctly rejects mutations of `client_id`, `client_type`, `token_endpoint_auth_method`, `pkce_required`, `subject_type`, `allowed_grant_types`, `allowed_response_types`, `client_secret_hash`, `active`, `disabled_at`, `disabled_by`, `last_secret_rotated_at`. RFC 7592 cannot relax these without breaking the existing security posture (e.g. flipping `:public` → `:confidential` from outside would be catastrophic).
**Do this instead:** RFC 7592 PUT goes through `Admin.Clients.update_client/2` unchanged. The protocol module rejects with `invalid_client_metadata` (RFC 7591 §3.2.2 error code) for any inbound field that hits `@immutable_fields` — same rejection list, different error name.

## Integration Points

### Internal Boundaries (NEW or EXTENDED only)

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `Web.RegistrationController` ↔ `Protocol.Registration` | Direct call; protocol returns `{:ok, %Success{}}` / `{:error, %Error{status, error, error_description}}` (mirror PAR controller's tuple shape) | Controller must map RFC 7591 §3.2.2 codes onto HTTP status (400 for `invalid_client_metadata`, 401 for missing/invalid IAT, 403 for policy-rejected). |
| `Protocol.Registration` ↔ `Lockspire.Clients.register_client/1` | Direct call inside `Repository.transact/1` | DCR pipeline pre-filters with policy, then delegates persistence. |
| `Protocol.RegistrationManagement` ↔ `Admin.Clients.{update_client, disable_client}` | Direct call with actor map `{type: :self_registered_client, id: client_id}` | Audit events flow naturally to operator audit log. |
| `Admin.ServerPolicy` ↔ `Storage.Ecto.Repository` | Same `get_server_policy/0` / `put_server_policy/1` already used by JAR/PAR | New `put_dcr_policy/1` validates allowlists then writes. |
| `Protocol.Discovery` ↔ `Admin.ServerPolicy` | Reads policy bit during `openid_configuration/0` | Cache acceptable; truthfulness is the contract. |
| `Web.Live.Admin.PoliciesLive.Dcr` ↔ `Admin.ServerPolicy` | Standard LiveView pattern (mirror `PoliciesLive.Par` and `PoliciesLive.Jar`) | No new pattern. |
| `Web.Live.Admin.IatLive.*` ↔ `Admin.InitialAccessTokens` | Standard LiveView pattern | New module on the operator side — small. |

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Host Phoenix app | Mounts `Lockspire.Web.Router` | `/register` and `/register/:client_id` become available after host re-mounts; no per-host opt-in beyond what already exists. |
| Host audit / log sinks | `Lockspire.Observability.emit/3` (existing) | New event names: `:dcr_client_registered`, `:dcr_client_registration_rejected`, `:dcr_client_updated`, `:dcr_client_deleted`, `:registration_access_token_rotated`, `:initial_access_token_issued`, `:initial_access_token_redeemed`, `:initial_access_token_revoked`. |
| Host rate limiter (optional) | Plug pipeline in host router before mounting `/register` | Lockspire does not provide one. Document this seam in SECURITY.md. |

## Build Order (Phase Sequencing)

This is the dependency-respecting order the roadmapper should expand into phases. Each level depends only on prior levels.

**Level 1 — Storage & domain (no protocol behavior yet):**
1. **DCR storage skeleton.** Migrations: add DCR fields to `lockspire_server_policies`; add `provenance` + RAT/IAT/timestamp fields to `lockspire_clients`; create `lockspire_initial_access_tokens`. Extend `Domain.Client`, `Domain.ServerPolicy`, add `Domain.InitialAccessToken`. Extend `Storage.Ecto.ClientRecord`, `ServerPolicyRecord`, add `InitialAccessTokenRecord`. Backfill existing client rows to `provenance: :operator_created`. Tests: schema round-trip + backfill correctness. *Ships nothing user-visible — is the foundation.*

**Level 2 — Policy resolver (pure, no HTTP):**
2. **`Lockspire.Protocol.DcrPolicy` resolver + `Admin.ServerPolicy.put_dcr_policy/1`.** Mirror `ParPolicy` / `JarPolicy` shape. Tests: resolver intersects allowlists; operator command validates allowlist contents; effective policy with and without IAT.

**Level 3 — Protocol pipeline (still no HTTP):**
3. **`Lockspire.Protocol.RegistrationAccessToken` and `Lockspire.Protocol.InitialAccessToken`.** Issue/verify/rotate/redeem. `Repository.redeem_initial_access_token/1` atomic decrement. Tests: hash-at-rest, single-use enforcement, rotation produces fresh plaintext.
4. **`Lockspire.Protocol.Registration.register/1`.** RFC 7591 metadata pipeline that delegates to `Lockspire.Clients.register_client/1`. Tests: policy intersect, IAT consumption, RAT issuance, RFC 7591 §3.2.1 response shape.
5. **`Lockspire.Protocol.RegistrationManagement.{read, update, delete}/1`.** RFC 7592 — delegates to `Admin.Clients`. Tests: RAT-required, immutable-field rejection passes through, RAT rotation on PUT.

**Level 4 — HTTP surface:**
6. **`/register` controller + JSON view.** Mirror `PushedAuthorizationRequestController`. Wire route in `router.ex`. Tests: integration tests through Plug.Conn for happy path + each RFC 7591 §3.2.2 error code.
7. **`/register/:client_id` controller + JSON view.** Tests: GET / PUT / DELETE with RAT bearer auth.

**Level 5 — Operator admin UI:**
8. **`PoliciesLive.Dcr` page.** Mirrors `PoliciesLive.Par` / `PoliciesLive.Jar`. Allowlists + defaults + booleans. Tests: LiveView render + form submission.
9. **`ClientsLive.Index` provenance column + filter; `ClientsLive.Show` self-registered panel + `:rotate_registration_access_token` live_action.** Tests: filter narrows correctly; RAT rotate is operator-attributed.
10. **`IatLive.Index` + `IatLive.New`.** Issue / list / revoke initial access tokens. Tests: issuance returns plaintext once; revocation prevents redemption.

**Level 6 — Discovery & docs (truthful surface):**
11. **`Lockspire.Protocol.Discovery` extension.** Gate `registration_endpoint` on `route mounted AND policy enabled`. Tests: discovery doc reflects policy.
12. **SECURITY.md / docs/operator-admin.md update.** Document the policy-bounded slice, the deferred surface (no software statements, no IdP federation, no FAPI, no JAR-04), and the host-side rate-limit seam.

**Level 7 — Closure:**
13. **End-to-end DCR scenario test** (anonymous IAT-required POST /register → token endpoint redemption → /register/:client_id rotation → operator revoke). Telemetry/audit assertions in this test.
14. **Milestone closure record + traceability matrix.** Per the existing v1.4 / v1.3 / v1.2 / v1.1 / v1.0 milestone-archival pattern.

**Reuse-vs-new audit (final):**
- *Reused intact:* `Lockspire.Clients`, `Admin.Clients.update_client`, `Admin.Clients.disable_client`, `Lockspire.Security.Policy` hashing, `Lockspire.Observability` emission, `Repository.transact/1`, `PoliciesLive.{Par,Jar}` shape, `ClientsLive.Show` live_action pattern, discovery's route-mounted truthfulness.
- *Extended:* `Domain.Client`, `Domain.ServerPolicy`, `ClientRecord`, `ServerPolicyRecord`, `Repository`, `Admin.Clients` (read filters + RAT command), `Admin.ServerPolicy`, `Discovery`, `Router`, `ClientsLive.{Index,Show}`.
- *New (justified):* `Domain.InitialAccessToken`, `InitialAccessTokenRecord`, `DcrPolicy`, `Registration`, `RegistrationManagement`, `RegistrationAccessToken`, `InitialAccessToken` (protocol module), `Admin.InitialAccessTokens`, `RegistrationController`, `RegistrationJSON`, `PoliciesLive.Dcr`, `IatLive.{Index,New}`.

## Sources

- **Existing codebase (HIGH confidence):**
  - `lib/lockspire/web/router.ex` — current route surface
  - `lib/lockspire/protocol/par_policy.ex`, `jar_policy.ex` — policy resolver pattern
  - `lib/lockspire/protocol/discovery.ex` — truthful-discovery pattern
  - `lib/lockspire/clients.ex` — existing registration validation pipeline
  - `lib/lockspire/admin/clients.ex` — `@immutable_fields`, audit emission, transact-with-audit
  - `lib/lockspire/admin/server_policy.ex` — singleton policy mutation pattern
  - `lib/lockspire/storage/ecto/{client_record,server_policy_record}.ex` — schema shape
  - `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex` — thin-controller pattern
  - `priv/repo/migrations/20260425221000_add_jar_policy_to_server_policies.exs` — additive-migration precedent

- **RFCs (HIGH confidence — fetched and quoted from rfc-editor.org):**
  - RFC 7591 §3 (initial access token is per-server policy; SHOULD allow open registration)
  - RFC 7591 §3.2.1 (response shape: client_id required, client_secret_expires_at required if secret issued, registration_access_token / registration_client_uri are RFC 7592 additions)
  - RFC 7591 §3.2.2 (defined error codes — no "registration disabled" error exists; HTTP 400 default)
  - RFC 7591 §2.3 (server MAY ignore software_statement)
  - RFC 7592 §2.1 (Bearer registration_access_token authenticates GET/PUT/DELETE)
  - RFC 7592 §2.2 (client_secret and registration_access_token MAY change on update)
  - RFC 7592 Appendix A.1 (registration_access_token SHOULD be rotated on read or update — SHOULD, not MUST)

---
*Architecture research for: RFC 7591/7592 Dynamic Client Registration integrated into Lockspire embedded library*
*Researched: 2026-04-25*
