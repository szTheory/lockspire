defmodule AdoptionDemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :adoption_demo

  @session_options [
    store: :cookie,
    key: "_adoption_demo_key",
    signing_salt: "adoption_demo_session"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static,
    at: "/lockspire-assets",
    from: :phoenix,
    only: ~w(phoenix.js)
  )

  plug(Plug.Static,
    at: "/lockspire-assets",
    from: :phoenix_live_view,
    only: ~w(phoenix_live_view.js)
  )

  plug(Plug.Static,
    at: "/lockspire-assets",
    from: :adoption_demo,
    only: ~w(lockspire-admin-live-view.js)
  )

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  # Lets host-owned HTML forms reach verb-specific routes such as
  # `delete "/authorized-apps/:id"` via a `_method` field.
  plug(Plug.MethodOverride)

  plug(Plug.Session, @session_options)

  plug(AdoptionDemoWeb.Router)
end
