# Phase 84: host-plug-pipeline-docs-and-milestone-closure - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
| --- | --- | --- | --- | --- |
| `lib/lockspire/web/protected_resource_challenge.ex` | utility | request-response | `lib/lockspire/web/controllers/userinfo_controller.ex` | partial |
| `lib/lockspire/plug/enforce_sender_constraints.ex` | middleware | request-response | `lib/lockspire/protocol/protected_resource_dpop.ex` | data-flow-match |
| `lib/lockspire/plug/require_token.ex` | middleware | request-response | `lib/lockspire/web/controllers/userinfo_controller.ex` | role-match |
| `lib/lockspire/web/controllers/userinfo_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/token_controller.ex` | role-match |
| `test/lockspire/plug/enforce_sender_constraints_test.exs` | test | request-response | `test/lockspire/web/userinfo_controller_test.exs` | data-flow-match |
| `test/lockspire/plug/require_token_test.exs` | test | request-response | `test/lockspire/web/userinfo_controller_test.exs` | data-flow-match |
| `test/integration/phase81_generated_host_route_protection_e2e_test.exs` | test | request-response | `test/integration/phase81_generated_host_route_protection_e2e_test.exs` | exact |
| `test/lockspire/release_readiness_contract_test.exs` | test | transform | `test/lockspire/release_readiness_contract_test.exs` | exact |
| `docs/protect-phoenix-api-routes.md` | doc | request-response | `docs/install-and-onboard.md` | role-match |
| `docs/supported-surface.md` | doc | transform | `docs/protect-phoenix-api-routes.md` | role-match |

## Pattern Assignments

### `lib/lockspire/web/protected_resource_challenge.ex` (utility, request-response)

**Analog:** `lib/lockspire/web/controllers/userinfo_controller.ex`

**Why this match:** This inferred helper should stay transport-only and extract the exact shared response-shaping now duplicated between `/userinfo` and `RequireToken`.

**Imports / adapter boundary** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:6)):
```elixir
use Phoenix.Controller, formats: [:json]

alias Lockspire.Protocol.Userinfo
alias Lockspire.Protocol.Userinfo.Error
alias Lockspire.Storage.Ecto.Repository
alias Lockspire.Web.UserinfoJSON
```

**Shared nonce/header exposure shape** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:60)):
```elixir
defp put_dpop_nonce(conn, %Error{dpop_nonce: nonce}) when is_binary(nonce) and nonce != "" do
  conn
  |> put_resp_header("dpop-nonce", nonce)
  |> expose_header("DPoP-Nonce")
  |> expose_header("WWW-Authenticate")
end
```

**Shared DPoP challenge formatting** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:78)):
```elixir
defp www_authenticate_value(%Error{error: "use_dpop_nonce"}) do
  profile =
    case Lockspire.Storage.Ecto.Repository.get_server_policy() do
      {:ok, policy} -> policy.security_profile
      _ -> :none
    end

  algorithms = Enum.join(Lockspire.Protocol.DPoP.signing_alg_values_supported(profile), " ")

  ~s(DPoP realm="Lockspire Userinfo", error="use_dpop_nonce", error_description="Resource server requires nonce in DPoP proof", algs="#{algorithms}")
end
```

**Secondary analog for header helper** ([lib/lockspire/web/controllers/token_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/token_controller.ex:61)):
```elixir
defp maybe_put_dpop_nonce(conn, %Error{dpop_nonce: nonce}) when is_binary(nonce) and nonce != "" do
  conn
  |> put_resp_header("dpop-nonce", nonce)
  |> expose_header("DPoP-Nonce")
end
```

Planner note: keep this helper internal to web/adapter code. Do not move any validation or nonce issuance into it.

---

### `lib/lockspire/plug/enforce_sender_constraints.ex` (middleware, request-response)

**Analog:** `lib/lockspire/protocol/protected_resource_dpop.ex`

**Imports / seam ownership** ([lib/lockspire/plug/enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:10)):
```elixir
alias Lockspire.AccessToken
alias Lockspire.Protocol.MTLSTokenBinding
alias Lockspire.Protocol.ProtectedResourceDPoP
```

**Request-building pattern** ([lib/lockspire/plug/enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:80)):
```elixir
request = %{
  authorization_scheme: access_token.authorization_scheme,
  access_token: access_token.token,
  dpop: header_value(conn, "dpop"),
  method: conn.method,
  target_uri: request_target_uri(conn),
  opts: [
    dpop_replay_store: Keyword.get(opts, :dpop_replay_store),
    dpop_max_age: Keyword.get(opts, :dpop_max_age, 300),
    dpop_clock_skew: Keyword.get(opts, :dpop_clock_skew, 30),
    now: Keyword.get(opts, :now, &DateTime.utc_now/0)
  ]
}
```

