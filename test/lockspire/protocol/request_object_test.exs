defmodule Lockspire.Protocol.RequestObjectTest do
  use ExUnit.Case, async: false
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.RequestObject
  alias Lockspire.Protocol.RequestObject.Claims
  alias Lockspire.Protocol.RequestObject.Retrieval
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

    assert {:ok, projected} =
             RequestObject.consume(
               %{"request" => jwe_compact, "client_id" => "client-123"},
               client
             )

    assert projected["response_type"] == "code"
    assert projected["client_id"] == "client-123"
  end

  test "consume/3 retains the public browser-safe authorization error when request is missing" do
    assert {:browser_error, %Error{} = issue} =
             RequestObject.consume(%{"client_id" => "client-123"}, %Client{
               client_id: "client-123"
             })

    assert issue.error == "invalid_request"
    assert issue.error_description == "request parameter is required"
    assert issue.reason_code == :missing_request
    assert issue.state == nil
    assert issue.redirect_uri == nil
  end

  test "retrieval preserves sealed-envelope precedence before considering a request value" do
    assert {:error, :request_object_and_request_uri_conflict} =
             Retrieval.fetch(%{"request" => "signed", "request_uri" => "urn:lockspire:par"})

    assert {:error, :request_object_conflict} =
             Retrieval.fetch(%{"request" => "signed", "scope" => "openid"})

    assert {:error, :missing_request} = Retrieval.fetch(%{"client_id" => "client-123"})
  end

  test "claims projection keeps only signed authorization parameters and authoritative client identity" do
    client = %Client{client_id: "client-123"}

    assert {:ok, projected} =
             Claims.project(
               %{
                 "client_id" => "attacker-client",
                 "response_type" => "code",
                 "scope" => "openid",
                 "unrecognized" => "ignored",
                 "nonce" => nil
               },
               client
             )

    assert projected == %{
             "client_id" => "client-123",
             "response_type" => "code",
             "scope" => "openid"
           }
  end
end
