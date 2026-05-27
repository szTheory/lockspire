defmodule AdoptionDemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :adoption_demo

  socket("/live", Phoenix.LiveView.Socket)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.Session,
    store: :cookie,
    key: "_adoption_demo_key",
    signing_salt: "adoption_demo_session"
  )

  plug(AdoptionDemoWeb.Router)
end
