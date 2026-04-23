defmodule Lockspire.Web.Router do
  @moduledoc """
  Mountable Phoenix router exposing Lockspire's host-facing interaction entrypoints.
  """

  use Phoenix.Router

  import Phoenix.LiveView.Router

  scope "/" do
    get("/authorize", Lockspire.Web.AuthorizeController, :show)
    get("/interactions/:interaction_id", Lockspire.Web.InteractionController, :show)
    post("/interactions/:interaction_id/complete", Lockspire.Web.InteractionController, :complete)
    live("/consent/:interaction_id", Lockspire.Web.ConsentLive, :show)
  end
end
