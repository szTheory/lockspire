defmodule Lockspire.Protocol.ClientSecretLifetimeAuthTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error
  alias Lockspire.Security.Policy
  alias Lockspire.JarTestHelpers

  @secret "phase-164-shared-secret"
  @now ~U[2026-10-20 12:00:00Z]
  @der_cert Base.decode64!(
              "MIIDlzCCAn+gAwIBAgIUf9kmQnJK500+Nv0BWu0gM48zcgIwDQYJKoZIhvcNAQELBQAwNjEUMBIGA1UEAwwLZXhhbXBsZS5jb20xETAPBgNVBAoMCFRlc3QgT3JnMQswCQYDVQQGEwJVUzAeFw0yNjA1MjIyMjI0MzhaFw0zNjA1MTkyMjI0MzhaMDYxFDASBgNVBAMMC2V4YW1wbGUuY29tMREwDwYDVQQKDAhUZXN0IE9yZzELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnzGcJzq614Cz9AN6axBrGwnx0odNBZJjdQ0VODx+WxDWepf5B9+B0qNEyMBg6eMzRWNSXPs5VaglfJUte35OTXtIh+Rz84PyPw7a8Yg+4EOasw2zqsxN+9uH/VYpV3dcrEJdA9Xx0x0ksLWV0vClTCSWNnJbJ8caftyp6fUL2kBPxv0nX/MVjNJxcm5QAmHXh+dSZ2CgZr6bdzN3JzNdc9JeYVJ9/7sMi7mbjSwLZElBBLIlPtJX7jVVTxLKR5UTnY9kYdxF3VaF42P/YPrcYJQ5LH8iilBxYL/qnct+ZwzvYgKACB8CEzNqIhTbDXzFh6J97OFDUnm+5XWIFMt+fAgMBAAGjgZwwgZkwHQYDVR0OBBYEFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMB8GA1UdIwQYMBaAFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMA8GA1UdEwEB/wQFMAMBAf8wRgYDVR0RBD8wPYILZXhhbXBsZS5jb22GFmh0dHBzOi8vZXhhbXBsZS5jb20vaWSHBMCoAQGBEHRlc3RAZXhhbXBsZS5jb20wDQYJKoZIhvcNAQELBQADggEBAJtQ86lCGy/Y+7SRx/sFWYhC9UaeRJix84ZBnqVEMA37uvZQ4N3AHP+XDhuhSe++ZMqkp9sZHsWQCIZkmqqLUtRUKGiFbe9DcSvbn9PuSN56EbLM0ZCNIt41lEpAYVOogeakehvU0YsSPA4p/MxQ7ZkizWqY9iqnZC93RX43FFLVlpR0YTnq4tiTo4Eln5kLdqhMJdBM/PUUjQAsKK4tUrxRI5u7ycKzI04/M8mo5tbg3UsIiZ4WiFaUENCMcI4RxQca2Kn5mN3gJyaE/NNM2E1fRhZQThVIGZOXO+BIvf1McaOBGbLeRdr2pP3/CORqljaH+kapJnOFVFw+N1daB8g="
            )

  test "basic and post share one decision instant for secret and app eligibility" do
    client = %Client{
      client_id: "lifetime-basic-client",
      token_endpoint_auth_method: :client_secret_basic,
      client_secret_hash: Policy.hash_client_secret(@secret),
      lifetime_version: 1,
      client_expires_at: @now,
      client_secret_expires_at: @now
    }

    Process.put(:client_secret_lifetime_auth_client, client)
    calls = :counters.new(1, [:atomics])

    # If auth samples the clock separately, secret auth sees the pre-deadline
    # instant and app eligibility sees equality. One shared sample must decide
    # both authorities consistently.
    clock = fn ->
      case :counters.get(calls, 1) do
        0 ->
          :counters.add(calls, 1, 1)
          DateTime.add(@now, -1, :second)

        _ ->
          :counters.add(calls, 1, 1)
          @now
      end
    end

    assert {:ok, %Client{}} =
             ClientAuth.authenticate(%{}, basic_header("lifetime-basic-client", @secret),
               client_store: __MODULE__.Store,
               now: clock
             )

    assert :counters.get(calls, 1) == 1
  end

  test "basic and post reject a secret at the strict deadline" do
    for method <- [:client_secret_basic, :client_secret_post] do
      client = %Client{
        client_id: "lifetime-#{method}",
        token_endpoint_auth_method: method,
        client_secret_hash: Policy.hash_client_secret(@secret),
        lifetime_version: 1,
        client_expires_at: DateTime.add(@now, 60, :second),
        client_secret_expires_at: @now
      }

      Process.put(:client_secret_lifetime_auth_client, client)

      {params, authorization} =
        if method == :client_secret_basic do
          {%{}, basic_header(client.client_id, @secret)}
        else
          {%{"client_id" => client.client_id, "client_secret" => @secret}, nil}
        end

      assert {:error,
              %Error{status: 401, error: "invalid_client", reason_code: :client_secret_expired}} =
               ClientAuth.authenticate(params, authorization,
                 client_store: __MODULE__.Store,
                 now: fn -> @now end
               )
    end
  end

  test "a valid secret JWT assertion receives no secret deadline skew allowance" do
    client = %Client{
      client_id: "lifetime-secret-jwt",
      token_endpoint_auth_method: :client_secret_jwt,
      client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(@secret),
      lifetime_version: 1,
      client_expires_at: DateTime.add(@now, 60, :second),
      client_secret_expires_at: @now
    }

    Process.put(:client_secret_lifetime_auth_client, client)

    assertion =
      JarTestHelpers.sign_jar(
        JOSE.JWK.from_oct(@secret),
        %{
          "iss" => client.client_id,
          "sub" => client.client_id,
          "aud" => Lockspire.Config.issuer!(),
          "jti" => "lifetime-secret-jwt-jti",
          "iat" => DateTime.to_unix(@now),
          "exp" => DateTime.add(@now, 300, :second) |> DateTime.to_unix()
        },
        alg: "HS256"
      )

    assert {:error,
            %Error{status: 401, error: "invalid_client", reason_code: :client_secret_expired}} =
             ClientAuth.authenticate(jwt_params(assertion), nil,
               client_store: __MODULE__.Store,
               jti_store: __MODULE__.ReplayStore,
               server_policy_store: __MODULE__.ServerPolicyStore,
               supported_jwt_auth_methods: [:client_secret_jwt],
               now: fn -> @now end
             )

    assert Process.get(:client_secret_lifetime_auth_jtis) ==
             MapSet.new(["lifetime-secret-jwt-jti"])
  end

  test "all non-secret methods accept a past dormant secret deadline with real credentials" do
    keys = JarTestHelpers.generate_keys()

    private_assertion =
      JarTestHelpers.sign_jar(
        keys.private_jwk,
        %{
          "iss" => "lifetime-private-key",
          "sub" => "lifetime-private-key",
          "aud" => Lockspire.Config.issuer!(),
          "jti" => "lifetime-private-key-jti",
          "iat" => DateTime.to_unix(@now),
          "exp" => DateTime.add(@now, 300, :second) |> DateTime.to_unix()
        },
        alg: "RS256"
      )

    {:ok, cert} = Lockspire.Mtls.Certificate.parse(@der_cert)
    cert_jwk = JOSE.JWK.from_key(cert.public_key)
    {_modules, cert_jwk_map} = JOSE.JWK.to_map(cert_jwk)

    cases = [
      {%Client{
         client_id: "lifetime-public",
         token_endpoint_auth_method: :none,
         client_secret_hash: Policy.hash_client_secret(@secret),
         lifetime_version: 1,
         client_expires_at: DateTime.add(@now, 60, :second),
         client_secret_expires_at: DateTime.add(@now, -60, :second)
       }, %{"client_id" => "lifetime-public"}, nil, []},
      {%Client{
         client_id: "lifetime-private-key",
         token_endpoint_auth_method: :private_key_jwt,
         client_secret_hash: Policy.hash_client_secret(@secret),
         jwks: keys.pub_jwk_map,
         lifetime_version: 1,
         client_expires_at: DateTime.add(@now, 60, :second),
         client_secret_expires_at: DateTime.add(@now, -60, :second)
       }, jwt_params(private_assertion), nil, []},
      {%Client{
         client_id: "lifetime-tls",
         token_endpoint_auth_method: :tls_client_auth,
         client_secret_hash: Policy.hash_client_secret(@secret),
         tls_client_auth_subject_dn: "C=US,O=Test Org,CN=example.com",
         lifetime_version: 1,
         client_expires_at: DateTime.add(@now, 60, :second),
         client_secret_expires_at: DateTime.add(@now, -60, :second)
       }, %{"client_id" => "lifetime-tls"}, nil, [mtls_cert: @der_cert]},
      {%Client{
         client_id: "lifetime-self-signed-tls",
         token_endpoint_auth_method: :self_signed_tls_client_auth,
         client_secret_hash: Policy.hash_client_secret(@secret),
         jwks: %{"keys" => [cert_jwk_map]},
         lifetime_version: 1,
         client_expires_at: DateTime.add(@now, 60, :second),
         client_secret_expires_at: DateTime.add(@now, -60, :second)
       }, %{"client_id" => "lifetime-self-signed-tls"}, nil, [mtls_cert: @der_cert]}
    ]

    for {client, params, authorization, extra_opts} <- cases do
      Process.put(:client_secret_lifetime_auth_client, client)

      assert {:ok, %Client{client_id: client_id}} =
               ClientAuth.authenticate(
                 params,
                 authorization,
                 Keyword.merge(extra_opts,
                   client_store: __MODULE__.Store,
                   jti_store: __MODULE__.ReplayStore,
                   server_policy_store: __MODULE__.ServerPolicyStore,
                   now: fn -> @now end
                 )
               )

      assert client_id == client.client_id
    end
  end

  defmodule Store do
    def fetch_client_by_id(client_id) do
      case Process.get(:client_secret_lifetime_auth_client) do
        %Client{client_id: ^client_id} = client -> {:ok, client}
        _ -> {:ok, nil}
      end
    end
  end

  defmodule ReplayStore do
    def record_used_jti(%UsedJti{jti: jti}) do
      used = Process.get(:client_secret_lifetime_auth_jtis, MapSet.new())

      if MapSet.member?(used, jti) do
        {:ok, :replay}
      else
        Process.put(:client_secret_lifetime_auth_jtis, MapSet.put(used, jti))
        {:ok, :accepted}
      end
    end
  end

  defmodule ServerPolicyStore do
    def get_server_policy, do: {:ok, %ServerPolicy{security_profile: :none}}
  end

  defp basic_header(client_id, secret),
    do: "Basic " <> Base.encode64("#{client_id}:#{secret}")

  defp jwt_params(assertion),
    do: %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
end
