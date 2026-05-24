# Phase 35: Owned Endpoint Consumption and Truthful Surface - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 14
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/userinfo.ex` | service | request-response | `lib/lockspire/protocol/userinfo.ex` | exact |
| `lib/lockspire/web/controllers/userinfo_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/userinfo_controller.ex` | exact |
| `lib/lockspire/protocol/protected_resource_dpop.ex` (implied new helper if extracted) | service | request-response | `lib/lockspire/protocol/token_endpoint_dpop.ex` | flow-match |
| `lib/lockspire/protocol/discovery.ex` | service | request-response | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/protocol/registration.ex` | service | transform | `lib/lockspire/protocol/registration.ex` | exact |
| `lib/lockspire/protocol/registration_management.ex` | service | CRUD | `lib/lockspire/protocol/registration_management.ex` | exact |
| `lib/lockspire/admin/clients.ex` | service | CRUD | `lib/lockspire/admin/clients.ex` | exact |
| `lib/lockspire/admin/server_policy.ex` | service | CRUD | `lib/lockspire/admin/server_policy.ex` | exact |
| `lib/lockspire/web/live/admin/policies_live/dpop.ex` (implied new) | component | event-driven | `lib/lockspire/web/live/admin/policies_live/par.ex` | role-match |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | component | event-driven | `lib/lockspire/web/live/admin/clients_live/form_component.ex` | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component | event-driven | `lib/lockspire/web/live/admin/clients_live/show.ex` | exact |
| `lib/lockspire/web/router.ex` | route | request-response | `lib/lockspire/web/router.ex` | exact |
| `test/lockspire/web/userinfo_controller_test.exs` | test | request-response | `test/lockspire/web/userinfo_controller_test.exs` | exact |
| `test/lockspire/web/discovery_controller_test.exs` | test | request-response | `test/lockspire/web/discovery_controller_test.exs` | exact |
| `test/lockspire/release_readiness_contract_test.exs` | test | transform | `test/lockspire/release_readiness_contract_test.exs` | exact |
| `test/lockspire/web/live/admin/policies_live/dpop_test.exs` (implied new) | test | event-driven | `test/lockspire/web/live/admin/policies_live/par_test.exs` | role-match |
| `test/lockspire/web/live/admin/clients_live_test.exs` | test | event-driven | `test/lockspire/web/live/admin/clients_live_test.exs` | exact |
| `docs/supported-surface.md` | config | transform | `docs/supported-surface.md` | exact |

## Pattern Assignments

### `lib/lockspire/web/controllers/userinfo_controller.ex` and `lib/lockspire/protocol/userinfo.ex`

**Use for:** thin controller -> protocol ownership, standards-shaped `WWW-Authenticate`, cache headers, repo-backed token lookup.

**Controller analog:** `lib/lockspire/web/controllers/userinfo_controller.ex`

**Thin adapter pattern** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:13)):
```elixir
def show(conn, _params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  case Userinfo.fetch_claims(%{authorization: authorization, opts: [token_store: Repository]}) do
    {:ok, claims} ->
      conn
      |> put_cache_headers()
      |> put_status(:ok)
      |> json(UserinfoJSON.response(claims))

    {:error, %Error{} = error} ->
      conn
      |> put_cache_headers()
      |> put_www_authenticate(error)
      |> put_status(error.status)
      |> json(UserinfoJSON.error_response(error))
  end
end
```

**Auth challenge pattern** ([lib/lockspire/web/controllers/userinfo_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:38)):
```elixir
defp put_www_authenticate(conn, %Error{status: 401, error: "invalid_token"}) do
  put_resp_header(
    conn,
    "www-authenticate",
    ~s(Bearer realm="Lockspire Userinfo", error="invalid_token")
  )
end
```

