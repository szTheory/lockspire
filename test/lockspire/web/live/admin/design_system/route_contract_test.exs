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
end
