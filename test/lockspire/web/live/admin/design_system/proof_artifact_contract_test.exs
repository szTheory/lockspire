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
    assert [admin, lab] = BrowserEvidence.parse!(valid_evidence())

    assert admin["Route / Surface"] == "/admin"
    assert admin["Journey"] == "Orient"
    assert admin["scrollWidth"] == 390
    assert admin["clientWidth"] == 390
    assert admin["Result"] == "pass"

    assert lab["Route / Surface"] == "AdminLab.StressSurface"
    assert lab["Journey"] == "Internal lab"
    assert BrowserEvidence.allowed_results() == ["pass", "fail", "gap", "blocked"]
  end

  test "browser evidence rejects malformed and sensitive observations" do
    invalid_result = String.replace(valid_evidence(), "| pass |", "| maybe |", global: false)

    assert_raise ArgumentError, ~r/invalid Result/, fn ->
      BrowserEvidence.parse!(invalid_result)
    end

    malformed_route = String.replace(valid_evidence(), "`/admin`", "`admin`", global: false)

    assert_raise ArgumentError, ~r/malformed Route \/ Surface/, fn ->
      BrowserEvidence.parse!(malformed_route)
    end

    duplicate = valid_evidence() <> "\nnot a table\n" <> valid_evidence()

    assert_raise ArgumentError, ~r/duplicate evidence row/, fn ->
      BrowserEvidence.parse!(duplicate)
    end

    for sensitive <- [
          "client_secret=plaintext-secret-value",
          "device_code=ABCD-EFGH-IJKL",
          "https://accounts.lockspire.com/admin"
        ] do
      assert_raise ArgumentError, ~r/sensitive evidence/, fn ->
        BrowserEvidence.assert_redaction_safe!(sensitive)
      end
    end
  end

  defp valid_evidence do
    """
    | Route / Surface | Journey | Viewport | Theme | Motion | Focus path | State | scrollWidth | clientWidth | Result | Scrubbed notes | Sensitive evidence check | Gap note | Deterministic command outcome |
    |---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
    | `/admin` | Orient | 390px | light | default | overview nav | healthy summary | 390 | 390 | pass | synthetic local observation | passed denylist | none | contract test pass |
    | `AdminLab.StressSurface` | Internal lab | 1440px | system | reduced-motion | fixture tab order | long synthetic values | 1440 | 1440 | pass | internal render only | passed denylist | none | stress contract pass |
    """
  end
end
