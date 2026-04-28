defmodule GeneratedHostAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :lockspire

  plug Plug.Session,
    store: :cookie,
    key: "_generated_host_app_key",
    signing_salt: "generated_host_salt"

  plug GeneratedHostAppWeb.Router
end
