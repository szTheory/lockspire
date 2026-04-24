defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
  @release_workflow_path Path.expand("../../.github/workflows/release.yml", __DIR__)
  @ci_workflow_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @release_please_config_path Path.expand("../../release-please-config.json", __DIR__)
  @release_please_manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @readme_path Path.expand("../../README.md", __DIR__)
  @supported_surface_path Path.expand("../../docs/supported-surface.md", __DIR__)
  @security_policy_path Path.expand("../../SECURITY.md", __DIR__)
  @project_path Path.expand("../../.planning/PROJECT.md", __DIR__)
  @roadmap_path Path.expand("../../.planning/ROADMAP.md", __DIR__)
  @requirements_path Path.expand("../../.planning/REQUIREMENTS.md", __DIR__)

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
    assert manifest =~ "\".\""
    assert manifest =~ ~r/"\.\":\s*"\d+\.\d+\.\d+"/
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

  test "preview docs keep the v0.1 embedded Phoenix wedge explicit" do
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)

    assert readme =~ "current `v0.1` preview"
    assert readme =~ "inside its existing app"
    assert readme =~ "The public support contract"
    assert readme =~ "Generator-backed install flow for Phoenix hosts"
    assert readme =~ "PAR, device flow, or dynamic client registration"

    assert supported_surface =~ "Lockspire `v0.1` is a preview release"
    assert supported_surface =~ "embedded OAuth/OIDC authorization server library for Phoenix and Elixir"
    assert supported_surface =~ "Authorization code flow with PKCE S256"
    assert supported_surface =~ "OIDC discovery and JWKS"
    assert supported_surface =~ "Lockspire does not use a demo app"
    assert supported_surface =~ "A `v0.1` preview claim should not say:"
    assert supported_surface =~ "Lockspire is production-ready for unsupported host shapes"

    refute readme =~ "production-ready"
  end

  test "security and release posture stay inside the supported preview surface" do
    security = File.read!(@security_policy_path)
    guide = File.read!(@maintainer_guide_path)
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)

    assert security =~ "Please do not file public issues"
    assert security =~ "Open a GitHub Security Advisory draft"
    assert security =~ "supported security surface is limited"
    assert security =~ "authorization code + PKCE"
    assert security =~ "PAR, device flow, and dynamic client registration"
    assert security =~ "PKCE S256 required by default"
    assert security =~ "no `alg=none`"

    assert guide =~ "inside the `v0.1` preview support contract"
    assert guide =~ "Preview releases should only claim the supported surface the repo can currently prove."
    assert guide =~ "authorization code + PKCE, discovery, JWKS, userinfo, revocation, introspection, refresh rotation"
    assert guide =~ "Do not broaden release claims to PAR, device flow, dynamic client registration, hosted auth service language, certification language, demo-app proof, or full CIAM positioning."

    assert ci_workflow =~ "run: mix docs.verify"
    assert release_workflow =~ "environment: hex-publish"
  end

  test "planning metadata keeps PAR future-facing while current posture rejects present support claims" do
    project = File.read!(@project_path)
    roadmap = File.read!(@roadmap_path)
    requirements = File.read!(@requirements_path)
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)
    security = File.read!(@security_policy_path)

    assert project =~ "PAR is the default next protocol-expansion milestone after release hardening"
    assert project =~ "not implemented and not supported in v1.1"

    assert roadmap =~ "document PAR as the next milestone candidate without starting it here or implying current v1.1 support"
    assert roadmap =~ "v1.2 PAR Foundation"
    assert roadmap =~ "PAR is not implemented and not supported in v1.1"

    assert requirements =~ "The next protocol-expansion milestone is documented as PAR, but PAR is not implemented and not supported during v1.1."
    assert requirements =~ "PAR implementation in v1.1"

    assert supported_surface =~ "does not currently support:"
    assert supported_surface =~ "- PAR"
    assert security =~ "- PAR, device flow, and dynamic client registration"

    refute readme =~ "already supports PAR"
    refute readme =~ "What v0.1 includes\n\n- PAR"
    refute supported_surface =~ "preview currently supports this repo-proven surface:\n\n- PAR"
    refute security =~ "supported security surface is limited to the embedded OAuth/OIDC provider behavior shipped in this repo and described in `docs/supported-surface.md`:\n\n- PAR"
  end
end
