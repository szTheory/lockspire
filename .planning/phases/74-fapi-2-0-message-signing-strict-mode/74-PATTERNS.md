# Phase 74: FAPI 2.0 Message Signing Strict Mode - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/security_profile.ex` | utility | transform | `lib/lockspire/protocol/security_profile.ex` | exact |
| `lib/lockspire/admin/server_policy.ex` | service | CRUD | `lib/lockspire/admin/server_policy.ex` | exact |
| `lib/lockspire/admin/clients.ex` | service | CRUD | `lib/lockspire/admin/clients.ex` | exact |
| `lib/lockspire/protocol/fapi20_enforcer_plug.ex` | middleware | request-response | `lib/lockspire/protocol/fapi20_enforcer_plug.ex` | exact |
| `lib/lockspire/protocol/authorization_request.ex` | service | request-response | `lib/lockspire/protocol/authorization_request.ex` | exact |
| `lib/lockspire/web/controllers/introspection_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/introspection_controller.ex` | exact |
| `lib/lockspire/web/live/admin/policies_live/security_profile.ex` | component | CRUD | `lib/lockspire/web/live/admin/policies_live/security_profile.ex` | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component | request-response | `lib/lockspire/web/live/admin/clients_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | component | transform | `lib/lockspire/web/live/admin/clients_live/form_component.ex` | exact |
| `test/lockspire/protocol/security_profile_test.exs` | test | transform | `test/lockspire/protocol/security_profile_test.exs` | exact |
| `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` | test | CRUD | `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` | exact |
| `test/lockspire/web/introspection_controller_test.exs` | test | request-response | `test/lockspire/web/introspection_controller_test.exs` | exact |
| `test/integration/phase41_fapi_2_0_e2e_test.exs` | test | request-response | `test/integration/phase41_fapi_2_0_e2e_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/protocol/security_profile.ex` (utility, transform)

**Analog:** `lib/lockspire/protocol/security_profile.ex`

Use this module as the single source of truth for enum expansion, inheritance resolution, and boolean convenience flags. Phase 74 should extend this struct rather than inventing a parallel toggle.

**Resolver struct and monotonic flags** ([lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:8)):
```elixir
@type mode :: :inherit | :fapi_2_0_security | :none

defmodule Resolved do
  @type t :: %__MODULE__{
          global_profile: ServerPolicy.security_profile(),
          client_profile: Lockspire.Protocol.SecurityProfile.mode(),
          effective_profile: ServerPolicy.security_profile(),
          fapi_2_0_security?: boolean()
        }

  defstruct global_profile: :none,
            client_profile: :inherit,
            effective_profile: :none,
            fapi_2_0_security?: false
end
```

**Canonical effective-profile resolution** ([lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:26)):
```elixir
def resolve_effective_profile(%ServerPolicy{} = server_policy, client) do
  client_profile = normalize_client_profile(client)
  effective_profile = effective_profile(server_policy.security_profile, client_profile)

  %Resolved{
    global_profile: server_policy.security_profile,
    client_profile: client_profile,
    effective_profile: effective_profile,
    fapi_2_0_security?: effective_profile == :fapi_2_0_security
  }
end
```

**Normalization pattern** ([lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:39)):
```elixir
defp normalize_client_profile(nil), do: :inherit

defp normalize_client_profile(client) do
  case Map.get(client, :security_profile, :inherit) do
    :fapi_2_0_security -> :fapi_2_0_security
    :none -> :none
    _other -> :inherit
  end
