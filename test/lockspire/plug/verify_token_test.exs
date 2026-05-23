defmodule Lockspire.Plug.VerifyTokenTest do
  use ExUnit.Case, async: false
  use Plug.Test

  alias Lockspire.Plug.VerifyToken
  alias Lockspire.AccessToken
  alias Lockspire.KeyCache
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Domain.SigningKey

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})
    
    {:ok, pid: Process.whereis(KeyCache)}
  end

  defp build_conn do
    conn(:get, "/")
  end

  defp generate_key_and_token(claims \\ %{}) do
    jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    kid = "test-kid-#{System.unique_integer()}"
    public_jwk = jose_jwk |> JOSE.JWK.to_public() |> JOSE.JWK.to_map() |> elem(1)

    key = %SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: public_jwk,
      status: :active,
      inserted_at: DateTime.utc_now()
    }

    {:ok, _} = Repository.publish_key(key)
    
    send(KeyCache, :refresh)
    :sys.get_state(KeyCache)

    default_claims = %{
      "client_id" => "test_client",
      "exp" => System.os_time(:second) + 3600,
      "nbf" => System.os_time(:second) - 60
    }

    merged_claims = Map.merge(default_claims, claims)

    jwk_map = jose_jwk |> JOSE.JWK.to_map() |> elem(1)
    
    {_, signed_token} = 
      JOSE.JWT.sign(jose_jwk, %{"alg" => "RS256", "kid" => kid}, merged_claims)
      |> JOSE.JWS.compact()

    {signed_token, merged_claims}
  end

  describe "VerifyToken plug" do
    test "assigns access_token with missing_token error when no header" do
      conn = build_conn() |> VerifyToken.call([])
      
      assert %AccessToken{error: :missing_token} = conn.assigns[:access_token]
      refute conn.halted
    end

    test "assigns access_token with missing_token error when not a Bearer token" do
      conn = build_conn() 
             |> put_req_header("authorization", "Basic abc")
             |> VerifyToken.call([])
             
      assert %AccessToken{error: :missing_token} = conn.assigns[:access_token]
      refute conn.halted
    end

    test "assigns invalid_token when token is malformed" do
      conn = build_conn()
             |> put_req_header("authorization", "Bearer not.a.jwt")
             |> VerifyToken.call([])
             
      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when kid is not found" do
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      {_, token} = JOSE.JWT.sign(jose_jwk, %{"alg" => "RS256", "kid" => "unknown-kid"}, %{"client_id" => "client"}) |> JOSE.JWS.compact()
      
      conn = build_conn()
             |> put_req_header("authorization", "Bearer #{token}")
             |> VerifyToken.call([])
             
      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when signature is invalid" do
      {token, _claims} = generate_key_and_token()
      
      tampered_token = token <> "tamper"
      
      conn = build_conn()
             |> put_req_header("authorization", "Bearer #{tampered_token}")
             |> VerifyToken.call([])
             
      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when exp is in the past" do
      {token, _claims} = generate_key_and_token(%{"exp" => System.os_time(:second) - 3600})
      
      conn = build_conn()
             |> put_req_header("authorization", "Bearer #{token}")
             |> VerifyToken.call([])
             
      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when nbf is in the future" do
      {token, _claims} = generate_key_and_token(%{"nbf" => System.os_time(:second) + 3600})
      
      conn = build_conn()
             |> put_req_header("authorization", "Bearer #{token}")
             |> VerifyToken.call([])
             
      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns valid AccessToken when everything is correct" do
      {token, claims} = generate_key_and_token()

      conn = build_conn()
             |> put_req_header("authorization", "Bearer #{token}")
             |> VerifyToken.call([])
             
      assert %AccessToken{
        token: ^token,
        claims: ^claims,
        client_id: "test_client",
        authorization_scheme: "Bearer",
        binding_type: nil,
        binding_requirements: nil,
        error: nil
      } = conn.assigns[:access_token]

      refute conn.halted
    end

    test "accepts DPoP authorization scheme and normalizes DPoP cnf requirements" do
      claims = %{"cnf" => %{"jkt" => "proof-thumbprint"}}
      {token, merged_claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "DPoP #{token}")
        |> VerifyToken.call([])

      assert %AccessToken{
               token: ^token,
               claims: ^merged_claims,
               client_id: "test_client",
               authorization_scheme: "DPoP",
               binding_type: "dpop",
               binding_requirements: %{dpop_jkt: "proof-thumbprint"},
               error: nil
             } = conn.assigns[:access_token]
    end

    test "preserves dual sender-binding requirements without ambiguity" do
      claims = %{"cnf" => %{"jkt" => "proof-thumbprint", "x5t#S256" => "cert-thumbprint"}}
      {token, merged_claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call([])

      assert %AccessToken{
               claims: ^merged_claims,
               authorization_scheme: "Bearer",
               binding_type: "dpop+mtls",
               binding_requirements: %{
                 dpop_jkt: "proof-thumbprint",
                 mtls_x5t_s256: "cert-thumbprint"
               }
             } = conn.assigns[:access_token]
    end
  end
end
