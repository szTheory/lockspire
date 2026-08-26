defmodule GeneratedHostAppWeb.Router do
  use Phoenix.Router

  alias GeneratedHostAppWeb.Plugs.PutCurrentScope

  import GeneratedHostAppWeb.Router.Lockspire

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(PutCurrentScope)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # This is intentionally host-owned. Real applications replace the fixture's
  # authorization plug with their operator session and product policy.
  pipeline :require_operator do
    plug(GeneratedHostAppWeb.Plugs.RequireOperator)
  end

  pipeline :lockspire_protected_api do
    plug(Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api")
    plug(Lockspire.Plug.EnforceSenderConstraints)
    plug(Lockspire.Plug.RequireToken)
  end

  scope "/", GeneratedHostAppWeb do
    pipe_through(:browser)

    get("/login", SessionController, :new)
    post("/login", SessionController, :create)
  end

  lockspire_routes()

  scope "/api", GeneratedHostAppWeb do
    pipe_through([:api, :lockspire_protected_api])

    get("/billing/summary", ProtectedApiController, :show)
  end
end
