# Phase 31: Host-Owned Verification UI Seam - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 19
**Analogs found:** 19 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/lockspire/protocol/device_verification.ex` | protocol/service | request-response | `lib/lockspire/protocol/authorization_flow.ex` | role-match |
| `lib/lockspire/protocol/device_authorization.ex` | protocol/service | request-response | `lib/lockspire/protocol/device_authorization.ex` | exact |
| `lib/lockspire/domain/device_authorization.ex` | model | transform | `lib/lockspire/domain/device_authorization.ex` | exact |
| `lib/lockspire/storage/device_authorization_store.ex` | service/behavior | CRUD | `lib/lockspire/storage/device_authorization_store.ex` | exact |
| `lib/lockspire/storage/ecto/device_authorization_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/device_authorization_record.ex` | exact |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `priv/repo/migrations/*_extend_lockspire_device_authorizations_verification_state.exs` | migration | transform | `priv/repo/migrations/20260423020100_extend_authorization_core_state.exs` | role-match |
| `lib/lockspire/generators/install.ex` | config/generator | file-I/O | `lib/lockspire/generators/install.ex` | exact |
| `lib/lockspire/generators/templates.ex` | config/generator | file-I/O | `lib/lockspire/generators/templates.ex` | exact |
| `priv/templates/lockspire.install/router.ex` | route/template | request-response | `priv/templates/lockspire.install/router.ex` | exact |
| `priv/templates/lockspire.install/verification_controller.ex` | controller/template | request-response | `priv/templates/lockspire.install/authorized_apps_controller.ex` | role-match |
| `priv/templates/lockspire.install/verification_html.ex` | html module/template | request-response | `priv/templates/lockspire.install/authorized_apps_html.ex` | role-match |
| `priv/templates/lockspire.install/verification_html/index.html.heex` | template | request-response | `priv/templates/lockspire.install/authorized_apps/index.html.heex` | role-match |
| `docs/device-flow-host-guide.md` | docs | request-response | `docs/dynamic-registration.md` | role-match |
| `docs/install-and-onboard.md` | docs | request-response | `docs/install-and-onboard.md` | exact |
| `docs/supported-surface.md` | docs | request-response | `docs/supported-surface.md` | exact |
| `test/integration/install_generator_test.exs` | test | file-I/O | `test/integration/install_generator_test.exs` | exact |
| `test/lockspire/protocol/device_authorization_test.exs` | test | request-response | `test/lockspire/protocol/device_authorization_test.exs` | exact |
| `test/lockspire/web/controllers/device_authorization_controller_test.exs` | test | request-response | `test/lockspire/web/controllers/device_authorization_controller_test.exs` | exact |
| `test/lockspire/storage/ecto/repository_device_authorization_test.exs` | test | CRUD | `test/lockspire/storage/ecto/repository_device_authorization_test.exs` | exact |
| `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` | test | request-response | `test/lockspire/web/interaction_controller_test.exs` | role-match |

## Pattern Assignments

### `lib/lockspire/protocol/device_verification.ex` (protocol/service, request-response)

**Analog:** `lib/lockspire/protocol/authorization_flow.ex`

**Public API shape** ([authorization_flow.ex](../../../lib/lockspire/protocol/authorization_flow.ex#L35), lines 35-60):
```elixir
@spec resume_interaction(String.t(), map(), keyword()) ::
        {:consent_required, Interaction.t()}
        | {:consent_reused, String.t()}
        | {:error, term()}

@spec approve_interaction(String.t(), map(), keyword()) ::
        {:approved, String.t()} | {:error, term()}
```

**Expected-state mutation pattern** ([authorization_flow.ex](../../../lib/lockspire/protocol/authorization_flow.ex#L401), lines 401-423):
```elixir
with {:ok, completed} <-
       interaction_store(opts).transition_interaction(
         interaction_id,
         [:pending_consent],
         %{status: :completed, completed_at: now(opts)}
       ) do
  ...
end
```

**Use for Phase 31:** expose separate lookup and approve/deny functions, with typed outcomes, and delegate final race-safe transitions to the store instead of letting the host mutate raw `user_code`.

---

### `lib/lockspire/protocol/device_authorization.ex` (protocol/service, request-response)

**Analog:** `lib/lockspire/protocol/device_authorization.ex`

**Success struct + response assembly** ([device_authorization.ex](../../../lib/lockspire/protocol/device_authorization.ex#L12), lines 12-22, 47-53):
```elixir
defmodule Success do
  @type t :: %__MODULE__{
          device_code: String.t(),
          user_code: String.t(),
          verification_uri: String.t(),
          verification_uri_complete: String.t() | nil,
          expires_in: pos_integer(),
          interval: pos_integer() | nil
        }
  defstruct [:device_code, :user_code, :verification_uri, :verification_uri_complete, :expires_in, :interval]
end

%Success{
  device_code: device_auth.device_code,
  user_code: device_auth.user_code,
  verification_uri: verification_uri(request),
  expires_in: DateTime.diff(device_auth.expires_at, now, :second)
}
```

**Store injection pattern** ([device_authorization.ex](../../../lib/lockspire/protocol/device_authorization.ex#L108), lines 108-125):
```elixir
defp device_authorization_store(request) do
  request
  |> request_opts()
  |> Keyword.get(:device_authorization_store, Repository)
end
```

**Use for Phase 31:** keep `authorize/1` as the source of `verification_uri_complete`; add the field there rather than teaching controllers or JSON serializers to invent it.

---

### `lib/lockspire/domain/device_authorization.ex` (model, transform)

**Analog:** `lib/lockspire/domain/device_authorization.ex`

**Struct + enforce_keys pattern** ([device_authorization.ex](../../../lib/lockspire/domain/device_authorization.ex#L8), lines 8-22):
```elixir
@enforce_keys [
  :device_code_hash,
  :user_code_hash,
  :client_id,
  :expires_at
]
defstruct [
  :device_code,
  :user_code,
  :device_code_hash,
  :user_code_hash,
  :client_id,
  :scopes,
  :expires_at
]
```

**Issuance pattern** ([device_authorization.ex](../../../lib/lockspire/domain/device_authorization.ex#L39), lines 39-54):
```elixir
%__MODULE__{
  device_code: device_code,
  device_code_hash: Policy.hash_token(device_code),
  user_code: user_code,
  user_code_hash: Policy.hash_token(user_code),
  client_id: Map.fetch!(attrs, :client_id),
  scopes: List.wrap(Map.get(attrs, :scopes, [])),
  expires_at: DateTime.add(now, ttl, :second)
}
```

**Use for Phase 31:** extend the domain struct with lifecycle and actor-binding fields in this same explicit style; keep hashes authoritative and raw codes optional.

---

### `lib/lockspire/storage/device_authorization_store.ex` (service/behavior, CRUD)

**Analog:** `lib/lockspire/storage/device_authorization_store.ex`

**Behavior pattern** ([device_authorization_store.ex](../../../lib/lockspire/storage/device_authorization_store.ex#L1), lines 1-9):
```elixir
defmodule Lockspire.Storage.DeviceAuthorizationStore do
  @moduledoc """
  Behaviour for storing and managing OAuth 2.0 Device Authorizations.
  """

  alias Lockspire.Domain.DeviceAuthorization

  @callback put_device_authorization(DeviceAuthorization.t()) ::
              {:ok, DeviceAuthorization.t()} | {:error, term()}
end
```

**Use for Phase 31:** add lookup and transition callbacks here first; protocol modules should target the behavior, not `Repository` directly.

---

### `lib/lockspire/storage/ecto/device_authorization_record.ex` (model, CRUD)

**Analog:** `lib/lockspire/storage/ecto/device_authorization_record.ex`

**Schema + changeset pattern** ([device_authorization_record.ex](../../../lib/lockspire/storage/ecto/device_authorization_record.ex#L9), lines 9-38):
```elixir
schema "lockspire_device_authorizations" do
  field(:device_code_hash, :string)
  field(:user_code_hash, :string)
  field(:client_id, :string)
  field(:scopes, {:array, :string}, default: [])
  field(:expires_at, :utc_datetime_usec)

  timestamps()
end

record
|> cast(attrs, [:device_code_hash, :user_code_hash, :client_id, :scopes, :expires_at])
|> validate_required([:device_code_hash, :user_code_hash, :client_id, :expires_at])
|> unique_constraint(:device_code_hash)
|> unique_constraint(:user_code_hash)
```

**Domain mapping pattern** ([device_authorization_record.ex](../../../lib/lockspire/storage/ecto/device_authorization_record.ex#L47), lines 47-56):
```elixir
%DeviceAuthorization{
  device_code_hash: record.device_code_hash,
  user_code_hash: record.user_code_hash,
  client_id: record.client_id,
  scopes: record.scopes,
  expires_at: record.expires_at
}
|> Map.merge(Enum.into(extra, %{}))
```

**Use for Phase 31:** add lifecycle and actor fields in both the schema and `to_domain/2`, then keep updates funneled through `update_changeset/2`.

---

### `lib/lockspire/storage/ecto/repository.ex` (service, CRUD)

**Analog:** `lib/lockspire/storage/ecto/repository.ex`

**Transaction wrapper** ([repository.ex](../../../lib/lockspire/storage/ecto/repository.ex#L229), lines 229-247):
```elixir
def transition_interaction(interaction_id, expected_statuses, attrs)
    when is_binary(interaction_id) and is_list(expected_statuses) and is_map(attrs) do
  transact(fn ->
    interaction_id
    |> locked_interaction_query()
    |> repo().one()
    |> transition_interaction_record(expected_statuses, attrs)
  end)
end
```

**Record transition guard** ([repository.ex](../../../lib/lockspire/storage/ecto/repository.ex#L1020), lines 1020-1032):
```elixir
defp transition_interaction_record(%InteractionRecord{} = record, expected_statuses, attrs) do
  if record.status in expected_statuses do
    record
    |> InteractionRecord.update_changeset(Map.put(attrs, :updated_at, DateTime.utc_now()))
    |> repo().update()
    |> map_one(&InteractionRecord.to_domain/1)
    |> unwrap_or_rollback()
  else
    repo().rollback(:invalid_state)
  end
end
```

**Simple insert mapping** ([repository.ex](../../../lib/lockspire/storage/ecto/repository.ex#L297), lines 297-303):
```elixir
def put_device_authorization(%DeviceAuthorization{} = auth) do
  %DeviceAuthorizationRecord{}
  |> DeviceAuthorizationRecord.changeset(auth)
  |> repo_insert()
  |> map_one(&DeviceAuthorizationRecord.to_domain/1)
end
```

**Use for Phase 31:** copy this exact `transact` + `lock("FOR UPDATE")` + `rollback(:invalid_state)` discipline for approve/deny/consume transitions on device authorizations.

---

### `priv/repo/migrations/*_extend_lockspire_device_authorizations_verification_state.exs` (migration, transform)

**Analog:** `priv/repo/migrations/20260423020100_extend_authorization_core_state.exs`

**Alter-table pattern** ([extend_authorization_core_state.exs](../../../priv/repo/migrations/20260423020100_extend_authorization_core_state.exs#L4), lines 4-16):
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

**Use for Phase 31:** follow this exact additive migration style for `status`, approval/denial timestamps, actor binding, and supporting indexes on device authorizations.

---

### `lib/lockspire/generators/install.ex` (generator, file-I/O)

**Analog:** `lib/lockspire/generators/install.ex`

**Template loop + EEx render** ([install.ex](../../../lib/lockspire/generators/install.ex#L11), lines 11-35):
```elixir
assigns = build_assigns(opts)

Enum.each(Templates.all(), fn template ->
  render_template(template, assigns)
end)
```

**Refuse-to-overwrite pattern** ([install.ex](../../../lib/lockspire/generators/install.ex#L37), lines 37-58):
```elixir
case File.read(destination) do
  {:ok, ^rendered} ->
    Mix.shell().info("* unchanged #{Path.relative_to_cwd(destination)}")

  {:ok, _existing} ->
    Mix.raise("""
    Refusing to overwrite modified file: #{Path.relative_to_cwd(destination)}
    ...
    """)
```

**Assigns pattern** ([install.ex](../../../lib/lockspire/generators/install.ex#L61), lines 61-88):
```elixir
%{
  project_root: Keyword.get(opts, :path, File.cwd!()),
  app_module: root_module,
  web_module: web_module,
  scope_module: scope_module,
  ...
  consent_live_module: "#{web_module}.LockspireConsentLive"
}
```

**Use for Phase 31:** add verification-specific assigns and next-step guidance here, preserving the current unchanged/raise semantics.

---

### `lib/lockspire/generators/templates.ex` (generator, file-I/O)

**Analog:** `lib/lockspire/generators/templates.ex`

**Template inventory pattern** ([templates.ex](../../../lib/lockspire/generators/templates.ex#L6), lines 6-40):
```elixir
%{
  template: "consent_live.ex",
  output: &"lib/#{&1.web_path}/live/lockspire_consent_live.ex"
},
%{
  template: "authorized_apps_controller.ex",
  output: &"lib/#{&1.web_path}/controllers/authorized_apps_controller.ex"
}
```

**Use for Phase 31:** register the new verification template here with a host-app output path beside the other generated seams.

---

### `priv/templates/lockspire.install/router.ex` (route/template, request-response)

**Analog:** `priv/templates/lockspire.install/router.ex`

**Host-owned route block pattern** ([router.ex](../../../priv/templates/lockspire.install/router.ex#L9), lines 9-23):
```elixir
def lockspire_routes do
  """
  scope "/", <%= @web_module %> do
    pipe_through [:browser]

    # Keep this route host-owned.
    get "/authorized-apps", AuthorizedAppsController, :index
    delete "/authorized-apps/:id", AuthorizedAppsController, :delete
  end

  scope "/" do
    forward "<%= @mount_path %>", Lockspire.Web.Router
  end
  """
end
```

**Use for Phase 31:** add `/verify` here as host-owned, with comments that the host must add auth/rate-limiting and that `verification_uri_complete` is prefill-only.

---

### `priv/templates/lockspire.install/verification_controller.ex` (controller/template, request-response)

**Analog:** `lib/lockspire/web/controllers/interaction_controller.ex`

**Controller action pattern** ([interaction_controller.ex](../../../lib/lockspire/web/controllers/interaction_controller.ex#L12), lines 12-40):
```elixir
def show(conn, %{"interaction_id" => interaction_id} = params) do
  case AuthorizationFlow.resume_interaction(interaction_id, params, protocol_opts()) do
    {:consent_required, interaction} ->
      render(conn, :show, interaction: interaction)

    {:error, :not_found} ->
      conn
      |> put_status(:not_found)
      |> render(:not_found)
  end
end
```

**Use for Phase 31:** keep the generated controller host-editable, use `show/2` only for prefill rendering, perform lookup on an explicit POST, and submit approve/deny as separate opaque-handle mutations.

---

### `priv/templates/lockspire.install/verification_html.ex` and `verification_html/index.html.heex` (template, request-response)

**Analog:** `priv/templates/lockspire.install/consent_live.ex`

**Review-surface content pattern** ([consent_live.ex](../../../priv/templates/lockspire.install/consent_live.ex#L20), lines 20-47):
```elixir
<h1>Authorize Access</h1>
<p><%= @client_name %> is requesting access.</p>
...
<button type="submit">Approve access</button>
<button type="submit">Deny access</button>
```

**Use for Phase 31:** render the visible code confirmation, client/scopes summary, and separate approve/deny actions in host-owned HEEx files without introducing auto-submit or GET side effects.

---

### `docs/device-flow-host-guide.md` (docs, request-response)

**Analog:** `docs/dynamic-registration.md`

**Host-owned responsibility framing** ([dynamic-registration.md](../../../docs/dynamic-registration.md#L5), lines 5-12):
```markdown
## Operator Setup

...
3. Configure your host application router to rate-limit the Lockspire Registration endpoints.
   **Lockspire does not provide built-in rate limiting.**
```

**Use for Phase 31:** follow this concrete host-responsibility style, but make the `/verify` contract more specific: IP trust, normalized `user_code` keys, neutral 429 behavior, and redacted logging guidance.

---

### `docs/install-and-onboard.md` (docs, request-response)

**Analog:** `docs/install-and-onboard.md`

**Generated-surface list pattern** ([install-and-onboard.md](../../../docs/install-and-onboard.md#L17), lines 17-25):
```markdown
This creates host-owned files for:

- Lockspire config
- Router mount helpers
- Account resolution
- Interaction handoff
- Consent UI shell
- Authorized apps account surface
```

**Next-step guidance pattern** ([install-and-onboard.md](../../../docs/install-and-onboard.md#L26), lines 26-40):
```markdown
Import `YourAppWeb.Router.Lockspire` ...
Implement the generated `AccountResolver` ...
Implement the generated interaction and consent modules in the host app ...
```

**Use for Phase 31:** add the verification seam and link to the new device-flow host guide from this onboarding page.

---

### `docs/supported-surface.md` (docs, request-response)

**Analog:** `docs/supported-surface.md`

**Capability list pattern** ([supported-surface.md](../../../docs/supported-surface.md#L7), lines 7-23):
```markdown
## Supported in scope

- Embedded Phoenix install flow through `mix lockspire.install`
- Authorization code flow with PKCE S256
...
- Host-owned login redirects and consent handoff seams
```

**Explicitly-out-of-scope list pattern** ([supported-surface.md](../../../docs/supported-surface.md#L24), lines 24-38):
```markdown
## Explicitly out of scope

...
- Device flow
- Dynamic client registration
```

**Use for Phase 31:** adjust the supported surface precisely, likely from “no device flow” to a narrower claim about host-owned verification seam support without over-claiming polling/token issuance until Phase 32.

---

### `test/integration/install_generator_test.exs` (test, file-I/O)

**Analog:** `test/integration/install_generator_test.exs`

**Generated-file assertions** ([install_generator_test.exs](../../../test/integration/install_generator_test.exs#L14), lines 14-83):
```elixir
assert File.read!(Path.join(@fixture_root, "lib/generated_host_app_web/router/lockspire.ex")) =~
         ~s(get "/authorized-apps", AuthorizedAppsController, :index)

assert File.read!(
         Path.join(@fixture_root, "lib/generated_host_app_web/live/lockspire_consent_live.ex")
       ) =~ "Approve access"
```

**Non-overwrite proof** ([install_generator_test.exs](../../../test/integration/install_generator_test.exs#L112), lines 112-125):
```elixir
File.write!(router_path, File.read!(router_path) <> "\n# host customization\n")

assert_raise Mix.Error, ~r/Refusing to overwrite modified file/, fn ->
  ...
end
```

**Use for Phase 31:** add verification file content assertions and keep the rerun safety proof on generated host files.

---

### `test/lockspire/protocol/device_authorization_test.exs` (test, request-response)

**Analog:** `test/lockspire/protocol/device_authorization_test.exs`

**Fake-store injection pattern** ([device_authorization_test.exs](../../../test/lockspire/protocol/device_authorization_test.exs#L8), lines 8-17):
```elixir
defmodule FakeClientStore do
  def fetch_client_by_id("valid_client"), do: {:ok, %Client{...}}
end

defmodule FakeDeviceStore do
  def put_device_authorization(%DeviceAuthorizationState{} = device_auth) do
    {:ok, device_auth}
  end
end
```

**Success assertion pattern** ([device_authorization_test.exs](../../../test/lockspire/protocol/device_authorization_test.exs#L19), lines 19-38):
```elixir
assert {:ok, %DeviceAuthorization.Success{} = success} = DeviceAuthorization.authorize(request)
assert success.verification_uri == "https://example.com/device"
assert success.expires_in == 300
```

**Use for Phase 31:** extend this file to assert `verification_uri_complete` population and keep protocol tests dependency-injected rather than DB-backed.

---

### `test/lockspire/web/controllers/device_authorization_controller_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/controllers/device_authorization_controller_test.exs`

**Direct-controller dispatch pattern** ([device_authorization_controller_test.exs](../../../test/lockspire/web/controllers/device_authorization_controller_test.exs#L38), lines 38-46):
```elixir
defp dispatch(conn) do
  conn
  |> put_req_header("accept", "application/json")
  |> Map.put(:private, %{phoenix_format: "json"})
  |> Lockspire.Web.DeviceAuthorizationController.call(:create)
end
```

**JSON field assertions** ([device_authorization_controller_test.exs](../../../test/lockspire/web/controllers/device_authorization_controller_test.exs#L48), lines 48-65):
```elixir
body = Jason.decode!(conn.resp_body)
assert Map.has_key?(body, "device_code")
assert Map.has_key?(body, "user_code")
assert Map.has_key?(body, "verification_uri")
assert Map.has_key?(body, "expires_in")
```

**Use for Phase 31:** add the HTTP-level `verification_uri_complete` assertion here once the protocol starts returning it.

---

### `test/lockspire/storage/ecto/repository_device_authorization_test.exs` (test, CRUD)

**Analog:** `test/lockspire/storage/ecto/repository_device_authorization_test.exs`

**Integration setup pattern** ([repository_device_authorization_test.exs](../../../test/lockspire/storage/ecto/repository_device_authorization_test.exs#L1), lines 1-20):
```elixir
use ExUnit.Case, async: false
@moduletag :integration

setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  ...
end
```

**Persistence assertions** ([repository_device_authorization_test.exs](../../../test/lockspire/storage/ecto/repository_device_authorization_test.exs#L22), lines 22-52):
```elixir
assert {:ok, result} = Repository.put_device_authorization(auth)
assert result.device_code_hash == auth.device_code_hash
...
assert {:error, %Ecto.Changeset{} = changeset} = Repository.put_device_authorization(auth)
```

**Use for Phase 31:** expand this file to cover lookup by normalized user-code hash and transition races/invalid-state outcomes inside the repository.

---

### `test/lockspire/web/controllers/lockspire_verification_controller_test.exs` (test, request-response)

**Analog:** `test/lockspire/web/controllers/device_authorization_controller_test.exs`

**Controller request/response assertion pattern** ([device_authorization_controller_test.exs](../../../test/lockspire/web/controllers/device_authorization_controller_test.exs#L40), lines 40-88):
```elixir
conn = post(conn, ~p"/device/code", %{"client_id" => client.client_id})

assert %{
         "device_code" => _,
         "user_code" => _,
         "verification_uri" => _
       } = json_response(conn, 200)
```

**Use for Phase 31:** add controller-surface tests that prove GET only pre-fills, lookup returns neutral invalid-or-expired copy, and approve/deny require explicit POST actions and signed-in actor binding.

## Shared Patterns

### Host Actor Resolution
**Source:** [lib/lockspire/web/controllers/interaction_controller.ex](../../../lib/lockspire/web/controllers/interaction_controller.ex#L101), lines 101-138 and [lib/lockspire/host/account_resolver.ex](../../../lib/lockspire/host/account_resolver.ex#L12), lines 12-24  
**Apply to:** `device_verification.ex`, generated verification controller, verification controller tests

```elixir
resolver = Lockspire.account_resolver!()

case resolver.resolve_current_account(conn_or_socket, context) do
  {:ok, account} ->
    case resolver.build_claims(account, context) do
      {:ok, %Claims{} = claims} -> {:ok, %{subject_id: claims.subject}}
      {:error, _reason} -> {:error, ...}
    end

  {:redirect, _result} -> {:error, ...}
  {:error, _reason} -> {:error, ...}
end
```

### Race-Safe State Transitions
**Source:** [lib/lockspire/storage/ecto/repository.ex](../../../lib/lockspire/storage/ecto/repository.ex#L229), lines 229-236 and [lib/lockspire/storage/ecto/repository.ex](../../../lib/lockspire/storage/ecto/repository.ex#L1020), lines 1020-1032  
**Apply to:** repository device-authorization transitions, protocol approve/deny flows

```elixir
transact(fn ->
  key
  |> locked_query()
  |> repo().one()
  |> transition_record(expected_statuses, attrs)
end)
```

### Generated Host-Seam Safety
**Source:** [lib/lockspire/generators/install.ex](../../../lib/lockspire/generators/install.ex#L37), lines 37-58 and [test/integration/install_generator_test.exs](../../../test/integration/install_generator_test.exs#L112), lines 112-125  
**Apply to:** install generator changes and verification template additions

```elixir
{:ok, ^rendered} -> Mix.shell().info("* unchanged ...")
{:ok, _existing} -> Mix.raise("Refusing to overwrite modified file: ...")
```

### Host-Owned Rate-Limit Contract
**Source:** [docs/dynamic-registration.md](../../../docs/dynamic-registration.md#L5), lines 5-12 and [docs/install-and-onboard.md](../../../docs/install-and-onboard.md#L26), lines 26-40  
**Apply to:** `docs/device-flow-host-guide.md`, onboarding docs, generated verification comments

```markdown
Configure your host application router to rate-limit the ... endpoints.
**Lockspire does not provide built-in rate limiting.**
```

## No Analog Found

None. Every planned file has at least a strong role-match analog in the current codebase.

## Metadata

**Analog search scope:** `lib/lockspire`, `priv/templates/lockspire.install`, `priv/repo/migrations`, `docs`, `test/lockspire`, `test/integration`  
**Files scanned:** 25  
**Pattern extraction date:** 2026-04-28
