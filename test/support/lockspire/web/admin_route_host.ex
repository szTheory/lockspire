defmodule Lockspire.Web.AdminRouteHost do
  @moduledoc false

  @session_options [
    store: :cookie,
    key: "_lockspire_admin_route_test",
    signing_salt: "admin-route-host-session"
  ]

  def session_options, do: @session_options

  defmacro host_consent_routes(prefix) do
    quote do
      Phoenix.Router.scope unquote(prefix) do
        Phoenix.Router.pipe_through(:host_consent)

        Phoenix.LiveView.Router.live_session :host_consent,
          on_mount: [Lockspire.Web.AdminRouteHost.ConsentAuthorization],
          session: {Lockspire.Web.AdminRouteHost.Identity, :consent_session, []} do
          Phoenix.LiveView.Router.live(
            "/consent/:interaction_id",
            Lockspire.Web.AdminRouteHost.ConsentLive,
            :show
          )
        end
      end
    end
  end

  def record_trace(trace_id, surface) when is_binary(trace_id) and trace_id != "" do
    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) -> send(observer, {:route_trace, trace_id, surface})
      nil -> :ok
    end
  end

  def record_trace(_trace_id, _surface), do: :ok

  def record_trace(trace_id, surface) when is_binary(trace_id) and trace_id != "" do
    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) -> send(observer, {:route_trace, trace_id, surface})
      nil -> :ok
    end
  end

  def record_trace(_trace_id, _surface), do: :ok

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
        public_jwk: %{
          "kty" => "RSA",
          "kid" => "admin-route-key",
          "alg" => "RS256",
          "use" => "sig"
        },
        private_jwk_encrypted:
          :erlang.term_to_binary(%{"kid" => "admin-route-key", "d" => "fixture"}),
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
    identity_id = get_session(conn, "host_staff_id")

    if Lockspire.Web.AdminRouteHost.Identity.authority_installed?() do
      session = %{
        "host_staff_id" => identity_id,
        "host_session_id" => get_session(conn, "host_session_id")
      }

      case Lockspire.Web.AdminRouteHost.Identity.authorize_session(session) do
        {:ok, staff} ->
          Lockspire.Web.AdminRouteHost.record_trace(trace_id(conn), :admin_http_allowed)
          assign(conn, :host_staff_id, staff.id)

        :error ->
          Lockspire.Web.AdminRouteHost.record_trace(trace_id(conn), :admin_http_denied)
          conn |> send_resp(:forbidden, "Forbidden") |> halt()
      end
    else
      case identity_id do
        identity_id when is_binary(identity_id) and identity_id != "" ->
          Lockspire.Web.AdminRouteHost.record_trace(trace_id(conn), :admin_http_allowed)
          assign(conn, :host_staff_id, identity_id)

        _missing ->
          Lockspire.Web.AdminRouteHost.record_trace(trace_id(conn), :admin_http_denied)
          conn |> send_resp(:forbidden, "Forbidden") |> halt()
      end
    end
  end

  defp trace_id(conn), do: conn |> get_req_header("x-route-trace") |> List.first()
end

defmodule Lockspire.Web.AdminRouteHost.TraceSurface do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn, only: [get_req_header: 2]

  @impl true
  def init(surface), do: surface

  @impl true
  def call(conn, surface) do
    trace_id = conn |> get_req_header("x-route-trace") |> List.first()
    Lockspire.Web.AdminRouteHost.record_trace(trace_id, surface)
    conn
  end
end

