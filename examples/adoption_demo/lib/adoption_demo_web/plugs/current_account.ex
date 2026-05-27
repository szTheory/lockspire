defmodule AdoptionDemoWeb.Plugs.CurrentAccount do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    login = get_session(conn, "demo_login")
    assign(conn, :current_account, AdoptionDemo.Accounts.get(login || ""))
  end
end
