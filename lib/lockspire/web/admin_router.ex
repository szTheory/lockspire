defmodule Lockspire.Web.AdminRouter do
  @moduledoc """
  Mountable Phoenix router exposing only Lockspire operator/admin LiveViews.

  Host applications should mount this router behind their own operator
  authentication pipeline before the general `Lockspire.Web.Router` forward.
  """

  use Phoenix.Router

  import Phoenix.LiveView.Router

  scope "/" do
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
  end
end
