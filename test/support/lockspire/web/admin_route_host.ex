defmodule Lockspire.Web.AdminRouteHost do
  @moduledoc false

  @session_options [
    store: :cookie,
    key: "_lockspire_admin_route_test",
    signing_salt: "admin-route-host-session"
  ]

  def session_options, do: @session_options
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
