defmodule Lockspire.Web.Router do
  @moduledoc """
  Mountable Phoenix router exposing Lockspire's host-facing interaction entrypoints.
  """

  use Phoenix.Router

  import Phoenix.LiveView.Router

  pipeline :fapi_boundary do
    plug(Lockspire.Protocol.FAPI20EnforcerPlug)
  end

  scope "/" do
    get("/.well-known/openid-configuration", Lockspire.Web.DiscoveryController, :show)
    get("/jwks", Lockspire.Web.JwksController, :index)
    post("/par", Lockspire.Web.PushedAuthorizationRequestController, :create)
    post("/register", Lockspire.Web.RegistrationController, :create)
    get("/register/:client_id", Lockspire.Web.RegistrationController, :show)
    put("/register/:client_id", Lockspire.Web.RegistrationController, :update)
    delete("/register/:client_id", Lockspire.Web.RegistrationController, :delete)
    post("/device/code", Lockspire.Web.DeviceAuthorizationController, :create)
    post("/revoke", Lockspire.Web.RevocationController, :create)
    post("/introspect", Lockspire.Web.IntrospectionController, :create)
    get("/end_session", Lockspire.Web.EndSessionController, :show)
    post("/end_session", Lockspire.Web.EndSessionController, :create)
    get("/end_session/complete", Lockspire.Web.EndSessionController, :complete)
    get("/interactions/:interaction_id", Lockspire.Web.InteractionController, :show)
    post("/interactions/:interaction_id/complete", Lockspire.Web.InteractionController, :complete)
    live("/consent/:interaction_id", Lockspire.Web.ConsentLive, :show)
    live("/admin", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
    live("/admin/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
    live("/admin/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
    live("/admin/consents", Lockspire.Web.Live.Admin.ConsentsLive.Index, :index)
    live("/admin/consents/:id", Lockspire.Web.Live.Admin.ConsentsLive.Show, :show)
    live("/admin/tokens", Lockspire.Web.Live.Admin.TokensLive.Index, :index)
    live("/admin/tokens/:id", Lockspire.Web.Live.Admin.TokensLive.Show, :show)
    live("/admin/keys", Lockspire.Web.Live.Admin.KeysLive.Index, :index)
    live("/admin/keys/:id", Lockspire.Web.Live.Admin.KeysLive.Show, :show)
    live("/admin/interactions", Lockspire.Web.Live.Admin.InteractionsLive.Index, :index)
    live("/admin/iats", Lockspire.Web.Live.Admin.IatLive.Index, :index)
    live("/admin/iats/new", Lockspire.Web.Live.Admin.IatLive.New, :new)
    live("/admin/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit)

    live(
      "/admin/clients/:client_id/par-policy",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :par_policy
    )

    live(
      "/admin/clients/:client_id/security-profile",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :security_profile
    )

    live(
      "/admin/clients/:client_id/redirects",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :redirects
    )

    live(
      "/admin/clients/:client_id/logout-uris",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :logout_uris
    )

    live(
      "/admin/clients/:client_id/rotate-secret",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :rotate_secret
    )

    live(
      "/admin/clients/:client_id/rotate-registration-access-token",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :rotate_registration_access_token
    )

    live("/admin/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show)

    live(
      "/admin/policies/security-profile",
      Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile,
      :show
    )

    live("/admin/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show)
    live("/admin/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show)

    # FAPI 2.0 boundary-guarded routes
    scope "/" do
      pipe_through(:fapi_boundary)

      get("/authorize", Lockspire.Web.AuthorizeController, :show)
      post("/token", Lockspire.Web.TokenController, :create)
      get("/userinfo", Lockspire.Web.UserinfoController, :show)
    end
  end
end
