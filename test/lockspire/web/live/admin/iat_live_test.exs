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

  describe "Index" do
    test "lists active tokens and allows revocation" do
      {:ok, iat, _secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "test",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, view, html} = live(conn_for_admin(), "/admin/iats")

      assert html =~ "Initial Access Tokens"
      assert html =~ to_string(iat.id)

      # Revoke
      view
      |> element("button[phx-click=\"revoke\"][phx-value-id=\"#{iat.id}\"]")
      |> render_click()

      # Refresh the token from DB (via UI update)
      # In the view it should reflect the status change, or at least the badge should change.
      html_after_revoke = render(view)
      refute html_after_revoke =~ "class=\"lockspire-admin-btn-danger\">Revoke</button>"
    end
  end

  describe "New" do
    test "minting an IAT shows the secret exactly once and clearing works" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

      # Initial state should have no secret
      refute render(view) =~ "Secret revealed"

      # Mint a new token
      html_after_mint =
        view
        |> element("form")
        |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

      assert html_after_mint =~ "Secret revealed"
      assert html_after_mint =~ "I have copied this secret"

      # Clicking the acknowledge button
      html_after_ack =
        view
        |> element("button[phx-click=\"acknowledge_copy\"]")
        |> render_click()

      refute html_after_ack =~ "Secret revealed"
      refute html_after_ack =~ "I have copied this secret"
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end
end