defmodule Lockspire.Web.AdminRouteHost.LiveAuthorization do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  def on_mount(_name, _params, session, socket) do
    lifecycle = if Phoenix.LiveView.connected?(socket), do: :connected, else: :disconnected

    case Lockspire.Web.AdminRouteHost.Identity.authorize_session(session) do
      {:ok, staff} ->
        Lockspire.Web.AdminRouteHost.Identity.record_hook(staff.id)

        Lockspire.Web.AdminRouteHost.Identity.record_authorization(
          session,
          lifecycle,
          :allowed,
          staff.id
        )

        Lockspire.Web.AdminRouteHost.record_trace(Map.get(session, "trace_id"), :admin_hook)
        {:cont, assign(socket, :host_staff, staff)}

      :error ->
        Lockspire.Web.AdminRouteHost.Identity.record_hook(:denied)

        Lockspire.Web.AdminRouteHost.Identity.record_authorization(
          session,
          lifecycle,
          :denied,
          Map.get(session, "host_staff_id")
        )

        Lockspire.Web.AdminRouteHost.record_trace(
          Map.get(session, "trace_id"),
          :admin_hook_denied
        )

        {:halt, Phoenix.LiveView.redirect(socket, to: "/host/sign-in")}
    end
  end
end

defmodule Lockspire.Web.AdminRouteHost.Identity do
  @moduledoc false

  @authority_key :lockspire_admin_route_identity_authority

  def child_spec(opts) do
    %{id: make_ref(), start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts) do
    Agent.start_link(fn -> Keyword.fetch!(opts, :authority) end)
  end

  def default_authority do
    %{
      identities: %{
        "staff-1" => %{id: "staff-1", role: :admin},
        "staff-2" => %{id: "staff-2", role: :staff}
      },
      sessions: %{
        "host-session-staff-1" => %{identity_id: "staff-1", valid?: true},
        "host-session-staff-2" => %{identity_id: "staff-2", valid?: true}
      },
      permissions: %{"staff-1" => true, "staff-2" => false}
    }
  end

  def staff_session(identity_id) when is_binary(identity_id) do
    %{
      "host_staff_id" => identity_id,
      "host_session_id" => "host-session-#{identity_id}"
    }
  end

  def authority_pointer do
    case :persistent_term.get(@authority_key, :unset) do
      :unset -> :unset
      pid -> {:ok, pid}
    end
  end

  def install_authority(pid) when is_pid(pid), do: :persistent_term.put(@authority_key, pid)

  def restore_authority(:unset), do: :persistent_term.erase(@authority_key)
  def restore_authority({:ok, pid}), do: :persistent_term.put(@authority_key, pid)

  def authority_installed? do
    :persistent_term.get(@authority_key, :unset) != :unset
  end

  def put_authority(authority) when is_map(authority) do
    case :persistent_term.get(@authority_key, :unset) do
      pid when is_pid(pid) ->
        if Process.alive?(pid) do
          Agent.update(pid, fn _current -> authority end)
        else
          :error
        end

      _missing ->
        :error
    end
  catch
    :exit, _reason -> :error
  end

  def authorize_session(session) when is_map(session) do
    case :persistent_term.get(@authority_key, :unset) do
      :unset ->
        resolve(Map.get(session, "host_staff_id"))

      pid when is_pid(pid) ->
        if Process.alive?(pid) do
          Agent.get(pid, fn authority -> authorize(authority, session) end)
        else
          :error
        end

      _invalid ->
        :error
    end
  catch
    :exit, _reason -> :error
  end

  def record_authorization(session, lifecycle, decision, identity_id) do
    trace_id = Map.get(session, "trace_id")

    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) ->
        send(observer, {:host_authorization, trace_id, lifecycle, decision, identity_id})

      nil ->
        :ok
    end
  end

  defp authorize(authority, session) do
    identity_id = Map.get(session, "host_staff_id")
    session_id = Map.get(session, "host_session_id")

    with true <- is_binary(identity_id) and identity_id != "",
         true <- is_binary(session_id) and session_id != "",
         %{identity_id: ^identity_id, valid?: true} <- Map.get(authority.sessions, session_id),
         %{id: ^identity_id} = staff <- Map.get(authority.identities, identity_id),
         true <- Map.get(authority.permissions, identity_id) == true do
      {:ok, staff}
    else
      _denied -> :error
    end
  end

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

  def session(conn, label) do
    case :persistent_term.get(:lockspire_admin_route_hook_observer, nil) do
      observer when is_pid(observer) -> send(observer, {:host_session_callback, label})
      nil -> :ok
    end

    trace_id = conn |> Plug.Conn.get_req_header("x-route-trace") |> List.first()
    Lockspire.Web.AdminRouteHost.record_trace(trace_id, :admin_session)

    host_session =
      ["host_staff_id", "host_session_id"]
      |> Enum.map(&{&1, Plug.Conn.get_session(conn, &1)})
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    Map.merge(host_session, %{"host_session_label" => label, "trace_id" => trace_id})
  end

  def consent_session(conn) do
    trace_id = conn |> Plug.Conn.get_req_header("x-route-trace") |> List.first()
    Lockspire.Web.AdminRouteHost.record_trace(trace_id, :consent_session)
    %{"trace_id" => trace_id}
  end
