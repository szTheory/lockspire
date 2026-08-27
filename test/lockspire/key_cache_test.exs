defmodule Lockspire.KeyCacheTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

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

      {:ok, pid} =
        KeyCache.start_link(
          name: server_name,
          table_name: table_name,
          refresh_interval: 0,
          ready?: fn -> true end,
          loader: fn -> Agent.get(result, & &1) end
        )

      assert_eventually(fn -> KeyCache.get_key("cached-key", table_name) end, {:ok, %JOSE.JWK{}})
      Agent.update(result, fn _ -> {:error, {:database_unavailable, "secret-value"}} end)

      log =
        capture_log(fn ->
          send(pid, :refresh)
          :sys.get_state(pid)
        end)

      assert log =~ "Failed to refresh KeyCache: key storage unavailable"
      refute log =~ "secret-value"
      assert {:ok, %JOSE.JWK{}} = KeyCache.get_key("cached-key", table_name)

      GenServer.stop(pid)
      Agent.stop(result)
    end
  end

  defp assert_eventually(fun, expected, attempts \\ 20)

  defp assert_eventually(_fun, _expected, 0), do: flunk("expected condition was never met")

  defp assert_eventually(fun, expected, attempts) do
    case fun.() do
      ^expected -> :ok
      _other ->
        Process.sleep(10)
        assert_eventually(fun, expected, attempts - 1)
    end
  end

  defp unique_table_name, do: String.to_atom("lockspire_key_cache_test_#{System.unique_integer([:positive])}")
  defp unique_server_name, do: String.to_atom("lockspire_key_cache_server_#{System.unique_integer([:positive])}")
end
