defmodule Lockspire.Web.AdminRouteHost do
  @moduledoc false

  @session_options [
    store: :cookie,
    key: "_lockspire_admin_route_test",
    signing_salt: "admin-route-host-session"
  ]

  def session_options, do: @session_options

  def seed_admin_records! do
    now = DateTime.utc_now()

    {:ok, client} =
      Lockspire.Storage.Ecto.Repository.register_client(%Lockspire.Domain.Client{
        lifetime_version: 0,
        client_id: "admin-route-client",
        client_secret_hash: "sha256:admin-route-client:fixture-hash",
        client_type: :confidential,
        name: "Admin Route Fixture",
        redirect_uris: ["https://admin-route.example.invalid/callback"],
        allowed_scopes: ["openid", "email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: now,
        metadata: %{}
      })

    {:ok, consent} =
      Lockspire.Storage.Ecto.Repository.grant_consent(%Lockspire.Domain.ConsentGrant{
        account_id: "admin-route-account",
        client_id: client.client_id,
        scopes: ["openid", "email"],
        granted_at: now,
        metadata: %{}
      })

    {:ok, token} =
      Lockspire.Storage.Ecto.Repository.store_token(%Lockspire.Domain.Token{
        token_hash: "sha256:admin-route-token:fixture-hash",
        token_type: :refresh_token,
        family_id: "admin-route-family",
        generation: 0,
        client_id: client.client_id,
        account_id: "admin-route-account",
        consent_grant_id: consent.id,
        scopes: ["openid", "email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, key} =
      Lockspire.Storage.Ecto.Repository.publish_key(%Lockspire.Domain.SigningKey{
        kid: "admin-route-key",
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk: %{"kty" => "RSA", "kid" => "admin-route-key", "alg" => "RS256", "use" => "sig"},
        private_jwk_encrypted: :erlang.term_to_binary(%{"kid" => "admin-route-key", "d" => "fixture"}),
        status: :active,
        published_at: now,
        activated_at: now,
        inserted_at: now
      })

    %{client: client, consent: consent, token: token, key: key}
  end
end

defmodule Lockspire.Web.AdminRouteHost.RequireStaff do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case get_session(conn, "host_staff_id") do
      identity_id when is_binary(identity_id) and identity_id != "" ->
        assign(conn, :host_staff_id, identity_id)

      _missing ->
        conn |> send_resp(:forbidden, "Forbidden") |> halt()
    end
  end
end

defmodule Lockspire.Web.AdminRouteHost.LiveAuthorization do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  def on_mount(_name, _params, session, socket) do
    case Lockspire.Web.AdminRouteHost.Identity.resolve(Map.get(session, "host_staff_id")) do
      {:ok, staff} ->
        Lockspire.Web.AdminRouteHost.Identity.record_hook(staff.id)
        {:cont, assign(socket, :host_staff, staff)}

      :error ->
        Lockspire.Web.AdminRouteHost.Identity.record_hook(:denied)
        {:halt, Phoenix.LiveView.redirect(socket, to: "/host/sign-in")}
    end
  end
end

defmodule Lockspire.Web.AdminRouteHost.Identity do
  @moduledoc false

  def resolve("staff-1"), do: {:ok, %{id: "staff-1", role: :admin}}
  def resolve(_identity_id), do: :error

  def record_hook(identity) do
    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) -> send(observer, {:host_live_hook, identity})
      nil -> :ok
    end
  end

  def record_mount do
    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) -> send(observer, :admin_mount_reached)
      nil -> :ok
    end
  end

  def session(_conn, label) do
    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) -> send(observer, {:host_session_callback, label})
      nil -> :ok
    end

    %{"host_session_label" => label}
  end
end

defmodule Lockspire.Web.AdminRouteHost.MountSentinelLive do
  @moduledoc false

  use Phoenix.LiveView

  @impl true
  def mount(_params, _session, socket) do
    Lockspire.Web.AdminRouteHost.Identity.record_mount()
    {:ok, socket}
  end

  @impl true
  def render(assigns), do: ~H"<main>Mounted</main>"
end

defmodule Lockspire.Web.AdminRouteHost.ForwardOnlyRouter do
  @moduledoc false

  use Phoenix.Router

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  scope "/lockspire/admin" do
    pipe_through(:browser)
    forward("/", Lockspire.Web.AdminRouter)
  end
end

defmodule Lockspire.Web.AdminRouteHost.CanonicalRouter do
  @moduledoc false

  use Phoenix.Router

  require Phoenix.LiveView.Router
  require Lockspire.Web.AdminRoutes

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["admin-route"]}
  )

  scope "/" do
    pipe_through(:browser)

    Phoenix.LiveView.Router.live_session :host_auth_probe,
      on_mount: [Lockspire.Web.AdminRouteHost.LiveAuthorization] do
      Phoenix.LiveView.Router.live(
        "/admin-auth-probe",
        Lockspire.Web.AdminRouteHost.MountSentinelLive,
        :index
      )
    end
  end

  scope "/" do
    forward("/lockspire", Lockspire.Web.Router)
  end
end

defmodule Lockspire.Web.AdminRouteHost.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :lockspire

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: Lockspire.Web.AdminRouteHost.session_options()]]
  )

  plug(Plug.Session, Lockspire.Web.AdminRouteHost.session_options())
  plug(Lockspire.Web.AdminRouteHost.ForwardOnlyRouter)
end

defmodule Lockspire.Web.AdminRouteHost.CanonicalEndpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :lockspire

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: Lockspire.Web.AdminRouteHost.session_options()]]
  )

  plug(Plug.Session, Lockspire.Web.AdminRouteHost.session_options())
  plug(Lockspire.Web.AdminRouteHost.CanonicalRouter)
end

defmodule Lockspire.Web.AdminRouteHost.DefaultRouter do
  @moduledoc false

  use Phoenix.Router
  require Lockspire.Web.AdminRoutes

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["default"]}
  )
end

defmodule Lockspire.Web.AdminRouteHost.NestedRouter do
  @moduledoc false

  use Phoenix.Router
  require Lockspire.Web.AdminRoutes

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/teams/ops/identity/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["nested"]}
  )
end

defmodule Lockspire.Web.AdminRouteHost.RootRouter do
  @moduledoc false

  use Phoenix.Router
  require Lockspire.Web.AdminRoutes

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["root"]}
  )
end

defmodule Lockspire.Web.AdminRouteHost.DefaultEndpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :lockspire

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: Lockspire.Web.AdminRouteHost.session_options()]]
  )

  plug(Plug.Session, Lockspire.Web.AdminRouteHost.session_options())
  plug(Lockspire.Web.AdminRouteHost.DefaultRouter)
end

defmodule Lockspire.Web.AdminRouteHost.NestedEndpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :lockspire

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: Lockspire.Web.AdminRouteHost.session_options()]]
  )

  plug(Plug.Session, Lockspire.Web.AdminRouteHost.session_options())
  plug(Lockspire.Web.AdminRouteHost.NestedRouter)
end

defmodule Lockspire.Web.AdminRouteHost.RootEndpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :lockspire

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: Lockspire.Web.AdminRouteHost.session_options()]]
  )

  plug(Plug.Session, Lockspire.Web.AdminRouteHost.session_options())
  plug(Lockspire.Web.AdminRouteHost.RootRouter)
end
