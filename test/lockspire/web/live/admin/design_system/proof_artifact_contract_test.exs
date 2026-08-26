defmodule Lockspire.Web.Live.Admin.DesignSystem.ProofArtifactContractTest do
  use ExUnit.Case, async: true
  use Lockspire.AdminContractHelpers

  describe "Rendered HTML security assertion contracts" do
    test "disabled link helper rejects anchor-shaped disabled actions and accepts semantic links" do
      disabled_anchor =
        ~s(<a href="/admin/clients" class="lockspire-admin-btn lockspire-admin-btn-disabled">Disabled link action</a>)

      error =
        assert_raise ExUnit.AssertionError, fn ->
          HtmlAssertions.assert_disabled_links_have_semantics(disabled_anchor)
        end

      assert Exception.message(error) =~ "expected disabled link actions to expose"

      semantic_disabled_link =
        ~s(<span role="link" aria-disabled="true" class="lockspire-admin-btn lockspire-admin-btn-secondary">Disabled link action</span>)

      assert HtmlAssertions.assert_disabled_links_have_semantics(semantic_disabled_link) ==
               semantic_disabled_link
    end

    test "token-like text helper rejects rendered credential and private-key shapes" do
      denied_examples = [
        {"JWT-looking text",
         "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890"},
        {"live-key-looking text", "sk_live_51JxExampleSecretValue"},
        {"cookie/auth-code-like text", "cookie=session_id%3Dabcdef1234567890"},
        {"cookie/auth-code-like text", "authorization_code=SplxlOBeZQQYbYS6WxSbIA"},
        {"private-key-like text", "-----BEGIN PRIVATE KEY-----"}
      ]

      for {label, value} <- denied_examples do
        error =
          assert_raise ExUnit.AssertionError, fn ->
            HtmlAssertions.assert_no_token_like_text("<p>#{value}</p>")
          end

        assert Exception.message(error) =~ "expected rendered HTML to omit #{label}"
      end

      safe_html = "<p>client_secret_jwt support is documented without sample keys.</p>"

      assert HtmlAssertions.assert_no_token_like_text(safe_html) == safe_html
    end
  end

  describe "Browser evidence artifact contracts" do
    test "browser evidence parser accepts strict representative evidence rows" do
      markdown = """
      ## Evidence Rows

      | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
      |---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
      | `/admin` | Orient | 320px | light | default | overview nav -> Configure link | dense cockpit | 320 | 320 | pass | local maintainer note; no screenshots retained | passed denylist | none | contract test pass |
      | `AdminLab.StressSurface` | Internal lab | 1440px | system | reduced-motion | stress fixture tab order | long-data fixture | 1440 | 1440 | pass | internal lab render only; values synthetic | passed denylist | none | component stress pass |
      """

      assert [
               %{
                 "Route / Surface" => "/admin",
                 "Journey" => "Orient",
                 "Viewport" => "320px",
                 "scrollWidth" => 320,
                 "clientWidth" => 320,
                 "Result" => "pass"
               },
               %{
                 "Route / Surface" => "AdminLab.StressSurface",
                 "Journey" => "Internal lab",
                 "Viewport" => "1440px",
                 "scrollWidth" => 1440,
                 "clientWidth" => 1440,
                 "Result" => "pass"
               }
             ] = BrowserEvidence.parse!(markdown)

      assert BrowserEvidence.required_columns() == [
               "Route / Surface",
               "Journey",
               "Viewport",
               "Theme",
               "Motion",
               "Focus path",
               "State",
               "scrollWidth",
               "clientWidth",
               "Result",
               "Scrubbed notes",
               "Sensitive evidence check",
               "Gap note",
               "Deterministic command outcome"
             ]

      assert BrowserEvidence.allowed_results() == ["pass", "fail", "gap", "blocked"]
    end

    test "browser evidence parser rejects malformed artifact rows" do
      missing_columns = """
      | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
      |---|---|---|---|---|---|---|---:|---|---|---|---|---|
      | `/admin` | Orient | 320px | light | default | overview nav | dense | 320 | pass | local note | passed denylist | none | contract test pass |
      """

      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(missing_columns) end
      assert Exception.message(error) =~ "missing required evidence columns"
      assert Exception.message(error) =~ "clientWidth"

      invalid_result = String.replace(valid_browser_evidence_markdown(), "| pass |", "| maybe |")
      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(invalid_result) end
      assert Exception.message(error) =~ ~s(invalid Result "maybe")

      invalid_width =
        String.replace(valid_browser_evidence_markdown(), "| 390 | 390 |", "| wide | 390 |")

      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(invalid_width) end
      assert Exception.message(error) =~ ~s(nonnumeric scrollWidth "wide")

      malformed_route =
        String.replace(valid_browser_evidence_markdown(), "`/admin/tokens`", "`admin/tokens`")

      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(malformed_route) end
      assert Exception.message(error) =~ ~s(malformed Route / Surface "admin/tokens")

      duplicate = valid_browser_evidence_markdown() <> valid_browser_evidence_markdown()
      error = assert_raise ArgumentError, fn -> BrowserEvidence.parse!(duplicate) end
      assert Exception.message(error) =~ "duplicate evidence row"
    end

    test "browser evidence redaction checks reject sensitive evidence text" do
      for forbidden <- [
            "cookie=session_id%3Dabcdef1234567890",
            "authorization_code=SplxlOBeZQQYbYS6WxSbIA",
            "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890",
            "client_secret=plaintext-secret-value",
            "-----BEGIN PRIVATE KEY-----",
            "code_verifier=verifier-material-value",
            "device_code=ABCD-EFGH-IJKL",
            "user_code=WDJB-MJHT",
            "copy-once secret shown in screenshot",
            "https://accounts.lockspire.com/admin"
          ] do
        error =
          assert_raise ArgumentError, fn -> BrowserEvidence.assert_redaction_safe!(forbidden) end

        assert Exception.message(error) =~ "sensitive evidence"
      end

      safe_note =
        "local maintainer note with scrubbed route, numeric widths, no screenshots retained"

      assert BrowserEvidence.assert_redaction_safe!(safe_note) == safe_note
    end

    test "closeout proof artifact has required non-gap representative evidence rows" do
      artifact = File.read!(@phase_125_proof_path)
      BrowserEvidence.assert_redaction_safe!(artifact)

      rows = BrowserEvidence.parse!(artifact)

      required_rows = [
        {"/admin", "Orient", "320px", "light", "default"},
        {"/admin/clients", "Configure", "390px", "dark", "reduced-motion"},
        {"/admin/tokens", "Support", "768px", "system", "default"},
        {"/admin/logouts", "Operate", "1024px", "dark", "reduced-motion"},
        {"AdminLab.StressSurface", "Internal lab", "1440px", "system", "default"}
      ]

      for {route, journey, viewport, theme, motion} <- required_rows do
        row =
          Enum.find(rows, fn row ->
            row["Route / Surface"] == route and row["Journey"] == journey and
              row["Viewport"] == viewport and row["Theme"] == theme and
              row["Motion"] == motion
          end)

        assert row, "missing required proof row for #{route} #{viewport} #{theme} #{motion}"
        assert row["Result"] == "pass"
        assert row["scrollWidth"] <= row["clientWidth"]
        assert row["Gap note"] == "none"
        assert row["Sensitive evidence check"] == "passed denylist"
      end

      empty_state_row =
        Enum.find(rows, fn row ->
          empty_or_no_match_evidence? =
            [row["State"], row["Scrubbed notes"]]
            |> Enum.join(" ")
            |> String.match?(~r/(?:\bempty\b|\bno[- ]match\b)/i)

          empty_or_no_match_evidence? and row["Result"] == "pass" and
            row["Gap note"] == "none" and
            row["Sensitive evidence check"] == "passed denylist" and
            is_integer(row["scrollWidth"]) and is_integer(row["clientWidth"])
        end)

      assert empty_state_row,
             "missing required empty/no-match proof row with pass result, numeric widths, no gap, and passing denylist check"

      assert Enum.map(rows, & &1["Viewport"]) |> Enum.uniq() |> Enum.sort() == [
               "1024px",
               "1440px",
               "320px",
               "390px",
               "768px"
             ]

      assert Enum.uniq(Enum.map(rows, & &1["Theme"])) |> Enum.sort() == [
               "dark",
               "light",
               "system"
             ]

      assert Enum.uniq(Enum.map(rows, & &1["Motion"])) |> Enum.sort() == [
               "default",
               "reduced-motion"
             ]
    end

    test "closeout proof artifact records source truth, commands, and adversarial signoff" do
      artifact = File.read!(@phase_125_proof_path)

      for phrase <- [
            "Maintainer-only final proof artifact",
            "AdminRouter source truth",
            "`/admin/clients/:client_id/edit?workflow=logout-propagation`",
            "Deterministic commands are the blocking proof path",
            "Representative browser/manual evidence rows",
            "Sensitive evidence denylist",
            "Explicit gaps",
            "Final adversarial review",
            "aesthetic overfit",
            "accessibility",
            "generic admin-template drift",
            "backend implementation leakage",
            "host integration weight",
            "screenshot-only quality",
            "theme, motion, and focus regressions",
            "redaction failures",
            "unsupported action creep",
            "stale route evidence",
            "package/runtime creep",
            "support-surface expansion"
          ] do
        assert artifact =~ phrase
      end

      for forbidden <- [
            "package.json",
            "playwright.config",
            "node_modules",
            "CI browser gate",
            "public browser proof route",
            "WCAG certification"
          ] do
        refute artifact =~ forbidden
      end
    end
  end

  test "public docs and package boundaries do not promote lab or browser proof surfaces" do
    supported_surface =
      File.read!(Path.expand("../../../../../docs/supported-surface.md", @contract_dir))

    mix = File.read!(Path.expand("../../../../../mix.exs", @contract_dir))

    for forbidden <- ["component-lab", "design-system-lab", "Playwright proof", "axe proof"] do
      refute supported_surface =~ forbidden
    end

    for forbidden_path <- [
          "proof/browser",
          "scripts/browser-proof",
          "package.json",
          "playwright.config"
        ] do
      refute mix =~ forbidden_path
    end
  end

  test "phase 119 copy redaction and browser-boundary fences stay scoped" do
    sources = phase_119_source_blob()
    mix = File.read!(Path.expand("../../../../../mix.exs", @contract_dir))

    for phrase <- [
          "DCR onboarding",
          "DCR policy",
          "post-logout redirect URIs",
          "logout propagation URIs",
          "Plaintext is shown once. Lockspire stores only the hash",
          "redacted_handle",
          "plaintext",
          "copy_once_secret_panel",
          "family-wide action",
          "remembered grant will no longer"
        ] do
      assert sources =~ phrase
    end

    refute Regex.match?(
             ~r/(?:^|>|\n)\s*(Submit|Continue|Go|Manage)\s*(?:<|\n|$)/,
             sources
           )

    for forbidden <- [
          "dangerous",
          "critical breach",
          "panic",
          "threat center",
          "attack map",
          "extreme caution",
          "Playwright",
          "playwright",
          "axe-core",
          "@axe-core",
          "screenshot",
          "browser proof",
          "visual regression"
        ] do
      refute sources =~ forbidden
    end

    for forbidden <- ["playwright", "axe-core", "@axe-core", "proof/browser", "package.json"] do
      refute mix =~ forbidden
    end
  end

  describe "Global admin proof guardrails" do
    test "route scorecards remain source-derived with stable evidence and support promises" do
      assert_phase_125_route_scorecard_contract!()
    end

    test "source docs package and router boundaries reject public proof surface creep" do
      phase_125_contract_sources()
      |> assert_phase_125_public_surface_boundary!()
    end

    test "source and rendered contracts reject generic CTAs unsupported actions and redaction drift" do
      phase_125_contract_sources()
      |> assert_phase_125_copy_and_redaction_boundary!()
    end

    test "CSS source contracts preserve long value focus theme motion and responsive no-overflow claims" do
      phase_125_contract_sources()
      |> assert_phase_125_css_and_responsive_contract!()
    end
  end

  test "phase 110 demo seeds cover required proof states with artificial data" do
    seeds = File.read!(@adoption_demo_seeds_path)

    for phrase <- [
          "healthy",
          "warning",
          "incident",
          "disabled",
          "self-registered",
          "retryable",
          "revoked",
          "expired",
          "long-value",
          "copy-once"
        ] do
      assert seeds =~ phrase
    end

    for phrase <- [
          "billingo-dashboard-public",
          "billingo-display-device",
          "billingo-reports-backend",
          "northstar-payables-portal",
          "legacy-csv-reporter"
        ] do
      assert seeds =~ phrase
    end

    for phrase <- [
          "status: :denied",
          "status: :consumed",
          "status: :discarded",
          "interaction-expired",
          "demo-iat-expired"
        ] do
      assert seeds =~ phrase
    end
  end

  test "phase 110 demo seeds keep secret and token proof values redaction-safe" do
    seeds = File.read!(@adoption_demo_seeds_path)

    for helper <- [
          "Lockspire.Security.Policy.hash_client_secret",
          "Lockspire.Security.Policy.hash_token"
        ] do
      assert seeds =~ helper
    end

    for forbidden <- [
          "real-client-secret",
          "production-secret",
          "prod-access-token",
          "prod-refresh-token",
          "customer.example.com",
          "tenant.example.com"
        ] do
      refute seeds =~ forbidden
    end

    assert seeds =~ "copy-once"
    assert seeds =~ "not stored or shown again as plaintext"
  end

  test "phase 110 operator docs preserve final journey model and host boundary" do
    guide = File.read!(@operator_admin_doc_path)

    for phrase <- [
          "Orient",
          "Configure",
          "Support",
          "Operate",
          "docs/supported-surface.md",
          "DCR onboarding",
          "DCR policy",
          "post-logout redirect URIs",
          "logout propagation URIs",
          "staff sessions",
          "MFA",
          "role checks",
          "tenant policy",
          "layouts",
          "branding",
          "product-specific authorization"
        ] do
      assert guide =~ phrase
    end
  end

  test "phase 110 screenshot and browser evidence inventories cover route proof fields" do
    router = File.read!(@admin_router_path)
    screenshots = File.read!(phase_110_path("110-SCREENSHOTS.md"))
    browser = File.read!(phase_110_path("110-BROWSER-EVIDENCE.md"))

    expected_routes =
      router
      |> mounted_admin_routes()
      |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
      |> Enum.sort()

    for route <- expected_routes do
      assert screenshots =~ route
    end

    for heading <- [
          "Coverage Matrix",
          "Journey",
          "Route",
          "Desktop",
          "Mobile",
          "Demo state",
          "Browser note"
        ] do
      assert screenshots =~ heading
    end

    for phrase <- [
          "Orient",
          "Configure",
          "Support",
          "Operate",
          "tmp/admin-ui-polish/",
          "390px no-page-overflow returned false"
        ] do
      assert screenshots =~ phrase
    end

    for phrase <- [
          "overview",
          "read-only",
          "390px",
          "no-page-overflow",
          "copy-once",
          "confirmation"
        ] do
      assert browser =~ phrase
    end
  end

  test "phase 110 screenshot inventory rows contain explicit desktop and mobile proof cells" do
    screenshots = File.read!(phase_110_path("110-SCREENSHOTS.md"))

    rows =
      screenshots
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "| "))
      |> Enum.reject(&String.contains?(&1, "---"))
      |> Enum.drop(1)

    assert length(rows) >= 29

    for row <- rows do
      cells =
        row
        |> String.trim("|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      assert [journey, route, desktop, mobile, demo_state, browser_note] = cells
      assert journey in ["Orient", "Configure", "Support", "Operate"]
      assert route |> String.trim("`") |> String.starts_with?("/admin")
      assert screenshot_cell_present?(desktop)
      assert screenshot_cell_present?(mobile)
      assert demo_state != ""
      assert browser_note != ""
    end
  end

  test "phase 110 proof artifacts fence runtime dependencies, generic labels, and redaction notes" do
    artifacts = phase_110_artifact_blob()

    for path <- Path.wildcard(@admin_live_glob) ++ [@admin_css_path, @admin_components_path] do
      refute File.read!(path) =~ "tmp/admin-ui-polish"
    end

    refute Regex.match?(
             ~r/(?:^|>|\n|\|)\s*(Submit|OK|Cancel|Apply|Open)\s*(?:<|\n|\||$)/,
             artifacts
           )

    for phrase <- [
          "Do not persist plaintext IATs",
          "RATs",
          "client secrets",
          "user codes",
          "verifier material",
          "access tokens",
          "refresh tokens",
          "token hashes",
          "Keep screenshot files under `tmp/admin-ui-polish/` as milestone evidence only"
        ] do
      assert artifacts =~ phrase
    end
  end

  test "phase 116 lab contract keeps maintainer proof out of supported routes" do
    contract = File.read!(phase_116_path("116-LAB-CONTRACT.md"))
    router = File.read!(@admin_router_path)

    supported_surface =
      File.read!(Path.expand("../../../../../docs/supported-surface.md", @contract_dir))

    for phrase <- [
          "maintainer/demo/test-only",
          "not a supported admin route",
          "public API",
          "not mount through Lockspire.Web.AdminRouter",
          "PhoenixStorybook",
          "rejected/default-deferred",
          "React/JS Storybook",
          "host-editable component registry",
          "internal_lab",
          "test_only",
          "demo_only",
          "never `admin_supported`",
          "client secrets",
          "registration access token plaintext",
          "initial access token plaintext after creation",
          "refresh/access token plaintext",
          "authorization codes",
          "cookies",
          "private keys",
          "verifier material",
          "user codes",
          "unredacted sensitive values",
          "ExUnit/source contracts"
        ] do
      assert contract =~ phrase
    end

    refute router =~ "component_lab"
    refute router =~ "design_system_lab"

    supported_surface = String.downcase(supported_surface)

    for forbidden <- ["component lab", "design system lab", "design-system lab"] do
      refute supported_surface =~ forbidden
    end
  end
end
