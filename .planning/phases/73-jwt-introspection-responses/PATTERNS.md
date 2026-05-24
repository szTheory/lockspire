# Phase 73: JWT Introspection Responses - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 5 likely Phase 73 files
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/introspection_jwt.ex` | protocol/service | transform | `lib/lockspire/protocol/id_token.ex` | role-match |
| `lib/lockspire/protocol/introspection_jwt.ex` | protocol/service | signing-key lookup | `lib/lockspire/protocol/jarm.ex` | exact-subpattern |
| `lib/lockspire/web/controllers/introspection_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/introspection_controller.ex` | exact |
| `lib/lockspire/web/controllers/introspection_controller.ex` | controller | content negotiation | `lib/lockspire/web/controllers/discovery_controller.ex` | partial |
| `test/lockspire/protocol/introspection_jwt_test.exs` | test | transform | `test/lockspire/protocol/jarm_test.exs` | role-match |
| `test/lockspire/web/introspection_controller_test.exs` | test | request-response | `test/lockspire/web/introspection_controller_test.exs` | exact |
| `test/lockspire/protocol/introspection_test.exs` | test | request-response | `test/lockspire/protocol/introspection_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/introspection_jwt.ex` (protocol/service, transform)

**Primary analog:** `lib/lockspire/protocol/id_token.ex`

Use the same purpose-built signer shape: validate inputs up front, build a narrow claims map explicitly, decode the private JWK locally, then sign with JOSE.

**Imports and narrow module scope** (`id_token.ex:6-8`):
```elixir
alias Lockspire.Host.Claims
alias Lockspire.Protocol.SecurityProfile
```

**Purpose-specific `sign/1` shape** (`id_token.ex:17-29`, `33-58`):
```elixir
@spec sign(map()) :: {:ok, String.t()} | {:error, atom()}
def sign(%{client_id: client_id, issuer: issuer, issued_at: %DateTime{} = issued_at,
           signing_key: %{kid: kid, alg: alg, private_jwk_encrypted: private_jwk}} = params)
    when is_binary(client_id) and is_binary(issuer) do
  security_profile = Map.get(params, :security_profile, :none)
  allowed_algs = SecurityProfile.allowed_signing_algorithms(security_profile)

  with :ok <- ensure_allowed_alg(alg, allowed_algs),
       {:ok, jwk_map} <- decode_private_jwk(private_jwk),
       claims <- build_claims(...),
       {_, compact} <-
         JOSE.JWT.sign(
           JOSE.JWK.from_map(jwk_map),
           %{"alg" => alg, "kid" => kid, "typ" => "JWT"},
           claims
         )
         |> JOSE.JWS.compact() do
    {:ok, compact}
  else
    {:error, reason} -> {:error, reason}
  end
end
```

**Claim shaping pattern** (`id_token.ex:71-92`):
```elixir
protocol_claims = %{
  "iss" => issuer,
  "aud" => client_id,
  "iat" => DateTime.to_unix(issued_at),
  "exp" => DateTime.add(issued_at, @id_token_ttl, :second) |> DateTime.to_unix(),
  "nonce" => nonce
}
```

Phase 73 should copy the explicit claim-construction style, but shape RFC 9701 claims instead:
`"iss"`, `"aud"`, `"iat"`, and `"token_introspection"`, with header `typ: "token-introspection+jwt"`.

**Optional-claim helpers** (`logout_token.ex:90-91`):
```elixir
defp maybe_put_claim(claims, _key, nil), do: claims
defp maybe_put_claim(claims, key, value), do: Map.put(claims, key, value)
```

That is the closest local pattern if the signer needs small conditional claim helpers, but Phase 73 should stay narrow and avoid adding top-level optional JWT claims by default.

### `lib/lockspire/protocol/introspection_jwt.ex` (protocol/service, signing-key lookup)

**Primary analog:** `lib/lockspire/protocol/jarm.ex`

Reuse the existing active-signing-key seam and JOSE decode path. Do not invent a second crypto-policy plane.

**Key-store seam** (`jarm.ex:37-47`, `60-67`):
```elixir
key_store = Map.get(context, :key_store, Config.repo!())
alg = signing_alg(client)

with {:ok, signing_key} <- fetch_key(key_store, alg, client.security_profile),
     {:ok, jwk_map} <- decode_private_jwk(signing_key.private_jwk_encrypted),
     ...
```

```elixir
defp fetch_key(key_store, alg, security_profile) do
  case key_store.fetch_active_signing_key(alg: alg, security_profile: security_profile) do
    {:ok, nil} -> {:error, :invalid_signing_key}
    {:ok, key} -> {:ok, key}
    {:error, reason} -> {:error, reason}
    nil -> {:error, :invalid_signing_key}
  end
