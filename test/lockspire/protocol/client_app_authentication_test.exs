defmodule Lockspire.Protocol.ClientAppAuthenticationTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error
  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication
  alias Lockspire.Protocol.TokenExchange.Internal.LegacyOptions
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Security.Policy

  @der_cert Base.decode64!(
              "MIIDlzCCAn+gAwIBAgIUf9kmQnJK500+Nv0BWu0gM48zcgIwDQYJKoZIhvcNAQELBQAwNjEUMBIGA1UEAwwLZXhhbXBsZS5jb20xETAPBgNVBAoMCFRlc3QgT3JnMQswCQYDVQQGEwJVUzAeFw0yNjA1MjIyMjI0MzhaFw0zNjA1MTkyMjI0MzhaMDYxFDASBgNVBAMMC2V4YW1wbGUuY29tMREwDwYDVQQKDAhUZXN0IE9yZzELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnzGcJzq614Cz9AN6axBrGwnx0odNBZJjdQ0VODx+WxDWepf5B9+B0qNEyMBg6eMzRWNSXPs5VaglfJUte35OTXtIh+Rz84PyPw7a8Yg+4EOasw2zqsxN+9uH/VYpV3dcrEJdA9Xx0x0ksLWV0vClTCSWNnJbJ8caftyp6fUL2kBPxv0nX/MVjNJxcm5QAmHXh+dSZ2CgZr6bdzN3JzNdc9JeYVJ9/7sMi7mbjSwLZElBBLIlPtJX7jVVTxLKR5UTnY9kYdxF3VaF42P/YPrcYJQ5LH8iilBxYL/qnct+ZwzvYgKACB8CEzNqIhTbDXzFh6J97OFDUnm+5XWIFMt+fAgMBAAGjgZwwgZkwHQYDVR0OBBYEFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMB8GA1UdIwQYMBaAFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMA8GA1UdEwEB/wQFMAMBAf8wRgYDVR0RBD8wPYILZXhhbXBsZS5jb22GFmh0dHBzOi8vZXhhbXBsZS5jb20vaWSHBMCoAQGBEHRlc3RAZXhhbXBsZS5jb20wDQYJKoZIhvcNAQELBQADggEBAJtQ86lCGy/Y+7SRx/sFWYhC9UaeRJix84ZBnqVEMA37uvZQ4N3AHP+XDhuhSe++ZMqkp9sZHsWQCIZkmqqLUtRUKGiFbe9DcSvbn9PuSN56EbLM0ZCNIt41lEpAYVOogeakehvU0YsSPA4p/MxQ7ZkizWqY9iqnZC93RX43FFLVlpR0YTnq4tiTo4Eln5kLdqhMJdBM/PUUjQAsKK4tUrxRI5u7ycKzI04/M8mo5tbg3UsIiZ4WiFaUENCMcI4RxQca2Kn5mN3gJyaE/NNM2E1fRhZQThVIGZOXO+BIvf1McaOBGbLeRdr2pP3/CORqljaH+kapJnOFVFw+N1daB8g="
            )

  setup do
    now = ~U[2026-10-20 12:00:00Z]
    secret = "client-secret-for-app-auth-test"
    Process.put(:app_auth_now, now)
    Process.put(:app_auth_secret, secret)
    Process.put(:app_auth_jtis, MapSet.new())
    :ok
  end

  test "all supported authentication methods reject app expiry at equality" do
    now = Process.get(:app_auth_now)
    secret = Process.get(:app_auth_secret)
    keys = JarTestHelpers.generate_keys()
    assertion = signed_assertion(keys.private_jwk, "private-key-client", now)
    secret_jwt = client_secret_assertion(secret, "secret-jwt-client", now)

    {:ok, cert} = Lockspire.Mtls.Certificate.parse(@der_cert)
    cert_jwk = JOSE.JWK.from_key(cert.public_key)
    {_modules, cert_jwk_map} = JOSE.JWK.to_map(cert_jwk)

    clients = [
      {%Client{client_id: "public-client", token_endpoint_auth_method: :none},
       %{"client_id" => "public-client"}, nil, []},
      {%Client{
         client_id: "basic-client",
         token_endpoint_auth_method: :client_secret_basic,
         client_secret_hash: Policy.hash_client_secret(secret)
       }, %{}, basic_header("basic-client", secret), []},
      {%Client{
         client_id: "post-client",
         token_endpoint_auth_method: :client_secret_post,
         client_secret_hash: Policy.hash_client_secret(secret)
       }, %{"client_id" => "post-client", "client_secret" => secret}, nil, []},
      {%Client{
         client_id: "secret-jwt-client",
         token_endpoint_auth_method: :client_secret_jwt,
         client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret)
       }, jwt_params(secret_jwt), nil, [supported_jwt_auth_methods: [:client_secret_jwt]]},
      {%Client{
         client_id: "private-key-client",
         token_endpoint_auth_method: :private_key_jwt,
         jwks: keys.pub_jwk_map
       }, jwt_params(assertion), nil, []},
      {%Client{
         client_id: "tls-client",
         token_endpoint_auth_method: :tls_client_auth,
         tls_client_auth_subject_dn: "C=US,O=Test Org,CN=example.com"
       }, %{"client_id" => "tls-client"}, nil, [mtls_cert: @der_cert]},
      {%Client{
         client_id: "self-signed-client",
         token_endpoint_auth_method: :self_signed_tls_client_auth,
         jwks: %{"keys" => [cert_jwk_map]}
       }, %{"client_id" => "self-signed-client"}, nil, [mtls_cert: @der_cert]}
    ]

    Enum.each(clients, fn {client, params, authorization, extra_opts} ->
      Process.put(:app_auth_client, %{
        client
        | lifetime_version: 1,
          client_expires_at: now,
          client_secret_expires_at: DateTime.add(now, -1, :second)
      })

      assert {:error,
              %Error{status: 401, error: "invalid_client", reason_code: :client_app_expired}} =
               ClientAuth.authenticate(
                 params,
                 authorization,
                 Keyword.merge(extra_opts,
                   client_store: __MODULE__.Store,
                   jti_store: __MODULE__.ReplayStore,
                   server_policy_store: __MODULE__.ServerPolicyStore,
                   supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                   now: fn -> now end
                 )
               )
    end)
  end

  test "injected clock decides before, at, and after the app deadline" do
    deadline = ~U[2026-10-20 12:00:00Z]

    client = %Client{
      client_id: "clock-client",
      token_endpoint_auth_method: :none,
      lifetime_version: 1,
      client_expires_at: deadline
    }

    Process.put(:app_auth_client, client)

    for {now, expected} <- [
          {DateTime.add(deadline, -1, :second), :ok},
          {deadline, :expired},
          {DateTime.add(deadline, 1, :second), :expired}
        ] do
      result =
        ClientAuth.authenticate(%{"client_id" => "clock-client"}, nil,
          client_store: __MODULE__.Store,
          now: fn -> now end
        )

      case expected do
        :ok -> assert {:ok, %Client{}} = result
        :expired -> assert {:error, %Error{reason_code: :client_app_expired}} = result
      end
    end
  end

  test "app eligibility normalizes subsecond decision instants for public clients" do
    deadline = ~U[2026-10-20 12:00:00Z]

    finite_client = %Client{
      client_id: "subsecond-public-client",
      token_endpoint_auth_method: :none,
      lifetime_version: 1,
      client_expires_at: deadline
    }

    Process.put(:app_auth_client, finite_client)

    assert {:ok, %Client{client_id: "subsecond-public-client"}} =
             ClientAuth.authenticate(%{"client_id" => finite_client.client_id}, nil,
               client_store: __MODULE__.Store,
               now: fn -> ~U[2026-10-20 11:59:59.999999Z] end
             )

    assert {:error, %Error{reason_code: :client_app_expired}} =
             ClientAuth.authenticate(%{"client_id" => finite_client.client_id}, nil,
               client_store: __MODULE__.Store,
               now: fn -> ~U[2026-10-20 12:00:00.999999Z] end
             )

    Process.put(:app_auth_client, %{
      finite_client
      | client_id: "default-clock-public-client",
        client_expires_at:
          DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.truncate(:second)
    })

    assert {:ok, %Client{client_id: "default-clock-public-client"}} =
             ClientAuth.authenticate(%{"client_id" => "default-clock-public-client"}, nil,
               client_store: __MODULE__.Store
             )
  end

  test "disabled apps and malformed lifetime state fail closed with endpoint errors" do
    now = Process.get(:app_auth_now)

    Process.put(:app_auth_client, %Client{
      client_id: "disabled-client",
      token_endpoint_auth_method: :none,
      active: false,
      lifetime_version: 1
    })

    assert {:error, %Error{status: 401, reason_code: :client_app_disabled}} =
             ClientAuth.authenticate(%{"client_id" => "disabled-client"}, nil,
               client_store: __MODULE__.Store,
               now: fn -> now end
             )

    Process.put(:app_auth_client, %Client{
      client_id: "invalid-state-client",
      token_endpoint_auth_method: :none,
      lifetime_version: nil
    })

    assert {:error, %Error{status: 500, error: "server_error"}} =
             ClientAuth.authenticate(%{"client_id" => "invalid-state-client"}, nil,
               client_store: __MODULE__.Store,
               client_lifetime: %ClientLifetime{
                 contract_version: 1,
                 client_store: __MODULE__.Store,
                 transaction_authority: %{identity: :test, participants: %{}}
               },
               now: fn -> now end
             )

    assert {:error, %Error{status: 500, error: "server_error"}} =
             ClientAuth.authenticate(%{"client_id" => "invalid-state-client"}, nil,
               client_store: __MODULE__.Store,
               client_lifetime: %ClientLifetime{
                 contract_version: 1,
                 client_store: __MODULE__.FailingStore,
                 transaction_authority: %{identity: :test, participants: %{}}
               },
               now: fn -> now end
             )

    assert {:error, %Error{status: 500, error: "server_error"}} =
             ClientAuth.authenticate(%{"client_id" => "down"}, nil,
               client_store: __MODULE__.FailingStore,
               now: fn -> now end
             )
  end

  test "a historical v0 secret timestamp remains advisory" do
    now = Process.get(:app_auth_now)
    secret = Process.get(:app_auth_secret)

    Process.put(:app_auth_client, %Client{
      client_id: "legacy-client",
      token_endpoint_auth_method: :client_secret_basic,
      client_secret_hash: Policy.hash_client_secret(secret),
      lifetime_version: 0,
      client_secret_expires_at: DateTime.add(now, -100, :second)
    })

    assert {:ok, %Client{client_id: "legacy-client"}} =
             ClientAuth.authenticate(%{}, basic_header("legacy-client", secret),
               client_store: __MODULE__.Store,
               now: fn -> now end
             )
  end

  test "public methods ignore shared-secret deadlines and enforcement stays deferred here" do
    now = Process.get(:app_auth_now)

    Process.put(:app_auth_client, %Client{
      client_id: "public-client",
      token_endpoint_auth_method: :none,
      lifetime_version: 1,
      client_expires_at: DateTime.add(now, 30, :second),
      client_secret_expires_at: DateTime.add(now, -30, :second)
    })

    assert {:ok, %Client{client_id: "public-client"}} =
             ClientAuth.authenticate(%{"client_id" => "public-client"}, nil,
               client_store: __MODULE__.Store,
               now: fn -> now end
             )

    Process.put(:app_auth_client, %Client{
      client_id: "basic-with-old-secret-date",
      token_endpoint_auth_method: :client_secret_basic,
      client_secret_hash: Policy.hash_client_secret(Process.get(:app_auth_secret)),
      lifetime_version: 1,
      client_expires_at: DateTime.add(now, 30, :second),
      client_secret_expires_at: DateTime.add(now, -30, :second)
    })

    assert {:ok, %Client{client_id: "basic-with-old-secret-date"}} =
             ClientAuth.authenticate(
               %{},
               basic_header("basic-with-old-secret-date", Process.get(:app_auth_secret)),
               client_store: __MODULE__.Store,
               now: fn -> now end
             )
  end

  test "verified identity binds the method-specific credential state without exposing its fingerprint" do
    client = %Client{
      client_id: "identity-client",
      token_endpoint_auth_method: :client_secret_basic,
      client_secret_hash: Policy.hash_client_secret("verified-secret"),
      lifetime_version: 1
    }

    identity = ClientAuthentication.verified_identity(client)

    assert ClientAuthentication.verified_identity_matches?(identity, client)

    refute ClientAuthentication.verified_identity_matches?(identity, %Client{
             client
             | client_secret_hash: Policy.hash_client_secret("rotated-secret")
           })

    refute inspect(identity) =~ Base.encode16(identity.fingerprint)

    public_client = %Client{
      client
      | token_endpoint_auth_method: :none,
        client_secret_hash: nil
    }

    public_identity = ClientAuthentication.verified_identity(public_client)

    assert ClientAuthentication.verified_identity_matches?(public_identity, %Client{
             public_client
             | client_secret_hash: Policy.hash_client_secret("unrelated-secret")
           })

    jwt_client = %Client{
      client_id: "jwt-identity-client",
      token_endpoint_auth_method: :client_secret_jwt,
      client_secret_hash: Policy.hash_client_secret("jwt-secret"),
      client_secret_jwt_verifier_encrypted: "encrypted-verifier-v1",
      lifetime_version: 1
    }

    jwt_identity = ClientAuthentication.verified_identity(jwt_client)

    refute ClientAuthentication.verified_identity_matches?(jwt_identity, %Client{
             jwt_client
             | client_secret_jwt_verifier_encrypted: "encrypted-verifier-v2"
           })

    key_client = %Client{
      client_id: "key-identity-client",
      token_endpoint_auth_method: :private_key_jwt,
      jwks: %{"keys" => [%{"kid" => "key-v1", "kty" => "RSA"}]},
      lifetime_version: 1
    }

    key_identity = ClientAuthentication.verified_identity(key_client)

    refute ClientAuthentication.verified_identity_matches?(key_identity, %Client{
             key_client
             | jwks: %{"keys" => [%{"kid" => "key-v2", "kty" => "RSA"}]}
           })

    mtls_client = %Client{
      client_id: "mtls-identity-client",
      token_endpoint_auth_method: :tls_client_auth,
      tls_client_auth_subject_dn: "CN=old.example.test",
      lifetime_version: 1
    }

    mtls_identity = ClientAuthentication.verified_identity(mtls_client)

    refute ClientAuthentication.verified_identity_matches?(mtls_identity, %Client{
             mtls_client
             | tls_client_auth_subject_dn: "CN=new.example.test"
           })
  end

  test "legacy option adaptation preserves callable request clocks for normal and CIBA grants" do
    now = Process.get(:app_auth_now)
    clock = fn -> now end

    for grant <- [:authorization_code, :ciba] do
      assert {:ok, dependencies} =
               LegacyOptions.from_request(%{opts: [now: clock]}, grant)

      assert dependencies.now == clock
      assert %ClientLifetime{} = dependencies.client_lifetime
    end
  end

  defmodule Store do
    alias Lockspire.Domain.Client

    def fetch_client_by_id(id) do
      case Process.get(:app_auth_client) do
        %Client{client_id: ^id} = client -> {:ok, client}
        _ -> {:ok, nil}
      end
    end
  end

  defmodule FailingStore do
    def fetch_client_by_id(_id), do: {:error, :database_unavailable}
  end

  defmodule ReplayStore do
    def record_used_jti(%Lockspire.Domain.UsedJti{jti: jti}) do
      jtis = Process.get(:app_auth_jtis, MapSet.new())

      if MapSet.member?(jtis, jti) do
        {:ok, :replay}
      else
        Process.put(:app_auth_jtis, MapSet.put(jtis, jti))
        {:ok, :accepted}
      end
    end
  end

  defmodule ServerPolicyStore do
    alias Lockspire.Domain.ServerPolicy

    def get_server_policy, do: {:ok, %ServerPolicy{security_profile: :none}}
  end

  defp basic_header(client_id, secret) do
    "Basic " <> Base.encode64("#{client_id}:#{secret}")
  end

  defp jwt_params(assertion) do
    %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
  end

  defp signed_assertion(private_jwk, client_id, now) do
    JarTestHelpers.sign_jar(
      private_jwk,
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Lockspire.Config.issuer!(),
        "jti" => "#{client_id}-jti",
        "iat" => DateTime.to_unix(now),
        "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
      },
      alg: "RS256"
    )
  end

  defp client_secret_assertion(secret, client_id, now) do
    payload = %{
      "iss" => client_id,
      "sub" => client_id,
      "aud" => Lockspire.Config.issuer!(),
      "jti" => "#{client_id}-jti",
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
    }

    JarTestHelpers.sign_jar(JOSE.JWK.from_oct(secret), payload, alg: "HS256")
  end
end
