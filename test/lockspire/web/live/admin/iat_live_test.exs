# credo:disable-for-this-file
defmodule Lockspire.Web.Live.Admin.IatLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Web.AdminProof.HtmlAssertions

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
    :ok
  end

  test "D-03/D-04/D-06/D-07 DCR page presents onboarding decision spine without unsupported controls" do
    {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_describedby_targets_exist(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_has_link(html, "/admin/iats/new")
    HtmlAssertions.assert_has_link(html, "/admin/iats")
    HtmlAssertions.assert_has_link(html, "/admin/policies/dcr")

    HtmlAssertions.assert_no_text(html, [
      "client secret",
      "RAT plaintext",
      "Developer portal",
      "Approve registration",
      "Deny registration",
      "Reveal secret",
      "Reveal token",
      "Export credential"
    ])

    assert html =~ "Configure"
    assert html =~ "DCR onboarding"
    assert html =~ "Registration gate"
    assert html =~ "Intake tokens"
    assert html =~ "Self-registered clients"
    assert html =~ "Next safe action"
    assert html =~ "Mint initial access token"
    assert html =~ "Review initial access tokens"
    assert html =~ "Edit DCR policy"
  end

  describe "Index" do
    test "D-03/D-04/D-08/D-09/D-10 renders intake inventory and requires inline revoke confirmation" do
      {:ok, iat, secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "test",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, view, html} = live(conn_for_admin(), "/admin/iats")

      HtmlAssertions.assert_no_duplicate_ids(html)
      HtmlAssertions.assert_describedby_targets_exist(html)
      HtmlAssertions.assert_no_generic_cta_text(html)
      HtmlAssertions.assert_has_link(html, "/admin/iats/new")
      HtmlAssertions.assert_no_text(html, [secret | forbidden_secret_samples()])

      assert html =~ "Configure"
      assert html =~ "Initial access token inventory"
      assert html =~ "Review initial access tokens"
      assert html =~ "Active"
      assert html =~ "Used"
      assert html =~ "Expired"
      assert html =~ "Revoked"
      assert html =~ "Total intake"
      assert html =~ "Single-use"
      assert html =~ "Creator"
      assert html =~ "Expires"
      assert html =~ "Last state change"
      assert html =~ "Usage/limit"
      assert html =~ "Revoke initial access token"
      assert html =~ ~s(phx-submit="confirm_revoke_iat")
      assert html =~ ~s(name="revoke[confirm]")

      assert html =~
               "Partners using this intake token can no longer dynamically register clients with it."

      refute html =~ ~s(data-confirm=)
      refute html =~ ~s(phx-click="revoke")
      assert html =~ "lockspire-admin-pane"
      assert html =~ "lockspire-admin-dense-resource-row"
      assert html =~ "lockspire-admin-long-value"
      refute html =~ secret

      html_without_confirmation =
        view
        |> element("form[phx-submit=\"confirm_revoke_iat\"]")
        |> render_submit(%{"revoke" => %{"id" => Integer.to_string(iat.id)}})

      assert html_without_confirmation =~
               "Select the confirmation checkbox to revoke this initial access token."

      assert html_without_confirmation =~ "lockspire-admin-errors"

      {:ok, [active_after_missing_confirmation]} = InitialAccessTokens.list_iats()
      assert active_after_missing_confirmation.id == iat.id
      assert active_after_missing_confirmation.revoked_at == nil

      html_after_revoke =
        view
        |> element("form[phx-submit=\"confirm_revoke_iat\"]")
        |> render_submit(%{
          "revoke" => %{"id" => Integer.to_string(iat.id), "confirm" => "true"}
        })

      {:ok, [revoked_after_confirmation]} = InitialAccessTokens.list_iats()
      assert revoked_after_confirmation.id == iat.id
      assert revoked_after_confirmation.revoked_at != nil

      refute html_after_revoke =~ ~s(phx-submit="confirm_revoke_iat")
      refute html_after_revoke =~ "Revoke initial access token</button>"
    end
  end

  describe "New" do
    test "D-06/D-07 minting an IAT is copy-once and durable inventory stays redacted" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

      # Initial state should have no secret
      initial_html = render(view)

      HtmlAssertions.assert_no_duplicate_ids(initial_html)
      HtmlAssertions.assert_describedby_targets_exist(initial_html)
      HtmlAssertions.assert_label_targets_exist(initial_html)
      HtmlAssertions.assert_no_generic_cta_text(initial_html)
      HtmlAssertions.assert_no_text(initial_html, forbidden_secret_samples())

      assert initial_html =~ "Configure"
      assert initial_html =~ "Mint initial access token"
      assert initial_html =~ "DCR policy"
      assert initial_html =~ "lockspire-admin-workflow-shell"
      assert initial_html =~ "iat_single_use-help"
      assert initial_html =~ "iat_expires_in_days-help"
      assert initial_html =~ ~s(name="single_use")
      assert initial_html =~ ~s(name="expires_in_days")
      assert initial_html =~ ~s(phx-submit="mint")
      assert initial_html =~ "Review initial access tokens"
      refute initial_html =~ "Initial access token minted"

      # Mint a new token
      html_after_mint =
        view
        |> element("form")
        |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

      assert html_after_mint =~ "Initial access token minted"
      assert html_after_mint =~ "lockspire-admin-copy-once-secret"

      assert html_after_mint =~
               "Plaintext is shown once. Lockspire stores only the hash and redacted durable state after this response."

      assert html_after_mint =~ "I have copied this secret"

      [_, plaintext] =
        Regex.run(
          ~r/<code[^>]*>(?<plaintext>[^<]+)<\/code>/,
          html_after_mint
        )

      # Clicking the acknowledge button
      html_after_ack =
        view
        |> element("button[phx-click=\"acknowledge_copy\"]")
        |> render_click()

      HtmlAssertions.assert_no_text(html_after_ack, [plaintext | forbidden_secret_samples()])

      refute html_after_ack =~ "Initial access token minted"
      refute html_after_ack =~ "I have copied this secret"
      refute html_after_ack =~ plaintext

      {:ok, _index_view, inventory_html} = live(conn_for_admin(), "/admin/iats")
      HtmlAssertions.assert_no_text(inventory_html, [plaintext | forbidden_secret_samples()])
      refute inventory_html =~ plaintext
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
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
      "BEGIN PRIVATE KEY"
    ]
  end
end
