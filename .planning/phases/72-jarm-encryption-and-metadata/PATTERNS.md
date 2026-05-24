# Phase 72: JARM Encryption & Metadata - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/jarm.ex` | service | transform | `lib/lockspire/protocol/jarm.ex`, `lib/lockspire/protocol/jar.ex` | exact+partial |
| `lib/lockspire/protocol/authorization_flow.ex` | service | request-response | `lib/lockspire/protocol/authorization_flow.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | service | transform | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/protocol/jarm/client_key_resolver.ex` | service | request-response | `lib/lockspire/protocol/client_auth/private_key_jwt.ex` | role-match |
| `lib/lockspire/storage/key_store.ex` | config | CRUD | `lib/lockspire/storage/key_store.ex` | exact |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `test/lockspire/protocol/jarm_test.exs` | test | transform | `test/lockspire/protocol/jarm_test.exs`, `test/lockspire/protocol/request_object_test.exs` | exact+partial |
| `test/lockspire/protocol/discovery_test.exs` | test | transform | `test/lockspire/protocol/discovery_test.exs` | exact |
| `test/lockspire/protocol/authorization_flow_test.exs` | test | request-response | `test/lockspire/protocol/authorization_flow_test.exs` | exact |
| `test/lockspire/web/authorize_controller_test.exs` | test | request-response | `test/lockspire/web/authorize_controller_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/jarm.ex` (service, transform)

**Primary analog:** `lib/lockspire/protocol/jarm.ex`

**Preserve signer shape and context lookup** ([lib/lockspire/protocol/jarm.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jarm.ex:13)):
```elixir
def sign(response_params, context) do
  client = Map.fetch!(context, :client)
  issuer = Map.fetch!(context, :issuer)
  key_store = Map.get(context, :key_store, Config.repo!())
```

**Preserve explicit `alg=none` rejection and fail-closed `with` flow** ([lib/lockspire/protocol/jarm.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jarm.ex:19)):
```elixir
alg_atom = client.authorization_signed_response_alg || :RS256
alg = to_string(alg_atom)

if alg == "none" do
  {:error, :invalid_algorithm}
else
  with {:ok, signing_key} <- fetch_key(key_store, alg, client.security_profile),
       {:ok, jwk_map} <- decode_private_jwk(signing_key.private_jwk_encrypted),
       claims <- build_claims(response_params, issuer, client.client_id),
```

**Nested JWS->JWE precedent:** reuse the sign-first shape here, then mirror the Phase 40 nested-JWT encryption call from `Jar` tests rather than inventing a second JOSE style. The exact sign step to preserve is ([lib/lockspire/protocol/jarm.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jarm.ex:28)):
```elixir
{_, compact} =
  JOSE.JWT.sign(
    JOSE.JWK.from_map(jwk_map),
    %{"alg" => signing_key.alg, "kid" => signing_key.kid, "typ" => "JWT"},
    claims
  )
  |> JOSE.JWS.compact()
```

**Secondary analog:** `test/lockspire/protocol/request_object_test.exs`

**Preserve nested JOSE call order for encryption** ([test/lockspire/protocol/request_object_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/request_object_test.exs:51)):
```elixir
jws = JOSE.JWT.sign(sig_jwk, %{"alg" => "ES256"}, claims)
{_, jws_compact} = JOSE.JWS.compact(jws)

jwe = JOSE.JWE.block_encrypt(enc_jwk, jws_compact, %{"alg" => "RSA-OAEP", "enc" => "A256GCM"})
{_, jwe_compact} = JOSE.JWE.compact(jwe)
```

**Preserve key decoding helper style** from both JARM and JAR so encryption can consume stored JSON or term-encoded JWKs without widening callers ([lib/lockspire/protocol/jarm.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jarm.ex:69), [lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:60)).

### `lib/lockspire/protocol/jarm/client_key_resolver.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/client_auth/private_key_jwt.ex`

**Preserve inline-first, remote-second key resolution posture** ([lib/lockspire/protocol/client_auth/private_key_jwt.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth/private_key_jwt.ex:46)):
```elixir
defp resolve_keys(%Client{jwks: jwks} = client, _opts) when is_map(jwks),
  do: {:ok, client, :inline_jwks}

defp resolve_keys(%Client{jwks_uri: jwks_uri} = client, opts) when is_binary(jwks_uri) do
  fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())
```

**Preserve guarded remote fetch seam and map failures into module-owned reasons** ([lib/lockspire/protocol/client_auth/private_key_jwt.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth/private_key_jwt.ex:52)):
```elixir
with {:ok, jwk_set} <- fetcher.get_keys(jwks_uri, jwks_fetcher_opts(opts)),
     {_modules, jwks} <- JOSE.JWK.to_map(jwk_set) do
  {:ok, %Client{client | jwks: jwks}, :jwks_uri}
else
  {:error, _reason} -> {:error, :client_jwks_fetch_failed}
end
```

