defmodule AdoptionDemoWeb.Plugs.RequireOperator do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_account] do
      %{operator?: true} ->
        conn

      nil ->
        redirect(conn, to: "/login?" <> URI.encode_query(%{"return_to" => return_to(conn)}))
        |> halt()

      _other ->
        conn
        |> put_resp_content_type("text/html")
        |> put_status(:forbidden)
        |> text(
          "Operator access requires the demo ops account. Sign out, then choose ops from the demo login picker."
        )
        |> halt()
    end
  end

  defp return_to(%{query_string: ""} = conn), do: conn.request_path
  defp return_to(conn), do: conn.request_path <> "?" <> conn.query_string
end
