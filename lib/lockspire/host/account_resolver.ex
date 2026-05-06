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

  @callback resolve_account(account_reference :: term(), context()) ::
              {:ok, account()} | {:error, :not_found | term()}

  @callback build_claims(account(), context()) ::
              {:ok, Claims.t()} | {:error, term()}

  @callback redirect_for_login(conn_or_socket :: connection(), context()) ::
              InteractionResult.t()

  @doc """
  Verifies the CIBA user_code (PIN/password) provided by the client.
  """
  @callback verify_backchannel_user_code(
              subject_id :: String.t(),
              user_code :: String.t(),
              context()
            ) ::
              :ok | {:error, :invalid_user_code | term()}

  @optional_callbacks [redirect_for_logout: 2, verify_backchannel_user_code: 3]
  @callback redirect_for_logout(conn_or_socket :: connection(), context()) ::
              InteractionResult.t()
end