end
```

**Profile-driven algorithm policy** ([lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:53)):
```elixir
@spec allowed_signing_algorithms(ServerPolicy.security_profile()) :: [String.t()]
def allowed_signing_algorithms(:fapi_2_0_security), do: ["ES256", "PS256"]
def allowed_signing_algorithms(:none), do: ["RS256", "ES256", "PS256", "EdDSA"]
```

**Phase 74 reuse:** add `:fapi_2_0_message_signing` here first, then derive any new booleans (`fapi_2_0_security?` should remain true for the stricter tier if monotonic semantics are desired).

---

### `lib/lockspire/admin/server_policy.ex` (service, CRUD)

**Analog:** `lib/lockspire/admin/server_policy.ex`

Global policy writes use a normalize-then-validate-then-persist pattern. Readiness checks return list-shaped field errors for LiveView rendering.

**Update seam** ([lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:67)):
```elixir
@spec put_security_profile(atom() | String.t()) ::
        {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
def put_security_profile(profile) do
  with {:ok, normalized_profile} <- normalize_security_profile(profile),
       :ok <- validate_fapi_signing_readiness(normalized_profile) do
    Repository.update_server_policy(fn %ServerPolicy{} = current ->
      %ServerPolicy{current | security_profile: normalized_profile}
    end)
  end
end
```

**Readiness gate returning field errors** ([lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:78)):
```elixir
defp validate_fapi_signing_readiness(:fapi_2_0_security) do
  case Repository.validate_fapi_signing_readiness() do
    :ok ->
      :ok

    {:error, reason}
    when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] ->
      {:error,
       [
         %{
           field: :security_profile,
           reason: reason,
           detail: :fapi_2_0_security
         }
       ]}

    {:error, _term} = err ->
      err
  end
end
```

**Enum normalization pattern** ([lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:181)):
```elixir
defp normalize_security_profile(:none), do: {:ok, :none}
defp normalize_security_profile(:fapi_2_0_security), do: {:ok, :fapi_2_0_security}

