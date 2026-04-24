defmodule Lockspire.Web.Live.Admin.KeysLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository
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

    %{active_key: active_key, upcoming_key: upcoming_key}
  end

  test "router exposes admin key routes" do
    routes = Router.routes(Lockspire.Web.Router)

    assert Enum.any?(routes, &live_route?(&1, "/admin/keys", Index))
    assert Enum.any?(routes, &live_route?(&1, "/admin/keys/:id", Show))
  end

  test "key index renders lifecycle states and shared admin navigation" do
    assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
    assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)

    html = rendered_to_string(Index.render(socket.assigns))

    assert html =~ "Signing key lifecycle"
    assert html =~ "ui-active"
    assert html =~ "ui-upcoming"
    assert html =~ "Clients"
    assert html =~ "Consents"
    assert html =~ "Tokens"
    assert html =~ "Keys"
    refute html =~ "Overview"
  end

  test "key detail exposes only guided actions and advances lifecycle", %{
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

    assert html =~ "Lifecycle actions"
    assert html =~ "Publish key"
    assert html =~ "Key handle"
    assert html =~ "kid_"
    assert html =~ "Database handle"
    refute html =~ "Retire key"
    refute html =~ "ui-upcoming"
    refute html =~ ~r/>\s*#{upcoming_key.id}\s*</

    assert {:noreply, socket} =
             Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.publishable
    assert socket.assigns.key_detail.key.handle =~ "kid_"
    assert socket.assigns.action_notice == "Key published for verification overlap."

    assert {:noreply, socket} = Show.handle_event("activate_key", %{}, socket)

    assert socket.assigns.action_error =~ "Confirm activation before changing the active signer."
    assert is_nil(socket.assigns.action_notice)

    assert {:noreply, socket} =
             Show.handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket)

    assert socket.assigns.key_detail.key.status == :active

    assert {:ok, retiring_key} = Repository.fetch_signing_key_by_id(active_key.id)
    assert retiring_key.status == :retiring
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
end
