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
end
