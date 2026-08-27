defmodule CleanRoomClientWeb.Router do
  use Phoenix.Router
  import Plug.Conn

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    get("/oauth/start", CleanRoomClientWeb.OAuthController, :start)
    get("/oauth/callback", CleanRoomClientWeb.OAuthController, :callback)
    post("/acceptance/replace-nonce", CleanRoomClientWeb.OAuthController, :replace_nonce)
    get("/oauth/dpop/start", CleanRoomClientWeb.OAuthController, :dpop_start)
    get("/oauth/dpop/callback", CleanRoomClientWeb.OAuthController, :dpop_callback)
    get("/journey", CleanRoomClientWeb.JourneyController, :status)
    get("/acceptance/callback-attempts", CleanRoomClientWeb.JourneyController, :callback_attempts)
    get("/health", CleanRoomClientWeb.JourneyController, :status)
  end
end
