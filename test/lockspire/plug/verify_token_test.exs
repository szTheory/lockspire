defmodule Lockspire.Plug.VerifyTokenTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  import Plug.Conn
  import Plug.Test

  alias Lockspire.AccessToken
  alias Lockspire.KeyCache
  alias Lockspire.Plug.RequireToken
  alias Lockspire.Plug.VerifyToken
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

  defp verify_conn(conn, opts \\ []) do
    conn
    |> VerifyToken.call(VerifyToken.init(opts))
  end

  defp generate_key_and_token(claims \\ %{}, header_overrides \\ %{}) do
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

    # Defaults are intentionally aligned with the five RFC 9068 / RFC 8725
    # compliance rules `validate_rfc9068_compliance/2` enforces (D-02). Tests
    # that need to violate a specific rule pass `claims: %{"key" => nil}` to
    # delete the default, or pass a non-conforming value as an override.
    default_claims = %{
      "client_id" => "test_client",
      "iss" => Lockspire.Config.issuer!(),
      "sub" => "test-user-#{System.unique_integer()}",
      "iat" => System.os_time(:second) - 60,
      "exp" => System.os_time(:second) + 3600,
      "nbf" => System.os_time(:second) - 60
    }

    merged_claims =
      default_claims
      |> Map.merge(claims)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    default_header = %{"alg" => "RS256", "kid" => kid, "typ" => "at+jwt"}

    merged_header =
      default_header
      |> Map.merge(header_overrides)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    {_, signed_token} =
      JOSE.JWT.sign(jose_jwk, merged_header, merged_claims)
      |> JOSE.JWS.compact()

    {signed_token, merged_claims}
  end

  defp build_opaque_token,
    do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  describe "VerifyToken plug" do
    test "init/1 rejects simultaneous audience and audiences options" do
      assert_raise ArgumentError, ~r/only one of :audience or :audiences/, fn ->
        VerifyToken.init(audience: "billing-api", audiences: ["admin-api"])
      end
    end

    test "init/1 preserves validated route restriction options" do
      opts = VerifyToken.init(scopes: ["read:billing"], audience: "billing-api")
      assert Keyword.fetch!(opts, :scopes) == ["read:billing"]
      assert Keyword.fetch!(opts, :audience) == "billing-api"
      assert Keyword.fetch!(opts, :enforce_audience) == false

      opts = VerifyToken.init(audiences: ["billing-api", "ledger-api"])
      assert Keyword.fetch!(opts, :scopes) == []
      assert Keyword.fetch!(opts, :audiences) == ["billing-api", "ledger-api"]
      assert Keyword.fetch!(opts, :enforce_audience) == false
    end

    test "init/1 raises when :enforce_audience is true and neither :audience nor :audiences is supplied (D-07)" do
      assert_raise ArgumentError, ~r/enforce_audience/, fn ->
        VerifyToken.init(enforce_audience: true)
      end

      assert_raise ArgumentError, ~r/audience/, fn ->
        VerifyToken.init(enforce_audience: true)
      end
    end

    test "init/1 with :enforce_audience true and :audience does not raise (D-07)" do
      opts = VerifyToken.init(enforce_audience: true, audience: "billing-api")
      assert Keyword.fetch!(opts, :audience) == "billing-api"
      assert Keyword.fetch!(opts, :enforce_audience) == true
    end

    test "init/1 with :enforce_audience true and :audiences does not raise (D-07)" do
      opts = VerifyToken.init(enforce_audience: true, audiences: ["billing-api", "admin-api"])
      assert Keyword.fetch!(opts, :audiences) == ["billing-api", "admin-api"]
      assert Keyword.fetch!(opts, :enforce_audience) == true
    end

    test "init/1 with :enforce_audience false and no audience does not raise (D-07)" do
      opts = VerifyToken.init(enforce_audience: false)
      assert Keyword.fetch!(opts, :enforce_audience) == false
    end

    test "init/1 with no options preserves back-compat with no-audience mounts (D-07)" do
      opts = VerifyToken.init([])
      assert Keyword.fetch!(opts, :enforce_audience) == false
    end

    test "init/1 with only :audience and no :enforce_audience defaults to enforce_audience: false (D-07)" do
      opts = VerifyToken.init(audience: "billing-api")
      assert Keyword.fetch!(opts, :audience) == "billing-api"
      assert Keyword.fetch!(opts, :enforce_audience) == false
    end

    test "assigns access_token with missing_token error when no header" do
      conn = build_conn() |> verify_conn()

      assert %AccessToken{error: :missing_token} = conn.assigns[:access_token]
      refute conn.halted
    end

    test "assigns access_token with missing_token error when not a Bearer token" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Basic abc")
        |> verify_conn()

      assert %AccessToken{error: :missing_token} = conn.assigns[:access_token]
      refute conn.halted
    end

    test "assigns invalid_token when token is malformed" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer not.a.jwt")
        |> verify_conn()

      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when kid is not found" do
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})

      {_, token} =
        JOSE.JWT.sign(jose_jwk, %{"alg" => "RS256", "kid" => "unknown-kid"}, %{
          "client_id" => "client"
        })
        |> JOSE.JWS.compact()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when signature is invalid" do
      {token, _claims} = generate_key_and_token()

      tampered_token = token <> "tamper"

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{tampered_token}")
        |> verify_conn()

      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when exp is in the past" do
      {token, _claims} = generate_key_and_token(%{"exp" => System.os_time(:second) - 3600})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns invalid_token when nbf is in the future" do
      {token, _claims} = generate_key_and_token(%{"nbf" => System.os_time(:second) + 3600})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: :invalid_token} = conn.assigns[:access_token]
    end

    test "assigns valid AccessToken when everything is correct" do
      {token, claims} = generate_key_and_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

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
        |> verify_conn()

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
        |> verify_conn()

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

    test "accepts a matching audience from a string aud claim" do
      {token, claims} = generate_key_and_token(%{"aud" => "billing-api"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn(audience: "billing-api")

      assert %AccessToken{claims: ^claims, error: nil} = conn.assigns[:access_token]
    end

    test "accepts any configured audience from an aud list claim" do
      {token, claims} = generate_key_and_token(%{"aud" => ["admin-api", "billing-api"]})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn(audiences: ["billing-api", "ledger-api"])

      assert %AccessToken{claims: ^claims, error: nil} = conn.assigns[:access_token]
    end

    test "records structured invalid_token errors for audience mismatch and malformed aud claims" do
      {mismatch_token, _claims} = generate_key_and_token(%{"aud" => "admin-api"})
      {malformed_token, _claims} = generate_key_and_token(%{"aud" => [123, "billing-api"]})

      mismatch_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{mismatch_token}")
        |> verify_conn(audience: "billing-api")

      assert %{
               category: :token_restriction,
               challenge: :bearer,
               reason_code: :invalid_audience,
               error: "invalid_token",
               error_description: "The access token audience is invalid for this route",
               required_audiences: ["billing-api"]
             } = mismatch_conn.assigns.access_token.error

      malformed_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{malformed_token}")
        |> verify_conn(audience: "billing-api")

      assert %{
               category: :token_restriction,
               reason_code: :invalid_audience
             } = malformed_conn.assigns.access_token.error
    end

    test "records structured invalid_token errors when a required audience is missing" do
      {token, _claims} = generate_key_and_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn(audience: "billing-api")

      assert %{
               category: :token_restriction,
               reason_code: :missing_audience,
               error: "invalid_token"
             } = conn.assigns.access_token.error
    end

    test "normalizes scope claim and records insufficient_scope errors when scopes are missing" do
      {ok_token, ok_claims} =
        generate_key_and_token(%{"scope" => "read:billing read:billing write:reports"})

      ok_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{ok_token}")
        |> verify_conn(scopes: ["read:billing", "write:reports"])

      assert %AccessToken{claims: ^ok_claims, error: nil} = ok_conn.assigns.access_token

      {denied_token, _claims} = generate_key_and_token(%{"scope" => "write:reports"})

      denied_conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{denied_token}")
        |> verify_conn(scopes: ["read:billing"])

      assert %{
               category: :insufficient_scope,
               challenge: :bearer,
               reason_code: :insufficient_scope,
               error: "insufficient_scope",
               error_description: "The access token is missing a required scope",
               required_scopes: ["read:billing"]
             } = denied_conn.assigns.access_token.error
    end

    test "emits redaction-safe logs for JWT failures and route restriction failures" do
      malformed_log =
        capture_log(fn ->
          build_conn()
          |> put_req_header("authorization", "Bearer not.a.jwt")
          |> verify_conn()
        end)

      assert malformed_log =~ "reason=malformed"
      refute malformed_log =~ "not.a.jwt"

      {token, _claims} =
        generate_key_and_token(%{"aud" => "admin-api", "scope" => "write:reports"})

      restriction_log =
        capture_log(fn ->
          build_conn()
          |> put_req_header("authorization", "Bearer #{token}")
          |> verify_conn(audience: "billing-api", scopes: ["read:billing"])
        end)

      assert restriction_log =~ "category=token_restriction"
      assert restriction_log =~ "reason=invalid_audience"
      refute restriction_log =~ token
    end
  end

  describe "VerifyToken plug -- opaque-token rejection (VERIFIER-01 / D-01)" do
    test "rejects a 32-byte Base64URL no-dots opaque token with the structured opaque error" do
      opaque = build_opaque_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{opaque}")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 category: :token_format,
                 challenge: :bearer,
                 reason_code: :opaque_token_not_accepted,
                 error: "invalid_token",
                 error_description: "opaque tokens not accepted on this route"
               },
               authorization_scheme: "Bearer"
             } = conn.assigns[:access_token]

      refute conn.halted
    end

    test "rejects a two-segment token as opaque" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer a.b")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 reason_code: :opaque_token_not_accepted,
                 challenge: :bearer,
                 error: "invalid_token",
                 error_description: "opaque tokens not accepted on this route"
               }
             } = conn.assigns[:access_token]
    end

    test "rejects a five-segment token as opaque" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer a.b.c.d.e")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 reason_code: :opaque_token_not_accepted,
                 challenge: :bearer,
                 error: "invalid_token",
                 error_description: "opaque tokens not accepted on this route"
               }
             } = conn.assigns[:access_token]
    end

    test "rejects a three-segment token with an empty middle segment as opaque" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer a..c")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 reason_code: :opaque_token_not_accepted,
                 challenge: :bearer,
                 error: "invalid_token",
                 error_description: "opaque tokens not accepted on this route"
               }
             } = conn.assigns[:access_token]
    end

    test "rejects a three-segment token with a non-Base64URL character as opaque" do
      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer a!b.c.d")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 reason_code: :opaque_token_not_accepted,
                 challenge: :bearer,
                 error: "invalid_token",
                 error_description: "opaque tokens not accepted on this route"
               }
             } = conn.assigns[:access_token]
    end

    test "passes an opaque token through RequireToken as a 401 with the RFC 6750 WWW-Authenticate header" do
      opaque = build_opaque_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{opaque}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      assert conn.halted

      [www_authenticate] = get_resp_header(conn, "www-authenticate")

      assert www_authenticate ==
               ~s(Bearer realm="Lockspire", error="invalid_token", error_description="opaque tokens not accepted on this route")
    end

    test "emits a redaction-safe log line with reason=opaque_token_not_accepted" do
      opaque = build_opaque_token()

      log =
        capture_log(fn ->
          build_conn()
          |> put_req_header("authorization", "Bearer #{opaque}")
          |> verify_conn()
        end)

      assert log =~ "reason=opaque_token_not_accepted"
      assert log =~ "category=token_format"
      refute log =~ opaque
    end
  end

  describe "VerifyToken plug -- RFC 9068 compliance (D-02, D-03, D-04)" do
    test "accepts JWT with typ=at+jwt (canonical lowercase)" do
      {token, _claims} = generate_key_and_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: nil} = conn.assigns[:access_token]
    end

    test "accepts JWT with typ=AT+JWT (uppercase)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "AT+JWT"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: nil} = conn.assigns[:access_token]
    end

    test "accepts JWT with typ=At+Jwt (mixed case)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "At+Jwt"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: nil} = conn.assigns[:access_token]
    end

    test "accepts JWT with typ=application/at+jwt (RFC 9068 §2.1 full form)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "application/at+jwt"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: nil} = conn.assigns[:access_token]
    end

    test "rejects JWT with typ=JWT (RFC 8725 §3.11 cross-JWT confusion)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "JWT"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 category: :token_validation,
                 challenge: :bearer,
                 reason_code: :invalid_typ,
                 error: "invalid_token",
                 error_description: error_description
               }
             } = conn.assigns[:access_token]

      assert error_description =~ "typ"
      assert error_description =~ "at+jwt"
    end

    test "rejects JWT with typ=jwt (lowercase, still wrong post-normalization)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "jwt"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_typ}} = conn.assigns[:access_token]
    end

    test "rejects JWT with missing typ header" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => nil})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_typ}} = conn.assigns[:access_token]
    end

    test "rejects JWT with empty-string typ header" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => ""})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_typ}} = conn.assigns[:access_token]
    end

    test "rejects JWT with typ=dpop+jwt (verifier MUST NOT accept DPoP-proof typ)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "dpop+jwt"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_typ}} = conn.assigns[:access_token]
    end

    test "rejects JWT with typ=application/jwt (stripping prefix leaves jwt, not at+jwt)" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "application/jwt"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_typ}} = conn.assigns[:access_token]
    end

    test "rejects JWT with wrong iss claim (RFC 9068 §4 issuer pinning)" do
      {token, _claims} = generate_key_and_token(%{"iss" => "https://attacker.example/op"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 category: :token_validation,
                 challenge: :bearer,
                 reason_code: :invalid_issuer,
                 error: "invalid_token",
                 error_description: error_description
               }
             } = conn.assigns[:access_token]

      assert error_description =~ "iss"
    end

    test "rejects JWT with missing iss claim" do
      {token, _claims} = generate_key_and_token(%{"iss" => nil})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_issuer}} = conn.assigns[:access_token]
    end

    test "rejects JWT with empty iss claim" do
      {token, _claims} = generate_key_and_token(%{"iss" => ""})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_issuer}} = conn.assigns[:access_token]
    end

    test "rejects JWT with trailing-slash variant of configured iss (exact compare, no normalization)" do
      configured = Lockspire.Config.issuer!()
      variant = configured <> "/"

      {token, _claims} = generate_key_and_token(%{"iss" => variant})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_issuer}} = conn.assigns[:access_token]
    end

    test "rejects JWT with missing exp claim (RFC 9068 §2.2)" do
      {token, _claims} = generate_key_and_token(%{"exp" => nil})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 category: :token_validation,
                 challenge: :bearer,
                 reason_code: :missing_exp,
                 error: "invalid_token",
                 error_description: error_description
               }
             } = conn.assigns[:access_token]

      assert error_description =~ "exp"
    end

    test "rejects JWT with exp=0 (zero is not a positive integer)" do
      {token, _claims} = generate_key_and_token(%{"exp" => 0})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :missing_exp}} = conn.assigns[:access_token]
    end

    test "rejects JWT with exp=-100 (negative not positive)" do
      {token, _claims} = generate_key_and_token(%{"exp" => -100})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :missing_exp}} = conn.assigns[:access_token]
    end

    test "rejects JWT with missing iat claim (RFC 9068 §2.2)" do
      {token, _claims} = generate_key_and_token(%{"iat" => nil})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 category: :token_validation,
                 challenge: :bearer,
                 reason_code: :missing_iat,
                 error: "invalid_token",
                 error_description: error_description
               }
             } = conn.assigns[:access_token]

      assert error_description =~ "iat"
    end

    test "rejects JWT with iat=0 (not positive)" do
      {token, _claims} = generate_key_and_token(%{"iat" => 0})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :missing_iat}} = conn.assigns[:access_token]
    end

    test "rejects JWT with missing sub claim (RFC 9068 §2.2)" do
      {token, _claims} = generate_key_and_token(%{"sub" => nil})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{
               error: %{
                 category: :token_validation,
                 challenge: :bearer,
                 reason_code: :missing_sub,
                 error: "invalid_token",
                 error_description: error_description
               }
             } = conn.assigns[:access_token]

      assert error_description =~ "sub"
    end

    test "rejects JWT with empty sub claim" do
      {token, _claims} = generate_key_and_token(%{"sub" => ""})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :missing_sub}} = conn.assigns[:access_token]
    end

    test "rejects JWT with whitespace-only sub claim" do
      {token, _claims} = generate_key_and_token(%{"sub" => "   "})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :missing_sub}} = conn.assigns[:access_token]
    end

    test "D-02 order: when multiple rules are violated, invalid_typ wins" do
      {token, _claims} =
        generate_key_and_token(
          %{"iss" => "https://attacker.example", "exp" => nil, "iat" => nil, "sub" => nil},
          %{"typ" => "JWT"}
        )

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn()

      assert %AccessToken{error: %{reason_code: :invalid_typ}} = conn.assigns[:access_token]
    end

    test "end-to-end through RequireToken: invalid_typ emerges as 401 with WWW-Authenticate naming the rule" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "JWT"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      assert conn.halted

      [www_authenticate] = get_resp_header(conn, "www-authenticate")

      assert www_authenticate =~ ~s(error="invalid_token")
      assert www_authenticate =~ "typ"
      assert www_authenticate =~ "at+jwt"
    end

    test "emits a redaction-safe log line with reason=invalid_typ" do
      {token, _claims} = generate_key_and_token(%{}, %{"typ" => "JWT"})

      log =
        capture_log(fn ->
          build_conn()
          |> put_req_header("authorization", "Bearer #{token}")
          |> verify_conn()
        end)

      assert log =~ "reason=invalid_typ"
      refute log =~ token
    end
  end

  describe "VerifyToken plug -- challenge derivation from binding (D-05, D-06)" do
    test "DPoP-bound token (cnf.jkt) failing audience emits challenge: :dpop and DPoP WWW-Authenticate" do
      claims = %{"cnf" => %{"jkt" => "proof-thumbprint"}, "aud" => "wrong-audience"}
      {token, _claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init(audience: "expected-audience"))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^DPoP realm="Lockspire"/
      assert www_authenticate =~ ~s(error="invalid_token")
      assert www_authenticate =~ "algs="
    end

    test "DPoP-bound token (cnf.jkt) failing scope emits 403 with DPoP WWW-Authenticate" do
      claims = %{
        "cnf" => %{"jkt" => "proof-thumbprint"},
        "scope" => "read:foo"
      }

      {token, _claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init(scopes: ["write:bar"]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 403
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^DPoP realm="Lockspire"/
      assert www_authenticate =~ ~s(error="insufficient_scope")
      assert www_authenticate =~ "algs="
    end

    test "DPoP-bound token failing RFC 9068 typ check emits DPoP WWW-Authenticate" do
      claims = %{"cnf" => %{"jkt" => "proof-thumbprint"}}
      {token, _claims} = generate_key_and_token(claims, %{"typ" => "JWT"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^DPoP realm="Lockspire"/
      assert www_authenticate =~ ~s(error="invalid_token")
      assert www_authenticate =~ "algs="
    end

    test "mTLS-bound token (cnf.x5t#S256 only) failing audience emits challenge: :bearer (RFC 8705 §3)" do
      claims = %{"cnf" => %{"x5t#S256" => "cert-thumbprint"}, "aud" => "wrong-audience"}
      {token, _claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init(audience: "expected-audience"))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^Bearer realm="Lockspire"/
      assert www_authenticate =~ ~s(error="invalid_token")
    end

    test "dpop+mtls combined token (both cnf claims) failing audience emits DPoP (DPoP wins per D-05 row 1)" do
      claims = %{
        "cnf" => %{"jkt" => "proof-thumbprint", "x5t#S256" => "cert-thumbprint"},
        "aud" => "wrong-audience"
      }

      {token, _claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init(audience: "expected-audience"))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^DPoP realm="Lockspire"/
      assert www_authenticate =~ "algs="
    end

    test "no-cnf token, request used Authorization: DPoP, audience failure emits DPoP (D-05 row 3 tiebreaker)" do
      {token, _claims} = generate_key_and_token(%{"aud" => "wrong-audience"})

      conn =
        build_conn()
        |> put_req_header("authorization", "DPoP #{token}")
        |> VerifyToken.call(VerifyToken.init(audience: "expected-audience"))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^DPoP realm="Lockspire"/
      assert www_authenticate =~ "algs="
    end

    test "no-cnf token, request used Authorization: Bearer, audience failure emits Bearer (D-05 row 4 default)" do
      {token, _claims} = generate_key_and_token(%{"aud" => "wrong-audience"})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init(audience: "expected-audience"))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^Bearer realm="Lockspire"/
    end

    test "no-cnf token, Bearer scheme, RFC 9068 missing_exp emits Bearer" do
      {token, _claims} = generate_key_and_token(%{"exp" => nil})

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^Bearer realm="Lockspire"/
    end

    test "Plan 01 opaque token presented as Authorization: DPoP emits DPoP (request-scheme tiebreaker)" do
      opaque = build_opaque_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "DPoP #{opaque}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^DPoP realm="Lockspire"/
      assert www_authenticate =~ "algs="
    end

    test "Plan 01 opaque token presented as Authorization: Bearer emits Bearer (regression)" do
      opaque = build_opaque_token()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{opaque}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")

      assert www_authenticate ==
               ~s(Bearer realm="Lockspire", error="invalid_token", error_description="opaque tokens not accepted on this route")
    end

    test "REGRESSION: legacy bare-atom error path (unknown kid) emits Bearer (default_invalid_error/0)" do
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})

      {_, token} =
        JOSE.JWT.sign(jose_jwk, %{"alg" => "RS256", "kid" => "unknown-kid", "typ" => "at+jwt"}, %{
          "client_id" => "client"
        })
        |> JOSE.JWS.compact()

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(VerifyToken.init([]))
        |> RequireToken.call(RequireToken.init([]))

      assert conn.status == 401
      [www_authenticate] = get_resp_header(conn, "www-authenticate")
      assert www_authenticate =~ ~r/^Bearer realm="Lockspire"/
    end

    test "AccessToken.error on DPoP-bound audience failure carries challenge: :dpop directly" do
      claims = %{"cnf" => %{"jkt" => "proof-thumbprint"}, "aud" => "wrong-audience"}
      {token, _claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn(audience: "expected-audience")

      assert %AccessToken{
               error: %{
                 category: :token_restriction,
                 challenge: :dpop,
                 reason_code: :invalid_audience
               }
             } = conn.assigns[:access_token]
    end

    test "AccessToken.error on mTLS-bound audience failure carries challenge: :bearer directly" do
      claims = %{"cnf" => %{"x5t#S256" => "cert-thumbprint"}, "aud" => "wrong-audience"}
      {token, _claims} = generate_key_and_token(claims)

      conn =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> verify_conn(audience: "expected-audience")

      assert %AccessToken{
               error: %{
                 category: :token_restriction,
                 challenge: :bearer,
                 reason_code: :invalid_audience
               }
             } = conn.assigns[:access_token]
    end
  end
end
