defmodule <%= @resolver_module %> do
  @behaviour Lockspire.Host.AccountResolver
<%= if @sigra_host do %>
  @moduledoc """
  Host-owned **Lockspire.AccountResolver** stub generated with `--sigra-host`.

  Wire `resolve_current_account/2` to your **Sigra** session / `current_scope` (see
  Sigra guide *Companion OAuth provider* on hexdocs). Lockspire must not import Sigra
  at compile time — keep the boundary in this module.
  """
<% else %>
  @moduledoc """
  Host-owned account resolver stub. Replace stubs with your real session integration.
  """
<% end %>

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, context) do
    <%= if @sigra_host do %>
    # TODO: resolve authenticated user from Sigra plugs / assign, then return
    # {:ok, account_map} instead of redirect when a session exists.
    <% end %>
    {:redirect, redirect_for_login(nil, context)}
  end

  @impl true
  def resolve_account(account_reference, _context) do
    {:ok, %{id: account_reference}}
  end

  @impl true
  def build_claims(account, _context) do
    {:ok, %Claims{sub: to_string(account.id)}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/login",
      return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
      params: %{
        "interaction_id" => Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
      }
    }
  end
end
