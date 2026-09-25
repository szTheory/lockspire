defmodule Lockspire.TestSupport.ReleaseProof.WorkflowAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.ReleaseProof.Paths

  @active_phase_number "140"
  @active_phase_label "Phase " <> @active_phase_number

  def assert_protected_publish_lane! do
    workflow = Paths.read!(".github/workflows/release.yml")
    release_train = Paths.read!(".planning/RELEASE-TRAIN.md")
    guide = Paths.read!("docs/maintainer-release.md")
    mixfile = Paths.read!("mix.exs")

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
    assert workflow =~ "mix release.preflight"
    assert workflow =~ "prepublish-proof:"
    assert publish =~ "release-package-${{ needs.recovery-validation.outputs.verified_sha }}"
    assert publish =~ "bash scripts/publish/publish_hex_idempotently.sh"
    assert publish_script =~ "upload_hex_artifact.exs \"$package_tar\""
    assert publish_script =~ "mix hex.publish docs --yes"
    assert publish_script =~ "release_artifact.py verify-local"
    assert publish_script =~ "release_artifact.py verify-hex"
    refute publish_script =~ "mix hex.publish --yes"
    refute publish_script =~ "mix hex.build"
    assert publish_script =~ "Hex release lookup failed closed"
    assert release_please =~ "uses: ./.github/actions/release-please"
    refute release_please =~ "publish_hex_idempotently.sh"
    refute workflow =~ "googleapis/release-please-action"

    assert release_train =~
             "`workflow_dispatch` validates and publishes one exact lowercase 40-hex commit equal to current `origin/main`"

    assert release_train =~
             "publishes the manifest-verified package to Hex before creating or validating the matching `lockspire-v<version>` GitHub release"

    refute release_train =~ "Push-triggered Hex publish"
    refute release_train =~ "GitHub release exists before Hex publish"

    assert guide =~
             "`workflow_dispatch` accepts only one lowercase full 40-hex commit equal to current `origin/main`"

    assert guide =~
             "publishes the manifest-verified package to Hex before creating or validating the matching GitHub release"

    refute guide =~ "exact commit SHA or tag"
    refute guide =~ "latest successful `main` CI"
    refute guide =~ "- `mix test." <> "phase" <> "3`"

    assert mixfile =~
             ~s(ci: [\n        "cmd sh -lc 'HEX_API_KEY= mix deps.get'",\n        "cmd sh -lc 'mix qa'",\n        "cmd sh -lc 'mix docs.verify'",\n        "cmd sh -lc 'HEX_API_KEY= mix deps.audit'",\n        "cmd sh -lc 'HEX_API_KEY= mix package.build'",\n        "cmd sh -lc 'MIX_ENV=test mix test.fast'",\n        "cmd sh -lc 'MIX_ENV=test mix test.integration'"\n      ])

    for historical_value <- [
          "1.5.0",
          "5d10ce2219c2e687cf9573c8b280abfb118a47d8",
          "33141161205",
          "33141484467",
          "lockspire-v1.5.0",
          "30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de"
        ] do
      assert release_train =~ historical_value
    end

    assert byte_offset(publish, "- name: Publish package") <
             byte_offset(publish, "- name: Create matching GitHub release")
  end

  def assert_current_release_truth! do
    config = Paths.read!("release-please-config.json")
    manifest = Paths.read!(".release-please-manifest.json")
    changelog = Paths.read!("CHANGELOG.md")
    mixfile = Paths.read!("mix.exs")
    guide = Paths.read!("docs/maintainer-release.md")
    project = Paths.read!(".planning/PROJECT.md")
    roadmap = Paths.read!(".planning/ROADMAP.md")
    state = Paths.read!(".planning/STATE.md")
    milestones = Paths.read!(".planning/MILESTONES.md")
    release_train = Paths.read!(".planning/RELEASE-TRAIN.md")
    hygiene = Paths.read!(".planning/REPO-HYGIENE-CHECKLIST.md")
    oidf_workflow = Paths.read!(".github/workflows/oidf-conformance.yml")
    conformance_guide = Paths.read!("docs/maintainer-conformance.md")

    assert Paths.mix_version() == Paths.manifest_version()
    assert Paths.manifest_version() == Paths.newest_changelog_version()
    assert config =~ "\"package-name\": \"lockspire\""
    assert config =~ "\"release-type\": \"elixir\""
    assert manifest =~ ~r/"\.":\s*"\d+\.\d+\.\d+"/
    assert changelog =~ "lockspire-v#{Paths.mix_version()}"
    assert mixfile =~ "\"Changelog\" => \"https://hexdocs.pm/lockspire/changelog.html\""
    assert guide =~ "docs/supported-surface.md"
    refute Enum.any?([mixfile, config, manifest, changelog], &String.contains?(&1, "1.0.0-rc"))

    assert project =~ "## Current Milestone: v1.38 Repository Baseline & Reconciliation"
    assert project =~ @active_phase_label <> " pre-planning gate"

    assert project =~
             "Finish the active v1.38 Repository Baseline & Reconciliation milestone before returning to the sustaining GA release train."

    assert roadmap =~ "🚧 **v1.38 Repository Baseline & Reconciliation**"
    assert roadmap =~ @active_phase_label <> ": Bounded Operational Loose-End Triage"
    assert state =~ "milestone: v1.38"
    assert state =~ "current_phase: 140"
    assert milestones =~ "## v1.37 Prime-Time Readiness Ratchet (Shipped: 2026-08-28)"
    assert milestones =~ "public package `1.5.0`"
    assert release_train =~ "Latest released version: `1.5.0`"

    assert hygiene =~
             "bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <40-lowercase-hex-current-main-sha> --format json"

    assert hygiene =~ "Every `WARN` requires one explicit `--warn-disposition CODE=DISPOSITION`"
    assert hygiene =~ ~s(`"warn_dispositions": []`)
    assert hygiene =~ "v1.38 and " <> @active_phase_label <> " are the current planning truth"
    assert hygiene =~ "v1.37 and Lockspire 1.5.0 remain the latest shipped truth"
    refute hygiene =~ "latest `main` CI"

    assert oidf_workflow =~ "name: Supplemental OIDF Conformance"
    assert oidf_workflow =~ "permissions:\n  contents: read"
    refute oidf_workflow =~ "push:"
    assert conformance_guide =~ "not OpenID certification"
    assert conformance_guide =~ "not a release gate"
    assert hygiene =~ "redacted, supplemental, non-certifying, and not a release gate"
    assert hygiene =~ "neither satisfies nor blocks required acceptance"
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