**Soft-failure propagation** ([lib/lockspire/plug/enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:95)):
```elixir
case ProtectedResourceDPoP.validate_access(access_token, request) do
  {:ok, proof} ->
    {:ok, proof}

  {:error, error} ->
    {:error, sender_error(:dpop, error)}
end
```

**Protocol contract to preserve** ([lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:66)):
```elixir
case DPoP.validate_proof(
       proof,
         method: request_method(request),
         target_uri: target_uri,
         now: now(request),
         max_age: Keyword.get(request_options(request), :dpop_max_age, 300),
         clock_skew: Keyword.get(request_options(request), :dpop_clock_skew, 30),
         security_profile: security_profile,
         nonce_purpose: :resource_server,
         secret_key_base: Keyword.get(request_options(request), :secret_key_base),
         nonce_max_age: Keyword.get(request_options(request), :dpop_nonce_max_age, 300)
     ) do
  {:ok, %DPoP{} = validated_proof} ->
    {:ok, validated_proof}

  {:error, reason} when reason in [:missing_dpop_nonce, :invalid_dpop_nonce] ->
    {:error, use_dpop_nonce_error(reason, request)}
```

**Typed nonce outcome source** ([lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:321)):
```elixir
defp use_dpop_nonce_error(reason_code, request) do
  %Error{
    status: 401,
    error: "use_dpop_nonce",
    error_description: "Resource server requires nonce in DPoP proof",
    reason_code: reason_code,
    dpop_nonce: DPoPNonce.issue(:resource_server, secret_key_base: secret_key_base(request))
  }
end
```

Planner note: Phase 84 should extend the plug request opts with endpoint secret material, not reimplement nonce logic.

---

### `lib/lockspire/plug/require_token.ex` (middleware, request-response)

**Analog:** `lib/lockspire/web/controllers/userinfo_controller.ex`

**Strict boundary branch structure** ([lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:19)):
```elixir
case conn.assigns[:access_token] do
  %AccessToken{error: nil, claims: claims} when not is_nil(claims) ->
    conn

  %AccessToken{error: :missing_token} ->
    handle_missing_token(conn)

  %AccessToken{error: error} when is_map(error) ->
    handle_structured_error(conn, error)
```

**Normalize typed errors before rendering** ([lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:63)):
```elixir
defp handle_structured_error(conn, %{category: :sender_constraint} = error),
  do: handle_invalid_token(conn, normalize_sender_error(error))

defp handle_structured_error(conn, %{category: :insufficient_scope} = error),
  do: handle_insufficient_scope(conn, normalize_insufficient_scope_error(error))
```

**Current challenge rendering to align with shared helper** ([lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:114)):
```elixir
defp www_authenticate(%{challenge: :dpop, error: error, error_description: description}) do
  algorithms = Enum.join(DPoP.signing_alg_values_supported(), " ")

  ~s(DPoP realm="Lockspire", error="#{error}", error_description="#{description}", algs="#{algorithms}")
end
```

**Current nonce/header exposure to extract** ([lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:140)):
```elixir
defp maybe_put_dpop_nonce(conn, %{dpop_nonce: nonce}) when is_binary(nonce) and nonce != "" do
  conn
  |> put_resp_header("dpop-nonce", nonce)
  |> expose_header("DPoP-Nonce")
  |> expose_header("WWW-Authenticate")
end
```

**Reference controller path with same transport concern** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:34)):
```elixir
{:error, %Error{} = error} ->
  conn
  |> put_cache_headers()
  |> put_dpop_nonce(error)
  |> put_www_authenticate(error)
  |> put_status(error.status)
  |> json(UserinfoJSON.error_response(error))
```

---

### `lib/lockspire/web/controllers/userinfo_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/token_controller.ex`

**Thin adapter input passing** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:13)):
```elixir
case Userinfo.fetch_claims(%{
       authorization: authorization,
       dpop: List.first(get_req_header(conn, "dpop")),
       method: conn.method,
       opts: [
         token_store: Repository,
         dpop_replay_store: Repository,
         server_policy_store: Repository,
         secret_key_base: conn.secret_key_base,
         mtls_cert: conn.private[:lockspire_mtls_cert]
       ]
     }) do
```

