defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
  @release_workflow_path Path.expand("../../.github/workflows/release.yml", __DIR__)
  @ci_workflow_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @release_please_config_path Path.expand("../../release-please-config.json", __DIR__)
  @release_please_manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)

  test "maintainer guide keeps the review-only release pr posture and separate evidence buckets" do
    guide = File.read!(@maintainer_guide_path)

    assert guide =~ "run `mix ci`"
    assert guide =~ "`mix ci` is the maintained contributor lane"
    assert guide =~ "`mix release.preflight` stays additive to `mix ci`"
    assert guide =~ "`mix package.publish-dry-run` remains a required release gate"
    assert guide =~ "Release Please PR as review-only evidence"
    assert guide =~ "trusted proof starts only after merge in the protected `hex-publish` lane"
    assert guide =~ "`workflow_dispatch` is used, treat it as recovery-only"
    assert guide =~ "Repo-owned proof:"
    assert guide =~ "GitHub settings proof:"
    assert guide =~ "Workflow-run proof:"

    assert guide =~
             "branch restriction to `main`, admin-bypass posture, and environment-secret placement"

    assert guide =~ "successful `hex-publish` workflow run"
    assert guide =~ "release-please-config.json"
    assert guide =~ ".release-please-manifest.json"

    refute guide =~ "mix package.verify"
  end

  test "release workflow keeps one protected publish lane with recovery-only manual dispatch" do
    release_workflow = File.read!(@release_workflow_path)

    assert release_workflow =~ "push:"
    assert release_workflow =~ "workflow_dispatch:"
    assert release_workflow =~ "environment: hex-publish"
    assert release_workflow =~ "recovery_reason"
    assert release_workflow =~ "workflow_dispatch is recovery-only"
    assert release_workflow =~ "Release Please generated PRs are review-only"
    assert release_workflow =~ "github.event_name == 'workflow_dispatch'"
    assert release_workflow =~ "mix local.hex --force"
    assert release_workflow =~ "mix local.rebar --force"

    assert release_workflow =~
             "Trusted proof starts only after merge in the protected hex-publish environment"

    assert release_workflow =~ "config-file: release-please-config.json"
    assert release_workflow =~ "manifest-file: .release-please-manifest.json"
    assert release_workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert release_workflow =~ "run: mix release.preflight"
    assert release_workflow =~ "run: mix hex.publish --yes"

    assert release_workflow =~
             "if: ${{ github.event_name == 'workflow_dispatch' || needs.release-please.outputs.release_created == 'true' }}"

    refute release_workflow =~ "pull_request:"
    refute release_workflow =~ "package-name: lockspire"

    refute release_workflow =~ "mix package.verify"
  end

  test "release please policy is checked in and keeps preview versioning explicit" do
    config = File.read!(@release_please_config_path)
    manifest = File.read!(@release_please_manifest_path)

    assert config =~ "\"bump-minor-pre-major\": true"
    assert config =~ "\"packages\""
    assert config =~ "\".\""
    assert config =~ "\"release-type\": \"elixir\""
    assert config =~ "\"package-name\": \"lockspire\""
    assert manifest =~ "\".\": \"0.1.0\""
  end

  test "workflow files keep contributor proof separate from the protected publish lane" do
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)
    mixfile = File.read!("mix.exs")

    assert mixfile =~ "ci: ["
    assert mixfile =~ "\"test.fast\": [\"test.setup\", \"test\"]"
    assert mixfile =~ "\"cmd sh -lc 'mix qa'\""
    assert mixfile =~ "\"cmd sh -lc 'mix docs.verify'\""
    assert mixfile =~ "\"cmd sh -lc 'HEX_API_KEY= mix deps.audit'\""
    assert mixfile =~ "\"cmd sh -lc 'HEX_API_KEY= mix package.build'\""
    assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.fast'\""
    assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.integration'\""
    assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.phase3'\""

    for command <- [
          "run: mix qa",
          "run: mix docs.verify",
          "run: mix deps.audit",
          "run: mix package.build",
          "run: mix test.fast",
          "run: mix test.integration",
          "run: mix test.phase3"
        ] do
      assert ci_workflow =~ command
    end

    assert release_workflow =~ "mix release.preflight"
    assert release_workflow =~ "mix hex.publish --yes"
  end
end
