# Lockspire-managed scaffolding
# Safe to update later only through `mix lockspire.upgrade` when the manifest says this file is unchanged.
# Keep this file unchanged if you want future managed upgrades to apply automatically.

defmodule GeneratedHostAppWeb.Router.Lockspire do
  @moduledoc """
  Host-owned mount point for the embedded Lockspire router.

  Import this module from `lib/generated_host_app_web/router.ex` and call
  `lockspire_routes/0` where your product wants the Lockspire surfaces to live.
  """

  defmacro lockspire_routes do
    quote do
      # For the canonical resource-server contract, semantic readers, and advanced
      # replay-store override, see `docs/protect-phoenix-api-routes.md`.
      # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
      # pipeline :lockspire_protected_api do
      #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://api.billingo.test/billing", enforce_audience: true
      #   plug Lockspire.Plug.EnforceSenderConstraints
      #   plug Lockspire.Plug.RequireToken
      # end
      # END LOCKSPIRE_PROTECTED_PIPELINE

      scope "/", GeneratedHostAppWeb do
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

      # This host-owned LiveView is intentionally defined before Lockspire's
      # public forward. It inherits the host browser pipeline and presentation
      # while obtaining all protocol facts from Lockspire.Web.ConsentContext.
      import Phoenix.LiveView.Router

      scope "/lockspire", GeneratedHostAppWeb do
        pipe_through([:browser])
        live("/consent/:interaction_id", LockspireConsentLive, :show)
      end

      # Lockspire supplies the route inventory and fixed LiveView session. Your
      # host-owned Plug and hook must implement current staff authorization.
      require Lockspire.Web.AdminRoutes

      pipeline :lockspire_operator_authorization do
        plug(GeneratedHostAppWeb.OperatorAuthorization)
      end

      Lockspire.Web.AdminRoutes.lockspire_admin_routes(
        "/lockspire/admin",
        pipe_through: [:browser, :lockspire_operator_authorization],
        on_mount: GeneratedHostAppWeb.OperatorAuthorization
      )

      scope "/" do
        forward("/lockspire", Lockspire.Web.Router)
      end
    end
  end
end