**Thin controller success/error envelope** ([lib/lockspire/web/controllers/token_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/token_controller.ex:33)):
```elixir
{:ok, %Success{} = success} ->
  conn
  |> put_cache_headers()
  |> put_status(:ok)
  |> json(TokenJSON.access_token_response(success))

{:error, %Error{} = error} ->
  conn
  |> put_cache_headers()
  |> maybe_put_dpop_nonce(error)
  |> maybe_put_www_authenticate(error)
  |> put_status(error.status)
  |> json(TokenJSON.error_response(error))
```

**Current DPoP-specific response logic to collapse into helper** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:50)):
```elixir
defp put_www_authenticate(conn, %Error{status: 401, error: "invalid_token"} = error) do
  put_resp_header(conn, "www-authenticate", www_authenticate_value(error))
end

defp put_www_authenticate(conn, %Error{status: 401, error: "use_dpop_nonce"} = error) do
  put_resp_header(conn, "www-authenticate", www_authenticate_value(error))
end
```

**Algorithm/profile drift seam** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:78)):
```elixir
profile =
  case Lockspire.Storage.Ecto.Repository.get_server_policy() do
    {:ok, policy} -> policy.security_profile
    _ -> :none
  end

algorithms = Enum.join(Lockspire.Protocol.DPoP.signing_alg_values_supported(profile), " ")
```

Planner note: preserve `secret_key_base: conn.secret_key_base` in the request opts; that is the owned-surface precedent the host plug path should match.

---

### `test/lockspire/plug/enforce_sender_constraints_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/userinfo_controller_test.exs`

**Soft-failure propagation assertions** ([test/lockspire/plug/enforce_sender_constraints_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/enforce_sender_constraints_test.exs:82)):
```elixir
assert %{
         category: :sender_constraint,
         challenge: :dpop,
         reason_code: :invalid_dpop_authorization_scheme
       } = bearer_conn.assigns.access_token.error

assert %{reason_code: :missing_dpop_proof} = missing_proof_conn.assigns.access_token.error
refute missing_proof_conn.halted
```

**Nonce propagation assertion** ([test/lockspire/plug/enforce_sender_constraints_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/enforce_sender_constraints_test.exs:120)):
```elixir
assert %{reason_code: :missing_dpop_nonce, error: "use_dpop_nonce", dpop_nonce: nonce} =
         conn.assigns.access_token.error

assert is_binary(nonce)
```

**Reference end-to-end nonce proof** ([test/lockspire/web/userinfo_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/userinfo_controller_test.exs:233)):
```elixir
assert conn.status == 401
[challenge] = get_resp_header(conn, "www-authenticate")
assert challenge =~ "error=\"use_dpop_nonce\""
assert [nonce] = get_resp_header(conn, "dpop-nonce")
assert is_binary(nonce)
```

---

### `test/lockspire/plug/require_token_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/userinfo_controller_test.exs`

**Strict challenge assertions** ([test/lockspire/plug/require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:69)):
```elixir
[challenge] = get_resp_header(conn, "www-authenticate")
assert challenge =~ "DPoP realm=\"Lockspire\""
assert challenge =~ "error=\"invalid_token\""
assert challenge =~ "error_description=\"A valid DPoP proof is required\""
assert challenge =~ "algs=\""
```

**Nonce header exposure assertions** ([test/lockspire/plug/require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:98)):
```elixir
assert conn.halted
assert conn.status == 401
assert ["retry-nonce"] = get_resp_header(conn, "dpop-nonce")
assert Enum.any?(get_resp_header(conn, "access-control-expose-headers"), &(&1 =~ "DPoP-Nonce"))
[challenge] = get_resp_header(conn, "www-authenticate")
assert challenge =~ "error=\"use_dpop_nonce\""
```

**401 vs 403 split to preserve** ([test/lockspire/plug/require_token_test.exs](/Users/jon/projects/lockspire/test/lockspire/plug/require_token_test.exs:148)):
```elixir
assert conn.status == 401
assert [
         "Bearer realm=\"Lockspire\", error=\"invalid_token\", error_description=\"The access token audience is invalid for this route\""
       ] = get_resp_header(conn, "www-authenticate")
```

```elixir
assert conn.status == 403
assert [
         "Bearer realm=\"Lockspire\", error=\"insufficient_scope\", error_description=\"The access token is missing a required scope\", scope=\"read:billing write:reports\""
       ] = get_resp_header(conn, "www-authenticate")
```

---

