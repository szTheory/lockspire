defmodule Lockspire.Web.Live.Admin.KeysLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.SigningKey
  alias Lockspire.KeyEncryptionHelpers
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.KeysLive.Index
  alias Lockspire.Web.Live.Admin.KeysLive.Protection
  alias Lockspire.Web.Live.Admin.KeysLive.Show
  alias Phoenix.Router

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    now = DateTime.utc_now()

    {:ok, active_key} =
      Repository.publish_key(
        signing_key("ui-active", :active, now,
          published_at: now,
          activated_at: now
        )
      )

    {:ok, upcoming_key} =
      Repository.publish_key(signing_key("ui-upcoming", :upcoming, now))

    {:ok, retiring_key} =
      Repository.publish_key(
        signing_key("ui-retiring", :retiring, now,
          published_at: now,
          activated_at: now,
          retiring_at: now
        )
      )

    {:ok, retired_key} =
      Repository.publish_key(
        signing_key("ui-retired", :retired, now,
          published_at: now,
          activated_at: now,
          retiring_at: now,
          retired_at: now
        )
      )

    %{
      active_key: active_key,
      upcoming_key: upcoming_key,
      retiring_key: retiring_key,
      retired_key: retired_key,
      now: now
    }
  end

  test "router exposes admin key routes" do
    routes = Router.routes(Lockspire.Web.AdminRouter)

    assert Enum.any?(routes, &live_route?(&1, "/keys", Index))
    assert Enum.any?(routes, &live_route?(&1, "/keys/:id", Show))
  end

  test "D-01/D-03/D-04/D-09/D-10 key index renders key state, safe generation grouping, and public lifecycle rows" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)

    html = rendered_to_string(Index.render(socket.assigns))

    HtmlAssertions.assert_page_contract!(html)
    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)

    assert html =~ "Configure"
    assert html =~ "Key inventory"
    refute html =~ "posture"
    assert html =~ "lockspire-admin-resource-list__item"
    assert html =~ "lockspire-admin-long-value"

    titles =
      html
      |> HtmlAssertions.document()
      |> LazyHTML.query("a.lockspire-admin-resource-list__title")
      |> Enum.map(&LazyHTML.text/1)

    assert length(titles) == 4
    assert length(Enum.uniq(titles)) == 4
    assert Enum.all?(titles, &String.starts_with?(&1, "Key "))
    assert html =~ "Active"
    assert html =~ "Prepared (upcoming)"
    assert html =~ "Retiring"
    assert html =~ "Retired"
    refute html =~ "Total keys"
    assert html =~ "lockspire-admin-action-group"

    [primary_action_group] =
      html
      |> HtmlAssertions.document()
      |> LazyHTML.query(".lockspire-admin-action-group__primary")
      |> Enum.to_list()

    assert LazyHTML.text(primary_action_group) =~ "Generate signing key"
    refute LazyHTML.text(primary_action_group) =~ "Generate encryption key"
    assert html =~ "Encryption keys"
    assert html =~ "It decrypts those requests; it does not sign tokens."
    assert html =~ "Generate encryption key"

    refute html =~ "Generation creates an upcoming key"

    assert html =~ "phx-disable-with=\"Generating signing key…\""
    assert html =~ "phx-disable-with=\"Generating encryption key…\""
    assert html =~ "Published to connected apps"
    assert html =~ "Not published to connected apps"
    assert html =~ "kid_"
    refute html =~ "ui-active"
    refute html =~ "ui-upcoming"
    refute html =~ "ui-retiring"
    refute html =~ "ui-retired"
    refute html =~ "Recommended next step"
    assert html =~ "Publish key so apps can prepare to trust it"
    assert html =~ "Retire key to stop publishing it"

    next_steps =
      html
      |> HtmlAssertions.document()
      |> LazyHTML.query(".lockspire-admin-key-record__next-step")
      |> Enum.map(&(&1 |> LazyHTML.text() |> String.trim()))

    assert next_steps != []
    assert length(next_steps) < length(titles)

    assert Enum.all?(next_steps, fn step ->
             step in [
               "Publish key so apps can prepare to trust it",
               "Activate key for connected apps to use",
               "Retire key to stop publishing it"
             ]
           end)

    refute html =~ "JWKS"

    assert html =~ "Apps"
    assert html =~ "Consents"
    assert html =~ "Tokens"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "App registration"
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)
  end

  test "key inventory distinguishes zero and one records from an unavailable read", %{now: now} do
    assert {:ok, empty_socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert empty_socket.assigns.inventory_state == :loading

    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DELETE FROM lockspire_signing_keys", [])

    assert {:noreply, empty_socket} =
             Index.handle_params(%{}, "/lockspire/admin/keys", empty_socket)

    assert empty_socket.assigns.inventory_state == :loaded
    assert empty_socket.assigns.total_keys == 0
    assert rendered_to_string(Index.render(empty_socket.assigns)) =~ "No signing keys are stored"

    {:ok, _one_key} = Repository.publish_key(signing_key("ui-single-key", :upcoming, now))

    assert {:noreply, one_socket} =
             Index.handle_params(%{}, "/lockspire/admin/keys", empty_socket)

    assert one_socket.assigns.inventory_state == :loaded
    assert one_socket.assigns.total_keys == 1
    assert length(one_socket.assigns.keys) == 1

    assert {:ok, unavailable_socket} = Index.mount(%{}, %{}, socket_for(:index))

    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])

    assert {:noreply, unavailable_socket} =
             Index.handle_params(%{}, "/lockspire/admin/keys", unavailable_socket)

    html = rendered_to_string(Index.render(unavailable_socket.assigns))

    assert unavailable_socket.assigns.inventory_state == :error
    assert is_nil(unavailable_socket.assigns.total_keys)
    assert html =~ "Could not load signing keys"
    assert html =~ "Try loading signing keys again"
    assert html =~ "phx-disable-with=\"Loading signing keys…\""
    assert html =~ "phx-disable-with=\"Loading signing keys…\""
    refute html =~ "No signing keys are stored"
    refute html =~ "Total keys"
  end

  test "generation validates its use, reports only confirmed read-back, and retains safe errors" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)
    assert socket.assigns.total_keys == 4

    assert {:noreply, socket} = Index.handle_event("generate", %{"use" => "not-an-atom"}, socket)
    assert socket.assigns.generation_error =~ "Choose signing or encryption key use"
    assert socket.assigns.total_keys == 4
    refute socket.assigns.generation_notice

    assert {:noreply, socket} = Index.handle_event("generate", %{"use" => "sig"}, socket)
    assert socket.assigns.inventory_state == :loaded
    assert socket.assigns.total_keys == 5
    assert socket.assigns.generation_notice =~ "Signing key generated"
    assert socket.assigns.generation_notice =~ "not active yet"
    assert socket.assigns.generated_key_path =~ "/admin/keys/"
    assert is_nil(socket.assigns.generation_error)

    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])

    assert {:noreply, failed_socket} =
             Index.handle_event("generate", %{"use" => "enc"}, socket)

    html = rendered_to_string(Index.render(failed_socket.assigns))
    assert failed_socket.assigns.total_keys == 5
    assert failed_socket.assigns.generation_error =~ "could not be generated"
    refute failed_socket.assigns.generation_error =~ "key-encryption key"
    refute html =~ "Signing key generated and confirmed"
    refute html =~ "Encryption key generated"
  end

  test "D-01/D-03/D-04/D-08/D-10 key detail keeps public metadata before confirmation-backed lifecycle actions",
       %{
         active_key: active_key,
         upcoming_key: upcoming_key
       } do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(upcoming_key.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(upcoming_key.id)},
               "/lockspire/admin/keys/#{upcoming_key.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    HtmlAssertions.assert_page_contract!(html)
    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)

    assert html =~ "Key status"
    assert html =~ "<h1>Key details</h1>"
    assert html =~ "Key actions"
    assert html =~ "Publish key"
    assert html =~ "Public key settings"
    assert html =~ "Next step"
    assert html =~ "Key ID"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "kid_"
    refute html =~ "Published at"
    refute html =~ "Activated at"
    refute html =~ "Retiring at"
    refute html =~ "Retired at"
    refute html =~ "Database handle"

    assert html =~
             "Publish this key so connected apps can recognize it before the signing key changes."

    assert html =~ "The current key remains active."
    refute html =~ "becomes available to verifiers"
    refute_unsupported_verifier_promise(html)
    assert html =~ "name=\"publish[confirm]\""
    assert html =~ "phx-submit=\"publish_key\""
    assert html =~ "phx-disable-with=\"Publishing key…\""
    refute html =~ "Retire key"
    refute html =~ "ui-upcoming"
    refute html =~ ~r/>\s*#{upcoming_key.id}\s*</
    assert_before(html, "Public key settings", "Key actions")
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)

    assert {:noreply, socket} = Show.handle_event("publish_key", %{}, socket)
    assert socket.assigns.action_error == "Confirm publish before changing key visibility."

    assert {:ok, unchanged_key} = Repository.fetch_signing_key_by_id(upcoming_key.id)
    assert unchanged_key.status == :upcoming
    assert is_nil(unchanged_key.published_at)

    assert {:noreply, socket} =
             Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.publishable
    assert socket.assigns.key_detail.key.handle =~ "kid_"

    assert socket.assigns.action_notice ==
             "This key is now shared with connected apps. The current signing key remains active."

    html = rendered_to_string(Show.render(socket.assigns))

    assert html =~
             "New tokens will use this key. The previous key stays available to apps while they switch."

    refute html =~ "only when verifiers can accept the cutover signer"
    refute_unsupported_verifier_promise(html)
    assert html =~ "name=\"activate[confirm]\""
    assert html =~ "phx-submit=\"activate_key\""
    assert html =~ "phx-disable-with=\"Activating key…\""
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)

    assert {:noreply, socket} =
             Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.action_error ==
             "This key is already shared with connected apps. Review its current status below."

    assert is_nil(socket.assigns.action_notice)

    assert {:noreply, socket} = Show.handle_event("activate_key", %{}, socket)

    assert socket.assigns.action_error =~
             "Confirm activation before changing which key signs new tokens."

    assert is_nil(socket.assigns.action_notice)

    assert {:ok, not_activated_key} = Repository.fetch_signing_key_by_id(upcoming_key.id)
    assert not_activated_key.status == :upcoming

    assert {:noreply, socket} =
             Show.handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :active

    assert socket.assigns.action_notice ==
             "This key now signs new tokens. The previous key remains available while apps switch."

    assert {:ok, retiring_key} = Repository.fetch_signing_key_by_id(active_key.id)
    assert retiring_key.status == :retiring

    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(active_key.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(active_key.id)},
               "/lockspire/admin/keys/#{active_key.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))
    assert html =~ "Retire key"

    assert html =~
             "Remove this key from the public list only after connected apps have switched to its replacement."

    refute_unsupported_verifier_promise(html)

    assert html =~ "name=\"retire[confirm]\""
    assert html =~ "phx-submit=\"retire_key\""
    assert html =~ "phx-disable-with=\"Retiring key…\""
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)

    assert {:noreply, socket} = Show.handle_event("retire_key", %{}, socket)

    assert socket.assigns.action_error ==
             "Confirm retirement before removing this key from the public list."

    assert {:ok, still_retiring_key} = Repository.fetch_signing_key_by_id(active_key.id)
    assert still_retiring_key.status == :retiring

    assert {:noreply, socket} =
             Show.handle_event("retire_key", %{"retire" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :retired
    assert socket.assigns.action_notice == "This key is no longer shared with connected apps."
    refute socket.assigns.key_detail.publishable
  end

  test "D-01/D-03/D-04 retired key detail is public-only and exposes no unsupported actions",
       %{retired_key: retired_key} do
    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(retired_key.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(retired_key.id)},
               "/lockspire/admin/keys/#{retired_key.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())

    assert html =~ "Key status"
    assert html =~ "Public key settings"
    refute html =~ "No further action is available"
    refute html =~ "Next step"
    refute html =~ "Key actions"
    assert html =~ "Published at"
    assert html =~ "Activated at"
    assert html =~ "Retiring at"
    assert html =~ "Retired at"
    assert html =~ "kid_"
    assert html =~ "Retired"
    assert html =~ "Published to connected apps"
    assert html =~ "<strong>No</strong>"
    refute socket.assigns.key_detail.publishable
    refute html =~ "ui-retired"
    refute html =~ "Publish key"
    refute html =~ "Activate key"
    refute html =~ "Retire key"
    refute html =~ ~s(phx-submit="publish_key")
    refute html =~ ~s(phx-submit="activate_key")
    refute html =~ ~s(phx-submit="retire_key")
    refute_forbidden_key_copy(html)
  end

  test "encryption key activation names its use without claiming a signer switch", %{now: now} do
    {:ok, encryption_key} =
      Repository.publish_key(
        signing_key("ui-upcoming-encryption", :upcoming, now,
          use: :enc,
          published_at: now
        )
      )

    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(encryption_key.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(encryption_key.id)},
               "/lockspire/admin/keys/#{encryption_key.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))

    assert html =~
             "New encrypted data will use this key. The previous key stays available to decrypt existing data."

    refute html =~ "New tokens will use this key."
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)
  end

  test "encryption key publish and activation feedback keep encryption separate from signing", %{
    now: now
  } do
    {:ok, encryption_key} =
      Repository.publish_key(signing_key("ui-unpublished-encryption", :upcoming, now, use: :enc))

    assert {:ok, socket} =
             Show.mount(%{"id" => Integer.to_string(encryption_key.id)}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(encryption_key.id)},
               "/lockspire/admin/keys/#{encryption_key.id}",
               socket
             )

    html = rendered_to_string(Show.render(socket.assigns))
    assert html =~ "<h1>Key details</h1>"
    assert html =~ "Publish this encryption key"
    assert html =~ "encrypt authorization requests"
    assert html =~ "The current encryption key remains active."
    refute html =~ "before the signing key changes"
    refute html =~ "Activate key to sign new tokens"
    refute html =~ "Published at"

    assert {:noreply, published_socket} =
             Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

    assert published_socket.assigns.key_detail.key.status == :upcoming
    assert published_socket.assigns.action_notice =~ "current encryption key remains active"
    published_html = rendered_to_string(Show.render(published_socket.assigns))
    assert published_html =~ "Published at"
    assert published_html =~ "Activate key for encrypted authorization requests"
    refute published_html =~ "Activated at"

    assert {:noreply, unchecked_socket} = Show.handle_event("activate_key", %{}, published_socket)

    assert unchecked_socket.assigns.action_error ==
             "Confirm activation before changing the active encryption key."

    assert unchecked_socket.assigns.key_detail.key.status == :upcoming

    assert {:noreply, activated_socket} =
             Show.handle_event(
               "activate_key",
               %{"activate" => %{"confirm" => "true"}},
               published_socket
             )

    assert activated_socket.assigns.key_detail.key.use == :enc
    assert activated_socket.assigns.key_detail.key.status == :active
    assert activated_socket.assigns.action_notice =~ "active for encrypted authorization requests"
    refute activated_socket.assigns.action_notice =~ "signs new tokens"
    activated_html = rendered_to_string(Show.render(activated_socket.assigns))
    assert activated_html =~ "Activated at"
    assert activated_html =~ activated_socket.assigns.action_notice
    HtmlAssertions.assert_no_text(activated_html, forbidden_key_material_samples())
  end

  test "key detail distinguishes missing from failed reads and keeps the selected key identifier",
       %{
         upcoming_key: upcoming_key
       } do
    missing_id = upcoming_key.id + 10_000
    assert {:ok, missing_socket} = Show.mount(%{"id" => missing_id}, %{}, socket_for(:show))

    assert {:noreply, missing_socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(missing_id)},
               "/lockspire/admin/keys/#{missing_id}",
               missing_socket
             )

    missing_html = rendered_to_string(Show.render(missing_socket.assigns))
    assert missing_socket.assigns.detail_state == :missing
    assert missing_html =~ "Key not found"
    assert missing_html =~ "Key ID:"
    assert missing_html =~ "Return to key inventory"
    refute missing_html =~ "Key details are unavailable"

    assert {:ok, failed_socket} =
             Show.mount(%{"id" => upcoming_key.id}, %{}, socket_for(:show))

    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])

    assert {:noreply, failed_socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(upcoming_key.id)},
               "/lockspire/admin/keys/#{upcoming_key.id}",
               failed_socket
             )

    failed_html = rendered_to_string(Show.render(failed_socket.assigns))
    assert failed_socket.assigns.detail_state == :error
    assert failed_socket.assigns.key_id == upcoming_key.id
    assert failed_html =~ "Key details are unavailable"

    assert failed_html =~ "could not load this key, so its current status is unknown."

    assert failed_html =~ "Return to key inventory"
    assert failed_html =~ "Try loading key details again"
    assert failed_html =~ "key_"
    HtmlAssertions.assert_no_text(failed_html, forbidden_key_material_samples())
  end

  test "failed lifecycle operation retains selected key and reports no success", %{
    active_key: active_key
  } do
    assert {:ok, socket} =
             Show.mount(%{"id" => active_key.id}, %{}, socket_for(:show))

    assert {:noreply, socket} =
             Show.handle_params(
               %{"id" => Integer.to_string(active_key.id)},
               "/lockspire/admin/keys/#{active_key.id}",
               socket
             )

    assert {:noreply, socket} =
             Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :active
    assert socket.assigns.key_detail.key.handle =~ "kid_"
    assert socket.assigns.action_error == "Only upcoming keys can be published."
    assert is_nil(socket.assigns.action_notice)
    html = rendered_to_string(Show.render(socket.assigns))
    assert html =~ "Only upcoming keys can be published."
    assert html =~ "Key actions"
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
  end

  describe "key protection" do
    test "key protection line names the current key-encryption key when stored keys are encrypted" do
      Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DELETE FROM lockspire_signing_keys", [])

      {:ok, _} =
        Repository.publish_key(
          Lockspire.KeyEncryptionHelpers.sealed_row("sealed-current", "test-1")
        )

      html = render_index()

      assert html =~ "Key protection"
      assert html =~ "Encrypted"

      text = protection_section(html) |> LazyHTML.text()
      assert text =~ ~s(key-encryption key "test-1")

      assert_before(html, "Key protection", "How key states work")
      refute_forbidden_key_copy(html)
    end

    test "key protection reads unknown and never healthy when the check cannot run" do
      assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
      Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])
      assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)
      html = rendered_to_string(Index.render(socket.assigns))

      assert html =~ "Unknown"
      assert html =~ "Could not load signing keys"

      section_html = protection_section(html) |> LazyHTML.to_html()
      refute section_html =~ "lockspire-admin-decision-summary__item-success"
      refute section_html =~ "Encrypted"
    end

    test "unencrypted state shows its command and keeps the key list" do
      {html, _socket} = drive_index()
      section = protection_section(html)

      assert LazyHTML.text(section) =~ "Some keys are stored unencrypted"
      assert html =~ "Key protection"
      assert html =~ "mix lockspire.keys.reencrypt"
      assert key_record_count(html) == 4
      assert_common_protection_checks(html, "")
    end

    test "older key state names only the current key-encryption key" do
      reset_keys()
      publish_sealed("sealed-current", "test-1")
      publish_sealed("sealed-older", "test-2")
      {html, _socket} = drive_index()
      section_text = protection_section(html) |> LazyHTML.text()

      assert section_text =~ "Encrypted, some with an older key-encryption key"
      assert section_text =~ "test-1"
      refute section_text =~ "test-2"
      assert html =~ "mix lockspire.keys.reencrypt"
      assert key_record_count(html) == 2
      assert_common_protection_checks(html, "test-1")
    end

    test "unreadable state shows no key-encryption key ids" do
      reset_keys()
      publish_sealed("sealed-gone", "gone-1")
      publish_sealed("sealed-wrong", "test-1", salt: "different")
      {html, _socket} = drive_index()
      section_text = protection_section(html) |> LazyHTML.text()

      assert section_text =~ "Some keys cannot be read"
      refute section_text =~ "gone-1"
      refute section_text =~ "test-1"
      assert html =~ "mix lockspire.doctor.key_encryption"
      assert key_record_count(html) == 2
      assert_common_protection_checks(html, "")
    end

    test "not set up state points at the generator and wins over unreadable" do
      publish_sealed("sealed-current", "test-1")
      KeyEncryptionHelpers.put_key_encryption(nil)
      {html, _socket} = drive_index()
      section_text = protection_section(html) |> LazyHTML.text()

      assert section_text =~ "Not set up"
      refute section_text =~ "Some keys cannot be read"
      assert html =~ "mix lockspire.gen.kek"
      assert key_record_count(html) == 5
      assert_common_protection_checks(html, "")
    end

    test "invalid setup shows setup needs attention and keeps the key list" do
      original = Application.fetch_env(:lockspire, :key_encryption)

      on_exit(fn ->
        case original do
          {:ok, value} -> Application.put_env(:lockspire, :key_encryption, value)
          :error -> Application.delete_env(:lockspire, :key_encryption)
        end
      end)

      Application.put_env(:lockspire, :key_encryption,
        keys: [{"bad", "not-base64"}],
        current: "bad"
      )

      {html, _socket} = drive_index()
      section_text = protection_section(html) |> LazyHTML.text()

      assert section_text =~ "Setup needs attention"
      refute section_text =~ "not-base64"
      refute section_text =~ "bad"
      assert html =~ "mix lockspire.doctor.key_encryption"
      assert key_record_count(html) == 4
      assert_common_protection_checks(html, "")
    end

    test "no stored keys with a key-encryption key reads encrypted above the empty state" do
      reset_keys()
      {html, _socket} = drive_index()

      assert protection_section(html) |> LazyHTML.text() =~ "Encrypted"
      assert html =~ "No signing keys are stored"
      assert_before(html, "Key protection", "No signing keys are stored")
      assert_common_protection_checks(html, "test-1")
    end

    test "unknown line renders alongside a loaded key list and is never healthy" do
      {_html, socket} = drive_index()

      socket =
        Phoenix.Component.assign(socket,
          key_protection: Protection.summarize({:error, :storage_unavailable})
        )

      html = rendered_to_string(Index.render(socket.assigns))
      section_html = protection_section(html) |> LazyHTML.to_html()

      assert section_html =~ "Unknown"
      refute section_html =~ "lockspire-admin-decision-summary__item-success"
      assert key_record_count(html) == 4
      assert_common_protection_checks(html, "")
    end

    test "a nil protection assign renders no section" do
      assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
      assert socket.assigns.key_protection == nil
      html = rendered_to_string(Index.render(socket.assigns))

      assert protection_section(html) |> Enum.count() == 0
      refute html =~ "Key protection"
    end

    test "the protection line renders above an inventory read error" do
      reset_keys()
      publish_sealed("sealed-current", "test-1")
      {_html, socket} = drive_index()
      assert socket.assigns.key_protection.state == :encrypted

      socket =
        Phoenix.Component.assign(socket,
          inventory_state: :error,
          keys: [],
          total_keys: nil,
          lifecycle_metrics: nil
        )

      html = rendered_to_string(Index.render(socket.assigns))

      assert protection_section(html) |> LazyHTML.text() =~ "Encrypted"
      assert html =~ "Could not load signing keys"
      assert_before(html, "Key protection", "Could not load signing keys")
    end

    test "the page discloses no key-encryption key material or internal field names" do
      reset_keys()
      publish_sealed("sealed-current", "test-1")
      publish_sealed("sealed-older", "test-2")
      {html, _socket} = drive_index()

      refute html =~ KeyEncryptionHelpers.config_material("test-1")
      refute html =~ KeyEncryptionHelpers.config_material("test-2")

      for denied <- [
            "configured_kek_ids",
            "by_kek_id",
            "unknown_kek",
            "LOCKSPIRE_KEY_ENCRYPTION_KEY"
          ] do
        refute html =~ denied
      end
    end

    test "a successful generate refreshes the protection line" do
      {_html, socket} = drive_index()
      assert socket.assigns.key_protection.state == :unencrypted

      reset_keys()
      assert {:noreply, socket} = Index.handle_event("generate", %{"use" => "sig"}, socket)

      assert socket.assigns.key_protection.state == :encrypted
      assert socket.assigns.generation_notice
    end
  end

  describe "missing key-encryption key" do
    test "generating a signing key without a key-encryption key explains the refusal" do
      assert_refusal("sig", "signing")
    end

    test "generating an encryption key without a key-encryption key explains the refusal" do
      assert_refusal("enc", "encryption")
    end

    test "a repeated refusal is identical and stores nothing" do
      KeyEncryptionHelpers.put_key_encryption(nil)
      {_html, socket} = drive_index()

      assert {:noreply, first} = Index.handle_event("generate", %{"use" => "sig"}, socket)
      assert {:noreply, second} = Index.handle_event("generate", %{"use" => "sig"}, first)

      assert first.assigns.generation_error == second.assigns.generation_error
      assert {:ok, keys} = Lockspire.Admin.list_keys()
      assert length(keys) == 4
    end

    test "a refusal without a key-encryption key takes precedence over a storage failure" do
      KeyEncryptionHelpers.put_key_encryption(nil)
      {_html, socket} = drive_index()

      Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])

      assert {:noreply, socket} = Index.handle_event("generate", %{"use" => "sig"}, socket)
      assert socket.assigns.generation_error =~ "No key-encryption key is set up"
      refute socket.assigns.generation_error =~ "could not be generated"
    end

    test "use validation still runs first" do
      KeyEncryptionHelpers.put_key_encryption(nil)
      {_html, socket} = drive_index()

      assert {:noreply, socket} = Index.handle_event("generate", %{}, socket)

      assert socket.assigns.generation_error =~
               "Choose signing or encryption key use before generating a key."
    end
  end

  defp assert_refusal(use, noun) do
    KeyEncryptionHelpers.put_key_encryption(nil)
    {_html, socket} = drive_index()

    assert {:noreply, socket} = Index.handle_event("generate", %{"use" => use}, socket)
    error = socket.assigns.generation_error

    assert error =~ "No key-encryption key is set up"
    assert error =~ "cannot create an #{noun} key" or error =~ "cannot create a #{noun} key"
    assert error =~ "will not store private keys unencrypted"
    assert error =~ "mix lockspire.gen.kek"
    assert is_nil(socket.assigns.generation_notice)
    assert is_nil(socket.assigns.generated_key_path)
    assert socket.assigns.total_keys == 4
    refute Map.has_key?(socket.assigns, :flash)

    html = rendered_to_string(Index.render(socket.assigns))

    alerts =
      html
      |> HtmlAssertions.document()
      |> LazyHTML.query(~s(ul.lockspire-admin-errors[role="alert"]))

    assert LazyHTML.text(alerts) =~ error

    document = HtmlAssertions.document(html)

    for u <- ["sig", "enc"] do
      button = LazyHTML.query(document, ~s(button[phx-value-use="#{u}"]))
      assert Enum.count(button) == 1
      assert LazyHTML.attribute(button, "disabled") == []
    end

    refute html =~ "LOCKSPIRE_KEY_ENCRYPTION_KEY"
    refute html =~ KeyEncryptionHelpers.config_material("test-1")
    refute_forbidden_key_copy(html)
  end

  defp drive_index do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)
    {rendered_to_string(Index.render(socket.assigns)), socket}
  end

  defp reset_keys do
    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DELETE FROM lockspire_signing_keys", [])
  end

  defp publish_sealed(kid, kek_id, opts \\ []) do
    {:ok, _} = Repository.publish_key(KeyEncryptionHelpers.sealed_row(kid, kek_id, opts))
  end

  defp key_record_count(html) do
    html
    |> HtmlAssertions.document()
    |> LazyHTML.query(".lockspire-admin-key-record")
    |> Enum.count()
  end

  defp assert_common_protection_checks(html, allowed_id) do
    refute_forbidden_key_copy(html)
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    assert_protection_is_text_only(html, allowed_id)
  end

  defp assert_protection_is_text_only(html, allowed_id) do
    section = protection_section(html)
    assert Enum.count(section) == 1

    HtmlAssertions.assert_no_interactive_controls(LazyHTML.to_html(section),
      events: ["phx-click", "phx-submit", "phx-change"]
    )

    for tag <- ["button", "a", "form", "input"] do
      assert Enum.empty?(LazyHTML.query(section, tag)), "expected no <#{tag}> in the section"
    end

    text = LazyHTML.text(section)
    text = if allowed_id == "", do: text, else: String.replace(text, allowed_id, "")
    refute text =~ ~r/\d/, "expected no digits (counts) in the protection line"
  end

  defp render_index do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)
    rendered_to_string(Index.render(socket.assigns))
  end

  defp protection_section(html) do
    html
    |> HtmlAssertions.document()
    |> LazyHTML.query(~s(section[aria-label="Key protection"]))
  end

  defp signing_key(kid, status, now, attrs \\ []) do
    attrs = Enum.into(attrs, %{})

    %SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => kid, "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: :erlang.term_to_binary(%{"kid" => kid, "d" => "private"}),
      status: status,
      inserted_at: now
    }
    |> Map.merge(attrs)
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end

  defp assert_before(html, first, second) do
    first_index = :binary.match(html, first)
    second_index = :binary.match(html, second)

    assert match?({_, _}, first_index), "expected #{inspect(first)} to be rendered"
    assert match?({_, _}, second_index), "expected #{inspect(second)} to be rendered"

    assert elem(first_index, 0) < elem(second_index, 0),
           "expected #{inspect(first)} before #{inspect(second)}"
  end

  defp refute_forbidden_key_copy(html) do
    downcased = String.downcase(html)

    for forbidden <- [
          "private jwk",
          "private_jwk",
          "export key",
          "fetch remote key",
          "force publish",
          "plaintext key"
        ] do
      refute downcased =~ forbidden, "expected no forbidden key copy #{inspect(forbidden)}"
    end
  end

  defp forbidden_key_material_samples do
    [
      "private_jwk_encrypted",
      "BEGIN PRIVATE KEY",
      "-----BEGIN",
      "export key",
      "raw key material",
      "force publish",
      "fetch remote key"
    ]
  end

  defp refute_unsupported_verifier_promise(html) do
    refute html =~ ~r/\b(?:within|after|for)\s+\d+\s+(?:seconds?|minutes?|hours?|days?)\b/i
    refute html =~ ~r/\b(?:all|every|remote)\s+verifiers?\b/i

    refute html =~
             ~r/\b(?:propagation|propagated)\s+(?:is|has|will be)\s+(?:complete|finished|done)\b/i
  end
end