**Protocol ownership pattern** ([lib/lockspire/protocol/userinfo.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/userinfo.ex:36)):
```elixir
def fetch_claims(request) when is_map(request) do
  with {:ok, bearer_token} <- parse_bearer_token(request),
       {:ok, %Token{} = access_token} <- fetch_access_token(bearer_token, request),
       {:ok, %Claims{} = claims} <- resolve_claims(access_token),
       userinfo_claims <- build_userinfo_claims(claims, access_token.scopes) do
    {:ok, userinfo_claims}
  else
    {:error, %Error{} = error} -> {:error, error}
  end
end
```

**Token lookup + error shaping** ([lib/lockspire/protocol/userinfo.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/userinfo.ex:48)):
```elixir
defp parse_bearer_token(request) do
  case Map.get(request, :authorization, Map.get(request, "authorization")) do
    "Bearer " <> token when byte_size(token) > 0 ->
      {:ok, token}

    _other ->
      {:error,
       error(401, "invalid_token", "Bearer access token is required", :missing_bearer_token)}
  end
end
```

**Phase 35 guidance:** keep the controller thin. If DPoP userinfo logic is extracted, it should look like `TokenEndpointDPoP`, with `userinfo.ex` orchestrating it rather than the controller parsing proofs.

---

### `lib/lockspire/protocol/protected_resource_dpop.ex` (implied) or DPoP additions inside `userinfo.ex`

**Use for:** centralized DPoP validation, canonical URI handling, replay recording, policy resolution, and durable token-mode enforcement.

**Analog:** `lib/lockspire/protocol/token_endpoint_dpop.ex`

**Shared DPoP context pipeline** ([lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:22)):
```elixir
def resolve_context(%Client{} = client, request) do
  with {:ok, resolved_policy} <- resolve_policy(client, request),
       {:ok, proof} <- validate_proof(resolved_policy, request),
       :ok <- record_dpop_proof_use(proof, request) do
    {:ok, issuance_context(resolved_policy.effective_policy, proof)}
  end
end
```

**Proof validation topology** ([lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:68)):
```elixir
case DPoP.validate_proof(
       proof,
       method: request_method(request),
       target_uri: token_endpoint_uri(),
       now: now(request),
       max_age: Keyword.get(request_options(request), :dpop_max_age, 300),
       clock_skew: Keyword.get(request_options(request), :dpop_clock_skew, 30)
     ) do
  {:ok, %DPoP{} = validated_proof} ->
    {:ok, validated_proof}

  {:error, reason} when is_atom(reason) ->
    {:error, invalid_dpop_proof("The DPoP proof is invalid", reason)}
end
```

**Replay recording pattern** ([lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:104)):
```elixir
defp record_dpop_proof_use(%DPoP{} = validated_proof, request) do
  with {:ok, %DpopReplay{} = replay} <- build_dpop_replay(validated_proof, request),
       {:ok, result} <- dpop_replay_store(request).record_dpop_proof(replay) do
    case result do
      :accepted -> :ok
      :replay -> {:error, invalid_dpop_proof("The DPoP proof has already been used", :dpop_proof_replayed)}
    end
  end
end
```

**Canonical URI + claim extraction pattern** ([lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:158)):
```elixir
with {:ok, htm} <- fetch_dpop_claim(claims, "htm"),
     {:ok, htu} <- fetch_dpop_claim(claims, "htu"),
     {:ok, jti} <- fetch_dpop_claim(claims, "jti"),
     {:ok, iat} <- fetch_dpop_iat(claims),
     {:ok, expires_at} <- dpop_replay_expiration(iat, request) do
  normalized_htm = String.upcase(htm)
  normalized_htu = canonical_dpop_htu(htu)
```

**Validator truth source** ([lib/lockspire/protocol/dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:36)):
```elixir
@allowed_algorithms ~w(RS256 RS384 RS512 PS256 PS384 PS512 ES256 ES384 ES512 EdDSA)
@required_typ "dpop+jwt"
```

