defmodule Lockspire.TestSupport.ClientSecretJwtSupportTruth do
  @moduledoc false

  def assert_canonical_support_contract!(content) do
    assert_includes_all(content, [
      "Confidential-client `client_secret_jwt` authentication on the same Lockspire-owned direct-client endpoints that reuse the shared verifier",
      "`HS256` only",
      "issuer-string `aud`",
      "required `jti`",
      "replay protection",
      "no support on `POST /par`",
      "does not claim broader JWT client-auth support",
      "FAPI-sensitive deployments should treat `client_secret_jwt` as outside the shipped FAPI posture."
    ])

    refute_includes_any(content, ["- `client_secret_jwt`\n"])
  end

  def assert_host_guide!(content) do
    assert_includes_all(content, [
      "`token_endpoint_auth_method=client_secret_jwt`",
      "`token_endpoint_auth_signing_alg=HS256`",
      "`aud` equal to the issuer identifier string",
      "`POST /par` is intentionally excluded from this slice.",
      "FAPI or mTLS equivalence",
      "The host app still owns"
    ])
  end

  def assert_release_guide_defers!(content) do
    assert_includes_all(content, [
      "docs/supported-surface.md",
      "does not define a second public support contract",
      "`client_secret_jwt`",
      "`private_key_jwt`"
    ])
  end

  defp assert_includes_all(content, snippets) do
    Enum.each(snippets, fn snippet ->
      unless String.contains?(content, snippet) do
        raise ExUnit.AssertionError, "expected content to include #{inspect(snippet)}"
      end
    end)
  end

  defp refute_includes_any(content, snippets) do
    Enum.each(snippets, fn snippet ->
      if String.contains?(content, snippet) do
        raise ExUnit.AssertionError, "expected content to exclude #{inspect(snippet)}"
      end
    end)
  end
end
