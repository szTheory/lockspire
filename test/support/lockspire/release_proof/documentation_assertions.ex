defmodule Lockspire.TestSupport.ReleaseProof.DocumentationAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.AdvancedSetupSupportTruth
  alias Lockspire.TestSupport.ClientSecretJwtSupportTruth
  alias Lockspire.TestSupport.ReleaseProof.Paths

  def assert_embedded_host_boundaries! do
    readme = Paths.read!("README.md")
    onboarding = Paths.read!("docs/install-and-onboard.md")
    operator = Paths.read!("docs/operator-admin.md")
    supported_surface = Paths.read!("docs/supported-surface.md")

    assert readme =~ "inside its existing app"
    assert readme =~ "not a hosted auth service"
    assert onboarding =~ "Lockspire stays embedded inside your host app"
    assert onboarding =~ "host-owned seams"
    assert operator =~ "host owns staff sessions, MFA, role checks"

    assert supported_surface =~
             "embedded OAuth/OIDC authorization server library for Phoenix and Elixir"

    assert supported_surface =~ "host-guarded `Lockspire.Web.AdminRouter`"
    refute operator =~ "Lockspire authenticates your operators"
  end

  def assert_security_boundaries! do
    security = Paths.read!("SECURITY.md")
    supported_surface = Paths.read!("docs/supported-surface.md")
    guide = Paths.read!("docs/maintainer-release.md")

    assert security =~ "PKCE S256 required by default"
    assert security =~ "no `alg=none`"

    assert security =~
             "host-owned account databases, login/session implementations, or rate limiting"

    assert security =~
             "external JAR-by-reference, generic external `request_uri` handling, SAML, LDAP, or generic federation features"

    assert supported_surface =~ "canonical public support contract"
    refute Regex.match?(~r/\bcertified\b/, security)
    refute Regex.match?(~r/\bcertified\b/, supported_surface)
    AdvancedSetupSupportTruth.assert_security_policy_deference!(security)
    ClientSecretJwtSupportTruth.assert_release_guide_defers!(guide)
  end

  def assert_protected_resource_guidance! do
    guide = Paths.read!("docs/protect-phoenix-api-routes.md")
    template = Paths.read!("priv/templates/lockspire.install/router.ex")

    AdvancedSetupSupportTruth.assert_protected_routes_guide!(guide)
    assert guide =~ "tenant, object, billing, product, response, and additional rate-limit policy"
    assert template =~ "# BEGIN LOCKSPIRE_PROTECTED_PIPELINE"
    assert template =~ "Lockspire.Plug.VerifyToken"
    assert template =~ "Lockspire.Plug.EnforceSenderConstraints"
    assert template =~ "Lockspire.Plug.RequireToken"
    refute template =~ "dpop_replay_store: MyAppWeb.ProtectedApiReplayStore"
  end
end
