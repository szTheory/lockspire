defmodule Lockspire.ClientsSecretMaterialTest do
  use ExUnit.Case, async: false

  alias Lockspire.Clients
  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  setup do
    endpoint_config = Application.get_env(:lockspire, Lockspire.Web.Endpoint)
    verifier_config = Application.fetch_env(:lockspire, ClientSecretVerifier)
    key_encryption_config = Application.fetch_env(:lockspire, :key_encryption)
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

      case verifier_config do
        {:ok, value} -> Application.put_env(:lockspire, ClientSecretVerifier, value)
        :error -> Application.delete_env(:lockspire, ClientSecretVerifier)
      end

      case key_encryption_config do
        {:ok, value} -> Application.put_env(:lockspire, :key_encryption, value)
        :error -> Application.delete_env(:lockspire, :key_encryption)
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

  test "cold secret generation resolves verifier configuration without caching it" do
    cache_key = Config.client_secret_verifier_cache_key()
    :persistent_term.erase(cache_key)

    legacy_secret = "cold-generation-legacy-endpoint-secret-key-base"
    Application.put_env(:lockspire, Lockspire.Web.Endpoint, secret_key_base: legacy_secret)
    Application.delete_env(:lockspire, ClientSecretVerifier)

    legacy = Clients.rotate_secret_material(client_id: "cold-legacy-client")

    assert {:ok, opened_legacy} =
             Policy.unseal_client_secret_jwt_verifier(
               legacy.client_secret_jwt_verifier_encrypted,
               secret_key_base: legacy_secret
             )

    assert opened_legacy == legacy.client_secret
    assert Policy.verify_client_secret(legacy.client_secret_hash, legacy.client_secret)
    assert :persistent_term.get(cache_key, :missing) == :missing

    verifier_key = :crypto.strong_rand_bytes(32)
    verifier_config = dedicated_verifier_config(verifier_key)
    Application.put_env(:lockspire, ClientSecretVerifier, verifier_config)

    dedicated = Clients.rotate_secret_material(client_id: "cold-dedicated-client")

    assert String.starts_with?(dedicated.client_secret_jwt_verifier_encrypted, "LSCV1.")

    assert {:ok, context} =
             Context.resolve(
               {:present, verifier_config},
               Config.client_secret_verifier_operation_forbidden_key_bytes(nil)
             )

    assert {:ok, opened_dedicated} =
             Lockspire.Security.ClientSecretVerifier.open(
               context,
               "cold-dedicated-client",
               dedicated.client_secret_jwt_verifier_encrypted,
               []
             )

    assert opened_dedicated == dedicated.client_secret
    assert Policy.verify_client_secret(dedicated.client_secret_hash, dedicated.client_secret)

    assert {:error, _reason} =
             Lockspire.Security.ClientSecretVerifier.open(
               context,
               "another-cold-dedicated-client",
               dedicated.client_secret_jwt_verifier_encrypted,
               []
             )

    assert :persistent_term.get(cache_key, :missing) == :missing
  end

  test "cold verifier configuration overlap fails closed and leaves startup cache empty" do
    cache_key = Config.client_secret_verifier_cache_key()
    :persistent_term.erase(cache_key)

    overlapping_key = :crypto.strong_rand_bytes(32)
    Application.put_env(:lockspire, Lockspire.Web.Endpoint, secret_key_base: overlapping_key)

    Application.put_env(
      :lockspire,
      ClientSecretVerifier,
      dedicated_verifier_config(overlapping_key)
    )

    error =
      assert_raise ArgumentError, fn ->
        Clients.rotate_secret_material(client_id: "cold-overlap-client")
      end

    assert Exception.message(error) ==
             "client secret material generation failed: client_secret_verifier_configuration_invalid"

    assert :persistent_term.get(cache_key, :missing) == :missing
  end

  test "cold verifier configuration rejects reuse of a signing key" do
    cache_key = Config.client_secret_verifier_cache_key()
    :persistent_term.erase(cache_key)

    signing_key = :crypto.strong_rand_bytes(32)

    Application.put_env(:lockspire, :key_encryption,
      keys: [{"signing-key", Base.encode64(signing_key)}],
      current: "signing-key"
    )

    Application.put_env(
      :lockspire,
      ClientSecretVerifier,
      dedicated_verifier_config(signing_key)
    )

    error =
      assert_raise ArgumentError, fn ->
        Clients.rotate_secret_material(client_id: "cold-signing-key-overlap-client")
      end

    assert Exception.message(error) ==
             "client secret material generation failed: client_secret_verifier_configuration_invalid"

    assert :persistent_term.get(cache_key, :missing) == :missing
  end

  test "cold invalid signing configuration fails closed without writing the verifier cache" do
    cache_key = Config.client_secret_verifier_cache_key()
    :persistent_term.erase(cache_key)

    Application.put_env(:lockspire, :key_encryption,
      keys: [{"broken", "not-base64"}],
      current: "broken"
    )

    Application.put_env(
      :lockspire,
      ClientSecretVerifier,
      dedicated_verifier_config(:crypto.strong_rand_bytes(32))
    )

    error =
      assert_raise ArgumentError, fn ->
        Clients.rotate_secret_material(client_id: "cold-invalid-signing-config-client")
      end

    assert Exception.message(error) ==
             "client secret material generation failed: client_secret_verifier_configuration_invalid"

    assert :persistent_term.get(cache_key, :missing) == :missing
  end

  test "invalid startup snapshot remains authoritative for secret generation" do
    cache_key = Config.client_secret_verifier_cache_key()
    invalid = %Context{state: :invalid, reason: :invalid_options}
    :persistent_term.put(cache_key, invalid)

    Application.put_env(
      :lockspire,
      ClientSecretVerifier,
      dedicated_verifier_config(:crypto.strong_rand_bytes(32))
    )

    error =
      assert_raise ArgumentError, fn ->
        Clients.rotate_secret_material(client_id: "invalid-snapshot-client")
      end

    assert Exception.message(error) ==
             "client secret material generation failed: client_secret_verifier_configuration_invalid"

    assert :persistent_term.get(cache_key) == invalid
  end

  test "corrupt non-context cache entries never trigger cold configuration resolution" do
    cache_key = Config.client_secret_verifier_cache_key()

    Application.put_env(
      :lockspire,
      ClientSecretVerifier,
      dedicated_verifier_config(:crypto.strong_rand_bytes(32))
    )

    for corrupt <- [:uninitialized, :unexpected] do
      :persistent_term.put(cache_key, corrupt)

      error =
        assert_raise ArgumentError, fn ->
          Clients.rotate_secret_material(client_id: "corrupt-cache-client")
        end

      assert Exception.message(error) ==
               "client secret material generation failed: client_secret_verifier_configuration_invalid"

      assert :persistent_term.get(cache_key) == corrupt
    end
  end

  test "valid startup snapshot remains authoritative for secret generation" do
    startup_key = :crypto.strong_rand_bytes(32)
    startup_config = dedicated_verifier_config(startup_key)
    Application.put_env(:lockspire, ClientSecretVerifier, startup_config)

    assert {:ok, startup_context} = Lockspire.Application.resolve_client_secret_verifier()

    Application.put_env(
      :lockspire,
      ClientSecretVerifier,
      dedicated_verifier_config(:crypto.strong_rand_bytes(32))
    )

    client_id = "startup-snapshot-client"
    material = Clients.rotate_secret_material(client_id: client_id)

    assert {:ok, opened} =
             Lockspire.Security.ClientSecretVerifier.open(
               startup_context,
               client_id,
               material.client_secret_jwt_verifier_encrypted,
               []
             )

    assert opened == material.client_secret
    assert Config.client_secret_verifier_context() == startup_context
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

  test "byte-distinct UTF-8 identities stay distinct without normalization" do
    context = dedicated_context(:crypto.strong_rand_bytes(32))
    composed = "café-client"
    decomposed = "cafe\u0301-client"

    assert composed != decomposed

    first =
      Clients.rotate_secret_material(client_id: composed, client_secret_verifier_context: context)

    second =
      Clients.rotate_secret_material(
        client_id: decomposed,
        client_secret_verifier_context: context
      )

    opened_for_composed =
      Lockspire.Security.ClientSecretVerifier.open(
        context,
        composed,
        first.client_secret_jwt_verifier_encrypted,
        []
      )

    opened_for_decomposed =
      Lockspire.Security.ClientSecretVerifier.open(
        context,
        decomposed,
        second.client_secret_jwt_verifier_encrypted,
        []
      )

    opened_crosswise =
      Lockspire.Security.ClientSecretVerifier.open(
        context,
        decomposed,
        first.client_secret_jwt_verifier_encrypted,
        []
      )

    assert match?({:ok, _secret}, opened_for_composed)
    assert match?({:ok, _secret}, opened_for_decomposed)
    refute match?({:ok, _secret}, opened_crosswise)
  end

  test "dedicated public-helper failures are clear, fixed, and redact supplied options" do
    context = dedicated_context(:crypto.strong_rand_bytes(32))

    for client_id <- [nil, ""] do
      opts =
        [client_secret_verifier_context: context]
        |> then(fn opts ->
          if is_nil(client_id), do: opts, else: Keyword.put(opts, :client_id, client_id)
        end)

      error =
        assert_raise ArgumentError, fn ->
          Clients.rotate_secret_material(opts)
        end

      assert Exception.message(error) ==
               "client secret material generation failed: client_secret_verifier_identity_missing"

      refute Exception.message(error) =~ inspect(context)
    end

    invalid_context = %Context{state: :invalid, reason: :invalid_options}

    error =
      assert_raise ArgumentError, fn ->
        Clients.rotate_secret_material(
          client_id: "invalid-context-client",
          client_secret_verifier_context: invalid_context
        )
      end

    assert Exception.message(error) ==
             "client secret material generation failed: client_secret_verifier_configuration_invalid"
  end

  test "legacy helper keeps its missing endpoint secret error clear" do
    :persistent_term.put(Config.client_secret_verifier_cache_key(), %Context{state: :absent})
    Application.delete_env(:lockspire, Lockspire.Web.Endpoint)

    error = assert_raise ArgumentError, fn -> Clients.rotate_secret_material() end

    assert Exception.message(error) ==
             "missing Lockspire endpoint secret_key_base required for client_secret_jwt verifier material"
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

  defp dedicated_verifier_config(key) do
    [
      keys: [{"cold-key", Base.url_encode64(key, padding: false)}],
      current: "cold-key",
      write_mode: :dedicated,
      legacy_read: :allow
    ]
  end
end
