defmodule Lockspire.ReleaseArtifactChainContractTest do
  use ExUnit.Case, async: true

  @tool Path.expand("../../scripts/publish/release_artifact.py", __DIR__)
  @publisher Path.expand("../../scripts/publish/publish_hex_idempotently.sh", __DIR__)
  @uploader Path.expand("../../scripts/publish/upload_hex_artifact.exs", __DIR__)
  @upload_fixture Path.expand("../support/hex_release_upload_fixture.py", __DIR__)
  @verifier Path.expand("../../scripts/publish/verify_install_truth.sh", __DIR__)
  @tag_target_verifier Path.expand(
                         "../../scripts/publish/verify_github_release_target.sh",
                         __DIR__
                       )
  @tag_guard Path.expand("../../scripts/publish/release_tag_guard.sh", __DIR__)

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
    create_valid_tarball!(tarball, version)
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
    assert payload["runtime"]["publisher_hex"] == payload["runtime"]["hex"]

    assert Map.keys(payload["runtime"]) |> Enum.sort() ==
             ~w(elixir hex mix otp phoenix phoenix_live_view postgresql publisher_hex)

    refute File.read!(context.manifest) =~ System.tmp_dir!()
    refute File.read!(context.manifest) =~ "token"
    refute File.read!(context.manifest) =~ "secret"
  end

  test "local drift, source substitution, and schema extension fail closed", context do
    File.write!(context.tarball, "replacement", [:append])
    assert {message, 1} = verify_local(context)
    assert message =~ "release artifact"

    original = Jason.decode!(File.read!(context.manifest))
    File.write!(context.tarball, String.duplicate("x", original["artifact"]["bytes"]))

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

  test "manifest rejects boolean byte counts", context do
    File.write!(context.tarball, "x")
    payload = Jason.decode!(File.read!(context.manifest))
    payload = put_in(payload["artifact"]["bytes"], true)
    payload = put_in(payload["artifact"]["sha256"], sha256(context.tarball))
    File.write!(context.manifest, Jason.encode!(payload))

    assert {message, 1} = verify_local(context)
    assert message =~ "release artifact size is invalid"
  end

  test "manifest rejects boolean schema versions", context do
    payload = Jason.decode!(File.read!(context.manifest))
    payload = Map.put(payload, "schema_version", true)
    File.write!(context.manifest, Jason.encode!(payload))

    assert {message, 1} = verify_local(context)
    assert message =~ "release manifest schema version is invalid"
  end

  test "release tag guard locks, creates, verifies, and cleans up one exact tag", context do
    {remote, source_sha, _other_sha, _blob_sha} = create_tag_remote!(context.root)
    bin = Path.join(context.root, "tag-guard-bin")
    ruleset_path = Path.join(context.root, "tag-freeze.json")
    output_path = Path.join(context.root, "tag-guard-output")
    File.mkdir_p!(bin)

    File.write!(Path.join(bin, "git"), tag_guard_git_wrapper())
    File.write!(Path.join(bin, "gh"), tag_guard_gh_wrapper())
    File.chmod!(Path.join(bin, "git"), 0o755)
    File.chmod!(Path.join(bin, "gh"), 0o755)

    env = [
      {"PATH", bin <> ":" <> System.get_env("PATH", "")},
      {"GH_TOKEN", "fixture-token"},
      {"REF_CREATE_TOKEN", "fixture-write-token"},
      {"GH_REPO", "lockspire/fixture"},
      {"GITHUB_SERVER_URL", "https://github.com"},
      {"GITHUB_OUTPUT", output_path},
      {"REAL_GIT", System.find_executable("git") || raise("git is required")},
      {"FAKE_GIT_REMOTE", remote},
      {"FAKE_RULESET_STATE", ruleset_path}
    ]

    assert {output, 0} =
             System.cmd(
               "bash",
               [@tag_guard, "create", "lockspire-v1.5.1"],
               env: env,
               stderr_to_stdout: true
             )

    assert output =~ "protected against update and deletion"
    assert File.read!(output_path) =~ "ruleset_id=42"

    ruleset = Jason.decode!(File.read!(ruleset_path))
    assert ruleset["target"] == "tag"
    assert ruleset["bypass_actors"] == []
    assert Enum.map(ruleset["rules"], & &1["type"]) |> Enum.sort() == ["deletion", "update"]
    assert Enum.find(ruleset["rules"], &(&1["type"] == "update")) == %{"type" => "update"}

    explicit_false_ruleset =
      Map.update!(ruleset, "rules", fn rules ->
        Enum.map(rules, fn rule ->
          if rule["type"] == "update",
            do: Map.put(rule, "parameters", %{"update_allows_fetch_and_merge" => false}),
            else: rule
        end)
      end)

    File.write!(ruleset_path, Jason.encode!(explicit_false_ruleset))

    assert {output, 0} =
             System.cmd(
               "bash",
               [@tag_guard, "ensure", "42", "lockspire-v1.5.1", source_sha],
               env: env,
               stderr_to_stdout: true
             )

    assert output =~ "resolves to verified commit #{source_sha}"

    assert {tag_sha, 0} =
             System.cmd("git", ["--git-dir", remote, "rev-parse", "refs/tags/lockspire-v1.5.1"])

    assert String.trim(tag_sha) == source_sha

    explicit_true_ruleset =
      Map.update!(ruleset, "rules", fn rules ->
        Enum.map(rules, fn rule ->
          if rule["type"] == "update",
            do: Map.put(rule, "parameters", %{"update_allows_fetch_and_merge" => true}),
            else: rule
        end)
      end)

    File.write!(ruleset_path, Jason.encode!(explicit_true_ruleset))

    assert {output, 1} =
             System.cmd(
               "bash",
               [@tag_guard, "preflight", "42", "lockspire-v1.5.1", source_sha],
               env: env,
               stderr_to_stdout: true
             )

    assert output =~ "tag freeze is not the exact active no-bypass update/deletion lock"
    File.write!(ruleset_path, Jason.encode!(ruleset))

    assert {output, 0} =
             System.cmd(
               "bash",
               [@tag_guard, "preflight", "42", "lockspire-v1.5.1", source_sha],
               env: env,
               stderr_to_stdout: true
             )

    assert output =~ "remains protected at verified SHA"

    assert {output, 0} =
             System.cmd(
               "bash",
               [@tag_guard, "delete", "42", "lockspire-v1.5.1"],
               env: env,
               stderr_to_stdout: true
             )

    assert output =~ "removed temporary release tag freeze 42"
  end

  test "manifest publisher Hex version must match the builder Hex version", context do
    payload = Jason.decode!(File.read!(context.manifest))
    payload = put_in(payload["runtime"]["publisher_hex"], "2.0.0")
    File.write!(context.manifest, Jason.encode!(payload))

    assert {message, 1} = verify_local(context)
    assert message =~ "publisher Hex version differs from builder Hex version"
  end

  test "prepublish receipt records successful manifest-bound publisher compatibility", context do
    payload = Jason.decode!(File.read!(context.manifest))
    receipt = Path.join(context.root, "prepublish-receipt.json")

    assert {_output, 0} =
             System.cmd(
               "python3",
               [
                 @tool,
                 "receipt",
                 "--manifest",
                 context.manifest,
                 "--stage",
                 "prepublish",
                 "--output",
                 receipt,
                 "--publisher-hex-version",
                 payload["runtime"]["hex"],
                 "--publisher-api-export",
                 "true",
                 "--exact-byte-fixture",
                 "true"
               ],
               stderr_to_stdout: true
             )

    assert Jason.decode!(File.read!(receipt))["publisher_compatibility"] == %{
             "hex_version" => payload["runtime"]["hex"],
             "api_export" => true,
             "exact_byte_fixture" => true
           }

    assert {message, 1} =
             System.cmd(
               "python3",
               [
                 @tool,
                 "receipt",
                 "--manifest",
                 context.manifest,
                 "--stage",
                 "prepublish",
                 "--output",
                 receipt,
                 "--publisher-hex-version",
                 "2.0.0",
                 "--publisher-api-export",
                 "true",
                 "--exact-byte-fixture",
                 "true"
               ],
               stderr_to_stdout: true
             )

    assert message =~ "publisher compatibility version differs from the manifest"
  end

  test "terminal receipt records complete public verification with deterministic manifest identity",
       context do
    state = terminal_state(context)
    receipt = Path.join(context.root, "terminal-receipt.json")

    assert {_output, 0} = write_terminal_receipt(context, state, receipt)
    payload = Jason.decode!(File.read!(receipt))

    assert payload["workflow_run_id"] == "991001"
    assert payload["source_sha"] == context.source_sha
    assert payload["ci_run_id"] == "991000"
    assert payload["version"] == Mix.Project.config()[:version]

    assert payload["manifest"] == %{
             "sha256" => sha256_bytes(File.read!(context.manifest)),
             "state" => "passed"
           }

    assert payload["artifact"] == %{
             "sha256" => Jason.decode!(File.read!(context.manifest))["artifact"]["sha256"],
             "state" => "passed"
           }

    assert payload["stages"] == %{
             "candidate" => "passed",
             "artifact" => "passed",
             "prepublish" => "passed",
             "hex_publish" => "passed",
             "github_release" => "passed",
             "tag" => "passed",
             "docs" => "passed",
             "install" => "passed"
           }

    assert payload["observations"]["hex_presence"] == "present"
    assert payload["observations"]["hex_checksum"] == payload["artifact"]["sha256"]
    assert payload["observations"]["tag_target_sha"] == context.source_sha
    assert payload["release_verified"]
    assert payload["blocker"] == "none"
    assert payload["next_safe_action"] == "none"

    second_receipt = Path.join(context.root, "terminal-receipt-second.json")
    assert {_output, 0} = write_terminal_receipt(context, state, second_receipt)
    assert File.read!(second_receipt) == File.read!(receipt)
  end

  test "terminal receipt keeps Hex public truth when later release proof fails", context do
    state = terminal_state(context)
    stages = put_in(state["stages"]["github_release"], "failed")
    stages = put_in(stages["stages"]["tag"], "not_run")
    stages = put_in(stages["stages"]["docs"], "not_run")
    stages = put_in(stages["stages"]["install"], "not_run")
    observations = put_in(stages["observations"]["github_release_presence"], "absent")
    observations = put_in(observations["observations"]["install_result"], "not_run")
    receipt = Path.join(context.root, "partial-terminal-receipt.json")

    assert {_output, 0} = write_terminal_receipt(context, observations, receipt)
    payload = Jason.decode!(File.read!(receipt))

    assert payload["observations"]["hex_presence"] == "present"
    assert payload["stages"]["hex_publish"] == "passed"
    assert payload["release_verified"] == false
    assert payload["blocker"] == "github_release_missing"
    assert payload["next_safe_action"] == "retry_same_artifact_before_expiry"
  end

  test "terminal receipt records prepublish stages as not run when no manifest exists", context do
    state = terminal_state(context)
    state = put_in(state["stages"]["artifact"], "not_run")
    state = put_in(state["stages"]["prepublish"], "not_run")
    state = put_in(state["stages"]["hex_publish"], "not_run")
    state = put_in(state["stages"]["github_release"], "not_run")
    state = put_in(state["stages"]["tag"], "not_run")
    state = put_in(state["stages"]["docs"], "not_run")
    state = put_in(state["stages"]["install"], "not_run")
    state = put_in(state["observations"]["hex_presence"], "absent")
    state = put_in(state["observations"]["hex_checksum"], nil)
    state = put_in(state["observations"]["github_release_presence"], "absent")
    state = put_in(state["observations"]["docs_presence"], "unknown")
    state = put_in(state["observations"]["tag_target_sha"], nil)
    state = put_in(state["observations"]["install_result"], "not_run")
    receipt = Path.join(context.root, "not-run-terminal-receipt.json")

    assert {_output, 0} = write_terminal_receipt(context, state, receipt, manifest: false)
    payload = Jason.decode!(File.read!(receipt))

    assert payload["manifest"] == %{"sha256" => nil, "state" => "not_run"}
    assert payload["artifact"] == %{"sha256" => nil, "state" => "not_run"}
    assert payload["stages"]["prepublish"] == "not_run"
    assert payload["release_verified"] == false
  end

  test "terminal receipt preserves unknown public observations without inferring success",
       context do
    state = terminal_state(context)
    state = put_in(state["stages"]["hex_publish"], "unknown")
    state = put_in(state["stages"]["github_release"], "unknown")
    state = put_in(state["stages"]["tag"], "unknown")
    state = put_in(state["stages"]["docs"], "unknown")
    state = put_in(state["stages"]["install"], "unknown")
    state = put_in(state["observations"]["hex_presence"], "unknown")
    state = put_in(state["observations"]["hex_checksum"], nil)
    state = put_in(state["observations"]["public_latest_version"], nil)
    state = put_in(state["observations"]["github_release_presence"], "unknown")
    state = put_in(state["observations"]["docs_presence"], "unknown")
    state = put_in(state["observations"]["tag_target_sha"], nil)
    state = put_in(state["observations"]["install_result"], "unknown")
    receipt = Path.join(context.root, "unknown-terminal-receipt.json")

    assert {_output, 0} = write_terminal_receipt(context, state, receipt)
    payload = Jason.decode!(File.read!(receipt))

    assert payload["observations"]["hex_presence"] == "unknown"
    assert payload["observations"]["github_release_presence"] == "unknown"
    assert payload["stages"]["hex_publish"] == "unknown"
    assert payload["stages"]["github_release"] == "unknown"
    assert payload["release_verified"] == false
  end

  test "terminal receipt treats an unavailable Hex checksum as unknown", context do
    state = put_in(terminal_state(context)["observations"]["hex_checksum"], nil)
    receipt = Path.join(context.root, "missing-hex-checksum-receipt.json")

    assert {_output, 0} = write_terminal_receipt(context, state, receipt)
    payload = Jason.decode!(File.read!(receipt))

    assert payload["observations"]["hex_presence"] == "present"
    assert payload["observations"]["hex_checksum"] == nil
    assert payload["stages"]["hex_publish"] == "unknown"
    assert payload["blocker"] == "hex_checksum_unknown"
    assert payload["release_verified"] == false
  end

  test "terminal receipt rejects unknown fields and stage values", context do
    receipt = Path.join(context.root, "invalid-terminal-receipt.json")
    unknown_field = Map.put(terminal_state(context), "unexpected", "value")

    assert {message, 1} = write_terminal_receipt(context, unknown_field, receipt)
    assert message =~ "fields differ from the allowlist"

    invalid_stage = put_in(terminal_state(context)["stages"]["tag"], "maybe")
    assert {message, 1} = write_terminal_receipt(context, invalid_stage, receipt)
    assert message =~ "stage state is invalid"
  end

  test "terminal receipt binds its workflow run identity to the current invocation", context do
    state = put_in(terminal_state(context)["workflow_run_id"], "991002")
    receipt = Path.join(context.root, "mismatched-terminal-receipt.json")

    assert {message, 1} = write_terminal_receipt(context, state, receipt)
    assert message =~ "workflow run identity mismatch"
    refute File.exists?(receipt)
  end

  test "terminal receipt rejects secret-bearing input without echoing the value", context do
    secret = "ghp_abcdefghijklmnopqrstuvwxyz123456"
    state = put_in(terminal_state(context)["version"], secret)
    receipt = Path.join(context.root, "secret-terminal-receipt.json")

    assert {message, 1} = write_terminal_receipt(context, state, receipt)
    assert message =~ "credential-like value"
    refute message =~ secret
    refute File.exists?(receipt)
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
    uploader = File.read!(@uploader)
    verifier = File.read!(@verifier)

    assert publisher =~ "release_artifact.py verify-local"
    assert publisher =~ "upload_hex_artifact.exs \"$package_tar\""
    assert publisher =~ "release_artifact.py verify-hex"
    assert uploader =~ "bytes = File.read!(tarball)"
    assert uploader =~ ~s(Hex.API.Release.publish("hexpm", bytes)
    refute publisher =~ "mix hex.publish --yes"
    assert verifier =~ "packages/lockspire/releases/$EXPECTED_VERSION"
    assert verifier =~ "--hex-version \"$EXPECTED_VERSION\""
    assert verifier =~ "--package-sha256 \"$EXPECTED_CHECKSUM\""
    assert verifier =~ "--only happy_path"
    refute verifier =~ "mix phx.new"
  end

  test "exact-artifact uploader sends the supplied tar bytes without rebuilding", context do
    captured = Path.join(context.root, "captured-release.tar")

    port =
      Port.open(
        {:spawn_executable, System.find_executable("python3")},
        [:binary, :exit_status, args: [@upload_fixture, captured], line: 1024]
      )

    assert_receive {^port, {:data, {:eol, port_line}}}, 2_000
    api_url = "http://127.0.0.1:#{String.trim(port_line)}"

    assert {output, 0} =
             System.cmd(
               "elixir",
               [@uploader, context.tarball],
               env: [{"HEX_API_URL", api_url}, {"HEX_API_KEY", "fixture-key"}],
               stderr_to_stdout: true
             )

    assert output =~ "Exact release artifact accepted by Hex"
    assert_receive {^port, {:exit_status, 0}}, 2_000
    assert File.read!(captured) == File.read!(context.tarball)
    manifest = Jason.decode!(File.read!(context.manifest))
    assert File.stat!(captured).size == manifest["artifact"]["bytes"]
    assert sha256(captured) == manifest["artifact"]["sha256"]
  end

  test "GitHub release target verification accepts exact lightweight and annotated tags",
       context do
    {remote, source_sha, _other_sha, _blob_sha} = create_tag_remote!(context.root)

    assert {output, 0} =
             verify_github_release_target(remote, "lockspire-v1.5.1-lightweight", source_sha)

    assert output =~ source_sha

    assert {output, 0} =
             verify_github_release_target(remote, "lockspire-v1.5.1-annotated", source_sha)

    assert output =~ source_sha
  end

  test "GitHub release target verification rejects missing and mismatched refs", context do
    {remote, source_sha, other_sha, _blob_sha} = create_tag_remote!(context.root)

    assert {output, 1} = verify_github_release_target(remote, "missing", source_sha)
    assert output =~ "tag ref"

    assert {output, 1} =
             verify_github_release_target(remote, "lockspire-v1.5.1-mismatch", source_sha)

    assert output =~ "not verified source"
    assert output =~ other_sha
  end

  test "prepublish tag verification permits an absent ref only in if-present mode", context do
    {remote, source_sha, _other_sha, _blob_sha} = create_tag_remote!(context.root)

    assert {output, 0} =
             verify_github_release_target(remote, "missing", source_sha, ["--if-present"])

    assert output =~ "prepublish tag check passed"
  end

  test "GitHub release target verification rejects malformed SHA and non-commit tag targets",
       context do
    {remote, source_sha, _other_sha, _blob_sha} = create_tag_remote!(context.root)

    assert {output, 1} =
             verify_github_release_target(remote, "lockspire-v1.5.1-lightweight", "not-a-sha")

    assert output =~ "40-character"

    assert {output, 1} = verify_github_release_target(remote, "lockspire-v1.5.1-blob", source_sha)
    assert output =~ "not verified source"
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

  defp terminal_state(context) do
    manifest = Jason.decode!(File.read!(context.manifest))

    %{
      "schema_version" => 1,
      "workflow_run_id" => "991001",
      "source_sha" => context.source_sha,
      "ci_run_id" => "991000",
      "package" => "lockspire",
      "version" => manifest["version"],
      "stages" => %{
        "candidate" => "passed",
        "artifact" => "passed",
        "prepublish" => "passed",
        "hex_publish" => "passed",
        "github_release" => "passed",
        "tag" => "passed",
        "docs" => "passed",
        "install" => "passed"
      },
      "observations" => %{
        "hex_presence" => "present",
        "hex_checksum" => manifest["artifact"]["sha256"],
        "public_latest_version" => manifest["version"],
        "github_release_presence" => "present",
        "tag_target_sha" => context.source_sha,
        "docs_presence" => "present",
        "install_result" => "passed"
      }
    }
  end

  defp write_terminal_receipt(context, state, receipt, opts \\ []) do
    state_path = Path.join(context.root, "terminal-state.json")
    File.write!(state_path, Jason.encode!(state))

    args = [
      @tool,
      "terminal-receipt",
      "--input",
      state_path,
      "--output",
      receipt,
      "--workflow-run-id",
      "991001"
    ]

    args =
      if Keyword.get(opts, :manifest, true),
        do: args ++ ["--manifest", context.manifest],
        else: args

    System.cmd("python3", args, stderr_to_stdout: true)
  end

  defp verify_github_release_target(remote, tag, source_sha, extra_args \\ []) do
    System.cmd(
      "bash",
      [@tag_target_verifier, tag, remote, source_sha] ++ extra_args,
      stderr_to_stdout: true
    )
  end

  defp tag_guard_git_wrapper do
    """
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "${1:-}" == ls-remote ]]; then
      shift
      exec "$REAL_GIT" ls-remote "$FAKE_GIT_REMOTE" "$@"
    fi
    exec "$REAL_GIT" "$@"
    """
  end

  defp tag_guard_gh_wrapper do
    """
    #!/usr/bin/env bash
    set -euo pipefail
    request="$*"

    list_rulesets() {
      if [[ -f "$FAKE_RULESET_STATE" ]]; then
        jq -n --slurpfile ruleset "$FAKE_RULESET_STATE" '[$ruleset]'
      else
        printf '[[]]\\n'
      fi
    }

    if [[ "$request" == *"api --paginate --slurp repos/lockspire/fixture/rulesets?per_page=100"* ]]; then
      list_rulesets
    elif [[ "$request" == *"api repos/lockspire/fixture/rulesets/42?includes_parents=false"* ]]; then
      cat "$FAKE_RULESET_STATE"
    elif [[ "$request" == *"api --method POST repos/lockspire/fixture/rulesets --input -"* ]]; then
      jq --argjson id 42 --arg source "lockspire/fixture" \
        '. + {id: $id, source_type: "Repository", source: $source}
        | .rules |= map(if .type == "update" then del(.parameters) else . end)' \
        > "$FAKE_RULESET_STATE"
      cat "$FAKE_RULESET_STATE"
    elif [[ "$request" == *"api --method POST repos/lockspire/fixture/git/refs --input -"* ]]; then
      payload="$(cat)"
      ref="$(jq -er '.ref' <<< "$payload")"
      sha="$(jq -er '.sha' <<< "$payload")"
      if "$REAL_GIT" --git-dir "$FAKE_GIT_REMOTE" show-ref --verify --quiet "$ref"; then
        exit 1
      fi
      "$REAL_GIT" --git-dir "$FAKE_GIT_REMOTE" update-ref "$ref" "$sha"
      jq -nc --arg ref "$ref" --arg sha "$sha" '{ref: $ref, object: {sha: $sha}}'
    elif [[ "$request" == *"api --method DELETE repos/lockspire/fixture/rulesets/42"* ]]; then
      rm -f "$FAKE_RULESET_STATE"
    else
      printf 'unexpected fake gh request\\n' >&2
      exit 1
    fi
    """
  end

  defp create_tag_remote!(root) do
    source = Path.join(root, "tag-source")
    remote = Path.join(root, "tag-remote.git")
    File.mkdir_p!(source)

    git!(root, ["init", "--bare", remote])
    git!(root, ["init", source])
    git!(source, ["config", "user.name", "Lockspire Test"])
    git!(source, ["config", "user.email", "lockspire-test@example.invalid"])

    File.write!(Path.join(source, "README.md"), "first commit\n")
    git!(source, ["add", "README.md"])
    git!(source, ["commit", "-m", "first commit"])
    source_sha = git!(source, ["rev-parse", "HEAD"])

    git!(source, ["tag", "lockspire-v1.5.1-lightweight", source_sha])
    git!(source, ["tag", "-a", "lockspire-v1.5.1-annotated", source_sha, "-m", "release tag"])

    File.write!(Path.join(source, "README.md"), "second commit\n")
    git!(source, ["add", "README.md"])
    git!(source, ["commit", "-m", "second commit"])
    other_sha = git!(source, ["rev-parse", "HEAD"])
    git!(source, ["tag", "lockspire-v1.5.1-mismatch", other_sha])

    blob_sha = git!(source, ["rev-parse", "HEAD:README.md"])
    git!(source, ["tag", "-a", "lockspire-v1.5.1-blob", blob_sha, "-m", "non-commit tag"])
    git!(source, ["remote", "add", "origin", remote])

    git!(source, [
      "push",
      "origin",
      "refs/tags/lockspire-v1.5.1-lightweight",
      "refs/tags/lockspire-v1.5.1-annotated",
      "refs/tags/lockspire-v1.5.1-mismatch",
      "refs/tags/lockspire-v1.5.1-blob"
    ])

    {remote, source_sha, other_sha, blob_sha}
  end

  defp git!(cwd, args) do
    assert {output, 0} = System.cmd("git", args, cd: cwd, stderr_to_stdout: true)
    String.trim(output)
  end

  defp sha256(path) do
    :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
  end

  defp sha256_bytes(bytes) do
    :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  end

  defp create_valid_tarball!(path, version) do
    expression = """
    Mix.start()
    Mix.Local.append_archives()
    metadata = %{name: "lockspire", version: Enum.at(System.argv(), 1)}
    {:ok, %{tarball: tarball}} = :mix_hex_tarball.create(metadata, [{~c"mix.exs", "fixture"}])
    File.write!(Enum.at(System.argv(), 0), tarball)
    """

    assert {_output, 0} =
             System.cmd("elixir", ["-e", expression, path, version], stderr_to_stdout: true)
  end
end
