defmodule CleanRoomProvider.Lockspire.AccountResolver do
  @moduledoc false
  @behaviour Lockspire.Host.AccountResolver

  alias CleanRoomProvider.Accounts
  alias Lockspire.Host.{Claims, InteractionResult}

  @impl true
  def resolve_current_account(%Plug.Conn{} = conn, context) do
    case Plug.Conn.get_session(conn, "account_id") do
      id when is_binary(id) and id != "" -> Accounts.fetch(id)
      _ -> {:redirect, redirect_for_login(conn, context)}
    end
  end

  def resolve_current_account(_conn_or_socket, context),
    do: {:redirect, redirect_for_login(nil, context)}

  @impl true
  def resolve_account(id, _context), do: Accounts.fetch(id)

  @impl true
  def build_claims(account, _context) do
    {:ok,
     %Claims{
       subject: account.id,
       id_token: %{"email" => account.email, "name" => account.name},
       userinfo: %{"email" => account.email, "email_verified" => true, "name" => account.name}
     }}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/login",
      return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
      params: %{
        "interaction_id" =>
          Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
      }
    }
  end
end
