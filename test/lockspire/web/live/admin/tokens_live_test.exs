defmodule Lockspire.Web.Live.Admin.TokensLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.TokensLive.Index
  alias Lockspire.Web.Live.Admin.TokensLive.Show

  @unsupported_support_controls [
    "Reveal token",
    "Recover token",
    "Export token",
    "Copy token",
    "Inspect hash",
    "Show token hash",
    "Show client secret",
    "Bulk revoke",
    "Replay authorization code",
    "Terminate host session",
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

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "token-ui-client",
        client_secret_hash: "sha256:token-ui:hash",
        client_type: :confidential,
        name: "Token UI Client",
        redirect_uris: ["https://token-ui.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: "token-ui-refresh-hash",
        token_type: :refresh_token,
        family_id: "family-ui-123",
        generation: 0,
        client_id: "token-ui-client",
        account_id: "account-token-ui",
        scopes: ["offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: "token-ui-access-hash",
        token_type: :access_token,
        family_id: "family-ui-123",
        generation: 1,
        parent_token_id: refresh_token.id,
        client_id: "token-ui-client",
        account_id: "account-token-ui",
        scopes: ["openid"],
        issued_at: DateTime.add(now, 5, :second),
        expires_at: DateTime.add(now, 3600, :second)
      })

    %{refresh_token: refresh_token}
  end

  test "router exposes admin token routes" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/tokens", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/tokens/:id", Show))
  end

  test "token index filters durable lifecycle state without exposing raw token hashes" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"account" => "account-token-ui", "status" => "active"},
               "/lockspire/admin/tokens?account=account-token-ui&status=active",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))
    decision_summary = fragment_html(html, ".lockspire-admin-decision-summary")
    rows = fragment_html(html, ".lockspire-admin-dense-resource-row")

    assert html =~ "Support"
    assert html =~ "Token investigation"
    assert html =~ "Selected account: account_"
    assert html =~ "Selected status: active"
    assert html =~ "Filter tokens"
    assert html =~ "Review token"
    assert html =~ "lockspire-admin-decision-summary"
    assert html =~ "lockspire-admin-dense-resource-row"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Token UI Client"
    assert html =~ "Account"
    assert html =~ "Family"
    assert html =~ "Expires"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "DCR"

    assert decision_summary =~ "Selected filters"
    assert decision_summary =~ "Token health"
    assert decision_summary =~ "Family pressure"
    assert decision_summary =~ "Smallest safe action"
    assert decision_summary =~ "account_"
    refute decision_summary =~ "account-token-ui"

    assert html_index(html, ~s(<dl class="lockspire-admin-decision-summary)) <
             html_index(
               html,
               ~s(<form method="get" action="/lockspire/admin/tokens" class="lockspire-admin-filter-bar)
             )

    assert rows =~ "Review token"
    assert rows =~ "account_"
    assert rows =~ "client_"
    assert rows =~ "family_"
    refute rows =~ "account-token-ui"
    refute rows =~ "family-ui-123"

    refute html =~ "token-ui-refresh-hash"
    refute html =~ "token-ui-access-hash"
    refute html =~ "client_secret"
    refute html =~ "verifier"
    refute html =~ "authorization_code"
    refute html =~ "code_verifier"
    refute html =~ "user_code"

    assert {:noreply, empty_socket} =
             Index.handle_params(
               %{"account" => "missing-account-token-ui"},
               "/lockspire/admin/tokens?account=missing-account-token-ui",
               socket
             )

    assert rendered_to_string(Index.render(empty_socket.assigns)) =~
             "No investigation results match these filters"
  end

  test "token detail shows lineage and guarded single-token and family revoke flows", %{
    refresh_token: refresh_token
  } do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(refresh_token.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(refresh_token.id)},
               "/lockspire/admin/tokens/#{refresh_token.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_has_link(html, "/lockspire/admin/tokens")

    HtmlAssertions.assert_no_text(html, [
      "token-ui-refresh-hash",
      "family-ui-123",
      "account-token-ui"
    ])

    assert html =~ "Support"
    assert html =~ "Token health decision"
    assert html =~ "Opaque tokens stay opaque here"
    assert html =~ "lockspire-admin-decision-summary"
    assert html =~ "Token identity and current state"
    assert html =~ "Refresh family lineage"
    assert html =~ "Corrective actions"
    assert html =~ "lockspire-admin-entity-header"
    assert html =~ "lockspire-admin-pane"
    assert html =~ "lockspire-admin-dense-resource-row"
    assert html =~ "lockspire-admin-description-list"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Client"
    assert html =~ "Token UI Client"
    assert html =~ "account_"
    assert html =~ "family_"
    assert html =~ "Session ID"
    assert html =~ "Not recorded"
    assert html =~ "Parent token"
    assert html =~ "lockspire-admin-confirmation-panel"
    assert html =~ ~s(phx-submit="revoke_token")
    assert html =~ ~s(phx-submit="revoke_family")
    assert html =~ "Token health"
    assert html =~ "Family lineage"
    assert html =~ "Reuse pressure"
    assert html =~ "Smallest safe action"
    assert html =~ "Revoke token"
    assert html =~ "Revoke token family"
    assert html =~ "family-wide refresh-token invalidation"
    assert html =~ "currently unrevoked tokens in the refresh family"
    refute html =~ "revokes every active token"
    refute html =~ "token-ui-refresh-hash"
    refute html =~ "family-ui-123"
    refute html =~ "account-token-ui"
    refute html =~ "Token ##{refresh_token.id}"

    decision_summary = fragment_html(html, ".lockspire-admin-decision-summary")

    assert decision_summary =~ "Token health"
    assert decision_summary =~ "Family lineage"
    assert decision_summary =~ "Reuse pressure"
    assert decision_summary =~ "Smallest safe action"

    assert html_index(html, ~s(<dl class="lockspire-admin-decision-summary)) <
             html_index(html, "Token identity and current state")

    assert {:noreply, missing_token_socket} = Show.handle_event("revoke_token", %{}, socket)

    assert missing_token_socket.assigns.revoke_error ==
             "Select the confirmation checkbox to revoke this token."

    missing_token_html = rendered_to_string(Show.render(missing_token_socket.assigns))
    assert missing_token_html =~ "Select the confirmation checkbox to revoke this token."
    assert missing_token_html =~ "lockspire-admin-errors"

    assert {:noreply, missing_family_socket} = Show.handle_event("revoke_family", %{}, socket)

    assert missing_family_socket.assigns.family_error ==
             "Select the confirmation checkbox to revoke this refresh family."

    missing_family_html = rendered_to_string(Show.render(missing_family_socket.assigns))

    assert missing_family_html =~
             "Select the confirmation checkbox to revoke this refresh family."

    assert missing_family_html =~ "lockspire-admin-errors"

    failed_revoke_socket = put_in(socket.assigns.token_id, -1)

    assert {:noreply, failed_revoke_socket} =
             Show.handle_event(
               "revoke_token",
               %{"revoke" => %{"confirm" => "true"}},
               failed_revoke_socket
             )

    assert failed_revoke_socket.assigns.revoke_error ==
             "Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying."

    failed_revoke_html = rendered_to_string(Show.render(failed_revoke_socket.assigns))

    assert failed_revoke_html =~
             "Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying."

    assert failed_revoke_html =~ "lockspire-admin-errors"

    assert {:noreply, socket} =
             Show.handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.token_detail.token.revoked_at
    assert socket.assigns.token_detail.token.family_handle =~ "family_"

    assert {:noreply, socket} =
             Show.handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.family_notice =~ "Revoked"
  end

  test "token detail clears stale sibling form errors after alternate revoke actions succeed", %{
    refresh_token: refresh_token
  } do
    {socket, _html} = render_show_for(refresh_token)

    assert {:noreply, socket_with_family_error} = Show.handle_event("revoke_family", %{}, socket)

    assert socket_with_family_error.assigns.family_error ==
             "Select the confirmation checkbox to revoke this refresh family."

    assert {:noreply, token_success_socket} =
             Show.handle_event(
               "revoke_token",
               %{"revoke" => %{"confirm" => "true"}},
               socket_with_family_error
             )

    assert is_nil(token_success_socket.assigns.family_error)
    assert is_nil(token_success_socket.assigns.revoke_error)

    alternate_token =
      store_support_token!(
        token_hash: "token-ui-clear-sibling-errors-hash",
        family_id: "family-ui-clear-sibling-errors"
      )

    {alternate_socket, _html} = render_show_for(alternate_token)

    assert {:noreply, socket_with_token_error} =
             Show.handle_event("revoke_token", %{}, alternate_socket)

    assert socket_with_token_error.assigns.revoke_error ==
             "Select the confirmation checkbox to revoke this token."

    assert {:noreply, family_success_socket} =
             Show.handle_event(
               "revoke_family",
               %{"family" => %{"confirm" => "true"}},
               socket_with_token_error
             )

    assert is_nil(family_success_socket.assigns.revoke_error)
    assert is_nil(family_success_socket.assigns.family_error)
  end

  test "token detail renders revoked, expired, no-family, and reuse-detected closed states" do
    revoked_token =
      store_support_token!(
        token_hash: "token-ui-already-revoked-hash",
        family_id: "family-ui-revoked",
        revoked_at: DateTime.utc_now()
      )

    {_socket, revoked_html} = render_show_for(revoked_token)

    assert revoked_html =~ "This token is already revoked. No further token action is available."
    assert revoked_html =~ "Token already revoked"
    assert revoked_html =~ ~r/<button[^>]*disabled[^>]*>.*Token already revoked/s

    expired_token =
      store_support_token!(
        token_hash: "token-ui-expired-hash",
        family_id: "family-ui-expired",
        issued_at: DateTime.add(DateTime.utc_now(), -7_200, :second),
        expires_at: DateTime.add(DateTime.utc_now(), -3_600, :second)
      )

    {_socket, expired_html} = render_show_for(expired_token)

    assert expired_html =~
             "This token is expired. No active token remains because its expiration time has passed."

    assert expired_html =~ "Expired"
    assert expired_html =~ ~r/<button[^>]*disabled[^>]*>.*Token expired/s

    no_family_token =
      store_support_token!(
        token_hash: "token-ui-no-family-hash",
        family_id: nil
      )

    {_socket, no_family_html} = render_show_for(no_family_token)

    assert no_family_html =~
             "This token is not part of a refresh family, so family-wide revocation is unavailable."

    assert no_family_html =~ ~r/<button[^>]*disabled[^>]*>.*Family-wide revocation unavailable/s

    reuse_revoked_token =
      store_support_token!(
        token_hash: "token-ui-reuse-revoked-hash",
        family_id: "family-ui-reuse-revoked",
        reuse_detected_at: DateTime.utc_now(),
        revoked_at: DateTime.utc_now()
      )

    {_socket, reuse_revoked_html} = render_show_for(reuse_revoked_token)

    assert reuse_revoked_html =~ "Reuse detected"

    assert reuse_revoked_html =~
             "This token is already revoked. No further token action is available."

    assert reuse_revoked_html =~ ~r/<button[^>]*disabled[^>]*>.*Token already revoked/s
    assert reuse_revoked_html =~ "No currently unrevoked tokens remain in the refresh family."
    assert reuse_revoked_html =~ ~r/<button[^>]*disabled[^>]*>.*Token family already revoked/s

    reusable_family_current =
      store_support_token!(
        token_hash: "token-ui-reuse-revoked-with-active-sibling-hash",
        family_id: "family-ui-reuse-with-sibling",
        generation: 0,
        reuse_detected_at: DateTime.utc_now(),
        revoked_at: DateTime.utc_now()
      )

    _active_sibling =
      store_support_token!(
        token_hash: "token-ui-reuse-active-sibling-hash",
        family_id: "family-ui-reuse-with-sibling",
        generation: 1,
        parent_token_id: reusable_family_current.id
      )

    {_socket, reusable_family_html} = render_show_for(reusable_family_current)

    reusable_family_summary =
      fragment_html(reusable_family_html, ".lockspire-admin-decision-summary")

    assert reusable_family_summary =~ "Smallest safe action"
    assert reusable_family_summary =~ "Revoke token family"

    assert reusable_family_summary =~
             "Reuse evidence means family-wide revocation is the safest available token action."

    assert reusable_family_html =~ "1 currently unrevoked tokens in the refresh family."
    assert reusable_family_html =~ "Revoke token family"
    refute reusable_family_html =~ "Token family already revoked"
  end

  test "support token route proof covers ugly states and redaction guardrails" do
    now = DateTime.utc_now()

    long_client_id = "token-proof-client-" <> String.duplicate("wrap-", 10) <> "client"
    long_account_id = "account-proof-" <> String.duplicate("case-", 10) <> "subject"
    long_family_id = "family-proof-" <> String.duplicate("lineage-", 8) <> "reuse"
    long_scope = "urn:lockspire:token:scope:" <> String.duplicate("wrapped-", 10) <> "read"

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: long_client_id,
        client_secret_hash: "sha256:token-proof-secret-hash",
        client_type: :confidential,
        name: "Token Proof Client With Dense State",
        redirect_uris: ["https://token-proof.invalid/callback"],
        allowed_scopes: ["openid", "offline_access", long_scope],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: now,
        metadata: %{}
      })

    active_token =
      store_support_token!(
        token_hash: "token-proof-active-hash-must-not-render",
        client_id: long_client_id,
        account_id: long_account_id,
        family_id: long_family_id,
        scopes: ["offline_access", long_scope],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      )

    _active_sibling =
      store_support_token!(
        token_hash: "token-proof-active-sibling-hash-must-not-render",
        client_id: long_client_id,
        account_id: long_account_id,
        family_id: long_family_id,
        generation: 1,
        parent_token_id: active_token.id,
        scopes: ["openid", long_scope],
        issued_at: DateTime.add(now, 30, :second),
        expires_at: DateTime.add(now, 86_400, :second)
      )

    _revoked_token =
      store_support_token!(
        token_hash: "token-proof-revoked-hash-must-not-render",
        client_id: long_client_id,
        account_id: long_account_id,
        family_id: "family-proof-revoked-" <> String.duplicate("closed-", 8),
        revoked_at: DateTime.add(now, -900, :second),
        issued_at: DateTime.add(now, -3_600, :second),
        expires_at: DateTime.add(now, 86_400, :second)
      )

    _expired_token =
      store_support_token!(
        token_hash: "token-proof-expired-hash-must-not-render",
        client_id: long_client_id,
        account_id: nil,
        family_id: nil,
        issued_at: DateTime.add(now, -7_200, :second),
        expires_at: DateTime.add(now, -3_600, :second)
      )

    reuse_token =
      store_support_token!(
        token_hash: "token-proof-reuse-hash-must-not-render",
        client_id: long_client_id,
        account_id: long_account_id,
        family_id: long_family_id,
        generation: 2,
        parent_token_id: active_token.id,
        scopes: ["offline_access", long_scope],
        reuse_detected_at: DateTime.add(now, -60, :second),
        issued_at: DateTime.add(now, -1_200, :second),
        expires_at: DateTime.add(now, 86_400, :second)
      )

    assert {:ok, index_socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, index_socket} =
             Index.handle_params(
               %{"client" => long_client_id, "status" => "all"},
               "/lockspire/admin/tokens?client=#{long_client_id}&status=all",
               index_socket
             )

    index_html = rendered_to_string(Index.render(index_socket.assigns))
    decision_summary = fragment_html(index_html, ".lockspire-admin-decision-summary")
    rows = fragment_html(index_html, ".lockspire-admin-dense-resource-row")

    assert_support_route_guardrails(index_html, [
      "token-proof-active-hash-must-not-render",
      "token-proof-active-sibling-hash-must-not-render",
      "token-proof-revoked-hash-must-not-render",
      "token-proof-expired-hash-must-not-render",
      "token-proof-reuse-hash-must-not-render",
      "sha256:token-proof-secret-hash"
    ])

    HtmlAssertions.assert_label_targets_exist(index_html)

    assert decision_summary =~ "Selected filters"
    assert decision_summary =~ "Token health"
    assert decision_summary =~ "Family pressure"
    assert decision_summary =~ "Smallest safe action"
    assert decision_summary =~ "2 active, 1 revoked, 1 expired, 1 reuse detected"
    assert decision_summary =~ "Reuse evidence in matching family"
    assert decision_summary =~ "Review affected token"
    refute decision_summary =~ long_client_id
    refute decision_summary =~ long_account_id
    refute decision_summary =~ long_family_id

    assert rows =~ "Active refresh token"
    assert rows =~ "Revoked refresh token"
    assert rows =~ "Expired refresh token"
    assert rows =~ "Reuse detected refresh token"
    assert rows =~ "Token Proof Client With Dense State"
    assert rows =~ "Not recorded"
    assert rows =~ "lockspire-admin-long-value"
    assert rows =~ "Review token"
    refute rows =~ long_client_id
    refute rows =~ long_account_id
    refute rows =~ long_family_id

    {_detail_socket, detail_html} = render_show_for(reuse_token)
    detail_summary = fragment_html(detail_html, ".lockspire-admin-decision-summary")

    assert_support_route_guardrails(detail_html, [
      "token-proof-reuse-hash-must-not-render",
      "token-proof-active-hash-must-not-render",
      "token-proof-active-sibling-hash-must-not-render",
      "sha256:token-proof-secret-hash",
      long_client_id,
      long_account_id,
      long_family_id
    ])

    assert detail_summary =~ "Token health"
    assert detail_summary =~ "Reuse detected"
    assert detail_summary =~ "Family lineage"
    assert detail_summary =~ "Reuse pressure present"
    assert detail_summary =~ "Smallest safe action"
    assert detail_summary =~ "Revoke token family"
    assert detail_html =~ long_scope
    assert detail_html =~ "lockspire-admin-long-value"
    assert detail_html =~ "family-wide refresh-token invalidation"
    assert detail_html =~ "does not expose token plaintext"
    refute detail_html =~ "revokes every active token"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp store_support_token!(attrs) do
    now = DateTime.utc_now()

    token =
      struct(
        %Token{
          token_hash: "token-ui-#{System.unique_integer([:positive])}",
          token_type: :refresh_token,
          family_id: "family-ui-#{System.unique_integer([:positive])}",
          generation: 0,
          client_id: "token-ui-client",
          account_id: "account-token-ui",
          scopes: ["offline_access"],
          issued_at: now,
          expires_at: DateTime.add(now, 86_400, :second)
        },
        attrs
      )

    assert {:ok, stored_token} = Repository.store_token(token)
    stored_token
  end

  defp render_show_for(token) do
    id = Integer.to_string(token.id)

    assert {:ok, socket} = Show.mount(%{"id" => id}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(%{"id" => id}, "/lockspire/admin/tokens/#{id}", socket)

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

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
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
