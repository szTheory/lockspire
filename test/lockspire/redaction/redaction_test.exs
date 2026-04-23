defmodule Lockspire.RedactionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Redaction

  test "for_telemetry drops bearer artifacts, secrets, and raw payloads while keeping stable handles" do
    metadata = %{
      access_token: "access-token-value",
      refresh_token: "refresh-token-value",
      authorization_code: "authorization-code-value",
      code_verifier: "plain-code-verifier",
      client_secret: "super-secret",
      client_secret_hash: "argon2id$hash",
      token_hash: "sha256$hash",
      family_id: "family-secret-hash",
      params: %{"token" => "access-token-value", "scope" => "openid"},
      payload: %{request: %{headers: %{"authorization" => "Bearer raw"}}},
      client_id: "client_123",
      reason_code: :refresh_token_reuse_detected
    }

    redacted = Redaction.for_telemetry(metadata)

    assert redacted.client_id == "client_123"
    assert redacted.reason_code == :refresh_token_reuse_detected
    assert redacted.family_handle == Redaction.handle(:family, "family-secret-hash")

    refute Map.has_key?(redacted, :access_token)
    refute Map.has_key?(redacted, :refresh_token)
    refute Map.has_key?(redacted, :authorization_code)
    refute Map.has_key?(redacted, :code_verifier)
    refute Map.has_key?(redacted, :client_secret)
    refute Map.has_key?(redacted, :client_secret_hash)
    refute Map.has_key?(redacted, :token_hash)
    refute Map.has_key?(redacted, :family_id)
    refute Map.has_key?(redacted, :params)
    refute Map.has_key?(redacted, :payload)
  end

  test "handles are stable for the same value and differ for different values" do
    assert Redaction.handle(:token, "same-value") == Redaction.handle(:token, "same-value")
    refute Redaction.handle(:token, "same-value") == Redaction.handle(:token, "other-value")
  end
end