**Preserve one bounded recovery path on stale remote keys** ([lib/lockspire/protocol/client_auth/private_key_jwt.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth/private_key_jwt.ex:71)):
```elixir
case verify_signature_once(assertion, client, allowed_signing_algorithms) do
  {:error, :no_matching_key} when jwks_source == :jwks_uri ->
    retry_remote_signature_verification(assertion, client, allowed_signing_algorithms, opts)
```

Use this exact posture for JARM encryption key resolution: allow one refresh on `jwks_uri`, never retry-loop, never downgrade to signed-only output.

### `lib/lockspire/protocol/authorization_flow.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/authorization_flow.ex`

**Preserve explicit response-builder integration inside the flow, not in a Plug** ([lib/lockspire/protocol/authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:410)):
```elixir
defp build_response_redirect(%Interaction{} = interaction, params, opts) do
  mode = interaction.response_mode || "query"

  if is_jarm_mode?(mode) do
    with {:ok, jwt} <- sign_jarm_response(interaction, params, opts) do
      format_jarm_redirect(interaction, mode, jwt)
    end
  else
    {:ok, build_redirect(interaction.redirect_uri, params, mode)}
  end
end
```

**Preserve fail-closed redirect behavior for denial and approval** ([lib/lockspire/protocol/authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:390), [lib/lockspire/protocol/authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:400)):
```elixir
params = %{"code" => raw_code, "state" => interaction.state, "iss" => Config.issuer!()}
params = %{"error" => "access_denied", "state" => interaction.state, "iss" => Config.issuer!()}
```

Phase 72 should keep this contract: when encrypted JARM is in effect, success and OAuth denial stay on the redirect path only if the nested JWT can actually be produced. Encryption setup failures should not silently fall back to query/fragment params.

**Preserve response-mode mapping** ([lib/lockspire/protocol/authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:456)):
```elixir
case mode do
  "form_post.jwt" -> {:ok, {:form_post, interaction.redirect_uri, %{"response" => jwt}}}
  "fragment.jwt" -> {:ok, build_redirect(interaction.redirect_uri, %{"response" => jwt}, "fragment")}
  _other -> {:ok, build_redirect(interaction.redirect_uri, %{"response" => jwt}, "query")}
end
```

### `lib/lockspire/protocol/discovery.ex` (service, transform)

**Analog:** `lib/lockspire/protocol/discovery.ex`

**Preserve mounted-surface truth source** ([lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:74)):
```elixir
defp mounted_endpoint_metadata do
  issuer = Config.issuer!()

  mounted_route_paths()
  |> Enum.reduce(%{}, fn path, acc ->
    case endpoint_metadata_entry(issuer, path) do
```

**Preserve one shared capability source, then publish through helpers** ([lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:97)):
```elixir
"token_endpoint_auth_methods_supported" =>
  token_endpoint_auth_methods_supported(endpoint_metadata),
...
|> put_endpoint_auth_metadata(endpoint_metadata)
```

**Preserve runtime truth from shared helpers rather than duplicated constants** ([lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:126)):
```elixir
defp id_token_signing_alg_values_supported do
  SecurityProfile.allowed_signing_algorithms(global_security_profile())
end

defp authorization_signing_alg_values_supported do
  SecurityProfile.allowed_signing_algorithms(global_security_profile())
end
```

**Preserve conditional publication keyed off actual advertised capability** ([lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:227)):
```elixir
if "private_key_jwt" in Map.get(metadata, methods_key, []) do
  Map.put(metadata, algorithms_key, SecurityProfile.allowed_signing_algorithms(global_security_profile()))
else
  metadata
end
```

Phase 72 should mirror this exactly for JARM encryption metadata: derive one authorization-response capability helper from mounted authorization surface plus effective issuer crypto posture, then publish both signing and encryption metadata from that shared source.

### `lib/lockspire/storage/key_store.ex` and `lib/lockspire/storage/ecto/repository.ex` (config/service, CRUD)

**Analog:** existing key-store seam with `use` partitioning.

**Preserve explicit behaviour seam for encryption-key lookup** ([lib/lockspire/storage/key_store.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/key_store.ex:10)):
```elixir
@callback list_decryption_keys() :: {:ok, [SigningKey.t()]} | {:error, store_error()}
@callback fetch_active_signing_key(keyword()) ::
            {:ok, SigningKey.t() | nil} | {:error, store_error()}
```

If Phase 72 needs OP-side response-encryption key lookup or reusable recipient-key filtering, add a first-class key-store function rather than reaching through repository internals from protocol code.

**Preserve `use`-isolated repository queries** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1025)):
```elixir
def list_decryption_keys do
  SigningKeyRecord
  |> where([key], key.use == :enc)
  |> where([key], key.status in [:active, :retiring])
```

