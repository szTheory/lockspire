defmodule Lockspire.ConfigKeyEncryptionTest do
  use ExUnit.Case, async: false

  import Lockspire.KeyEncryptionHelpers

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption.KeySet

  @sentinel "SENTINEL-KEK-VALUE"

  setup do
    # Registers env + cache restoration on exit; tests then vary the env directly.
    put_key_encryption(Application.get_env(:lockspire, :key_encryption))
    :ok
  end

  defp b64(seed), do: :crypto.hash(:sha256, seed) |> Base.encode64()
  defp valid_keys, do: [{"a", b64("one")}, {"b", b64("two")}]

  defp put(config), do: Application.put_env(:lockspire, :key_encryption, config)

  defp message(config) do
    put(config)
    error = assert_raise(ArgumentError, fn -> Config.key_encryption!() end)
    Exception.message(error)
  end

  test "absent block returns nil" do
    ExUnit.CaptureLog.capture_log(fn -> put_key_encryption(nil) end)
    assert Config.key_encryption!() == nil
  end

  test "valid block resolves and defaults legacy_plaintext to :allow" do
    put(keys: valid_keys(), current: "a")

    assert %KeySet{current_id: "a", ids: ["a", "b"], legacy_plaintext: :allow} =
             Config.key_encryption!()
  end

  test "standard and URL-safe base64, padded or not, are accepted" do
    raw = <<251, 255, 191>> <> :binary.copy(<<1, 2, 3, 4>>, 7) <> <<9>>
    assert byte_size(raw) == 32

    for encoded <- [
          Base.encode64(raw),
          Base.encode64(raw, padding: false),
          Base.url_encode64(raw),
          Base.url_encode64(raw, padding: false)
        ] do
      put(keys: [{"a", encoded}], current: "a")
      assert %KeySet{keys: %{"a" => ^raw}} = Config.key_encryption!()
    end
  end

  invalid_cases = [
    {"not a keyword list", :not_a_list, ":key_encryption"},
    {"unknown option", [keys: [{"a", "x"}], current: "a", bogus: 1], ":key_encryption"},
    {"keys missing", [current: "a"], ":keys"},
    {"empty keys", [keys: [], current: "a"], ":keys"},
    {"entry not a tuple", [keys: ["a"], current: "a"], ":keys"},
    {"bad id charset", [keys: [{"bad id!", "x"}], current: "a"], ":keys"},
    {"id too long", [keys: [{String.duplicate("a", 33), "x"}], current: "a"], ":keys"},
    {"bad base64", [keys: [{"a", "***not base64***"}], current: "a"], ":keys"},
    {"current missing", [keys: [{"a", Base.encode64(:crypto.hash(:sha256, "m"))}]], ":current"},
    {"current unknown", [keys: [{"a", Base.encode64(:crypto.hash(:sha256, "m"))}], current: "z"],
     ":current"},
    {"bad mode",
     [
       keys: [{"a", Base.encode64(:crypto.hash(:sha256, "m"))}],
       current: "a",
       legacy_plaintext: :strict
     ], ":legacy_plaintext"}
  ]

  for {name, config, expected} <- invalid_cases do
    test "invalid: #{name}" do
      msg = message(unquote(Macro.escape(config)))
      assert msg =~ ":key_encryption"
      assert msg =~ unquote(expected)
    end
  end

  test "invalid key error points to gen.kek and warns about phx.gen.secret" do
    msg = message(keys: [{"a", Base.encode64(:crypto.strong_rand_bytes(31))}], current: "a")
    assert msg =~ "mix lockspire.gen.kek"
    assert msg =~ "phx.gen.secret"
    refute msg =~ "openssl"
    refute msg =~ "elixir -e"
    refute msg =~ "Base.encode64("
  end

  test "invalid: key lengths, weak and duplicate material, duplicate ids" do
    for len <- [31, 33] do
      assert message(keys: [{"a", Base.encode64(:crypto.strong_rand_bytes(len))}], current: "a") =~
               ":keys"
    end

    assert message(keys: [{"a", Base.encode64(:binary.copy(<<5>>, 32))}], current: "a") =~
             "weak_key_material"

    same = b64("same")
    assert message(keys: [{"a", same}, {"b", same}], current: "a") =~ "duplicate_key_material"
    assert message(keys: [{"a", b64("x")}, {"a", b64("y")}], current: "a") =~ "duplicate_key_id"
  end

  test "sentinel never appears in messages or formatted exceptions" do
    sentinel_b64 = Base.encode64(@sentinel)

    cases = [
      [keys: [{"a", @sentinel}], current: "a"],
      [keys: [{"a", sentinel_b64}], current: "a"],
      [keys: [{@sentinel, b64("x")}], current: "a"],
      [keys: [{"a", b64("x")}], current: @sentinel],
      [keys: [{"a", b64("x")}], current: "a", legacy_plaintext: @sentinel],
      [keys: [{"a", b64("x")}], current: "a", legacy_plaintext: String.to_atom(@sentinel)],
      [{String.to_atom(@sentinel), 1}],
      @sentinel,
      [keys: [{"a", @sentinel, 1}], current: "a"]
    ]

    for config <- cases do
      put(config)

      try do
        Config.key_encryption!()
        flunk("expected raise")
      rescue
        e in ArgumentError ->
          refute Exception.message(e) =~ @sentinel
          refute Exception.format(:error, e, __STACKTRACE__) =~ @sentinel
      end
    end
  end

  describe "{:system, var} entries" do
    @var_a "LOCKSPIRE_TEST_KEK_ENV_A"
    @var_b "LOCKSPIRE_TEST_KEK_ENV_B"
    @var_s "LOCKSPIRE_TEST_KEK_ENV_S"

    setup do
      prior = for v <- [@var_a, @var_b, @var_s], do: {v, System.get_env(v)}
      for v <- [@var_a, @var_b, @var_s], do: System.delete_env(v)

      on_exit(fn ->
        for {v, value} <- prior do
          if value, do: System.put_env(v, value), else: System.delete_env(v)
        end
      end)

      :ok
    end

    test "resolves a variable at runtime and leaves app env untouched" do
      System.put_env(@var_a, b64("one"))
      put(keys: [{"a", {:system, @var_a}}], current: "a")

      expected = :crypto.hash(:sha256, "one")
      assert %KeySet{keys: %{"a" => ^expected}} = Config.key_encryption!()

      System.put_env(@var_a, b64("two"))
      expected2 = :crypto.hash(:sha256, "two")
      assert %KeySet{keys: %{"a" => ^expected2}} = Config.key_encryption!()

      assert Application.get_env(:lockspire, :key_encryption)[:keys] == [{"a", {:system, @var_a}}]
    end

    test "mixed literal and variable entries keep configured order" do
      System.put_env(@var_b, b64("two"))
      put(keys: [{"a", b64("one")}, {"b", {:system, @var_b}}], current: "a")
      assert %KeySet{ids: ["a", "b"]} = Config.key_encryption!()
    end

    test "unset variable raises missing_env naming only the variable" do
      msg = message(keys: [{"a", {:system, @var_a}}], current: "a")
      assert msg =~ "invalid config :key_encryption"
      assert msg =~ "missing_env"
      assert msg =~ @var_a
      assert msg =~ "mix lockspire.gen.kek"
    end

    test "empty variable is treated exactly like an unset one" do
      unset = message(keys: [{"a", {:system, @var_a}}], current: "a")
      System.put_env(@var_a, "")
      assert message(keys: [{"a", {:system, @var_a}}], current: "a") == unset
    end

    test "the first missing variable in configured order is the one named" do
      msg = message(keys: [{"a", {:system, @var_a}}, {"b", {:system, @var_b}}], current: "a")
      assert msg =~ @var_a
      refute msg =~ @var_b
    end

    test "a valid variable's value never appears when another variable is missing" do
      System.put_env(@var_s, Base.encode64(:crypto.hash(:sha256, @sentinel)))
      msg = message(keys: [{"a", {:system, @var_s}}, {"b", {:system, @var_b}}], current: "a")
      refute msg =~ Base.encode64(:crypto.hash(:sha256, @sentinel))
      refute msg =~ @sentinel
      assert msg =~ @var_b
    end

    test "two ids reading the same variable fail as duplicate material without the value" do
      value = b64("same")
      System.put_env(@var_a, value)
      msg = message(keys: [{"a", {:system, @var_a}}, {"b", {:system, @var_a}}], current: "a")
      assert msg =~ "duplicate_key_material"
      refute msg =~ value
    end

    test "a trailing newline is not trimmed and fails closed" do
      value = b64("one") <> "\n"
      System.put_env(@var_a, value)
      msg = message(keys: [{"a", {:system, @var_a}}], current: "a")
      assert msg =~ "invalid_base64"
      refute msg =~ value
    end

    test "a short value fails with invalid_key_length without the value" do
      value = Base.encode64(:crypto.strong_rand_bytes(31))
      System.put_env(@var_a, value)
      msg = message(keys: [{"a", {:system, @var_a}}], current: "a")
      assert msg =~ "invalid_key_length"
      refute msg =~ value
    end

    test "malformed system entries are classified by KeySet, not crashed on" do
      for entry <- [{"a", {:system, :atom}}, {"a", {:system}}, {:system, @var_a}] do
        assert message(keys: [entry], current: "a") =~ "invalid_key_entry"
      end
    end

    test "empty keys still fail with missing_keys" do
      assert message(keys: [], current: "a") =~ "missing_keys"
    end
  end

  describe "boot and redaction with {:system, var}" do
    require Logger

    @boot_var "LOCKSPIRE_TEST_KEK_BOOT_A"
    @boot_var_b "LOCKSPIRE_TEST_KEK_BOOT_B"

    setup do
      prior = for v <- [@boot_var, @boot_var_b], do: {v, System.get_env(v)}
      for v <- [@boot_var, @boot_var_b], do: System.delete_env(v)

      on_exit(fn ->
        for {v, value} <- prior do
          if value, do: System.put_env(v, value), else: System.delete_env(v)
        end
      end)

      :ok
    end

    defp forms(bytes, value) do
      [
        value,
        bytes,
        Base.url_encode64(bytes, padding: false),
        Base.encode16(bytes, case: :lower)
      ]
    end

    test "a configured block with an unset variable aborts boot validation" do
      put(keys: [{"a", {:system, @boot_var}}], current: "a")
      :persistent_term.erase(Config.key_encryption_cache_key())

      assert_raise ArgumentError, ~r/missing_env/, fn ->
        Lockspire.Application.validate_key_encryption!()
      end

      refute :persistent_term.get(Config.key_encryption_cache_key(), :miss) == :unconfigured
      assert_raise ArgumentError, fn -> Config.key_encryption!() end
    end

    test "inspect, interpolation and logs of a resolved key set show no key material" do
      bytes = :crypto.hash(:sha256, "redaction-one")
      value = Base.encode64(bytes)
      System.put_env(@boot_var, value)
      put(keys: [{"a", {:system, @boot_var}}, {"b", b64("redaction-two")}], current: "a")
      ks = Config.key_encryption!()

      outputs = [
        inspect(ks),
        inspect(ks, limit: :infinity, pretty: true),
        "#{inspect(ks)}",
        ExUnit.CaptureLog.capture_log(fn -> Logger.error("keyset #{inspect(ks)}") end)
      ]

      for out <- outputs, form <- forms(bytes, value) do
        refute out =~ form
      end

      assert hd(outputs) =~ "#Lockspire.KeyEncryption.KeySet<"
      assert hd(outputs) =~ "a"
      assert Enum.at(outputs, 3) =~ "keyset"
    end

    test "inspect of a system-resolved key set equals inspect of a literal one" do
      value = b64("same-shape")
      System.put_env(@boot_var, value)
      put(keys: [{"a", {:system, @boot_var}}], current: "a")
      system_ks = Config.key_encryption!()
      put(keys: [{"a", value}], current: "a")
      literal_ks = Config.key_encryption!()

      assert inspect(system_ks) == inspect(literal_ks)
    end

    test "a missing variable message never carries another variable's value" do
      sentinel_key = Base.encode64(:crypto.hash(:sha256, @sentinel))
      System.put_env(@boot_var, sentinel_key)

      msg =
        message(keys: [{"a", {:system, @boot_var}}, {"b", {:system, @boot_var_b}}], current: "a")

      refute msg =~ sentinel_key
      assert msg =~ @boot_var_b
    end
  end

  test "static guard: no compile-time KEK read and no endpoint secret fallback" do
    for path <- Path.wildcard("lib/**/*.ex") do
      source = File.read!(path)

      refute source =~ ~r/compile_env\(\s*:lockspire,\s*:key_encryption/,
             "#{path} reads :key_encryption at compile time"
    end

    for path <- [
          "lib/lockspire/security/key_encryption.ex",
          "lib/lockspire/security/key_encryption/key_set.ex"
        ] do
      refute File.read!(path) =~ "secret_key_base"
    end
  end
end
