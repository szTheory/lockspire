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
        lifetime_version: 0,
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

  test "token index filters durable lifecycle state without exposing raw token hashes", %{
    refresh_token: refresh_token
  } do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"account" => "account-token-ui", "status" => "active"},
               "/lockspire/admin/tokens?account=account-token-ui&status=active",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))
    HtmlAssertions.assert_page_contract!(html, labels: :required)
    rows = fragment_html(html, ".lockspire-admin-dense-resource-row")

    assert_path_query(html, "/lockspire/admin/tokens/#{refresh_token.id}", %{
      "account" => "account-token-ui",
      "client" => "",
      "status" => "active"
    })

    assert html =~ "Support"
    assert html =~ "Tokens"

    assert html =~
             "Find access or refresh tokens by account, app, or status"

    assert html =~ "Find tokens"
    assert html =~ "Filter tokens"
    assert html =~ "View token details"
    refute html =~ ~s(<dl class="lockspire-admin-decision-summary)
    assert html =~ "lockspire-admin-dense-resource-row"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Token UI Client"
    assert html =~ "Account"
    refute rows =~ "Family"
    refute rows =~ "Expires"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "App registration"

    assert html =~ ~s(value="account-token-ui")
    assert html =~ ~s(value="active" selected)

    assert rows =~ "View token details"
    assert rows =~ Lockspire.Redaction.handle(:token, refresh_token.id)
    assert rows =~ "account_"
    refute rows =~ "client_"
    refute rows =~ "family_"
    refute visible_text(rows) =~ "account-token-ui"
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

    empty_html = rendered_to_string(Index.render(empty_socket.assigns))
    assert empty_html =~ "No matching tokens"
    assert empty_html =~ "missing-account-token-ui"
    refute empty_html =~ "Could not load tokens"
  end

  test "token filter submit keeps the native GET fallback and emits busy copy" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"account" => "account-token-ui", "status" => "active"},
               "/lockspire/admin/tokens?account=account-token-ui&status=active",
               socket
             )

    assert socket.assigns.tokens != []

    initial_html = rendered_to_string(Index.render(socket.assigns))
    assert initial_html =~ ~s(phx-submit="filter_inventory")
    assert initial_html =~ ~s(phx-disable-with="Filtering tokens…")

    {:noreply, submitted} =
      Index.handle_event(
        "filter_inventory",
        %{"account" => "pending-account", "client" => "", "status" => "all"},
        socket
      )

    assert submitted.assigns.tokens == socket.assigns.tokens
    assert {:live, :patch, %{to: path}} = submitted.redirected
    assert ["/lockspire/admin/tokens", query] = String.split(path, "?", parts: 2)

    assert URI.decode_query(query) == %{
             "account" => "pending-account",
             "client" => "",
             "status" => "all"
           }

    assert initial_html =~ ~s(method="get")
  end

  test "token inventory count copy is accurate for zero, one, and many records" do
    _single_match =
      store_support_token!(
        token_hash: "token-ui-single-count-hash",
        family_id: "family-ui-single-count",
        account_id: "account-single-count"
      )

    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, zero_socket} =
             Index.handle_params(
               %{"account" => "account-no-matches", "status" => "all"},
               "/lockspire/admin/tokens?account=account-no-matches&status=all",
               socket
             )

    zero_html = rendered_to_string(Index.render(zero_socket.assigns))
    assert zero_html =~ "Matching tokens: 0"
    assert zero_html =~ "No matching tokens"
    refute zero_html =~ ~s(<dl class="lockspire-admin-decision-summary)

    assert {:noreply, one_socket} =
             Index.handle_params(
               %{"account" => "account-single-count", "status" => "all"},
               "/lockspire/admin/tokens?account=account-single-count&status=all",
               socket
             )

    one_html = rendered_to_string(Index.render(one_socket.assigns))
    assert one_html =~ "Matching token: 1"
    refute one_html =~ ~s(<dl class="lockspire-admin-decision-summary)

    assert {:noreply, many_socket} =
             Index.handle_params(
               %{"account" => "account-token-ui", "status" => "all"},
               "/lockspire/admin/tokens?account=account-token-ui&status=all",
               socket
             )

    many_html = rendered_to_string(Index.render(many_socket.assigns))
    assert many_html =~ "Matching tokens: 2"
    refute many_html =~ ~s(<dl class="lockspire-admin-decision-summary)
  end

  test "token index keeps failed reads distinct from successful empty results" do
    original_repo = Application.fetch_env!(:lockspire, :repo)

    try do
      Application.put_env(:lockspire, :repo, String)
      assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

      assert {:noreply, failed_socket} =
               Index.handle_params(
                 %{
                   "account" => "account-read-failure",
                   "client" => "client-read-failure",
                   "status" => "revoked"
                 },
                 "/lockspire/admin/tokens?account=account-read-failure&client=client-read-failure&status=revoked",
                 socket
               )

      html = rendered_to_string(Index.render(failed_socket.assigns))

      assert failed_socket.assigns.filters == %{
               "account" => "account-read-failure",
               "client" => "client-read-failure",
               "status" => "revoked"
             }

      assert html =~ "Could not load tokens"
      assert html =~ "Try loading tokens again"
      assert html =~ "account-read-failure"
      assert html =~ "client-read-failure"
      assert html =~ "status=revoked"
      refute html =~ "No matching tokens"
      refute html =~ "0 matching token lifecycle records"
    after
      Application.put_env(:lockspire, :repo, original_repo)
    end
  end

  test "token detail shows lineage and guarded single-token and family revoke flows", %{
    refresh_token: refresh_token
  } do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(refresh_token.id)}, %{}, socket_for(:show))

    filters = %{
      "account" => "account-token-ui",
      "client" => "token-ui-client",
      "status" => "active"
    }

    params = Map.merge(%{"id" => Integer.to_string(refresh_token.id)}, filters)
    uri = "/lockspire/admin/tokens/#{refresh_token.id}?" <> URI.encode_query(filters)

    assert {:noreply, socket} =
             Show.handle_params(
               params,
               uri,
               socket
             )

    assert socket.assigns.filters == filters
    assert {:noreply, revisited_socket} = Show.handle_params(params, uri, socket)
    assert revisited_socket.assigns.filters == filters

    html = rendered_to_string(Show.render(socket.assigns))
    assert_path_query(html, "/lockspire/admin/tokens", filters)

    HtmlAssertions.assert_page_contract!(html)

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_has_link(html, "/lockspire/admin/tokens")

    HtmlAssertions.assert_no_text(without_filter_query_values(html), [
      "token-ui-refresh-hash",
      "family-ui-123",
      "account-token-ui"
    ])

    assert html =~ "Support"
    assert html =~ "Token details"

    assert html =~
             "This token is active. Token values stay hidden."

    refute visible_text(html) =~ "Operator detail"
    refute html =~ ~s(<dl class="lockspire-admin-decision-summary)
    assert html =~ "Record identifiers"
    assert html =~ "Related tokens"
    assert html =~ "Revoke access"
    assert html =~ "lockspire-admin-token-detail"
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
    assert html =~ "Revoke token"
    assert html =~ "Revoke token family"

    assert html =~
             "Revoke this refresh token? This revokes only this token; other tokens in its refresh family remain unchanged."

    assert html =~
             "Revoke this refresh token family? This revokes the currently unrevoked tokens in this family."

    assert html =~ ~s(phx-disable-with="Revoking this refresh token…")
    assert html =~ ~s(phx-disable-with="Revoking this refresh token family…")
    refute html =~ "revokes every active token"
    refute html =~ "token-ui-refresh-hash"
    refute html =~ "family-ui-123"
    refute visible_text(html) =~ "account-token-ui"
    refute html =~ "Token ##{refresh_token.id}"

    assert html_index(html, "Record identifiers") < html_index(html, "Client handle")

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
    assert socket.assigns.token_detail.family_active_count == 1
    assert socket.assigns.token_detail.token.family_handle =~ "family_"

    assert {:noreply, socket} =
             Show.handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.family_notice =~ "Revoked"
    assert socket.assigns.family_notice =~ "1 currently unrevoked token"
    assert socket.assigns.token_detail.family_active_count == 0
  end

  test "token detail uses kind-specific single-record confirmations and revokes only the selected record",
       %{
         refresh_token: refresh_token
       } do
    access_token =
      store_support_token!(
        token_hash: "token-ui-access-only-hash-must-not-render",
        token_type: :access_token,
        family_id: "family-ui-access-only",
        consent_grant_id: 1234
      )

    {_access_socket, access_html} = render_show_for(access_token)

    assert access_html =~
             "Revoke this access token? This revokes only this token; other tokens in its refresh family remain unchanged."

    HtmlAssertions.assert_has_link(access_html, "/lockspire/admin/clients/token-ui-client")
    assert access_html =~ "View consent grant"
    refute access_html =~ "token-ui-access-only-hash-must-not-render"

    {_refresh_socket, refresh_html} = render_show_for(refresh_token)

    assert refresh_html =~
             "Revoke this refresh token? This revokes only this token; other tokens in its refresh family remain unchanged."

    assert refresh_html =~
             "Revoke this refresh token family? This revokes the currently unrevoked tokens in this family."

    assert refresh_html =~ ~s(phx-disable-with="Revoking this refresh token…")
    assert refresh_html =~ ~s(phx-disable-with="Revoking this refresh token family…")
    refute refresh_html =~ "Current refresh_token token"
    assert refresh_html =~ "This refresh token"
    assert refresh_html =~ "Generation 0"
    refute refresh_html =~ "This family-wide action revokes currently unrevoked tokens"
  end

  test "token detail encodes a client pivot as one path segment" do
    client_id = "token-ui?case=1"

    assert {:ok, _client} =
             Repository.register_client(%Client{
               lifetime_version: 0,
               client_id: client_id,
               client_type: :confidential,
               name: "Reserved Client ID",
               provenance: :self_registered,
               par_policy: :required,
               dpop_policy: :dpop,
               security_profile: :fapi_2_0_security
             })

    token =
      store_support_token!(
        token_hash: "token-ui-reserved-client-id-hash",
        client_id: client_id
      )

    {_socket, html} = render_show_for(token)

    assert html =~ ~s(href="/lockspire/admin/clients/token-ui%3Fcase%3D1")
    refute html =~ ~s(href="/lockspire/admin/clients/token-ui?case=1")
  end

  test "token detail reports missing and unavailable records with a return path" do
    assert {:ok, missing_socket} = Show.mount(%{"id" => "999999999"}, %{}, socket_for(:show))

    assert {:noreply, missing_socket} =
             Show.handle_params(
               %{"id" => "999999999"},
               "/lockspire/admin/tokens/999999999",
               missing_socket
             )

    missing_html = rendered_to_string(Show.render(missing_socket.assigns))
    assert missing_html =~ "Token not found"
    assert missing_html =~ "Back to tokens"
    assert missing_html =~ ~s(href="/lockspire/admin/tokens")

    original_repo = Application.fetch_env!(:lockspire, :repo)

    try do
      Application.put_env(:lockspire, :repo, String)
      assert {:ok, failed_socket} = Show.mount(%{"id" => "2"}, %{}, socket_for(:show))

      assert {:noreply, failed_socket} =
               Show.handle_params(%{"id" => "2"}, "/lockspire/admin/tokens/2", failed_socket)

      failed_html = rendered_to_string(Show.render(failed_socket.assigns))
      assert failed_html =~ "Could not load token details"
      assert failed_html =~ "Try loading token details again"
      refute failed_html =~ "Token not found"
      assert failed_html =~ ~s(href="/lockspire/admin/tokens/2")
    after
      Application.put_env(:lockspire, :repo, original_repo)
    end
  end

  test "token detail shows an unavailable family read instead of a singleton family", %{
    refresh_token: refresh_token
  } do
    filters = %{
      "account" => "account-token-ui",
      "client" => "token-ui-client",
      "status" => "reuse_detected"
    }

    with_repo_failure(:family_read, fn ->
      id = Integer.to_string(refresh_token.id)
      assert {:ok, socket} = Show.mount(%{"id" => id}, %{}, socket_for(:show))

      assert {:noreply, socket} =
               Show.handle_params(
                 Map.merge(%{"id" => id}, filters),
                 "/lockspire/admin/tokens/#{id}?" <> URI.encode_query(filters),
                 socket
               )

      html = rendered_to_string(Show.render(socket.assigns))
      assert html =~ "Could not load token details"
      assert html =~ "Try loading token details again"
      refute html =~ "Related refresh tokens"
      refute html =~ "Token not found"
      assert_path_query(html, "/lockspire/admin/tokens/#{id}", filters)
      assert_path_query(html, "/lockspire/admin/tokens", filters)
    end)
  end

  test "token and family revocation render recoverable errors after an initial token read failure",
       %{
         refresh_token: refresh_token
       } do
    {socket, _html} = render_show_for(refresh_token)

    with_repo_failure(:initial_read, fn ->
      assert {:noreply, token_error_socket} =
               Show.handle_event(
                 "revoke_token",
                 %{"revoke" => %{"confirm" => "true"}},
                 socket
               )

      assert token_error_socket.assigns.revoke_error =~ "Revocation could not be confirmed"

      assert rendered_to_string(Show.render(token_error_socket.assigns)) =~
               "Revocation could not be confirmed"

      assert {:noreply, family_error_socket} =
               Show.handle_event(
                 "revoke_family",
                 %{"family" => %{"confirm" => "true"}},
                 socket
               )

      assert family_error_socket.assigns.family_error =~ "Revocation could not be confirmed"

      assert rendered_to_string(Show.render(family_error_socket.assigns)) =~
               "Revocation could not be confirmed"
    end)
  end

  test "token detail rejects malformed and non-positive IDs instead of loading a numeric prefix",
       %{
         refresh_token: refresh_token
       } do
    malformed_ids = [Integer.to_string(refresh_token.id) <> "junk", "0", "-1"]

    for id <- malformed_ids do
      assert {:ok, socket} = Show.mount(%{"id" => id}, %{}, socket_for(:show))

      assert {:noreply, socket} =
               Show.handle_params(%{"id" => id}, "/lockspire/admin/tokens/#{id}", socket)

      assert socket.assigns.token_id == nil
      assert socket.assigns.detail_state == :missing
      assert rendered_to_string(Show.render(socket.assigns)) =~ "Token not found"

      for {event, params} <- [
            {"revoke_token", %{"revoke" => %{"confirm" => "true"}}},
            {"revoke_family", %{"family" => %{"confirm" => "true"}}}
          ] do
        assert {:noreply, socket} = Show.handle_event(event, params, socket)
        assert socket.assigns.revoke_error =~ "Revocation could not be confirmed"
      end
    end
  end

  test "token detail displays a stored session identifier only as its stable safe handle" do
    raw_sid = "host-session-secret-token-ui"
    token = store_support_token!(sid: raw_sid)

    {_socket, html} = render_show_for(token)

    assert html =~ Lockspire.Redaction.handle(:session, raw_sid)
    refute html =~ raw_sid
  end

  test "family revoke transaction failure stays recoverable and leaves the family unchanged", %{
    refresh_token: refresh_token
  } do
    {:ok, family_before} = Repository.list_token_family("family-ui-123")
    assert Enum.count(family_before, &is_nil(&1.revoked_at)) == 2
    {socket, _html} = render_show_for(refresh_token)

    with_repo_failure(:transaction, fn ->
      assert {:noreply, failed_socket} =
               Show.handle_event(
                 "revoke_family",
                 %{"family" => %{"confirm" => "true"}},
                 socket
               )

      assert failed_socket.assigns.family_error ==
               "Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying."

      assert is_nil(failed_socket.assigns.family_notice)
      html = rendered_to_string(Show.render(failed_socket.assigns))
      assert html =~ "The token may still be active"
      refute html =~ "Revoked 2 currently unrevoked tokens"
    end)

    {:ok, family_after} = Repository.list_token_family("family-ui-123")
    assert Enum.count(family_after, &is_nil(&1.revoked_at)) == 2
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
    refute revoked_html =~ ~s(phx-submit="revoke_token")
    refute revoked_html =~ ~s(phx-submit="revoke_family")

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
    refute expired_html =~ ~s(phx-submit="revoke_token")
    refute expired_html =~ ~s(phx-submit="revoke_family")

    no_family_token =
      store_support_token!(
        token_hash: "token-ui-no-family-hash",
        family_id: nil
      )

    {_socket, no_family_html} = render_show_for(no_family_token)

    assert no_family_html =~ ~s(phx-submit="revoke_token")
    refute no_family_html =~ ~s(phx-submit="revoke_family")
    refute no_family_html =~ "Token history"

    reuse_revoked_token =
      store_support_token!(
        token_hash: "token-ui-reuse-revoked-hash",
        family_id: "family-ui-reuse-revoked",
        reuse_detected_at: DateTime.utc_now(),
        revoked_at: DateTime.utc_now()
      )

    {_socket, reuse_revoked_html} = render_show_for(reuse_revoked_token)

    assert reuse_revoked_html =~ "Used after replacement"
    assert reuse_revoked_html =~ "1 token in this family is revoked."
    assert reuse_revoked_html =~ "No active tokens to revoke"
    refute reuse_revoked_html =~ "No further action needed"

    refute reuse_revoked_html =~ ~s(phx-submit="revoke_token")
    refute reuse_revoked_html =~ ~s(phx-submit="revoke_family")

    reused_token_without_active_sibling =
      store_support_token!(
        token_hash: "token-ui-reuse-no-active-sibling-hash",
        family_id: "family-ui-reuse-no-active-sibling",
        reuse_detected_at: DateTime.utc_now()
      )

    {reused_socket, reused_without_active_sibling_html} =
      render_show_for(reused_token_without_active_sibling)

    assert reused_socket.assigns.token_detail.family_active_count == 0

    assert reused_without_active_sibling_html =~
             "No active tokens remain in this refresh-token family."

    refute reused_without_active_sibling_html =~
             "1 active token remains in this refresh-token family."

    assert reused_without_active_sibling_html =~ "No active tokens to revoke"

    refute reused_without_active_sibling_html =~ ~s(phx-submit="revoke_token")
    refute reused_without_active_sibling_html =~ ~s(phx-submit="revoke_family")

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

    assert reusable_family_html =~ "Revoke all active family tokens"
    refute reusable_family_html =~ ~s(phx-submit="revoke_token")
    assert reusable_family_html =~ ~s(phx-submit="revoke_family")

    assert reusable_family_html =~ "1 active token remains in this refresh-token family."
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
        lifetime_version: 0,
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

    refute index_html =~ ~s(<dl class="lockspire-admin-decision-summary)
    assert index_html =~ "Matching tokens: 5"

    assert rows =~ "Active refresh token"
    assert rows =~ "Revoked refresh token"
    assert rows =~ "Expired refresh token"
    assert rows =~ "Refresh token used after replacement"
    assert rows =~ "Token Proof Client With Dense State"
    assert rows =~ "Not recorded"
    assert rows =~ "lockspire-admin-long-value"
    assert rows =~ "View token details"
    refute visible_text(rows) =~ long_client_id
    refute rows =~ long_account_id
    refute rows =~ long_family_id

    {_detail_socket, detail_html} = render_show_for(reuse_token)

    assert_support_route_guardrails(detail_html, [
      "token-proof-reuse-hash-must-not-render",
      "token-proof-active-hash-must-not-render",
      "token-proof-active-sibling-hash-must-not-render",
      "sha256:token-proof-secret-hash",
      long_client_id,
      long_account_id,
      long_family_id
    ])

    refute detail_html =~ ~s(<dl class="lockspire-admin-decision-summary)
    assert detail_html =~ "Used after replacement"
    assert detail_html =~ "Revoke all active family tokens"

    assert detail_html =~ long_scope
    assert detail_html =~ "lockspire-admin-long-value"

    assert detail_html =~
             "A refresh token was presented again after replacement or revocation."

    assert detail_html =~ "These handles identify records without revealing token values."
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
    |> without_filter_query_values()
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

  defp without_filter_query_values(html) do
    Regex.replace(~r/(account|client)=[^&"]*/, html, fn match ->
      [key, _value] = String.split(match, "=", parts: 2)
      key <> "=[filter]"
    end)
  end

  defp visible_text(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace("&amp;", "&")
  end

  defp assert_path_query(html, path, expected_query) do
    encoded_query =
      case Regex.run(~r/href="#{Regex.escape(path)}\?([^"]+)"/, html) do
        [_, query] -> query
        _other -> flunk("expected a link to #{path} with preserved filter context")
      end

    assert encoded_query
           |> String.replace("&amp;", "&")
           |> URI.decode_query() == expected_query
  end

  defp with_repo_failure(failure, fun) do
    previous_repo = Application.fetch_env!(:lockspire, :repo)
    previous_failure = Application.get_env(:lockspire, :tokens_live_test_repo_failure)

    try do
      Application.put_env(:lockspire, :tokens_live_test_repo_failure, failure)
      Application.put_env(:lockspire, :repo, Lockspire.Web.Live.Admin.TokensLiveTest.FailingRepo)
      fun.()
    after
      Application.put_env(:lockspire, :repo, previous_repo)
      Application.put_env(:lockspire, :tokens_live_test_repo_failure, previous_failure)
    end
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

defmodule Lockspire.Web.Live.Admin.TokensLiveTest.FailingRepo do
  @moduledoc false

  def all(query, options \\ []) do
    if Application.get_env(:lockspire, :tokens_live_test_repo_failure) == :family_read and
         query_source(query) == Lockspire.Storage.Ecto.TokenRecord do
      raise "synthetic token family read failure"
    end

    Lockspire.TestRepo.all(query, options)
  end

  def one(query, options \\ []) do
    if Application.get_env(:lockspire, :tokens_live_test_repo_failure) == :initial_read and
         query_source(query) == Lockspire.Storage.Ecto.TokenRecord do
      raise "synthetic token initial read failure"
    end

    Lockspire.TestRepo.one(query, options)
  end

  def transaction(fun, options \\ []) do
    if Application.get_env(:lockspire, :tokens_live_test_repo_failure) == :transaction do
      {:error, :synthetic_token_transaction_failure}
    else
      Lockspire.TestRepo.transaction(fun, options)
    end
  end

  def rollback(reason), do: Lockspire.TestRepo.rollback(reason)

  defp query_source(query) do
    query
    |> Ecto.Queryable.to_query()
    |> Map.fetch!(:from)
    |> Map.fetch!(:source)
    |> case do
      {_table, schema} -> schema
      source -> source
    end
  end
end