**Preserve signing-key isolation** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1055)):
```elixir
def fetch_active_signing_key(opts \\ []) when is_list(opts) do
  SigningKeyRecord
  |> where([key], key.status == :active)
  |> where([key], key.use == :sig)
```

**Preserve activation semantics partitioned by `use`** ([lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1883)):
```elixir
case fetch_active_signing_key_records(selected_record.use) do
```

### Tests to Copy

**Nested JWS->JWE test style:** `test/lockspire/protocol/request_object_test.exs` proves the repo already accepts compact nested JWT round-trips; extend that style into `test/lockspire/protocol/jarm_test.exs`.

**JARM signer unit style:** `test/lockspire/protocol/jarm_test.exs` keeps the crypto path isolated behind a mocked key store and direct JOSE verification ([test/lockspire/protocol/jarm_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/jarm_test.exs:35)).

**Guarded remote key resolution style:** `test/lockspire/protocol/client_auth_test.exs` already pins inline-vs-remote JWKS resolution, single refresh, and fail-closed replay semantics ([test/lockspire/protocol/client_auth_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/client_auth_test.exs:68), [test/lockspire/protocol/client_auth_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/client_auth_test.exs:91), [test/lockspire/protocol/client_auth_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/client_auth_test.exs:163)).

**Discovery truth style:** `test/lockspire/protocol/discovery_test.exs` pins metadata only when mounted and only when the runtime can truthfully advertise it ([test/lockspire/protocol/discovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/discovery_test.exs:103), [test/lockspire/protocol/discovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/discovery_test.exs:139), [test/lockspire/protocol/discovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/discovery_test.exs:163)).

**Fail-closed authorization redirect style:** `test/lockspire/web/authorize_controller_test.exs` is the precedent for "trusted redirect when redirect-safe, first-party browser error when not" ([test/lockspire/web/authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:192), [test/lockspire/web/authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:298), [test/lockspire/web/authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:326)).

## Shared Patterns

### Nested JWT construction
**Sources:** [lib/lockspire/protocol/jarm.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jarm.ex:13), [test/lockspire/protocol/request_object_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/request_object_test.exs:51)

Preserve this sequence:
1. Build claims.
2. Sign with OP private key.
3. Compact JWS.
4. Encrypt compact JWS when client encryption metadata is configured.
5. Compact JWE.

No alternate JOSE flow should exist elsewhere in controllers.

### Guarded `jwks_uri` boundary
**Sources:** [lib/lockspire/jwks_fetcher.ex](/Users/jon/projects/lockspire/lib/lockspire/jwks_fetcher.ex:24), [lib/lockspire/protocol/client_auth/private_key_jwt.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth/private_key_jwt.ex:49)

Preserve:
```elixir
with {:ok, _parsed_uri} <- validate_fetch_target(uri, opts) do
...
{:ok, %Req.Response{status: status}} when status in 300..399 ->
  {:ignore, {:error, fetch_error(:redirect_disallowed)}}
```

And preserve the caller-side pattern of mapping fetcher errors into module-owned reasons instead of leaking Req or JOSE details.

### Metadata truth from one capability helper
**Sources:** [lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:86), [lib/lockspire/protocol/client_auth.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/client_auth.ex:33)

Preserve the Phase 59/61 pattern:
```elixir
def supported_auth_method_names do
  Enum.map(@supported_auth_methods, &Atom.to_string/1)
end
```

Discovery should call one shared helper and then narrow publication by mounted-route truth. Phase 72 should do the same for authorization-response signing+encryption capability.

### Fail-closed external behavior
**Sources:** [lib/lockspire/protocol/authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:410), [test/lockspire/jwks_fetcher_test.exs](/Users/jon/projects/lockspire/test/lockspire/jwks_fetcher_test.exs:62)

Preserve two invariants:
1. Redirect-path crypto failures do not silently weaken the response contract.
2. Redirects, retries, and unsafe targets are refused explicitly at the guarded boundary.

## Planning Precedents

- **Phase 71:** JARM stays in explicit protocol helpers and authorization-flow formatting, not hidden Plugs.
- **Phase 40:** Nested JWT support is implemented as a focused JOSE transform with `use`-isolated encryption keys.
- **Phase 59:** Discovery metadata must come from one shared capability source, not duplicated feature lists.
- **Phase 60:** Remote `jwks_uri` handling stays guarded, bounded, HTTPS-only, redirect-disabled, and refresh-at-most-once.
- **Phase 61:** Shared client-key resolution prefers inline material, allows one refresh on remote mismatch, and fails closed.

## No Analog Found

None. Every likely Phase 72 file has a strong in-repo analog or a direct prior-phase planning precedent.

## Metadata

**Analog search scope:** `.planning/phases/40-*`, `.planning/phases/59-*`, `.planning/phases/60-*`, `.planning/phases/61-*`, `.planning/phases/71-*`, `lib/lockspire/**`, `test/lockspire/**`
**Pattern extraction date:** 2026-05-07