**Claim checks already proven** ([lib/lockspire/protocol/dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:95)):
```elixir
with {:ok, method, target_uri, now, max_age, clock_skew} <- parse_validation_opts(opts),
     :ok <- check_htm(claims, method),
     :ok <- check_htu(claims, target_uri),
     :ok <- check_iat(claims, now, max_age, clock_skew),
     :ok <- check_jti(claims) do
  :ok
end
```

**Phase 35 guidance:** there is no exact protected-resource DPoP analog yet. Copy this module’s shape, then add userinfo-specific checks for `ath` and `Token.cnf["jkt"]` matching the validated proof key. Do not move this logic into `UserinfoController`.

---

### `lib/lockspire/protocol/discovery.ex`, `test/lockspire/web/discovery_controller_test.exs`, `docs/supported-surface.md`, `test/lockspire/release_readiness_contract_test.exs`

**Use for:** discovery truth guarded by route-mounted behavior plus docs/release tests.

**Discovery builder analog:** `lib/lockspire/protocol/discovery.ex`

**Mounted-route truth pattern** ([lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:61)):
```elixir
defp mounted_endpoint_metadata do
  issuer = Config.issuer!()

  mounted_route_paths()
  |> Enum.reduce(%{}, fn path, acc ->
    case endpoint_metadata_entry(issuer, path) do
      nil -> acc
      {key, value} -> Map.put(acc, key, value)
    end
  end)
end
```

**Published metadata assembly** ([lib/lockspire/protocol/discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:73)):
```elixir
%{
  "issuer" => issuer,
  "scopes_supported" => scopes_supported(),
  "response_types_supported" => @response_types_supported,
  "response_modes_supported" => @response_modes_supported,
  "grant_types_supported" => grant_types_supported(endpoint_metadata),
  "token_endpoint_auth_methods_supported" =>
    token_endpoint_auth_methods_supported(endpoint_metadata),
  "code_challenge_methods_supported" => code_challenge_methods_supported(endpoint_metadata),
  "subject_types_supported" => @subject_types_supported,
  "id_token_signing_alg_values_supported" => @id_token_signing_alg_values_supported
}
|> Map.merge(endpoint_metadata)
```

**HTTP truth test pattern** ([test/lockspire/web/discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:30)):
```elixir
test "GET /.well-known/openid-configuration publishes truthful mounted metadata" do
  conn =
    build_conn(:get, "/.well-known/openid-configuration")
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

**Positive + negative assertions pattern** ([test/lockspire/web/discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:41)):
```elixir
assert body["userinfo_endpoint"] == "https://example.test/lockspire/userinfo"
refute Map.has_key?(body, "registration_endpoint")
refute Map.has_key?(body, "require_pushed_authorization_requests")
```

**Supported-surface doc pattern** ([docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:7)):
```markdown
## Supported in scope

- OIDC discovery and JWKS
- Userinfo
...
## Explicitly out of scope
...
## Trust posture
...
```

**Release-contract backstop pattern** ([test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:191)):
```elixir
test "preview docs keep the v0.1 embedded Phoenix wedge explicit" do
  readme = File.read!(@readme_path)
  supported_surface = File.read!(@supported_surface_path)
  ...
  assert supported_surface =~ "OIDC discovery and JWKS"
```

**Phase 35 guidance:** add DPoP discovery claims only if the repo proves them on Lockspire-owned surfaces. Mirror the existing “assert present / refute unsupported” style in discovery tests and the release-readiness doc assertions.

---

### `lib/lockspire/protocol/registration.ex` and `lib/lockspire/protocol/registration_management.ex`

**Use for:** DCR metadata intake/update patterns for `dpop_bound_access_tokens`, with request parsing in protocol modules and durable client state persisted explicitly.

**Registration pipeline analog** ([lib/lockspire/protocol/registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:57)):
```elixir
with :ok <- require_iat_when_policy_demands(server_policy, iat),
     {:ok, iat_record} <- maybe_redeem_iat(iat),
     {:ok, %Resolved{} = resolved} <- resolve_policy(server_policy, iat_record, metadata),
     :ok <- validate_intake_metadata(metadata, resolved),
     credentials <- generate_credentials(),
     {:ok, %Client{} = client} <-
       persist_client(metadata, resolved, iat_record, credentials, source) do
