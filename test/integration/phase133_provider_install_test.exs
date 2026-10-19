defmodule Lockspire.Integration.Phase133ProviderInstallTest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @moduletag :phase133
  @moduletag :package_clean
  @tag timeout: 180_000

  @builder Path.expand("../../scripts/acceptance/clean_room/build_provider.py", __DIR__)

  test "a clean provider installs through public seams and proves its package boundary" do
    assert {output, 0} = System.cmd("python3", [@builder, "--self-test"], stderr_to_stdout: true)

    assert output =~ "provider installation verified"
    assert output =~ "provider discovery verified"
    assert output =~ "provider boundary verified"
    refute output =~ "phase133-bearer-client-secret-sentinel"
    refute output =~ "phase133-dpop-client-secret-sentinel"
  end

  test "provider bootstrap keeps bearer and DPoP enrollment independently bounded" do
    assert {output, 0} =
             System.cmd("python3", [@builder, "--check-bootstrap"], stderr_to_stdout: true)

    assert output =~ "provider bootstrap verified"
    assert output =~ "separate secret handoffs verified"
    assert output =~ "protected pipeline verified"
    refute output =~ "phase133-bearer-client-secret-sentinel"
    refute output =~ "phase133-dpop-client-secret-sentinel"
  end

  test "fresh provider migrations use the explicit generated path" do
    builder = File.read!(@builder)

    assert builder =~
             ~s("ecto.migrate",\n                "--migrations-path",\n                "priv/repo/migrations")
  end

  @tag :gen_kek
  @tag timeout: 600_000
  test "gen.kek prints a valid key in a host whose runtime config raises without one" do
    assert {output, 0} =
             System.cmd("python3", [@builder, "--check-gen-kek"], stderr_to_stdout: true)

    assert output =~ "gen.kek cold run verified"
    assert output =~ "host runtime fails closed without the key"
    refute Regex.match?(~r/[A-Za-z0-9+\/]{43}=/, output)
  end
end