### `test/integration/phase81_generated_host_route_protection_e2e_test.exs` (test, request-response)

**Analog:** `test/integration/phase81_generated_host_route_protection_e2e_test.exs`

**Generated-host endpoint setup** ([test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:19)):
```elixir
Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
  secret_key_base: String.duplicate("a", 64),
  server: false
)
```

**Nonce challenge and retry proof shape** ([test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:175)):
```elixir
challenge_conn =
  protected_conn()
  |> put_req_header("authorization", "DPoP #{token}")
  |> put_req_header("dpop", generate_dpop_proof(dpop_keys.private_jwk, token, nil))
  |> get(@protected_route)

assert challenge_conn.status == 401
[nonce_challenge] = get_resp_header(challenge_conn, "www-authenticate")
assert nonce_challenge =~ "error=\"use_dpop_nonce\""
assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")
```

**Retry acceptance proof** ([test/integration/phase81_generated_host_route_protection_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase81_generated_host_route_protection_e2e_test.exs:186)):
```elixir
proof = generate_dpop_proof(dpop_keys.private_jwk, token, retry_nonce)

success_conn =
  protected_conn()
  |> put_req_header("authorization", "DPoP #{token}")
  |> put_req_header("dpop", proof)
  |> get(@protected_route)

assert success_conn.status == 200
```

Planner note: keep this as the milestone-closing proof. Extend, do not duplicate a larger negative matrix here.

---

### `test/lockspire/release_readiness_contract_test.exs` (test, transform)

**Analog:** `test/lockspire/release_readiness_contract_test.exs`

**Docs-as-contract assertion style** ([test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:436)):
```elixir
assert supported_surface =~ "Host Phoenix API route protection"
assert supported_surface =~ "Lockspire.Plug.VerifyToken"
assert supported_surface =~ "Lockspire.Plug.RequireToken"
assert supported_surface =~ "scopes:` and `audience:` / `audiences:` restrictions"
assert supported_surface =~ "host Phoenix API routes protected by the shipped plug pipeline"
assert supported_surface =~ "bearer clients remaining unchanged by default"
```

**Out-of-scope fence style** ([test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:443)):
```elixir
assert supported_surface =~
         "Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope"
```

**Guide assertions to mirror when docs change** ([test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:450)):
```elixir
assert protected_routes_guide =~ "Lockspire.Plug.VerifyToken"
assert protected_routes_guide =~ "Lockspire.Plug.EnforceSenderConstraints"
assert protected_routes_guide =~ "Lockspire.Plug.RequireToken"
assert protected_routes_guide =~ "403"
assert protected_routes_guide =~ "insufficient_scope"
assert protected_routes_guide =~ "business authorization"
assert protected_routes_guide =~ "tenant checks"
assert protected_routes_guide =~ "Lockspire.AccessToken"
```

---

### `docs/protect-phoenix-api-routes.md` (doc, request-response)

**Analog:** `docs/install-and-onboard.md`

**Canonical pipeline wording** ([docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:7)):
```markdown
## Canonical plug order

Use the plugs in this order:

```elixir
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```
```

**Narrow ownership wording** ([docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:20)):
```markdown
`Lockspire.Plug.VerifyToken` authenticates the access token and enforces route-level `scopes:` / `audience:` restrictions.

`Lockspire.Plug.EnforceSenderConstraints` enforces DPoP when the token is sender-constrained.

