defmodule GeneratedHostAppWeb.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", GeneratedHostAppWeb do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create

    get "/verify", LockspireVerificationController, :show
    post "/verify", LockspireVerificationController, :lookup
    post "/verify/:handle/approve", LockspireVerificationController, :approve
    post "/verify/:handle/deny", LockspireVerificationController, :deny
  end

  scope "/" do
    forward "/lockspire", Lockspire.Web.Router
  end
end
