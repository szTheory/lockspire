defmodule Lockspire.Protocol.LogoutTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.LogoutToken

  @issued_at ~U[2026-04-29 18:00:00Z]

  test "sign/1 emits a signed back-channel logout token with required claims" do
    keys = JarTestHelpers.generate_keys()

    assert {:ok, jwt, logout_token_jti} =
             LogoutToken.sign(%{
               issuer: "https://example.test/lockspire",
               logout_event: logout_event(),
               delivery: logout_delivery(session_required: true),
               issued_at: @issued_at,
               signing_key: signing_key(keys)
             })

    claims = decode_claims(jwt, keys)

    assert claims["iss"] == "https://example.test/lockspire"
    assert claims["aud"] == "client-123"
    assert claims["sub"] == "subject-123"
    assert claims["sid"] == "sid-123"
    assert claims["iat"] == DateTime.to_unix(@issued_at)
    assert claims["jti"] == logout_token_jti
    assert claims["events"] == %{"http://schemas.openid.net/event/backchannel-logout" => %{}}
    refute Map.has_key?(claims, "nonce")
  end

  test "sign/1 omits sid when the persisted delivery snapshot does not require session binding" do
    keys = JarTestHelpers.generate_keys()

    assert {:ok, jwt, _logout_token_jti} =
             LogoutToken.sign(%{
               issuer: "https://example.test/lockspire",
               logout_event: logout_event(),
               delivery: logout_delivery(session_required: false),
               issued_at: @issued_at,
               signing_key: signing_key(keys)
             })

    claims = decode_claims(jwt, keys)

    refute Map.has_key?(claims, "sid")
  end

  test "sign/1 rejects missing or malformed signing key material" do
    assert {:error, :invalid_signing_key} =
             LogoutToken.sign(%{
               issuer: "https://example.test/lockspire",
               logout_event: logout_event(),
               delivery: logout_delivery(),
               issued_at: @issued_at,
               signing_key: %{kid: "kid-123", alg: "RS256", private_jwk_encrypted: "not-json"}
             })
  end

  defp logout_event do
    %LogoutEvent{
      event_id: "evt-123",
      sid: "sid-123",
      subject: "subject-123"
    }
  end

  defp logout_delivery(overrides \\ []) do
    base = %LogoutDelivery{
      delivery_id: "delivery-123",
      client_id: "client-123",
      channel: :backchannel,
      target_uri: "https://snapshot.example.com/backchannel-logout",
      session_required: true
    }

    struct!(base, Enum.into(overrides, %{}))
  end

  defp signing_key(keys) do
    %{
      kid: "kid-123",
      alg: "RS256",
      private_jwk_encrypted: Jason.encode!(keys.priv_jwk_map)
    }
  end

  defp decode_claims(jwt, keys) do
    public_jwk = JOSE.JWK.to_public(keys.private_jwk)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, ["RS256"], jwt)

    claims
  end
end
