defmodule Lockspire.ConfigClientSecretVerifierTest do
  use ExUnit.Case, async: false

  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context

  setup do
    key = Config.client_secret_verifier_cache_key()
    previous_cache = :persistent_term.get(key, :missing)
    previous_setting = Application.fetch_env(:lockspire, Context)

    on_exit(fn ->
      case previous_cache do
        :missing -> :persistent_term.erase(key)
        value -> :persistent_term.put(key, value)
      end

      case previous_setting do
        {:ok, value} -> Application.put_env(:lockspire, Context, value)
        :error -> Application.delete_env(:lockspire, Context)
      end
    end)

    :ok
  end

  defp encoded(seed), do: :crypto.hash(:sha256, seed) |> Base.encode64()

  defp config(key, opts \\ []) do
    Keyword.merge(
      [
        keys: [{"primary", encoded(key)}],
        current: "primary",
        write_mode: :dedicated,
        legacy_read: :allow
      ],
      opts
    )
  end

  defp resolve(config) do
    Application.put_env(:lockspire, Context, config)
    Lockspire.Application.resolve_client_secret_verifier()
  end

  test "startup retains absent, valid, and invalid-present settings as distinct states" do
    Application.put_env(:lockspire, :non_keyword_host_option, [:keep, :opaque])
    on_exit(fn -> Application.delete_env(:lockspire, :non_keyword_host_option) end)

    Application.delete_env(:lockspire, Context)

    assert {:ok, %Context{state: :absent}} =
             Lockspire.Application.resolve_client_secret_verifier()

    assert {:ok, %Context{state: :valid}} = resolve(config("valid"))

    assert {:ok, %Context{state: :invalid, reason: reason}} = resolve(nil)
    assert reason == :invalid_options
    assert Config.client_secret_verifier_context().state == :invalid

    assert %Context{state: :valid} =
             Config.client_secret_verifier_context(
               client_secret_verifier_context: {:present, config("explicit-recovery")}
             )
  end

  test "application environment edits and concurrent reads cannot hot reload the snapshot" do
    assert {:ok, %Context{state: :valid} = snapshot} = resolve(config("first"))
    Application.put_env(:lockspire, Context, config("second", write_mode: :legacy))

    reads = for _ <- 1..32, do: Task.async(fn -> Config.client_secret_verifier_context() end)
    assert Enum.all?(Task.await_many(reads), &(&1 == snapshot))
    assert Config.client_secret_verifier_context().keys == snapshot.keys
    assert Config.client_secret_verifier_context().write_mode == :dedicated
  end

  test "a cache miss fails diagnostically without resolving mutable application env" do
    :persistent_term.erase(Config.client_secret_verifier_cache_key())
    Application.put_env(:lockspire, Context, config("ambient"))

    assert %Context{state: :invalid, reason: :client_secret_verifier_configuration_invalid} =
             Config.client_secret_verifier_context()
  end

  test "complete overrides are validated and never merged with ambient configuration" do
    assert {:ok, %Context{state: :valid}} = resolve(config("ambient"))
    {:ok, override} = Context.resolve({:present, config("override")}, [])

    assert %Context{state: :valid, keys: override_keys} =
             Config.client_secret_verifier_context(client_secret_verifier_context: override)

    assert override_keys == override.keys

    partial = [
      keys: [{"primary", encoded("override")}],
      current: nil,
      write_mode: :dedicated
    ]

    assert %Context{state: :invalid} =
             Config.client_secret_verifier_context(
               client_secret_verifier_context: {:present, partial}
             )
  end

  test "staged keys including a current ID retain legacy writes" do
    assert {:ok, %Context{state: :valid, write_mode: :legacy, current_id: "primary"}} =
             resolve(config("staged", write_mode: :legacy))

    assert {:ok, %Context{state: :valid, current_id: nil}} =
             Context.resolve(
               {:present, config("read-only", current: nil, write_mode: :legacy)},
               []
             )

    assert {:ok, %Context{state: :valid, current_id: nil}} =
             Context.resolve(
               {:present,
                Keyword.delete(config("read-only-omitted", write_mode: :legacy), :current)},
               []
             )
  end

  test "exact grammar rejects duplicates, unknown options, invalid current, and contradictory modes" do
    key = encoded("a")

    duplicate = [
      keys: [{"primary", key}],
      current: "primary",
      write_mode: :dedicated,
      legacy_read: :allow,
      write_mode: :legacy
    ]

    invalid = [
      duplicate,
      config("unknown", unexpected: true),
      config("unknown-current", current: "absent"),
      config("missing-current", current: nil),
      config("bad-write-mode", write_mode: :enable),
      config("bad-read-mode", legacy_read: :strict),
      config("contradiction", write_mode: :legacy, legacy_read: :reject),
      config("bad-id", keys: [{"bad id", key}]),
      config("bad-encoding", keys: [{"primary", "not base64"}]),
      config("bad-length", keys: [{"primary", Base.encode64(:crypto.strong_rand_bytes(31))}]),
      config("duplicate-id", keys: [{"primary", key}, {"primary", encoded("b")}]),
      config("duplicate-bytes", keys: [{"primary", key}, {"secondary", key}])
    ]

    for candidate <- invalid do
      assert {:ok, %Context{state: :invalid}} = Context.resolve({:present, candidate}, [])
    end

    decoded_duplicate =
      <<251, 255, 190>> <> binary_part(:crypto.hash(:sha256, "decoded duplicate"), 0, 29)

    assert {:ok, %Context{state: :invalid, reason: :invalid_key}} =
             Context.resolve(
               {:present,
                config("duplicate-decoded",
                  keys: [
                    {"primary", Base.encode64(decoded_duplicate)},
                    {"secondary", Base.url_encode64(decoded_duplicate, padding: false)}
                  ]
                )},
               []
             )
  end

  test "the four frozen standard and URL-safe base64 variants remain accepted" do
    key = <<251, 255, 190>> <> binary_part(:crypto.hash(:sha256, "encoding variants"), 0, 29)

    encodings = [
      Base.encode64(key),
      Base.encode64(key, padding: false),
      Base.url_encode64(key),
      Base.url_encode64(key, padding: false)
    ]

    for encoded_key <- encodings do
      assert {:ok, %Context{state: :valid, keys: %{"primary" => ^key}}} =
               Context.resolve(
                 {:present,
                  [keys: [{"primary", encoded_key}], write_mode: :legacy, legacy_read: :allow]},
                 []
               )
    end
  end

  test "configured endpoint and signing key bytes cannot be reused" do
    signing_bytes = Config.key_encryption_keyset().keys |> Map.values() |> hd()

    assert {:ok, %Context{state: :invalid, reason: :invalid_key}} =
             Context.resolve(
               {:present, config("reused", keys: [{"primary", Base.encode64(signing_bytes)}])},
               [signing_bytes]
             )

    endpoint_secret = Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]

    assert {:ok, %Context{state: :invalid}} =
             Context.resolve(
               {:present,
                config("endpoint", keys: [{"primary", Base.encode64(endpoint_secret)}])},
               [endpoint_secret]
             )

    assert {:ok, %Context{state: :valid}} = resolve(config("override-base"))

    override =
      config("reused-override", keys: [{"primary", Base.encode64(signing_bytes)}])

    assert %Context{state: :invalid, reason: :invalid_key} =
             Config.client_secret_verifier_context(
               client_secret_verifier_context: {:present, override}
             )
  end

  test "invalid contexts and inspection expose only allowlisted state and reason atoms" do
    sentinel = "VERIFIER-CONFIG-SENTINEL"
    {:ok, %Context{} = invalid} = Context.resolve({:present, keys: [{sentinel, sentinel}]}, [])

    assert inspect(invalid) =~ "state: :invalid"
    assert inspect(invalid) =~ "reason: :invalid_options"
    refute inspect(invalid) =~ sentinel

    forged = %Context{invalid | reason: sentinel}
    assert inspect(forged) =~ "reason: :client_secret_verifier_configuration_invalid"
    refute inspect(forged) =~ sentinel
  end

  test "override comparison uses the startup-known purpose key set" do
    endpoint_config = Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)

    on_exit(fn ->
      Application.put_env(:lockspire, Lockspire.Web.Endpoint, endpoint_config)
    end)

    assert {:ok, %Context{state: :valid}} = resolve(config("startup-key"))
    post_startup_endpoint_key = :crypto.strong_rand_bytes(32)

    Application.put_env(
      :lockspire,
      Lockspire.Web.Endpoint,
      Keyword.put(endpoint_config, :secret_key_base, post_startup_endpoint_key)
    )

    override =
      config("override-key", keys: [{"primary", Base.encode64(post_startup_endpoint_key)}])

    assert %Context{state: :valid, keys: %{"primary" => ^post_startup_endpoint_key}} =
             Config.client_secret_verifier_context(
               client_secret_verifier_context: {:present, override}
             )
  end

  test "dedicated envelope key lookup distinguishes missing and unknown configured IDs" do
    {:ok, %Context{} = context} = Context.resolve({:present, config("reader")}, [])
    missing_current = %Context{context | current_id: nil, write_mode: :legacy}

    assert ClientSecretVerifier.seal(missing_current, "client", "secret") ==
             {:error, :client_secret_verifier_key_missing}

    assert {:error, :client_secret_verifier_key_unknown} =
             ClientSecretVerifier.open(context, "client", "LSCV1.unknown.abc", [])
  end
end
