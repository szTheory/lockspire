defmodule Lockspire.TestSupport.ReleaseProof.WorkflowAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.ReleaseProof.Paths

  def assert_protected_publish_lane! do
    workflow = Paths.read!(".github/workflows/release.yml")

    release_please =
      Paths.workflow_job(".github/workflows/release.yml", "release-please", "recovery-validation")

    recovery =
      Paths.workflow_job(".github/workflows/release.yml", "recovery-validation", "publish")

    publish = Paths.final_workflow_job(".github/workflows/release.yml", "publish")
    publish_script = Paths.read!("scripts/publish/publish_hex_idempotently.sh")

    assert workflow =~ "source_ci_run_id"
    assert recovery =~ "git rev-parse origin/main"
    assert recovery =~ "actions/runs/$SOURCE_CI_RUN_ID"
    assert publish =~ "needs.recovery-validation.result == 'success'"
    assert publish =~ "git checkout --detach \"$VERIFIED_SHA\""
    assert publish =~ "mix release.preflight"
    assert publish =~ "bash scripts/publish/publish_hex_idempotently.sh"
    assert publish_script =~ "mix hex.publish --yes"
    assert publish_script =~ "release_artifact.py verify-local"
    assert publish_script =~ "release_artifact.py verify-hex"
    assert publish_script =~ "cmp -s"
    assert publish_script =~ "Hex release lookup failed closed"
    assert release_please =~ "uses: ./.github/actions/release-please"
    refute release_please =~ "publish_hex_idempotently.sh"
    refute workflow =~ "googleapis/release-please-action"

    assert byte_offset(publish, "- name: Publish package") <
             byte_offset(publish, "- name: Create matching GitHub release")
  end

  def assert_current_release_truth! do
    config = Paths.read!("release-please-config.json")
    manifest = Paths.read!(".release-please-manifest.json")
    changelog = Paths.read!("CHANGELOG.md")
    mixfile = Paths.read!("mix.exs")
    guide = Paths.read!("docs/maintainer-release.md")

    assert Paths.mix_version() == Paths.manifest_version()
    assert Paths.manifest_version() == Paths.newest_changelog_version()
    assert config =~ "\"package-name\": \"lockspire\""
    assert config =~ "\"release-type\": \"elixir\""
    assert manifest =~ ~r/"\.":\s*"\d+\.\d+\.\d+"/
    assert changelog =~ "lockspire-v#{Paths.mix_version()}"
    assert mixfile =~ "\"Changelog\" => \"https://hexdocs.pm/lockspire/changelog.html\""
    assert guide =~ "docs/supported-surface.md"
    refute Enum.any?([mixfile, config, manifest, changelog], &String.contains?(&1, "1.0.0-rc"))
  end

  def assert_evidence_boundaries! do
    ci = Paths.read!(".github/workflows/ci.yml")
    release = Paths.read!(".github/workflows/release.yml")
    guide = Paths.read!("docs/maintainer-release.md")

    assert ci =~ "run: mix qa"
    assert ci =~ "run: mix docs.verify"
    assert ci =~ "run: mix package.build"
    assert release =~ "environment: hex-publish"
    assert release =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert guide =~ "Release Please PR as review-only evidence"
    assert guide =~ "trusted proof starts only after merge"
    assert guide =~ "does not define a second public support contract"
    refute ci =~ "HEX_API_KEY"
  end

  defp byte_offset(bytes, needle) do
    case :binary.match(bytes, needle) do
      {offset, _length} -> offset
      :nomatch -> flunk("expected #{inspect(needle)} in release workflow")
    end
  end
end
