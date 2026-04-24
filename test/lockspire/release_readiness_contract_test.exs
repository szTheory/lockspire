defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
  @release_workflow_path Path.expand("../../.github/workflows/release.yml", __DIR__)
  @release_please_action_path Path.expand("../../.github/actions/release-please/action.yml", __DIR__)
  @release_please_runtime_package_path Path.expand("../../.github/actions/release-please/runtime/package.json", __DIR__)
  @release_please_runtime_lock_path Path.expand("../../.github/actions/release-please/runtime/package-lock.json", __DIR__)
  @release_please_runtime_index_path Path.expand("../../.github/actions/release-please/runtime/index.js", __DIR__)
  @ci_workflow_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @release_please_config_path Path.expand("../../release-please-config.json", __DIR__)
  @release_please_manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @readme_path Path.expand("../../README.md", __DIR__)
  @supported_surface_path Path.expand("../../docs/supported-surface.md", __DIR__)
  @security_policy_path Path.expand("../../SECURITY.md", __DIR__)
  @install_and_onboard_path Path.expand("../../docs/install-and-onboard.md", __DIR__)
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
    assert guide =~ "exact commit SHA or tag being recovered"
    assert guide =~ "Repo-owned proof:"
    assert guide =~ ".github/actions/release-please/action.yml"
    assert guide =~ "GitHub settings proof:"
    assert guide =~ "Workflow-run proof:"
    assert guide =~ "should call `./.github/actions/release-please`"
    assert guide =~ "direct third-party Release Please action reference"

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
    assert release_workflow =~ "recovery_ref"
    assert release_workflow =~ "workflow_dispatch is recovery-only"
    assert release_workflow =~ "github.event_name != 'workflow_dispatch'"
    assert release_workflow =~ "Check out repository for the recovery ref"
    assert release_workflow =~ "ref: ${{ inputs.recovery_ref }}"
    assert release_workflow =~ "Release Please generated PRs are review-only"
    assert release_workflow =~ "github.event_name == 'workflow_dispatch'"
    assert release_workflow =~ "mix local.hex --force"
    assert release_workflow =~ "mix local.rebar --force"

    assert release_workflow =~
             "Trusted proof starts only after merge in the protected hex-publish environment"

    assert release_workflow =~ "uses: ./.github/actions/release-please"
    assert release_workflow =~ "config-file: release-please-config.json"
    assert release_workflow =~ "manifest-file: .release-please-manifest.json"
    assert release_workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert release_workflow =~ "run: mix release.preflight"
    assert release_workflow =~ "run: mix hex.publish --yes"

    assert release_workflow =~
             "if: ${{ github.event_name == 'workflow_dispatch' || needs.release-please.outputs.release_created == 'true' }}"

    refute release_workflow =~ "pull_request:"
    refute release_workflow =~ "package-name: lockspire"
    refute release_workflow =~ "googleapis/release-please-action"

    refute release_workflow =~ "mix package.verify"
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
    assert runtime_package =~ "\"release-please\": \"17.3.0\""
    assert runtime_package =~ "\"@actions/core\": \"1.10.0\""
    assert runtime_lock =~ "\"lockspire-release-please-runtime\""
    assert runtime_lock =~ "\"release-please\": \"17.3.0\""
    assert runtime_index =~ "core.setOutput(\"release_created\", false)"
    assert runtime_index =~ "setPathOutput(path, \"release_created\", true)"
    assert runtime_index =~ "manifest.createReleases()"
    assert runtime_index =~ "manifest.createPullRequests()"
    refute action =~ "googleapis/release-please-action@"
    refute action =~ "using: node20"
    refute action =~ "npm install"
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
    assert readme =~
             "Pushed authorization requests through Lockspire-issued `request_uri` references"

    assert readme =~
             "Request-object-by-value support, generic external `request_uri` handling, device flow, or dynamic client registration"

    assert supported_surface =~ "Lockspire `v0.1` is a preview release"

    assert supported_surface =~
             "embedded OAuth/OIDC authorization server library for Phoenix and Elixir"

    assert supported_surface =~ "Authorization code flow with PKCE S256"
    assert supported_surface =~
             "Pushed authorization requests only as Lockspire-issued `request_uri` references"

    assert supported_surface =~ "OIDC discovery and JWKS"
    assert supported_surface =~ "Lockspire does not use a demo app"
    assert supported_surface =~ "A `v0.1` preview claim should not say:"
    assert supported_surface =~ "Lockspire is production-ready for unsupported host shapes"
    assert supported_surface =~ "Generic external `request_uri` handling outside Lockspire's own PAR endpoint"

    refute readme =~ "production-ready"
  end

  test "security and release posture stay inside the supported preview surface" do
    security = File.read!(@security_policy_path)
    onboarding = File.read!(@install_and_onboard_path)
    guide = File.read!(@maintainer_guide_path)
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)

    assert security =~ "Please do not file public issues"
    assert security =~ "Open a GitHub Security Advisory draft"
    assert security =~ "supported security surface is limited"
    assert security =~ "authorization code + PKCE"
    assert security =~
             "pushed authorization requests only through Lockspire-issued `request_uri` references"

    assert security =~ "PKCE S256 required by default"
    assert security =~ "no `alg=none`"
    assert security =~
             "request-object-by-value support, generic external `request_uri` handling, device flow, and dynamic client registration"

    assert guide =~ "inside the `v0.1` preview support contract"

    assert guide =~
             "Preview releases should only claim the supported surface the repo can currently prove."

    assert guide =~
             "authorization code + PKCE, discovery, JWKS, userinfo, revocation, introspection, refresh rotation"

    assert guide =~
             "Do not broaden release claims to request-object-by-value support, generic external request_uri handling, device flow, dynamic client registration, hosted auth service language, certification language, demo-app proof, or full CIAM positioning."

    assert onboarding =~ "canonical onboarding path is Phoenix-first and generator-first"
    assert onboarding =~ "Lockspire stays embedded inside your host app"
    assert onboarding =~ "authorization-code + PKCE exchange"
    assert onboarding =~ "The executable repo proof lives in:"
    assert onboarding =~ "test/integration/install_generator_test.exs"
    assert onboarding =~ "test/integration/phase6_onboarding_e2e_test.exs"
    refute Regex.match?(~r/## 5\\..*\\n(?:- .*\\n)*- .*\\bdevice flow\\b/m, onboarding)
    refute onboarding =~ "production-ready"

    assert ci_workflow =~ "run: mix docs.verify"
    assert release_workflow =~ "environment: hex-publish"
  end

  test "planning metadata and repo truth keep PAR scoped to the narrow v1.2 slice" do
    project = File.read!(@project_path)
    roadmap = File.read!(@roadmap_path)
    requirements = File.read!(@requirements_path)
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)
    security = File.read!(@security_policy_path)

    assert project =~
             "PAR is the default next protocol-expansion milestone after release hardening"

    assert project =~ "not implemented and not supported in v1.1"
    assert project =~ "Add pushed authorization requests as a narrow extension"
    assert project =~
             "Advertise PAR support truthfully in discovery, docs, and support-facing surfaces without implying broader JAR, DCR, or device-flow support."

    assert roadmap =~
             "document PAR as the next milestone candidate without starting it here or implying current v1.1 support"

    assert roadmap =~ "v1.2 PAR Foundation"
    assert roadmap =~ "15-03: Add end-to-end tests for the PAR-backed authorization code + PKCE flow and truth-surface contract coverage"
    assert roadmap =~
             "README, supported-surface docs, and related contract tests describe PAR as implemented without implying JAR-by-value, DCR, or device-flow support."

    assert requirements =~
             "The next protocol-expansion milestone is documented as PAR, but PAR is not implemented and not supported during v1.1."

    assert requirements =~
             "PAR-03"

    assert requirements =~
             "advertise only the implemented PAR slice and do not imply request-object-by-value, dynamic registration, or device-flow support."

    assert readme =~
             "Pushed authorization requests through Lockspire-issued `request_uri` references on the existing authorization code + PKCE path"

    assert supported_surface =~
             "Pushed authorization requests only as Lockspire-issued `request_uri` references that extend the existing authorization code + PKCE flow"

    assert security =~
             "pushed authorization requests only through Lockspire-issued `request_uri` references on the authorization code + PKCE path"

    refute readme =~ "supports broader request-object modes"
    refute supported_surface =~ "Request-object-by-value support is in scope"
    refute security =~ "hosted auth is part of the supported security surface"

    refute Regex.match?(
             ~r/Pushed authorization requests.*generic external `request_uri` handling/m,
             readme
           )

    refute Regex.match?(
             ~r/Supported in scope\\s+(?:.*\\n)*- .*dynamic client registration/m,
             supported_surface
           )
  end
end
