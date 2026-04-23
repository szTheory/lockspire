defmodule <%= @web_module %>.Router.Lockspire do
  @moduledoc """
  Host-owned mount point for the embedded Lockspire router.

  Import this module from `lib/<%= @web_path %>/router.ex` and call
  `lockspire_routes/0` where your product wants the Lockspire surfaces to live.
  """

  def lockspire_routes do
    """
    scope "/", <%= @web_module %> do
      pipe_through [:browser]

      # Keep this route host-owned. Most apps will place it behind an authenticated
      # account pipeline or move it under their existing settings area.
      get "/authorized-apps", AuthorizedAppsController, :index
      delete "/authorized-apps/:id", AuthorizedAppsController, :delete
    end

    scope "/" do
      forward "<%= @mount_path %>", Lockspire.Web.Router
    end
    """
  end
end
