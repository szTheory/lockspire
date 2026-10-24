defmodule AdoptionDemoWeb.Plugs.RequireOperator do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def operator_account?(%{operator?: true}), do: true
  def operator_account?(_account), do: false

  def call(conn, _opts) do
    case conn.assigns[:current_account] do
      account when is_map(account) ->
        if operator_account?(account), do: conn, else: forbidden(conn)

      nil ->
        redirect(conn, to: "/login?" <> URI.encode_query(%{"return_to" => return_to(conn)}))
        |> halt()

      _other ->
        forbidden(conn)
    end
  end

  defp forbidden(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> put_status(:forbidden)
    |> text(
      "Operator access requires the demo ops account. Sign out, then choose ops from the demo login picker."
    )
    |> halt()
  end

  defp return_to(%{query_string: ""} = conn), do: conn.request_path
  defp return_to(conn), do: conn.request_path <> "?" <> conn.query_string
end
