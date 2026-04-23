defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  @readme_path Path.expand("../../README.md", __DIR__)
  @install_guide_path Path.expand("../../docs/install-and-onboard.md", __DIR__)
  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
  @supported_surface_path Path.expand("../../docs/supported-surface.md", __DIR__)
  @security_policy_path Path.expand("../../SECURITY.md", __DIR__)
  @release_workflow_path Path.expand("../../.github/workflows/release.yml", __DIR__)
  @ci_workflow_path Path.expand("../../.github/workflows/ci.yml", __DIR__)

  test "public docs keep the canonical onboarding path Phoenix-first and Sigra companion-only" do
    readme = File.read!(@readme_path)
    install_guide = File.read!(@install_guide_path)

    assert readme =~ "embedded OAuth/OIDC authorization server for Phoenix applications"
    assert readme =~ "Run `mix lockspire.install`."
    assert readme =~ "Sigra companion host"
    refute readme =~ "required dependency on Sigra"

    assert install_guide =~ "The canonical onboarding path is Phoenix-first and generator-first."
    assert install_guide =~ "mix lockspire.install"
    assert install_guide =~ "mix lockspire.install --sigra-host"
    assert install_guide =~ "It does not add a compile-time dependency on Sigra"
  end

  test "maintainer and release docs keep one contributor gate and one additive release lane" do
    guide = File.read!(@maintainer_guide_path)

    assert guide =~ "run `mix ci`"
    assert guide =~ "`mix ci` is the maintained contributor lane"
    assert guide =~ "`mix release.preflight` stays additive to `mix ci`"
    assert guide =~ "`mix package.publish-dry-run` remains a required release gate"
    assert guide =~ "Release Please PR as review-only evidence"
    assert guide =~ "trusted proof starts only after merge in the protected `hex-publish` lane"
    assert guide =~ "`workflow_dispatch` is used, treat it as recovery-only"
    assert guide =~ "`mix test.fast`"
    assert guide =~ "`mix test.integration`"
    assert guide =~ "`mix test.phase3`"
    assert guide =~ "trusted release workflow"
    assert guide =~ "protected `hex-publish` environment"

    refute guide =~ "mix package.verify"
  end

  test "supported-surface and security docs keep preview claims bounded to implemented scope" do
    supported_surface = File.read!(@supported_surface_path)
    security_policy = File.read!(@security_policy_path)

    assert supported_surface =~
             "Lockspire v0.1 is a focused embedded OAuth/OIDC provider library."

    assert supported_surface =~ "It should not claim:"
    assert supported_surface =~ "certification or formal conformance"
    assert supported_surface =~ "Host-owned login and consent seams"

    assert security_policy =~ "Lockspire’s supported security surface is limited"
    assert security_policy =~ "authorization code + PKCE"
    assert security_policy =~ "Unsupported or out-of-scope surfaces include:"
    assert security_policy =~ "host login/session implementations"
    refute security_policy =~ "SAML support"
  end

  test "release workflow keeps the authenticated publish preflight in the protected environment" do
    release_workflow = File.read!(@release_workflow_path)

    assert release_workflow =~ "environment: hex-publish"
    assert release_workflow =~ "recovery_reason"
    assert release_workflow =~ "workflow_dispatch is recovery-only"
    assert release_workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert release_workflow =~ "run: mix release.preflight"
    assert release_workflow =~ "run: mix hex.publish --yes"

    refute release_workflow =~ "mix package.verify"
  end

  test "workflow files keep critical automation steps pinned and aligned to the contributor gate" do
    ci_workflow = File.read!(@ci_workflow_path)
    release_workflow = File.read!(@release_workflow_path)
    mixfile = File.read!("mix.exs")

    for pinned_action <- [
          "actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd",
          "erlef/setup-beam@8d44588995e53ce789721e96227122a67826542d",
          "actions/cache@0400d5f644dc74513175e3cd8d07132dd4860809"
        ] do
      assert ci_workflow =~ pinned_action
      assert release_workflow =~ pinned_action
    end

    assert mixfile =~ "ci: ["
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
          "run: MIX_ENV=test mix test.fast",
          "run: mix test.integration",
          "run: mix test.phase3"
        ] do
      assert ci_workflow =~ command
    end

    assert release_workflow =~
             "googleapis/release-please-action@16a9c90856f42705d54a6fda1823352bdc62cf38"
  end
end
