defmodule Lockspire.ReleaseArtifactChainContractTest do
  use ExUnit.Case, async: true

  @tool Path.expand("../../scripts/publish/release_artifact.py", __DIR__)
  @publisher Path.expand("../../scripts/publish/publish_hex_idempotently.sh", __DIR__)
  @verifier Path.expand("../../scripts/publish/verify_install_truth.sh", __DIR__)

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-release-artifact-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    version = Mix.Project.config()[:version]
    tarball = Path.join(root, "lockspire-#{version}.tar")
    manifest = Path.join(root, "manifest.json")
    File.write!(tarball, "deterministic-package-bytes")
    source_sha = String.duplicate("a", 40)

    assert {_output, 0} =
             System.cmd(
               "python3",
               [
                 @tool,
                 "create",
                 "--tar",
                 tarball,
                 "--source-sha",
                 source_sha,
                 "--output",
                 manifest
               ],
               stderr_to_stdout: true
             )

    %{root: root, tarball: tarball, manifest: manifest, source_sha: source_sha}
  end

  test "manifest binds exact tar, source, version, and allowlisted runtime", context do
    assert {_output, 0} = verify_local(context)
    payload = Jason.decode!(File.read!(context.manifest))

    assert Map.keys(payload) |> Enum.sort() ==
             ~w(artifact package runtime schema_version source_sha version)

    assert payload["package"] == "lockspire"
    assert payload["source_sha"] == context.source_sha
    assert payload["artifact"]["filename"] == Path.basename(context.tarball)
    assert payload["artifact"]["sha256"] == sha256(context.tarball)

    assert Map.keys(payload["runtime"]) |> Enum.sort() ==
             ~w(elixir hex mix otp phoenix phoenix_live_view postgresql)

    refute File.read!(context.manifest) =~ System.tmp_dir!()
    refute File.read!(context.manifest) =~ "token"
    refute File.read!(context.manifest) =~ "secret"
  end

  test "local drift, source substitution, and schema extension fail closed", context do
    File.write!(context.tarball, "replacement", [:append])
    assert {message, 1} = verify_local(context)
    assert message =~ "release artifact"

    File.write!(context.tarball, "deterministic-package-bytes")

    assert {message, 1} =
             System.cmd(
               "python3",
               [
                 @tool,
                 "verify-local",
                 "--tar",
                 context.tarball,
                 "--manifest",
                 context.manifest,
                 "--source-sha",
                 String.duplicate("b", 40)
               ],
               stderr_to_stdout: true
             )

    assert message =~ "source SHA mismatch"

    payload = Jason.decode!(File.read!(context.manifest)) |> Map.put("token", "unsafe")
    File.write!(context.manifest, Jason.encode!(payload))
    assert {message, 1} = verify_local(context)
    assert message =~ "allowlist"
  end

  test "Hex verification requires the same exact version and checksum", context do
    payload = Jason.decode!(File.read!(context.manifest))
    response = Path.join(context.root, "hex.json")

    File.write!(
      response,
      Jason.encode!(%{
        version: payload["version"],
        checksum: payload["artifact"]["sha256"],
        has_docs: true
      })
    )

    assert {_output, 0} =
             System.cmd(
               "python3",
               [@tool, "verify-hex", "--manifest", context.manifest, "--response", response],
               stderr_to_stdout: true
             )

    File.write!(
      response,
      Jason.encode!(%{version: payload["version"], checksum: String.duplicate("0", 64)})
    )

    assert {message, 1} =
             System.cmd(
               "python3",
               [@tool, "verify-hex", "--manifest", context.manifest, "--response", response],
               stderr_to_stdout: true
             )

    assert message =~ "Hex release checksum mismatch"
  end

  test "publisher and verifier carry manifest identity into exact public HTTP proof" do
    publisher = File.read!(@publisher)
    verifier = File.read!(@verifier)

    assert publisher =~ "release_artifact.py verify-local"
    assert publisher =~ "cmp -s"
    assert publisher =~ "release_artifact.py verify-hex"
    assert verifier =~ "packages/lockspire/releases/$EXPECTED_VERSION"
    assert verifier =~ "--hex-version \"$EXPECTED_VERSION\""
    assert verifier =~ "--package-sha256 \"$EXPECTED_CHECKSUM\""
    assert verifier =~ "--only happy_path"
    refute verifier =~ "mix phx.new"
  end

  defp verify_local(context) do
    System.cmd(
      "python3",
      [
        @tool,
        "verify-local",
        "--tar",
        context.tarball,
        "--manifest",
        context.manifest,
        "--source-sha",
        context.source_sha
      ],
      stderr_to_stdout: true
    )
  end

  defp sha256(path) do
    :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
  end
end
