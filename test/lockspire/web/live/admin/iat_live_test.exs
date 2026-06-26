# credo:disable-for-this-file
defmodule Lockspire.Web.Live.Admin.IatLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.InitialAccessTokens

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

  test "DCR page preserves onboarding and policy vocabulary" do
    {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")

    assert html =~ "DCR onboarding"
    assert html =~ "DCR policy"
    assert html =~ "Mint initial access token"
    assert html =~ "Review initial access tokens"
  end

  describe "Index" do
    test "renders DCR onboarding inventory context and allows guarded revocation" do
      {:ok, iat, secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "test",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, view, html} = live(conn_for_admin(), "/admin/iats")

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
      assert html =~ "lockspire-admin-pane"
      assert html =~ "lockspire-admin-dense-resource-row"
      assert html =~ "lockspire-admin-long-value"
      refute html =~ secret

      # Revoke
      view
      |> element("button[phx-click=\"revoke\"][phx-value-id=\"#{iat.id}\"]")
      |> render_click()

      # Refresh the token from DB (via UI update)
      # In the view it should reflect the status change, or at least the badge should change.
      html_after_revoke = render(view)
      refute html_after_revoke =~ "Revoke initial access token</button>"
    end
  end

  describe "New" do
    test "minting an IAT uses copy-once panel and clearing removes plaintext" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

      # Initial state should have no secret
      initial_html = render(view)
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
               "Copy this value now. Lockspire stores only the hash after this response."

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

      refute html_after_ack =~ "Initial access token minted"
      refute html_after_ack =~ "I have copied this secret"
      refute html_after_ack =~ plaintext
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end
end
