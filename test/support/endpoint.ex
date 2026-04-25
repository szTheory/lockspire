defmodule Lockspire.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :lockspire

  plug Plug.Session,
    store: :cookie,
    key: "_lockspire_key",
    signing_salt: "lockspire_salt"

  plug Lockspire.Web.Router
end
