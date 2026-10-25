defmodule Lockspire.ClientsSecretMaterialTest do
  use ExUnit.Case, async: false

  alias Lockspire.Clients
  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  setup do
    endpoint_config = Application.get_env(:lockspire, Lockspire.Web.Endpoint)
    cache_key = Config.client_secret_verifier_cache_key()
    cached_context = :persistent_term.get(cache_key, :missing)

    on_exit(fn ->
      if is_nil(endpoint_config) do
        Application.delete_env(:lockspire, Lockspire.Web.Endpoint)
      else
        Application.put_env(:lockspire, Lockspire.Web.Endpoint, endpoint_config)
      end

      if cached_context == :missing do
        :persistent_term.erase(cache_key)
      else
        :persistent_term.put(cache_key, cached_context)
      end
    end)

    :ok
  end

  test "hash-only generation is independent of verifier state and endpoint secrets" do
    cache_key = Config.client_secret_verifier_cache_key()
    :persistent_term.put(cache_key, %Context{state: :invalid, reason: :invalid_options})
    Application.delete_env(:lockspire, Lockspire.Web.Endpoint)

    assert {hash, plaintext} = Clients.rotate_secret_hash()
    assert is_binary(hash) and is_binary(plaintext)
    assert byte_size(plaintext) == 43
    assert Policy.verify_client_secret(hash, plaintext)
  end

  test "material helper preserves its three-key success map and legacy opening" do
    material = Clients.rotate_secret_material()

    assert Map.keys(material) |> Enum.sort() ==
             [:client_secret, :client_secret_hash, :client_secret_jwt_verifier_encrypted]

    assert byte_size(material.client_secret) == 43
    assert Policy.verify_client_secret(material.client_secret_hash, material.client_secret)

    assert {:ok, opened} =
             Policy.unseal_client_secret_jwt_verifier(
               material.client_secret_jwt_verifier_encrypted
             )

    assert opened == material.client_secret
  end

  test "dedicated material binds an explicit identity and each generation is fresh" do
    key = :crypto.strong_rand_bytes(32)
    context = dedicated_context(key)
    client_id = "custom-é-id"
    opts = [client_id: client_id, client_secret_verifier_context: context]

    first = Clients.rotate_secret_material(opts)
    second = Clients.rotate_secret_material(opts)

    assert Map.keys(first) |> Enum.sort() ==
             [:client_secret, :client_secret_hash, :client_secret_jwt_verifier_encrypted]

    assert first.client_secret != second.client_secret
    assert first.client_secret_hash != second.client_secret_hash

    assert first.client_secret_jwt_verifier_encrypted !=
             second.client_secret_jwt_verifier_encrypted

    first_secret = first.client_secret

    opened =
      Lockspire.Security.ClientSecretVerifier.open(
        Config.client_secret_verifier_context(client_secret_verifier_context: context),
        client_id,
        first.client_secret_jwt_verifier_encrypted,
        []
      )

    assert match?({:ok, _secret}, opened)
    assert opened |> elem(1) |> then(&(&1 == first_secret))
  end

  test "dedicated public-helper failures are clear, fixed, and redact supplied options" do
    context = dedicated_context(:crypto.strong_rand_bytes(32))

    error =
      assert_raise ArgumentError, fn ->
        Clients.rotate_secret_material(client_secret_verifier_context: context)
      end

    assert Exception.message(error) ==
             "client secret material generation failed: client_secret_verifier_identity_missing"

    refute Exception.message(error) =~ inspect(context)
  end

  defp dedicated_context(key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"test-key", Base.url_encode64(key, padding: false)}],
           current: "test-key",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    context
  end
end
