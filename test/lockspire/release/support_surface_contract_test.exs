defmodule Lockspire.Release.SupportSurfaceContractTest do
  use ExUnit.Case, async: true
  use Lockspire.TestSupport.ReleaseContractHelpers

  test "adopter docs keep host account and operator boundaries explicit" do
    install_guide = File.read!(@install_and_onboard_path)
    operator_guide = File.read!(@operator_admin_guide_path)
    recipe = File.read!(@saas_adoption_recipe_path)
    supported_surface = File.read!(@supported_surface_path)
    getting_started = File.read!(@readme_path) <> File.read!("docs/getting-started.md")

    for doc <- [install_guide, operator_guide, recipe] do
      assert doc =~ "Lockspire.Web.AdminRouter"
      assert doc =~ "operator"
      assert doc =~ "host"
    end

    assert install_guide =~ "Lockspire does not authenticate your staff"
    assert operator_guide =~ "pipe_through [:browser, :require_operator]"
    assert operator_guide =~ "host owns staff sessions, MFA, role checks"
    assert recipe =~ "stable subject"
    assert recipe =~ "Store the printed `client_secret` immediately"
    assert recipe =~ "tenant checks, business authorization, rate limiting"
    assert supported_surface =~ "host-guarded `Lockspire.Web.AdminRouter`"
    assert getting_started =~ "docs/saas-adoption-recipe.md"

    refute recipe =~ "Lockspire owns operator authentication"
    refute operator_guide =~ "Lockspire authenticates your operators"
  end

  test "GA docs keep the embedded Phoenix wedge explicit and pin the narrow protected-route surface" do
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
    refute readme =~ "Lockspire `1.0.0` is the GA release"

    assert supported_surface =~ "The current GA line currently supports"
    refute supported_surface =~ "Lockspire `1.0.0` is a GA release"

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
    assert supported_surface =~ "OIDC CIBA"
    assert supported_surface =~ "Poll, Ping, and Push delivery modes"
    assert supported_surface =~ "canonical public support contract"
    assert supported_surface =~ "DPoP-Nonce"

    assert supported_surface =~
             "README, `SECURITY.md`, and maintainer-only release guidance point back to this file"

    assert supported_surface =~ "primary public proof story"
    assert supported_surface =~ "A 1.0 GA claim should not say:"
    assert supported_surface =~ "Lockspire is production-ready for unsupported host shapes"

    assert supported_surface =~
             "Generic external `request_uri` handling outside Lockspire's own PAR endpoint"

    assert supported_surface =~ "polling"
    assert supported_surface =~ "token issuance"
    assert supported_surface =~ "Lockspire-owned semantic RAR consent rendering"
    assert supported_surface =~ "docs/protect-phoenix-api-routes.md"
    assert supported_surface =~ "phase81_generated_host_route_protection_e2e_test.exs"

    refute readme =~ "production-ready"
  end

  test "security and release posture stay inside the supported GA surface" do
    security = File.read!(@security_policy_path)
    onboarding = File.read!(@install_and_onboard_path)
    client_secret_jwt_guide = File.read!(@client_secret_jwt_host_guide_path)
    guide = File.read!(@maintainer_guide_path)
    ci_workflow = File.read!(@ci_workflow_path)
    _release_workflow = File.read!(@release_workflow_path)

    assert security =~ "Please do not file public issues"
    assert security =~ "Open a GitHub Security Advisory draft"
    assert security =~ "canonical public support contract"
    assert security =~ "does not define a second feature or topology matrix"
    assert security =~ "embedded Phoenix surface the repo currently proves"
    assert security =~ "host-seam contracts documented in repo-owned guides"
    assert security =~ "confidential-client `private_key_jwt` support"
    assert security =~ "JAR request objects by value"
    assert security =~ "secure defaults and FAPI 2.0 Security Profile enforcement"

    assert security =~ "PKCE S256 required by default"
    assert security =~ "no `alg=none`"
    assert security =~ "issuer-string `aud`"

    assert security =~
             "host-owned account databases, login/session implementations, or rate limiting"

    assert security =~
             "external JAR-by-reference, generic external `request_uri` handling, SAML, LDAP, or generic federation features"

    assert guide =~ "inside the 1.0 GA support contract"

    assert guide =~
             "Releases should only claim the supported surface the repo can currently prove."

    assert guide =~
             "authorization code + PKCE, PAR, JAR request objects by value on the shipped `/authorize` and `/par` paths, discovery, JWKS, repo-proven `private_key_jwt` on Lockspire-owned direct-client endpoints, userinfo, revocation, introspection, refresh rotation"

    assert guide =~
             "Do not broaden release claims to external JAR-by-reference, generic external request_uri handling, unsupported client-auth methods, hosted auth service language, certification language, demo-app proof, or full CIAM positioning."

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
    assert onboarding =~ "docs/protect-phoenix-api-routes.md"
    assert onboarding =~ "canonical optional host-route path"

    assert onboarding =~
             "Host Phoenix API routes can enforce route-level `scopes:` and `audience:` restrictions"

    assert onboarding =~ "phase81_generated_host_route_protection_e2e_test.exs"
    assert onboarding =~ "docs/private-key-jwt-host-guide.md"
    assert onboarding =~ "docs/client-secret-jwt-host-guide.md"
    assert onboarding =~ "bounded reactive rollover truth"
    assert onboarding =~ "mix lockspire.doctor remote-jwks --client <client_id>"
    assert onboarding =~ "does not diagnose runtime remote-`jwks_uri` incidents"
    assert onboarding =~ "LockspireVerificationController"
    assert onboarding =~ "lockspire_verification_html"
    assert onboarding =~ "docs/device-flow-host-guide.md"
    assert onboarding =~ "docs/rar-consent-host-guide.md"
    assert onboarding =~ "custom RAR consent"
    assert onboarding =~ "rate limiting"
    assert onboarding =~ "manifest-tracked managed scaffolding"
    assert onboarding =~ "/end_session/complete"
    assert onboarding =~ "durable back-channel delivery through Oban and Req"
    assert onboarding =~ "The executable repo proof lives in:"
    assert onboarding =~ "test/integration/install_generator_test.exs"
    assert onboarding =~ "test/integration/phase6_onboarding_e2e_test.exs"
    assert onboarding =~ "host login"
    assert onboarding =~ "compile-time dependency on Sigra"
    refute onboarding =~ "production-ready"

    assert_canonical_support_contract!(File.read!(@supported_surface_path))
    assert_host_guide!(client_secret_jwt_guide)
    assert_release_guide_defers!(guide)

    assert ci_workflow =~ "run: mix docs.verify"
  end

  test "advanced-setup support contract stays pinned semantically across canonical and derived docs" do
    supported_surface = File.read!(@supported_surface_path)
    onboarding = File.read!(@install_and_onboard_path)
    private_key_jwt_guide = File.read!(@private_key_jwt_host_guide_path)
    mtls_guide = File.read!(@mtls_host_guide_path)
    protected_routes_guide = File.read!(@protect_phoenix_api_routes_path)
    operator_admin_guide = File.read!(@operator_admin_guide_path)
    dynamic_registration_guide = File.read!(@dynamic_registration_guide_path)

    assert_advanced_setup_support_contract!(supported_surface)
    assert_install_and_onboard_guide!(onboarding)
    assert_private_key_jwt_host_guide!(private_key_jwt_guide)
    assert_mtls_host_guide!(mtls_guide)
    assert_protected_routes_guide!(protected_routes_guide)
    assert_operator_admin_guide!(operator_admin_guide)
    assert_dynamic_registration_guide!(dynamic_registration_guide)
  end

  test "canonical lockspire_protected_api pipeline is byte-identical across the four RECIPE-01 sites" do
    files = [
      {@protect_phoenix_api_routes_path, :elixir_in_markdown_fence},
      {@adoption_demo_router_path, :elixir},
      {@install_template_router_path, :elixir_in_commented_heredoc},
      {@adoption_smoke_script_path, :python_commented}
    ]

    hashes = Enum.map(files, fn {path, kind} -> {path, canonical_hash!(path, kind)} end)

    for {path_a, hash_a} <- hashes, {path_b, hash_b} <- hashes, path_a < path_b do
      assert hash_a == hash_b,
             "canonical pipeline block drifted between #{Path.relative_to_cwd(path_a)} and #{Path.relative_to_cwd(path_b)}"
    end
  end

  test "canonical protected-route guidance uses the configured durable replay default" do
    guide = File.read!(@protect_phoenix_api_routes_path)
    template = File.read!(@install_template_router_path)

    assert guide =~ "configured Lockspire repository"
    assert guide =~ "advanced override"
    assert guide =~ "Lockspire.AccessToken.subject(access_token)"
    assert guide =~ "Lockspire.AccessToken.confirmation(access_token)"
    assert guide =~ "tenant, object, billing, product, response, and additional rate-limit policy"

    refute template =~ "dpop_replay_store: MyAppWeb.ProtectedApiReplayStore"
  end

  test "v1.37 resource-server and registration support contract stays additive and bounded" do
    supported_surface = File.read!(@supported_surface_path)
    guide = File.read!(@protect_phoenix_api_routes_path)
    upgrade = File.read!(Path.join(Path.dirname(@upgrading_v1_27_path), "v1.37.md"))

    for reader <- ["subject/1", "scopes/1", "audiences/1", "expires_at/1", "confirmation/1"] do
      assert guide =~ "Lockspire.AccessToken.#{reader}"
      assert upgrade =~ "Lockspire.AccessToken.#{reader}"
    end

    assert guide =~ "configured Lockspire repository"
    assert guide =~ "advanced override"
    assert guide =~ "tenant, object, billing, product, response, and additional rate-limit policy"

    assert supported_surface =~ "built-in `openid`"
    assert supported_surface =~ "device-code-only clients without redirect URIs"
    assert supported_surface =~ "exactly one inline `jwks` or HTTPS `jwks_uri`"

    assert supported_surface =~
             "authorization-code or `code` response shape requires non-empty redirect URIs"

    refute supported_surface =~ "formal certification"

    assert upgrade =~ "additive"
    assert upgrade =~ "raw `claims` map remains available"
    assert upgrade =~ "configured Lockspire repository"
    assert upgrade =~ "custom replay stores remain supported"
  end

  test "mix lockspire.install never prompts for or branches on access-token format (SCAFFOLD-02, D-02 #1)" do
    # The install task + generator SOURCE must never gain a token-format decision.
    # The install TEMPLATE is intentionally NOT a refute target: it legitimately carries
    # `audience:`/`enforce_audience:` in the commented canonical pipeline, and the generator
    # renders that template at runtime via EEx.eval_file, so the generator source itself stays
    # clean. SCAFFOLD-02 is already satisfied behaviorally (Phases 97/101); this is its drift fence.
    for path <- [@install_task_path, @install_generator_path] do
      src = File.read!(path)

      refute src =~ ~r/access_token_format|token[_ ]format|:jwt|:opaque/i,
             "install task/generator must never prompt for or branch on token format (SCAFFOLD-02): " <>
               "#{Path.relative_to_cwd(path)}"
    end
  end

  test "install-template canonical lockspire_protected_api block stays fully commented (SCAFFOLD-01, D-02 #2)" do
    # CRITICAL (Pitfall 3): assert against the RAW template bytes, NOT
    # extract_canonical_pipeline!/2's output — that helper's normalize/2 STRIPS the leading `# `
    # prefix, so asserting "every line commented" against it is a tautology that always passes.
    # The "still commented / uncomment-ready" property REQUIRES the raw File.read! bytes.
    raw = File.read!(@install_template_router_path)

    [body] =
      Regex.run(
        ~r/# BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n(.*?)\n[ \t]*# END LOCKSPIRE_PROTECTED_PIPELINE/ms,
        raw,
        capture: :all_but_first
      )

    for line <- String.split(body, "\n"), String.trim(line) != "" do
      assert line =~ ~r/^\s*#/,
             "install-template canonical lockspire_protected_api block must stay fully commented " <>
               "(SCAFFOLD-01): offending line #{inspect(line)}"
    end
  end

  test "v1.27 migration guide pins the honest runtime opt-out and nil-inherit naming (MIGRATE-01, D-09/D-10)" do
    # Pins docs/upgrading/v1.27.md against drift from shipped behavior. A failure here means the
    # migration prose diverged from the real runtime opt-out (D-09) or the affected-client semantics
    # (D-10) — fix the GUIDE to match shipped behavior, do not relax this assertion.
    doc = File.read!(@upgrading_v1_27_path)

    # D-09: the HONEST one-line runtime opt-out is a ServerPolicy call, not a config key.
    assert doc =~ "put_access_token_format(:opaque)",
           "v1.27 guide must document the runtime opt-out put_access_token_format(:opaque) (MIGRATE-01, D-09)"

    # D-10: affected clients are exactly those whose access_token_format is nil (they inherit :jwt).
    assert doc =~ ~r/access_token_format.{0,40}nil/,
           "v1.27 guide must name affected clients as those whose access_token_format is nil (MIGRATE-01, D-10)"

    # The flip narrative: both formats named.
    assert doc =~ "opaque" and doc =~ ":jwt",
           "v1.27 guide must explain the opaque->:jwt default flip (MIGRATE-01)"

    # D-09: there is NO config :lockspire key for this — refuse a phantom no-op instruction.
    refute doc =~ ~r/config :lockspire.*access_token_format/,
           "v1.27 guide must NOT point operators at a phantom config :lockspire access_token_format key (MIGRATE-01, D-09)"
  end

  test "canonical lockspire_protected_api pipeline declares a non-empty audience: across all four RECIPE-01 sites (D-07)" do
    files = [
      {@protect_phoenix_api_routes_path, :elixir_in_markdown_fence},
      {@adoption_demo_router_path, :elixir},
      {@install_template_router_path, :elixir_in_commented_heredoc},
      {@adoption_smoke_script_path, :python_commented}
    ]

    for {path, kind} <- files do
      bytes = extract_canonical_pipeline!(path, kind)

      case Regex.run(
             ~r/Lockspire\.Plug\.VerifyToken,[^\n]*\baudience:\s*"([^"]+)"/,
             bytes,
             capture: :all_but_first
           ) do
        [captured] when is_binary(captured) ->
          assert String.length(captured) > 0,
                 "expected non-empty audience: value on the Lockspire.Plug.VerifyToken line in " <>
                   "#{Path.relative_to_cwd(path)} (D-07 cross-API token reuse defense)"

        _ ->
          flunk(
            "missing or empty audience: keyword on the Lockspire.Plug.VerifyToken line in " <>
              "#{Path.relative_to_cwd(path)} (D-07 cross-API token reuse defense). The canonical " <>
              "lockspire_protected_api pipeline MUST declare audience: \"...\" on the VerifyToken " <>
              "declaration so the install template's enforce_audience: true raise stays meaningful."
          )
      end
    end
  end

  test "docs/saas-adoption-recipe.md cross-links to the canonical pipeline rather than restating plug names" do
    recipe = File.read!(@saas_adoption_recipe_path)

    assert recipe =~ ~r/protect-phoenix-api-routes\.md/,
           "expected docs/saas-adoption-recipe.md to cross-link to docs/protect-phoenix-api-routes.md"

    refute recipe =~
             ~r/`Lockspire\.Plug\.VerifyToken`.*`Lockspire\.Plug\.EnforceSenderConstraints`.*`Lockspire\.Plug\.RequireToken`/s,
           "expected docs/saas-adoption-recipe.md to no longer restate the three plug names in concatenated form"
  end

  test "docs/protect-phoenix-api-routes.md carries the canonical pipeline declaration exactly once (D-15)" do
    page = File.read!(@protect_phoenix_api_routes_path)

    declaration_count =
      page |> String.split("pipeline :lockspire_protected_api do") |> length() |> Kernel.-(1)

    assert declaration_count == 1,
           "expected docs/protect-phoenix-api-routes.md to declare the canonical pipeline exactly once; found #{declaration_count} restatements (D-15 within-file refute)"
  end

  test "maintainer and security docs defer to the canonical advanced-setup contract" do
    guide = File.read!(@maintainer_guide_path)
    security = File.read!(@security_policy_path)

    assert_maintainer_release_deference!(guide)
    assert_security_policy_deference!(security)
    refute_broadened_security_non_claims!(security)
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

  test "private_key_jwt host guide teaches bounded reactive rollover diagnosis and fallback posture" do
    guide = File.read!(@private_key_jwt_host_guide_path)

    assert_private_key_jwt_host_guide!(guide)
    assert guide =~ "publish the new key before first use"
    assert guide =~ "keep the previous key available during the overlap window"
    assert guide =~ "admin client detail screen"
    assert guide =~ "remote_jwks_fetch_failed"
    assert guide =~ "remote_jwks_invalid"
    assert guide =~ "remote_jwks_key_unavailable"
    assert guide =~ "remote_jwks_signature_invalid"
    assert guide =~ "`mix lockspire.verify` is not the right tool"
    assert guide =~ "Lockspire owns:"
    assert guide =~ "The host team owns:"
    assert guide =~ "The client integrator owns:"
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
    sigra_companion = File.read!(Path.expand("../../../docs/sigra-companion-host.md", __DIR__))
    onboarding = File.read!(@install_and_onboard_path)
    supported_surface = File.read!(@supported_surface_path)

    assert sigra_companion =~ "must **not** import Sigra at compile time"
    assert sigra_companion =~ "conn.assigns.current_scope.user"
    assert sigra_companion =~ "create a second install topology"
    assert sigra_companion =~ "stable internal identifier"
    assert sigra_companion =~ "return_to"
    assert sigra_companion =~ "interaction_id"
    assert sigra_companion =~ "phase6_onboarding_e2e_test.exs"
    assert sigra_companion =~ "docs/protect-phoenix-api-routes.md"
    assert sigra_companion =~ "post-token business authorization"

    assert sigra_companion =~
             "unauthenticated `/authorize` -> host login -> interaction resume -> consent -> token exchange"

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
    assert mixfile =~ "\"docs/protect-phoenix-api-routes.md\""
  end

  test "planning metadata and repo truth keep PAR scoped to the narrow v1.3 slice" do
    project = File.read!(@project_path)
    readme = File.read!(@readme_path)
    supported_surface = File.read!(@supported_surface_path)
    security = File.read!(@security_policy_path)

    assert project =~
             "PAR-backed authorization consumption on the existing authorization code + PKCE path was validated in Phase 15."

    assert project =~
             "Discovery, support docs, and SECURITY wording now describe only the shipped PAR slice, validated in Phase 15."

    assert project =~
             "PAR milestone closure and release-runtime hygiene were validated in Phase 16"

    assert readme =~ "public support contract for the current release lives in"
    assert readme =~ "For exact scope, non-claims, and repo-owned proof"

    assert supported_surface =~
             "Pushed authorization requests only as Lockspire-issued `request_uri` references that extend the existing authorization code + PKCE flow"

    assert security =~ "canonical public support contract"
    assert security =~ "external JAR-by-reference, generic external `request_uri` handling"

    refute readme =~ "supports broader request-object modes"
    assert supported_surface =~ "JAR request objects by value"
    assert supported_surface =~ "signed request objects and nested encrypted request objects"
    assert supported_surface =~ "JAR by reference through external request-object URLs"
    refute security =~ "hosted auth is part of the supported security surface"
  end

  test "operator workflow docs keep PAR policy and effective requirement explicit" do
    operator_admin = File.read!(Path.expand("../../../docs/operator-admin.md", __DIR__))

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
    assert security_down =~ "external jar-by-reference"
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
    refute workflow =~ "schedule:"
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
    assert workflow =~ "uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a"
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
    assert supported_surface =~ "automatic `DPoP-Nonce` challenge and retry support"

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

  test "phase 73 JWT introspection support contract stays narrow and truthful" do
    supported_surface = File.read!(@supported_surface_path)

    assert supported_surface =~ "RFC 9701 JWT introspection responses"
    assert supported_surface =~ "Accept: application/token-introspection+jwt"
    assert supported_surface =~ "Content-Type: application/token-introspection+jwt"
    assert supported_surface =~ "Error responses stay on the standard JSON OAuth error path"
    assert supported_surface =~ "No host MIME registration is required"
    assert supported_surface =~ "\"active\": false"
    assert supported_surface =~ "\"token_introspection\": {"

    assert supported_surface =~
             "does not claim introspection encryption, new discovery metadata, or strict mode enforcement"
  end

  test "phase 74 message-signing support contract distinguishes optional capability from strict enforcement" do
    supported_surface = File.read!(@supported_surface_path)

    assert supported_surface =~
             "JWT-secured authorization response mode (JARM) as an optional authorization-response representation"

    assert supported_surface =~ "FAPI 2.0 Message Signing strict enforcement"

    assert supported_surface =~
             "baseline optional JARM and RFC 9701 capabilities above become explicit requirements"

    assert supported_surface =~ "requires JARM"
    assert supported_surface =~ "requires `Accept: application/token-introspection+jwt`"
    assert supported_surface =~ "mixed-mode escape hatches"
    assert supported_surface =~ "does not require JARM encryption"
    assert supported_surface =~ "does not broaden Lockspire into a larger FAPI certification"
  end

  test "all four RECIPE-01 sites order VerifyToken → EnforceSenderConstraints → RequireToken (BIND-03/D-05)" do
    files = [
      {@protect_phoenix_api_routes_path, :elixir_in_markdown_fence},
      {@adoption_demo_router_path, :elixir},
      {@install_template_router_path, :elixir_in_commented_heredoc},
      {@adoption_smoke_script_path, :python_commented}
    ]

    for {path, kind} <- files do
      bytes = extract_canonical_pipeline!(path, kind)
      v = byte_offset(bytes, "Lockspire.Plug.VerifyToken")
      e = byte_offset(bytes, "Lockspire.Plug.EnforceSenderConstraints")
      r = byte_offset(bytes, "Lockspire.Plug.RequireToken")

      assert v < e and e < r,
             "canonical pipeline in #{Path.relative_to_cwd(path)} must order " <>
               "VerifyToken → EnforceSenderConstraints → RequireToken (BIND-03/D-05)"
    end
  end
end
