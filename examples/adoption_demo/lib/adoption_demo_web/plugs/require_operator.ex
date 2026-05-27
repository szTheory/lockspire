defmodule AdoptionDemoWeb.Plugs.RequireOperator do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_account] do
      %{operator?: true} ->
        conn

      _other ->
        conn
        |> put_resp_content_type("text/html")
        |> put_status(:forbidden)
        |> text("Operator access requires the demo ops account.")
        |> halt()
    end
  end
end
