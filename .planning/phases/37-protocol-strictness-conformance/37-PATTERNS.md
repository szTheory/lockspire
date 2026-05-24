# Phase 37: Protocol Strictness & Conformance - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 17
**Analogs found:** 15 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/authorization_request.ex` | service | request-response | `lib/lockspire/protocol/authorization_request.ex` | exact |
| `lib/lockspire/protocol/authorization_flow.ex` | service | event-driven | `lib/lockspire/protocol/authorization_flow.ex` | exact |
| `lib/lockspire/web/controllers/authorize_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/authorize_controller.ex` | exact |
| `lib/lockspire/protocol/id_token.ex` | service | transform | `lib/lockspire/protocol/id_token.ex` | exact |
| `lib/lockspire/host/claims.ex` | utility | transform | `lib/lockspire/host/claims.ex` | exact |
| `lib/lockspire/host/account_resolver.ex` | provider | request-response | `lib/lockspire/host/account_resolver.ex` | exact |
| `lib/lockspire/domain/interaction.ex` | model | CRUD | `lib/lockspire/domain/interaction.ex` | exact |
| `lib/lockspire/storage/ecto/interaction_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/interaction_record.ex` | exact |
| `priv/repo/migrations/*_add_lockspire_interaction_auth_time.exs` | migration | CRUD | `priv/repo/migrations/20260423020100_extend_authorization_core_state.exs` | role-match |
| `test/lockspire/protocol/authorization_request_test.exs` | test | request-response | `test/lockspire/protocol/authorization_request_test.exs` | exact |
| `test/lockspire/protocol/authorization_flow_test.exs` | test | event-driven | `test/lockspire/protocol/authorization_flow_test.exs` | exact |
| `test/lockspire/web/authorize_controller_test.exs` | test | request-response | `test/lockspire/web/authorize_controller_test.exs` | exact |
| `test/integration/phase37_protocol_strictness_e2e_test.exs` or updates to `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` | test | request-response | `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` | role-match |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `docs/supported-surface.md` | docs | transform | `docs/supported-surface.md` | exact |
| `scripts/conformance/*` | utility | batch | none in repo | no-analog |

## Pattern Assignments

### `lib/lockspire/protocol/authorization_request.ex` (service, request-response)

**Analog:** `lib/lockspire/protocol/authorization_request.ex`

**Imports and validated-contract pattern** ([lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:6)):
```elixir
alias Lockspire.Config
alias Lockspire.Domain.Client
alias Lockspire.Domain.PushedAuthorizationRequest
alias Lockspire.Observability
alias Lockspire.Protocol.ParPolicy
alias Lockspire.Protocol.RequestObject
alias Lockspire.Security.Policy
alias Lockspire.Storage.Ecto.Repository
```

**Validation pipeline pattern** ([authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:69)):
```elixir
def validate(params) when is_map(params) do
  with {:ok, %Client{} = client} <- fetch_client(params),
       {:ok, resolved_par_policy} <- resolve_effective_par_policy(client),
       :ok <- maybe_require_pushed_authorization_request(params, client, resolved_par_policy),
       {:ok, resolved_params} <- resolve_authorization_params(params, client),
       {:ok, resolved_params} <- maybe_consume_request_object(resolved_params, client),
       {:ok, %Validated{} = validated} <- validate_with_client(resolved_params, client) do
    validated = %Validated{validated | client: client}
    Observability.emit(:authorization_request_accepted, %{}, %{client_id: client.client_id, redirect_safe: true})
    {:ok, validated}
  else
    {:browser_error, %Error{} = error} ->
      emit_rejection(params["client_id"], error, false)
      {:browser_error, error}

    {:redirect_error, %Error{} = error} ->
      emit_rejection(params["client_id"], error, true)
      {:redirect_error, error}
  end
end
```

**Prompt validation pattern** ([authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:295)):
```elixir
defp validate_prompt(params) do
  prompt =
    params["prompt"]
    |> normalize_optional_string()
    |> case do
      nil -> []
      value -> String.split(value, " ", trim: true)
    end

  cond do
    prompt == [] ->
      {:ok, []}

    length(prompt) != length(Enum.uniq(prompt)) ->
      {:redirect_error,
       redirect_error(params, :invalid_request, "prompt values must be unique", :duplicate_prompt)}

    Enum.any?(prompt, &(&1 in ["none", "select_account"])) ->
      {:redirect_error,
       redirect_error(params, :invalid_request, "prompt value is not supported", :unsupported_prompt)}

    Enum.all?(prompt, &MapSet.member?(@allowed_prompts, &1)) ->
      {:ok, prompt}

    true ->
      {:redirect_error,
       redirect_error(params, :invalid_request, "prompt value is invalid", :invalid_prompt)}
  end
end
```

**What to copy for Phase 37**
- Keep the `with` pipeline shape and the `{:browser_error, ...}` vs `{:redirect_error, ...}` split.
- Extend `Validated` rather than passing loose maps.
- Put `prompt=none`, `max_age`, and any essential-claim parsing here before host handoff.
- Reuse strict redirect-safe error construction through `redirect_error/4`, not controller-specific ad hoc logic.

---

### `lib/lockspire/protocol/authorization_flow.ex` (service, event-driven)

**Analog:** `lib/lockspire/protocol/authorization_flow.ex`

**Entry-point branching pattern** ([authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:17)):
```elixir
def start_authorization(%Validated{} = validated, subject_context, opts \\ []) do
  now = now(opts)
  interaction_id = generate_interaction_id(opts)

  if login_required?(validated.prompt, subject_context) do
    validated
    |> build_interaction(interaction_id, nil, :pending_login, now)
    |> persist_login_required(opts)
  else
    start_subject_authorization(validated, subject_context, interaction_id, now, opts)
  end
end
```

**Durable interaction build pattern** ([authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:187)):
```elixir
defp build_interaction(%Validated{} = validated, interaction_id, subject_id, status, now) do
  %Interaction{
    interaction_id: interaction_id,
    client_id: validated.client_id,
    account_id: subject_id,
    scopes_requested: validated.scopes,
    prompt: validated.prompt,
    nonce: validated.nonce,
    redirect_uri: validated.redirect_uri,
    return_to: default_return_to(interaction_id),
    state: validated.state,
    code_challenge: validated.code_challenge,
    code_challenge_method: validated.code_challenge_method,
    status: status,
    login_required_at: if(status == :pending_login, do: now),
    consent_requested_at: if(status == :pending_consent, do: now),
    expires_at: DateTime.add(now, @authorization_code_ttl, :second)
  }
end
```

**State transition pattern** ([authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:438)):
```elixir
defp move_login_to_pending_consent(%Interaction{} = interaction, subject_id, opts) do
  interaction_store(opts).transition_interaction(
    interaction.interaction_id,
    [:pending_login],
    %{
      status: :pending_consent,
      account_id: subject_id,
      consent_requested_at: now(opts)
    }
  )
end
```

**Redirect/audit helper pattern** ([authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:328), [authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:355)):
```elixir
defp build_redirect(base_uri, params) when is_binary(base_uri) and is_map(params) do
  uri = URI.parse(base_uri)
  existing = URI.decode_query(uri.query || "")

  merged =
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> then(&Map.merge(existing, &1))

  %{uri | query: URI.encode_query(merged)}
  |> URI.to_string()
end

defp transact_with_audit(store, audit_events, fun)
     when is_atom(store) and is_list(audit_events) and is_function(fun, 0) do
  store.transact(fn ->
    fun.()
    |> maybe_append_audit_events(store, audit_events)
  end)
  |> normalize_transaction_result()
end
```

**What to copy for Phase 37**
- Keep protocol decisions in this module, with Phoenix remaining thin.
- Model silent-auth outcomes as explicit return tuples before any login redirect or consent UI.
- Persist new freshness truth through the same `Interaction` transition/store path.
- Reuse transaction-wrapped state transitions plus audit append helpers for any fresh-auth persistence.

---

### `lib/lockspire/web/controllers/authorize_controller.ex` (controller, request-response)

**Analog:** `lib/lockspire/web/controllers/authorize_controller.ex`

**Thin adapter pattern** ([authorize_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/authorize_controller.ex:17)):
```elixir
def show(conn, params) do
  case AuthorizationRequest.validate(params) do
    {:ok, %Validated{} = validated} ->
      with {:ok, subject_context} <- resolve_subject_context(conn, validated),
           outcome <- AuthorizationFlow.start_authorization(validated, subject_context, protocol_store_opts()) do
        handle_authorization_outcome(conn, outcome)
      else
        {:error, %Error{} = error} ->
          render_browser_error(conn, error, :internal_server_error)
      end

    {:browser_error, %Error{} = error} ->
      render_browser_error(conn, error, :bad_request)

    {:redirect_error, %Error{} = error} ->
      redirect(conn, external: redirect_location(error))
  end
end
```

**Login vs consent handoff pattern** ([authorize_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/authorize_controller.ex:41)):
```elixir
defp handle_authorization_outcome(conn, {:login_required, interaction}) do
  resolver = Lockspire.account_resolver!()

  %InteractionResult{} =
    base_result =
    resolver.redirect_for_login(conn, %{
      interaction_id: interaction.interaction_id,
      return_to: consent_path(interaction.interaction_id)
    })

  login_result = %InteractionResult{
    base_result
    | return_to: consent_path(interaction.interaction_id),
      params: base_result.params |> Map.put("interaction_id", interaction.interaction_id)
  }

  redirect_to_result(conn, login_result)
end

defp handle_authorization_outcome(conn, {:consent_required, interaction}) do
  redirect(conn, to: consent_path(interaction.interaction_id))
end

defp handle_authorization_outcome(conn, {:consent_reused, redirect_uri}) do
  redirect(conn, external: redirect_uri)
end
```

**Redirect-safe OAuth error merge pattern** ([authorize_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/authorize_controller.ex:120)):
```elixir
defp redirect_location(%Error{} = error) do
  uri = URI.parse(error.redirect_uri)
  existing_params = URI.decode_query(uri.query || "")

  oauth_params =
    %{
      "error" => error.error,
      "error_description" => error.error_description,
      "state" => error.state
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()

  uri
  |> Map.put(:query, URI.encode_query(Map.merge(existing_params, oauth_params)))
  |> URI.to_string()
end
```

**What to copy for Phase 37**
- Keep controller logic as tuple dispatch only.
- Any new silent-auth error coming from `AuthorizationFlow` should stay redirect-safe through this controller helper.
- Do not let controller code decide protocol taxonomy beyond mapping tuples to redirect/render behavior.

---

### `lib/lockspire/protocol/id_token.ex` and `lib/lockspire/host/claims.ex` (service + utility, transform)

**Analogs:** `lib/lockspire/protocol/id_token.ex`, `lib/lockspire/host/claims.ex`

**Protocol-claim assembly pattern** ([id_token.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/id_token.ex:16)):
```elixir
def sign(%{
      client_id: client_id,
      issuer: issuer,
      host_claims: %Claims{} = host_claims,
      interaction_nonce: nonce,
      access_token: access_token,
      issued_at: %DateTime{} = issued_at,
      signing_key: %{kid: kid, alg: "RS256", private_jwk_encrypted: private_jwk}
    })
    when is_binary(client_id) and is_binary(issuer) and is_binary(access_token) do
  with {:ok, jwk_map} <- decode_private_jwk(private_jwk),
       claims <- build_claims(host_claims, issuer, client_id, nonce, access_token, issued_at),
       {_, compact} <-
         JOSE.JWT.sign(
           JOSE.JWK.from_map(jwk_map),
           %{"alg" => "RS256", "kid" => kid, "typ" => "JWT"},
           claims
         )
         |> JOSE.JWS.compact() do
    {:ok, compact}
  else
    {:error, reason} -> {:error, reason}
  end
end
```

**Reserved-claim filtering pattern** ([claims.ex](/Users/jon/projects/lockspire/lib/lockspire/host/claims.ex:6)):
```elixir
@protocol_claims ~w(iss aud exp iat nonce at_hash sub)

def build_id_token_claims(%__MODULE__{} = claims, protocol_claims)
    when is_map(protocol_claims) do
  claims.id_token
  |> Map.drop(@protocol_claims)
  |> Map.put("sub", claims.subject)
  |> Map.merge(protocol_claims)
  |> drop_nil_claims()
end
```

**What to copy for Phase 37**
- Add `auth_time` as a protocol-owned claim in the same `protocol_claims` merge path.
- Keep claim emission conditional in `IdToken.build_claims/6`; do not move host-claim filtering elsewhere.
- Do not let host `id_token` claims override protocol-owned `auth_time`.

---

### `lib/lockspire/host/account_resolver.ex` and generated-host resolver (provider, request-response)

**Analogs:** `lib/lockspire/host/account_resolver.ex`, `test/support/generated_host_app/lockspire/test_account_resolver.ex`

**Behaviour contract pattern** ([account_resolver.ex](/Users/jon/projects/lockspire/lib/lockspire/host/account_resolver.ex:12)):
```elixir
@callback resolve_current_account(conn_or_socket :: term(), context()) ::
            {:ok, account()} | {:redirect, InteractionResult.t()}

@callback resolve_account(account_reference :: term(), context()) ::
            {:ok, account()} | {:error, :not_found | term()}

@callback build_claims(account(), context()) ::
            {:ok, Claims.t()} | {:error, term()}

@callback redirect_for_login(conn_or_socket :: term(), context()) ::
            InteractionResult.t()
```

**Generated host session-lookup pattern** ([test_account_resolver.ex](/Users/jon/projects/lockspire/test/support/generated_host_app/lockspire/test_account_resolver.ex:9)):
```elixir
def resolve_current_account(%Plug.Conn{} = conn, context) do
  case Plug.Conn.get_session(conn, "current_account_id") do
    account_id when is_binary(account_id) and account_id != "" ->
      {:ok, %{id: account_id}}

    _ ->
      {:redirect, redirect_for_login(conn, context)}
  end
end
```

**What to copy for Phase 37**
- Keep the seam singular and explicit.
- If Phase 37 adds fresh-auth metadata to the host seam, do it by extending the account/context contract here rather than introducing a second auth-specific adapter.
- Generated-host fixture code is the right place to demonstrate the new seam in integration/conformance runs.

---

### `lib/lockspire/domain/interaction.ex`, `lib/lockspire/storage/ecto/interaction_record.ex`, and migration file (model + migration, CRUD)

**Analogs:** `lib/lockspire/domain/interaction.ex`, `lib/lockspire/storage/ecto/interaction_record.ex`, `priv/repo/migrations/20260423020100_extend_authorization_core_state.exs`

**Domain struct pattern** ([interaction.ex](/Users/jon/projects/lockspire/lib/lockspire/domain/interaction.ex:10)):
```elixir
@type t :: %__MODULE__{
        id: integer() | nil,
        interaction_id: String.t(),
        client_id: String.t(),
        account_id: String.t() | nil,
        scopes_requested: [String.t()],
        prompt: prompt(),
        nonce: String.t() | nil,
        redirect_uri: String.t() | nil,
        return_to: String.t(),
        state: String.t() | nil,
        code_challenge: String.t() | nil,
        code_challenge_method: code_challenge_method(),
        status: status(),
        login_required_at: DateTime.t() | nil,
        consent_requested_at: DateTime.t() | nil,
        completed_at: DateTime.t() | nil,
        denied_at: DateTime.t() | nil,
        expired_at: DateTime.t() | nil,
        denial_reason: String.t() | nil,
        expires_at: DateTime.t()
      }
```

**Ecto schema/update pattern** ([interaction_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/interaction_record.ex:14)):
```elixir
schema "lockspire_interactions" do
  field(:interaction_id, :string)
  field(:client_id, :string)
  field(:account_id, :string)
  field(:scopes_requested, {:array, :string}, default: [])
  field(:prompt, {:array, :string}, default: [])
  field(:nonce, :string)
  field(:redirect_uri, :string)
  field(:return_to, :string)
  field(:state, :string)
  field(:code_challenge, :string)
  field(:code_challenge_method, Ecto.Enum, values: [:S256])
  field(:status, Ecto.Enum, values: @statuses)
  field(:login_required_at, :utc_datetime_usec)
  field(:consent_requested_at, :utc_datetime_usec)
  field(:completed_at, :utc_datetime_usec)
  field(:denied_at, :utc_datetime_usec)
  field(:expired_at, :utc_datetime_usec)
  field(:denial_reason, :string)
  field(:expires_at, :utc_datetime_usec)
  field(:tenant_id, :string)
  timestamps()
end
```

**Migration style pattern** ([20260423020100_extend_authorization_core_state.exs](/Users/jon/projects/lockspire/priv/repo/migrations/20260423020100_extend_authorization_core_state.exs:4)):
```elixir
def change do
  alter table(:lockspire_interactions) do
    add :status, :text, null: false, default: "pending_login"
    add :login_required_at, :utc_datetime_usec
    add :consent_requested_at, :utc_datetime_usec
    add :completed_at, :utc_datetime_usec
    add :denied_at, :utc_datetime_usec
    add :expired_at, :utc_datetime_usec
    add :denial_reason, :text
  end

  create index(:lockspire_interactions, [:status])
end
```

**What to copy for Phase 37**
- Put durable `auth_time` truth on `Interaction` and `InteractionRecord`, not in transient controller/session state.
- Follow the existing timestamp field naming and `:utc_datetime_usec` type.
- Add migration indexes only if query paths need them; current precedent adds indexes alongside state fields.

---

### `test/lockspire/protocol/authorization_request_test.exs` (test, request-response)

**Analog:** `test/lockspire/protocol/authorization_request_test.exs`

**Repo-backed setup pattern** ([authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:13)):
```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :known_scopes, ["profile", "email", "offline_access"])
  Application.put_env(:lockspire, :issuer, "https://server.example.com/lockspire")

  start_supervised!(Lockspire.TestRepo)
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
  :ok
end
```

**Typed validated-contract assertions** ([authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:64)):
```elixir
assert {:ok, %Validated{} = validated} =
         AuthorizationRequest.validate(valid_params(client.client_id))

assert validated.client_id == client.client_id
assert validated.redirect_uri == "https://client.example.com/callback"
assert validated.scopes == ["profile", "email"]
assert validated.prompt == ["login", "consent"]
```

**Reason-code assertion pattern** ([authorization_request_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_request_test.exs:149)):
```elixir
params =
  valid_params("client_123")
  |> Map.put("prompt", "login login")

assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
assert error.reason_code == :duplicate_prompt
```

**What to copy for Phase 37**
- Add prompt/max_age/auth_time cases as narrow reason-code assertions first.
- Keep repo-backed validation tests at the protocol module, not only web-controller coverage.
- Assert telemetry reason codes whenever new rejection paths are added.

---

### `test/lockspire/protocol/authorization_flow_test.exs` (test, event-driven)

**Analog:** `test/lockspire/protocol/authorization_flow_test.exs`

**Agent-backed fake-store pattern** ([authorization_flow_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_flow_test.exs:12)):
```elixir
{:ok, pid} =
  Agent.start_link(fn ->
    %{
      audits: [],
      interactions: %{},
      consents: %{},
      tokens: %{}
    }
  end)

Store.use_agent(pid)
```

**Deterministic event/state assertion pattern** ([authorization_flow_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_flow_test.exs:50)):
```elixir
assert {:login_required, %Interaction{} = login_interaction} =
         AuthorizationFlow.start_authorization(validated_request(), nil,
           interaction_store: Store,
           consent_store: Store,
           token_store: Store,
           now: &fixed_now/0,
           code_generator: fn -> "unused-code" end,
           interaction_id_generator: fn -> "interaction-login" end
         )

assert login_interaction.status == :pending_login
assert login_interaction.login_required_at == fixed_now()
```

**Consent reuse vs force-consent branching pattern** ([authorization_flow_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/authorization_flow_test.exs:86)):
```elixir
assert {:consent_reused, redirect_uri} = AuthorizationFlow.start_authorization(...)
assert {:consent_required, %Interaction{} = forced_interaction} =
         AuthorizationFlow.start_authorization(validated_request(prompt: ["consent"], state: "forced-state"), ...)
```

**What to copy for Phase 37**
- Use the fake store for silent-auth taxonomy and durable `auth_time` transitions before wiring full controller tests.
- Inject `now` for max-age freshness boundaries.
- Assert interaction timestamps directly on the domain struct and persisted fake store state.

---

### `test/lockspire/web/authorize_controller_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/authorize_controller_test.exs`

**Host-resolver fixture pattern** ([authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:1)):
```elixir
defmodule Lockspire.Web.AuthorizeControllerLoginResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  def resolve_current_account(_conn_or_socket, _context) do
    {:redirect, redirect_for_login(nil, %{})}
  end
end
```

**Redirect-safe error assertion pattern** ([authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:191)):
```elixir
conn =
  "client_123"
  |> valid_params()
  |> Map.put("prompt", "select_account")
  |> call_authorize()

assert conn.status in [302, 303]
assert location = redirect_location(conn)
assert location =~ "https://client.example.com/callback"
assert location =~ "error=invalid_request"
assert location =~ "state=state-123"
```

**Interactive login handoff assertion pattern** ([authorize_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/authorize_controller_test.exs:294)):
```elixir
conn =
  "client_123"
  |> valid_params()
  |> Map.delete("prompt")
  |> call_authorize()

assert conn.status in [302, 303]
assert location = redirect_location(conn)
assert location =~ "/sign-in?"
assert location =~ "source=authorize"
assert location =~ "interaction_id="
```

**What to copy for Phase 37**
- Add paired tests that prove `prompt=none` never follows the interactive login path.
- Keep controller tests focused on HTTP surface: browser error page vs external redirect.
- Use alternate resolver fixtures to model authenticated, unauthenticated, and freshness-stale host states.

---

### `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs` (test, request-response)

**Analog:** `test/integration/phase3_oidc_token_lifecycle_e2e_test.exs`

**Embedded-resolver integration fixture pattern** ([phase3_oidc_token_lifecycle_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase3_oidc_token_lifecycle_e2e_test.exs:19)):
```elixir
defmodule Resolver do
  @behaviour Lockspire.Host.AccountResolver

  def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-e2e"}}

  def build_claims(account, _context) do
    {:ok,
     %Claims{
       subject: account.id,
       id_token: %{"email" => "#{account.id}@example.test"},
       userinfo: %{"email" => "#{account.id}@example.test", "email_verified" => true}
     }}
  end
end
```

**OIDC token claim verification pattern** ([phase3_oidc_token_lifecycle_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase3_oidc_token_lifecycle_e2e_test.exs:157)):
```elixir
missing_nonce_params =
  authorization_params(public_client.client_id)
  |> Map.put("scope", "openid email profile")

assert {:redirect_error, error} = AuthorizationRequest.validate(missing_nonce_params)
assert error.reason_code == :missing_nonce

assert {true, %JOSE.JWT{fields: id_token_claims}, _jws} =
         JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

assert id_token_claims["iss"] == "https://example.test/lockspire"
assert id_token_claims["aud"] == public_client.client_id
assert id_token_claims["sub"] == "subject-e2e"
assert id_token_claims["nonce"] == "nonce-phase3"
```

**What to copy for Phase 37**
- Keep conformance-adjacent proof as repo-native integration tests with explicit JOSE verification.
- Add `auth_time` assertions at the signed token layer, not only by inspecting intermediate structs.
- If a new `phase37` integration test is created, mirror the setup style and narrow it to the new protocol surface.

---

### `mix.exs` and `.github/workflows/ci.yml` (config, batch)

**Analogs:** `mix.exs`, `.github/workflows/ci.yml`

**Mix alias pattern** ([mix.exs](/Users/jon/projects/lockspire/mix.exs:56)):
```elixir
"test.integration": ["test.setup", "test --only integration"],
"test.phase3.e2e": [
  "test.setup",
  "test --include integration test/integration/phase3_oidc_token_lifecycle_e2e_test.exs"
],
"test.phase3": [
  "test.setup",
  "test --include integration test/integration/phase3_oidc_token_lifecycle_e2e_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/userinfo_controller_test.exs"
],
ci: [
  "cmd sh -lc 'HEX_API_KEY= mix deps.get'",
  "cmd sh -lc 'mix qa'",
  "cmd sh -lc 'mix docs.verify'",
  "cmd sh -lc 'HEX_API_KEY= mix deps.audit'",
  "cmd sh -lc 'HEX_API_KEY= mix package.build'",
  "cmd sh -lc 'MIX_ENV=test mix test.fast'",
  "cmd sh -lc 'MIX_ENV=test mix test.integration'",
  "cmd sh -lc 'MIX_ENV=test mix test.phase3'"
]
```

**Split-job CI pattern** ([ci.yml](/Users/jon/projects/lockspire/.github/workflows/ci.yml:20)):
```yaml
jobs:
  fast:
    ...
    steps:
      - name: Run qa gate
        run: mix qa
      - name: Build docs
        run: mix docs.verify
      - name: Audit retired dependencies
        run: mix deps.audit
      - name: Verify Hex package
        run: mix package.build
      - name: Run fast tests
        run: mix test.fast

  integration:
    ...
    steps:
      - name: Run integration suite including onboarding and OIDC E2E proof
        run: mix test.integration
      - name: Run Phase 3 protocol gate
        run: mix test.phase3
```

**What to copy for Phase 37**
- Add a dedicated `mix test.phase37` or similarly narrow alias instead of bloating `test.integration`.
- Keep CI mechanically equivalent to the maintained alias contract.
- Put conformance automation behind a distinct script or alias, not inline bash in the workflow.

---

### `docs/supported-surface.md` and `test/lockspire/release_readiness_contract_test.exs` (docs + test)

**Analogs:** `docs/supported-surface.md`, `test/lockspire/release_readiness_contract_test.exs`

**Public-support posture pattern** ([supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md:45)):
```markdown
## Trust posture

Lockspire stays at `v0.2.0` preview because public claims are limited to what this repo can prove today.
Repo-owned proof for this preview posture lives in:

- `docs/install-and-onboard.md`
- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`
- `test/lockspire/release_readiness_contract_test.exs`
- `.github/workflows/ci.yml`
- `docs/maintainer-release.md`
```

**Docs contract-test pattern** ([release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:160)):
```elixir
test "workflow files keep contributor proof separate from the protected publish lane" do
  ci_workflow = File.read!(@ci_workflow_path)
  release_workflow = File.read!(@release_workflow_path)
  mixfile = File.read!("mix.exs")

  assert mixfile =~ "ci: ["
  assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.integration'\""
  assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.phase3'\""

  for command <- [
        "run: mix qa",
        "run: mix docs.verify",
        "run: mix deps.audit",
        "run: mix package.build",
        "run: mix test.fast",
        "run: mix test.integration",
        "run: mix test.phase3"
      ] do
    assert ci_workflow =~ command
  end
end
```

**What to copy for Phase 37**
- Keep any broadened public claim tied to checked-in proof.
- If Phase 37 adds conformance language to docs, add corresponding contract assertions in `release_readiness_contract_test.exs`.
- Maintain the repo-owned evidence list explicitly; do not imply broader certification than the repo can rerun.

## Shared Patterns

### Redirect-safe vs browser-safe authorization errors
**Sources:** [lib/lockspire/protocol/authorization_request.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_request.ex:524), [lib/lockspire/web/controllers/authorize_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/authorize_controller.ex:120)
**Apply to:** `authorization_request`, `authorization_flow`, `authorize_controller`, controller tests
```elixir
defp browser_error(error, description, reason_code) do
  %Error{
    error: to_string(error),
    error_description: description,
    reason_code: reason_code,
    redirect_uri: nil,
    state: nil
  }
end

defp redirect_error(params, error, description, reason_code) do
  %Error{
    error: to_string(error),
    error_description: description,
    reason_code: reason_code,
    redirect_uri: params["redirect_uri"],
    state: normalize_optional_string(params["state"])
  }
end
```

### Strict numeric/time validation
**Sources:** [lib/lockspire/protocol/jar.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/jar.ex:217), [lib/lockspire/protocol/request_object.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/request_object.ex:166)
**Apply to:** `max_age`, `auth_time`, request object parsing, any timestamp coercion
```elixir
with {:ok, expected_client_id, expected_audience, now, leeway, max_age} <- parse_opts(opts),
     :ok <- check_issuer(claims, expected_client_id),
     :ok <- check_audience(claims, expected_audience),
     :ok <- check_expiration(claims, now, leeway, max_age),
     :ok <- check_not_before(claims, now, leeway),
     :ok <- check_issued_at(claims, now, leeway) do
  :ok
end
```

### Durable interaction truth over session inference
**Sources:** [lib/lockspire/protocol/authorization_flow.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/authorization_flow.ex:187), [lib/lockspire/storage/ecto/interaction_record.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/interaction_record.ex:39)
**Apply to:** `auth_time` persistence, silent auth, freshness checks
```elixir
attrs =
  interaction
  |> Map.from_struct()
  |> Map.put(:prompt, prompt)

record
|> cast(attrs, [...])
|> validate_required([:interaction_id, :client_id, :return_to, :expires_at, :status])
|> unique_constraint(:interaction_id)
```

### Thin Phoenix adapter over protocol core
**Sources:** [lib/lockspire/web/controllers/authorize_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/authorize_controller.ex:17), [lib/lockspire/web/controllers/interaction_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/interaction_controller.ex:14)
**Apply to:** controller changes, generated host fixtures
```elixir
with {:ok, subject_context} <- resolve_subject_context(conn, validated),
     outcome <- AuthorizationFlow.start_authorization(validated, subject_context, protocol_store_opts()) do
  handle_authorization_outcome(conn, outcome)
end
```

### Repo-native proof and alias-backed CI
**Sources:** [mix.exs](/Users/jon/projects/lockspire/mix.exs:56), [.github/workflows/ci.yml](/Users/jon/projects/lockspire/.github/workflows/ci.yml:81), [test/lockspire/release_readiness_contract_test.exs](/Users/jon/projects/lockspire/test/lockspire/release_readiness_contract_test.exs:160)
**Apply to:** `mix` alias additions, CI updates, docs proof claims
```elixir
ci: [
  "cmd sh -lc 'HEX_API_KEY= mix deps.get'",
  "cmd sh -lc 'mix qa'",
  "cmd sh -lc 'mix docs.verify'",
  "cmd sh -lc 'HEX_API_KEY= mix deps.audit'",
  "cmd sh -lc 'HEX_API_KEY= mix package.build'",
  "cmd sh -lc 'MIX_ENV=test mix test.fast'",
  "cmd sh -lc 'MIX_ENV=test mix test.integration'",
  "cmd sh -lc 'MIX_ENV=test mix test.phase3'"
]
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `scripts/conformance/run_lockspire_plan.py` and sibling `scripts/conformance/*` files | utility | batch | No existing repo script directory or runner wrapper; planner should borrow naming/entrypoint discipline from `mix.exs` aliases and CI, but the concrete script structure is new. |
| `docs/conformance.md` if introduced as a dedicated runbook | docs | batch | No dedicated conformance runbook exists yet; closest documentation patterns are `docs/maintainer-release.md` for operator runbooks and `docs/supported-surface.md` for public-proof posture. |

## Metadata

**Analog search scope:** `lib/lockspire`, `test/lockspire`, `test/integration`, `test/support/generated_host_app`, `priv/repo/migrations`, `docs`, `.github/workflows`, `mix.exs`

**Files scanned:** 18

**Pattern extraction date:** 2026-04-28
