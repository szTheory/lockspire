defmodule <%= @web_module %>.Router.Lockspire do
  @moduledoc """
  Host-owned mount point for the embedded Lockspire router.
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
