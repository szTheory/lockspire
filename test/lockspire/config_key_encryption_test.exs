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

  test "invalid key error names both generation commands and warns about phx.gen.secret" do
    msg = message(keys: [{"a", Base.encode64(:crypto.strong_rand_bytes(31))}], current: "a")
    assert msg =~ "openssl rand -base64 32"
    assert msg =~ "Base.encode64(:crypto.strong_rand_bytes(32))"
    assert msg =~ "phx.gen.secret"
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
