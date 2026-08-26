defmodule <%= @web_module %>.Router.Lockspire do
  @moduledoc """
  Host-owned mount point for the embedded Lockspire router.

  Import this module from `lib/<%= @web_path %>/router.ex` and call
  `lockspire_routes/0` where your product wants the Lockspire surfaces to live.
  """

  defmacro lockspire_routes do
    quote do
      # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
      # pipeline :lockspire_protected_api do
      #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://api.billingo.test/billing", enforce_audience: true
      #   plug Lockspire.Plug.EnforceSenderConstraints,
      #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
      #   plug Lockspire.Plug.RequireToken
      # end
      # END LOCKSPIRE_PROTECTED_PIPELINE

      scope "/", <%= @web_module %> do
        pipe_through([:browser])

        # Keep `/verify` host-owned. Require your normal auth/session wiring and add
        # host-owned rate limiting for both GET and POST before exposing device login.
        # `verification_uri_complete` is prefill-only; GET /verify must stay side-effect
        # free and must never lookup, approve, or deny on page load.
        # Read `docs/device-flow-host-guide.md` for the full rate-limit and anti-phishing
        # contract, and do not log raw verification query strings or raw user codes.
        get("/verify", LockspireVerificationController, :show)
        post("/verify", LockspireVerificationController, :lookup)
        post("/verify/:handle/approve", LockspireVerificationController, :approve)
        post("/verify/:handle/deny", LockspireVerificationController, :deny)

        # Keep this route host-owned. Most apps will place it behind an authenticated
        # account pipeline or move it under their existing settings area.
        get("/authorized-apps", AuthorizedAppsController, :index)
        delete("/authorized-apps/:id", AuthorizedAppsController, :delete)
      end

      # Mount Lockspire's operator UI behind your host-owned operator auth
      # pipeline before the general public OAuth/OIDC forward below.
      #
      # Example:
      #
      #   scope "<%= @mount_path %>/admin" do
      #     pipe_through [:browser, :require_operator]
      #     forward "/", Lockspire.Web.AdminRouter
      #   end
      #
      # Do not rely on Lockspire to authenticate your operators. Lockspire owns
      # protocol/admin state after the request reaches these LiveViews; your host app
      # owns who may reach them.
      scope "<%= @mount_path %>/admin" do
        pipe_through([:browser, :require_operator])
        # `mix lockspire.verify` requires this marker, which is emitted only
        # after the host-owned operator pipeline in this generated macro.
        forward("/", Lockspire.Web.AdminRouter, [], metadata: %{lockspire_operator_guard: true})
      end

      # This host-owned LiveView is intentionally defined before Lockspire's
      # public forward. It inherits the host browser pipeline and presentation
      # while obtaining all protocol facts from Lockspire.Web.ConsentContext.
      import Phoenix.LiveView.Router

      scope "<%= @mount_path %>", <%= @web_module %> do
        pipe_through([:browser])
        live("/consent/:interaction_id", LockspireConsentLive, :show)
      end

      scope "/" do
        forward("<%= @mount_path %>", Lockspire.Web.Router)
      end
    end
  end
end
