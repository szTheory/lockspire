defmodule GeneratedHostAppWeb.FetchSession do
  @moduledoc false
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts), do: Plug.Conn.fetch_session(conn)
end

defmodule GeneratedHostAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :lockspire

  plug(Plug.Session,
    store: :cookie,
    key: "_generated_host_app_key",
    signing_salt: "generated_host_salt"
  )

  plug(GeneratedHostAppWeb.FetchSession)
  plug(GeneratedHostAppWeb.Router)
end
