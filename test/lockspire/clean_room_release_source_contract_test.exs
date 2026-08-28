defmodule Lockspire.CleanRoomReleaseSourceContractTest do
  use ExUnit.Case, async: true

  @package_input Path.expand("../../scripts/acceptance/clean_room/package_input.py", __DIR__)
  @journey Path.expand("../../scripts/acceptance/clean_room_saas_journey.py", __DIR__)
  @provider Path.expand("../../scripts/acceptance/clean_room/build_provider.py", __DIR__)
  @wrapper Path.expand("../../scripts/acceptance/run_clean_room_saas_journey.sh", __DIR__)

  test "one explicit package source is prepared once and shared by both roles" do
    input = File.read!(@package_input)
    journey = File.read!(@journey)
    provider = File.read!(@provider)

    assert input =~ "class PackageSource"
    assert input =~ "class PackageIdentity"
    assert input =~ "def prepare_package("
    assert input =~ ":mix_hex_tarball.unpack"
    assert input =~ "mix\", \"hex.package\", \"fetch"
    assert input =~ "Lockspire package tar checksum mismatch"
    assert input =~ "Lockspire package filename and metadata versions differ"

    assert length(Regex.scan(~r/prepare_package\(run_root, selected_source\)/, journey)) == 1
    assert journey =~ "package_root=package_root"
    assert journey =~ "client_port, package_root"
    assert provider =~ "package_root: Path | None = None"
    assert input =~ "def clean_room_database_url(role: str)"
    assert provider =~ ~s|database_url = clean_room_database_url("provider")|
    refute provider =~ "postgres://postgres:postgres@127.0.0.1"
  end

  test "tar and Hex version arguments are exact, exclusive, and available through the real journey" do
    assert {help, 0} = System.cmd("python3", [@journey, "--help"], stderr_to_stdout: true)
    assert help =~ "--package-tar"
    assert help =~ "--hex-version"
    assert help =~ "--package-sha256"

    assert {message, 2} =
             System.cmd(
               "python3",
               [
                 @journey,
                 "--package-tar",
                 "one.tar",
                 "--hex-version",
                 "1.2.3",
                 "--only",
                 "happy_path"
               ],
               stderr_to_stdout: true
             )

    assert message =~ "not allowed with argument"

    input = File.read!(@package_input)
    assert input =~ ~s(r"[0-9]+\\.[0-9]+\\.[0-9]+)
    refute input =~ "latest"
  end

  test "wrapper preserves probe diagnostics and routes release proof to the real journey" do
    wrapper = File.read!(@wrapper)
    assert wrapper =~ ~s(if [[ "${1:-}" == "--probe" ]])
    assert wrapper =~ "clean_room_saas_journey.py"
    assert wrapper =~ "processes.py"
  end
end
