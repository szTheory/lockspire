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
