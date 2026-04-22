defmodule Lockspire.Host.AccountResolver do
  @moduledoc """
  Singular host seam for account lookup, claim material, and login handoff.
  """

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @type account :: term()
  @type context :: map()

  # @callback resolve_current_account/2
  @callback resolve_current_account(conn_or_socket :: term(), context()) ::
              {:ok, account()} | {:redirect, InteractionResult.t()}

  @callback resolve_account(account_reference :: term(), context()) ::
              {:ok, account()} | {:error, :not_found | term()}

  # @callback build_claims/2
  @callback build_claims(account(), context()) ::
              {:ok, Claims.t()} | {:error, term()}

  @callback redirect_for_login(conn_or_socket :: term(), context()) ::
              InteractionResult.t()
end
