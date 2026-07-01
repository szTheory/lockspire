defmodule Lockspire.Web.Live.Admin.ConsentsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.ConsentsLive.Index
  alias Lockspire.Web.Live.Admin.ConsentsLive.Show

  @unsupported_support_controls [
    "Reveal secret",
    "Reveal token",
    "Recover consent",
    "Export consent",
    "Edit grant",
    "Bulk revoke",
    "Copy secret",
    "Terminate host session",
    "Revoke token",
    "Run worker"
  ]

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    long_scope = "urn:lockspire:consent:scope:#{String.duplicate("wrapped-", 12)}read"

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "consent-ui-client",
        client_secret_hash: "sha256:consent-ui:hash",
        client_type: :confidential,
        name: "Consent UI Client",
        redirect_uris: ["https://consent-ui.example.com/callback"],
        allowed_scopes: ["openid", "email", long_scope],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, grant} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "account-consent-ui",
        client_id: "consent-ui-client",
        scopes: ["openid", "email", long_scope],
        granted_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{grant: grant, long_scope: long_scope}
  end

  test "router exposes admin consent routes" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/consents", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/consents/:id", Show))
  end

  test "consent index renders support grant investigation filters and rows without secrets" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{
                 "account" => "account-consent-ui",
                 "client" => "consent-ui-client",
                 "status" => "active"
               },
               "/lockspire/admin/consents?account=account-consent-ui&client=consent-ui-client&status=active",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))
    decision_summary = fragment_html(html, ".lockspire-admin-decision-summary")
    rows = fragment_html(html, ".lockspire-admin-dense-resource-row")

    assert html =~ "Support"
    assert html =~ "Consent grant investigation"
    assert html =~ "Selected account: account_"
    assert html =~ "Selected client: client_"
    assert html =~ "Selected status: active"
    assert html =~ "Filter consent grants"
    assert html =~ "Review stored grant"
    assert html =~ "lockspire-admin-decision-summary"
    assert html =~ "lockspire-admin-dense-resource-row"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Consent UI Client"
    assert html =~ "Scopes"
    assert html =~ "openid, email"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "DCR"

    assert decision_summary =~ "Selected filters"
    assert decision_summary =~ "Grant status"
    assert decision_summary =~ "Scope context"
    assert decision_summary =~ "Smallest safe action"
    assert decision_summary =~ "account_"
    assert decision_summary =~ "client_"
    refute decision_summary =~ "account-consent-ui"
    refute decision_summary =~ "consent-ui-client"

    assert html_index(html, ~s(<dl class="lockspire-admin-decision-summary)) <
             html_index(
               html,
               ~s(<form method="get" action="/lockspire/admin/consents" class="lockspire-admin-filter-bar)
             )

    assert rows =~ "Review stored grant"
    assert rows =~ "account_"
    assert rows =~ "client_"
    assert rows =~ "openid, email"
    refute rows =~ "account-consent-ui"
    refute rows =~ "consent-ui-client"

    refute html =~ "sha256:consent-ui:hash"
    refute html =~ "client_secret"
    refute html =~ "refresh_token"
    refute html =~ "user_code"
    refute html =~ "verifier"

    assert {:noreply, empty_socket} =
             Index.handle_params(
               %{"account" => "missing-account-consent-ui"},
               "/lockspire/admin/consents?account=missing-account-consent-ui",
               socket
             )

    assert rendered_to_string(Index.render(empty_socket.assigns)) =~
             "No investigation results match these filters"
  end

  test "consent detail renders support-grade detail and guarded revoke action", %{
    grant: grant,
    long_scope: long_scope
  } do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(grant.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(grant.id)},
               "/lockspire/admin/consents/#{grant.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_has_link(html, "/lockspire/admin/consents")

    HtmlAssertions.assert_no_text(html, [
      "account-consent-ui",
      "consent-ui-client",
      "sha256:consent-ui:hash",
      "client_secret",
      "refresh_token",
      "token_hash",
      "verifier",
      "authorization_code",
      "user_code"
    ])

    assert html =~ "Support"
    assert html =~ "Stored grant decision"
    assert html =~ "Durable consent truth"
    assert html =~ "lockspire-admin-decision-summary"
    assert html =~ "Durable grant identity and current state"
    assert html =~ "Scope context"
    assert html =~ "Review stored grant"
    assert html =~ "Revoke consent grant"
    assert html =~ "lockspire-admin-entity-header"
    assert html =~ "lockspire-admin-pane"
    assert html =~ ~s(phx-submit="revoke_consent")
    assert html =~ "remembered grant will no longer"
    assert html =~ "future remembered-consent reuse"
    assert html =~ "openid, email"
    assert html =~ long_scope
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "account_"
    assert html =~ "client_"
    refute html =~ "account-consent-ui"
    refute html =~ "consent-ui-client"
    refute html =~ "sha256:consent-ui:hash"

    decision_summary = fragment_html(html, ".lockspire-admin-decision-summary")

    assert decision_summary =~ "Grant status"
    assert decision_summary =~ "Scope context"
    assert decision_summary =~ "Client/account pivot"
    assert decision_summary =~ "Revocation consequence"
    assert decision_summary =~ "account_"
    assert decision_summary =~ "client_"
    assert decision_summary =~ "future remembered-consent reuse"
    refute decision_summary =~ "account-consent-ui"
    refute decision_summary =~ "consent-ui-client"

    assert html_index(html, ~s(<dl class="lockspire-admin-decision-summary)) <
             html_index(html, "Durable grant identity and current state")

    assert {:noreply, missing_confirm_socket} = Show.handle_event("revoke_consent", %{}, socket)

    assert missing_confirm_socket.assigns.revoke_error ==
             "Select the confirmation checkbox to revoke this consent grant."

    missing_confirm_html = rendered_to_string(Show.render(missing_confirm_socket.assigns))

    assert missing_confirm_html =~
             "Select the confirmation checkbox to revoke this consent grant."

    assert missing_confirm_html =~ "lockspire-admin-errors"

    failed_revoke_socket = put_in(socket.assigns.consent_id, -1)

    assert {:noreply, failed_revoke_socket} =
             Show.handle_event(
               "revoke_consent",
               %{"revoke" => %{"confirm" => "true"}},
               failed_revoke_socket
             )

    assert failed_revoke_socket.assigns.revoke_error ==
             "Revocation could not be confirmed. The consent grant may still be active; reload this Support workflow before retrying."

    failed_revoke_html = rendered_to_string(Show.render(failed_revoke_socket.assigns))

    assert failed_revoke_html =~
             "Revocation could not be confirmed. The consent grant may still be active; reload this Support workflow before retrying."

    assert failed_revoke_html =~ "lockspire-admin-errors"

    assert {:noreply, socket} =
             Show.handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.consent.grant.status == :revoked

    revoked_html = rendered_to_string(Show.render(socket.assigns))

    assert revoked_html =~
             "This consent grant is already revoked. It no longer authorizes future remembered-consent reuse."

    assert revoked_html =~ "Consent grant already revoked"
    assert revoked_html =~ ~r/<button[^>]*disabled[^>]*>.*Consent grant already revoked/s
  end

  test "support consent route proof covers ugly grant states and redaction guardrails" do
    now = DateTime.utc_now()

    long_client_id = "consent-proof-client-" <> String.duplicate("wrap-", 10) <> "client"
    long_account_id = "account-consent-proof-" <> String.duplicate("case-", 10) <> "subject"
    long_scope = "urn:lockspire:consent:scope:" <> String.duplicate("wrapped-", 10) <> "read"

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: long_client_id,
        client_secret_hash: "sha256:consent-proof-secret-hash",
        client_type: :confidential,
        name: "Consent Proof Client With Dense State",
        redirect_uris: ["https://consent-proof.invalid/callback"],
        allowed_scopes: ["openid", "email", long_scope],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: now,
        metadata: %{}
      })

    active_grant =
      store_support_consent!(
        account_id: long_account_id,
        client_id: long_client_id,
        scopes: ["openid", "email", long_scope],
        granted_at: DateTime.add(now, -1_200, :second)
      )

    _sparse_grant =
      store_support_consent!(
        account_id: "account-consent-proof-sparse",
        client_id: long_client_id,
        scopes: [],
        kind: :one_time,
        granted_at: DateTime.add(now, -900, :second)
      )

    revoked_grant =
      store_support_consent!(
        account_id: long_account_id,
        client_id: long_client_id,
        scopes: ["openid"],
        granted_at: DateTime.add(now, -3_600, :second),
        status: :revoked,
        revoked_at: DateTime.add(now, -600, :second),
        revoked_by: "operator-proof-id",
        revoked_reason: "operator_revoked"
      )

    assert {:ok, index_socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, index_socket} =
             Index.handle_params(
               %{"client" => long_client_id, "status" => "all"},
               "/lockspire/admin/consents?client=#{long_client_id}&status=all",
               index_socket
             )

    index_html = rendered_to_string(Index.render(index_socket.assigns))
    decision_summary = fragment_html(index_html, ".lockspire-admin-decision-summary")
    rows = fragment_html(index_html, ".lockspire-admin-dense-resource-row")

    assert_support_route_guardrails(index_html, [
      "sha256:consent-proof-secret-hash",
      "client_secret",
      "refresh_token",
      "token_hash",
      "authorization_code",
      "code_verifier",
      "user_code"
    ])

    HtmlAssertions.assert_label_targets_exist(index_html)

    assert decision_summary =~ "Selected filters"
    assert decision_summary =~ "Grant status"
    assert decision_summary =~ "Scope context"
    assert decision_summary =~ "Smallest safe action"
    assert decision_summary =~ "2 active, 1 revoked"
    assert decision_summary =~ "3 scopes across matching grants"
    assert decision_summary =~ "Review stored grant"
    refute decision_summary =~ long_client_id
    refute decision_summary =~ long_account_id

    assert rows =~ "Active remembered grant"
    assert rows =~ "Active one time grant"
    assert rows =~ "Revoked remembered grant"
    assert rows =~ "Consent Proof Client With Dense State"
    assert rows =~ "No scopes recorded"
    assert rows =~ long_scope
    assert rows =~ "lockspire-admin-long-value"
    assert rows =~ "Review stored grant"
    refute rows =~ long_client_id
    refute rows =~ long_account_id

    {_active_socket, active_html} = render_show_for(active_grant)
    active_summary = fragment_html(active_html, ".lockspire-admin-decision-summary")

    assert_support_route_guardrails(active_html, [
      "sha256:consent-proof-secret-hash",
      long_client_id,
      long_account_id
    ])

    assert active_summary =~ "Grant status"
    assert active_summary =~ "Active remembered grant"
    assert active_summary =~ "Scope context"
    assert active_summary =~ "Client/account pivot"
    assert active_summary =~ "Revocation consequence"
    assert active_summary =~ "Stops future reuse"
    assert active_html =~ long_scope
    assert active_html =~ "Not recorded"
    assert active_html =~ "future remembered-consent reuse"
    assert active_html =~ "lockspire-admin-long-value"

    {_revoked_socket, revoked_html} = render_show_for(revoked_grant)
    revoked_summary = fragment_html(revoked_html, ".lockspire-admin-decision-summary")

    assert_support_route_guardrails(revoked_html, [
      "sha256:consent-proof-secret-hash",
      long_client_id,
      long_account_id
    ])

    assert revoked_summary =~ "Already revoked"

    assert revoked_html =~
             "This consent grant is already revoked. It no longer authorizes future remembered-consent reuse."

    assert revoked_html =~ "Consent grant already revoked"
    assert revoked_html =~ ~r/<button[^>]*disabled[^>]*>.*Consent grant already revoked/s
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end

  defp store_support_consent!(attrs) do
    now = DateTime.utc_now()

    grant =
      struct(
        %ConsentGrant{
          account_id: "account-consent-proof",
          client_id: "consent-ui-client",
          scopes: ["openid"],
          granted_at: now,
          metadata: %{}
        },
        attrs
      )

    assert {:ok, stored_grant} = Repository.grant_consent(grant)
    stored_grant
  end

  defp render_show_for(grant) do
    id = Integer.to_string(grant.id)

    assert {:ok, socket} = Show.mount(%{"id" => id}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(%{"id" => id}, "/lockspire/admin/consents/#{id}", socket)

    {socket, rendered_to_string(Show.render(socket.assigns))}
  end

  defp assert_support_route_guardrails(html, denied_values) do
    html
    |> HtmlAssertions.assert_no_duplicate_ids()
    |> HtmlAssertions.assert_describedby_targets_exist()
    |> HtmlAssertions.assert_aria_targets_exist("aria-labelledby")
    |> HtmlAssertions.assert_aria_targets_exist("aria-controls")
    |> HtmlAssertions.assert_links_have_hrefs()
    |> HtmlAssertions.assert_disabled_links_have_semantics()
    |> HtmlAssertions.assert_no_generic_cta_text()
    |> HtmlAssertions.assert_no_token_like_text()
    |> HtmlAssertions.assert_no_text(@unsupported_support_controls ++ denied_values)
  end

  defp fragment_html(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.to_html()
  end

  defp html_index(html, needle) do
    case :binary.match(html, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected rendered HTML to contain #{inspect(needle)}")
    end
  end
end
