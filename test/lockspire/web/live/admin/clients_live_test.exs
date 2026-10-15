defmodule Lockspire.Web.Live.Admin.ClientsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.ClientsLive.Index
  alias Lockspire.Web.Live.Admin.ClientsLive.Show
  alias Lockspire.Web.Live.Admin.OverviewLive

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
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(Lockspire.TestRepo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)

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

  test "router exposes overview as the operator entrypoint and keeps client workflows" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin", OverviewLive.Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/overview", OverviewLive.Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients/new", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients/:client_id/par-policy", Show))
    assert Enum.any?(routes, &live_route?(&1, "/admin/clients/:client_id/logout-uris", Show))

    assert Enum.any?(
             routes,
             &live_route?(&1, "/admin/dcr", Lockspire.Web.Live.Admin.DcrLive.Index)
           )

    assert Enum.any?(
             routes,
             &live_route?(&1, "/admin/policies", Lockspire.Web.Live.Admin.PoliciesLive.Index)
           )

    assert Enum.any?(
             routes,
             &live_route?(&1, "/admin/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop)
           )
  end

  test "shared warning status copy does not expose the internal operator role" do
    html =
      render_component(&AdminComponents.status_badge/1, status: :retryable)

    assert html =~ ~s(title="Attention may be needed")
    refute html =~ "Operator"
  end

  test "clients index renders durable client truth and URL-driven filters" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{"q" => "Alpha"}, "/admin?q=Alpha", socket)

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Apps"
    assert html =~ "Alpha Client"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "App registration"
    refute html =~ "Beta Client"
    assert html =~ "Add app"

    # Test provenance filter
    assert {:noreply, socket} =
             Index.handle_params(
               %{"provenance" => "self_registered"},
               "/admin?provenance=self_registered",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))
    assert html =~ "Gamma Client"
    refute html =~ "Alpha Client"
    refute html =~ "Beta Client"
  end

  test "client filter submit keeps the native GET fallback and emits busy copy" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} = Index.handle_params(%{}, "/admin/clients", socket)

    {:noreply, submitted} =
      Index.handle_event(
        "filter_inventory",
        %{"q" => "alpha", "status" => "all", "provenance" => "all"},
        socket
      )

    assert submitted.assigns.clients == socket.assigns.clients

    assert {:live, :patch, %{to: "/admin/clients?page=1&provenance=all&q=alpha&status=all"}} =
             submitted.redirected

    html = rendered_to_string(Index.render(socket.assigns))
    assert html =~ ~s(method="get")
    assert html =~ ~s(action="/admin/clients")
    assert html =~ ~s(phx-submit="filter_inventory")
    assert html =~ ~s(phx-disable-with="Filtering apps…")
  end

  test "client filter submit patches the URL and resets pagination" do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients?page=3")
    assert html =~ ~s(phx-disable-with="Filtering apps…")

    view
    |> form("form[phx-submit=filter_inventory]", %{
      "q" => "alpha",
      "status" => "all",
      "provenance" => "all"
    })
    |> render_submit()

    assert_patch(view, "/admin/clients?page=1&provenance=all&q=alpha&status=all")
    assert render(view) =~ ~s(value="alpha")
    assert render(view) =~ "1 matching app"
  end

  test "clients index links to a focused registration route that preserves normalized filters" do
    assert {:ok, _view, html} =
             live(conn_for_admin(), "/admin/clients?q=Alpha&status=active&provenance=operator")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_label_targets_exist(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)

    assert html =~ "Configure"
    assert html =~ "Apps"
    refute html =~ "Selected client context"
    refute html =~ ~s(id="client-create-form")
    assert html =~ ~s(aria-label="Admin navigation")
    assert html =~ ~s(option value="operator" selected)
    assert html =~ "Added directly"
    assert html =~ "Registered through API"
    assert html =~ "registered by another app through the API"

    assert html =~ "1 matching app"
    assert html =~ "of 3 total apps"
    assert html =~ "Filter apps"
    assert html =~ "Add app"
    refute html =~ "Apply"
    refute html =~ "Clients are the default operator entrypoint"
    refute html =~ "Copy this client secret now"

    assert html =~
             ~s(href="/admin/clients/new?page=1&amp;provenance=operator&amp;q=Alpha&amp;status=active")

    assert {:ok, _registration_view, registration_html} =
             live(
               conn_for_admin(),
               "/admin/clients/new?page=1&provenance=operator&q=Alpha&status=active"
             )

    assert registration_html =~ ~s(<h1>New app</h1>)
    assert registration_html =~ "Add an app that will use this service."
    assert registration_html =~ ~s(id="client-create-form")

    assert registration_html =~
             "Can keep a client secret secure."

    assert registration_html =~ "How the app authenticates"
    assert registration_html =~ "Allowed permissions (OAuth scopes)"
    assert registration_html =~ "Sign-in return URLs"
    assert registration_html =~ "Lockspire sends users back to one of these URLs after sign-in."
    refute registration_html =~ "client_secret_jwt uses"

    assert registration_html =~
             ~s(href="/admin/clients?page=1&amp;provenance=operator&amp;q=Alpha&amp;status=active")

    assert length(Regex.scan(~r/Add app/, registration_html)) == 1
    assert registration_html =~ "Add app"
    refute registration_html =~ "Add app</h2>"
    refute registration_html =~ "Enter this client's name, token endpoint authentication method"
    refute registration_html =~ "Find an app"
    refute registration_html =~ "Selected client context"
  end

  test "registration route keeps normalized inventory context and one-time client-secret handoff" do
    assert {:ok, view, html} =
             live(
               conn_for_admin(),
               "/admin/clients/new?q=Alpha&status=invalid&provenance=self_registered&page=-2"
             )

    assert html =~ ~s(<h1>New app</h1>)
    refute html =~ ~s(option value="active" selected)

    assert html =~
             ~s(href="/admin/clients?page=1&amp;provenance=self_registered&amp;q=Alpha&amp;status=all")

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{
        name: "Capability Proof Client",
        client_type: "confidential",
        token_endpoint_auth_method: "client_secret_basic",
        redirect_uris: "https://capability-proof.example.com/callback",
        allowed_scopes: "email"
      }
    })
    |> render_submit()

    created_html = render(view)

    assert created_html =~ "Copy this client secret now"
    assert created_html =~ "View app details"
    assert created_html =~ "Client secret"
    assert created_html =~ "Copy it now"
    assert created_html =~ "It is shown once, and Lockspire stores only a hash."
    refute created_html =~ "client_secret_hash"

    plaintext_secret = extract_copy_once_value(created_html)

    created_client_id = extract_created_client_id(created_html)
    assert created_html =~ ~s(href="/admin/clients/#{created_client_id}")

    {:ok, _detail_view, durable_detail_html} =
      live(conn_for_admin(), "/admin/clients/#{created_client_id}")

    HtmlAssertions.assert_no_text(durable_detail_html, [
      plaintext_secret,
      "client_secret_hash",
      "registration_access_token_hash",
      "raw request object",
      "verifier material",
      "host tenant policy",
      "developer portal"
    ])

    {:ok, _index_view, durable_index_html} = live(conn_for_admin(), "/admin/clients")
    HtmlAssertions.assert_no_text(durable_index_html, [plaintext_secret, "client_secret_hash"])
  end

  test "client registration reserves primary styling for creation and keeps return navigation secondary" do
    {:ok, _index_view, index_html} = live(conn_for_admin(), "/admin/clients")
    index_doc = HtmlAssertions.document(index_html)

    [create_class] =
      index_doc
      |> LazyHTML.query("a[href='/admin/clients/new?page=1&provenance=all&q=&status=all']")
      |> LazyHTML.attribute("class")

    assert create_class == "lockspire-admin-btn lockspire-admin-btn-primary"

    {:ok, _registration_view, registration_html} =
      live(conn_for_admin(), "/admin/clients/new")

    registration_doc = HtmlAssertions.document(registration_html)

    [back_class] =
      registration_doc
      |> LazyHTML.query("a[href='/admin/clients?page=1&provenance=all&q=&status=all']")
      |> LazyHTML.attribute("class")

    [submit_class] =
      registration_doc
      |> LazyHTML.query("#client-create-form button[type=submit]")
      |> LazyHTML.attribute("class")

    assert back_class == "lockspire-admin-btn lockspire-admin-btn-secondary"
    assert submit_class == "lockspire-admin-btn lockspire-admin-btn-primary"
  end

  test "app creation shows a form error instead of crashing when storage raises" do
    endpoint_config = Application.get_env(:lockspire, Lockspire.Web.Endpoint)

    Application.put_env(
      :lockspire,
      Lockspire.Web.Endpoint,
      # An empty key is checked before any inferred fallback, so sealing fails.
      Keyword.put(endpoint_config, :secret_key_base, "")
    )

    on_exit(fn -> Application.put_env(:lockspire, Lockspire.Web.Endpoint, endpoint_config) end)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/new")

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        html =
          view
          |> form("#client-create-form", %{
            client: %{
              name: "Missing Key App",
              client_type: "confidential",
              token_endpoint_auth_method: "client_secret_basic",
              redirect_uris: "https://missing-key.example.com/callback",
              allowed_scopes: "email"
            }
          })
          |> render_submit()

        assert html =~ "App was not created."
        assert html =~ "Missing Key App"
      end)

    assert log =~ "Lockspire admin could not create an app"
    assert render(view) =~ "App was not created."
  end

  test "rejected client creation retains safe input and associates actionable field errors" do
    submitted_name = "Partner Portal 🚀"
    submitted_redirect = "https://*.partner.example/callback"

    assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/new")
    assert html =~ ~s(id="client-create-form")
    assert html =~ ~s(phx-disable-with="Creating app…")

    view
    |> form("#client-create-form", %{
      client: %{
        name: submitted_name,
        client_type: "confidential",
        token_endpoint_auth_method: "client_secret_basic",
        redirect_uris: submitted_redirect,
        allowed_scopes: "email, profile"
      }
    })
    |> render_submit()

    html = render(view)

    assert html =~ "App was not created. Review the marked fields and try again."
    assert html =~ "App name"
    assert html =~ "How the app authenticates"
    assert html =~ "Permissions this app may request."
    assert html =~ "Sign-in return URLs"
    assert html =~ ~s(value="#{submitted_name}")
    assert html =~ submitted_redirect
    assert html =~ ~s(data-values="email, profile")

    assert html =~
             "Enter a valid URL for users to return to after sign-in."

    assert html =~ ~s(id="client_redirect_uris-error")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(role="alert" tabindex="-1")
    refute html =~ "invalid_redirect_uri"
    refute html =~ "Client created"
    refute html =~ "Copy this client secret now"
  end

  test "created client secret is cleared on acknowledgement and inventory filter change" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/new")

    view
    |> form("#client-create-form", %{
      client: %{
        name: "One-time Secret Client",
        client_type: "confidential",
        token_endpoint_auth_method: "client_secret_basic",
        redirect_uris: "https://one-time.example.com/callback",
        allowed_scopes: "email"
      }
    })
    |> render_submit()

    created_html = render(view)
    secret = extract_copy_once_value(created_html)
    assert created_html =~ secret

    view
    |> element("button[phx-click=hide_created_secret]")
    |> render_click()

    hidden_html = render(view)
    assert hidden_html =~ "Credential hidden. It will not be shown again."
    assert hidden_html =~ "Redacted"
    refute hidden_html =~ secret

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{
        name: "One-time Secret Client Two",
        client_type: "confidential",
        token_endpoint_auth_method: "client_secret_basic",
        redirect_uris: "https://one-time-two.example.com/callback",
        allowed_scopes: "email"
      }
    })
    |> render_submit()

    second_secret = extract_copy_once_value(render(view))
    refute second_secret == secret

    view |> render_patch("/admin/clients?q=One-time%20Secret%20Client")

    filtered_html = render(view)
    refute filtered_html =~ second_secret
    refute filtered_html =~ "Client created"
  end

  test "created client secret appears above the reset registration form" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/new")

    view
    |> form("#client-create-form", %{
      client: %{
        name: "Panel Order Client",
        client_type: "confidential",
        token_endpoint_auth_method: "client_secret_basic",
        redirect_uris: "https://panel-order.example.com/callback",
        allowed_scopes: "email"
      }
    })
    |> render_submit()

    html = render(view)
    {result_at, _} = :binary.match(html, ~s(id="client-created-result"))
    {form_at, _} = :binary.match(html, ~s(id="client-create-form"))
    assert result_at < form_at
  end

  test "app details return to the filtered list the operator came from" do
    {:ok, _view, list_html} = live(conn_for_admin(), "/admin/clients?q=Alpha&status=active")

    assert list_html =~
             ~s(href="/admin/clients/alpha-client?page=1&amp;provenance=all&amp;q=Alpha&amp;status=active")

    {:ok, _view, show_html} =
      live(
        conn_for_admin(),
        "/admin/clients/alpha-client?page=1&provenance=all&q=Alpha&status=active"
      )

    assert show_html =~
             ~s(href="/admin/clients?page=1&amp;provenance=all&amp;q=Alpha&amp;status=active")

    {:ok, _view, unfiltered_html} = live(conn_for_admin(), "/admin/clients")
    assert unfiltered_html =~ ~s(href="/admin/clients/alpha-client")

    {:ok, _view, plain_show_html} = live(conn_for_admin(), "/admin/clients/alpha-client")
    assert plain_show_html =~ ~s(href="/admin/clients")
    refute plain_show_html =~ ~s(href="/admin/clients?)
  end

  test "client IDs with reserved URL characters are encoded in app links" do
    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "odd/id?x#y",
        client_secret_hash: "sha256:odd",
        client_type: :confidential,
        name: "Odd id app",
        redirect_uris: ["https://odd.example.test/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        active: true,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, _view, html} = live(conn_for_admin(), "/admin/clients?q=Odd")
    assert html =~ ~s(href="/admin/clients/odd%2Fid%3Fx%23y?)

    {:ok, _view, show_html} = live(conn_for_admin(), "/admin/clients/odd%2Fid%3Fx%23y")
    assert show_html =~ "Odd id app"
    assert show_html =~ ~s(href="/admin/clients/odd%2Fid%3Fx%23y/edit")
  end

  test "non-string search params are treated as an empty search instead of crashing" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients?q[]=x")
    assert html =~ "of 3 total apps"

    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients?q[a]=b")
    assert html =~ "of 3 total apps"
  end

  test "inventory pagination links reach apps beyond the first page" do
    for n <- 1..9 do
      {:ok, _client} =
        Repository.register_client(%Client{
          client_id: "paged-client-#{n}",
          client_secret_hash: "sha256:paged:#{n}",
          client_type: :confidential,
          name: "Paged app #{n}",
          redirect_uris: ["https://paged.example.test/callback"],
          allowed_scopes: ["email"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: true,
          subject_type: :public,
          active: true,
          created_at: DateTime.utc_now(),
          metadata: %{}
        })
    end

    {:ok, _view, page_one} = live(conn_for_admin(), "/admin/clients")
    assert page_one =~ "12 matching apps"
    assert page_one =~ "Next apps"
    refute page_one =~ "Previous apps"

    assert page_one =~
             ~s(href="/admin/clients?page=2&amp;provenance=all&amp;q=&amp;status=all")

    {:ok, _view, page_two} = live(conn_for_admin(), "/admin/clients?page=2")
    assert page_two =~ "Previous apps"
    refute page_two =~ "Next apps"

    assert page_two =~
             ~s(href="/admin/clients?page=1&amp;provenance=all&amp;q=&amp;status=all")
  end

  test "client inventory distinguishes first-use empty from filtered empty" do
    assert {3, nil} = Lockspire.TestRepo.delete_all(Lockspire.Storage.Ecto.ClientRecord)
    assert {:ok, []} = Repository.list_clients()

    assert {:ok, _view, empty_html} = live(conn_for_admin(), "/admin/clients")
    assert empty_html =~ "No apps yet"
    assert empty_html =~ "Add app"

    assert empty_html =~
             ~s(href="/admin/clients/new?page=1&amp;provenance=all&amp;q=&amp;status=all")

    refute empty_html =~ "No matching apps"

    assert {:ok, _filtered_view, filtered_html} =
             live(conn_for_admin(), "/admin/clients?q=missing")

    assert filtered_html =~ "No matching apps"
    refute filtered_html =~ "No apps yet"
  end

  test "clients index proves empty, disabled, many-count, and long-value Configure states" do
    long_client_id =
      "client-" <>
        String.duplicate("very-long-partner-identifier-", 4) <>
        "terminal"

    {:ok, _disabled_client} =
      Repository.register_client(%Client{
        client_id: long_client_id,
        client_secret_hash: "sha256:disabled:secret:hash",
        client_type: :confidential,
        name: "Disabled " <> String.duplicate("long partner workspace ", 4),
        redirect_uris: [
          "https://partners.example.test/" <>
            String.duplicate("deep/path-segment/", 8) <>
            "callback"
        ],
        allowed_scopes: ["email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        active: false,
        disabled_at: DateTime.utc_now(),
        disabled_by: "test-operator",
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, _view, disabled_html} = live(conn_for_admin(), "/admin/clients?status=disabled")

    assert disabled_html =~ ~s(option value="disabled" selected)
    assert disabled_html =~ "1 matching app"
    assert disabled_html =~ "of 4 total apps"
    assert disabled_html =~ long_client_id
    assert disabled_html =~ "Disabled"
    assert disabled_html =~ "lockspire-admin-resource-list"

    disabled_html
    |> HtmlAssertions.assert_no_duplicate_ids()
    |> HtmlAssertions.assert_label_targets_exist()
    |> HtmlAssertions.assert_links_have_hrefs()
    |> HtmlAssertions.assert_no_generic_cta_text()
    |> HtmlAssertions.assert_no_text([
      "sha256:disabled:secret:hash",
      "client_secret_hash",
      "registration_access_token_hash",
      "Reveal secret",
      "Export credential",
      "force-publish",
      "host tenant policy",
      "developer portal"
    ])

    {:ok, _view, empty_html} = live(conn_for_admin(), "/admin/clients?q=does-not-exist")

    assert empty_html =~ ~s(value="does-not-exist")
    assert empty_html =~ "0 matching apps"
    assert empty_html =~ "of 4 total apps"
    assert empty_html =~ "No matching apps"
    assert empty_html =~ "Change or clear the filters to see other records."

    HtmlAssertions.assert_no_generic_cta_text(empty_html)
  end

  test "client inventory leads with filters and safe detail actions, with truthful empty and failure states" do
    assert {:ok, _view, populated_html} = live(conn_for_admin(), "/admin/clients")

    assert populated_html =~ "View app"
    assert populated_html =~ "3 matching apps"
    assert populated_html =~ "alpha-client"
    assert populated_html =~ "Active"

    HtmlAssertions.assert_has_link(
      populated_html,
      "/admin/clients/new?page=1&provenance=all&q=&status=all"
    )

    assert {:ok, _empty_view, empty_html} =
             live(conn_for_admin(), "/admin/clients?q=does-not-exist&status=active")

    assert empty_html =~ "No matching apps"
    assert empty_html =~ "Change or clear the filters to see other records."
    assert empty_html =~ ~s(value="does-not-exist")
    assert empty_html =~ ~s(value="active" selected)

    prior_repo = Application.get_env(:lockspire, :repo)
    unavailable_repo = Module.concat(__MODULE__, "UnavailableRepo")

    try do
      Application.put_env(:lockspire, :repo, unavailable_repo)

      assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

      assert {:noreply, socket} =
               Index.handle_params(
                 %{"q" => "alpha", "status" => "disabled", "page" => "3"},
                 "/admin/clients?q=alpha&status=disabled&page=3",
                 socket
               )

      error_html = rendered_to_string(Index.render(socket.assigns))

      assert error_html =~ "Could not load apps"
      assert error_html =~ "The app list is not available until this read succeeds."
      assert error_html =~ "Reload this view"

      assert [_, reload_href] =
               Regex.run(~r/href="([^"]*page=3[^"]*)"/, error_html)

      assert reload_href =~ "q=alpha"
      assert reload_href =~ "status=disabled"
      assert error_html =~ ~s(value="alpha")
      assert error_html =~ ~s(value="disabled" selected)
      refute error_html =~ "No matching apps"
    after
      Application.put_env(:lockspire, :repo, prior_repo)
    end
  end

  test "client detail explains API-registered apps and sign-out configuration" do
    assert {:ok, alpha_socket} =
             Show.mount(%{"client_id" => "alpha-client"}, %{}, socket_for(:show))

    assert {:noreply, alpha_socket} =
             Show.handle_params(
               %{"client_id" => "alpha-client"},
               "/admin/clients/alpha-client",
               alpha_socket
             )

    alpha_html = rendered_to_string(Show.render(alpha_socket.assigns))

    refute alpha_html =~ "Self-registered client (DCR)"
    assert alpha_html =~ "Sign-out return URLs"
    assert alpha_html =~ "Server sign-out notification URL"
    assert alpha_html =~ "Delivery is best effort."
    assert alpha_html =~ "Edit sign-out notifications"
    assert alpha_html =~ "Edit sign-out return URLs"

    assert {:ok, gamma_socket} =
             Show.mount(%{"client_id" => "gamma-client"}, %{}, socket_for(:show))

    assert {:noreply, gamma_socket} =
             Show.handle_params(
               %{"client_id" => "gamma-client"},
               "/admin/clients/gamma-client",
               gamma_socket
             )

    gamma_html = rendered_to_string(Show.render(gamma_socket.assigns))

    assert gamma_html =~ "This app was registered through the API."
    assert gamma_html =~ "Rotate app management token"
  end

  test "client registration form uses clear, task-focused language" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/new")

    assert html =~ "Add an app that will use this service."

    refute html =~
             "Enter this client&#39;s name, token endpoint authentication method, callback URI, and allowed scopes."

    assert html =~ "Permissions this app may request."
    assert html =~ "How the app authenticates"
    assert html =~ "Client secret in the request header"
    assert html =~ "Client secret in the request body"
    assert html =~ "Signed client assertion (JWT)"
    assert html =~ "No client secret"
    assert html =~ "Can keep a client secret secure."
    assert html =~ "Cannot keep a client secret secure. Uses PKCE."
    assert html =~ "Sign-in return URLs"
    assert html =~ "Lockspire sends users back to one of these URLs after sign-in."
    assert html =~ ~s(value="client_secret_jwt")
    assert html =~ "Uses the client secret to sign assertions with HS256."
    refute html =~ "direct-client"

    assert {:ok, _edit_view, edit_html} =
             live(conn_for_admin(), "/admin/clients/alpha-client/edit")

    assert edit_html =~ "Edit app settings"
    assert edit_html =~ "App name"
    assert edit_html =~ "Provider default:"
    refute edit_html =~ "Selected setting:"
    refute edit_html =~ "operator-safe metadata"
  end

  test "RAT rotation workflow renders plaintext copy-once and explicit clear" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/gamma-client")

    view
    |> element("a", "Rotate app management token")
    |> render_click()

    rat_prompt_html = render(view)

    assert rat_prompt_html =~ "Rotate app management token"
    assert rat_prompt_html =~ "current token stops working after rotation"
    assert rat_prompt_html =~ "new token is shown once, right after you confirm"
    refute rat_prompt_html =~ "Rotate Registration Access Token (RAT)"

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
    assert html =~ "New app management token"
    assert html =~ "I have copied the token"

    # Explicit clear
    view
    |> element("button", "I have copied the token")
    |> render_click()

    html_cleared = render(view)
    refute html_cleared =~ "New app management token"
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

    assert alpha_html =~ "Authorization requests"
    assert alpha_html =~ "Default: Optional"
    assert alpha_html =~ "This app: Use provider default"
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

    assert beta_html =~ "Authorization requests"
    assert beta_html =~ "Default: Optional"
    assert beta_html =~ "This app: Required"
    assert beta_html =~ "Required"
  end

  test "saving client PAR override persists change" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/alpha-client")

    view
    |> element("a", "Edit authorization request rules")
    |> render_click()

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{mode: "par_policy", par_policy: "required"}
    })
    |> render_submit()

    assert {:ok, client} = Lockspire.Admin.get_client("alpha-client")
    assert client.par_policy == :required
  end

  test "edit client renders a DPoP policy selector with inherit bearer and dpop" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/alpha-client/edit")

    html = render(view)

    assert html =~ "Access token proof"
    assert html =~ "Use provider default"
    assert html =~ "Bearer access tokens"
    assert html =~ "Tokens tied to a key (DPoP)"
  end

  test "saving client DPoP override persists change without affecting PAR workflow" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/alpha-client/edit")

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{mode: "edit", dpop_policy: "dpop", allowed_scopes: "email"}
    })
    |> render_submit()

    assert {:ok, client} = Lockspire.Admin.get_client("alpha-client")
    assert client.dpop_policy == :dpop
    assert client.par_policy == :inherit
  end

  test "saving client DPoP override preserves the existing client name when omitted from params" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/alpha-client/edit")

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{mode: "edit", dpop_policy: "bearer", allowed_scopes: "email"}
    })
    |> render_submit()

    assert {:ok, client} = Lockspire.Admin.get_client("alpha-client")
    assert client.name == "Alpha Client"
    assert client.dpop_policy == :bearer
  end

  test "saving post-logout redirect URIs persists the new list" do
    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/clients/alpha-client/logout-uris")

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{
        mode: "logout_uris",
        post_logout_redirect_uris:
          "https://alpha.example.com/logout\nhttps://alpha.example.com/logout/complete"
      }
    })
    |> render_submit()

    assert {:ok, client} = Lockspire.Admin.get_client("alpha-client")

    assert client.post_logout_redirect_uris == [
             "https://alpha.example.com/logout",
             "https://alpha.example.com/logout/complete"
           ]
  end

  test "saving dedicated logout propagation settings persists backchannel and frontchannel fields separately from post-logout redirects" do
    backchannel_logout_uri =
      "https://alpha.example.com/" <>
        String.duplicate("backchannel/logout/path/", 6) <>
        "durable-delivery"

    frontchannel_logout_uri =
      "https://alpha.example.com/" <>
        String.duplicate("frontchannel/logout/path/", 6) <>
        "browser-cleanup"

    assert {:ok, view, _html} =
             live(
               conn_for_admin(),
               "/admin/clients/alpha-client/edit?workflow=logout-propagation"
             )

    view
    |> form(".lockspire-admin-form-shell form", %{
      client: %{
        mode: "logout_propagation",
        backchannel_logout_uri: backchannel_logout_uri,
        backchannel_logout_session_required: "true",
        frontchannel_logout_uri: frontchannel_logout_uri,
        frontchannel_logout_session_required: "true"
      }
    })
    |> render_submit()

    assert {:ok, client} = Lockspire.Admin.get_client("alpha-client")
    assert client.backchannel_logout_uri == backchannel_logout_uri
    assert client.backchannel_logout_session_required == true
    assert client.frontchannel_logout_uri == frontchannel_logout_uri
    assert client.frontchannel_logout_session_required == true
    assert client.post_logout_redirect_uris == []

    html = render(view)

    assert html =~ backchannel_logout_uri
    assert html =~ frontchannel_logout_uri
    assert html =~ "Server sign-out notification URL"
    assert html =~ "Browser sign-out notification URL"
    assert html =~ "Save notification settings"
    assert html =~ "These URLs tell Lockspire where this app receives sign-out notifications."
    assert html =~ "Server notifications are stored and retried."
    assert html =~ "Browser notifications may be blocked"

    HtmlAssertions.assert_no_generic_cta_text(html)

    HtmlAssertions.assert_no_text(html, [
      "post_logout_redirect_uris: #{backchannel_logout_uri}",
      "Reveal secret",
      "Export credential",
      "host tenant policy",
      "developer portal"
    ])

    assert html =~ ~s(label for="client_backchannel_logout_uri")
    assert html =~ ~s(label for="client_frontchannel_logout_uri")
  end

  defp extract_created_client_id(html) do
    [_, client_id] = Regex.run(~r/Client ID:\s*<code[^>]*>([^<]+)<\/code>/, html)
    client_id
  end

  defp extract_copy_once_value(html) do
    [_, value] =
      Regex.run(
        ~r/<section class="[^"]*lockspire-admin-copy-once-secret[^"]*".*?<code[^>]*>([^<]+)<\/code>/s,
        html
      )

    value
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
