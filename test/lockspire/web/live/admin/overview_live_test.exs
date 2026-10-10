defmodule Lockspire.Web.Live.Admin.OverviewLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.OverviewLive.Index

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
    now = DateTime.utc_now()

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "overview-client",
        client_type: :confidential,
        name: "Overview Client",
        provenance: :self_registered,
        par_policy: :required,
        dpop_policy: :dpop,
        security_profile: :fapi_2_0_security
      })

    {:ok, _consent} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "overview-account",
        client_id: "overview-client",
        scopes: ["openid"],
        granted_at: now
      })

    {:ok, _token} =
      Repository.store_token(%Token{
        token_hash: "overview-token",
        token_type: :refresh_token,
        client_id: "overview-client",
        account_id: "overview-account",
        reuse_detected_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: "overview-interaction",
        client_id: "overview-client",
        return_to: "https://example.com/return",
        status: :pending_consent,
        expires_at: DateTime.add(now, 600, :second)
      })

    {:ok, _auth} =
      Repository.put_device_authorization(%DeviceAuthorization{
        device_code_hash: "overview-device",
        user_code_hash: "overview-user-code",
        verification_handle: "overview-device-handle",
        client_id: "overview-client",
        status: :pending,
        effective_poll_interval_seconds: 5,
        next_poll_allowed_at: now,
        expires_at: DateTime.add(now, 600, :second)
      })

    {:ok, _iat} =
      Repository.save_initial_access_token(%InitialAccessToken{
        token_hash: "overview-iat",
        expires_at: DateTime.add(now, 3600, :second),
        created_by: "test"
      })

    {:ok, _key} =
      Repository.publish_key(%SigningKey{
        kid: "overview-key",
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk: %{"kty" => "RSA", "n" => "n", "e" => "AQAB"},
        private_jwk_encrypted: <<1>>,
        status: :active,
        published_at: now,
        activated_at: now
      })

    {:ok, logout_event} =
      %LogoutEventRecord{}
      |> LogoutEventRecord.changeset(%LogoutEvent{
        event_id: "overview-logout",
        completed_at: now
      })
      |> Lockspire.TestRepo.insert()
      |> case do
        {:ok, record} -> {:ok, LogoutEventRecord.to_domain(record)}
        other -> other
      end

    %LogoutDeliveryRecord{}
    |> LogoutDeliveryRecord.changeset(%LogoutDelivery{
      delivery_id: "overview-logout-delivery",
      logout_event_id: logout_event.id,
      client_id: "overview-client",
      channel: :backchannel,
      target_uri: "https://example.com/backchannel",
      status: :retryable,
      attempt_count: 2
    })
    |> Lockspire.TestRepo.insert!()

    :ok
  end

  test "router exposes source-derived overview routes" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/overview", Index))
  end

  test "overview renders task-centered status and journey links at both entry routes" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin")
    assert {:ok, _overview_view, overview_html} = live(conn_for_admin(), "/admin/overview")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)

    assert html =~ "Provider overview"
    assert overview_html =~ "Provider overview"

    assert html =~
             "Review client registrations, security policy, signing keys, and current authorization activity."

    refute html =~ "Operator cockpit"
    refute overview_html =~ "Operator cockpit"
    assert html =~ "Security posture"
    assert html =~ "Key readiness"
    assert html =~ "Support queue"
    assert html =~ "Live operations"
    assert html =~ "Refresh reuse incidents"
    assert html =~ "Active initial access tokens"
    assert html =~ "/admin/dcr"

    for href <- [
          "/admin/clients",
          "/admin/policies",
          "/admin/keys",
          "/admin/tokens?status=reuse_detected",
          "/admin/consents?status=active",
          "/admin/logouts",
          "/admin/interactions",
          "/admin/device_authorizations",
          "/admin/dcr"
        ] do
      HtmlAssertions.assert_has_link(html, href)
    end

    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())

    HtmlAssertions.assert_no_text(html, [
      "Rotate client secret",
      "Rotate registration access token",
      "Revoke token",
      "Revoke token family",
      "Disable client",
      "Enable client",
      "Retry logout delivery",
      "Discard logout delivery",
      "Approve DCR request",
      "Deny DCR request",
      "host tenant policy",
      "developer portal",
      "public theming",
      "AI judge",
      "browser gate"
    ])
  end

  test "overview starts in loading state and keeps each failed source independent" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    loading_html = rendered_to_string(Index.render(socket.assigns))
    loading_text = rendered_text(loading_html)

    assert loading_text =~ "Provider overview"
    assert loading_text =~ "Loading client inventory"
    assert loading_text =~ "Loading server policy"
    refute Regex.match?(~r/summary-value\">\s*\d+/, loading_html)
    refute loading_text =~ "No matching"

    sources = [
      {:clients, "Client inventory unavailable", "/admin/clients"},
      {:tokens, "Token inventory unavailable", "/admin/tokens?status=reuse_detected"},
      {:consents, "Consent inventory unavailable", "/admin/consents?status=active"},
      {:keys, "Signing-key inventory unavailable", "/admin/keys"},
      {:iats, "Initial access token inventory unavailable", "/admin/dcr"},
      {:interactions, "Interaction inventory unavailable", "/admin/interactions"},
      {:devices, "Device authorization inventory unavailable", "/admin/device_authorizations"},
      {:logouts, "Logout delivery inventory unavailable", "/admin/logouts"},
      {:policy, "Security policy unavailable", "/admin/policies"}
    ]

    for {source, unavailable_copy, pivot} <- sources do
      with_read_override({:fail, source}, fn ->
        failed_html = loaded_overview_html()
        failed_text = rendered_text(failed_html)

        assert failed_text =~ unavailable_copy
        assert failed_text =~ "Security posture"
        assert failed_text =~ "Live operations"
        HtmlAssertions.assert_has_link(failed_html, pivot)

        if source != :clients do
          assert failed_text =~ "1 client"
        end
      end)
    end
  end

  test "overview counts use measured zero, one, and many copy" do
    with_read_override(:empty_clients, fn ->
      text = loaded_overview_html() |> rendered_text()
      assert text =~ "0 clients"
      assert text =~ "Measured from client inventory"
    end)

    one_text = loaded_overview_html() |> rendered_text()
    assert one_text =~ "1 client"
    assert one_text =~ "1 self-registered client"

    register_overview_client("overview-client-two", :self_registered)
    many_text = loaded_overview_html() |> rendered_text()
    assert many_text =~ "2 clients"
    assert many_text =~ "2 self-registered clients"
  end

  test "overview distinguishes configured policy defaults, stored policy, and read failure" do
    default_text = loaded_overview_html() |> rendered_text()
    assert default_text =~ "Configured defaults"
    assert default_text =~ "optional"
    assert default_text =~ "bearer"
    refute default_text =~ "Stored server policy"

    assert {:ok, _stored_policy} =
             Repository.put_server_policy(%ServerPolicy{
               par_policy: :required,
               dpop_policy: :dpop
             })

    stored_text = loaded_overview_html() |> rendered_text()
    assert stored_text =~ "Stored server policy"
    assert stored_text =~ "required"
    assert stored_text =~ "dpop"
    refute stored_text =~ "Configured defaults"

    with_read_override({:fail, :policy}, fn ->
      failed_text = loaded_overview_html() |> rendered_text()
      assert failed_text =~ "Security policy unavailable"
      assert failed_text =~ "1 client"
      refute failed_text =~ "Configured defaults"
      refute failed_text =~ "Stored server policy"
      refute failed_text =~ "optional"
    end)
  end

  test "security and DCR landing pages orient related workflows" do
    assert {:ok, _security_view, security_html} = live(conn_for_admin(), "/admin/policies")

    assert security_html =~ "Policy posture"
    assert security_html =~ "Dynamic Client Registration"
    assert security_html =~ "/admin/policies/dcr"

    assert {:ok, _dcr_view, dcr_html} = live(conn_for_admin(), "/admin/dcr")

    assert dcr_html =~ "DCR onboarding"
    assert dcr_html =~ "Create initial access token"
    assert dcr_html =~ "Review self-registered clients"
    assert dcr_html =~ "Overview Client"
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp loaded_overview_html do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/admin", socket)
    rendered_to_string(Index.render(socket.assigns))
  end

  defp with_read_override(mode, fun) do
    previous_repo = Application.get_env(:lockspire, :repo)
    previous_mode = Application.get_env(:lockspire, :overview_live_test_mode)

    try do
      Application.put_env(:lockspire, :overview_live_test_mode, mode)
      Application.put_env(:lockspire, :repo, Lockspire.Web.Live.Admin.OverviewLiveTest.ReadRepo)
      fun.()
    after
      Application.put_env(:lockspire, :repo, previous_repo)
      Application.put_env(:lockspire, :overview_live_test_mode, previous_mode)
    end
  end

  defp register_overview_client(client_id, provenance) do
    assert {:ok, _client} =
             Repository.register_client(%Client{
               client_id: client_id,
               client_type: :confidential,
               name: "#{client_id} Name",
               provenance: provenance
             })
  end

  defp rendered_text(html) do
    html
    |> String.replace(~r/<style\b[^>]*>.*?<\/style>/s, " ")
    |> String.replace(~r/<script\b[^>]*>.*?<\/script>/s, " ")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
  end

  defp forbidden_secret_samples do
    [
      "real-client-secret",
      "production-secret",
      "prod-access-token",
      "prod-refresh-token",
      "sk_live_",
      "pk_live_",
      "eyJhbGci",
      "BEGIN PRIVATE KEY",
      "authorization_code=",
      "code_verifier="
    ]
  end

  defp backend_leak_samples do
    [
      "Postgrex",
      "Ecto.Changeset",
      "Lockspire.Storage",
      "stacktrace",
      "constraint violation",
      "private_jwk_encrypted"
    ]
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end
end

defmodule Lockspire.Web.Live.Admin.OverviewLiveTest.ReadRepo do
  @moduledoc false

  def one(query, options \\ []) do
    maybe_fail(query)
    Lockspire.TestRepo.one(query, options)
  end

  def all(query, options \\ []) do
    case {Application.get_env(:lockspire, :overview_live_test_mode), source(query)} do
      {:empty_clients, Lockspire.Storage.Ecto.ClientRecord} ->
        []

      _other ->
        maybe_fail(query)
        Lockspire.TestRepo.all(query, options)
    end
  end

  defp maybe_fail(query) do
    case Application.get_env(:lockspire, :overview_live_test_mode) do
      {:fail, source_name} ->
        if source(query) == source_module(source_name),
          do: raise("synthetic overview read failure")

      _other ->
        :ok
    end
  end

  defp source(query) do
    query
    |> Ecto.Queryable.to_query()
    |> Map.fetch!(:from)
    |> Map.fetch!(:source)
    |> case do
      {_table, schema} -> schema
      value -> value
    end
  end

  defp source_module(:clients), do: Lockspire.Storage.Ecto.ClientRecord
  defp source_module(:tokens), do: Lockspire.Storage.Ecto.TokenRecord
  defp source_module(:consents), do: Lockspire.Storage.Ecto.ConsentGrantRecord
  defp source_module(:keys), do: Lockspire.Storage.Ecto.SigningKeyRecord

  defp source_module(:iats),
    do: Lockspire.Storage.Ecto.InitialAccessTokenRecord

  defp source_module(:interactions), do: Lockspire.Storage.Ecto.InteractionRecord

  defp source_module(:devices),
    do: Lockspire.Storage.Ecto.DeviceAuthorizationRecord

  defp source_module(:logouts), do: Lockspire.Storage.Ecto.LogoutDeliveryRecord
  defp source_module(:policy), do: Lockspire.Storage.Ecto.ServerPolicyRecord
end
