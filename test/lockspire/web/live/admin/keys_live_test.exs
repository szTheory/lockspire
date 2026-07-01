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
      retired_key: retired_key
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
    assert html =~ "lockspire-admin-action-group__primary"
    assert html =~ "Key generation actions"
    assert html =~ "JWKS visible"
    assert html =~ "JWKS hidden"
    assert html =~ "ui-active"
    assert html =~ "ui-upcoming"
    assert html =~ "ui-retiring"
    assert html =~ "ui-retired"
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
    assert html =~ "Publish this public key for verification overlap before activation."
    assert html =~ "name=\"publish[confirm]\""
    assert html =~ "phx-submit=\"publish_key\""
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
    assert socket.assigns.action_notice == "Key published for verification overlap."
    html = rendered_to_string(Show.render(socket.assigns))
    assert html =~ "Activate this public key only when verifiers can accept the cutover signer."
    assert html =~ "name=\"activate[confirm]\""
    assert html =~ "phx-submit=\"activate_key\""
    HtmlAssertions.assert_no_text(html, forbidden_key_material_samples())
    refute_forbidden_key_copy(html)

    assert {:noreply, socket} =
             Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.action_notice == "Key is already published for verification overlap."
    assert is_nil(socket.assigns.action_error)

    assert {:noreply, socket} = Show.handle_event("activate_key", %{}, socket)

    assert socket.assigns.action_error =~ "Confirm activation before changing the active signer."
    assert is_nil(socket.assigns.action_notice)

    assert {:ok, not_activated_key} = Repository.fetch_signing_key_by_id(upcoming_key.id)
    assert not_activated_key.status == :upcoming

    assert {:noreply, socket} =
             Show.handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :active
    assert socket.assigns.action_notice == "Key activated for signer cutover."

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
             "Retire this public key only after verifiers have moved off publication overlap."

    assert html =~ "name=\"retire[confirm]\""
    assert html =~ "phx-submit=\"retire_key\""
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
    assert socket.assigns.action_notice == "Key retired from publication overlap."
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
    refute html =~ "ui-retired"
    refute html =~ "Publish key"
    refute html =~ "Activate key"
    refute html =~ "Retire key"
    refute html =~ ~s(phx-submit="publish_key")
    refute html =~ ~s(phx-submit="activate_key")
    refute html =~ ~s(phx-submit="retire_key")
    refute_forbidden_key_copy(html)
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
end