defp normalize_security_profile(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "none" -> {:ok, :none}
    "fapi_2_0_security" -> {:ok, :fapi_2_0_security}
    _other -> invalid_security_profile(value)
  end
end
```

**Phase 74 reuse:** extend the enum and keep the same list-shaped error contract for missing signing/JARM/JWT-introspection prerequisites.

---

### `lib/lockspire/admin/clients.ex` (service, CRUD)

**Analog:** `lib/lockspire/admin/clients.ex`

Per-client overrides follow the same enum validation as server policy, plus transition-sensitive readiness checks. This is the correct pattern for per-client `security_profile` upgrades.

**Validation pipeline hook** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:212)):
```elixir
errors =
  []
  |> maybe_append_errors(validate_redirects_if_present(attrs))
  |> maybe_append_errors(validate_post_logout_redirects_if_present(attrs))
  |> maybe_append_errors(validate_logout_propagation(attrs, effective_redirect_uris(client, attrs)))
  |> maybe_append_errors(validate_scopes_if_present(attrs))
  |> maybe_append_errors(validate_par_policy_if_present(attrs))
  |> maybe_append_errors(validate_dpop_policy_if_present(attrs))
  |> maybe_append_errors(validate_security_profile_if_present(client, attrs))
```

**Per-client override validation** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:317)):
```elixir
defp validate_security_profile_if_present(client, attrs) do
  case fetch_mutable_attr(attrs, :security_profile) do
    :error ->
      :ok

    {:ok, value} ->
      with {:ok, profile} <- normalize_security_profile(value),
           :ok <- check_fapi_signing_readiness(client.security_profile, profile) do
        :ok
      else
        :error ->
          {:error,
           [%{field: :security_profile, reason: :invalid_security_profile, detail: value}]}

        {:error, reason}
        when reason in [:missing_compliant_active_key, :missing_compliant_publishable_key] ->
          {:error, [%{field: :security_profile, reason: reason, detail: :fapi_2_0_security}]}
      end
  end
end
```

**Transition-aware readiness helper** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:338)):
```elixir
@doc false
def check_fapi_signing_readiness(:fapi_2_0_security, :fapi_2_0_security), do: :ok

def check_fapi_signing_readiness(_old_profile, :fapi_2_0_security) do
  Repository.validate_fapi_signing_readiness()
end

def check_fapi_signing_readiness(_old_profile, _new_profile), do: :ok
```

**Normalization for persisted mutable attrs** ([lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:406)):
```elixir
defp normalize_mutable_field(:security_profile, value) do
  case normalize_security_profile(value) do
    {:ok, profile} -> profile
    :error -> value
  end
end
```

**Phase 74 reuse:** keep the same pattern and expand it for `:fapi_2_0_message_signing`, including no-op behavior for same-profile edits and readiness checks only when entering the strict tier.

---

### `lib/lockspire/protocol/fapi20_enforcer_plug.ex` (middleware, request-response)

**Analog:** `lib/lockspire/protocol/fapi20_enforcer_plug.ex`

This file is the precedent for coarse path/header fail-fast enforcement only. Phase 74 context explicitly says not to place JARM or JWT-introspection strictness here.

**Route dispatch boundary** ([lib/lockspire/protocol/fapi20_enforcer_plug.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/fapi20_enforcer_plug.ex:39)):
```elixir
def call(conn, opts) do
  case conn.path_info do
    ["authorize"] -> with_resolved_profile(conn, opts, &enforce_authorize/2)
    ["token"] -> with_resolved_profile(conn, opts, &enforce_token/2)
    ["userinfo"] -> with_resolved_profile(conn, opts, &enforce_userinfo/2)
    _other -> conn
  end
end
```

**Resolved-profile gate** ([lib/lockspire/protocol/fapi20_enforcer_plug.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/fapi20_enforcer_plug.ex:53)):
```elixir
case policy_fn.() do
  {:ok, %ServerPolicy{} = server_policy} ->
    client = fetch_client(conn)
    resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

    if resolved.fapi_2_0_security? do
      enforcement_fn.(conn, resolved)
    else
      conn
    end

  {:error, _reason} ->
    fail_closed(conn)
end
```

**Fail-fast JSON/redirect rejection pattern** ([lib/lockspire/protocol/fapi20_enforcer_plug.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/fapi20_enforcer_plug.ex:127)):
```elixir
error_params = %{
  "error" => "invalid_request",
  "error_description" => "request_uri from the PAR endpoint is required"
}

if valid_redirect_uri?(redirect_uri) do
  conn
  |> put_resp_header("location", location)
  |> send_resp(302, "")
  |> halt()
else
  conn
  |> put_resp_content_type("application/json")
  |> send_resp(400, Jason.encode!(error_params))
  |> halt()
end
```

**Telemetry emission pattern** ([lib/lockspire/protocol/fapi20_enforcer_plug.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/fapi20_enforcer_plug.ex:111)):
```elixir
metadata = %{
  client_id: client_id,
  reason: reason,
  path_info: conn.path_info
}

Observability.emit(:fapi20, :failed, %{}, metadata)
```

**Phase 74 reuse:** leave this Plug as the Phase 41 coarse guard. If touched, only extend monotonic strict-tier detection; do not duplicate response-mode negotiation or introspection media-type logic here.

---

### `lib/lockspire/protocol/authorization_request.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/authorization_request.ex`

This is the right place for strict JARM enforcement because it already has validated client state, resolved security profile, redirect-safe error shaping, and response-mode parsing.

**Profile resolution early in validation** ([lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:91)):
```elixir
with {:ok, %Client{} = client} <- fetch_client(params),
     {:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
     {:ok, resolved_security_profile} <- resolve_effective_security_profile(client),
     :ok <-
       maybe_require_pushed_authorization_request(
         params,
         client,
         resolved_par_policy,
         resolved_security_profile
       ),
     {:ok, resolved_params} <- resolve_authorization_params(params, client),
     {:ok, resolved_params} <-
       maybe_consume_request_object(resolved_params, client,
         security_profile: resolved_security_profile
       ),
     {:ok, %Validated{} = validated} <-
       validate_with_client(resolved_params, client,
         security_profile: resolved_security_profile
       ) do
```

**Redirect-safe error construction** ([lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:251)):
```elixir
defp par_required_error(params, %Client{} = client) do
  case validate_redirect_uri(client, params) do
    {:ok, _redirect_uri} ->
      {:redirect_error,
       redirect_error(
         params,
         :invalid_request,
         "request_uri from the PAR endpoint is required",
         :par_required_request_uri
       )}

    {:browser_error, %Error{}} ->
      {:browser_error,
       browser_error(
         :invalid_request,
         "request_uri from the PAR endpoint is required",
         :par_required_request_uri
       )}
  end
end
```

**Validation pipeline where new strict response-mode checks belong** ([lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:291)):
```elixir
with :ok <- maybe_validate_pushed_client_id(params, client, pushed?),
     :ok <- maybe_reject_inbound_request_uri(params, pushed?),
     {:ok, redirect_uri} <- validate_redirect_uri(client, params),
     {:ok, scopes} <- validate_scopes(client, params),
     {:ok, prompt} <- validate_prompt(params),
     {:ok, max_age} <- validate_max_age(params),
     :ok <- validate_response_type(params),
     {:ok, response_mode} <- validate_response_mode(params),
     :ok <- validate_nonce(params, scopes),
     :ok <- validate_pkce(client, params, security_profile: security_profile),
```

**Current response-mode parsing contract** ([lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:475)):
```elixir
defp validate_response_mode(%{"response_mode" => mode} = params) when is_binary(mode) do
  if MapSet.member?(@allowed_response_modes, mode) do
    {:ok, resolve_default_delivery_mode(mode, params["response_type"])}
  else
    {:redirect_error,
     redirect_error(
       params,
       :invalid_request,
       "response_mode is invalid or unsupported",
       :invalid_response_mode
     )}
  end
end

defp validate_response_mode(params) do
  {:ok, resolve_default_delivery_mode(nil, params["response_type"])}
end

defp resolve_default_delivery_mode("jwt", "code"), do: "query.jwt"
defp resolve_default_delivery_mode(nil, "code"), do: "query"
```

**Phase 74 reuse:** add strict-mode checks immediately around `validate_response_mode/1` or in a follow-on validator that receives `resolved_security_profile` and the resolved mode. Preserve the existing redirect-safe `{:redirect_error, %Error{}}` contract and explicit reason codes.

---

### `lib/lockspire/web/controllers/introspection_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/introspection_controller.ex`

This controller is already the wire-format adapter for Accept negotiation. Phase 74 strict JWT-introspection enforcement belongs here, backed by protocol-owned caller/profile helpers if needed.

**Thin controller over protocol result** ([lib/lockspire/web/controllers/introspection_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/introspection_controller.ex:18)):
```elixir
def create(conn, params) do
  authorization = List.first(get_req_header(conn, "authorization"))

  wants_jwt? = accepts_introspection_jwt?(conn)

  case Introspection.introspect(%{
         params: params,
         authorization: authorization,
         opts: [client_store: Repository, token_store: Repository, consent_store: Repository]
       }) do
    {:ok, %Success{} = success} ->
      conn
      |> put_cache_headers()
      |> maybe_put_vary_accept(wants_jwt?)
      |> render_success(success, wants_jwt?)

    {:error, %Error{} = error} ->
      conn
      |> put_cache_headers()
      |> maybe_put_www_authenticate(error)
      |> put_status(error.status)
      |> json(IntrospectionJSON.error_response(error))
  end
end
```

**JWT response rendering seam** ([lib/lockspire/web/controllers/introspection_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/introspection_controller.ex:55)):
```elixir
defp render_success(conn, %Success{} = success, true) do
  case IntrospectionJwt.sign(%{
         success: success,
         issuer: Config.issuer!(),
         issued_at: DateTime.utc_now(),
         key_store: Repository
       }) do
    {:ok, jwt} ->
      conn
      |> put_resp_header("content-type", @jwt_media_type)
      |> send_resp(:ok, jwt)

    {:error, _reason} ->
      conn
      |> put_status(:internal_server_error)
      |> json(IntrospectionJSON.error_response(server_error()))
  end
end
```

**Accept parsing contract** ([lib/lockspire/web/controllers/introspection_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/introspection_controller.ex:80)):
```elixir
defp accepts_introspection_jwt?(conn) do
  conn
  |> get_req_header("accept")
  |> Enum.flat_map(&Plug.Conn.Utils.list/1)
  |> Enum.reduce_while(:absent, fn entry, _acc ->
    case parse_accept_entry(entry) do
      {:ok, {@jwt_media_type, q}} when q > 0.0 -> {:halt, true}
      {:ok, {@jwt_media_type, _q}} -> {:cont, false}
      {:ok, _other} -> {:cont, :absent}
      :error -> {:halt, false}
    end
  end)
  |> Kernel.==(true)
end
```

**Phase 74 reuse:** strict mode should reject missing/wildcard/JSON-only/malformed negotiation before success fallback, while preserving current JSON OAuth error handling for failures.

---

### `lib/lockspire/web/live/admin/policies_live/security_profile.ex` (component, CRUD)

**Analog:** `lib/lockspire/web/live/admin/policies_live/security_profile.ex`

Global admin policy pages use a bounded form + summary pattern. Errors are rendered from the same field-error list returned by admin services.

**Mount and derived summary state** ([lib/lockspire/web/live/admin/policies_live/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/security_profile.ex:13)):
```elixir
socket
|> assign(
  page_title: "Security profile",
  current_section: :policies,
  policy: nil,
  summary: %{inherit: 0, fapi_2_0_security: 0, none: 0},
  form_errors: []
)
|> load_policy()
|> load_summary()
```

**Save-event pattern** ([lib/lockspire/web/live/admin/policies_live/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/security_profile.ex:33)):
```elixir
case Admin.put_security_profile(profile) do
  {:ok, %ServerPolicy{} = policy} ->
    {:noreply,
     socket
     |> assign(policy: policy, form_errors: [])
     |> put_flash(:info, "Global security profile updated")}

  {:error, errors} when is_list(errors) ->
    {:noreply, assign(socket, form_errors: errors)}

  {:error, _reason} ->
    {:noreply,
     assign(socket,
       form_errors: [%{field: :security_profile, reason: :request_failed, detail: nil}]
     )}
end
```

**Calm bounded explanation copy** ([lib/lockspire/web/live/admin/policies_live/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/security_profile.ex:64)):
```heex
<select id="security_profile" name="policy[security_profile]">
  <option value="none" selected={@policy.security_profile == :none}>None (Standard OIDC)</option>
  <option value="fapi_2_0_security" selected={@policy.security_profile == :fapi_2_0_security}>FAPI 2.0 Security Profile</option>
</select>
<p class="lockspire-admin-help">
  <strong>None (Standard OIDC):</strong> Baseline OIDC/OAuth 2.0 security.
  <br />
  <strong>FAPI 2.0 Security Profile:</strong> Strict enforcement of FAPI 2.0 requirements (mandatory PAR, DPoP, S256 PKCE). Rejects non-compliant requests.
</p>
```

**Derived summary from stored clients** ([lib/lockspire/web/live/admin/policies_live/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/security_profile.ex:125)):
```elixir
{:ok, clients} = Admin.list_clients()

summary =
  Enum.reduce(clients, %{inherit: 0, fapi_2_0_security: 0, none: 0}, fn %Client{
                                                                          security_profile: mode
                                                                        },
                                                                        acc ->
    Map.update!(acc, mode, &(&1 + 1))
  end)
```

**Phase 74 reuse:** extend this page instead of creating a new console. Add the new tier, plus one bounded readiness/remediation panel fed by canonical server-side helpers.

---

### `lib/lockspire/web/live/admin/clients_live/show.ex` (component, request-response)

**Analog:** `lib/lockspire/web/live/admin/clients_live/show.ex`

Per-client detail pages already expose global override, client override, effective result, and a warning for mixed-mode bypass. This is the right home for effective message-signing posture.

**Detail-page visibility pattern** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:159)):
```heex
<p>Global security profile: <code>{security_profile_label(@effective_security_profile.global_profile)}</code></p>
<p>Client security override: <code>{security_profile_label(@client.security_profile)}</code></p>
<p>Effective security profile: <strong>{security_verdict_for(@effective_security_profile)}</strong></p>
<div
  :if={mixed_mode_override?(@effective_security_profile)}
  class="lockspire-admin-warning"
  role="alert"
>
  <strong>Warning:</strong> This client overrides the global FAPI 2.0 Security Profile
  to None. FAPI 2.0 boundary checks (PAR, DPoP) will NOT be enforced for this client.
</div>
```

**Canonical effective-policy reuse** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:475)):
```elixir
defp resolve_effective_security_profile(%Client{} = client) do
  SecurityProfile.resolve_effective_profile(server_policy(), client)
end
```

**String-label and verdict helpers** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:490)):
```elixir
defp security_profile_label(profile) when profile in [:inherit, :fapi_2_0_security, :none] do
  Atom.to_string(profile)
end

defp security_verdict_for(%{effective_profile: :fapi_2_0_security}),
  do: "FAPI 2.0 Security Profile"

defp security_verdict_for(%{effective_profile: :none}), do: "None (Standard OIDC)"
```

**Workflow routing pattern** ([lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:543)):
```elixir
defp save_client_attrs(%{"mode" => "security_profile"} = params, _client) do
  %{security_profile: params["security_profile"], actor: %{type: :operator, id: "admin-ui"}}
end
```

**Phase 74 reuse:** add an effective message-signing readiness panel here, not a second page. Compute it from canonical helpers, alongside the existing effective-profile display and mixed-mode warnings.

---

### `lib/lockspire/web/live/admin/clients_live/form_component.ex` (component, transform)

**Analog:** `lib/lockspire/web/live/admin/clients_live/form_component.ex`

Per-client edits use mode-specific forms with contextual help derived from effective policy state.

**Mode-driven form rendering** ([lib/lockspire/web/live/admin/clients_live/form_component.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/form_component.ex:14)):
```elixir
assigns =
  assigns
  |> assign(:title, title_for(assigns.mode))
  |> assign(:button_label, button_for(assigns.mode))
  |> assign(:defaults, defaults_for(assigns.mode, assigns.client))
```

**Security-profile edit block** ([lib/lockspire/web/live/admin/clients_live/form_component.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/form_component.ex:169)):
```heex
<label for="client_security_profile">Client security profile override</label>
<select id="client_security_profile" name="client[security_profile]">
  <option value="inherit" selected={@defaults.security_profile == "inherit"}>
    Inherit from global policy
  </option>
  <option
    value="fapi_2_0_security"
    selected={@defaults.security_profile == "fapi_2_0_security"}
  >
    FAPI 2.0 Security Profile
  </option>
  <option value="none" selected={@defaults.security_profile == "none"}>
    None (Standard OIDC)
  </option>
</select>

<div :if={@effective_security_profile} class="lockspire-admin-help">
  <p>
    <strong>Global policy:</strong> {@effective_security_profile.global_profile}
  </p>
  <p>
    <strong>Effective profile:</strong> {if @effective_security_profile.effective_profile ==
                                             :fapi_2_0_security,
      do: "FAPI 2.0 Security Profile",
      else: "None (Standard OIDC)"}
  </p>
</div>
```

**Error rendering contract** ([lib/lockspire/web/live/admin/clients_live/form_component.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/form_component.ex:250)):
```elixir
def error_list(assigns) do
  ~H"""
  <ul :if={@errors != []} class="lockspire-admin-errors">
    <%= for error <- @errors do %>
      <li>{format_error(error)}</li>
    <% end %>
  </ul>
  """
end
```

**Phase 74 reuse:** keep the same workflow and extend the select/help copy for `:fapi_2_0_message_signing`. If remediation details are shown during edit, source them from the same readiness helper used by the show page.

---

### Test Patterns

#### `test/lockspire/protocol/security_profile_test.exs` (unit semantics)

**Analog:** `test/lockspire/protocol/security_profile_test.exs`

Use table-style unit tests to prove global/client inheritance, explicit opt-in, explicit opt-out, nil client handling, and algorithm restrictions.

**Effective-profile assertions** ([test/lockspire/protocol/security_profile_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/security_profile_test.exs:9)):
```elixir
resolved = SecurityProfile.resolve_effective_profile(server_policy, client)

assert %Resolved{} = resolved
assert resolved.global_profile == :fapi_2_0_security
assert resolved.client_profile == :inherit
assert resolved.effective_profile == :fapi_2_0_security
assert resolved.fapi_2_0_security? == true
```

**Algorithm-policy assertions** ([test/lockspire/protocol/security_profile_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/security_profile_test.exs:98)):
```elixir
algorithms = SecurityProfile.allowed_signing_algorithms(:fapi_2_0_security)
assert algorithms == ["ES256", "PS256"]
```

**Phase 74 reuse:** add strict-tier cases here first. This is the canonical place to prove monotonic resolution semantics.

#### `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` (global policy LiveView)

**Analog:** `test/lockspire/web/live/admin/policies_live/security_profile_test.exs`

This repo proves admin policy behavior by rendering the page, submitting the form, and asserting persisted state plus rendered copy.

**Route/render pattern** ([test/lockspire/web/live/admin/policies_live/security_profile_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/policies_live/security_profile_test.exs:71)):
```elixir
assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/security-profile")

assert html =~ "Global security profile"
assert html =~ "Save global security profile"
assert html =~ "Current profile is None (Standard OIDC)"
```

**Submit-and-reload pattern** ([test/lockspire/web/live/admin/policies_live/security_profile_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/policies_live/security_profile_test.exs:88)):
```elixir
view
|> form("form[phx-submit=save_policy]", %{policy: %{security_profile: "fapi_2_0_security"}})
|> render_submit()

assert {:ok, %{security_profile: :fapi_2_0_security}} = Admin.get_server_policy()
```

**Field-error pattern** ([test/lockspire/web/live/admin/policies_live/security_profile_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/live/admin/policies_live/security_profile_test.exs:124)):
```elixir
html =
  view
  |> render_submit("save_policy", %{policy: %{security_profile: "invalid"}})

assert html =~ "security_profile"
assert html =~ "invalid_security_profile"
```

**Phase 74 reuse:** extend these tests for the new enum option and readiness/remediation copy when strict prerequisites are missing.

#### `test/lockspire/web/introspection_controller_test.exs` (controller negotiation)

**Analog:** `test/lockspire/web/introspection_controller_test.exs`

Use controller tests for content negotiation matrix, response headers, JWT claim shape, and JSON fallback.

**JWT-success contract** ([test/lockspire/web/introspection_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/introspection_controller_test.exs:192)):
```elixir
conn =
  build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
  |> put_req_header("authorization", basic_auth(client.client_id, secret))
  |> put_req_header("accept", "application/token-introspection+jwt")
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

assert conn.status == 200
assert get_resp_header(conn, "content-type") == ["application/token-introspection+jwt"]
assert get_resp_header(conn, "vary") == ["Accept"]
```

**Negotiation matrix pattern** ([test/lockspire/web/introspection_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/introspection_controller_test.exs:245)):
```elixir
requests = [
  [],
  [{"accept", "*/*"}],
  [{"accept", "application/json"}],
  [{"accept", "application/token-introspection+jwt;q=0, application/json;q=1.0"}],
  [{"accept", "application/json; q=bogus"}]
]

Enum.each(requests, fn headers ->
  ...
  assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
end)
```

**Weighted q-value precedence pattern** ([test/lockspire/web/introspection_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/introspection_controller_test.exs:271)):
```elixir
|> put_req_header(
  "accept",
  "application/json;q=0.9, application/token-introspection+jwt;q=0.1"
)
...
|> put_req_header(
  "accept",
  "application/token-introspection+jwt;q=0, application/json;q=1.0"
)
```

**Phase 74 reuse:** convert the current fallback cases into rejection cases only when the effective client/profile is `:fapi_2_0_message_signing`, while preserving baseline optional behavior outside that profile.

#### `test/integration/phase41_fapi_2_0_e2e_test.exs` (full strict-profile proof)

**Analog:** `test/integration/phase41_fapi_2_0_e2e_test.exs`

This is the existing precedent for proving strict profile behavior across endpoint boundaries and mixed-mode overrides.

**Per-client opt-in under global none** ([test/integration/phase41_fapi_2_0_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase41_fapi_2_0_e2e_test.exs:239)):
```elixir
put_security_profile!(:none)

assert {:ok, _client} =
         Repository.update_client(client, %{security_profile: :fapi_2_0_security})

authorize_conn =
  build_conn(:get, "/authorize", %{
    "client_id" => client.client_id,
    "response_type" => "code",
    "redirect_uri" => "https://client.example.com/callback",
    "scope" => "openid",
    "code_challenge" => code_challenge("phase41-opt-in-verifier"),
    "code_challenge_method" => "S256"
  })
  |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
```

**Mixed-mode escape hatch** ([test/integration/phase41_fapi_2_0_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase41_fapi_2_0_e2e_test.exs:262)):
```elixir
put_security_profile!(:fapi_2_0_security)
assert {:ok, _client} = Repository.update_client(client, %{security_profile: :none})
...
refute evidence =~ "request_uri+from+the+PAR+endpoint+is+required"
```

**Phase 74 reuse:** add a new integration file or extend this style to prove strict message-signing opt-in, global strict mode, and `:none` escape hatch behavior across `/authorize` and `/introspect`.

## Shared Patterns

### One Canonical Security-Profile Plane

**Sources:** [lib/lockspire/protocol/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/security_profile.ex:26), [lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:67), [lib/lockspire/admin/clients.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex:317)

Apply to all Phase 74 runtime and admin work. Add the new enum once, resolve it once, validate it once, then reuse that resolution everywhere.

```elixir
resolved = SecurityProfile.resolve_effective_profile(server_policy, client)
```

### Enforcement Placement By Context

**Sources:** [lib/lockspire/protocol/fapi20_enforcer_plug.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/fapi20_enforcer_plug.ex:39), [lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:291), [lib/lockspire/web/controllers/introspection_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/introspection_controller.ex:18)

Use three layers consistently:

- Plug: coarse path/header fail-fast only.
- Protocol validator: redirect-safe `/authorize` correctness with resolved client/profile state.
- Controller: wire-format negotiation and HTTP response selection for `/introspect`.

### Admin Visibility Must Reuse Runtime Truth

**Sources:** [lib/lockspire/web/live/admin/clients_live/show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:475), [lib/lockspire/web/live/admin/policies_live/security_profile.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/security_profile.ex:125)

Do not invent UI-only readiness logic. Derive effective posture from the same canonical profile and readiness helpers used by runtime validation.

### Error Contract Shape

**Sources:** [lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:251), [lib/lockspire/admin/server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:78), [lib/lockspire/web/controllers/introspection_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/introspection_controller.ex:34)

Keep existing shapes:

- `/authorize`: `{:redirect_error, %Error{}}` or `{:browser_error, %Error{}}`
- Admin writes: `{:error, [%{field:, reason:, detail:}]}`
- `/introspect`: OAuth JSON error bodies even when JWT success is enforced

### Test Layering

**Sources:** protocol unit tests, LiveView tests, controller tests, integration tests above

Phase 74 should preserve the existing split:

- protocol semantics in `test/lockspire/protocol/...`
- wire behavior in `test/lockspire/web/...`
- operator UX in `test/lockspire/web/live/...`
- end-to-end strict-profile proof in `test/integration/...`

## No Analog Found

None required. The existing Phase 41 security-profile work, Phase 73 introspection controller work, and current admin security-profile LiveViews already provide the concrete seams Phase 74 should extend.

## Metadata

**Analog search scope:** `lib/lockspire/protocol`, `lib/lockspire/admin`, `lib/lockspire/web/controllers`, `lib/lockspire/web/live/admin`, `test/lockspire/protocol`, `test/lockspire/web`, `test/integration`
**Files scanned:** 13 source/test files plus Phase 74 planning context
**Pattern extraction date:** 2026-05-08
