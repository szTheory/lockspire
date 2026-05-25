defmodule GeneratedHostAppWeb.Router do
  use Phoenix.Router

  alias GeneratedHostAppWeb.Plugs.PutCurrentScope

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

  pipeline :lockspire_protected_api do
    plug(Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api")

    plug(Lockspire.Plug.EnforceSenderConstraints,
      dpop_replay_store: GeneratedHostAppWeb.ProtectedApiReplayStore
    )

    plug(Lockspire.Plug.RequireToken)
  end

  scope "/", GeneratedHostAppWeb do
    pipe_through(:browser)

    get("/login", SessionController, :new)
    post("/login", SessionController, :create)

    get("/verify", LockspireVerificationController, :show)
    post("/verify", LockspireVerificationController, :lookup)
    post("/verify/:handle/approve", LockspireVerificationController, :approve)
    post("/verify/:handle/deny", LockspireVerificationController, :deny)
  end

  scope "/" do
    forward("/lockspire", Lockspire.Web.Router)
  end

  scope "/api", GeneratedHostAppWeb do
    pipe_through([:api, :lockspire_protected_api])

    get("/billing/summary", ProtectedApiController, :show)
  end
end
