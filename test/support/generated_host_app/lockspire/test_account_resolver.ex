defmodule GeneratedHostApp.Lockspire.TestAccountResolver do
  @moduledoc false

  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias GeneratedHostAppWeb.Plugs.PutCurrentScope

  @impl true
  def resolve_current_account(%Plug.Conn{} = conn, context) do
    case conn.assigns[:current_scope] || PutCurrentScope.current_scope(conn) do
      %{user: user} when is_map(user) ->
        {:ok, maybe_put_auth_time(user, conn)}

      _ ->
        {:redirect, redirect_for_login(conn, context)}
    end
  end

  def resolve_current_account(_conn_or_socket, context),
    do: {:redirect, redirect_for_login(nil, context)}

  @impl true
  def resolve_account(account_reference, _context), do: build_account(account_reference)

  @impl true
  def build_claims(account, _context) do
    email = Map.get(account, :email, "#{account.id}@example.test")
    name = Map.get(account, :name, "Generated Host User")

    {:ok,
     %Claims{
       subject: to_string(account.id),
       id_token: %{"email" => email},
       userinfo: %{
         "email" => email,
         "email_verified" => true,
         "name" => name
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
        |> Map.take([
          :verification_handle,
          "verification_handle",
          :interaction_id,
          "interaction_id"
        ])
        |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
    }
  end

  defp build_account(account_reference) do
    {:ok,
     %{
       id: account_reference,
       email: "#{account_reference}@example.test",
       name: "Generated Host User"
     }}
  end

  defp maybe_put_auth_time(user, conn) do
    case session_auth_time(conn) do
      nil -> user
      auth_time -> Map.put(user, :auth_time, auth_time)
    end
  end

  defp session_auth_time(conn) do
    case Plug.Conn.get_session(conn, "current_auth_time_unix") do
      unix when is_integer(unix) -> DateTime.from_unix!(unix)
      _other -> nil
    end
  end
end
