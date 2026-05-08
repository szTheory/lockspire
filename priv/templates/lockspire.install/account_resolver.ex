defmodule <%= @resolver_module %> do
  @behaviour Lockspire.Host.AccountResolver
<%= if @sigra_host do %>
  @moduledoc """
  Host-owned **Lockspire.AccountResolver** stub generated with `--sigra-host`.

  Wire `resolve_current_account/2` to your **Sigra** session / `current_scope` (see
  Sigra guide *Companion OAuth provider* on hexdocs). Read
  `conn.assigns.current_scope.user` (or your equivalent host-owned assign) and return
  `{:ok, user}` when the session is present. Lockspire must not import Sigra at compile
  time — keep the boundary in this module.
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
    # TODO: read conn.assigns.current_scope.user (or your equivalent host-owned assign),
    # then return {:ok, user_map} instead of redirecting when a session exists.
    # Keep your real Sigra login route host-owned and preserve both return_to and
    # interaction_id so Lockspire can resume the pending OAuth interaction after login.
    <% end %>
    {:redirect, redirect_for_login(nil, context)}
  end

  @impl true
  def resolve_account(_account_reference, _context) do
    raise """
    Implement <%= @resolver_module %>.resolve_account/2 before shipping Lockspire.

    This callback must load the real host account for the stored subject reference.
    Do not leave generated placeholder account lookup in production.
    """
  end

  @impl true
  def build_claims(_account, _context) do
    raise """
    Implement <%= @resolver_module %>.build_claims/2 before shipping Lockspire.

    This callback defines the subject and emitted OIDC claims for your host accounts.
    Use a stable internal identifier for `sub`, keep the default example claim set
    intentionally narrow, and replace the scaffold with real host-owned claims logic.
    """
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

  @impl true
  def redirect_for_logout(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/logout",
      return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
      params: %{
        "account_id" => Map.get(context, :account_id) || Map.get(context, "account_id")
      }
    }
  end
end
