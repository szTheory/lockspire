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
  @oidf_conformance_workflow_path Path.expand(
                                    "../../.github/workflows/oidf-conformance.yml",
                                    __DIR__
                                  )
  @release_please_config_path Path.expand("../../release-please-config.json", __DIR__)
  @release_please_manifest_path Path.expand("../../.release-please-manifest.json", __DIR__)
  @readme_path Path.expand("../../README.md", __DIR__)
  @supported_surface_path Path.expand("../../docs/supported-surface.md", __DIR__)
  @maintainer_conformance_path Path.expand("../../docs/maintainer-conformance.md", __DIR__)
  @phase37_conformance_script_path Path.expand(
                                     "../../scripts/conformance/run_phase37_suite.sh",
                                     __DIR__
                                   )
  @phase37_conformance_plan_path Path.expand(
                                   "../../scripts/conformance/phase37-plan.json",
                                   __DIR__
                                 )
  @security_policy_path Path.expand("../../SECURITY.md", __DIR__)
  @install_and_onboard_path Path.expand("../../docs/install-and-onboard.md", __DIR__)
  @device_flow_host_guide_path Path.expand("../../docs/device-flow-host-guide.md", __DIR__)
  @rar_consent_host_guide_path Path.expand("../../docs/rar-consent-host-guide.md", __DIR__)
  @project_path Path.expand("../../.planning/PROJECT.md", __DIR__)
  @roadmap_path Path.expand("../../.planning/milestones/v1.3-ROADMAP.md", __DIR__)
  @requirements_path Path.expand("../../.planning/milestones/v1.3-REQUIREMENTS.md", __DIR__)
  @fapi2_conformance_plan_path Path.expand("../../scripts/conformance/fapi2-plan.json", __DIR__)
  @templates_registry_path Path.expand("../../lib/lockspire/generators/templates.ex", __DIR__)

  defp mix_version do
    "mix.exs"
    |> File.read!()
    |> then(&Regex.run(~r/version:\s+"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end

  defp manifest_version do
    @release_please_manifest_path
    |> File.read!()
    |> then(&Regex.run(~r/"\."\s*:\s*"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end

  defp newest_changelog_version do
    changelog_versions()
    |> List.first()
  end

  defp changelog_versions do
    "CHANGELOG.md"
    |> File.read!()
    |> then(&Regex.scan(~r/^## \[([0-9]+\.[0-9]+\.[0-9]+)\]/m, &1, capture: :all_but_first))
    |> Enum.map(&List.first/1)
  end

  defp release_workflow_job(name, next_name) do
    @release_workflow_path
    |> File.read!()
    |> then(
      &Regex.run(
        ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
        &1,
        capture: :all_but_first
      )
    )
    |> List.first()
  end

  defp publish_job_section do
    @release_workflow_path
    |> File.read!()
    |> then(&Regex.run(~r/^  publish:\n(.*)\z/ms, &1, capture: :all_but_first))
    |> List.first()
  end

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
    assert guide =~ "`workflow_dispatch` is used, treat it as recovery-only"
    assert guide =~ "exact commit SHA or tag being recovered"
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

  test "release workflow keeps one protected publish lane with recovery-only manual dispatch" do
    release_workflow = File.read!(@release_workflow_path)
    release_please_job = release_workflow_job("release-please", "recovery-validation")
    recovery_validation_job = release_workflow_job("recovery-validation", "publish")
    publish_job = publish_job_section()

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
             "Checked-in version and changelog truth becomes authoritative only after the merged release commit crosses the protected hex-publish environment."

    assert release_workflow =~ "uses: ./.github/actions/release-please"
    assert release_workflow =~ "config-file: release-please-config.json"
    assert release_workflow =~ "manifest-file: .release-please-manifest.json"
    assert release_workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert release_workflow =~ "run: mix release.preflight"
    assert release_workflow =~ "run: mix hex.publish --yes"
    assert release_workflow =~ "needs.recovery-validation.result == 'success'"
    assert release_workflow =~ "needs.release-please.outputs.release_created == 'true'"
    assert release_workflow =~ "always()"
    assert release_please_job =~ "uses: ./.github/actions/release-please"
    assert release_please_job =~ "tag_name: ${{ steps.release.outputs.tag_name || '' }}"
    assert recovery_validation_job =~ "recovery_ref must be an exact 40-character commit SHA or an existing tag"
    assert publish_job =~ "environment: hex-publish"
    assert publish_job =~ "run: mix release.preflight"
    assert publish_job =~ "run: mix hex.publish --yes"
    refute release_please_job =~ "run: mix release.preflight"
    refute release_please_job =~ "run: mix hex.publish --yes"
    refute recovery_validation_job =~ "run: mix release.preflight"
    refute recovery_validation_job =~ "run: mix hex.publish --yes"

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
    assert mix_version() == "1.0.0"
    assert changelog =~ "lockspire-v1.0.0"
    assert changelog =~ "one `lockspire` package"
    assert mixfile =~ "\"Changelog\" => \"https://hexdocs.pm/lockspire/changelog.html\""
    assert mixfile =~ "\"Docs\" => \"https://hexdocs.pm/lockspire\""
    assert mixfile =~ "\"Supported surface\" => \"https://hexdocs.pm/lockspire/supported-surface.html\""
    assert release_workflow =~ "uses: ./.github/actions/release-please"
    assert release_workflow =~ "config-file: release-please-config.json"
    assert release_workflow =~ "manifest-file: .release-please-manifest.json"
    assert release_workflow =~ "outputs:"
    assert release_workflow =~ "tag_name: ${{ steps.release.outputs.tag_name || '' }}"
    assert release_workflow =~ "Release Please selected root tag ${{ steps.release.outputs.tag_name }}"
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

    assert mix_version() == "1.0.0"
    assert manifest_version() == "1.0.0"
    assert newest_changelog_version() == "1.0.0"
    assert changelog_versions() == ["1.0.0", "0.2.0", "0.1.2", "0.1.1"]

    assert supported_surface =~ "canonical public support contract"

    for doc <- [readme, security, guide] do
      assert doc =~ "docs/supported-surface.md"
    end

    assert guide =~ "## Release candidate checklist"
    assert guide =~ "checked-in release-candidate contract end to end"
    assert guide =~ "target is `lockspire-v1.0.0`"
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

    assert guide =~ "Repo-owned proof:"
    assert guide =~ "GitHub settings proof:"
    assert guide =~ "Workflow-run proof:"
    assert guide =~ "Release candidate checklist"
    assert guide =~ "review-only evidence"
    assert guide =~ "only authoritative proof of authenticated `mix release.preflight` and `mix hex.publish --yes`"
    assert guide =~ "Protected-environment proof starts only when the `publish` job"
    assert guide =~ "Repo-owned commands stop at `mix ci`"
    assert supported_surface =~ "canonical public support contract"

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

    assert mixfile =~ "\"conformance.phase37\": ["
    assert mixfile =~ "test/integration/phase37_protocol_strictness_e2e_test.exs"
    assert mixfile =~ "cmd bash scripts/conformance/run_phase37_suite.sh"
    assert mixfile =~ "\"conformance.phase37\": :test"

    assert release_workflow =~ "mix release.preflight"
    assert release_workflow =~ "mix hex.publish --yes"

    assert oidf_conformance_workflow =~ "workflow_dispatch:"
    assert oidf_conformance_workflow =~ "schedule:"
    assert oidf_conformance_workflow =~ "MIX_ENV=test mix conformance.phase37"
    assert oidf_conformance_workflow =~ "LOCKSPIRE_PHASE37_MODE: hosted"
    refute oidf_conformance_workflow =~ "pull_request:"
  end

  test "GA docs keep the embedded Phoenix wedge explicit and pin the narrow DPoP surface" do
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)

    assert readme =~ "current release"
    assert readme =~ "inside its existing app"
    assert readme =~ "The public support contract"
    assert readme =~ "authoritative support contract"
    assert readme =~ "Generator-backed install and onboarding"
    assert readme =~ "not a hosted auth service"
    assert readme =~ "What Lockspire is not"
    assert readme =~ "For exact scope, non-claims, and repo-owned proof"

    assert supported_surface =~ "Lockspire `1.0.0` is a GA release"

    assert supported_surface =~
             "embedded OAuth/OIDC authorization server library for Phoenix and Elixir"

    assert supported_surface =~ "Authorization code flow with PKCE S256"
    assert supported_surface =~ "One canonical Phoenix onboarding path"
    assert supported_surface =~ "second topology"
    assert supported_surface =~ "conn.assigns.current_scope.user"
    assert supported_surface =~ "mix lockspire.verify"
    assert supported_surface =~ "mix lockspire.upgrade"

    assert supported_surface =~
             "Pushed authorization requests only as Lockspire-issued `request_uri` references"

    assert supported_surface =~ "OIDC discovery and JWKS"
    assert supported_surface =~ "resource_indicators_supported"
    assert supported_surface =~ "authorization_details_types_supported"
    assert supported_surface =~ "docs/rar-consent-host-guide.md"
    assert supported_surface =~ "host-owned device verification seam"
    assert supported_surface =~ "docs/device-flow-host-guide.md"
    assert supported_surface =~ "canonical public support contract"
    assert supported_surface =~ "README, `SECURITY.md`, and maintainer-only release guidance point back to this file"
    assert supported_surface =~ "primary public proof story"
    assert supported_surface =~ "A 1.0 GA claim should not say:"
    assert supported_surface =~ "Lockspire is production-ready for unsupported host shapes"

    assert supported_surface =~
             "Generic external `request_uri` handling outside Lockspire's own PAR endpoint"

    assert supported_surface =~ "polling"
    assert supported_surface =~ "token issuance"

    assert supported_surface =~
             "DPoP on token requests, the Lockspire-owned `userinfo` endpoint, and truthful introspection visibility for active bound tokens"

    assert supported_surface =~ "bearer clients remaining unchanged by default"
    assert supported_surface =~ "Generic host protected-resource middleware remains out of scope"
    assert supported_surface =~ "Lockspire-owned semantic RAR consent rendering"

    refute readme =~ "production-ready"
  end

  test "security and release posture stay inside the supported GA surface" do
    security = File.read!(@security_policy_path)
    onboarding = File.read!(@install_and_onboard_path)
    guide = File.read!(@maintainer_guide_path)
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)

    assert security =~ "Please do not file public issues"
    assert security =~ "Open a GitHub Security Advisory draft"
    assert security =~ "canonical public support contract"
    assert security =~ "does not define a second feature or topology matrix"
    assert security =~ "embedded Phoenix surface the repo currently proves"
    assert security =~ "host-seam contracts documented in repo-owned guides"
    assert security =~ "confidential-client `private_key_jwt` support"
    assert security =~ "secure defaults and FAPI 2.0 Security Profile enforcement"

    assert security =~ "PKCE S256 required by default"
    assert security =~ "no `alg=none`"
    assert security =~ "confidential client uses `jwks_uri`"
    assert security =~ "issuer-string `aud`"

    assert security =~ "host-owned account databases, login/session implementations, or rate limiting"
    assert security =~ "request-object-by-value support, generic external `request_uri` handling, SAML, LDAP, or generic federation features"

    assert guide =~ "inside the 1.0 GA support contract"

    assert guide =~
             "Releases should only claim the supported surface the repo can currently prove."

    assert guide =~
             "authorization code + PKCE, discovery, JWKS, repo-proven `private_key_jwt` on Lockspire-owned direct-client endpoints, userinfo, revocation, introspection, refresh rotation"

    assert guide =~
             "Do not broaden release claims to request-object-by-value support, generic external request_uri handling, unsupported client-auth methods, hosted auth service language, certification language, demo-app proof, or full CIAM positioning."

    assert onboarding =~ "canonical onboarding path is Phoenix-first and generator-first"
    assert onboarding =~ "Lockspire stays embedded inside your host app"
    assert onboarding =~ "mix lockspire.verify"
    assert onboarding =~ "mix lockspire.upgrade"
    assert onboarding =~ "Lockspire-managed scaffolding"
    assert onboarding =~ "host-owned seams"
    assert onboarding =~ "conn.assigns.current_scope.user"
    assert onboarding =~ "host-owned session seam"
    assert onboarding =~ "interaction resume"
    assert onboarding =~ "authorization-code + PKCE exchange"
    assert onboarding =~ "docs/private-key-jwt-host-guide.md"
    assert onboarding =~ "LockspireVerificationController"
    assert onboarding =~ "lockspire_verification_html"
    assert onboarding =~ "docs/device-flow-host-guide.md"
    assert onboarding =~ "docs/rar-consent-host-guide.md"
    assert onboarding =~ "custom RAR consent"
    assert onboarding =~ "rate limiting"
    assert onboarding =~ "manifest-tracked managed scaffolding"
    assert onboarding =~ "The executable repo proof lives in:"
    assert onboarding =~ "test/integration/install_generator_test.exs"
    assert onboarding =~ "test/integration/phase6_onboarding_e2e_test.exs"
    assert onboarding =~ "host login"
    assert onboarding =~ "compile-time dependency on Sigra"
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
    assert onboarding =~ "device polling"
    assert onboarding =~ "`slow_down`"
    assert onboarding =~ "host-owned `/verify` seam"

    assert supported_surface =~ "host-owned device verification seam"
    assert supported_surface =~ "docs/device-flow-host-guide.md"
    assert supported_surface =~ "Device authorization flow"
    assert supported_surface =~ "device polling"
    assert supported_surface =~ "device authorization endpoint"
    assert supported_surface =~ "token redemption"
    assert supported_surface =~ "not a Lockspire-owned browser UI"
  end

  test "sigra companion docs keep the host seam narrow and topology guidance truthful" do
    sigra_companion = File.read!(Path.expand("../../docs/sigra-companion-host.md", __DIR__))
    onboarding = File.read!(@install_and_onboard_path)
    supported_surface = File.read!(@supported_surface_path)

    assert sigra_companion =~ "must **not** import Sigra at compile time"
    assert sigra_companion =~ "conn.assigns.current_scope.user"
    assert sigra_companion =~ "create a second install topology"
    assert sigra_companion =~ "stable internal identifier"
    assert sigra_companion =~ "return_to"
    assert sigra_companion =~ "interaction_id"
    assert sigra_companion =~ "phase6_onboarding_e2e_test.exs"
    assert sigra_companion =~ "unauthenticated `/authorize` -> host login -> interaction resume -> consent -> token exchange"

    assert onboarding =~ "docs/sigra-companion-host.md"
    assert supported_surface =~ "guidance for the host-owned seam rather than a second topology"
  end

  test "phase 58 docs and release contract pin the rar consent seam and discovery claims" do
    guide = File.read!(@rar_consent_host_guide_path)
    onboarding = File.read!(@install_and_onboard_path)
    supported_surface = File.read!(@supported_surface_path)
    mixfile = File.read!("mix.exs")

    assert guide =~ "payment_initiation"
    assert guide =~ "authorization_details"
    assert guide =~ "host app owns the consent UX"
    assert guide =~ "Lockspire validates and persists `authorization_details`"
    assert guide =~ "lockspire_consent_live.ex"
    assert guide =~ "interaction_handler.ex"

    assert onboarding =~ "docs/rar-consent-host-guide.md"
    assert onboarding =~ "generated `lockspire_consent_live.ex` seam"

    assert supported_surface =~ "resource_indicators_supported"
    assert supported_surface =~ "authorization_details_types_supported"
    assert supported_surface =~ "docs/rar-consent-host-guide.md"
    assert supported_surface =~ "payment_initiation"

    assert mixfile =~ "\"docs/rar-consent-host-guide.md\""
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

    assert project =~ "v1.3 added PAR policy controls"
    assert project =~ "v1.4 added the narrow JAR request-object slice"

    assert roadmap =~ "v1.3 PAR Policy Controls"
    assert roadmap =~ "Phase 19: Operator UX and Truthful Surface"

    assert roadmap =~
             "19-02: Update discovery/docs/contract tests so support claims match the shipped policy slice"

    assert requirements =~ "v1.3 PAR Policy Controls"
    assert requirements =~ "PARPOL-04"

    assert requirements =~
             "Integrators and maintainers can discover the shipped PAR policy slice through truthful metadata and docs"

    assert readme =~ "public support contract for the current release lives in"
    assert readme =~ "For exact scope, non-claims, and repo-owned proof"

    assert supported_surface =~
             "Pushed authorization requests only as Lockspire-issued `request_uri` references that extend the existing authorization code + PKCE flow"

    assert security =~ "canonical public support contract"
    assert security =~ "request-object-by-value support, generic external `request_uri` handling"

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

    assert supported_surface =~ "Lockspire-issued `request_uri`"
    assert supported_surface =~ "required"
    assert supported_surface =~ "optional"
    assert readme =~ "canonical support contract"
    assert security =~ "canonical public support contract"

    assert supported_surface =~ "global"
    assert supported_surface =~ "client"

    readme_down = String.downcase(readme)
    assert readme_down =~ "hosted auth"
    assert readme_down =~ "supported-surface"

    security_down = String.downcase(security)
    assert security_down =~ "request-object-by-value"
    assert security_down =~ "generic external `request_uri`"
    assert security_down =~ "canonical support contract"
    assert security_down =~ "hosted auth"
    assert security_down =~ "device flow seam"

    supported_surface_down = String.downcase(supported_surface)
    assert supported_surface_down =~ "device flow"
    assert supported_surface_down =~ "hosted auth"
    refute supported_surface_down =~ "device flow polling and token issuance"
  end

  test "phase 37 conformance docs and wiring stay tied to executable proof" do
    supported_surface = File.read!(@supported_surface_path)
    maintainer_conformance = File.read!(@maintainer_conformance_path)
    workflow = File.read!(@oidf_conformance_workflow_path)
    script = File.read!(@phase37_conformance_script_path)
    plan = File.read!(@phase37_conformance_plan_path)
    mixfile = File.read!("mix.exs")

    assert supported_surface =~ "test/integration/phase37_protocol_strictness_e2e_test.exs"
    assert supported_surface =~ "repo-owned proof"
    assert supported_surface =~ "canonical public support contract"
    refute supported_surface =~ "docs/maintainer-conformance.md"
    refute supported_surface =~ "scripts/conformance/phase37-plan.json"
    refute supported_surface =~ "mix conformance.phase37"
    refute supported_surface =~ ".artifacts/conformance/phase37"

    assert maintainer_conformance =~ "phase37_protocol_strictness_e2e_test.exs"
    assert maintainer_conformance =~ "docs/supported-surface.md"
    assert maintainer_conformance =~ "repo-native"
    assert maintainer_conformance =~ "optional"
    assert maintainer_conformance =~ "supplemental"
    assert maintainer_conformance =~ "not part of the public support contract"
    assert maintainer_conformance =~ "not a required release gate"
    assert maintainer_conformance =~ "not milestone-closing proof"
    assert maintainer_conformance =~ ".artifacts/conformance/phase37"
    assert maintainer_conformance =~ "third-party cookie"
    assert maintainer_conformance =~ "browser cookie"
    assert maintainer_conformance =~ "LOCKSPIRE_TEST_DB_HOST"
    assert maintainer_conformance =~ "OIDF_CONFORMANCE_SERVER"

    assert maintainer_conformance =~ "manual maintainer step"
    refute maintainer_conformance =~ "certified"
    refute maintainer_conformance =~ "completed certification"
    assert maintainer_conformance =~ "mTLS"
    assert maintainer_conformance =~ "private_key_jwt"
    refute maintainer_conformance =~ "definitive verification"
    refute maintainer_conformance =~ "the OIDF suite as the release gate"

    assert workflow =~ "workflow_dispatch:"
    assert workflow =~ "schedule:"
    assert workflow =~ "MIX_ENV=test mix conformance.phase37"
    assert workflow =~ "bash scripts/conformance/run_phase37_suite.sh"

    assert script =~ ".artifacts/conformance/phase37"
    assert script =~ "phase37-plan.json"
    assert script =~ "run-test-plan.py"
    assert plan =~ "oidcc-prompt-none-not-logged-in"
    assert plan =~ "oidcc-max-age-10000"

    assert mixfile =~ "\"conformance.phase37\": ["
  end

  test "phase 42 preparatory lane docs stay truthful about certification and feature support" do
    maintainer_conformance = File.read!(@maintainer_conformance_path)
    workflow = File.read!(@oidf_conformance_workflow_path)

    # Must contain "preparatory" wording and unsupported feature disclaimers
    assert maintainer_conformance =~ "preparatory OIDF lane"
    assert maintainer_conformance =~ "Phase 42 wires the lane for Phase 43 consumption"
    assert maintainer_conformance =~ "does not claim pass-ready certification"
    assert maintainer_conformance =~
             "does not imply support for mTLS or broader protocol surface beyond the repo-proven embedded-library wedge"

    assert maintainer_conformance =~
             "Lockspire's shipped runtime now supports the repo-proven `private_key_jwt` slice"

    assert maintainer_conformance =~ "validate the prerequisites for this check"
    assert maintainer_conformance =~ "does NOT execute `scripts/conformance/fapi2-check.sh`"

    # Must not over-claim
    refute maintainer_conformance =~ "fully certified"
    refute maintainer_conformance =~ "Phase 43 completion"

    # Artifact/CI truth
    assert workflow =~ "uses: actions/upload-artifact@v4"
    assert workflow =~ "mix lockspire.oidf_conformance"
  end

  test "phase 43 FAPI 2.0 milestone claims stay truthful and bounded (D-12, D-19, D-20)" do
    security = File.read!(@security_policy_path)
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)
    maintainer_conformance = File.read!(@maintainer_conformance_path)
    fapi2_plan = File.read!(@fapi2_conformance_plan_path)
    templates_registry = File.read!(@templates_registry_path)
    workflow = File.read!(@oidf_conformance_workflow_path)

    positive_pinned_strings = [
      "FAPI 2.0 Security Profile",
      "PAR",
      "DPoP",
      "ES256/PS256",
      "exact-match redirect URIs",
      "RFC 9207",
      "authorization_response_iss_parameter_supported",
      "require_pushed_authorization_requests"
    ]

    for pinned <- positive_pinned_strings do
      assert supported_surface =~ pinned,
             "expected docs/supported-surface.md to contain pinned positive FAPI 2.0 string #{inspect(pinned)}"
    end

    for {doc_name, doc_text} <- [
          {"SECURITY.md", security},
          {"README.md", readme},
          {"docs/supported-surface.md", supported_surface}
        ] do
      refute Regex.match?(~r/\bcertified\b/, doc_text),
             "#{doc_name} must NOT contain the literal word 'certified'"
    end

    assert security =~ "FAPI 2.0 Security Profile"
    assert security =~ "DPoP"
    assert security =~ "mTLS"
    assert security =~ "OIDF"
    assert readme =~ "supported-surface"

    oidf_plan_pins = [
      "fapi2-security-profile-final-test-plan",
      "plain_fapi",
      "private_key_jwt",
      "dpop",
      "unsigned",
      "plain_response"
    ]

    for pinned <- oidf_plan_pins do
      assert maintainer_conformance =~ pinned,
             "expected docs/maintainer-conformance.md to pin #{inspect(pinned)}"

      assert fapi2_plan =~ pinned,
             "expected scripts/conformance/fapi2-plan.json to pin #{inspect(pinned)}"
    end

    assert maintainer_conformance =~
             "This conformance guide is still a maintainer workflow doc, not the product contract"

    assert maintainer_conformance =~
             "the repo's runtime truth remains defined by the supported-surface docs plus executable proof"

    assert templates_registry =~ "fapi_smoke_e2e_test.exs",
           "expected templates registry to register the FAPI smoke E2E test template"

    assert workflow =~ "mix lockspire.oidf_conformance"
  end
end
