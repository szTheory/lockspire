# Phase 71: JARM Core - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/jarm.ex` | utility | transform | `lib/lockspire/protocol/id_token.ex` | exact |
| `lib/lockspire/domain/client.ex` | model | CRUD | `lib/lockspire/domain/client.ex` | exact |
| `lib/lockspire/domain/interaction.ex` | model | CRUD | `lib/lockspire/domain/interaction.ex` | exact |
| `lib/lockspire/protocol/authorization_request.ex` | validator | request-response | `lib/lockspire/protocol/authorization_request.ex` | exact |
| `lib/lockspire/protocol/authorization_flow.ex` | service | request-response | `lib/lockspire/protocol/authorization_flow.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | config | request-response | `lib/lockspire/protocol/discovery.ex` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/jarm.ex` (utility, transform)

**Analog:** `lib/lockspire/protocol/id_token.ex`

**Core Pattern (JWT Signing)** (lines 20-37):
```elixir
    with :ok <- ensure_allowed_alg(alg, allowed_algs),
         {:ok, auth_time} <- validate_auth_time(Map.get(params, :auth_time)),
         sid <- Map.get(params, :sid),
         {:ok, jwk_map} <- decode_private_jwk(private_jwk),
         claims <-
           build_claims(
             host_claims,
             issuer,
             client_id,
             nonce,
             access_token,
             issued_at,
             auth_time,
             sid
           ),
         {_, compact} <-
           JOSE.JWT.sign(
             JOSE.JWK.from_map(jwk_map),
             %{"alg" => alg, "kid" => kid, "typ" => "JWT"},
             claims
           )
           |> JOSE.JWS.compact() do
      {:ok, compact}
```

**Error Handling Pattern** (lines 38-42):
```elixir
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def sign(_params), do: {:error, :invalid_signing_key}
```

---

### `lib/lockspire/protocol/authorization_flow.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/authorization_flow.ex`

**Core Pattern (JARM redirect construction)** (lines 456-468):
```elixir
  defp format_jarm_redirect(interaction, mode, jwt) do
    jarm_params = %{"response" => jwt}

    case mode do
      "form_post.jwt" ->
        {:ok, {:form_post, interaction.redirect_uri, jarm_params}}

      "fragment.jwt" ->
        {:ok, build_redirect(interaction.redirect_uri, jarm_params, "fragment")}
        
      _other -> # "jwt" (which defaults to query.jwt for code) or "query.jwt"
        {:ok, build_redirect(interaction.redirect_uri, jarm_params, "query")}
    end
  end
```

**Core Pattern (Query / Fragment formatting)** (lines 471-487):
```elixir
  defp build_redirect(base_uri, params, mode) when is_binary(base_uri) and is_map(params) do
    uri = URI.parse(base_uri)

    clean_params =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    if mode == "fragment" do
      # When fragment mode, we don't merge with existing query, we put in fragment
      existing_fragment = URI.decode_query(uri.fragment || "")
      merged = Map.merge(existing_fragment, clean_params)
      %{uri | fragment: URI.encode_query(merged)} |> URI.to_string()
    else
      existing = URI.decode_query(uri.query || "")
      merged = Map.merge(existing, clean_params)
      %{uri | query: URI.encode_query(merged)} |> URI.to_string()
    end
  end
```

---

### `lib/lockspire/protocol/authorization_request.ex` (validator, request-response)

**Analog:** `lib/lockspire/protocol/authorization_request.ex`

**Core Pattern (Validation)** (lines 475-484):
```elixir
  defp validate_response_mode(%{"response_mode" => mode} = params) when is_binary(mode) do
    if MapSet.member?(@allowed_response_modes, mode) do
      # ... implementation ...
    else
      {:error,
       %Error{
         error: "invalid_request",
         error_description: "response_mode is invalid or unsupported",
         reason: :invalid_response_mode
       }}
```

---

### `lib/lockspire/protocol/discovery.ex` (config, request-response)

**Analog:** `lib/lockspire/protocol/discovery.ex`

**Core Pattern (Module Attributes)** (lines 25-32):
```elixir
  @response_modes_supported [
    "query",
    "fragment",
    "form_post",
    "jwt",
    "query.jwt",
    "fragment.jwt",
    "form_post.jwt"
  ]
```

## Shared Patterns

### Cryptography Storage and Keys
**Source:** `lib/lockspire/storage/key_store.ex`
**Apply to:** `lib/lockspire/protocol/authorization_flow.ex`
When fetching keys for JARM, use `KeyStore.fetch_active_signing_key(alg: alg_str, security_profile: client.security_profile)` to dynamically pull the private key based on `client.authorization_signed_response_alg`.

## Metadata

**Analog search scope:** `lib/lockspire/**/*.ex`
**Files scanned:** 6
**Pattern extraction date:** 2024-05-18