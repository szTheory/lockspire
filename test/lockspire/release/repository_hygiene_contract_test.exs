defmodule Lockspire.Release.RepositoryHygieneContractTest do
  # These contract tests run the repo hygiene gate against throwaway Git
  # fixtures. Keep them isolated from the rest of the suite so shared OS
  # resources cannot distort the receipts.
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
end
