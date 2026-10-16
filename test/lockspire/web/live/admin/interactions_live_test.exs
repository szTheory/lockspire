defmodule Lockspire.Web.Live.Admin.InteractionsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.InteractionsLive.Index

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    interactions = [
      interaction_fixture(:pending_login, now),
      interaction_fixture(:pending_consent, now),
      interaction_fixture(:completed, now),
      interaction_fixture(:denied, now),
      interaction_fixture(:expired, now)
    ]

    %{interactions: interactions}
  end

  test "router exposes admin interactions routes" do
    routes = Lockspire.Web.AdminRouteTestHelpers.admin_routes()

    assert Enum.any?(routes, &live_route?(&1, "/admin/interactions", Index))
  end

  test "interactions index renders operate queue buckets and resource rows" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{},
               "/lockspire/admin/interactions",
               socket
             )

    html = rendered_to_string(Index.render(socket.assigns))
    page_html = page_markup(html)

    HtmlAssertions.assert_page_contract!(html)

    HtmlAssertions.assert_no_duplicate_ids(page_html)
    HtmlAssertions.assert_describedby_targets_exist(page_html)
    HtmlAssertions.assert_no_generic_cta_text(page_html)

    HtmlAssertions.assert_no_text(page_html, [
      "authorization_code",
      "request object",
      "cookie",
      "session token",
      "nonce",
      "pkce",
      "raw params",
      "refresh_token",
      "access_token",
      "private_key",
      "verifier_material",
      "raw-nonce-value",
      "raw-state-value",
      "pkce-material-value"
    ])

    refute_protocol_field_context(page_html, "state")

    HtmlAssertions.assert_no_interactive_controls(page_html,
      text: unsupported_queue_control_text()
    )

    assert page_html =~ "Activity"
    assert page_html =~ "Sign-in requests"
    assert page_html =~ "Sign-in request history"

    assert page_html =~
             "See requests waiting for sign-in or consent, plus the results already recorded."

    assert page_html =~ "Waiting for sign-in"
    assert page_html =~ "Waiting for consent"
    assert page_html =~ "Completed"
    assert page_html =~ "Denied"
    assert page_html =~ "Expired"
    assert summary_stat?(page_html, "Waiting for sign-in", 1)
    assert summary_stat?(page_html, "Waiting for consent", 1)
    assert summary_stat?(page_html, "Completed", 1)
    assert summary_stat?(page_html, "Denied", 1)
    assert summary_stat?(page_html, "Expired", 1)
    assert page_html =~ "5 sign-in requests recorded"
    assert page_html =~ "lockspire-admin-pane"
    assert page_html =~ "lockspire-admin-resource-list"
    assert page_html =~ "lockspire-admin-dense-resource-row"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ "Waiting for sign-in"
    assert page_html =~ "Waiting for consent"
    assert page_html =~ "Completed sign-in request"
    assert page_html =~ "Denied sign-in request"
    assert page_html =~ "Expired sign-in request"

    assert page_html =~ "The person must sign in before they can review the request."
    assert page_html =~ "The person has not responded to the consent request yet."
    assert page_html =~ "The request was completed."
    assert page_html =~ "The request was denied."
    assert page_html =~ "The request expired before it was completed."

    assert page_html =~
             Lockspire.Redaction.handle(
               :interaction,
               "test-interaction-pending-login-with-a-long-safe-review-handle"
             )

    refute page_html =~ "test-interaction-pending-login-with-a-long-safe-review-handle"
    assert page_html =~ "client-with-a-very-long-safe-fixture-value-pending-login"
    assert page_html =~ "View app details"

    assert page_html =~
             Lockspire.Redaction.handle(:interaction, "test-interaction-pending-consent")

    assert page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-completed")
    assert page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-denied")
    assert page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-expired")
    assert page_html =~ "Request reference"
    assert page_html =~ "Client ID"
    assert page_html =~ "Account"
    assert page_html =~ "Prompt"
    assert page_html =~ "Created"
    assert page_html =~ "Last activity"
    assert page_html =~ "Expires"
    assert page_html =~ "login, consent"
    assert page_html =~ "consent"
    assert page_html =~ "Not recorded"
    refute page_html =~ "account-with-a-very-long-safe-fixture-value"
    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"
    refute_unsupported_queue_controls(page_html)
    assert page_html =~ "Waiting for sign-in"
  end

  test "pending filter shows only requests waiting for sign-in or consent" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"status" => "pending"},
               "/lockspire/admin/interactions?status=pending",
               socket
             )

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert socket.assigns.interactions
           |> Enum.map(& &1.status)
           |> Enum.sort() == [:pending_consent, :pending_login]

    assert page_html =~ "2 requests waiting for sign-in or consent"

    assert page_html =~
             Lockspire.Redaction.handle(
               :interaction,
               "test-interaction-pending-login-with-a-long-safe-review-handle"
             )

    refute page_html =~ "test-interaction-pending-login-with-a-long-safe-review-handle"

    assert page_html =~
             Lockspire.Redaction.handle(:interaction, "test-interaction-pending-consent")

    refute page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-completed")
    refute page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-denied")
    refute page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-expired")
    refute page_html =~ "Completed sign-in request"
    refute page_html =~ "Denied sign-in request"
    refute page_html =~ "Expired sign-in request"
    refute summary_stat?(page_html, "Waiting for sign-in", 1)
    refute summary_stat?(page_html, "Waiting for consent", 1)
    refute summary_stat?(page_html, "Completed", 1)
    refute summary_stat?(page_html, "Denied", 1)
    refute summary_stat?(page_html, "Expired", 1)
    assert page_html =~ "View all sign-in requests"
    assert page_html =~ ~s(href="/lockspire/admin/interactions")
    refute_unsupported_queue_controls(page_html)
  end

  test "unknown interaction status filters fall back to the full history" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"status" => "completed"},
               "/lockspire/admin/interactions?status=completed",
               socket
             )

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert length(socket.assigns.interactions) == 5
    assert page_html =~ "5 sign-in requests recorded"

    assert page_html =~
             Lockspire.Redaction.handle(
               :interaction,
               "test-interaction-pending-login-with-a-long-safe-review-handle"
             )

    refute page_html =~ "test-interaction-pending-login-with-a-long-safe-review-handle"

    assert page_html =~
             Lockspire.Redaction.handle(:interaction, "test-interaction-pending-consent")

    assert page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-completed")
    assert page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-denied")
    assert page_html =~ Lockspire.Redaction.handle(:interaction, "test-interaction-expired")
    refute page_html =~ "View all sign-in requests"
  end

  test "empty pending filter shows its successful zero state and full-history route" do
    clear_interactions()

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    interaction_fixture(:completed, now)

    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(
               %{"status" => "pending"},
               "/lockspire/admin/interactions?status=pending",
               socket
             )

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert page_html =~ "0 requests waiting for sign-in or consent"
    assert page_html =~ "No requests waiting for sign-in or consent"
    assert page_html =~ "There are no requests waiting for sign-in or consent."
    assert page_html =~ "View all sign-in requests"
    assert page_html =~ ~s(href="/lockspire/admin/interactions")
    refute summary_stat?(page_html, "Completed", 1)
  end

  test "interactions empty state names the absent records without controls" do
    html =
      %{
        current_section: :interactions,
        page_title: "Sign-in requests",
        interaction_read_state: :loaded,
        interaction_filter: :all,
        interactions: [],
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert html =~ "No sign-in requests recorded"
    assert html =~ "There are no recorded authorization requests to review."
    refute html =~ "operator"
    assert html =~ "Return to overview"
    assert html =~ ~s(href="/lockspire/admin/overview")
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_queue_control_text())
  end

  test "interactions show a stable loading state before reading the queue" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert socket.assigns.interaction_read_state == :loading

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert page_html =~ "Sign-in requests"
    assert page_html =~ "Loading sign-in requests…"
    refute page_html =~ "Waiting for sign-in"
    refute page_html =~ "No sign-in requests recorded"
    refute page_html =~ "sign-in requests recorded"
  end

  test "failed interaction reads show unavailable and a same-route retry" do
    with_failed_read(fn ->
      assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

      assert {:noreply, socket} =
               Index.handle_params(%{}, "/lockspire/admin/interactions", socket)

      page_html =
        socket.assigns
        |> Index.render()
        |> rendered_to_string()
        |> page_markup()

      assert socket.assigns.interaction_read_state == :unavailable
      assert page_html =~ "Could not load sign-in requests"
      assert page_html =~ "Lockspire could not read sign-in requests"
      assert page_html =~ "the current results are unavailable"
      refute page_html =~ "No count or empty result"
      assert page_html =~ "Reload sign-in requests"
      assert page_html =~ ~s(href="/lockspire/admin/interactions")
      refute page_html =~ "Waiting for sign-in"
      refute page_html =~ "No sign-in requests waiting for review"
      refute page_html =~ "0 sign-in requests recorded"
    end)
  end

  test "successful empty interaction reads show measured zero and the named empty state" do
    clear_interactions()
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{}, "/lockspire/admin/interactions", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert socket.assigns.interaction_read_state == :loaded
    assert page_html =~ "0 sign-in requests recorded"
    assert summary_stat?(page_html, "Waiting for sign-in", 0)
    assert page_html =~ "No sign-in requests recorded"
    assert page_html =~ "There are no recorded authorization requests to review."
    refute page_html =~ "Could not load sign-in requests"
  end

  test "one interaction uses singular count copy and exposes the supported client pivot" do
    clear_interactions()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    interaction_fixture(:pending_login, now, %{
      interaction_id: "one-safe-interaction-id",
      client_id: "client-one"
    })

    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{}, "/lockspire/admin/interactions", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert page_html =~ "1 sign-in request recorded"
    assert page_html =~ Lockspire.Redaction.handle(:interaction, "one-safe-interaction-id")
    refute page_html =~ "one-safe-interaction-id"
    assert page_html =~ ~s(href="/lockspire/admin/clients/client-one")
    refute page_html =~ "one sign-in requests recorded"
    refute_unsupported_queue_controls(page_html)
  end

  test "interaction review keeps queue evidence redaction-safe and read-only" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))

    assert {:noreply, socket} =
             Index.handle_params(%{}, "/lockspire/admin/interactions", socket)

    page_html =
      socket.assigns
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert_operate_route_guardrails(page_html, [
      "raw-nonce-value",
      "raw-state-value",
      "pkce-material-value",
      "authorization_code",
      "request object",
      "cookie",
      "session token",
      "refresh_token",
      "access_token",
      "private_key",
      "verifier_material",
      "raw params"
    ])

    assert page_html =~ "Sign-in request history"
    assert page_html =~ "Waiting for sign-in"
    assert page_html =~ "Waiting for consent"
    assert page_html =~ "Completed"
    assert page_html =~ "Denied"
    assert page_html =~ "Expired"
    assert page_html =~ "Waiting for sign-in"
    assert page_html =~ "Waiting for consent"
    assert page_html =~ "Completed sign-in request"
    assert page_html =~ "Denied sign-in request"
    assert page_html =~ "Expired sign-in request"
    assert page_html =~ "Not recorded"
    assert page_html =~ "lockspire-admin-long-value"

    assert page_html =~
             Lockspire.Redaction.handle(
               :interaction,
               "test-interaction-pending-login-with-a-long-safe-review-handle"
             )

    refute page_html =~ "test-interaction-pending-login-with-a-long-safe-review-handle"
    assert page_html =~ "client-with-a-very-long-safe-fixture-value-pending-login"
    refute page_html =~ "account-with-a-very-long-safe-fixture-value"
    refute_protocol_field_context(page_html, "state")
    refute_protocol_field_context(page_html, "nonce")
    refute_unsupported_queue_controls(page_html)
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end

  defp interaction_fixture(status, now, overrides \\ %{}) do
    attrs = interaction_attrs(status, now) |> Map.merge(overrides)

    {:ok, interaction} =
      attrs
      |> then(&struct(Interaction, &1))
      |> Repository.put_interaction()

    interaction
  end

  defp clear_interactions do
    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DELETE FROM lockspire_interactions", [])
  end

  defp with_failed_read(fun) do
    previous_repo = Application.get_env(:lockspire, :repo)

    try do
      Application.put_env(
        :lockspire,
        :repo,
        Lockspire.Web.Live.Admin.InteractionsLiveTest.FailingRepo
      )

      fun.()
    after
      Application.put_env(:lockspire, :repo, previous_repo)
    end
  end

  defp interaction_attrs(:pending_login, now) do
    %{
      interaction_id: "test-interaction-pending-login-with-a-long-safe-review-handle",
      client_id: "client-with-a-very-long-safe-fixture-value-pending-login",
      account_id: "account-with-a-very-long-safe-fixture-value-pending-login",
      status: :pending_login,
      prompt: ["login", "consent"],
      return_to: "https://fixture.invalid/return?raw_params=hidden",
      nonce: "raw-nonce-value",
      state: "raw-state-value",
      code_challenge: "pkce-material-value",
      login_required_at: DateTime.add(now, -120, :second),
      expires_at: DateTime.add(now, 600, :second)
    }
  end

  defp interaction_attrs(:pending_consent, now) do
    %{
      interaction_id: "test-interaction-pending-consent",
      client_id: "client-with-a-very-long-safe-fixture-value-pending-consent",
      account_id: "account-with-a-very-long-safe-fixture-value-pending-consent",
      status: :pending_consent,
      prompt: ["consent"],
      return_to: "https://fixture.invalid/consent",
      consent_requested_at: DateTime.add(now, -90, :second),
      expires_at: DateTime.add(now, 480, :second)
    }
  end

  defp interaction_attrs(:completed, now) do
    %{
      interaction_id: "test-interaction-completed",
      client_id: "client-completed-safe-fixture",
      account_id: "account-completed-safe-fixture",
      status: :completed,
      prompt: nil,
      return_to: "https://fixture.invalid/completed",
      completed_at: DateTime.add(now, -60, :second),
      expires_at: DateTime.add(now, 360, :second)
    }
  end

  defp interaction_attrs(:denied, now) do
    %{
      interaction_id: "test-interaction-denied",
      client_id: "client-denied-safe-fixture",
      account_id: "account-denied-safe-fixture",
      status: :denied,
      prompt: ["consent"],
      return_to: "https://fixture.invalid/denied",
      denied_at: DateTime.add(now, -45, :second),
      denial_reason: "operator declined fixture",
      expires_at: DateTime.add(now, 240, :second)
    }
  end

  defp interaction_attrs(:expired, now) do
    %{
      interaction_id: "test-interaction-expired",
      client_id: "client-expired-safe-fixture",
      account_id: nil,
      status: :expired,
      prompt: ["login"],
      return_to: "https://fixture.invalid/expired",
      expired_at: DateTime.add(now, -30, :second),
      expires_at: DateTime.add(now, -30, :second)
    }
  end

  defp summary_stat?(html, label, value) do
    Regex.match?(
      ~r/<span class="lockspire-admin-summary-value">\s*#{value}\s*<\/span>\s*<span class="lockspire-admin-summary-label">\s*#{Regex.escape(label)}\s*<\/span>/,
      html
    )
  end

  defp refute_protocol_field_context(html, field_name) do
    refute Regex.match?(
             ~r/(?:\b#{Regex.escape(field_name)}=|"#{Regex.escape(field_name)}"\s*:|\b#{Regex.escape(field_name)}:)/i,
             html
           )
  end

  defp refute_unsupported_queue_controls(html) do
    refute Regex.match?(
             ~r/\b(Retry|Discard|Approve|Deny|Logout now|Worker control|Requeue)\b/i,
             html
           )
  end

  defp unsupported_queue_control_text do
    ["Retry", "Discard", "Approve", "Deny", "Logout now", "Worker control", "Requeue"]
  end

  defp assert_operate_route_guardrails(html, denied_values) do
    html
    |> HtmlAssertions.assert_no_duplicate_ids()
    |> HtmlAssertions.assert_describedby_targets_exist()
    |> HtmlAssertions.assert_aria_targets_exist("aria-labelledby")
    |> HtmlAssertions.assert_aria_targets_exist("aria-controls")
    |> HtmlAssertions.assert_links_have_hrefs()
    |> HtmlAssertions.assert_disabled_links_have_semantics()
    |> HtmlAssertions.assert_no_generic_cta_text()
    |> HtmlAssertions.assert_no_token_like_text()
    |> HtmlAssertions.assert_no_text(denied_values)

    HtmlAssertions.assert_no_interactive_controls(html, text: unsupported_queue_control_text())

    refute html =~ "<table"
    refute html =~ "lockspire-admin-table-wrap"

    html
  end

  defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
end

defmodule Lockspire.Web.Live.Admin.InteractionsLiveTest.FailingRepo do
  @moduledoc false

  def all(_query, _options \\ []), do: raise("synthetic interaction list read failure")
end
