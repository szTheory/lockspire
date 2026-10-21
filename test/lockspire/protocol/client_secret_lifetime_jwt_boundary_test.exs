defmodule Lockspire.Protocol.ClientSecretLifetimeJwtBoundaryTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error
  alias Lockspire.Security.Policy
  alias Lockspire.JarTestHelpers

  @secret "phase-164-finite-jwt-secret"
  @deadline ~U[2026-10-20 12:00:00Z]

  test "finite secret JWT authenticates once before expiry and fails at equality after JWT checks" do
    client = %Client{
      client_id: "finite-secret-jwt-client",
      token_endpoint_auth_method: :client_secret_jwt,
      client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(@secret),
      lifetime_version: 1,
      client_expires_at: DateTime.add(@deadline, 60, :second),
      client_secret_expires_at: @deadline
    }

    Process.put(:finite_secret_jwt_boundary_client, client)
    Process.put(:finite_secret_jwt_boundary_jtis, MapSet.new())

    before_expiry = DateTime.add(@deadline, -1, :second)
    assertion = assertion(client.client_id, "accepted-once", before_expiry)

    assert {:ok, %Client{client_id: "finite-secret-jwt-client"}} =
             authenticate(assertion, before_expiry)

    assert {:error, %Error{reason_code: :client_assertion_replayed}} =
             authenticate(assertion, before_expiry)

    at_equality = assertion(client.client_id, "at-expiry", before_expiry)

    assert {:error,
            %Error{
              status: 401,
              error: "invalid_client",
              reason_code: :client_secret_expired
            }} = authenticate(at_equality, @deadline)

    assert Process.get(:finite_secret_jwt_boundary_jtis) ==
             MapSet.new(["accepted-once", "at-expiry"])
  end

  defp authenticate(assertion, now) do
    ClientAuth.authenticate(jwt_params(assertion), nil,
      client_store: __MODULE__.ClientStore,
      jti_store: __MODULE__.ReplayStore,
      server_policy_store: __MODULE__.ServerPolicyStore,
      supported_jwt_auth_methods: [:client_secret_jwt],
      now: fn -> now end
    )
  end

  defp assertion(client_id, jti, issued_at) do
    JarTestHelpers.sign_jar(
      JOSE.JWK.from_oct(@secret),
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Lockspire.Config.issuer!(),
        "jti" => jti,
        "iat" => DateTime.to_unix(issued_at),
        "exp" => DateTime.add(issued_at, 300, :second) |> DateTime.to_unix()
      },
      alg: "HS256"
    )
  end

  defp jwt_params(assertion),
    do: %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }

  defmodule ClientStore do
    def fetch_client_by_id(client_id) do
      case Process.get(:finite_secret_jwt_boundary_client) do
        %Client{client_id: ^client_id} = client -> {:ok, client}
        _ -> {:ok, nil}
      end
    end
  end

  defmodule ReplayStore do
    def record_used_jti(%UsedJti{jti: jti}) do
      used = Process.get(:finite_secret_jwt_boundary_jtis, MapSet.new())

      if MapSet.member?(used, jti) do
        {:ok, :replay}
      else
        Process.put(:finite_secret_jwt_boundary_jtis, MapSet.put(used, jti))
        {:ok, :accepted}
      end
    end
  end

  defmodule ServerPolicyStore do
    def get_server_policy, do: {:ok, %ServerPolicy{security_profile: :none}}
  end
end