```

**Slice-specific validation pattern** ([lib/lockspire/protocol/registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:123)):
```elixir
def validate_intake_metadata(metadata, %Resolved{} = _resolved) when is_map(metadata) do
  with :ok <- validate_jwks(metadata),
       :ok <- validate_grant_response_coherence(metadata),
       :ok <- validate_redirect_uris(metadata) do
    validate_pkce_floor(metadata)
  end
end
```

**Explicit durable field mapping pattern** ([lib/lockspire/protocol/registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:225)):
```elixir
client = %Client{
  ...
  token_endpoint_auth_method: auth_method,
  pkce_required: true,
  ...
  metadata: build_extension_metadata(metadata)
}
```

**Extension metadata intake pattern** ([lib/lockspire/protocol/registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:291)):
```elixir
defp build_extension_metadata(metadata) when is_map(metadata) do
  metadata
  |> Map.take(["client_uri"])
  |> Map.reject(fn {_k, v} -> is_nil(v) end)
end
```

**Update path mirrors intake** ([lib/lockspire/protocol/registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:61)):
```elixir
with {:ok, resolved} <- DcrPolicy.resolve(server_policy, nil, metadata),
     :ok <- Registration.validate_intake_metadata(metadata, resolved),
     {new_rat_plaintext, new_rat_hash} <- RegistrationAccessToken.generate(),
     {:ok, updated_client} <- persist_update(client, metadata, new_rat_hash) do
```

**Update mapping pattern** ([lib/lockspire/protocol/registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:242)):
```elixir
%Client{
  client
  | client_type: client_type,
    name: Map.get(metadata, "client_name"),
    redirect_uris: Map.get(metadata, "redirect_uris", []),
    allowed_scopes: allowed_scopes,
    ...
    metadata: extension_metadata
}
```

**Phase 35 guidance:** mirror these registration/update seams for `dpop_bound_access_tokens`, but persist into `Client.dpop_policy`, not generic JSON metadata. Intake/update should stay symmetric.

---

### `lib/lockspire/admin/server_policy.ex`, `lib/lockspire/web/live/admin/policies_live/par.ex`, `test/lockspire/web/live/admin/policies_live/par_test.exs`

**Use for:** narrow global policy page, enum validation, and route-backed LiveView tests.

**Global enum persistence seam** ([lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:44)):
```elixir
@spec put_dpop_policy(atom() | String.t()) ::
        {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
def put_dpop_policy(mode) do
  with {:ok, normalized_mode} <- normalize_dpop_policy(mode) do
    Repository.update_server_policy(fn %ServerPolicy{} = current ->
      %ServerPolicy{current | dpop_policy: normalized_mode}
    end)
  end
end
```

**Enum normalization pattern** ([lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:105)):
```elixir
defp normalize_dpop_policy(:bearer), do: {:ok, :bearer}
defp normalize_dpop_policy(:dpop), do: {:ok, :dpop}
...
defp invalid_dpop_policy(value) do
  {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: value}]}
end
```

**Global policy LiveView shape** ([lib/lockspire/web/live/admin/policies_live/par.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/par.ex:13)):
```elixir
socket
|> assign(
  page_title: "PAR policy",
  current_section: :policies,
  policy: nil,
  summary: %{inherit: 0, required: 0, optional: 0},
  form_errors: []
)
|> load_policy()
|> load_summary()
```

**Save-event pattern** ([lib/lockspire/web/live/admin/policies_live/par.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/par.ex:33)):
```elixir
case Admin.put_server_policy(mode) do
  {:ok, %ServerPolicy{} = policy} ->
    {:noreply,
     socket
     |> assign(policy: policy, form_errors: [])
     |> put_flash(:info, "Global PAR policy updated")}

  {:error, errors} when is_list(errors) ->
    {:noreply, assign(socket, form_errors: errors)}
