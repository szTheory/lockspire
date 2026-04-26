defmodule Lockspire.Web.Live.Admin.ClientsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.ClientsLive.Index
  alias Lockspire.Web.Live.Admin.ClientsLive.Show
  alias Phoenix.Router

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "")

    on_exit(fn ->
      Application.put_env(:lockspire, :mount_path, "/lockspire")
    end)

    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      render_errors: [view: Lockspire.Web.ErrorView, accepts: ~w(html json)],
      live_view: [signing_salt: "lockspire_salt"]
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, _alpha} =
      Repository.register_client(%Client{
        client_id: "alpha-client",
        client_secret_hash: "sha256:alpha:hash",
        client_type: :confidential,
        name: "Alpha Client",
        redirect_uris: ["https://alpha.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, _beta} =
      Repository.register_client(%Client{
        client_id: "beta-client",
        client_type: :public,
        name: "Beta Client",
        redirect_uris: ["https://beta.example.com/callback"],
        allowed_scopes: ["profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        par_policy: :required,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, _gamma} =
      Repository.register_client(%Client{
        client_id: "gamma-client",
        client_type: :confidential,
        name: "Gamma Client",
        redirect_uris: ["https://gamma.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{},
        provenance: :self_registered,
        registration_client_uri: "https://lockspire.example.com/register/gamma-client",
        registration_access_token_hash: "sha256:gamma:rat"
      })

    :ok
  end

  test "router exposes admin clients as the default operator entrypoint without an overview route" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients/:client_id/par-policy", Show))
    refute Enum.any?(routes, &(&1.path == "/admin/overview"))
  end

  test "clients index renders durable client truth and URL-driven filters" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{"q" => "Alpha"}, "/admin?q=Alpha", socket)

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Client inventory"
    assert html =~ "Alpha Client"
    assert html =~ "Keys"
    refute html =~ "Beta Client"
    refute html =~ "Overview"
    assert html =~ "Register client"

    # Test provenance filter
    assert {:noreply, socket} =
             Index.handle_params(%{"provenance" => "self_registered"}, "/admin?provenance=self_registered", socket)

    html = rendered_to_string(Index.render(socket.assigns))
    assert html =~ "Gamma Client"
    refute html =~ "Alpha Client"
    refute html =~ "Beta Client"
  end

  test "client detail shows self-registered panel for DCR clients" do
    assert {:ok, alpha_socket} =
             Show.mount(%{"client_id" => "alpha-client"}, %{}, socket_for(:show))
    assert {:noreply, alpha_socket} =
             Show.handle_params(%{"client_id" => "alpha-client"}, "/admin/clients/alpha-client", alpha_socket)
    alpha_html = rendered_to_string(Show.render(alpha_socket.assigns))

    refute alpha_html =~ "Self-registered client (DCR)"

    assert {:ok, gamma_socket} =
             Show.mount(%{"client_id" => "gamma-client"}, %{}, socket_for(:show))
    assert {:noreply, gamma_socket} =
             Show.handle_params(%{"client_id" => "gamma-client"}, "/admin/clients/gamma-client", gamma_socket)
    gamma_html = rendered_to_string(Show.render(gamma_socket.assigns))

    assert gamma_html =~ "Self-registered client (DCR)"
    assert gamma_html =~ "Rotate Registration Access Token (RAT)"
  end

  test "RAT rotation workflow renders plaintext copy-once and explicit clear" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/gamma-client")

    view
    |> element("a", "Rotate Registration Access Token (RAT)")
    |> render_click()

    assert render(view) =~ "Rotate Registration Access Token (RAT)"

    # Reject without confirm
    view
    |> form("form[phx-submit=rotate_rat]", %{})
    |> render_submit()

    assert render(view) =~ "confirmation required"

    # Rotate
    view
    |> form("form[phx-submit=rotate_rat]", %{rotate: %{confirm: "true"}})
    |> render_submit()

    html = render(view)
    assert html =~ "New Registration Access Token"
    assert html =~ "I have copied the token"

    # Explicit clear
    view
    |> element("button", "I have copied the token")
    |> render_click()

    html_cleared = render(view)
    refute html_cleared =~ "New Registration Access Token"
    refute html_cleared =~ "I have copied the token"
  end

  test "client detail shows stored override and effective PAR policy state" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, alpha_socket} =
             Show.mount(%{"client_id" => "alpha-client"}, %{}, socket_for(:show))

    assert {:noreply, alpha_socket} =
             Show.handle_params(
               %{"client_id" => "alpha-client"},
               "/admin/clients/alpha-client",
               alpha_socket
             )

    alpha_html = rendered_to_string(Show.render(alpha_socket.assigns))

    assert alpha_html =~ "Global PAR policy"
    assert alpha_html =~ "Client PAR override"
    assert alpha_html =~ "inherit"
    assert alpha_html =~ "Effective PAR requirement"
    assert alpha_html =~ "Not required"

    assert {:ok, beta_socket} =
             Show.mount(%{"client_id" => "beta-client"}, %{}, socket_for(:show))

    assert {:noreply, beta_socket} =
             Show.handle_params(
               %{"client_id" => "beta-client"},
               "/admin/clients/beta-client",
               beta_socket
             )

    beta_html = rendered_to_string(Show.render(beta_socket.assigns))

    assert beta_html =~ "Global PAR policy"
    assert beta_html =~ "Client PAR override"
    assert beta_html =~ "required"
    assert beta_html =~ "Effective PAR requirement"
    assert beta_html =~ "Required"
  end

  test "saving client PAR override persists change" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/alpha-client")

    view
    |> element("a", "Edit PAR policy")
    |> render_click()

    view
    |> form("form[phx-submit=save_client]", %{
      client: %{mode: "par_policy", par_policy: "required"}
    })
    |> render_submit()

    assert {:ok, client} = Lockspire.Admin.get_client("alpha-client")
    assert client.par_policy == :required
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end
