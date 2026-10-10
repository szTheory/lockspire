defmodule Lockspire.Web.Live.Admin.KeysLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.KeysLive.Index
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

  test "D-01/D-03/D-04/D-09/D-10 key index renders posture, safe generation grouping, and public lifecycle rows" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)

    html = rendered_to_string(Index.render(socket.assigns))

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)

    assert html =~ "Configure"
    assert html =~ "Review key lifecycle"
    assert html =~ "Key lifecycle posture"
    assert html =~ "lockspire-admin-resource-list__item"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Active"
    assert html =~ "Upcoming"
    assert html =~ "Retiring"
    assert html =~ "Retired"
    assert html =~ "Total keys"
    assert html =~ "lockspire-admin-action-group"

    [primary_action_group] =
      html
      |> HtmlAssertions.document()
      |> LazyHTML.query(".lockspire-admin-action-group__primary")
      |> Enum.to_list()

    [secondary_action_group] =
      html
      |> HtmlAssertions.document()
      |> LazyHTML.query(".lockspire-admin-action-group__secondary")
      |> Enum.to_list()

    assert LazyHTML.text(primary_action_group) =~ "Generate signing key"
    refute LazyHTML.text(primary_action_group) =~ "Generate encryption key"
    assert LazyHTML.text(secondary_action_group) =~ "Generate encryption key"
    assert html =~ "Key generation actions"
    assert html =~ "phx-disable-with=\"Generating signing key…\""
    assert html =~ "phx-disable-with=\"Generating encryption key…\""
    assert html =~ "Served in JWKS"
    assert html =~ "Not served in JWKS"
    assert html =~ "kid_"
    refute html =~ "ui-active"
    refute html =~ "ui-upcoming"
    refute html =~ "ui-retiring"
    refute html =~ "ui-retired"
    assert html =~ "Next safe action"
    assert html =~ "Publish key for verification overlap"
    assert html =~ "Retire key after verifier overlap"
    assert html =~ "Clients"
    assert html =~ "Consents"
    assert html =~ "Tokens"
    assert html =~ "Keys"
    assert html =~ "Overview"
    assert html =~ "DCR"
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
    assert is_nil(socket.assigns.generation_error)

    Ecto.Adapters.SQL.query!(Lockspire.TestRepo, "DROP TABLE lockspire_signing_keys", [])

    assert {:noreply, failed_socket} =
             Index.handle_event("generate", %{"use" => "enc"}, socket)

    html = rendered_to_string(Index.render(failed_socket.assigns))
    assert failed_socket.assigns.total_keys == 5
    assert failed_socket.assigns.generation_error =~ "could not be generated"
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

    HtmlAssertions.assert_no_duplicate_ids(html)
    HtmlAssertions.assert_links_have_hrefs(html)
    HtmlAssertions.assert_no_generic_cta_text(html)
    HtmlAssertions.assert_no_token_like_text(html)

    assert html =~ "Review key lifecycle"
    assert html =~ "Lifecycle actions"
    assert html =~ "Publish key"
    assert html =~ "Public JWK metadata"
    assert html =~ "Next safe action"
    assert html =~ "Key handle"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "kid_"
    assert html =~ "Database handle"
    assert html =~ "Make this public key available for verifier overlap."
    assert html =~ "The current signing key remains active."
    refute html =~ "becomes available to verifiers"
    refute_unsupported_verifier_promise(html)
    assert html =~ "name=\"publish[confirm]\""
    assert html =~ "phx-submit=\"publish_key\""
    assert html =~ "phx-disable-with=\"Publishing key…\""
    refute html =~ "Retire key"
    refute html =~ "ui-upcoming"
    refute html =~ ~r/>\s*#{upcoming_key.id}\s*</
    assert_before(html, "Public JWK metadata", "Lifecycle actions")
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
             "Key is now served in JWKS; the current signer remains active."

    html = rendered_to_string(Show.render(socket.assigns))
    assert html =~ "Use this key to sign new tokens. The previous active key moves to retiring."
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
             "This key is already published. Review its current JWKS state below."

    assert is_nil(socket.assigns.action_notice)

    assert {:noreply, socket} = Show.handle_event("activate_key", %{}, socket)

    assert socket.assigns.action_error =~ "Confirm activation before changing the active signer."
    assert is_nil(socket.assigns.action_notice)

    assert {:ok, not_activated_key} = Repository.fetch_signing_key_by_id(upcoming_key.id)
    assert not_activated_key.status == :upcoming

    assert {:noreply, socket} =
             Show.handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :active

    assert socket.assigns.action_notice ==
             "Key is now the active signer, and the previous signer moved to retiring overlap."

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

    assert html =~ "Remove this key from the published JWKS set."
    refute html =~ "only after verifiers have moved off publication overlap"
    refute_unsupported_verifier_promise(html)

    assert html =~ "name=\"retire[confirm]\""
    assert html =~ "phx-submit=\"retire_key\""
    assert html =~ "phx-disable-with=\"Retiring key…\""
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)

    assert {:noreply, socket} = Show.handle_event("retire_key", %{}, socket)

    assert socket.assigns.action_error ==
             "Confirm retirement before removing publication overlap."

    assert {:ok, still_retiring_key} = Repository.fetch_signing_key_by_id(active_key.id)
    assert still_retiring_key.status == :retiring

    assert {:noreply, socket} =
             Show.handle_event("retire_key", %{"retire" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :retired
    assert socket.assigns.action_notice == "Key is no longer served in JWKS."
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

    assert html =~ "Review key lifecycle"
    assert html =~ "Public JWK metadata"
    assert html =~ "No lifecycle action available"
    assert html =~ "kid_"
    assert html =~ "Retired"
    assert html =~ "Not served in JWKS"
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

  test "key detail distinguishes missing from failed reads and keeps a safe selected handle", %{
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
    assert missing_html =~ "Signing key not found"
    assert missing_html =~ "Return to key inventory"
    refute missing_html =~ "Signing key details are unavailable"

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
    assert failed_html =~ "Signing key details are unavailable"
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
    assert html =~ "Key detail"
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
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
          "private key",
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