```

**Summary card pattern** ([lib/lockspire/web/live/admin/policies_live/par.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/par.ex:80)):
```elixir
Enum.reduce(clients, %{inherit: 0, required: 0, optional: 0}, fn %Client{par_policy: mode}, acc ->
  Map.update!(acc, mode, &(&1 + 1))
end)
```

**Policy page tests** ([test/lockspire/web/live/admin/policies_live/par_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/policies_live/par_test.exs:63)):
```elixir
assert Enum.any?(routes, &live_route?(&1, "/admin/policies/par", Par))
...
view
|> form("form[phx-submit=save_policy]", %{policy: %{par_policy: "required"}})
|> render_submit()
...
assert html =~ "invalid_par_policy"
```

**Phase 35 guidance:** the DPoP global policy page should be a narrow clone of PAR: one enum form, one override summary, no generalized sender-constrained control plane.

---

### `lib/lockspire/admin/clients.ex`, `lib/lockspire/web/live/admin/clients_live/form_component.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`, `test/lockspire/web/live/admin/clients_live_test.exs`

**Use for:** client override flows, durable enum validation, route-per-workflow editing, and effective-policy display.

**Mutable field seam** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:12)):
```elixir
@mutable_fields ~w(name redirect_uris allowed_scopes logo_uri tos_uri policy_uri contacts par_policy dpop_policy metadata)a
```

**Safe update pipeline** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:111)):
```elixir
with {:ok, %Client{} = client} <- get_client(client_id),
     :ok <- reject_immutable_changes(attrs),
     :ok <- validate_safe_update(attrs) do
  Repository.update_client(client, normalize_update_attrs(attrs))
end
```

**Client DPoP validation pattern** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:239)):
```elixir
defp validate_dpop_policy_if_present(attrs) do
  case fetch_mutable_attr(attrs, :dpop_policy) do
    :error -> :ok
    {:ok, value} ->
      case normalize_dpop_policy(value) do
        {:ok, _policy} -> :ok
        :error -> {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: value}]}
      end
  end
end
```

**Normalization pattern** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:358)):
```elixir
defp normalize_dpop_policy(:inherit), do: {:ok, :inherit}
defp normalize_dpop_policy(:bearer), do: {:ok, :bearer}
defp normalize_dpop_policy(:dpop), do: {:ok, :dpop}
```

**Per-workflow form pattern** ([lib/lockspire/web/live/admin/clients_live/form_component.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/form_component.ex:115)):
```elixir
<div :if={@mode == :par_policy}>
  <label for="client_par_policy">Client PAR override</label>
  <select id="client_par_policy" name="client[par_policy]">
    <option value="inherit" selected={@defaults.par_policy == "inherit"}>
      Inherit from global policy
    </option>
```

**Show-page action routing pattern** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:45)):
```elixir
case params["mode"] do
  "edit" -> Admin.update_client(...)
  "redirects" -> Admin.update_client(...)
  "par_policy" ->
    Admin.update_client(socket.assigns.client_id, %{
      par_policy: params["par_policy"],
      actor: %{type: :operator, id: "admin-ui"}
    })
