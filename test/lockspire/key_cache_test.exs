defmodule Lockspire.KeyCacheTest do
  use ExUnit.Case, async: false

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

  describe "initialization and refresh" do
    test "fetches active keys and stores them in ETS", %{pid: pid} do
      # Insert an active key
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      kid = "test-kid-1"
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

      # Trigger refresh
      send(pid, :refresh)

      # Wait a bit for the message to be processed
      :sys.get_state(pid)

      # Check if it's in ETS
      assert {:ok, retrieved_jwk} = KeyCache.get_key(kid)
      assert %JOSE.JWK{} = retrieved_jwk
    end

    test "removes keys that are no longer active", %{pid: pid} do
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      kid = "test-kid-2"
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

      {:ok, published_key} = Repository.publish_key(key)

      send(pid, :refresh)
      :sys.get_state(pid)

      assert {:ok, _} = KeyCache.get_key(kid)

      # Retire the key
      {:ok, _} = Repository.publish_key(%{published_key | status: :retired})

      send(pid, :refresh)
      :sys.get_state(pid)

      assert {:error, :not_found} = KeyCache.get_key(kid)
    end
  end

  describe "get_key/1" do
    test "returns error when key not found" do
      assert {:error, :not_found} = KeyCache.get_key("non-existent-kid")
    end
  end

  describe "repository readiness" do
    test "the default repository readiness check enables a cold lookup before its retry timer" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      repo_name = unique_server_name()
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      parent = self()
      key = signing_key("default-ready-key")

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          repo: repo_name,
          refresh_interval: 0,
          initial_retry_interval: 5_000,
          loader: fn ->
            count = Agent.get_and_update(calls, &{&1 + 1, &1 + 1})
            send(parent, {:default_loader_called, count})
            {:ok, [key]}
          end
        )

      refute_receive {:default_loader_called, _}, 30
      {:ok, repo_pid} = Agent.start_link(fn -> :ready end, name: repo_name)

      assert {:ok, %JOSE.JWK{}} = KeyCache.get_key(key.kid, table_name)
      assert_receive {:default_loader_called, 1}, 200
      assert Agent.get(calls, & &1) == 1

      GenServer.stop(pid)
      Agent.stop(repo_pid)
      Agent.stop(calls)
    end

    test "a ready cold lookup loads one full snapshot even while an unready retry is pending" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      {:ok, readiness} = Agent.start_link(fn -> false end)
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      parent = self()
      key = signing_key("cold-ready-key")

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          initial_retry_interval: 5_000,
          ready?: fn -> Agent.get(readiness, & &1) end,
          loader: fn ->
            count = Agent.get_and_update(calls, &{&1 + 1, &1 + 1})
            send(parent, {:loader_called, count})
            {:ok, [key]}
          end
        )

      refute_receive {:loader_called, _}, 30
      Agent.update(readiness, fn _ -> true end)

      results =
        1..12
        |> Task.async_stream(fn _ -> KeyCache.get_key(key.kid, table_name) end,
          max_concurrency: 12,
          timeout: 2_000
        )
        |> Enum.to_list()

      assert Enum.all?(results, &match?({:ok, {:ok, %JOSE.JWK{}}}, &1))
      assert_receive {:loader_called, 1}, 200
      assert Agent.get(calls, & &1) == 1

      GenServer.stop(pid)
      Agent.stop(readiness)
      Agent.stop(calls)
    end

    test "a failed cold snapshot is throttled until an independent retry succeeds" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      {:ok, readiness} = Agent.start_link(fn -> false end)
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      parent = self()
      key = signing_key("retry-cold-key")

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          initial_retry_interval: 800,
          ready?: fn -> Agent.get(readiness, & &1) end,
          loader: fn ->
            count = Agent.get_and_update(calls, &{&1 + 1, &1 + 1})
            send(parent, {:loader_called, count})
            if count == 1, do: {:error, :unavailable}, else: {:ok, [key]}
          end,
          failure_reporter: fn reason -> send(parent, {:refresh_failure, reason}) end
        )

      refute_receive {:loader_called, _}, 30
      Agent.update(readiness, fn _ -> true end)

      results =
        1..12
        |> Task.async_stream(fn _ -> KeyCache.get_key(key.kid, table_name) end,
          max_concurrency: 12,
          timeout: 2_000
        )
        |> Enum.to_list()

      assert Enum.all?(results, &match?({:ok, {:error, :not_found}}, &1))
      assert_receive {:loader_called, 1}, 200
      assert_receive {:refresh_failure, :key_storage_unavailable}, 200
      refute_receive {:loader_called, 2}, 100
      assert Agent.get(calls, & &1) == 1
      assert {:error, :not_found} = KeyCache.get_key("another-unknown-kid", table_name)
      assert Agent.get(calls, & &1) == 1

      assert_receive {:loader_called, 2}, 2_000

      assert_eventually(fn ->
        match?({:ok, %JOSE.JWK{}}, KeyCache.get_key(key.kid, table_name))
      end)

      GenServer.stop(pid)
      Agent.stop(readiness)
      Agent.stop(calls)
    end

    test "an explicit refresh can satisfy a pending retry and cancels the stale retry" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      {:ok, readiness} = Agent.start_link(fn -> false end)
      parent = self()
      key = signing_key("manual-refresh-key")

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          initial_retry_interval: 250,
          ready?: fn -> Agent.get(readiness, & &1) end,
          loader: fn ->
            send(parent, :manual_refresh_loaded)
            {:ok, [key]}
          end
        )

      refute_receive :manual_refresh_loaded, 30
      Agent.update(readiness, fn _ -> true end)
      send(pid, :refresh)
      assert_receive :manual_refresh_loaded, 200
      assert {:ok, %JOSE.JWK{}} = KeyCache.get_key(key.kid, table_name)
      refute_receive :manual_refresh_loaded, 300

      GenServer.stop(pid)
      Agent.stop(readiness)
    end

    test "a successful empty snapshot is warm and unknown kid lookups do not reload" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      parent = self()

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          loader: fn ->
            Agent.update(calls, &(&1 + 1))
            send(parent, :empty_snapshot_loaded)
            {:ok, []}
          end
        )

      assert_receive :empty_snapshot_loaded, 200

      results =
        1..12
        |> Task.async_stream(fn _ -> KeyCache.get_key("not-in-empty-snapshot", table_name) end,
          max_concurrency: 12,
          timeout: 2_000
        )
        |> Enum.to_list()

      assert Enum.all?(results, &match?({:ok, {:error, :not_found}}, &1))
      refute_receive :empty_snapshot_loaded, 30
      assert Agent.get(calls, & &1) == 1

      GenServer.stop(pid)
      Agent.stop(calls)
    end

    test "initial_refresh false does not demand-load on a cold lookup" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      parent = self()

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          initial_refresh?: false,
          ready?: fn -> true end,
          loader: fn ->
            send(parent, :unexpected_demand_load)
            {:ok, []}
          end
        )

      assert {:error, :not_found} = KeyCache.get_key("cold-disabled", table_name)
      refute_receive :unexpected_demand_load, 30

      GenServer.stop(pid)
    end

    test "defers the initial refresh until the repository is ready" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      {:ok, readiness} = Agent.start_link(fn -> false end)
      parent = self()

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          initial_retry_interval: 10,
          ready?: fn -> Agent.get(readiness, & &1) end,
          loader: fn ->
            send(parent, :loaded_after_repository_ready)
            {:ok, []}
          end
        )

      refute_receive :loaded_after_repository_ready, 30
      Agent.update(readiness, fn _ -> true end)
      assert_receive :loaded_after_repository_ready, 200

      GenServer.stop(pid)
      Agent.stop(readiness)
    end

    test "logs a sanitized failure and retains cached keys once the repository was ready" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      public_jwk = jose_jwk |> JOSE.JWK.to_public() |> JOSE.JWK.to_map() |> elem(1)
      key = %SigningKey{kid: "cached-key", public_jwk: public_jwk}
      {:ok, result} = Agent.start_link(fn -> {:ok, [key]} end)
      parent = self()

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          ready?: fn -> true end,
          loader: fn -> Agent.get(result, & &1) end,
          failure_reporter: fn reason -> send(parent, {:refresh_failure, reason}) end
        )

      assert_eventually(fn ->
        match?({:ok, %JOSE.JWK{}}, KeyCache.get_key("cached-key", table_name))
      end)

      Agent.update(result, fn _ -> {:error, {:database_unavailable, "secret-value"}} end)

      send(pid, :refresh)
      assert_receive {:refresh_failure, :key_storage_unavailable}
      assert {:ok, %JOSE.JWK{}} = KeyCache.get_key("cached-key", table_name)

      GenServer.stop(pid)
      Agent.stop(result)
    end

    test "a warm refresh failure retains its snapshot and does not reload on unknown kids" do
      table_name = unique_table_name()
      server_name = unique_server_name()
      jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      public_jwk = jose_jwk |> JOSE.JWK.to_public() |> JOSE.JWK.to_map() |> elem(1)
      key = %SigningKey{kid: "warm-retained-key", public_jwk: public_jwk}
      {:ok, result} = Agent.start_link(fn -> {:ok, [key]} end)
      {:ok, calls} = Agent.start_link(fn -> 0 end)
      parent = self()

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          ready?: fn -> true end,
          loader: fn ->
            Agent.update(calls, &(&1 + 1))
            Agent.get(result, & &1)
          end,
          failure_reporter: fn reason -> send(parent, {:warm_refresh_failure, reason}) end
        )

      assert_eventually(fn ->
        match?({:ok, %JOSE.JWK{}}, KeyCache.get_key(key.kid, table_name))
      end)

      Agent.update(result, fn _ -> {:error, {:database_unavailable, "private"}} end)

      send(pid, :refresh)
      assert_receive {:warm_refresh_failure, :key_storage_unavailable}
      assert {:ok, %JOSE.JWK{}} = KeyCache.get_key(key.kid, table_name)
      assert {:error, :not_found} = KeyCache.get_key("warm-unknown-kid", table_name)
      refute_receive {:warm_refresh_failure, _}, 100
      assert Agent.get(calls, & &1) == 2

      GenServer.stop(pid)
      Agent.stop(result)
      Agent.stop(calls)
    end
  end

  defp assert_eventually(fun, attempts \\ 20)

  defp assert_eventually(_fun, 0), do: flunk("expected condition was never met")

  defp assert_eventually(fun, attempts) do
    if fun.() do
      :ok
    else
      Process.sleep(10)
      assert_eventually(fun, attempts - 1)
    end
  end

  defp unique_table_name,
    do: String.to_atom("lockspire_key_cache_test_#{System.unique_integer([:positive])}")

  defp signing_key(kid) do
    jose_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    public_jwk = jose_jwk |> JOSE.JWK.to_public() |> JOSE.JWK.to_map() |> elem(1)

    %SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: public_jwk,
      status: :active,
      inserted_at: DateTime.utc_now()
    }
  end

  defp unique_server_name,
    do: String.to_atom("lockspire_key_cache_server_#{System.unique_integer([:positive])}")
end
