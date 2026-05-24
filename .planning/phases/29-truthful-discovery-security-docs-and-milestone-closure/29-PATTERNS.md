# Phase 29: Truthful Discovery, SECURITY/Docs, and Milestone Closure - Pattern Map

**Mapped:** 2024-05-20
**Files analyzed:** 8
**Analogs found:** 7 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/discovery.ex` | component/protocol | request-response | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/web/router.ex` / controllers | route/controller | request-response | `lib/lockspire/web/router.ex` | exact |
| `test/lockspire/protocol/discovery_test.exs` | test | request-response | `test/lockspire/protocol/discovery_test.exs` | exact |
| `SECURITY.md` | docs | N/A | `SECURITY.md` | exact |
| `docs/dynamic-registration.md` | docs | N/A | `docs/getting-started.md` | role-match |
| `mix.exs` | config | N/A | `mix.exs` | exact |
| `test/integration/phase29_dcr_e2e_test.exs` | test | event-driven / CRUD | `test/integration/phase28_e2e_test.exs` | exact |
| `REQUIREMENTS.md` | docs | N/A | N/A | N/A |

## Pattern Assignments

### `lib/lockspire/protocol/discovery.ex` (component/protocol, request-response)

**Analog:** `lib/lockspire/protocol/discovery.ex`

**Pattern** (lines 75-80):
```elixir
  defp endpoint_metadata_entry(issuer, path) do
    Enum.find_value(@endpoint_paths, fn {key, route_path} ->
      if route_path == path do
        {key, issuer_url(issuer, route_path)}
      end
    end)
  end
```
*Note: Needs to adapt pattern to query `Lockspire.Config.server_policy/0` or similar mechanism to check `registration_policy != :disabled` before advertising `registration_endpoint`.*

---

### `lib/lockspire/web/router.ex` / `lib/lockspire/web/controllers/registration_controller.ex` (route/controller, request-response)

**Analog:** `lib/lockspire/web/router.ex`

**Pattern** (lines 10-23):
```elixir
  scope "/" do
    # ...
    post("/register", Lockspire.Web.RegistrationController, :create)
    # ...
  end
```
*Note: The `RegistrationController` functions need to check if the policy is `:disabled` and if so, return a 404 (not 403) to comply with the success criteria.*

---

### `test/lockspire/protocol/discovery_test.exs` (test, request-response)

**Analog:** `test/lockspire/protocol/discovery_test.exs`

**Pattern** (lines 20-25):
```elixir
  test "published_token_endpoint_auth_methods_supported/0 reflects the static list when /token is mounted" do
    assert Discovery.published_token_endpoint_auth_methods_supported() == @static_methods
  end
```
*Note: Write a contract test asserting discovery and runtime stay aligned for `registration_endpoint` across all three modes (`:disabled`, `:initial_access_token`, `:open`).*

---

### `SECURITY.md` (docs, N/A)

**Analog:** `SECURITY.md`

**Pattern** (lines 35-42):
```markdown
Unsupported or out-of-scope surfaces include:

- host-owned account databases
- host login/session implementations
- third-party IdP integrations not shipped in this repo
- hosted auth as a separate service
- request-object-by-value support, generic external `request_uri` handling, device flow, and dynamic client registration
- SAML, LDAP, or generic federation features
```
*Note: Explicitly list software statements, external-IdP federation, FAPI bundles, JAR-04, `jwks_uri` outbound fetch, and built-in rate limiting as out of scope.*

---

### `docs/dynamic-registration.md` (docs, N/A)

**Analog:** `docs/getting-started.md`

**Pattern** (lines 1-10):
```markdown
# Getting Started

Lockspire is for Phoenix teams that need to become an OAuth/OIDC provider inside an existing product.
```

---

### `test/integration/phase29_dcr_e2e_test.exs` (test, event-driven / CRUD)

**Analog:** `test/integration/phase28_e2e_test.exs`

**Imports and Setup Pattern** (lines 1-22):
```elixir
defmodule Lockspire.Integration.Phase28E2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    # ...
  end
```

**E2E Flow Pattern** (lines 53-84):
```elixir
  test "Full flow triggers every expected event: mint -> register -> read -> rotate -> update -> delete -> revoke -> unauthorized" do
    # Require IAT
    {:ok, %ServerPolicy{}} =
      Repository.put_server_policy(%ServerPolicy{
        registration_policy: :initial_access_token,
        # ...
      })

    # ... Mint IAT

    # 2. Register Client
    register_conn =
      build_conn(:post, "/register", %{
        "client_name" => "Phase 28 E2E Client",
        "redirect_uris" => ["https://client.example.com/callback"]
      })
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{iat_secret}")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
      
    assert register_conn.status == 201
```

## Shared Patterns

### Test Telemetry Capture
**Source:** `test/integration/phase28_e2e_test.exs`
**Apply to:** Integration tests asserting event completion
```elixir
  defp start_telemetry_capture do
    test_pid = self()
    handler_id = "phase28_test_handler_#{System.unique_integer()}"

    events = [
      [:lockspire, :dcr, :register],
      [:lockspire, :dcr, :read],
      [:lockspire, :dcr, :update],
      [:lockspire, :dcr, :delete],
      [:lockspire, :dcr, :rotate]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    events
  end
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `REQUIREMENTS.md` | docs | N/A | General traceability doc update |

## Metadata

**Analog search scope:** `lib/`, `test/`, `docs/`, root
**Files scanned:** 15
**Pattern extraction date:** 2024-05-20