end
```

**Repository truth for lookup behavior** (`repository.ex:1055-1065`, `1076-1085`):
```elixir
def fetch_active_signing_key(opts \\ []) when is_list(opts) do
  SigningKeyRecord
  |> where([key], key.status == :active)
  |> where([key], key.use == :sig)
  |> ...
  |> filter_keys_for_security_profile(Keyword.get(opts, :security_profile, :none))
  |> filter_keys_for_alg(Keyword.get(opts, :alg))
  |> List.first()
  |> then(&{:ok, &1})
end
```

```elixir
defp filter_keys_for_security_profile(keys, :fapi_2_0_security) do
  allowed_algs = SecurityProfile.allowed_signing_algorithms(:fapi_2_0_security)
  Enum.filter(keys, fn %SigningKey{alg: alg, use: use} = key ->
    use == :sig and alg in allowed_algs and
      Policy.validate_key_compliance(key, :fapi_2_0_security) == :ok
  end)
end
```

Planner guidance:
- Fetch through `Config.repo!()`/injected `key_store`.
- Pass `security_profile` and an explicit `alg`.
- Keep signer-specific errors narrow and stable.

### `lib/lockspire/web/controllers/introspection_controller.ex` (controller, request-response)

**Primary analog:** `lib/lockspire/web/controllers/introspection_controller.ex`

Preserve the current controller-to-protocol boundary: controller extracts HTTP details, calls one protocol entrypoint, then renders the wire representation.

**Thin adapter boundary** (`introspection_controller.ex:13-33`):
```elixir
authorization = List.first(get_req_header(conn, "authorization"))

case Introspection.introspect(%{
       params: params,
       authorization: authorization,
       opts: [client_store: Repository, token_store: Repository, consent_store: Repository]
     }) do
  {:ok, response} ->
    conn
    |> put_cache_headers()
    |> put_status(:ok)
    |> json(IntrospectionJSON.response(response))

  {:error, %Error{} = error} ->
    conn
    |> put_cache_headers()
    |> maybe_put_www_authenticate(error)
    |> put_status(error.status)
    |> json(IntrospectionJSON.error_response(error))
end
```

Planner guidance:
- Keep `Lockspire.Protocol.Introspection` as the source of token truth.
- Add JWT-vs-JSON representation choice in the controller only.
- Keep JSON errors on the current path even if JWT was requested.

**Response header posture** (`introspection_controller.ex:36-46`):
```elixir
defp put_cache_headers(conn) do
  conn
  |> put_resp_header("cache-control", "no-store")
  |> put_resp_header("pragma", "no-cache")
end

defp maybe_put_www_authenticate(conn, %Error{error: "invalid_client"}) do
  put_resp_header(conn, "www-authenticate", ~s(Basic realm="Lockspire Token Endpoint"))
end
```

Phase 73 should preserve those headers and add `Vary: Accept` on the JWT representation path.

### `lib/lockspire/web/controllers/introspection_controller.ex` (controller, content negotiation)

**Closest analog:** `lib/lockspire/web/controllers/discovery_controller.ex`

There is no exact local `Accept` parser analog. The reusable part is only the controller pattern of explicit header setting plus direct rendering.

**Explicit response shaping from controller** (`discovery_controller.ex:11-15`):
```elixir
conn
|> put_resp_header("cache-control", "public, max-age=300")
|> put_status(:ok)
|> json(DiscoveryJSON.openid_configuration(Discovery.openid_configuration()))
```

Planner guidance:
- Introduce a small Lockspire-owned negotiation helper or private controller function.
- Do not rely on Phoenix MIME registration or `plug :accepts`.
- Treat this as a fresh implementation area with partial analog support only.

### `test/lockspire/protocol/introspection_jwt_test.exs` (test, transform)

**Primary analog:** `test/lockspire/protocol/jarm_test.exs`

Copy the focused cryptographic unit-test structure: local mock key store, generated JOSE keys, direct claims decode, and assertions on stable error tuples.

**Inline mock seam** (`jarm_test.exs:10-19`):
```elixir
defmodule MockKeyStore do
  def fetch_active_signing_key(opts) do
    key = Process.get(:mock_signing_key)
    if key do
      {:ok, %{key | alg: Keyword.get(opts, :alg, "RS256")}}
    else
      {:ok, nil}
    end
  end
end
```

**Setup-generated key fixture** (`jarm_test.exs:33-46`):
```elixir
setup do
  keys = JarTestHelpers.generate_keys()
  {_modules, private_jwk_map} = JOSE.JWK.to_map(keys.private_jwk)

  key = %SigningKey{
    kid: "mock-kid",
    alg: "RS256",
    private_jwk_encrypted: Jason.encode!(private_jwk_map)
  }

  Process.put(:mock_signing_key, key)
  %{keys: keys}
