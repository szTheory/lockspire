defmodule Lockspire.TestAccountResolver do
  @moduledoc false
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context) do
    {:ok, %{id: "account-123"}}
  end

  @impl true
  def resolve_account(account_reference, _context) do
    {:ok, %{id: account_reference}}
  end

  @impl true
  def build_claims(account, _context) do
    {:ok,
     %Claims{
       subject: to_string(account.id),
       id_token: %{"sub" => to_string(account.id)},
       userinfo: %{"sub" => to_string(account.id)}
     }}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/sign-in",
      return_to: Map.get(context, :return_to),
      params: %{"interaction_id" => "interaction-123"}
    }
  end

  @impl true
  def redirect_for_logout(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/sign-out",
      return_to: Map.get(context, :return_to),
      params: %{"account_id" => Map.get(context, :account_id)}
    }
  end
end
