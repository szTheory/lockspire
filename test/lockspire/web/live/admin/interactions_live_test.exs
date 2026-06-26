defmodule Lockspire.Web.Live.Admin.InteractionsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.Live.Admin.InteractionsLive.Index
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
    expires_at = DateTime.add(now, 600, :second)

    {:ok, interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: "test-interaction-123",
        client_id: "test-client",
        status: :pending_login,
        return_to: "http://example.com/return",
        expires_at: expires_at,
        inserted_at: now,
        updated_at: now
      })

    %{interaction: interaction}
  end

  test "router exposes admin interactions routes" do
    routes = Router.routes(Lockspire.Web.Router)

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

    assert page_html =~ "Operate"
    assert page_html =~ "Authorization interaction queue"
    assert page_html =~ "Review interactions"
    assert page_html =~ "Pending login"
    assert page_html =~ "Pending consent"
    assert page_html =~ "Completed"
    assert page_html =~ "Denied"
    assert page_html =~ "Expired"
    assert page_html =~ "lockspire-admin-pane"
    assert page_html =~ "lockspire-admin-resource-list"
    assert page_html =~ "lockspire-admin-dense-resource-row"
    assert page_html =~ "lockspire-admin-long-value"
    assert page_html =~ "test-interaction-123"
    refute page_html =~ "<table"
    refute page_html =~ "lockspire-admin-table-wrap"
    refute page_html =~ "phx-click"
    refute page_html =~ "phx-submit"
    refute_unsupported_queue_controls(page_html)
    assert page_html =~ "Pending login"
  end

  test "interactions empty state names operator review without controls" do
    html =
      %{
        current_section: :interactions,
        page_title: "Active interactions",
        interactions: [],
        __changed__: %{}
      }
      |> Index.render()
      |> rendered_to_string()
      |> page_markup()

    assert html =~ "No authorization interactions waiting for review"
    assert html =~ "There are no authorization interaction records waiting for operator review."
    refute html =~ "phx-click"
    refute html =~ "phx-submit"
  end

  defp socket_for(action) do
    %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
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

  defp page_markup(html), do: Regex.replace(~r/<style>.*?<\/style>/s, html, "")
end
