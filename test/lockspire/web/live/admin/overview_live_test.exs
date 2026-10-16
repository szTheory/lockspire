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

    {:ok, _approved_auth} =
      Repository.put_device_authorization(%DeviceAuthorization{
        device_code_hash: "overview-approved-device",
        user_code_hash: "overview-approved-user-code",
        verification_handle: "overview-approved-device-handle",
        client_id: "overview-approved-client",
        status: :approved,
        subject_id: "overview-approved-account",
        approved_at: now,
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

    %LogoutDeliveryRecord{}
    |> LogoutDeliveryRecord.changeset(%LogoutDelivery{
      delivery_id: "overview-succeeded-logout-delivery",
      logout_event_id: logout_event.id,
      client_id: "overview-succeeded-client",
      channel: :backchannel,
      target_uri: "https://example.com/succeeded-backchannel",
      status: :succeeded,
      attempt_count: 1,
      delivered_at: now
    })
    |> Lockspire.TestRepo.insert!()

    :ok
  end

  test "router exposes source-derived overview routes" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/overview", Index))
  end

  @tag :overview_summary_copy
  test "overview uses one title and concise, decision-focused copy" do
    assert {:ok, view, html} = live(conn_for_admin(), "/admin")

    assert html =~ "<h1>Overview</h1>"
    refute html =~ "<h2>Overview</h2>"
    refute html =~ "See what needs review and open the related records."
    assert html =~ "Security events"
    assert html =~ "Sign-out problems"
    assert has_element?(view, "button[aria-describedby='refresh-token-reuse-help']", "")

    assert has_element?(
             view,
             "#refresh-token-reuse-help[role='tooltip']",
             "Lockspire revoked every token"
           )

    assert has_element?(view, "button[aria-describedby='logout-delivery-help']", "")

    assert has_element?(
             view,
             "#logout-delivery-help[role='tooltip']",
             "Failed notices may be retried"
           )

    refute has_element?(
             view,
             "a[href='/admin/tokens?status=reuse_detected']",
             "A refresh token was presented"
           )

    refute has_element?(
             view,
             "a[href='/admin/logouts?status=needs_review']",
             "Failed notices may be retried"
           )

    assert has_element?(
             view,
             ".lockspire-admin-overview-review-row:has(a[href='/admin/tokens?status=reuse_detected']) small",
             "Related tokens revoked"
           )

    assert has_element?(
             view,
             ".lockspire-admin-overview-review-row:has(a[href='/admin/logouts?status=needs_review']) small",
             "Sign-out notices failed or were discarded"
           )

    # The info trigger sits beside the row label, outside the link.
    assert has_element?(
             view,
             ".lockspire-admin-overview-review-label button[aria-describedby='logout-delivery-help']"
           )

    refute has_element?(view, "a button[aria-describedby='logout-delivery-help']")

    assert html =~ "Refresh tokens used more than once"
    assert html =~ "App sign-out notices needing review"

    assert rendered_text(html) =~ "Lockspire revoked every token in its family."
    assert rendered_text(html) =~ "it does not prove theft"
    assert rendered_text(html) =~ "not just unresolved cases"

    assert rendered_text(html) =~
             "Failed notices may be retried; discarded notices will not be sent again."

    refute html =~ "Provider overview"
    refute html =~ "Review client registrations, security policy, signing keys"
    refute html =~ "Measured from"
    refute html =~ "self-registered client"
    refute html =~ "was compromised"
    refute html =~ "session ended"
    refute html =~ "Security posture"
    refute html =~ "Key readiness"
    refute html =~ "Support queue"
    refute html =~ "Live operations"

    assert length(Regex.scan(~r/Refresh tokens used more than once/, html)) == 1
    assert length(Regex.scan(~r/App sign-out notices needing review/, html)) == 1

    for href <- [
          "/admin/tokens?status=reuse_detected",
          "/admin/logouts?status=needs_review"
        ] do
      HtmlAssertions.assert_has_link(html, href)
    end
  end

  test "page contract rejects pages without exactly one h1" do
    assert_raise ExUnit.AssertionError, ~r/found 0/, fn ->
      HtmlAssertions.assert_page_contract!("<main><p>none</p></main>")
    end

    assert_raise ExUnit.AssertionError, ~r/found 2/, fn ->
      HtmlAssertions.assert_page_contract!("<h1>One</h1><h1>Two</h1>")
    end

    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_page_contract!("<h1>One</h1>", labels: :required)
    end

    assert "<h1>One</h1>" == HtmlAssertions.assert_page_contract!("<h1>One</h1>")
  end

  test "overview renders task-centered status and journey links at both entry routes" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin")
    assert {:ok, _overview_view, overview_html} = live(conn_for_admin(), "/admin/overview")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_page_contract!(html)
    HtmlAssertions.assert_page_contract!(overview_html)

    assert html =~ "<h1>Overview</h1>"
    assert overview_html =~ "<h1>Overview</h1>"
    refute html =~ "<h2>Overview</h2>"
    refute overview_html =~ "<h2>Overview</h2>"
    refute html =~ "See what needs review and open the related records."
    refute html =~ "Provider overview"
    refute overview_html =~ "Provider overview"

    refute html =~ "Operator cockpit"
    refute overview_html =~ "Operator cockpit"
    assert html =~ "Security events"
    assert html =~ "Sign-out problems"
    assert html =~ "Waiting for users"
    assert html =~ "Apps and access"
    refute html =~ "Provider defaults"
    assert html =~ "Active token-signing key"
    assert html =~ "Refresh tokens used more than once"
    assert html =~ "App sign-out notices needing review"
    refute html =~ "Active app setup token"
    assert html =~ "/admin/dcr"
    refute html =~ "Measured from"
    refute html =~ "self-registered client"
    refute html =~ "reuse incident"
    refute html =~ "logout failure"

    for href <- [
          "/admin/clients",
          "/admin/policies",
          "/admin/keys",
          "/admin/tokens?status=reuse_detected",
          "/admin/consents?status=active",
          "/admin/logouts?status=needs_review",
          "/admin/interactions?status=pending",
          "/admin/device_authorizations?status=pending",
          "/admin/dcr"
        ] do
      HtmlAssertions.assert_has_link(html, href)
    end

    assert [_, "1"] =
             Regex.run(
               ~r{<a href="/admin/interactions\?status=pending">\s*<span>Sign-in or consent request</span>\s*<strong>(\d+)</strong>},
               html
             )

    assert {:ok, _interactions_view, interactions_html} =
             live(conn_for_admin(), "/admin/interactions?status=pending")

    assert interactions_html =~ "1 request waiting for sign-in or consent"
    assert interactions_html =~ Lockspire.Redaction.handle(:interaction, "overview-interaction")
    refute interactions_html =~ "overview-interaction"
    refute interactions_html =~ "Sign-in request queue"
    refute interactions_html =~ "Active interactions"

    assert [_, "1"] =
             Regex.run(
               ~r{<a href="/admin/device_authorizations\?status=pending">\s*<span>Device sign-in waiting for approval</span>\s*<strong>(\d+)</strong>},
               html
             )

    assert {:ok, _devices_view, devices_html} =
             live(conn_for_admin(), "/admin/device_authorizations?status=pending")

    device_text = rendered_text(devices_html)
    assert device_text =~ "overview-client"
    refute device_text =~ "overview-approved-client"

    assert [_, "1"] =
             Regex.run(
               ~r{<a href="/admin/logouts\?status=needs_review">App sign-out notices needing review</a>.*?</span>\s*<strong>(\d+)</strong>}s,
               html
             )

    assert {:ok, _logouts_view, logouts_html} =
             live(conn_for_admin(), "/admin/logouts?status=needs_review")

    logout_text = rendered_text(logouts_html)
    assert logout_text =~ "overview-client"
    refute logout_text =~ "overview-succeeded-client"

    HtmlAssertions.assert_no_text(html, forbidden_secret_samples() ++ backend_leak_samples())

    HtmlAssertions.assert_no_text(html, [
      "Rotate client secret",
      "Rotate registration access token",
      "Revoke token",
      "Revoke token family",
      "Disable app",
      "Enable app",
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

  @tag :overview_read_states
  test "overview starts in loading state and keeps each failed source independent" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    loading_html = rendered_to_string(Index.render(socket.assigns))
    loading_text = rendered_text(loading_html)

    assert loading_text =~ "Overview"
    assert loading_text =~ "Loading app records"
    assert loading_text =~ "Loading signing keys"
    refute loading_text =~ "Loading security settings"
    refute Regex.match?(~r/summary-value\">\s*\d+/, loading_html)
    refute loading_text =~ "No matching"

    sources = [
      {:clients, "Could not load app records. The current results are unavailable.",
       "/admin/clients"},
      {:tokens, "Could not load refresh token records. The current results are unavailable.",
       "/admin/tokens?status=reuse_detected"},
      {:consents, "Could not load consent grants. The current results are unavailable.",
       "/admin/consents?status=active"},
      {:keys, "Could not load signing keys. The current results are unavailable.", "/admin/keys"},
      {:interactions, "Could not load sign-in requests. The current results are unavailable.",
       "/admin/interactions?status=pending"},
      {:devices,
       "Could not load device authorization requests. The current results are unavailable.",
       "/admin/device_authorizations?status=pending"},
      {:logouts, "Could not load app sign-out notices. The current results are unavailable.",
       "/admin/logouts?status=needs_review"}
    ]

    for {source, unavailable_copy, pivot} <- sources do
      with_read_override({:fail, source}, fn ->
        failed_html = loaded_overview_html()
        failed_text = rendered_text(failed_html)

        assert failed_text =~ "Unavailable"
        assert failed_text =~ unavailable_copy
        assert failed_text =~ "Security events"
        assert failed_text =~ "Apps and access"
        HtmlAssertions.assert_has_link(failed_html, pivot)

        if source != :clients do
          assert failed_text =~ "Registered app 1"
        end
      end)
    end
  end

  test "overview counts use accurate zero, one, and many copy" do
    with_read_override(:empty_clients, fn ->
      text = loaded_overview_html() |> rendered_text()
      assert text =~ "Registered apps 0"
      refute text =~ "Measured from"
    end)

    one_text = loaded_overview_html() |> rendered_text()
    assert one_text =~ "Registered app 1"
    refute one_text =~ "self-registered"

    register_overview_client("overview-client-two", :self_registered)
    many_text = loaded_overview_html() |> rendered_text()
    assert many_text =~ "Registered apps 2"
    refute many_text =~ "self-registered"
  end

  test "overview leaves detailed configuration on its destination pages" do
    for source <- [:policy, :iats] do
      with_read_override({:fail, source}, fn ->
        text = loaded_overview_html() |> rendered_text()
        refute text =~ "Unavailable"
        refute text =~ "Provider defaults"
        refute text =~ "Request step"
        refute text =~ "Standard OpenID Connect"
        refute text =~ "Active app setup token"
        assert text =~ "Registered app 1"
      end)
    end
  end

  test "overview active signing count excludes encryption keys" do
    now = DateTime.utc_now()

    assert {:ok, _} =
             Repository.publish_key(%SigningKey{
               kid: "overview-encryption-key",
               kty: :RSA,
               alg: "RSA-OAEP-256",
               use: :enc,
               public_jwk: %{"kty" => "RSA", "n" => "n", "e" => "AQAB"},
               private_jwk_encrypted: <<1>>,
               status: :active,
               published_at: now,
               activated_at: now
             })

    assert {:ok, view, _} = live(conn_for_admin(), "/admin")
    assert has_element?(view, "a[href='/admin/keys']", "Active token-signing key")

    assert has_element?(
             view,
             ".lockspire-admin-overview-review-row:has(a[href='/admin/keys']) > strong",
             "1"
           )

    assert has_element?(view, "#signing-key-help", "verify that a token came from your server")
  end

  test "expired pending records stay in inventories but not the waiting overview or pivots" do
    now = DateTime.utc_now()

    assert {:ok, _} =
             Repository.put_interaction(%Interaction{
               interaction_id: "overview-stale-interaction",
               client_id: "overview-client",
               return_to: "https://example.com/return",
               status: :pending_login,
               expires_at: DateTime.add(now, -60, :second)
             })

    assert {:ok, _} =
             Repository.put_device_authorization(%DeviceAuthorization{
               device_code_hash: "overview-stale-device",
               user_code_hash: "overview-stale-code",
               verification_handle: "overview-stale-handle",
               client_id: "overview-stale-client",
               status: :pending,
               effective_poll_interval_seconds: 5,
               next_poll_allowed_at: now,
               expires_at: DateTime.add(now, -60, :second)
             })

    assert {:ok, view, _} = live(conn_for_admin(), "/admin")
    assert has_element?(view, "a[href='/admin/interactions?status=pending'] strong", "1")
    assert has_element?(view, "a[href='/admin/device_authorizations?status=pending'] strong", "1")

    assert {:ok, _, pending_interactions} =
             live(conn_for_admin(), "/admin/interactions?status=pending")

    assert pending_interactions =~
             Lockspire.Redaction.handle(:interaction, "overview-interaction")

    refute pending_interactions =~ "overview-interaction"

    refute pending_interactions =~
             Lockspire.Redaction.handle(:interaction, "overview-stale-interaction")

    assert {:ok, _, all_interactions} = live(conn_for_admin(), "/admin/interactions")

    assert all_interactions =~
             Lockspire.Redaction.handle(:interaction, "overview-stale-interaction")

    refute all_interactions =~ "overview-stale-interaction"
    assert all_interactions =~ "Expired sign-in request"

    assert summary_stat(all_interactions, "Waiting for sign-in") +
             summary_stat(all_interactions, "Waiting for consent") == 1

    assert {:ok, _, pending_devices} =
             live(conn_for_admin(), "/admin/device_authorizations?status=pending")

    refute pending_devices =~ "overview-stale-client"
    assert {:ok, _, all_devices} = live(conn_for_admin(), "/admin/device_authorizations")
    assert all_devices =~ "overview-stale-client"
    assert all_devices =~ "Expired before completion"
    assert summary_stat(all_devices, "Pending") == 1
  end

  defp summary_stat(html, label) do
    [_, value] =
      Regex.run(
        ~r/lockspire-admin-summary-value">(\d+)<\/span>\s*<span class="lockspire-admin-summary-label">#{label}</,
        html
      )

    String.to_integer(value)
  end

  test "security and DCR landing pages orient related workflows" do
    assert {:ok, _security_view, security_html} = live(conn_for_admin(), "/admin/policies")

    assert security_html =~ "Security settings"
    assert security_html =~ "App self-registration"
    assert security_html =~ "/admin/policies/dcr"

    assert {:ok, _dcr_view, dcr_html} = live(conn_for_admin(), "/admin/dcr")

    assert dcr_html =~ "App registration"
    assert dcr_html =~ "Apps registered by their teams"
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
