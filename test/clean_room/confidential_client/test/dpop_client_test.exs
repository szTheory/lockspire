defmodule CleanRoomClient.DPoPClientTest do
  use ExUnit.Case, async: true

  alias CleanRoomClient.{DPoP, OIDCVerifier, Transactions}

  test "rejects discovery issuer drift and validates nonce-bound claims" do
    transaction =
      Transactions.start(%{
        profile: :bearer,
        issuer: "https://issuer.example",
        client_id: "client"
      })

    metadata = %{
      "issuer" => "https://issuer.example",
      "jwks_uri" => "https://issuer.example/jwks",
      "id_token_signing_alg_values_supported" => ["RS256"]
    }

    assert {:ok, verified_metadata} = OIDCVerifier.validate_metadata(metadata, transaction.issuer)

    assert {:ok, _} =
             OIDCVerifier.validate_claims(
               %{
                 "iss" => transaction.issuer,
                 "aud" => "client",
                 "exp" => System.system_time(:second),
                 "nonce" => transaction.nonce,
                 "sub" => "subject"
               },
               transaction,
               verified_metadata
             )

    assert {:error, :invalid_discovery} =
             OIDCVerifier.validate_metadata(
               %{"issuer" => "https://other.example"},
               transaction.issuer
             )
  end

  test "creates endpoint-specific fresh DPoP proofs" do
    key = DPoP.new_key()
    token_proof = DPoP.proof(key.private_jwk, :post, "https://issuer.example/token")

    userinfo_proof =
      DPoP.proof(key.private_jwk, :get, "https://issuer.example/userinfo", %{
        ath: DPoP.access_token_hash("token")
      })

    assert token_proof != userinfo_proof
    refute String.contains?(token_proof, "token")
  end
end