end
```

**Detail-page truth display** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:167)):
```elixir
<p>Global PAR policy: <code>{par_policy_label(@effective_par_policy.global_policy)}</code></p>
<p>Client PAR override: <code>{par_policy_label(@client.par_policy)}</code></p>
<p>Effective PAR requirement: <strong>{verdict_for(@effective_par_policy)}</strong></p>
```

**Route suffix pattern** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:343)):
```elixir
defp show_path(client_id, :show), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id
defp show_path(client_id, :par_policy), do: show_path(client_id, :show) <> "/par-policy"
```

**Workflow tests** ([test/lockspire/web/live/admin/clients_live_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/clients_live_test.exs:96)):
```elixir
assert Enum.any?(routes, &live_route?(&1, "/admin/clients/:client_id/par-policy", Show))
...
view
|> element("a", "Edit PAR policy")
|> render_click()
...
assert client.par_policy == :required
```

**Validation tests for enum round-trips** ([test/lockspire/admin/clients_test.exs](/Users/jon/projects/lockspire/test/lockspire/admin/clients_test.exs:259)):
```elixir
assert fetched_client.dpop_policy == :inherit
assert dpop_client.dpop_policy == :dpop
assert bearer_client.dpop_policy == :bearer
assert inherited_client.dpop_policy == :inherit
assert {:error, [%{field: :dpop_policy, reason: :invalid_dpop_policy, detail: "strict"}]} = ...
```

**Phase 35 guidance:** DPoP client override UX should reuse this exact pattern: new `:dpop_policy` action, dedicated route suffix, single-purpose form block, and effective/global/client state rendered together.

---

### `lib/lockspire/web/router.ex`

**Use for:** adding narrow admin policy and client-edit routes without introducing a new admin overview layer.

**Analog:** `lib/lockspire/web/router.ex`

**Route grouping pattern** ([lib/lockspire/web/router.ex](/Users/jon/projects/lockspire/lib/lockspire/web/router.ex:27)):
```elixir
live("/admin", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
live("/admin/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
live("/admin/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
...
live("/admin/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show)
live("/admin/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show)
```

**Phase 35 guidance:** add DPoP pages as sibling routes under `/admin/policies/*` and `/admin/clients/:client_id/*`, following the PAR route naming shape exactly.

## Shared Patterns

### Thin Phoenix Adapter
**Sources:** [userinfo controller](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/userinfo_controller.ex:13), [discovery builder](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:73)

Controllers should gather HTTP headers/params, delegate to protocol modules, and only own status/header/json shaping.

### DPoP Validator Truth
**Sources:** [token endpoint DPoP](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:22), [DPoP validator](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:36), [DPoP tests](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:146)

Use the same proof validation primitives everywhere. The proof/test seam already proves `htm`, `htu`, `iat`, `jti`, `typ`, allowed `alg`, and replay state. For userinfo, add `ath` and token `cnf.jkt` binding on top of this seam instead of inventing a parallel parser.

### Truthful Surface Guarded by Tests and Docs
**Sources:** [discovery controller test](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:30), [supported surface doc](/Users/jon/projects/lockspire/docs/supported-surface.md:42), [release readiness contract](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:191)

Public claims land in three places together: discovery metadata, `docs/supported-surface.md`, and release-readiness assertions. Keep all three aligned.

### Narrow Operator Policy Workflow
**Sources:** [PAR policy LiveView](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/par.ex:13), [client show LiveView](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:45), [clients form component](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/form_component.ex:115)

Global policy is a focused page. Client override is a focused workflow. Each flow updates one explicit enum and re-renders durable truth. Avoid a combined “all token policies” editor.

### Explicit Durable Enum Mapping
**Sources:** [admin clients](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:239), [server policy](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:44), [DPoP policy resolver](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_policy.ex:26)

Persist DPoP mode in enum fields (`ServerPolicy.dpop_policy`, `Client.dpop_policy`) and derive effective behavior from those enums. Do not hide DPoP mode in generic metadata.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/lockspire/protocol/protected_resource_dpop.ex` | service | request-response | No existing protected-resource DPoP consumer exists yet; copy structure from `token_endpoint_dpop.ex` and add `ath` + token `cnf` enforcement. |

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/web/controllers`, `lib/lockspire/web/live/admin`, `lib/lockspire/admin`, `test/lockspire/web`, `test/lockspire/admin`, `test/lockspire/protocol`, `docs`

**Files scanned:** 22
**Pattern extraction date:** 2026-04-28