end

defmodule Lockspire.Web.AdminRouteHost.ConsentAuthorization do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  def on_mount(_name, _params, session, socket) do
    Lockspire.Web.AdminRouteHost.record_trace(Map.get(session, "trace_id"), :consent_hook)
    {:cont, assign(socket, :host_consent, true)}
  end
end

defmodule Lockspire.Web.AdminRouteHost.ConsentLive do
  @moduledoc false

  use Phoenix.LiveView

  @impl true
  def mount(%{"interaction_id" => interaction_id}, _session, socket) do
    {:ok, Phoenix.Component.assign(socket, :interaction_id, interaction_id)}
  end

  @impl true
  def render(assigns), do: ~H"<main>Host consent <span><%= @interaction_id %></span></main>"
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
  require Lockspire.Web.AdminRouteHost

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  pipeline :host_consent do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :consent_http)
  end

  pipeline :public_surface do
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :public_http)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["admin-route"]}
  )

  Lockspire.Web.AdminRouteHost.host_consent_routes("/lockspire")

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
    pipe_through(:public_surface)
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
  require Lockspire.Web.AdminRouteHost

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  pipeline :host_consent do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :consent_http)
  end

  pipeline :public_surface do
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :public_http)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["default"]}
  )

  Lockspire.Web.AdminRouteHost.host_consent_routes("/lockspire")

  scope "/" do
    pipe_through(:public_surface)
    forward("/lockspire", Lockspire.Web.Router)
  end
end

defmodule Lockspire.Web.AdminRouteHost.NestedRouter do
  @moduledoc false

  use Phoenix.Router
  require Lockspire.Web.AdminRoutes
  require Lockspire.Web.AdminRouteHost

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  pipeline :host_consent do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :consent_http)
  end

  pipeline :public_surface do
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :public_http)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/teams/ops/identity/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["nested"]}
  )

  Lockspire.Web.AdminRouteHost.host_consent_routes("/teams/ops/identity")

  scope "/" do
    pipe_through(:public_surface)
    forward("/teams/ops/identity", Lockspire.Web.Router)
  end
end

defmodule Lockspire.Web.AdminRouteHost.RootRouter do
  @moduledoc false

  use Phoenix.Router
  require Lockspire.Web.AdminRoutes
  require Lockspire.Web.AdminRouteHost

  pipeline :browser do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.RequireStaff)
  end

  pipeline :host_consent do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :consent_http)
  end

  pipeline :public_surface do
    plug(Lockspire.Web.AdminRouteHost.TraceSurface, :public_http)
  end

  Lockspire.Web.AdminRoutes.lockspire_admin_routes("/admin",
    pipe_through: [:browser],
    on_mount: Lockspire.Web.AdminRouteHost.LiveAuthorization,
    session: {Lockspire.Web.AdminRouteHost.Identity, :session, ["root"]}
  )

  Lockspire.Web.AdminRouteHost.host_consent_routes("")

  scope "/" do
    pipe_through(:public_surface)
    forward("/", Lockspire.Web.Router)
  end
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
