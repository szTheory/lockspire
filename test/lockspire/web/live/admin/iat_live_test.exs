# credo:disable-for-this-file
defmodule Lockspire.Web.Live.Admin.IatLiveTest.FailingMintRepo do
  def insert(_changeset, _opts), do: {:error, :temporarily_unavailable}
  def rollback(reason), do: {:error, reason}
end

defmodule Lockspire.Web.Live.Admin.IatLiveTest.FailingReadRepo do
  def all(_query, _opts), do: raise("synthetic initial access token list failure")
end

defmodule Lockspire.Web.Live.Admin.IatLiveTest.MissingIatRepo do
  def update_all(_query, _updates, _opts), do: {0, nil}
end

defmodule Lockspire.Web.Live.Admin.IatLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Admin.InitialAccessTokens
  alias Lockspire.Storage.Ecto.Repository
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
    HtmlAssertions.assert_has_link(html, "/admin/iats")
    HtmlAssertions.assert_has_link(html, "/admin/policies/dcr")

    HtmlAssertions.assert_no_text(html, [
      "RAT plaintext",
      "Developer portal",
      "Approve registration",
      "Deny registration",
      "Force publish",
      "Remote key fetch",
      "Tenant policy editor",
      "Reveal secret",
      "Reveal token",
      "Export credential"
    ])

    assert html =~ "Configure"
    assert html =~ "App registration"
    assert html =~ "App setup tokens"
    assert html =~ "Apps registered by their teams"
    assert html =~ "Change registration rules"
    assert html =~ "Review setup tokens"
    refute html =~ "issuer"
    refute html =~ "Initial Access Token"
  end

  describe "Index" do
    test "D-06/D-07 successful empty inventory has zero counts and a named next step" do
      {:ok, _view, html} = live(conn_for_admin(), "/admin/iats")

      assert String.contains?(html, "No app setup tokens yet")
      assert inventory_counts(html) == ["0", "0", "0", "0", "0"]
      assert length(Regex.scan(~r/href="\/admin\/iats\/new"/, html)) == 1
      assert html =~ "Create app setup token"
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-alert-danger")
    end

    test "D-06 populated inventory has one create action" do
      {:ok, _iat, _plaintext} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "operator",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, _view, html} = live(conn_for_admin(), "/admin/iats")

      assert length(Regex.scan(~r/href="\/admin\/iats\/new"/, html)) == 1
      assert html =~ "Create app setup token"
    end

    test "D-06 failed inventory read remains unavailable and reload can recover" do
      Application.put_env(
        :lockspire,
        :repo,
        Lockspire.Web.Live.Admin.IatLiveTest.FailingReadRepo
      )

      on_exit(fn -> Application.put_env(:lockspire, :repo, Lockspire.TestRepo) end)
      {:ok, view, html} = live(conn_for_admin(), "/admin/iats")

      assert String.contains?(html, "Lockspire could not load app setup tokens.")
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-summary-stat")
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-empty")
      assert String.contains?(html, ~s(phx-click="reload_iats"))

      Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
      recovered_html = render_click(view, "reload_iats")

      assert String.contains?(recovered_html, "No app setup tokens yet")
      assert inventory_counts(recovered_html) == ["0", "0", "0", "0", "0"]
    end

    test "D-06/D-07 failed revoke retains the active row and its creation context" do
      {:ok, iat, plaintext} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "partner-onboarding-review",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, view, html} = live(conn_for_admin(), "/admin/iats")
      assert_no_sensitive_text(html, [plaintext])
      assert inventory_counts(html) == ["1", "0", "0", "0", "1"]

      Application.put_env(
        :lockspire,
        :repo,
        Lockspire.Web.Live.Admin.IatLiveTest.MissingIatRepo
      )

      on_exit(fn -> Application.put_env(:lockspire, :repo, Lockspire.TestRepo) end)

      failed_html =
        render_submit(view, "confirm_revoke_iat", %{
          "revoke" => %{"id" => Integer.to_string(iat.id), "confirm" => "true"}
        })

      assert_no_sensitive_text(failed_html, [plaintext])

      assert String.contains?(
               failed_html,
               "Lockspire could not confirm revocation."
             )

      assert String.contains?(failed_html, "partner-onboarding-review")
      assert inventory_counts(failed_html) == ["1", "0", "0", "0", "1"]
      assert String.contains?(failed_html, ~s(phx-submit="confirm_revoke_iat"))
      assert length(Regex.scan(~r/Lockspire could not confirm revocation\./, failed_html)) == 1
      HtmlAssertions.assert_no_selector(failed_html, ".lockspire-admin-errors")
    end

    test "unchecked revoke shows an error only on its token row without revoking either token" do
      tokens =
        for creator <- ["first-app-intake", "second-app-intake"] do
          {:ok, token, _plaintext} =
            InitialAccessTokens.mint_iat(%{
              single_use: true,
              created_by: creator,
              expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
            })

          token
        end

      [first_token, second_token] = tokens
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats")
      confirm_error = "Select the checkbox to confirm revoking this app setup token."

      first_error_html =
        render_submit(view, "confirm_revoke_iat", %{
          "revoke" => %{"id" => Integer.to_string(first_token.id)}
        })

      assert iat_row_html(first_error_html, first_token.id) =~ confirm_error
      refute iat_row_html(first_error_html, second_token.id) =~ confirm_error

      assert length(Regex.scan(~r/Select the checkbox to confirm revoking/, first_error_html)) ==
               1

      HtmlAssertions.assert_no_selector(first_error_html, ".lockspire-admin-alert-warning")

      second_error_html =
        render_submit(view, "confirm_revoke_iat", %{
          "revoke" => %{"id" => Integer.to_string(second_token.id)}
        })

      refute iat_row_html(second_error_html, first_token.id) =~ confirm_error
      assert iat_row_html(second_error_html, second_token.id) =~ confirm_error

      assert length(Regex.scan(~r/Select the checkbox to confirm revoking/, second_error_html)) ==
               1

      {:ok, unchanged_tokens} = InitialAccessTokens.list_iats()
      assert Enum.all?(unchanged_tokens, &is_nil(&1.revoked_at))
      assert inventory_counts(second_error_html) == ["2", "0", "0", "0", "2"]

      reloaded_html = render_click(view, "reload_iats")
      refute reloaded_html =~ confirm_error

      render_submit(view, "confirm_revoke_iat", %{
        "revoke" => %{"id" => Integer.to_string(first_token.id)}
      })

      revoked_html =
        render_submit(view, "confirm_revoke_iat", %{
          "revoke" => %{"id" => Integer.to_string(second_token.id), "confirm" => "true"}
        })

      refute revoked_html =~ confirm_error
      assert inventory_counts(revoked_html) == ["1", "0", "0", "1", "2"]
      {:ok, updated_tokens} = InitialAccessTokens.list_iats()
      assert Enum.find(updated_tokens, &(&1.id == first_token.id)).revoked_at == nil
      assert Enum.find(updated_tokens, &(&1.id == second_token.id)).revoked_at != nil
    end

    test "unchecked revoke with an unknown target shows one global failure" do
      {:ok, token, _plaintext} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats")

      for params <- [
            %{"revoke" => %{"id" => Integer.to_string(token.id + 1)}},
            %{"revoke" => %{"id" => "not-an-id"}},
            %{}
          ] do
        failed_html = render_submit(view, "confirm_revoke_iat", params)

        assert length(Regex.scan(~r/Lockspire could not confirm revocation\./, failed_html)) == 1
        HtmlAssertions.assert_has_selector(failed_html, ".lockspire-admin-alert-warning")
        HtmlAssertions.assert_no_selector(failed_html, ".lockspire-admin-errors")
      end

      assert {:ok, [unchanged_token]} = InitialAccessTokens.list_iats()
      assert unchanged_token.revoked_at == nil
    end

    test "D-03/D-04/D-08/D-09/D-10 renders App setup tokens and requires inline revoke confirmation" do
      {:ok, active_iat, active_secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "operator-with-a-long-durable-intake-context-#{String.duplicate("x", 64)}",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      {:ok, expired_iat, expired_secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "expired-fixture",
          expires_at: DateTime.add(DateTime.utc_now(), -1, :day)
        })

      {:ok, used_iat, used_secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: false,
          created_by: "used-fixture",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      assert {:ok, used_iat_after_redeem} =
               Repository.redeem_initial_access_token(used_iat.token_hash, DateTime.utc_now())

      assert used_iat_after_redeem.used_at != nil

      {:ok, revoked_iat, revoked_secret} =
        InitialAccessTokens.mint_iat(%{
          single_use: true,
          created_by: "revoked-fixture",
          expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
        })

      assert :ok = InitialAccessTokens.revoke_iat(revoked_iat.id)

      denied_material =
        [
          active_secret,
          expired_secret,
          used_secret,
          revoked_secret,
          active_iat.token_hash,
          expired_iat.token_hash,
          used_iat.token_hash,
          revoked_iat.token_hash
        ] ++ forbidden_secret_samples()

      {:ok, view, html} = live(conn_for_admin(), "/admin/iats")

      HtmlAssertions.assert_page_contract!(html)
      HtmlAssertions.assert_no_duplicate_ids(html)
      HtmlAssertions.assert_describedby_targets_exist(html)
      HtmlAssertions.assert_no_generic_cta_text(html)
      HtmlAssertions.assert_has_link(html, "/admin/iats/new")
      assert_no_sensitive_text(html, denied_material)

      assert html =~ "Configure"
      assert html =~ "App setup tokens"
      assert html =~ "Token history"
      assert html =~ "Active"
      assert html =~ "Used"
      assert html =~ "Expired"
      assert html =~ "Revoked"
      assert html =~ "Total"
      assert html =~ "Single-use"
      assert html =~ "Created by"
      assert html =~ "Expires"
      assert html =~ "Last state change"
      assert html =~ "Use limit"
      assert html =~ "Revoke app setup token"
      assert html =~ ~s(phx-submit="confirm_revoke_iat")
      assert html =~ ~s(name="revoke[confirm]")
      assert html =~ "Multi-use"
      assert html =~ "expired-fixture"
      assert html =~ "used-fixture"
      assert html =~ "revoked-fixture"
      assert inventory_counts(html) == ["1", "1", "1", "1", "4"]

      assert html =~ "Apps can no longer use this token to register."

      refute html =~ ~s(data-confirm=)
      refute html =~ ~s(phx-click="revoke")
      assert html =~ "lockspire-admin-pane"
      assert html =~ "lockspire-admin-dense-resource-row"
      assert html =~ "lockspire-admin-long-value"

      html_without_confirmation =
        view
        |> element("form[phx-submit=\"confirm_revoke_iat\"]")
        |> render_submit(%{"revoke" => %{"id" => Integer.to_string(active_iat.id)}})

      assert_no_sensitive_text(html_without_confirmation, denied_material)

      assert html_without_confirmation =~
               "Select the checkbox to confirm revoking this app setup token."

      assert html_without_confirmation =~ "lockspire-admin-errors"

      {:ok, tokens_after_missing_confirmation} = InitialAccessTokens.list_iats()

      active_after_missing_confirmation =
        Enum.find(tokens_after_missing_confirmation, &(&1.id == active_iat.id))

      assert active_after_missing_confirmation.revoked_at == nil

      html_after_revoke =
        view
        |> element("form[phx-submit=\"confirm_revoke_iat\"]")
        |> render_submit(%{
          "revoke" => %{"id" => Integer.to_string(active_iat.id), "confirm" => "true"}
        })

      {:ok, tokens_after_confirmation} = InitialAccessTokens.list_iats()
      revoked_after_confirmation = Enum.find(tokens_after_confirmation, &(&1.id == active_iat.id))

      assert revoked_after_confirmation.revoked_at != nil

      assert_no_sensitive_text(html_after_revoke, denied_material)
      refute html_after_revoke =~ ~s(phx-submit="confirm_revoke_iat")
      refute html_after_revoke =~ "Revoke token</button>"
      assert html_after_revoke =~ "The app setup token was revoked."

      duplicate_revoke_html =
        render_submit(view, "confirm_revoke_iat", %{
          "revoke" => %{"id" => Integer.to_string(active_iat.id), "confirm" => "true"}
        })

      assert_no_sensitive_text(duplicate_revoke_html, denied_material)
      assert String.contains?(duplicate_revoke_html, "The app setup token was revoked.")

      assert inventory_counts(duplicate_revoke_html) == ["0", "1", "1", "2", "4"]
      refute String.contains?(duplicate_revoke_html, ~s(phx-submit="confirm_revoke_iat"))
    end
  end

  describe "New" do
    test "D-04/D-05/D-06 rejects malformed expiry before minting" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")
      before_count = iat_count()

      assert {:ok, html} =
               safe_render_submit(view, %{"single_use" => "true", "expires_in_days" => "30 days"})

      assert String.contains?(html, "Enter a whole number of days greater than zero.")
      assert String.contains?(html, ~s(value="30 days"))

      assert String.contains?(
               html,
               ~s(aria-describedby="iat_expires_in_days-help iat_expires_in_days-error")
             )

      assert String.contains?(html, ~s(role="alert" tabindex="-1"))
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
      assert iat_count() == before_count
    end

    test "D-04/D-05/D-06 rejects missing expiry before minting" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")
      before_count = iat_count()

      assert {:ok, html} = safe_render_mint(view, %{"single_use" => "true"})

      assert String.contains?(html, "Enter a whole number of days greater than zero.")
      assert String.contains?(html, ~s(id="iat_expires_in_days"))
      assert String.contains?(html, ~s(value=""))
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
      assert iat_count() == before_count
    end

    test "D-04/D-05/D-06 rejects zero expiry before minting" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")
      before_count = iat_count()

      assert {:ok, html} =
               safe_render_submit(view, %{"single_use" => "true", "expires_in_days" => "0"})

      assert String.contains?(html, "Enter a whole number of days greater than zero.")
      assert String.contains?(html, ~s(value="0"))
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
      assert iat_count() == before_count
    end

    test "D-04/D-05/D-06 rejects negative expiry before minting" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")
      before_count = iat_count()

      assert {:ok, html} =
               safe_render_submit(view, %{"single_use" => "true", "expires_in_days" => "-2"})

      assert String.contains?(html, "Enter a whole number of days greater than zero.")
      assert String.contains?(html, ~s(value="-2"))
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
      assert iat_count() == before_count
    end

    test "D-05/D-06 retains safe input and gives inline feedback when mint fails" do
      Application.put_env(
        :lockspire,
        :repo,
        Lockspire.Web.Live.Admin.IatLiveTest.FailingMintRepo
      )

      on_exit(fn -> Application.put_env(:lockspire, :repo, Lockspire.TestRepo) end)
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

      assert {:ok, html} =
               safe_render_submit(view, %{"single_use" => "true", "expires_in_days" => "14"})

      assert String.contains?(
               html,
               "Lockspire could not confirm token creation, so no value is shown. Check the app setup token list before trying again."
             )

      assert String.contains?(html, ~s(value="14"))
      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
    end

    test "D-07 preserves the 30-day and single-use mint defaults" do
      {:ok, _view, html} = live(conn_for_admin(), "/admin/iats/new")

      assert String.contains?(html, ~s(name="expires_in_days"))
      assert String.contains?(html, ~s(value="30"))
      refute String.contains?(html, ~s(name="single_use"))
      refute String.contains?(html, "Multi-use")
    end

    test "D-08 route parameter changes clear a successful one-time handoff" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

      view
      |> element("form")
      |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

      html = render_patch(view, "/admin/iats/new?refresh=1")

      HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
      assert String.contains?(html, ~s(phx-submit="mint"))
    end

    test "D-08 replayed mint event preserves the visible handoff without minting again" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")
      before_count = iat_count()
      params = %{"single_use" => "true", "expires_in_days" => "30"}

      first_html = render_submit(view, "mint", params)
      minted_count = iat_count()

      assert_handoff_rendered(first_html)
      assert minted_count == before_count + 1

      replay_html = render_submit(view, "mint", params)

      assert_handoff_rendered(replay_html)
      assert iat_count() == minted_count
      assert handoff_token_digest(replay_html) == handoff_token_digest(first_html)
    end

    test "D-06/D-07 minting an IAT is copy-once and durable inventory stays redacted" do
      {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

      # Initial state should have no secret
      initial_html = render(view)

      HtmlAssertions.assert_page_contract!(initial_html, labels: :required)
      HtmlAssertions.assert_no_duplicate_ids(initial_html)
      HtmlAssertions.assert_describedby_targets_exist(initial_html)
      HtmlAssertions.assert_label_targets_exist(initial_html)
      HtmlAssertions.assert_no_generic_cta_text(initial_html)
      HtmlAssertions.assert_no_text(initial_html, forbidden_secret_samples())

      assert initial_html =~ "Configure"
      assert initial_html =~ "Create app setup token"
      refute initial_html =~ "DCR policy"
      assert initial_html =~ "lockspire-admin-workflow-shell"
      assert initial_html =~ "iat_expires_in_days-help"
      assert initial_html =~ ~s(name="expires_in_days")
      assert initial_html =~ ~s(value="30")

      assert initial_html =~
               "The token expires after this many days. Registration rules still apply."

      assert initial_html =~
               "This token lets an app register once. It cannot access user data or manage an existing app."

      refute initial_html =~ "Registration Access Token"
      refute initial_html =~ "metadata allowlist"
      refute initial_html =~ ~s(name="metadata_allowlist")

      refute initial_html =~ "Multi-use"
      refute initial_html =~ ~s(name="single_use")
      assert initial_html =~ ~s(phx-submit="mint")
      assert initial_html =~ "Review app setup tokens"
      refute initial_html =~ "Copy this app setup token now"

      # Mint a new token
      html_after_mint =
        view
        |> element("form")
        |> render_submit(%{"expires_in_days" => "30"})

      assert_handoff_rendered(html_after_mint)
      plaintext = handoff_token(html_after_mint)
      assert {:ok, [minted_iat]} = InitialAccessTokens.list_iats()
      assert minted_iat.single_use

      # Clicking the acknowledge button
      html_after_ack =
        view
        |> element("button[phx-click=\"acknowledge_copy\"]")
        |> render_click()

      assert_handoff_cleared(html_after_ack, plaintext)

      {:ok, _index_view, inventory_html} = live(conn_for_admin(), "/admin/iats")
      assert_handoff_not_present(inventory_html, plaintext)
    end
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp iat_count do
    {:ok, iats} = InitialAccessTokens.list_iats()
    length(iats)
  end

  defp assert_no_sensitive_text(html, values) do
    if Enum.any?(values, fn value -> is_binary(value) and String.contains?(html, value) end) do
      flunk("Sensitive IAT material appeared in rendered HTML.")
    end
  end

  defp assert_handoff_rendered(html) do
    required_copy =
      Enum.all?(
        [
          "Copy this app setup token now",
          "It is shown once. Copy it now; Lockspire cannot show it again.",
          "Hide token"
        ],
        &String.contains?(html, &1)
      )

    if not required_copy or is_nil(handoff_token_digest(html)) do
      flunk("The successful IAT mint did not render its copy-once handoff.")
    end

    HtmlAssertions.assert_has_selector(html, ".lockspire-admin-copy-once-secret")
  end

  defp assert_handoff_cleared(html, token) do
    assert_handoff_not_present(html, token)

    unless String.contains?(html, "Credential hidden. It will not be shown again.") do
      flunk("The IAT handoff did not confirm that the credential was hidden.")
    end
  end

  defp assert_handoff_not_present(html, token) do
    if String.contains?(html, token) do
      flunk("The IAT plaintext remained in rendered HTML after handoff clearing.")
    end

    if String.contains?(html, "Copy this app setup token now") do
      flunk("The IAT handoff remained visible after it was cleared.")
    end

    HtmlAssertions.assert_no_selector(html, ".lockspire-admin-copy-once-secret")
  end

  defp handoff_token(html) do
    case Regex.run(~r/<code[^>]*>(?<plaintext>[^<]+)<\/code>/, html, capture: :all_names) do
      [plaintext] -> plaintext
      _ -> flunk("The successful IAT mint did not render its copy-once token value.")
    end
  end

  defp handoff_token_digest(html) do
    case Regex.run(~r/<code[^>]*>(?<plaintext>[^<]+)<\/code>/, html, capture: :all_names) do
      [plaintext] ->
        :crypto.hash(:sha256, plaintext) |> Base.encode16(case: :lower)

      _ ->
        nil
    end
  end

  defp inventory_counts(html) do
    Regex.scan(
      ~r/<span class="lockspire-admin-summary-value">([^<]+)<\/span>/,
      html,
      capture: :all_but_first
    )
    |> List.flatten()
  end

  defp iat_row_html(html, token_id) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(".lockspire-admin-dense-resource-row")
    |> Enum.map(&LazyHTML.to_html/1)
    |> Enum.find(&String.contains?(&1, ~s(id="revoke_iat_#{token_id}_confirm")))
  end

  defp safe_render_submit(view, params) do
    {:ok, view |> element("form") |> render_submit(params)}
  rescue
    exception -> {:error, exception}
  catch
    :exit, reason -> {:error, reason}
  end

  defp safe_render_mint(view, params) do
    {:ok, render_submit(view, "mint", params)}
  rescue
    exception -> {:error, exception}
  catch
    :exit, reason -> {:error, reason}
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