`Lockspire.Plug.RequireToken` turns structured verification failures into the correct OAuth-style HTTP response, including `403 insufficient_scope` when the token is valid but under-scoped.
```

**Failure matrix pattern** ([docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:75)):
```markdown
| Situation | Status | Wire behavior |
| --- | --- | --- |
| Missing or invalid token | `401` | `WWW-Authenticate: Bearer ... error="invalid_token"` |
| Audience mismatch | `401` | Bearer challenge with `invalid_token` and a restriction failure description |
| Missing required scope | `403` | `WWW-Authenticate: Bearer ... error="insufficient_scope"` plus `scope="..."` |
| DPoP-bound token without valid proof | `401` | `WWW-Authenticate: DPoP ...` sender-constraint failure |
| DPoP-bound token with proof missing a valid nonce | `401` | `WWW-Authenticate: DPoP ... error="use_dpop_nonce"` plus `DPoP-Nonce: ...` |
```

**Cross-link pattern from onboarding doc** ([docs/install-and-onboard.md](/Users/jon/projects/lockspire/docs/install-and-onboard.md:69)):
```markdown
If you also want to protect host-owned Phoenix API routes with Lockspire-issued access tokens, follow [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md). That guide keeps the route middleware narrow: Lockspire verifies token protocol facts, while your host app keeps business authorization and tenant policy.
```

---

### `docs/supported-surface.md` (doc, transform)

**Analog:** `docs/protect-phoenix-api-routes.md`

**Support-contract style** ([docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:5)):
```markdown
This page is the canonical public support contract for what Lockspire currently supports, what it does not support, and what repo-owned proof backs those claims.
```

**Supported-surface bullet style to preserve** ([docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:32)):
```markdown
- Host Phoenix API route protection with `Lockspire.Plug.VerifyToken`, optional `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`, including route-level `scopes:` and `audience:` / `audiences:` restrictions for Lockspire-issued access tokens
- DPoP on token requests, Lockspire-owned endpoints, host Phoenix API routes protected by the shipped plug pipeline, and truthful introspection visibility for active bound tokens, including automatic `DPoP-Nonce` challenge and retry support on those shipped DPoP surfaces, with bearer clients remaining unchanged by default unless they explicitly opt into DPoP mode
```

**Out-of-scope wording pattern** ([docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:95)):
```markdown
## Explicitly out of scope

- Generic API gateway, service-mesh, or third-party issuer protected-resource middleware remains out of scope
- broader resource-server integration beyond Lockspire-owned endpoints and the shipped Phoenix plug pipeline
```

**Repo-proof section style** ([docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:119)):
```markdown
Repo-owned proof for this posture lives in:

- `docs/protect-phoenix-api-routes.md` for the shipped host Phoenix API route protection guide
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` for generated-host Phoenix API route protection proof
- `test/lockspire/release_readiness_contract_test.exs` for narrow release and docs posture checks
```

---

## Shared Patterns

### Protocol-owned DPoP validation
**Sources:** [lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:15), [lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:321)
**Apply to:** `lib/lockspire/plug/enforce_sender_constraints.ex`, `lib/lockspire/web/controllers/userinfo_controller.ex`, `lib/lockspire/web/protected_resource_challenge.ex`
```elixir
with :ok <- validate_authorization_scheme(request),
     {:ok, raw_access_token} <- fetch_access_token(request),
     {:ok, target_uri} <- fetch_target_uri(request),
     {:ok, proof} <- validate_proof(request, security_profile, target_uri),
     :ok <- validate_ath(proof, raw_access_token),
     :ok <- validate_token_binding(binding_source, proof),
     :ok <- record_dpop_proof_use(proof, request) do
  {:ok, proof}
end
```

### Soft-then-strict host pipeline
**Sources:** [lib/lockspire/plug/enforce_sender_constraints.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/enforce_sender_constraints.ex:55), [lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:19), [docs/protect-phoenix-api-routes.md](/Users/jon/projects/lockspire/docs/protect-phoenix-api-routes.md:11)
**Apply to:** host plug code, docs, generated-host proof
```elixir
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api"
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
```

### Shared protected-resource challenge transport
**Sources:** [lib/lockspire/plug/require_token.ex](/Users/jon/projects/lockspire/lib/lockspire/plug/require_token.ex:140), [lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:60)
**Apply to:** new helper plus both adapters
```elixir
conn
|> put_resp_header("dpop-nonce", nonce)
|> expose_header("DPoP-Nonce")
|> expose_header("WWW-Authenticate")
```

### Docs-as-contract
**Sources:** [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:5), [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:436)
**Apply to:** `docs/supported-surface.md`, `docs/protect-phoenix-api-routes.md`, `docs/install-and-onboard.md`, `test/lockspire/release_readiness_contract_test.exs`
```elixir
assert supported_surface =~ "Host Phoenix API route protection"
assert supported_surface =~ "host Phoenix API routes protected by the shipped plug pipeline"
assert protected_routes_guide =~ "business authorization"
assert protected_routes_guide =~ "tenant checks"
```

## No Analog Found

None. The only inferred new file is `lib/lockspire/web/protected_resource_challenge.ex`; it has strong partial analogs in existing adapter code but no exact existing helper module.

## Metadata

**Analog search scope:** `lib/lockspire/plug`, `lib/lockspire/protocol`, `lib/lockspire/web/controllers`, `test/lockspire/plug`, `test/lockspire/web`, `test/integration`, `docs`, `test/support/generated_host_app_web/router`
**Files scanned:** 13
**Pattern extraction date:** 2026-05-24
