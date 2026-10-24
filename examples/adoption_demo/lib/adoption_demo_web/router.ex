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

  pipeline :admin_live_view_root_layout do
    plug(:put_admin_live_view_root_layout)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
  pipeline :lockspire_protected_api do
    plug(Lockspire.Plug.VerifyToken,
      scopes: ["read:billing"],
      audience: "https://api.billingo.test/billing",
      enforce_audience: true
    )

    plug(Lockspire.Plug.EnforceSenderConstraints)
    plug(Lockspire.Plug.RequireToken)
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

  require Lockspire.Web.AdminRoutes

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
    pipe_through: [:browser, :operator, :admin_live_view_root_layout],
    on_mount: AdoptionDemoWeb.OperatorAuthorization,
    root_layout: {AdoptionDemoWeb.AdminRootLayout, :root}
  )

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

  defp put_admin_live_view_root_layout(conn, _opts) do
    Phoenix.Controller.put_root_layout(conn, html: {AdoptionDemoWeb.AdminRootLayout, :root})
  end
end
