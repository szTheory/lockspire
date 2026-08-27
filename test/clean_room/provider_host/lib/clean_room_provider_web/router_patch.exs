defmodule CleanRoomProviderWeb.Router do
  use Phoenix.Router
  import CleanRoomProviderWeb.Router.Lockspire

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :require_operator do
    plug(CleanRoomProviderWeb.OperatorAuthorization)
  end

  pipeline :lockspire_protected_api do
    plug(Lockspire.Plug.VerifyToken,
      scopes: ["read:billing"],
      audience: "http://127.0.0.1:4100/api/billing"
    )

    plug(Lockspire.Plug.EnforceSenderConstraints)
    plug(Lockspire.Plug.RequireToken)
  end

  scope "/", CleanRoomProviderWeb do
    pipe_through(:browser)
    get("/login", SessionController, :new)
    post("/login", SessionController, :create)
  end

  lockspire_routes()

  scope "/api", CleanRoomProviderWeb do
    pipe_through([:api, :lockspire_protected_api])
    get("/billing/summary", BillingController, :show)
  end
end
