defmodule Lockspire.Web.Live.Admin.DesignSystem.RouteContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.RouteAssertions
  alias Lockspire.Web.AdminProof.RouteScorecards

  test "mounted admin routes cover current operator capabilities" do
    RouteAssertions.assert_mounted_routes!()
  end

  test "browser inventory remains covered by current router workflows" do
    inventory_path =
      Path.join([
        File.cwd!(),
        ".planning",
        "milestones",
        "v1.40-phases",
        "144-working-preview-and-representative-journeys",
        "144-ROUTE-INVENTORY.md"
      ])

    routes =
      inventory_path
      |> File.read!()
      |> String.split("\n")
      |> Enum.flat_map(fn line ->
        case Regex.run(~r/^\| `([^`]+)` \|/, line) do
          [_, route] -> [route]
          nil -> []
        end
      end)

    expected_routes = RouteScorecards.expected_routes()
    historical_routes = MapSet.new(routes)
    current_routes = MapSet.new(expected_routes)

    assert routes != []
    assert MapSet.subset?(historical_routes, current_routes)
  end

  test "operator documentation keeps the host and embedded-library boundary explicit" do
    RouteAssertions.assert_operator_boundary!()
  end

  test "operate routes are read-only and deny unsupported queue commands" do
    RouteAssertions.assert_read_only_operate_surfaces!()
  end

  test "configure routes retain their supported action vocabulary" do
    RouteAssertions.assert_configure_actions!()
  end

  test "operator source and documentation redact sensitive credential material" do
    RouteAssertions.assert_redaction_boundary!()
  end

  test "public package inputs exclude internal proof surfaces" do
    RouteAssertions.assert_public_package_ceiling!()
  end

  test "page hero API and admin LiveView sources carry no eyebrow" do
    component = File.read!("lib/lockspire/web/components/admin_components.ex")
    refute component =~ ~r/attr\(?\s*:eyebrow/
    refute component =~ "eyebrow"

    sources = Path.wildcard("lib/lockspire/web/live/admin/**/*.ex")
    assert sources != []

    for path <- sources do
      refute File.read!(path) =~ "eyebrow", "#{path} still references an eyebrow"
    end
  end

  test "route review matrix covers every current route exactly once with complete evidence" do
    review_path =
      Path.join([
        File.cwd!(),
        ".planning",
        "phases",
        "153-configure-support-page-refinement",
        "153-ROUTE-REVIEW.md"
      ])

    rows =
      review_path
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "| `/admin"))
      |> Enum.map(fn line ->
        line |> String.trim() |> String.trim("|") |> String.split("|") |> Enum.map(&String.trim/1)
      end)

    for cells <- rows do
      assert length(cells) == 7, "malformed review row: #{inspect(cells)}"
      assert Enum.all?(cells, &(&1 != "")), "blank evidence cell: #{inspect(cells)}"
    end

    reviewed = Enum.map(rows, fn [route | _] -> String.trim(route, "`") end)
    assert length(reviewed) == 30
    assert length(Enum.uniq(reviewed)) == 30
    assert Enum.sort(reviewed) == Enum.sort(RouteScorecards.expected_routes())
  end
end
