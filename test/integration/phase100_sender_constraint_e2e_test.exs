defmodule Lockspire.Integration.Phase100SenderConstraintE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint
  @issuer "https://example.test/lockspire"
  @protected_route "/api/billing/summary"
  @protected_target_uri "http://api.example.test/api/billing/summary"

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.KeyCache
  alias Lockspire.Protocol.AccessTokenSigner
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.MTLSTokenBinding
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    # MUST match Config.issuer!() so signer's iss == verifier's pin (Pattern 1)
    Application.put_env(:lockspire, :issuer, @issuer)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile", "email", "read:billing"])

    Application.put_env(
      :lockspire,
      :account_resolver,
      GeneratedHostApp.Lockspire.TestAccountResolver
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})

    kid = "phase100-kid-#{System.unique_integer()}"
    signing_key = publish_signing_key(kid)

    %{signing_key: signing_key, signing_kid: kid}
  end

  # BIND-01: DPoP-bound at+jwt minted via AccessTokenSigner.issue/3 through the full pipeline
  test "BIND-01: DPoP-bound at+jwt minted by AccessTokenSigner traverses the full pipeline to 200 with cnf binding_requirements" do
    dpop_keys = JarTestHelpers.generate_ec_keys()
    {:ok, jkt} = DPoP.thumbprint(dpop_keys.pub_jwk_map)

    # D-07: mint via the real signer, NOT hand-signed — proves Phase 99 maybe_put_cnf carry-through
    token = %Token{
      token_hash: "unused",
      token_type: :access_token,
      client_id: "generated-host-api-client",
      account_id: "generated-host-user",
      scopes: ["read:billing"],
      # LIST aud — A1 confirmed VerifyToken accepts list aud (Plan 02)
      audience: ["billing-api"],
      # The thing Phase 99 carries through via maybe_put_cnf/2
      cnf: %{"jkt" => jkt},
      issued_at: DateTime.utc_now(),
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
    }

    client = %Client{client_id: "generated-host-api-client", access_token_format: :jwt}
    # server_policy_store omitted -> :jwt fallback per resolve_format/98 (A2)
    request = %{opts: [key_store: Lockspire.Config.repo!()]}

    {:ok, raw_at_jwt, _hash} = AccessTokenSigner.issue(token, client, request)

    # Mandatory three-request nonce dance (Pitfall 1) — a single proof without nonce
    # returns 401 use_dpop_nonce, never 200.

    # Request 1: DPoP proof WITHOUT nonce -> 401 use_dpop_nonce + DPoP-Nonce response header
    challenge_conn =
      protected_conn()
      |> put_req_header("authorization", "DPoP #{raw_at_jwt}")
      |> put_req_header("dpop", generate_dpop_proof(dpop_keys.private_jwk, raw_at_jwt, nil))
      |> get(@protected_route)

    assert challenge_conn.status == 401
    assert [nonce_challenge] = get_resp_header(challenge_conn, "www-authenticate")
    assert nonce_challenge =~ "error=\"use_dpop_nonce\""
    assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")

    # Request 2: DPoP proof WITH nonce -> 200
    proof = generate_dpop_proof(dpop_keys.private_jwk, raw_at_jwt, retry_nonce)

    success_conn =
      protected_conn()
      |> put_req_header("authorization", "DPoP #{raw_at_jwt}")
      |> put_req_header("dpop", proof)
      |> get(@protected_route)

    assert success_conn.status == 200

    assert %{
             "access_token" => %{
               "binding_type" => "dpop",
               "binding_requirements" => %{"dpop_jkt" => ^jkt}
             }
           } = Jason.decode!(success_conn.resp_body)
  end

  # BIND-02: mTLS-bound at+jwt minted via AccessTokenSigner.issue/3 through the full pipeline
  test "BIND-02: mTLS-bound at+jwt minted by AccessTokenSigner traverses the full pipeline to 200 with binding_type mtls" do
    # D-08: synthetic string cert — confirmed sufficient; real DER-cert/:mtls_extractor deferred
    cert = "phase100-mtls-client-cert"

    # Derive x5t from the SAME cert string presented via conn.private — CRITICAL for confirmation_matches?/2
    {:ok, x5t} = MTLSTokenBinding.thumbprint(cert)

    # D-07: mint via the real signer — proves Phase 99 maybe_put_cnf carry-through for mTLS
    token = %Token{
      token_hash: "unused",
      token_type: :access_token,
      client_id: "generated-host-api-client",
      account_id: "generated-host-user",
      scopes: ["read:billing"],
      # LIST aud — A1 confirmed VerifyToken accepts list aud (Plan 02)
      audience: ["billing-api"],
      # cnf carries x5t#S256 — the thing Phase 99 carries through via maybe_put_cnf/2
      cnf: %{"x5t#S256" => x5t},
      issued_at: DateTime.utc_now(),
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second)
    }

    client = %Client{client_id: "generated-host-api-client", access_token_format: :jwt}
    request = %{opts: [key_store: Lockspire.Config.repo!()]}

    {:ok, raw_at_jwt, _hash} = AccessTokenSigner.issue(token, client, request)

    # No nonce dance for mTLS — Bearer authorization + cert presented via conn.private
    conn =
      protected_conn()
      |> put_req_header("authorization", "Bearer #{raw_at_jwt}")
      |> Plug.Conn.put_private(:lockspire_mtls_cert, cert)
      |> get(@protected_route)

    assert conn.status == 200

    assert %{
             "access_token" => %{
               "binding_type" => "mtls"
             }
           } = Jason.decode!(conn.resp_body)
  end

  # ---------------------------------------------------------------------------
  # Private helpers — copied verbatim from phase81 (lines 250-255, 257-283, 305-319)
  # ---------------------------------------------------------------------------

  defp protected_conn do
    # Pitfall 3: must pin host "api.example.test" port 80 to match router/CORS config
    build_conn()
    |> Map.put(:host, "api.example.test")
    |> Map.put(:port, 80)
    |> put_req_header("accept", "application/json")
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: "sig",
        public_jwk:
          jwk
          |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    # Mandatory sync point (Pitfall 2) — async refresh races sign/verify -> flaky unknown-kid
    send(KeyCache, :refresh)
    :sys.get_state(KeyCache)
    key
  end

  defp generate_dpop_proof(dpop_key, access_token, nonce) do
    claims =
      %{
        "htm" => "GET",
        "htu" => @protected_target_uri,
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate(),
        "ath" => DPoP.access_token_ath(access_token),
        "nonce" => nonce
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    JarTestHelpers.sign_dpop_proof(dpop_key, claims)
  end
end
