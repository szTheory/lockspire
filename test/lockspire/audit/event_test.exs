defmodule Lockspire.Audit.EventTest do
  use ExUnit.Case, async: true

  alias Lockspire.Audit.Event

  test "normalizes private_key_jwt verifier events without retaining raw assertion or jwks material" do
    event =
      Event.normalize(%{
        action: :client_auth_failed,
        outcome: :failed,
        reason_code: :client_assertion_signature_invalid,
        actor: %{type: :client, id: "client-123"},
        resource: %{type: :client_authentication, id: "client-123"},
        metadata: %{
          client_id: "client-123",
          client_assertion: "raw.jwt.value",
          client_secret_jwt_verifier_encrypted: "sealed-value",
          jwt_header: %{"alg" => "RS256"},
          jwt_claims: %{"sub" => "client-123"},
          jwks_body: %{"keys" => [%{"kid" => "kid-1"}]},
          jwks_source: :jwks_uri
        }
      })

    assert event.reason_code == "client_assertion_signature_invalid"
    assert event.metadata["client_id"] == "client-123"
    assert event.metadata["jwks_source"] == :jwks_uri
    refute Map.has_key?(event.metadata, "client_assertion")
    refute Map.has_key?(event.metadata, "client_secret_jwt_verifier_encrypted")
    refute Map.has_key?(event.metadata, "jwt_header")
    refute Map.has_key?(event.metadata, "jwt_claims")
    refute Map.has_key?(event.metadata, "jwks_body")
  end
end
