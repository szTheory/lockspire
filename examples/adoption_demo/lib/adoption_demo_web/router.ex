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

  scope "/lockspire/admin" do
    pipe_through([:browser, :operator, :admin_live_view_root_layout])

    # The embedded AdminRouter is still forwarded for host compatibility. The
    # demo also mounts its LiveViews directly so LiveView signs the full host
    # paths used by websocket joins, matching the test host mount.
    live("/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
    live("/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
    live("/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
    live("/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
    live("/consents", Lockspire.Web.Live.Admin.ConsentsLive.Index, :index)
    live("/consents/:id", Lockspire.Web.Live.Admin.ConsentsLive.Show, :show)
    live("/tokens", Lockspire.Web.Live.Admin.TokensLive.Index, :index)
    live("/tokens/:id", Lockspire.Web.Live.Admin.TokensLive.Show, :show)
    live("/keys", Lockspire.Web.Live.Admin.KeysLive.Index, :index)
    live("/keys/:id", Lockspire.Web.Live.Admin.KeysLive.Show, :show)
    live("/interactions", Lockspire.Web.Live.Admin.InteractionsLive.Index, :index)
    live("/logouts", Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index, :index)
    live("/iats", Lockspire.Web.Live.Admin.IatLive.Index, :index)
    live("/iats/new", Lockspire.Web.Live.Admin.IatLive.New, :new)

    live(
      "/device_authorizations",
      Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index,
      :index
    )

    live("/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit)

    live(
      "/clients/:client_id/par-policy",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :par_policy
    )

    live(
      "/clients/:client_id/security-profile",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :security_profile
    )

    live(
      "/clients/:client_id/redirects",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :redirects
    )

    live(
      "/clients/:client_id/logout-uris",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :logout_uris
    )

    live(
      "/clients/:client_id/rotate-secret",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :rotate_secret
    )

    live(
      "/clients/:client_id/rotate-registration-access-token",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :rotate_registration_access_token
    )

    live("/dcr", Lockspire.Web.Live.Admin.DcrLive.Index, :index)
    live("/policies", Lockspire.Web.Live.Admin.PoliciesLive.Index, :index)
    live("/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show)

    live(
      "/policies/security-profile",
      Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile,
      :show
    )

    live("/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show)
    live("/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show)

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

  defp put_admin_live_view_root_layout(conn, _opts) do
    Phoenix.Controller.put_root_layout(conn, html: {AdoptionDemoWeb.AdminRootLayout, :root})
  end
end
