# Lockspire-managed scaffolding
# Safe to update later only through `mix lockspire.upgrade` when the manifest says this file is unchanged.
# Keep this file unchanged if you want future managed upgrades to apply automatically.

defmodule GeneratedHostAppWeb.Router.Lockspire do
  @moduledoc """
  Host-owned mount point for the embedded Lockspire router.

  Import this module from `lib/generated_host_app_web/router.ex` and call
  `lockspire_routes()` where your product wants the Lockspire surfaces to live.
  Calling it injects a real, deny-closed route table -- see `lockspire_routes/1` below.

  You can also paste the body this macro expands to directly into your router
  module, in place of calling it. The emitted body contains no macro-expansion-time
  constructs, so a direct paste compiles.
  """

  # Optional example: a protected-resource pipeline for your own host-owned API
  # routes that must accept Lockspire-issued access tokens. This is documentation
  # only -- uncomment and adapt it in your own router if you have a host API that
  # needs to verify Lockspire tokens directly. It plays no part in the routes
  # `lockspire_routes/1` injects below.
  #
  # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
  # pipeline :lockspire_protected_api do
  #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://api.billingo.test/billing", enforce_audience: true
  #   plug Lockspire.Plug.EnforceSenderConstraints,
  #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  #   plug Lockspire.Plug.RequireToken
  # end
  # END LOCKSPIRE_PROTECTED_PIPELINE

  defmacro lockspire_routes(_opts \\ []) do
    quote do
      # Deny-closed by default: replace this pipeline's plug with your own
      # operator auth before mounting the admin surface in production. Namespaced
      # so it cannot collide with a pipeline your host already defines.
      pipeline :lockspire_require_operator do
        plug(:lockspire_deny_operator_access)
      end

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

      # Mount Lockspire's operator UI behind your host-owned operator auth
      # pipeline before the general public OAuth/OIDC forward below. The
      # :lockspire_require_operator pipeline emitted above denies every request
      # with a 403 until you replace its plug with your own operator auth.
      #
      # Do not rely on Lockspire to authenticate your operators. Lockspire owns
      # protocol/admin state after the request reaches these LiveViews; your host app
      # owns who may reach them.
      scope "/lockspire/admin" do
        pipe_through([:browser, :lockspire_require_operator])
        forward("/", Lockspire.Web.AdminRouter)
      end

      # The interaction routes and the consent LiveView must be piped through your
      # host's browser pipeline for session fetching and CSRF protection -- the
      # public forward below carries no pipeline of its own.
      scope "/lockspire" do
        pipe_through([:browser])

        get("/interactions/:interaction_id", Lockspire.Web.InteractionController, :show)

        post(
          "/interactions/:interaction_id/complete",
          Lockspire.Web.InteractionController,
          :complete
        )

        # `on_mount:` is deliberately left for your host to supply here -- it is
        # specific to your account/session implementation (for example,
        # phx.gen.auth's `{MyAppWeb.UserAuth, :mount_current_scope}`).
        live_session :lockspire_consent do
          live("/consent/:interaction_id", Lockspire.Web.ConsentLive, :show)
        end
      end

      scope "/" do
        forward("/lockspire", Lockspire.Web.Router)
      end

      defp lockspire_deny_operator_access(conn, _opts) do
        conn
        |> Plug.Conn.send_resp(403, "Lockspire operator access is not configured")
        |> Plug.Conn.halt()
      end
    end
  end
end
