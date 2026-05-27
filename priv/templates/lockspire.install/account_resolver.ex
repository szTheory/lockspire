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
  def resolve_current_account(conn_or_socket, context) do
    <%= if @sigra_host do %>
    # This helper reads conn.assigns.current_scope.user when present. Adjust it if
    # your Sigra-backed host stores the signed-in user under a different assign.
    # Keep your real Sigra login route host-owned and preserve both return_to and
    # interaction_id so Lockspire can resume the pending OAuth interaction after login.
    <% end %>
    case current_account(conn_or_socket) do
      nil -> {:redirect, redirect_for_login(conn_or_socket, context)}
      account -> {:ok, account}
    end
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

    Typical shape:

        {:ok,
         %Claims{
           subject: "user:" <> to_string(account.id),
           claims: %{
             "email" => account.email,
             "name" => account.name
           }
         }}

    Keep tenant authorization, billing tier checks, and product policy in your host
    application. Lockspire should receive stable account facts, not own your business
    authorization model.
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

  defp current_account(%Plug.Conn{assigns: %{current_scope: %{user: user}}}) when not is_nil(user),
    do: user

  defp current_account(%Plug.Conn{assigns: %{current_scope: scope}}) do
    case Map.get(scope, :user) || Map.get(scope, "user") do
      nil -> nil
      user -> user
    end
  end

  defp current_account(%Plug.Conn{assigns: %{current_user: user}}) when not is_nil(user), do: user

  defp current_account(%Phoenix.LiveView.Socket{assigns: %{current_scope: %{user: user}}})
       when not is_nil(user),
       do: user

  defp current_account(%Phoenix.LiveView.Socket{assigns: %{current_scope: scope}}) do
    case Map.get(scope, :user) || Map.get(scope, "user") do
      nil -> nil
      user -> user
    end
  end

  defp current_account(%Phoenix.LiveView.Socket{assigns: %{current_user: user}})
       when not is_nil(user),
       do: user

  defp current_account(_conn_or_socket), do: nil
end
