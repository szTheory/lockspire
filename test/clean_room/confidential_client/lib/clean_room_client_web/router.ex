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
    get("/oauth/dpop/start", CleanRoomClientWeb.OAuthController, :dpop_start)
    get("/oauth/dpop/callback", CleanRoomClientWeb.OAuthController, :dpop_callback)
    get("/journey", CleanRoomClientWeb.JourneyController, :status)
    get("/health", CleanRoomClientWeb.JourneyController, :status)
  end
end
