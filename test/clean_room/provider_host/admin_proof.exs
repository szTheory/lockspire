defmodule CleanRoomProviderWeb.AdminProof.Store do
  @moduledoc false

  def child_spec(_opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [[]]}}
  end

  def start_link(_opts) do
    Agent.start_link(&initial_state/0, name: __MODULE__)
  end

  def ensure_started do
    case Agent.start_link(&initial_state/0, name: __MODULE__) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  defp initial_state do
    %{
      enabled: true,
      identity_present: true,
      session_valid: true,
      http: 0,
      http_allowed: 0,
      http_denied: 0,
      live_mount: 0,
      live_mount_allowed: 0,
      live_mount_denied: 0,
      live_connected: 0,
      live_connected_allowed: 0,
      live_connected_denied: 0,
      protected_callbacks: 0,
      params: 0,
      params_denied: 0
    }
  end

  def allowed?(session, connected?) do
    ensure_started()

    Agent.get_and_update(__MODULE__, fn state ->
      permitted = permitted?(state, session)
      count = if connected?, do: :live_connected, else: :live_mount

      outcome =
        case {connected?, permitted} do
          {true, true} -> :live_connected_allowed
          {true, false} -> :live_connected_denied
          {false, true} -> :live_mount_allowed
          {false, false} -> :live_mount_denied
        end

      {permitted, state |> Map.update!(count, &(&1 + 1)) |> Map.update!(outcome, &(&1 + 1))}
    end)
  end

  def current_allowed?(session) do
    ensure_started()

    Agent.get(__MODULE__, fn state ->
      permitted?(state, session)
    end)
  end

  def authorize_http(session) do
    ensure_started()

    Agent.get_and_update(__MODULE__, fn state ->
      permitted = permitted?(state, session)
      counter = if permitted, do: :http_allowed, else: :http_denied
      {permitted, state |> Map.update!(:http, &(&1 + 1)) |> Map.update!(counter, &(&1 + 1))}
    end)
  end

  def record_params do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | params: &1.params + 1})
  end

  def record_params_denied do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | params_denied: &1.params_denied + 1})
  end

  def record_protected_callback do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | protected_callbacks: &1.protected_callbacks + 1})
  end

  def set_enabled(enabled) when is_boolean(enabled) do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | enabled: enabled})
  end

  def invalidate_session do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | session_valid: false})
  end

  def delete_identity do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | identity_present: false})
  end

  def observations do
    ensure_started()

    Agent.get(__MODULE__, fn state ->
      Map.take(state, [
        :http,
        :http_allowed,
        :http_denied,
        :live_mount,
        :live_mount_allowed,
        :live_mount_denied,
        :live_connected,
        :live_connected_allowed,
        :live_connected_denied,
        :protected_callbacks,
        :params,
        :params_denied
      ])
    end)
  end

  def reset do
    ensure_started()

    Agent.update(__MODULE__, fn _state -> initial_state() end)
  end

  defp permitted?(state, session) do
    state.enabled and state.identity_present and state.session_valid and
      Map.get(session, "host_staff_id") == "proof-staff" and
      Map.get(session, "host_session_id") == "proof-session"
  end
end

defmodule CleanRoomProviderWeb.AdminProof.Control do
  @moduledoc false
  @behaviour Plug
  import Plug.Conn, only: [get_req_header: 2, send_resp: 3, halt: 1]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    expected = System.get_env("LOCKSPIRE_PROOF_CAPABILITY", "")
    supplied = conn |> get_req_header("x-lockspire-proof-capability") |> List.first() || ""

    if conn.remote_ip in [{127, 0, 0, 1}, {0, 0, 0, 0, 0, 0, 0, 1}] and
         expected != "" and Plug.Crypto.secure_compare(expected, supplied) do
      conn
    else
      conn |> send_resp(:not_found, "not found") |> halt()
    end
  end
end

defmodule CleanRoomProviderWeb.AdminProof.Controller do
  @moduledoc false
  use Phoenix.Controller, formats: [:json]

  def withdraw(conn, _params) do
    CleanRoomProviderWeb.AdminProof.Store.set_enabled(false)
    send_resp(conn, 204, "")
  end

  def restore(conn, _params) do
    CleanRoomProviderWeb.AdminProof.Store.set_enabled(true)
    send_resp(conn, 204, "")
  end

  def observations(conn, _params) do
    json(conn, CleanRoomProviderWeb.AdminProof.Store.observations())
  end

  def seed(conn, _params) do
    attrs = %{
      client_id: "phase170-browser-client",
      name: "Phase 170 Browser App",
      client_type: :confidential,
      redirect_uris: ["https://phase170.example.test/callback"],
      allowed_scopes: ["openid", "profile"],
      allowed_grant_types: ["authorization_code"],
      token_endpoint_auth_method: :client_secret_basic,
      actor: %{type: :operator, id: "phase170-proof"}
    }

    case Lockspire.Admin.create_client(attrs) do
      {:ok, _result} -> json(conn, %{client_id: attrs.client_id})
      {:error, _reason} -> send_resp(conn, :internal_server_error, "proof seed failed")
    end
  end

  def reset(conn, _params) do
    CleanRoomProviderWeb.AdminProof.Store.reset()
    send_resp(conn, 204, "")
  end

  def invalidate_session(conn, _params) do
    CleanRoomProviderWeb.AdminProof.Store.invalidate_session()
    send_resp(conn, 204, "")
  end

  def delete_identity(conn, _params) do
    CleanRoomProviderWeb.AdminProof.Store.delete_identity()
    send_resp(conn, 204, "")
  end
