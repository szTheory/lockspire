defmodule CleanRoomClientWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :clean_room_confidential_client

  @session [store: :cookie, key: "_clean_room_client", signing_salt: "clean-room-client-salt"]
  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.Session, @session)
  plug(CleanRoomClientWeb.Router)
end
