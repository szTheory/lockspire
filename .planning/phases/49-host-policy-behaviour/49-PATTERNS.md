# Phase 49: Host Policy Behaviour - Pattern Map

**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/host/token_exchange_validator.ex` | provider | request-response | `lib/lockspire/host/account_resolver.ex` | exact |
| `lib/lockspire/host/token_exchange_context.ex` | model | data-carrier | `lib/lockspire/host/context.ex` | exact |
| `lib/lockspire/config.ex` | config | config-access | `lib/lockspire/config.ex` | exact |
| `lib/lockspire/protocol/rfc8693_exchange.ex` | protocol | request-response | `lib/lockspire/protocol/userinfo.ex` | role-match |

## Pattern Assignments

### `lib/lockspire/host/token_exchange_validator.ex` (provider, request-response)

**Analog:** `lib/lockspire/host/account_resolver.ex`

**Behaviour Definition Pattern** (lines 1-13):
```elixir
defmodule Lockspire.Host.AccountResolver do
  @moduledoc """
  Singular host seam for account lookup, claim material, and login handoff.
  """

  alias Lockspire.Host.Claims
  alias Lockspire.Host.Context
  alias Lockspire.Host.InteractionResult

  @type account :: term()
  @type connection :: Plug.Conn.t() | Phoenix.LiveView.Socket.t() | term()
  @type context :: Context.t()

  @callback resolve_current_account(conn_or_socket :: connection(), context()) ::
              {:ok, account()} | {:redirect, InteractionResult.t()}
```
*Note: `TokenExchangeValidator` will define the `@callback validate(...)` signature.*

### `lib/lockspire/host/token_exchange_context.ex` (model, data-carrier)

**Analog:** `lib/lockspire/host/context.ex`

**Struct Pattern** (lines 1-15):
```elixir
defmodule Lockspire.Host.Context do
  @moduledoc """
  Contextual information passed to host integration callbacks.
  """

  @type interaction_type ::
          :login | :consent | :logout | :refresh | :exchange | :userinfo | term()

  @type t :: %__MODULE__{
          interaction_type: interaction_type() | nil,
          interaction_id: String.t() | nil,
          # ...
        }

  defstruct [
    :interaction_type,
    :interaction_id,
    # ...
  ]
end
```

### `lib/lockspire/config.ex` (config)

**Analog:** `lib/lockspire/config.ex`

**Config Reader Pattern** (lines 16-23):
```elixir
  @doc """
  Returns the configured account resolver module, or raises if missing.
  """
  @spec account_resolver!() :: module()
  def account_resolver! do
    fetch_required!(:account_resolver)
  end
```
*Note: For `token_exchange_validator`, it shouldn't use `fetch_required!` but rather provide a fallback to a default strict-deny implementation using `Application.get_env(@app, :token_exchange_validator, Lockspire.Host.DefaultTokenExchangeValidator)`.*

### `lib/lockspire/protocol/rfc8693_exchange.ex` (protocol, request-response)

**Analog:** `lib/lockspire/protocol/userinfo.ex`

**Host Behaviour Invocation and Error Mapping Pattern** (lines 115-131):
```elixir
  defp resolve_claims(%Token{} = access_token) do
    resolver = Config.account_resolver!()

    context = %{
      client_id: access_token.client_id,
      scopes: access_token.scopes,
      interaction_id: access_token.interaction_id
    }

    with {:ok, account} <- resolver.resolve_account(access_token.account_id, context),
         {:ok, %Claims{} = claims} <- resolver.build_claims(account, context) do
      {:ok, claims}
    else
      {:error, _reason} ->
        {:error,
         error(500, "server_error", "Unable to resolve subject claims", :claims_resolution_failed)}
    end
```
*Note: In `rfc8693_exchange.ex`, the `{:error, term()}` from the validator will be mapped to a standard `access_denied` error instead of a 500 server error, using the local `%Error{}` struct convention (e.g., status 403 or 400).*