end

defmodule CleanRoomProviderWeb.AdminProof.SessionController do
  @moduledoc false
  use Phoenix.Controller, formats: [:html]
  import Plug.Conn

  def new(conn, _params) do
    csrf = Plug.CSRFProtection.get_csrf_token()

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
    <!doctype html><html><head><meta name="csrf-token" content="#{escape(csrf)}"></head>
    <body><form method="post" action="/login">
      <input type="hidden" name="_csrf_token" value="#{escape(csrf)}">
      <button type="submit">Sign in</button>
    </form></body></html>
    """)
  end

  def create(conn, %{"mode" => "nonstaff"}) do
    conn
    |> put_session("host_staff_id", "proof-nonstaff")
    |> put_session("host_session_id", "proof-nonstaff-session")
    |> redirect(to: System.get_env("LOCKSPIRE_PROOF_ADMIN_PATH", "/lockspire/admin"))
  end

  def create(conn, _params) do
    conn
    |> put_session("host_staff_id", "proof-staff")
    |> put_session("host_session_id", "proof-session")
    |> redirect(to: System.get_env("LOCKSPIRE_PROOF_ADMIN_PATH", "/lockspire/admin"))
  end

  defp escape(value), do: value |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
end

defmodule CleanRoomProviderWeb.AdminProof.OperatorAuthorization do
  @moduledoc false
  @behaviour Plug
  import Plug.Conn, only: [assign: 3, get_session: 2, send_resp: 3, halt: 1]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    session = %{
      "host_staff_id" => get_session(conn, "host_staff_id"),
      "host_session_id" => get_session(conn, "host_session_id")
    }

    if CleanRoomProviderWeb.AdminProof.Store.authorize_http(session) do
      assign(conn, :host_staff_id, session["host_staff_id"])
    else
      conn |> send_resp(:forbidden, "operator authorization required") |> halt()
    end
  end

  def on_mount(:default, _params, session, socket) do
    case CleanRoomProviderWeb.AdminProof.authorize(session, socket) do
      :ok ->
        CleanRoomProviderWeb.AdminProof.Store.record_protected_callback()

        socket =
          Phoenix.LiveView.attach_hook(socket, :proof_current_policy, :handle_params, fn _params,
                                                                                         _uri,
                                                                                         live_socket ->
            if CleanRoomProviderWeb.AdminProof.Store.current_allowed?(session) do
              CleanRoomProviderWeb.AdminProof.Store.record_params()
              {:cont, live_socket}
            else
              CleanRoomProviderWeb.AdminProof.Store.record_params_denied()
              {:halt, Phoenix.LiveView.redirect(live_socket, to: "/login")}
            end
          end)

        {:cont, Phoenix.Component.assign(socket, :host_staff_id, session["host_staff_id"])}

      :error ->
        {:halt, Phoenix.LiveView.redirect(socket, to: "/login")}
    end
  end
end

defmodule CleanRoomProviderWeb.AdminProof do
  @moduledoc false

  def session(conn) do
    %{
      "host_staff_id" => Plug.Conn.get_session(conn, "host_staff_id"),
      "host_session_id" => Plug.Conn.get_session(conn, "host_session_id")
    }
  end

  def authorize(session, socket) do
    lifecycle = if Phoenix.LiveView.connected?(socket), do: :connected, else: :disconnected

    if CleanRoomProviderWeb.AdminProof.Store.allowed?(session, lifecycle == :connected),
      do: :ok,
      else: :error
  end
end

defmodule CleanRoomProviderWeb.AdminProof.PublicLive do
  @moduledoc false
  use Phoenix.LiveView

  def session(conn),
    do:
      Map.put(
        CleanRoomProviderWeb.AdminProof.session(conn),
        "host_public_id",
        "proof-public-user"
      )

  def render(assigns) do
    ~H"""
    <main data-proof-public-session>
      <h1>Host public session</h1>
      <.link href={System.get_env("LOCKSPIRE_PROOF_ADMIN_PATH", "/lockspire/admin")}>Open admin</.link>
    </main>
    """
  end
end

defmodule CleanRoomProviderWeb.AdminProof.ConsentLive do
  @moduledoc false
  use Phoenix.LiveView

  def session(conn),
    do:
      Map.put(
        CleanRoomProviderWeb.AdminProof.session(conn),
        "host_consent_id",
        "proof-consent-interaction"
      )

  def render(assigns) do
    ~H"""
    <main data-proof-consent-session>
      <h1>Host consent session</h1>
      <.link href={System.get_env("LOCKSPIRE_PROOF_ADMIN_PATH", "/lockspire/admin")}>Open admin</.link>
    </main>
    """
  end
end

defmodule CleanRoomProviderWeb.AdminRootLayout do
  @moduledoc false
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!doctype html>
    <html lang="en"><head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
      <script src="/lockspire-assets/phoenix.js" defer></script>
      <script src="/lockspire-assets/phoenix_live_view.js" defer></script>
      <script src="/lockspire-assets/lockspire-admin-live-view.js" defer></script>
      <title>Lockspire admin proof</title>
    </head><body>{@inner_content}</body></html>
    """
  end
end
