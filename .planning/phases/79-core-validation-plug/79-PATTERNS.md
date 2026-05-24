# Phase 79: Core Validation Plug - Pattern Map

**Mapped:** `date +%Y-%m-%d`
**Files analyzed:** 4
**Analogs found:** 3 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/plug/verify_token.ex` | plug | request-response | `lib/lockspire/mtls/plug.ex` | role-match |
| `lib/lockspire/plug/require_token.ex` | plug | request-response | `lib/lockspire/protocol/fapi20_enforcer_plug.ex` | role-match |
| `lib/lockspire/access_token.ex` | model | data encapsulation | `lib/lockspire/domain/token.ex` | role-match |
| `lib/lockspire/key_cache.ex` | service | in-memory ETS | None | none |

## Pattern Assignments

### `lib/lockspire/plug/verify_token.ex` (plug, request-response)

**Analog:** `lib/lockspire/mtls/plug.ex` (for structure) and `lib/lockspire/protocol/fapi20_enforcer_plug.ex` (for header extraction).

**Imports and Structure pattern** (lines 1-10 of `lib/lockspire/mtls/plug.ex`):
```elixir
defmodule Lockspire.MTLS.Plug do
  @moduledoc """
  Plug middleware to extract Mutual TLS (mTLS) client certificates.
  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
```

**Soft Plug State Assignment pattern** (adapted from `lib/lockspire/mtls/plug.ex` lines 23-28):
```elixir
  @impl Plug
  def call(conn, opts) do
    # Instead of put_private, use Plug.Conn.assign for VerifyToken
    # assign(conn, :access_token, %Lockspire.AccessToken{...})
```

**Header Extraction pattern** (lines 78-79 of `lib/lockspire/protocol/fapi20_enforcer_plug.ex`):
```elixir
    auth_header = get_req_header(conn, "authorization") |> List.first()
    auth_scheme_is_dpop? = is_binary(auth_header) and String.starts_with?(auth_header, "DPoP ")
```

---

### `lib/lockspire/plug/require_token.ex` (plug, request-response)

**Analog:** `lib/lockspire/protocol/fapi20_enforcer_plug.ex` (for strict halting and JSON error responses).

**Strict Halting pattern** (lines 154-165 of `lib/lockspire/protocol/fapi20_enforcer_plug.ex`):
```elixir
  defp reject_userinfo(conn) do
    body = %{
      "error" => "invalid_token",
      "error_description" => "DPoP-bound access token required"
    }

    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header(
      "www-authenticate",
      ~s(DPoP realm="Lockspire Userinfo", error="invalid_token", algs="ES256 PS256 EdDSA")
    )
    |> send_resp(401, Jason.encode!(body))
    |> halt()
  end
```

---

### `lib/lockspire/access_token.ex` (model, data encapsulation)

**Analog:** `lib/lockspire/domain/token.ex`

**Struct definition pattern** (lines 1-12 of `lib/lockspire/domain/token.ex`):
```elixir
defmodule Lockspire.Domain.Token do
  @moduledoc """
  Durable token and token-family state owned by Lockspire.
  """

  @type token_type :: :authorization_code | :access_token | :refresh_token

  @type t :: %__MODULE__{
          id: integer() | nil,
          # ...
        }
```
**Struct defaults pattern** (lines 37-41 of `lib/lockspire/domain/token.ex`):
```elixir
  defstruct [
    :id,
    :token_hash,
    :token_type,
    # ...
  ]
```

---

## No Analog Found

Files with no close match in the codebase (planner should use general Elixir/Erlang patterns):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/lockspire/key_cache.ex` | service | in-memory ETS | No custom `GenServer` interacting with `:ets` directly exists yet (existing caches use `Cachex`). The `KeyCache` should be implemented as a standard Elixir `GenServer` initializing an ETS table with `[:set, :named_table, :public, read_concurrency: true]` to meet the Phase 79 design context requirement for microsecond key resolution latency. |

## Metadata

**Analog search scope:** `lib/**/*.ex`
**Files scanned:** 188
**Pattern extraction date:** 2024-05-18
