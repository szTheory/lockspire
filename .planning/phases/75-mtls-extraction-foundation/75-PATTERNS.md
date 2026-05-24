# Phase 75: MTLS Extraction Foundation - Pattern Map

**Mapped:** 2024-05-22
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/mtls/extractor.ex` | behaviour | transform | `lib/lockspire/host/token_exchange_validator.ex` | role-match |
| `lib/lockspire/mtls/plug.ex` | middleware | request-response | `lib/lockspire/protocol/fapi20_enforcer_plug.ex` | exact |
| `lib/lockspire/mtls/cowboy_direct_extractor.ex` | component | extraction | `lib/lockspire/host/default_delegation_validator.ex` | role-match |
| `lib/lockspire/mtls/proxy_header_extractor.ex` | component | extraction | `lib/lockspire/host/default_delegation_validator.ex` | role-match |
| `test/lockspire/mtls/plug_test.exs` | test | request-response | `test/lockspire/protocol/fapi20_enforcer_plug_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/mtls/extractor.ex` (behaviour, transform)

**Analog:** `lib/lockspire/host/token_exchange_validator.ex`

**Behaviour Definition Pattern** (lines 1-17):
```elixir
defmodule Lockspire.Host.TokenExchangeValidator do
  @moduledoc """
  Behaviour for validating token exchange requests against host application business logic.
  """

  alias Lockspire.Host.TokenExchangeContext

  @doc """
  Validates a token exchange request.

  Returns:
    - `:ok` to permit the exchange with default claims.
    - `{:ok, %{claims: claims}}` to permit and merge additional claims.
    - `{:error, reason}` to deny the exchange.
  """
  @callback validate(context :: TokenExchangeContext.t()) ::
              :ok
              | {:ok, %{claims: map()}}
              | {:error, term()}
end
```

---

### `lib/lockspire/mtls/plug.ex` (middleware, request-response)

**Analog:** `lib/lockspire/protocol/fapi20_enforcer_plug.ex`

**Imports and Plug Initialization Pattern** (lines 24-41):
```elixir
  import Plug.Conn

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Observability
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Storage.Ecto.Repository

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    # ... logic here ...
  end
```

**Error Handling / Halt Pattern** (lines 121-132):
```elixir
  defp reject_token(conn) do
    body = %{
      "error" => "invalid_dpop_proof",
      "error_description" => "A valid DPoP proof is required"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(body))
    |> halt()
  end
```

---

### `lib/lockspire/mtls/cowboy_direct_extractor.ex` & `lib/lockspire/mtls/proxy_header_extractor.ex` (component, extraction)

**Analog:** `lib/lockspire/host/default_delegation_validator.ex`

**Behaviour Implementation Pattern** (lines 1-13):
```elixir
defmodule Lockspire.Host.DefaultDelegationValidator do
  @moduledoc """
  A default implementation of `Lockspire.Host.TokenExchangeValidator` that properly structures
  the `act` (actor) claim when delegating tokens according to RFC 8693.
  """

  @behaviour Lockspire.Host.TokenExchangeValidator

  alias Lockspire.Host.TokenExchangeContext

  @impl true
  def validate(%TokenExchangeContext{actor_token: nil}), do: :ok
```

---

### `test/lockspire/mtls/plug_test.exs` (test, request-response)

**Analog:** `test/lockspire/protocol/fapi20_enforcer_plug_test.exs`

**Plug Test Structure Pattern** (lines 1-9):
```elixir
defmodule Lockspire.Protocol.FAPI20EnforcerPlugTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Phoenix.ConnTest, only: [build_conn: 2, build_conn: 3]

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.FAPI20EnforcerPlug
```

**Plug Test Execution Pattern** (lines 51-57):
```elixir
      conn =
        build_conn(:post, "/token", %{"client_id" => "unknown"})
        |> Map.put(:path_info, ["token"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
```

**Error Assertion Pattern** (lines 104-107):
```elixir
      assert conn.halted
      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_request"
```

## Shared Patterns

### HTTP Response Rejection
**Source:** `lib/lockspire/protocol/fapi20_enforcer_plug.ex`
**Apply to:** `Lockspire.MTLS.Plug` on missing/invalid certificate
```elixir
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(body))
    |> halt()
```

## Metadata

**Analog search scope:** `lib/lockspire/`, `test/`
**Files scanned:** ~5 (targeted)
**Pattern extraction date:** 2024-05-22
