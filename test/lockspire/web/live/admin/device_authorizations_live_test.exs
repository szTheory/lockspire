defmodule Lockspire.Web.Live.Admin.DeviceAuthorizationsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest
  import Phoenix.ConnTest

  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index

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

    now = DateTime.utc_now()

    {:ok, _auth} =
      Repository.put_device_authorization(%DeviceAuthorization{
        device_code_hash: "hash1",
        user_code_hash: "hash2",
        verification_handle: "handle1",
        client_id: "test-client",
        status: :pending,
        effective_poll_interval_seconds: 5,
        next_poll_allowed_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    :ok
  end

  test "router exposes admin device authorizations" do
    routes = Phoenix.Router.routes(Lockspire.Web.Router)
    assert Enum.any?(routes, &live_route?(&1, "/admin/device_authorizations", Index))
  end

  test "device authorizations index renders operate queue rows without code material" do
    assert {:ok, _view, html} = live(conn_for_admin(), "/admin/device_authorizations")

    assert html =~ "Operate"
    assert html =~ "Device authorization queue"
    assert html =~ "Review device authorizations"
    assert html =~ "Pending"
    assert html =~ "Approved"
    assert html =~ "Denied"
    assert html =~ "Expired"
    assert html =~ "Completed"
    assert html =~ "lockspire-admin-pane"
    assert html =~ "lockspire-admin-resource-list"
    assert html =~ "lockspire-admin-dense-resource-row"
    assert html =~ "lockspire-admin-long-value"
    assert html =~ "Device authorization"
    refute html =~ "hash1"
    refute html =~ "hash2"
    refute html =~ "device_code"
    refute html =~ "user_code"
    refute html =~ "test-client"
    refute html =~ "client_secret"
    refute html =~ "phx-click"
    refute html =~ "phx-submit"

    refute_unsupported_queue_controls(html)
  end

  test "device authorization empty state names operator review without controls" do
    html =
      %{
        current_section: :device_authorizations,
        page_title: "Device Authorizations",
        device_authorizations: [],
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()

    assert html =~ "No device authorizations waiting for review"
    assert html =~ "There are no device authorization records waiting for operator review."
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
  end

  defp conn_for_admin do
    Phoenix.ConnTest.build_conn()
  end

  defp live_route?(route, path, view) do
    route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
  end

  defp refute_unsupported_queue_controls(html) do
    refute Regex.match?(
             ~r/\b(Retry|Discard|Approve|Deny|Logout now|Worker control|Requeue)\b/i,
             html
           )
  end
end
