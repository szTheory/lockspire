defmodule LockspireCompatibilityFixture.AdminHostRuntimeTest do
  use ExUnit.Case, async: false

  test "the shared host lifecycle suite runs on the exact supported floor" do
    assert Application.spec(:phoenix, :vsn) == ~c"1.8.5"
    assert Application.spec(:phoenix_live_view, :vsn) == ~c"1.1.28"

    IO.puts(
      "FLOOR_RUNTIME phoenix=#{Application.spec(:phoenix, :vsn)} " <>
        "phoenix_live_view=#{Application.spec(:phoenix_live_view, :vsn)} " <>
        "shared_files=4"
    )
  end
end

Code.require_file(Path.expand("../../../test/lockspire/web/admin_routes_compile_test.exs", __DIR__))
Code.require_file(Path.expand("../../../test/lockspire/web/admin_route_inventory_test.exs", __DIR__))
Code.require_file(Path.expand("../../../test/lockspire/web/admin_route_separation_test.exs", __DIR__))
Code.require_file(
  Path.expand("../../../test/lockspire/web/live/admin/admin_route_integration_test.exs", __DIR__)
)

ExUnit.after_suite(fn stats ->
  if stats.total <= 1 do
    raise "exact-floor shared runtime suite did not execute all original regression files"
  end

  IO.puts(
    "FLOOR_RUNTIME_SUITE phoenix=#{Application.spec(:phoenix, :vsn)} " <>
      "phoenix_live_view=#{Application.spec(:phoenix_live_view, :vsn)} tests=#{stats.total} " <>
      "failures=#{stats.failures}"
  )
end)
