defmodule Lockspire.Web.Router do
  @moduledoc """
  Mountable Phoenix router exposing Lockspire's host-facing interaction entrypoints.
  """

  use Phoenix.Router

  import Phoenix.LiveView.Router

  scope "/" do
    get("/.well-known/openid-configuration", Lockspire.Web.DiscoveryController, :show)
    get("/authorize", Lockspire.Web.AuthorizeController, :show)
    get("/jwks", Lockspire.Web.JwksController, :index)
    post("/par", Lockspire.Web.PushedAuthorizationRequestController, :create)
    post("/register", Lockspire.Web.RegistrationController, :create)
    get("/register/:client_id", Lockspire.Web.RegistrationController, :show)
    put("/register/:client_id", Lockspire.Web.RegistrationController, :update)
    delete("/register/:client_id", Lockspire.Web.RegistrationController, :delete)
    post("/token", Lockspire.Web.TokenController, :create)
    post("/revoke", Lockspire.Web.RevocationController, :create)
    post("/introspect", Lockspire.Web.IntrospectionController, :create)
    get("/userinfo", Lockspire.Web.UserinfoController, :show)
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
    live("/admin/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit)

    live(
      "/admin/clients/:client_id/par-policy",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :par_policy
    )

    live(
      "/admin/clients/:client_id/redirects",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :redirects
    )

    live(
      "/admin/clients/:client_id/rotate-secret",
      Lockspire.Web.Live.Admin.ClientsLive.Show,
      :rotate_secret
    )

    live("/admin/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show)
    live("/admin/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show)
  end
end
