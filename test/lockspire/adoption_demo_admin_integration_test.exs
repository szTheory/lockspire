defmodule Lockspire.AdoptionDemoAdminIntegrationTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @router_path Path.join(
                 @repo_root,
                 "examples/adoption_demo/lib/adoption_demo_web/router.ex"
               )

  test "demo router delegates its admin inventory to the canonical native route macro" do
    source = File.read!(@router_path)

    assert source =~ "Lockspire.Web.AdminRoutes.lockspire_admin_routes(\"/lockspire/admin\""
    refute source =~ "Phoenix.LiveView.Router.live"
    refute source =~ "Lockspire.Web.AdminRouter"
  end
end
