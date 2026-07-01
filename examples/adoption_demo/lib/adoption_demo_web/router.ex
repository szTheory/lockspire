defmodule AdoptionDemoWeb.Router do
  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(AdoptionDemoWeb.Plugs.CurrentAccount)
    plug(:fetch_live_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :operator do
    plug(AdoptionDemoWeb.Plugs.RequireOperator)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
  pipeline :lockspire_protected_api do
    plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://billing.acme-ledger.test", enforce_audience: true
    plug Lockspire.Plug.EnforceSenderConstraints,
      dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    plug Lockspire.Plug.RequireToken
  end
  # END LOCKSPIRE_PROTECTED_PIPELINE

  scope "/", AdoptionDemoWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/login", SessionController, :new)
    post("/login", SessionController, :create)
    post("/logout", SessionController, :delete)
    get("/developer/apps", DeveloperController, :index)
    get("/oauth/callback", OAuthCallbackController, :show)
    get("/authorized-apps", AuthorizedAppsController, :index)
    delete("/authorized-apps/:id", AuthorizedAppsController, :delete)
    get("/verify", DeviceVerificationController, :show)
    post("/verify", DeviceVerificationController, :lookup)
    post("/verify/:handle/approve", DeviceVerificationController, :approve)
    post("/verify/:handle/deny", DeviceVerificationController, :deny)
  end

  scope "/lockspire/admin" do
    pipe_through([:browser, :operator])
    forward("/", Lockspire.Web.AdminRouter)
  end

  scope "/lockspire" do
    pipe_through(:browser)

    get("/interactions/:interaction_id", Lockspire.Web.InteractionController, :show)
    post("/interactions/:interaction_id/complete", Lockspire.Web.InteractionController, :complete)
    get("/consent/:interaction_id", AdoptionDemoWeb.ConsentController, :show)
  end

  scope "/" do
    forward("/lockspire", Lockspire.Web.Router)
  end

  scope "/api", AdoptionDemoWeb do
    pipe_through([:api, :lockspire_protected_api])

    get("/billing/summary", ApiController, :billing_summary)
  end
end
