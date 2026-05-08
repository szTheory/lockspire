defmodule GeneratedHostAppWeb.Plugs.PutCurrentScope do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    assign(conn, :current_scope, current_scope(conn))
  end

  def current_scope(conn) do
    case get_session(conn, "current_account_id") do
      account_id when is_binary(account_id) and account_id != "" ->
        %{user: build_user(account_id, conn)}

      _ ->
        nil
    end
  end

  defp build_user(account_id, conn) do
    %{
      id: account_id,
      email: get_session(conn, "current_account_email") || "#{account_id}@example.test",
      name: get_session(conn, "current_account_name") || "Generated Host User"
    }
  end
end
