defmodule Lockspire.Web.AdminRouter do
  @moduledoc """
  Mountable Phoenix router exposing only Lockspire operator/admin LiveViews.

  Host applications should mount this router behind their own operator
  authentication pipeline before the general `Lockspire.Web.Router` forward.
  """

  use Phoenix.Router

  require Phoenix.LiveView.Router

  scope "/" do
    require Lockspire.Web.AdminRoutes
    Lockspire.Web.AdminRoutes.__admin_live_routes__()
  end
end
