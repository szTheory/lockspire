defmodule Lockspire.Protocol.RequestObjectTest do
  use ExUnit.Case, async: false
  alias Lockspire.Protocol.RequestObject
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  test "consume/3 handles a nested JWE request object end-to-end when a valid :enc key is present" do
    now = DateTime.utc_now()
    enc_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    sig_jwk = JOSE.JWK.generate_key({:ec, "P-256"})

    Repository.publish_key(%Lockspire.Domain.SigningKey{
      kid: "enc-test",
      kty: :RSA,
      alg: "RS256",
      use: :enc,
      public_jwk: %{"kty" => "RSA", "kid" => "enc-test", "alg" => "RS256", "use" => "enc"},
      private_jwk_encrypted: :erlang.term_to_binary(JOSE.JWK.to_map(enc_jwk) |> elem(1)),
      status: :active,
      published_at: now,
      activated_at: now
    })

    client = %Client{
      client_id: "client-123",
      jwks: JOSE.JWK.to_public_map(sig_jwk) |> elem(1)
    }

    claims = %{
      "iss" => "client-123",
      "aud" => "https://example.test/lockspire",
      "exp" => DateTime.to_unix(now) + 300,
      "response_type" => "code",
      "client_id" => "client-123"
    }

    jws = JOSE.JWT.sign(sig_jwk, %{"alg" => "ES256"}, claims)
    {_, jws_compact} = JOSE.JWS.compact(jws)

    jwe = JOSE.JWE.block_encrypt(enc_jwk, jws_compact, %{"alg" => "RSA-OAEP", "enc" => "A256GCM"})
    {_, jwe_compact} = JOSE.JWE.compact(jwe)

    assert {:ok, projected} = RequestObject.consume(%{"request" => jwe_compact, "client_id" => "client-123"}, client)
    assert projected["response_type"] == "code"
    assert projected["client_id"] == "client-123"
  end
end
