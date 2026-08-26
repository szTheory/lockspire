defmodule Lockspire.Release.ReleaseAutomationContractTest do
  use ExUnit.Case, async: true
  use Lockspire.TestSupport.ReleaseContractHelpers

  test "maintainer guide keeps the review-only release pr posture and separate evidence buckets" do
    guide = File.read!(@maintainer_guide_path)

    assert guide =~ "run `mix ci`"
    assert guide =~ "`mix ci` is the maintained contributor lane"
    assert guide =~ "`mix release.preflight` stays additive to `mix ci`"
    assert guide =~ "`mix package.publish-dry-run` remains a required release gate"
    assert guide =~ "maintainer-only release operations guidance"
    assert guide =~ "does not define a second public support contract"
    assert guide =~ "Release Please PR as review-only evidence"
    assert guide =~ "trusted proof starts only after merge in the protected `hex-publish` lane"
    assert guide =~ "`workflow_dispatch` is used, treat it as exact-ref only"
    assert guide =~ "exact commit SHA or tag being published by release automation or recovered"
    assert guide =~ "./scripts/maintainer/repo_hygiene_check.sh"
    assert guide =~ "merge commit's own successful `CI` push run"
    assert guide =~ ".github/workflows/release-please-automerge.yml"
    assert guide =~ "pre-merge CI run is never publish evidence"
    assert guide =~ "cannot publish a tag, a stale SHA, or a pre-merge run"

    assert guide =~
             "Treat `PASS` as ready, `WARN` as triage required, and `BLOCK` as stop-and-fix."

    assert guide =~ "Repo-owned proof:"
    assert guide =~ ".github/actions/release-please/action.yml"
    assert guide =~ "GitHub settings proof:"
    assert guide =~ "Workflow-run proof:"
    assert guide =~ "Public release claims stay anchored to `docs/supported-surface.md`"
    assert guide =~ "GitHub settings and workflow-run evidence support that story"
    assert guide =~ "should call `./.github/actions/release-please`"
    assert guide =~ "direct third-party Release Please action reference"

    assert guide =~
             "branch restriction to `main`, admin-bypass posture, and environment-secret placement"

    assert guide =~ "successful `hex-publish` workflow run"
    assert guide =~ "release-please-config.json"
    assert guide =~ ".release-please-manifest.json"
    assert guide =~ "public docs and `SECURITY.md` still defer to `docs/supported-surface.md`"
    assert guide =~ "This file does not broaden the Lockspire product contract"

    refute guide =~ "mix package.verify"
  end

  test "release workflow has one exact-CI-evidence publish lane" do
    release_workflow = File.read!(@release_workflow_path)
    release_please_job = release_workflow_job("release-please", "recovery-validation")
    recovery_validation_job = release_workflow_job("recovery-validation", "publish")
    publish_job = publish_job_section()

    assert release_workflow =~ "source_ci_run_id"
    assert release_workflow =~ "actions: read"
    assert recovery_validation_job =~ "^\[0-9a-f]{40}$"
    assert recovery_validation_job =~ "git rev-parse origin/main"
    assert recovery_validation_job =~ "actions/runs/$SOURCE_CI_RUN_ID"
    assert recovery_validation_job =~ "'.conclusion'"
    assert publish_job =~ "needs.recovery-validation.result == 'success'"
    assert publish_job =~ "git checkout --detach \"$VERIFIED_SHA\""
    assert publish_job =~ "mix release.preflight"
    assert publish_job =~ "mix hex.publish --yes"
    assert release_please_job =~ "uses: ./.github/actions/release-please"
    refute release_please_job =~ "mix hex.publish --yes"
    refute release_workflow =~ "googleapis/release-please-action"
  end

  test "ci and release cache restore keys stay scoped to the active beam pair" do
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)
    workflows = [ci_workflow, release_workflow]

    for workflow <- workflows do
      refute workflow =~ ~r/^\s+\$\{\{ runner\.os \}\}-mix-[A-Za-z0-9-]+-v\d+-\s*$/m
      refute workflow =~ ~r/^\s+\$\{\{ runner\.os \}\}-dialyzer-v\d+-\s*$/m
    end

    assert ci_workflow =~
             ~S/${{ runner.os }}-mix-fast-v2-${{ env.OTP_VERSION }}-${{ env.ELIXIR_VERSION }}-/

    assert ci_workflow =~
             ~S/${{ runner.os }}-mix-compat-v2-${{ env.MIN_OTP_VERSION }}-${{ env.MIN_ELIXIR_VERSION }}-/

    assert ci_workflow =~
             ~S/${{ runner.os }}-mix-integration-v2-${{ env.OTP_VERSION }}-${{ env.ELIXIR_VERSION }}-/

    assert ci_workflow =~
             ~S/${{ runner.os }}-mix-adoption-demo-v1-${{ env.OTP_VERSION }}-${{ env.ELIXIR_VERSION }}-/

    assert ci_workflow =~ "Restore Dialyzer cache"
    assert ci_workflow =~ "priv/plts"

    assert ci_workflow =~
             ~S/${{ runner.os }}-dialyzer-v1-${{ env.OTP_VERSION }}-${{ env.ELIXIR_VERSION }}-/

    refute release_workflow =~ "mix-release-v2"
  end

  test "release please automerge workflow only merges guarded bot release prs after green main ci" do
    workflow = File.read!(@release_please_automerge_workflow_path)

    assert workflow =~ "name: Release Please Auto Merge"
    assert workflow =~ "workflow_run:"
    assert workflow =~ "workflows:"
    assert workflow =~ "workflows: [CI]"
    assert workflow =~ "types:"
    assert workflow =~ "types: [completed]"
    assert workflow =~ "github.event.workflow_run.conclusion == 'success'"
    assert workflow =~ "github.event.workflow_run.head_branch == 'main'"
    assert workflow =~ "contents: write"
    assert workflow =~ "pull-requests: write"
    assert workflow =~ "actions: write"
    assert workflow =~ "GH_REPO: ${{ github.repository }}"
    assert workflow =~ "--author app/github-actions"
    assert workflow =~ "release-please--branches--main--components--lockspire"
    assert workflow =~ "chore\\\\(main\\\\): release lockspire"
    assert workflow =~ ".release-please-manifest.json,CHANGELOG.md,mix.exs"
    assert workflow =~ "gh pr merge \"$pr_number\" --squash --delete-branch"
    assert workflow =~ "mergeCommit"
    assert workflow =~ "gh workflow run release.yml"
    assert workflow =~ "--field recovery_ref=\"$CI_HEAD_SHA\""
    assert workflow =~ "merge validated by CI run $CI_RUN_ID"

    refute workflow =~ "HEX_API_KEY"
    refute workflow =~ "pull_request_target"
  end

  test "repo-controlled release please action stays on a supported runtime and keeps root release outputs" do
    action = File.read!(@release_please_action_path)
    runtime_package = File.read!(@release_please_runtime_package_path)
    runtime_lock = File.read!(@release_please_runtime_lock_path)
    runtime_index = File.read!(@release_please_runtime_index_path)

    assert action =~ "using: composite"
    assert action =~ "actions/setup-node@2028fbc5c25fe9cf00d9f06a71cc4710d4507903"
    assert action =~ "node-version: \"24\""
    assert action =~ "npm ci"
    assert action =~ "--ignore-scripts"
    assert action =~ "node .github/actions/release-please/runtime/index.js"
    assert action =~ "config-file"
    assert action =~ "manifest-file"
    assert runtime_package =~ "\"release-please\": \"17.11.2\""
    assert runtime_package =~ "\"@actions/core\": \"3.0.1\""
    assert runtime_lock =~ "\"lockspire-release-please-runtime\""
    assert runtime_lock =~ "\"release-please\": \"17.11.2\""
    assert runtime_index =~ "core.setOutput(\"release_created\", false)"
    assert runtime_index =~ "setPathOutput(path, \"release_created\", true)"
    assert runtime_index =~ "manifest.createReleases()"
    assert runtime_index =~ "manifest.createPullRequests()"
    refute action =~ "googleapis/release-please-action@"
    refute action =~ "using: node20"
    refute action =~ "npm install"
  end

  test "release metadata and workflow contracts agree on one checked-in version story" do
    config = File.read!(@release_please_config_path)
    manifest = File.read!(@release_please_manifest_path)
    release_workflow = File.read!(@release_workflow_path)
    action = File.read!(@release_please_action_path)
    mixfile = File.read!("mix.exs")
    changelog = File.read!("CHANGELOG.md")

    assert config =~ "\"bump-minor-pre-major\": false"
    assert config =~ "\"include-v-in-tag\": true"
    assert config =~ "\"packages\""
    assert config =~ "\".\""
    assert config =~ "\"component\": \"lockspire\""
    assert config =~ "\"include-component-in-tag\": true"
    assert config =~ "\"release-type\": \"elixir\""
    assert config =~ "\"package-name\": \"lockspire\""
    assert manifest =~ "\".\""
    assert manifest =~ ~r/"\.\":\s*"\d+\.\d+\.\d+"/
    assert mix_version() == manifest_version()
    assert manifest_version() == newest_changelog_version()
    assert changelog =~ "lockspire-v#{mix_version()}"
    assert changelog =~ "one `lockspire` package"
    assert mixfile =~ "\"Changelog\" => \"https://hexdocs.pm/lockspire/changelog.html\""
    assert mixfile =~ "\"Docs\" => \"https://hexdocs.pm/lockspire\""

    assert mixfile =~
             "\"Supported surface\" => \"https://hexdocs.pm/lockspire/supported-surface.html\""

    assert release_workflow =~ "uses: ./.github/actions/release-please"
    assert release_workflow =~ "config-file: release-please-config.json"
    assert release_workflow =~ "manifest-file: .release-please-manifest.json"
    assert release_workflow =~ "source_ci_run_id"
    assert release_workflow =~ "verified_sha"

    assert action =~ "config-file"
    assert action =~ "manifest-file"
    assert action =~ "node .github/actions/release-please/runtime/index.js"

    for artifact <- [mixfile, config, manifest, changelog] do
      refute artifact =~ "1.0.0-rc"
      refute artifact =~ "lockspire_rc"
      refute artifact =~ "lockspire-rc"
    end

    refute changelog =~ "GA-ready"
  end

  test "release truth hierarchy stays canonical across metadata and docs" do
    readme = File.read!(@readme_path)
    security = File.read!(@security_policy_path)
    supported_surface = File.read!(@supported_surface_path)
    guide = File.read!(@maintainer_guide_path)

    assert mix_version() == manifest_version()
    assert newest_changelog_version() == mix_version()
    assert List.first(changelog_versions()) == mix_version()

    assert supported_surface =~ "canonical public support contract"

    for doc <- [readme, security, guide] do
      assert doc =~ "docs/supported-surface.md"
    end

    assert guide =~ "## Release candidate checklist"
    assert guide =~ "checked-in release-candidate contract end to end"
    assert guide =~ "target is still `lockspire-v<version>`"
    assert guide =~ "checked-in proof stops there"
    assert guide =~ "creating a second support matrix"
    assert guide =~ "does not define a second public support contract"
    assert security =~ "does not define a second feature or topology matrix"
    assert readme =~ "authoritative support contract"
    refute readme =~ "What v1.0 includes"
    refute readme =~ "What v1.0 does not include"
    refute guide =~ "## Supported in scope"
    refute guide =~ "## Explicitly out of scope"

    for subordinate_doc <- [readme, security, guide] do
      refute subordinate_doc =~ "resource_indicators_supported"
      refute subordinate_doc =~ "authorization_details_types_supported"
    end
  end

  test "release prep docs keep evidence buckets separate and avoid checked-in publish-proof claims" do
    guide = File.read!(@maintainer_guide_path)
    readme = File.read!(@readme_path)
    security = File.read!(@security_policy_path)
    supported_surface = File.read!(@supported_surface_path)
    changelog = File.read!("CHANGELOG.md")
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)

    assert guide =~ "Repo-owned proof:"
    assert guide =~ "GitHub settings proof:"
    assert guide =~ "Workflow-run proof:"
    assert guide =~ "Release candidate checklist"
    assert guide =~ "review-only evidence"

    assert guide =~ "GitHub release, Hex publish, and unprivileged install-truth artifact"

    assert guide =~ "Protected-environment proof starts only when the `publish` job"
    assert guide =~ "Repo-owned commands stop at `mix ci`"
    assert supported_surface =~ "canonical public support contract"
    assert repo_hygiene_script =~ "Result: safe to start release prep"
    assert repo_hygiene_script =~ "Result: proceed with caution"
    assert repo_hygiene_script =~ "Result: not ready"

    for doc <- [guide, readme, security, changelog] do
      refute doc =~ "Hex-public proof"
      refute doc =~ "install-from-Hex proof"
      refute doc =~ "successful publish proof"
      refute doc =~ "published to Hex already"
    end
  end

  test "workflow files keep contributor proof separate from the protected publish lane" do
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)
    oidf_conformance_workflow = File.read!(@oidf_conformance_workflow_path)
    mixfile = File.read!("mix.exs")

    assert ci_workflow =~ "name: Release Hygiene Drift"
    assert ci_workflow =~ "bash ./scripts/maintainer/repo_hygiene_check.sh --ci"
    assert ci_workflow =~ "cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}"
    assert mixfile =~ "ci: ["
    assert mixfile =~ "\"test.fast\": [\"test.setup\", \"test\"]"
    assert mixfile =~ "\"cmd sh -lc 'mix qa'\""
    assert mixfile =~ "\"qa.dialyzer\": ["
    assert mixfile =~ "\"cmd sh -lc 'mix docs.verify'\""
    assert mixfile =~ "\"cmd sh -lc 'HEX_API_KEY= mix deps.audit'\""
    assert mixfile =~ "\"cmd sh -lc 'HEX_API_KEY= mix package.build'\""
    assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.fast'\""
    assert mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.integration'\""
    refute mixfile =~ "\"cmd sh -lc 'MIX_ENV=test mix test.phase3'\""

    for command <- [
          "run: mix qa",
          "run: mix docs.verify",
          "run: mix deps.audit",
          "run: mix package.build",
          "scripts/ci/run_test_matrix.sh --fast",
          "scripts/ci/run_test_matrix.sh --integration"
        ] do
      assert ci_workflow =~ command
    end

    assert mixfile =~ "\"conformance.phase37\": ["
    assert mixfile =~ "test/integration/phase37_protocol_strictness_e2e_test.exs"
    assert mixfile =~ "cmd bash scripts/conformance/run_phase37_suite.sh"
    assert mixfile =~ "\"conformance.phase37\": :test"

    assert release_workflow =~ "mix release.preflight"
    assert release_workflow =~ "mix hex.publish --yes"
    assert release_workflow =~ "environment: hex-publish"
    assert release_workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"

    assert oidf_conformance_workflow =~ "workflow_dispatch:"
    refute oidf_conformance_workflow =~ "schedule:"
    assert oidf_conformance_workflow =~ "MIX_ENV=test mix conformance.phase37"
    assert oidf_conformance_workflow =~ "LOCKSPIRE_PHASE37_MODE: hosted"
    refute oidf_conformance_workflow =~ "pull_request:"
  end
end
