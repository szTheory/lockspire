defmodule CleanRoomClientWeb.Router do
  use Phoenix.Router
  import Plug.Conn

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
  end

  scope "/" do
    pipe_through(:browser)
    get("/oauth/start", CleanRoomClientWeb.OAuthController, :start)
    get("/oauth/callback", CleanRoomClientWeb.OAuthController, :callback)
    post("/acceptance/replace-nonce", CleanRoomClientWeb.OAuthController, :replace_nonce)
    get("/oauth/dpop/start", CleanRoomClientWeb.OAuthController, :dpop_start)
    get("/oauth/dpop/callback", CleanRoomClientWeb.OAuthController, :dpop_callback)

    post(
      "/acceptance/dpop/resource/challenge",
      CleanRoomClientWeb.JourneyController,
      :resource_challenge
    )

    post("/acceptance/dpop/resource/retry", CleanRoomClientWeb.JourneyController, :resource_retry)

    post(
      "/acceptance/dpop/resource/restart-ready",
      CleanRoomClientWeb.JourneyController,
      :resource_restart_ready
    )

    post(
      "/acceptance/dpop/resource/replay",
      CleanRoomClientWeb.JourneyController,
      :resource_replay
    )

    get("/journey", CleanRoomClientWeb.JourneyController, :status)
    get("/acceptance/callback-attempts", CleanRoomClientWeb.JourneyController, :callback_attempts)
    get("/acceptance/csrf", CleanRoomClientWeb.JourneyController, :csrf)
    get("/health", CleanRoomClientWeb.JourneyController, :status)
  end
end
