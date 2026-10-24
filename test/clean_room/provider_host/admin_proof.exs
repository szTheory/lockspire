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

  defp initial_state, do: %{enabled: true, http: 0, live_mount: 0, live_connected: 0, params: 0}

  def allowed?(session, connected?) do
    ensure_started()

    Agent.get_and_update(__MODULE__, fn state ->
      permitted =
        state.enabled and Map.get(session, "host_staff_id") == "proof-staff" and
          Map.get(session, "host_session_id") == "proof-session"

      count = if connected?, do: :live_connected, else: :live_mount
      {permitted, Map.update!(state, count, &(&1 + 1))}
    end)
  end

  def current_allowed?(session) do
    ensure_started()

    Agent.get(__MODULE__, fn state ->
      state.enabled and Map.get(session, "host_staff_id") == "proof-staff" and
        Map.get(session, "host_session_id") == "proof-session"
    end)
  end

  def authorize_http(session) do
    ensure_started()

    Agent.get_and_update(__MODULE__, fn state ->
      permitted =
        state.enabled and Map.get(session, "host_staff_id") == "proof-staff" and
          Map.get(session, "host_session_id") == "proof-session"

      {permitted, %{state | http: state.http + 1}}
    end)
  end

  def record_params do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | params: &1.params + 1})
  end

  def set_enabled(enabled) when is_boolean(enabled) do
    ensure_started()
    Agent.update(__MODULE__, &%{&1 | enabled: enabled})
  end

  def observations do
    ensure_started()
    Agent.get(__MODULE__, &Map.take(&1, [:http, :live_mount, :live_connected, :params]))
  end

  def reset do
    ensure_started()

    Agent.update(
      __MODULE__,
      &%{&1 | enabled: true, http: 0, live_mount: 0, live_connected: 0, params: 0}
    )
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
        socket =
          Phoenix.LiveView.attach_hook(socket, :proof_current_policy, :handle_params, fn _params,
                                                                                         _uri,
                                                                                         live_socket ->
            CleanRoomProviderWeb.AdminProof.Store.record_params()

            if CleanRoomProviderWeb.AdminProof.Store.current_allowed?(session),
              do: {:cont, live_socket},
              else: {:halt, Phoenix.LiveView.redirect(live_socket, to: "/login")}
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
