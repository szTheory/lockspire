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

  test "JOSE compatibility patch is idempotent and rejects unknown source shapes" do
    script = """
    import importlib.util
    import os
    from pathlib import Path
    import sys
    import tempfile

    provider_path = Path(os.environ["LOCKSPIRE_PROVIDER_BUILDER"])
    sys.path.insert(0, str(provider_path.parent))
    spec = importlib.util.spec_from_file_location("build_provider", provider_path)
    provider = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(provider)

    with tempfile.TemporaryDirectory() as temporary:
        deps = Path(temporary)
        jose = deps / "jose"
        (jose / "include").mkdir(parents=True)
        (jose / "lib" / "jose").mkdir(parents=True)

        for module in ("jwe", "jwk", "jws", "jwt"):
            header = f"jose_{module}.hrl"
            (jose / "include" / header).write_text("record")
            (jose / "lib" / "jose" / f"{module}.ex").write_text(
                f'from_lib: "jose/include/{header}"'
            )

        environment = {"MIX_DEPS_PATH": str(deps)}
        provider.patch_jose_record_extractors(Path(temporary), environment)
        provider.patch_jose_record_extractors(Path(temporary), environment)

        jwt = jose / "lib" / "jose" / "jwt.ex"
        assert 'from: Path.expand("../../include/jose_jwt.hrl", __DIR__)' in jwt.read_text()
        jwt.write_text("unexpected extractor")

        try:
            provider.patch_jose_record_extractors(Path(temporary), environment)
        except provider.PackageInputError as error:
            assert "locked JOSE extractor shape changed: lib/jose/jwt.ex" in str(error)
        else:
            raise AssertionError("unknown JOSE source shape was accepted")
    """

    assert {_, 0} =
             System.cmd("python3", ["-c", script],
               env: [{"LOCKSPIRE_PROVIDER_BUILDER", @provider}],
               stderr_to_stdout: true
             )
  end
end
