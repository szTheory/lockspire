defmodule Lockspire.Release.RepositoryHygieneContractTest do
  # These fixtures run the actual hygiene helper, source collector and owned
  # guard. Only external Git/GitHub/Mix/PostgreSQL/Docker commands are faked in
  # throwaway repositories; no accepted receipt is supplied by a fixture.
  # Keep them isolated so shared OS resources cannot distort the receipts.
  use ExUnit.Case, async: false

  alias Lockspire.TestSupport.ReleaseProof.PackageAssertions
  alias Lockspire.TestSupport.QualityBaseline

  @release_train Path.expand("../../../.planning/RELEASE-TRAIN.md", __DIR__)

  @tag :release_train_links
  test "local release train Markdown destinations resolve" do
    content = File.read!(@release_train)

    destinations =
      Regex.scan(~r/\[[^\]]+\]\(([^)]+)\)/, content, capture: :all_but_first)
      |> List.flatten()

    local_destinations =
      Enum.reject(destinations, fn destination ->
        URI.parse(destination).scheme != nil or String.starts_with?(destination, "#")
      end)

    assert local_destinations != [],
           "expected at least one local link in .planning/RELEASE-TRAIN.md"

    Enum.each(local_destinations, fn destination ->
      path = destination |> String.split("#", parts: 2) |> hd()
      resolved = Path.expand(path, Path.dirname(@release_train))

      assert File.exists?(resolved),
             "unresolved local Markdown destination #{inspect(destination)} in .planning/RELEASE-TRAIN.md"
    end)
  end

  test "package inputs are explicit and exclude repository-local artifacts" do
    PackageAssertions.assert_hex_package_inputs!()
  end

  test "repository hygiene stays deterministic and outside the public product surface" do
    PackageAssertions.assert_repository_hygiene!()
  end

  @tag :phase139_gate_repair
  test "repository-owned workflow and shell lint passes" do
    repo_root = Path.expand("../../..", __DIR__)

    {output, status} =
      System.cmd("bash", ["scripts/ci/lint_workflows.sh"],
        cd: repo_root,
        stderr_to_stdout: true
      )

    assert status == 0, output
  end

  @tag :workflow_lint_discovery
  test "workflow lint scans tracked regular shell files including extensionless scripts" do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-workflow-lint-#{System.unique_integer([:positive])}"
      )

    repo = Path.join(fixture, "repo")
    bin = Path.join(fixture, "bin")
    tracked_script = "scripts/maintainer/quality check"
    tracked_workflow = ".github/workflows/ci.yml"

    vendor_hook =
      "tmp/lockspire-compatibility-fixture/deps/lazy_html/_build/c/third_party/lexbor/.git/hooks/pre-commit.sample"

    File.mkdir_p!(repo)
    File.mkdir_p!(bin)

    try do
      {_, 0} = System.cmd("git", ["init", "--quiet", repo])
      File.mkdir_p!(Path.dirname(Path.join(repo, tracked_script)))
      File.mkdir_p!(Path.dirname(Path.join(repo, tracked_workflow)))
      File.mkdir_p!(Path.dirname(Path.join(repo, vendor_hook)))
      File.write!(Path.join(repo, tracked_script), "#!/bin/sh\nexit 0\n")
      File.chmod!(Path.join(repo, tracked_script), 0o755)
      File.write!(Path.join(repo, tracked_workflow), "name: Fixture\non: push\njobs: {}\n")
      File.write!(Path.join(repo, vendor_hook), "#!/bin/sh\necho $(printf bad)\n")
      File.chmod!(Path.join(repo, vendor_hook), 0o755)

      {_, 0} = System.cmd("git", ["-C", repo, "add", "--", tracked_script, tracked_workflow])

      workflow_marker = Path.join(fixture, "actionlint-workflow-arg")

      write_executable_stub!(bin, "actionlint", """
      #!/bin/sh
      if [ "${1:-}" = "--version" ]; then
        echo 'actionlint 1.7.12'
        exit 0
      fi
      case " $* " in
        *".github/workflows/ci.yml"*)
          printf '%s\\n' "$*" > "$FAKE_WORKFLOW_MARKER"
          exit 0
          ;;
        *) echo 'tracked workflow was not linted' >&2; exit 3 ;;
      esac
      """)

      shell_marker = Path.join(fixture, "shellcheck-script-arg")

      write_executable_stub!(bin, "shellcheck", """
      #!/bin/sh
      if [ "${1:-}" = "--version" ]; then
        echo 'ShellCheck 0.11.0'
        exit 0
      fi
      tracked=0
      for file in "$@"; do
        case "$file" in
          *quality\\ check)
            tracked=1
            printf '%s\\n' "$file" >> "$FAKE_SHELL_MARKER"
            ;;
          *pre-commit.sample)
            echo 'SC2046 untracked vendor pre-commit hook was linted' >&2
            exit 2
            ;;
        esac
      done
      [ "$tracked" -eq 1 ] || { echo 'tracked extensionless script was not linted' >&2; exit 3; }
      """)

      script_path = Path.expand("../../../scripts/ci/lint_workflows.sh", __DIR__)

      {output, status} =
        System.cmd("bash", [script_path],
          cd: repo,
          env: [
            {"PATH", bin <> ":" <> System.get_env("PATH", "")},
            {"FAKE_WORKFLOW_MARKER", workflow_marker},
            {"FAKE_SHELL_MARKER", shell_marker}
          ],
          stderr_to_stdout: true
        )

      assert status == 0, output
      assert File.read!(workflow_marker) =~ "ci.yml"
      assert File.read!(shell_marker) == "./scripts/maintainer/quality check\n"
    after
      File.rm_rf!(fixture)
    end
  end

  @tag :phase139_gate_repair
  test "active release proof composes phase labels from semantic attributes" do
    assert QualityBaseline.active_phase_numbered_proof_locations() == []
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA repository hygiene joins synchronized local and workflow truth" do
    PackageAssertions.assert_phase_139_exact_sha_hygiene!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA hygiene blocks misleading release train claims before acceptance" do
    PackageAssertions.assert_phase_139_release_train_fail_closed!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA hygiene matches only exact active-project Docker volume names" do
    PackageAssertions.assert_phase_139_docker_volume_name_matching!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  test "local hygiene warns when Docker state cannot be observed" do
    PackageAssertions.assert_phase_139_local_docker_list_failures!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA repository hygiene fails every ambiguous or stale path closed" do
    PackageAssertions.assert_phase_139_exact_sha_hygiene_fail_closed!()
  end

  defp write_executable_stub!(directory, name, contents) do
    path = Path.join(directory, name)
    File.write!(path, contents)
    File.chmod!(path, 0o755)
  end
end
