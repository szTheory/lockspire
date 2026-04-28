defmodule GeneratedHostApp.Lockspire.TestAccountResolver do
  @moduledoc false

  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(%Plug.Conn{} = conn, context) do
    case Plug.Conn.get_session(conn, "current_account_id") do
      account_id when is_binary(account_id) and account_id != "" ->
        {:ok, %{id: account_id}}

      _ ->
        {:redirect, redirect_for_login(conn, context)}
    end
  end

  def resolve_current_account(_conn_or_socket, context),
    do: {:redirect, redirect_for_login(nil, context)}

  @impl true
  def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

  @impl true
  def build_claims(account, _context) do
    {:ok,
     %Claims{
       subject: to_string(account.id),
       id_token: %{"email" => "#{account.id}@example.test"},
       userinfo: %{
         "email" => "#{account.id}@example.test",
         "email_verified" => true,
         "name" => "Generated Host User"
       }
     }}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/login",
      return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
      params:
        context
        |> Map.take([:verification_handle, "verification_handle"])
        |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
    }
  end
end
