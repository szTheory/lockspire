defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
  @release_workflow_path Path.expand("../../.github/workflows/release.yml", __DIR__)
  @release_please_action_path Path.expand(
                                "../../.github/actions/release-please/action.yml",
                                __DIR__
                              )
  @release_please_runtime_package_path Path.expand(
                                         "../../.github/actions/release-please/runtime/package.json",
                                         __DIR__
                                       )
  @release_please_runtime_lock_path Path.expand(
                                      "../../.github/actions/release-please/runtime/package-lock.json",
                                      __DIR__
                                    )
  @release_please_runtime_index_path Path.expand(
                                       "../../.github/actions/release-please/runtime/index.js",
                                       __DIR__
                                     )
  @ci_workflow_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @release_please_config_path Path.expand("../../release-please-config.json", __DIR__)
  @release_please_manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @readme_path Path.expand("../../README.md", __DIR__)
  @supported_surface_path Path.expand("../../docs/supported-surface.md", __DIR__)
  @security_policy_path Path.expand("../../SECURITY.md", __DIR__)
  @install_and_onboard_path Path.expand("../../docs/install-and-onboard.md", __DIR__)
  @device_flow_host_guide_path Path.expand("../../docs/device-flow-host-guide.md", __DIR__)
  @project_path Path.expand("../../.planning/PROJECT.md", __DIR__)
  @roadmap_path Path.expand("../../.planning/milestones/v1.3-ROADMAP.md", __DIR__)
  @requirements_path Path.expand("../../.planning/milestones/v1.3-REQUIREMENTS.md", __DIR__)

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
    assert release_workflow =~ "Check out repository for Release Please"
    assert release_workflow =~ "Confirm manual dispatch stays recovery-only"
    assert release_workflow =~ "steps.manual_dispatch.outputs.release_created"
    assert release_workflow =~ "echo \"release_created=false\" >> \"$GITHUB_OUTPUT\""
    assert release_workflow =~ "workflow_dispatch bypasses Release Please"
    assert release_workflow =~ "recovery-validation:"
    assert release_workflow =~ "name: Validate Recovery Ref"
    assert release_workflow =~ "Check out repository for recovery validation"
    assert release_workflow =~ "fetch-depth: 0"
    assert release_workflow =~ "fetch-tags: true"
    assert release_workflow =~ "Validate recovery-only inputs and lock to an immutable ref"
    assert release_workflow =~ "[[ \"$recovery_ref\" =~ ^[0-9a-f]{40}$ ]]"
    assert release_workflow =~ "git show-ref --verify --quiet \"refs/tags/$recovery_ref\""
    assert release_workflow =~ "echo \"checkout_ref=$recovery_ref\" >> \"$GITHUB_OUTPUT\""
    assert release_workflow =~ "exact 40-character commit SHA or an existing tag"
    assert release_workflow =~ "workflow_dispatch is recovery-only"
    assert release_workflow =~ "ref: ${{ needs.recovery-validation.outputs.checkout_ref }}"

    assert release_workflow =~
             "Confirm recovery checkout is detached to the validated immutable ref"

    assert release_workflow =~ "git checkout --detach HEAD"
    assert release_workflow =~ "Release Please generated PRs are review-only"
    assert release_workflow =~ "id: release"
    assert release_workflow =~ "github.event_name == 'workflow_dispatch'"
    assert release_workflow =~ "github.event_name != 'workflow_dispatch'"
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

    assert release_workflow =~ "needs.recovery-validation.result == 'success'"
    assert release_workflow =~ "needs.release-please.outputs.release_created == 'true'"
    assert release_workflow =~ "always()"

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
    assert supported_surface =~ "host-owned device verification seam"
    assert supported_surface =~ "docs/device-flow-host-guide.md"
    assert supported_surface =~ "Lockspire does not use a demo app"
    assert supported_surface =~ "A `v0.1` preview claim should not say:"
    assert supported_surface =~ "Lockspire is production-ready for unsupported host shapes"

    assert supported_surface =~
             "Generic external `request_uri` handling outside Lockspire's own PAR endpoint"

    assert supported_surface =~ "polling"
    assert supported_surface =~ "token issuance"

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
             "request-object-by-value support, generic external `request_uri` handling, and device flow"

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
    assert onboarding =~ "LockspireVerificationController"
    assert onboarding =~ "lockspire_verification_html"
    assert onboarding =~ "docs/device-flow-host-guide.md"
    assert onboarding =~ "rate limiting"
    assert onboarding =~ "The executable repo proof lives in:"
    assert onboarding =~ "test/integration/install_generator_test.exs"
    assert onboarding =~ "test/integration/phase6_onboarding_e2e_test.exs"
    refute onboarding =~ "production-ready"

    assert ci_workflow =~ "run: mix docs.verify"
    assert release_workflow =~ "environment: hex-publish"
  end

  test "device-flow host guide keeps the verification seam abuse-control contract explicit" do
    guide = File.read!(@device_flow_host_guide_path)

    assert guide =~ "## Host-owned verification seam"
    assert guide =~ "## Anti-phishing rules for `verification_uri_complete`"
    assert guide =~ "verification_uri_complete is prefill-only"
    assert guide =~ "re-display the code"
    assert guide =~ "never approve on GET"
    assert guide =~ "## Rate limiting /verify"
    assert guide =~ "GET /verify"
    assert guide =~ "POST /verify"
    assert guide =~ "trusted IP"
    assert guide =~ "strip separators and whitespace + uppercase"
    assert guide =~ "normalized_user_code"
    assert guide =~ "{normalized_user_code, ip}"
    assert guide =~ "Retry-After"
    assert guide =~ "short `Retry-After`"
    assert guide =~ "stepped or exponential backoff"
    assert guide =~ "fingerprints instead of raw codes"
    assert guide =~ "Lockspire does not provide built-in rate limiting"
    assert guide =~ "Hammer-style"
    assert guide =~ "PlugAttack-style"
  end

  test "phase 31 onboarding and supported surface point to the verification seam truthfully" do
    onboarding = File.read!(@install_and_onboard_path)
    supported_surface = File.read!(@supported_surface_path)

    assert onboarding =~ "LockspireVerificationController"
    assert onboarding =~ "lockspire_verification_html"
    assert onboarding =~ "docs/device-flow-host-guide.md"
    assert onboarding =~ "rate limiting"
    assert onboarding =~ "verification"

    assert supported_surface =~ "host-owned device verification seam"
    assert supported_surface =~ "docs/device-flow-host-guide.md"
    assert supported_surface =~ "polling"
    assert supported_surface =~ "token issuance"
    refute supported_surface =~ "Lockspire-owned browser UI"
  end

  test "planning metadata and repo truth keep PAR scoped to the narrow v1.3 slice" do
    project = File.read!(@project_path)
    roadmap = File.read!(@roadmap_path)
    requirements = File.read!(@requirements_path)
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)
    security = File.read!(@security_policy_path)

    assert project =~ "v1.5 delivered Dynamic Client Registration"
    assert project =~ "v1.2 delivered the narrow PAR wedge"

    assert project =~
             "v1.3 added PAR policy controls, and v1.4 added the narrow JAR request-object slice"

    assert roadmap =~ "v1.3 PAR Policy Controls"
    assert roadmap =~ "Phase 19: Operator UX and Truthful Surface"

    assert roadmap =~
             "19-02: Update discovery/docs/contract tests so support claims match the shipped policy slice"

    assert requirements =~ "v1.3 PAR Policy Controls"
    assert requirements =~ "PARPOL-04"

    assert requirements =~
             "Integrators and maintainers can discover the shipped PAR policy slice through truthful metadata and docs"

    assert readme =~
             "Pushed authorization requests through Lockspire-issued `request_uri` references on the existing authorization code + PKCE path"

    assert supported_surface =~
             "Pushed authorization requests only as Lockspire-issued `request_uri` references that extend the existing authorization code + PKCE flow"

    assert security =~
             "pushed authorization requests only through Lockspire-issued `request_uri` references on the authorization code + PKCE path"

    refute readme =~ "supports broader request-object modes"
    refute supported_surface =~ "Request-object-by-value support is in scope"
    refute security =~ "hosted auth is part of the supported security surface"
  end

  test "operator workflow docs keep PAR policy and effective requirement explicit" do
    operator_admin = File.read!(Path.expand("../../docs/operator-admin.md", __DIR__))

    assert operator_admin =~ "/admin/policies/par"
    assert operator_admin =~ "/admin/clients/:client_id/par-policy"
    assert operator_admin =~ "Global PAR policy"
    assert operator_admin =~ "Client PAR override"
    assert operator_admin =~ "Effective PAR requirement"
  end

  test "supported surface and security docs distinguish capability from policy-resolved requirement" do
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)
    security = File.read!(@security_policy_path)

    for doc <- [readme, supported_surface, security] do
      assert doc =~ "Lockspire-issued `request_uri`"
      assert doc =~ "required"
      assert doc =~ "optional"
    end

    assert supported_surface =~ "global"
    assert supported_surface =~ "client"

    # Explicit exclusions preserved
    for doc <- [readme, supported_surface, security] do
      doc_down = String.downcase(doc)
      assert doc_down =~ "request-object-by-value"
      assert doc_down =~ "generic external `request_uri`"
      assert doc_down =~ "dynamic client registration"
      assert doc_down =~ "device flow"
      assert doc_down =~ "hosted auth"
    end
  end
end
