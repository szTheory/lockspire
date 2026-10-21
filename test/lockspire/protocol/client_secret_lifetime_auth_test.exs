defmodule Lockspire.Protocol.ClientSecretLifetimeAuthTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error
  alias Lockspire.Security.Policy

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
        0 -> :counters.add(calls, 1, 1); DateTime.add(@now, -1, :second)
        _ -> :counters.add(calls, 1, 1); @now
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

      assert {:error, %Error{status: 401, error: "invalid_client", reason_code: :client_secret_expired}} =
               ClientAuth.authenticate(params, authorization,
                 client_store: __MODULE__.Store,
                 now: fn -> @now end
               )
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

  defp basic_header(client_id, secret),
    do: "Basic " <> Base.encode64("#{client_id}:#{secret}")
end