end
```

**Decode-and-assert shape** (`jarm_test.exs:153-162`, `232-240`):
```elixir
assert {:ok, jwt} = Jarm.sign(params, context)
claims = decode_claims(jwt, keys, ["RS256"])

assert claims["iss"] == "https://auth.example.com"
assert claims["aud"] == "client-123"
```

Phase 73 protocol tests should assert:
- header `typ == "token-introspection+jwt"`
- top-level claims are only the RFC 9701 envelope fields being introduced
- nested `"token_introspection"` preserves current payload semantics with string keys
- missing key / unsupported algorithm errors are stable tuples

### `test/lockspire/web/introspection_controller_test.exs` (test, request-response)

**Primary analog:** `test/lockspire/web/introspection_controller_test.exs`

Extend the current HTTP contract suite instead of creating a separate controller test file.

**Current endpoint-fixture structure** (`introspection_controller_test.exs:15-27`, `31-63`, `82-183`):
```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :mount_path, "/lockspire")
  Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
  ...
end
```

The existing fixture already covers:
- confidential caller success
- inactive collapse
- `authorization_details`
- DPoP `cnf`

That makes it the right file to extend with negotiated JWT delivery cases.

**HTTP assertion style** (`introspection_controller_test.exs:190-207`, `271-283`):
```elixir
conn =
  build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
  |> put_req_header("authorization", basic_auth(client.client_id, secret))
  |> put_req_header("accept", "application/json")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

assert conn.status == 200
body = Jason.decode!(conn.resp_body)
assert body["active"] == true
```

Phase 73 controller tests should follow the same shape, but add:
- explicit `Accept: application/token-introspection+jwt`
- content type assertion on `application/token-introspection+jwt`
- `Vary: Accept`
- JWT decode and nested payload assertions for both active and inactive success cases
- JSON error assertion even when JWT was requested

### `test/lockspire/protocol/introspection_test.exs` (test, request-response)

**Primary analog:** `test/lockspire/protocol/introspection_test.exs`

Keep this suite focused on token-classification truth, not wire representation.

**Current truth-style assertions** (`introspection_test.exs:193-212`, `268-341`):
```elixir
assert {:ok, response} =
         Introspection.introspect(%{
           params: %{"token" => "introspect-access-token"},
           authorization: basic_auth(client.client_id, secret),
           opts: [client_store: Repository, token_store: Repository]
         })

assert response.active == true
assert response.client_id == client.client_id
```

```elixir
assert {:ok, %{active: false}} = Introspection.introspect(...)
```

Planner guidance:
- Do not move negotiation or JWT-shaping assertions into this suite.
- Only extend it if Phase 73 requires a small change to the raw introspection map contract.

## Shared Patterns

### Purpose-Built JWT Modules
**Sources:** `lib/lockspire/protocol/id_token.ex`, `lib/lockspire/protocol/logout_token.ex`

Shared rule: each JWT-producing module owns its own claim envelope and JOSE header instead of delegating to a generic “sign arbitrary map” helper.

### Controller Owns Representation, Protocol Owns Truth
**Sources:** `lib/lockspire/web/controllers/introspection_controller.ex`, `lib/lockspire/protocol/introspection.ex`

Shared rule: keep request parsing and response rendering in the controller, but keep authentication, token lookup, and payload truth in protocol modules.

### Active Signing Key Lookup
**Sources:** `lib/lockspire/protocol/jarm.ex`, `lib/lockspire/storage/ecto/repository.ex`

Shared rule: use `fetch_active_signing_key(alg: ..., security_profile: ...)` and inherit the existing security-profile filtering instead of adding introspection-specific key policy.

### Focused Test Split
**Sources:** `test/lockspire/protocol/jarm_test.exs`, `test/lockspire/protocol/introspection_test.exs`, `test/lockspire/web/introspection_controller_test.exs`

Shared rule:
- protocol signer tests decode JWTs and assert claims directly
- protocol introspection tests assert raw token-state truth
- controller tests assert headers, content type, and HTTP-level negotiation

## No Exact Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/lockspire/web/controllers/introspection_controller.ex` `Accept` negotiation helper | utility/controller-private | request-response | No existing Lockspire module performs RFC 9110-style media-type negotiation without host MIME registration. Implement fresh as a small Lockspire-owned helper. |

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/web/controllers`, `lib/lockspire/storage`, `test/lockspire/protocol`, `test/lockspire/web`, `.planning/phases/71-jarm-core`, `.planning/phases/72-jarm-encryption-and-metadata`, `.planning/phases/73-jwt-introspection-responses`

**Files scanned:** 16
**Pattern extraction date:** 2026-05-07
