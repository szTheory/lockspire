defmodule Lockspire.Web.Live.Admin.DesignSystem.ProofArtifactContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.{BrowserEvidence, HtmlAssertions, RedactionAssertions}

  test "rendered operator context is useful without exposing credential material" do
    safe_html = """
    <section>
      <span class="lockspire-admin-redacted-value">client clt_12…a9</span>
      <span class="lockspire-admin-status-active">Active</span>
    </section>
    """

    assert RedactionAssertions.assert_rendered_safe!(safe_html) == safe_html
    assert RedactionAssertions.assert_safe_operator_context!(safe_html) == safe_html

    for raw_value <- [
          "client_secret=plaintext-secret-value",
          "access_token=opaque-access-token-value",
          "refresh_token=opaque-refresh-token-value",
          "authorization_code=SplxlOBeZQQYbYS6WxSbIA",
          "cookie=session_id%3Dabcdef1234567890",
          "-----BEGIN PRIVATE KEY-----",
          "SELECT token_hash FROM oauth_tokens",
          ~s(error_body="upstream stack trace")
        ] do
      assert_raise ExUnit.AssertionError, fn ->
        RedactionAssertions.assert_rendered_safe!("<p>#{raw_value}</p>")
      end
    end
  end

  test "current admin source keeps raw storage fields behind redacted presentation" do
    assert RedactionAssertions.assert_source_boundaries!() == :ok
  end

  test "disabled actions and token-like text retain semantic rendering guards" do
    disabled_anchor =
      ~s(<a href="/admin/clients" class="lockspire-admin-btn lockspire-admin-btn-disabled">Disabled</a>)

    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_disabled_links_have_semantics(disabled_anchor)
    end

    semantic_link =
      ~s(<span role="link" aria-disabled="true" class="lockspire-admin-btn">Disabled</span>)

    assert HtmlAssertions.assert_disabled_links_have_semantics(semantic_link) == semantic_link

    jwt =
      "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2NvdW50LTEyMyJ9.signaturevalue1234567890"

    assert_raise ExUnit.AssertionError, fn ->
      HtmlAssertions.assert_no_token_like_text("<p>#{jwt}</p>")
    end
  end

  test "browser evidence accepts the maintained capability shape" do
    assert [admin, lab, boundary_799, boundary_800, boundary_801] =
             BrowserEvidence.parse!(valid_evidence())

    assert admin["Route / Surface"] == "/admin"
    assert admin["Journey"] == "Orient"
    assert admin["scrollWidth"] == 390
    assert admin["clientWidth"] == 390
    assert admin["Result"] == "pass"

    assert lab["Route / Surface"] == "AdminLab.StressSurface"
    assert lab["Journey"] == "Internal lab"

    assert Enum.map([boundary_799, boundary_800, boundary_801], & &1["Viewport"]) ==
             ["799px", "800px", "801px"]

    assert BrowserEvidence.allowed_results() == ["pass", "fail", "gap", "blocked"]
  end

  test "browser evidence rejects malformed and sensitive observations" do
    invalid_result = String.replace(valid_evidence(), "| pass |", "| maybe |", global: false)

    assert_raise ArgumentError, ~r/invalid Result/, fn ->
      BrowserEvidence.parse!(invalid_result)
    end

    passing_overflow =
      String.replace(valid_evidence(), "| 390 | 390 | pass |", "| 391 | 390 | pass |",
        global: false
      )

    assert_raise ArgumentError, ~r/cannot report document-level horizontal overflow/, fn ->
      BrowserEvidence.parse!(passing_overflow)
    end

    malformed_route = String.replace(valid_evidence(), "`/admin`", "`admin`", global: false)

    assert_raise ArgumentError, ~r/malformed Route \/ Surface/, fn ->
      BrowserEvidence.parse!(malformed_route)
    end

    outside_admin_namespace =
      String.replace(valid_evidence(), "`/admin`", "`/administrator`", global: false)

    assert_raise ArgumentError, ~r/malformed Route \/ Surface/, fn ->
      BrowserEvidence.parse!(outside_admin_namespace)
    end

    duplicate = valid_evidence() <> "\nnot a table\n" <> valid_evidence()

    assert_raise ArgumentError, ~r/duplicate evidence row/, fn ->
      BrowserEvidence.parse!(duplicate)
    end

    for sensitive <- [
          "client_secret=plaintext-secret-value",
          "device_code=ABCD-EFGH-IJKL",
          "Authorization: Bearer abcdefghijklmnop",
          "proxy-authorization: basic c2VydmljZTpwYXNzd29yZA==",
          "https://accounts.lockspire.com/admin",
          "https://api.acme.co/x",
          "https://auth.acme.ai/cb",
          "https://auth.acme-example.com/cb"
        ] do
      assert_raise ArgumentError, ~r/sensitive evidence/, fn ->
        BrowserEvidence.assert_redaction_safe!(sensitive)
      end
    end

    # RFC 2606 / RFC 6761 names are the synthetic demo's own hosts.
    for reserved <- [
          "https://partners.northstar.example.com/backchannel-logout",
          "http://lockspire-ui-review.localhost/lockspire",
          "https://billingo.test/callback"
        ] do
      assert BrowserEvidence.assert_redaction_safe!(reserved) == reserved
    end

    distinct_states =
      valid_evidence() <>
        "| `/admin` | Orient | 390px | light | default | overview nav | validation error state | 390 | 390 | pass | synthetic local observation | passed denylist | none | contract test pass |\n"

    assert length(BrowserEvidence.parse!(distinct_states)) == 6
  end

  test "browser evidence accepts zoom-equivalent and nav-boundary widths" do
    header =
      "| Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |\n|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|\n"

    row = fn width ->
      "| `/admin/overview` | Orient | #{width}px | light | default | page load | width #{width} | #{width} | #{width} | pass | synthetic local observation | passed denylist | none | contract test pass |\n"
    end

    widths = [640, 720, 1119, 1120, 1261, 1280]
    rows = BrowserEvidence.parse!(header <> Enum.map_join(widths, &row.(&1)))

    assert Enum.map(rows, & &1["Viewport"]) == Enum.map(widths, &"#{&1}px")

    assert_raise ArgumentError, ~r/invalid Viewport/, fn ->
      BrowserEvidence.parse!(header <> row.(641))
    end
  end

  defp valid_evidence do
    """
    | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
    |---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
    | `/admin` | Orient | 390px | light | default | overview nav | healthy summary | 390 | 390 | pass | synthetic local observation | passed denylist | none | contract test pass |
    | `AdminLab.StressSurface` | Internal lab | 1440px | system | reduced-motion | fixture tab order | long synthetic values | 1440 | 1440 | pass | internal render only | passed denylist | none | stress contract pass |
    | `/admin/clients` | Configure | 799px | light | default | shell nav | synthetic client list | 799 | 799 | pass | boundary viewport fixture | passed denylist | none | parser boundary contract pass |
    | `/admin/clients` | Configure | 800px | light | default | shell nav | synthetic client list | 800 | 800 | pass | boundary viewport fixture | passed denylist | none | parser boundary contract pass |
    | `/admin/clients` | Configure | 801px | light | default | shell nav | synthetic client list | 801 | 801 | pass | boundary viewport fixture | passed denylist | none | parser boundary contract pass |
    """
  end
end
