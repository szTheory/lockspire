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

      # Keep `/verify` host-owned. Require your normal auth/session wiring and add
      # host-owned rate limiting for both GET and POST before exposing device login.
      # `verification_uri_complete` is prefill-only; GET /verify must stay side-effect
      # free and must never lookup, approve, or deny on page load.
      # Read `docs/device-flow-host-guide.md` for the full rate-limit and anti-phishing
      # contract, and do not log raw verification query strings or raw user codes.
      get "/verify", LockspireVerificationController, :show
      post "/verify", LockspireVerificationController, :lookup
      post "/verify/:handle/approve", LockspireVerificationController, :approve
      post "/verify/:handle/deny", LockspireVerificationController, :deny

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
