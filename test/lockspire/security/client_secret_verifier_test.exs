defmodule Lockspire.Security.ClientSecretVerifierTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context

  @aad_label "lockspire-client-secret-jwt-verifier"
  @header "LSCV1"
  @max_bytes 1_048_576
  @max_envelope_bytes 1_398_207
  @max_payload_bytes 1_048_626

  test "independently constructed envelope authenticates exact plaintext and AAD" do
    key = random_key()
    key_id = "independent.primary"
    client_id = "client.exact-utf8"
    secret = :crypto.strong_rand_bytes(32)
    context = context(key_id, key)

    envelope = independent_envelope(key_id, key, client_id, secret)

    assert true == open_matches?(context, client_id, envelope, secret)
    assert false == open_matches?(context, client_id <> "-substituted", envelope, secret)

    assert false ==
             open_matches?(
               context,
               client_id,
               independent_envelope(key_id, key, client_id, secret, aad_label: "wrong-purpose"),
               secret
             )
  end

  test "dotted key IDs round-trip and each seal uses a fresh IV" do
    key_id = "primary.verifier.v1"
    key = random_key()
    context = context(key_id, key)
    client_id = "client-dotted-key"
    secret = <<0, 1, 2, 255, 0>>

    assert {:ok, first} = ClientSecretVerifier.seal(context, client_id, secret)
    assert {:ok, second} = ClientSecretVerifier.seal(context, client_id, secret)
    assert true == open_matches?(context, client_id, first, secret)
    assert true == open_matches?(context, client_id, second, secret)
    refute payload_iv(first) == payload_iv(second)
  end

  test "wrong key, wrong identity, and bound-field tampering fail closed" do
    key_id = "verifier-1"
    key = random_key()
    context = context(key_id, key)
    client_id = "bound-client"
    secret = :crypto.strong_rand_bytes(32)
    envelope = independent_envelope(key_id, key, client_id, secret)

    assert false == open_matches?(context, client_id <> "-other", envelope, secret)

    assert open_error(context(key_id, random_key()), client_id, envelope) ==
             :client_secret_verifier_unavailable

    assert open_error(
             context,
             client_id,
             replace_payload(envelope, fn payload -> flip_byte(payload, 0) end)
           ) != :ok

    assert open_error(
             context,
             client_id,
             replace_payload(envelope, fn payload -> flip_byte(payload, 12) end)
           ) != :ok

    assert open_error(
             context,
             client_id,
             replace_payload(envelope, fn payload -> flip_byte(payload, 28) end)
           ) != :ok

    assert open_error(context, client_id, replace_key_id(envelope, "unknown.key")) ==
             :client_secret_verifier_key_unknown
  end

  test "reserved LSCV family rejects unknown versions, malformed text, short tags, and noncanonical base64" do
    key_id = "verifier-1"
    key = random_key()
    context = context(key_id, key)
    client_id = "reserved-family-client"
    legacy_key = "legacy-key-for-test-only"

    legacy =
      Lockspire.Security.Policy.seal_client_secret_jwt_verifier("legacy-secret", legacy_key)

    assert ClientSecretVerifier.open(context, client_id, legacy,
             legacy_secret_key_base: legacy_key
           ) == {:ok, "legacy-secret"}

    for malformed <- [
          "LSCV",
          "LSCV2.#{key_id}.AAAA",
          "LSCV1.#{key_id}.not*base64",
          "LSCV1.#{key_id}.#{Base.url_encode64(:binary.copy(<<0>>, 27), padding: false)}"
        ] do
      assert open_error(context, client_id, malformed, legacy_secret_key_base: legacy_key) != :ok
    end

    valid = independent_envelope(key_id, key, client_id, "canonical")
    assert open_error(context, client_id, replace_payload(valid, &noncanonical_payload/1)) != :ok
  end

  test "plaintext version, age kind, length, and trailing bytes are authenticated and strict" do
    key_id = "verifier-1"
    key = random_key()
    context = context(key_id, key)
    client_id = "strict-plaintext-client"

    invalid_plaintexts = [
      <<2, 1::unsigned-big-32, "x", 0>>,
      <<1, 1::unsigned-big-32, "x", 2>>,
      <<1, 2::unsigned-big-32, "x", 0>>,
      <<1, 1::unsigned-big-32, "x", 0, 99>>
    ]

    for plaintext <- invalid_plaintexts do
      envelope = independent_envelope(key_id, key, client_id, plaintext: plaintext)
      assert open_error(context, client_id, envelope) == :client_secret_verifier_unavailable
    end
  end

  test "byte caps accept exactly one MiB and reject the next byte" do
    key_id = String.duplicate("k", 32)
    context = context(key_id, random_key())
    client_id = String.duplicate("é", div(@max_bytes, 2))
    secret = :binary.copy(<<255>>, @max_bytes)

    assert {:ok, envelope} = ClientSecretVerifier.seal(context, client_id, secret)
    assert byte_size(client_id) == @max_bytes
    assert byte_size(envelope) <= @max_envelope_bytes
    assert true == open_matches?(context, client_id, envelope, secret)
    assert elem(ClientSecretVerifier.seal(context, client_id, secret <> <<0>>), 0) == :error
    assert elem(ClientSecretVerifier.seal(context, client_id <> "x", secret), 0) == :error

    unknown_key_id = String.duplicate("u", 32)

    exact_size =
      @header <>
        "." <> unknown_key_id <> "." <> String.duplicate("A", @max_envelope_bytes - 6 - 32 - 1)

    assert byte_size(exact_size) == @max_envelope_bytes
    assert open_error(context, "id", exact_size) == :client_secret_verifier_key_unknown

    assert open_error(context, "id", exact_size <> "A") ==
             :client_secret_verifier_unsupported_format

    assert @max_payload_bytes == 1_048_626
  end

  test "context validation rejects incomplete, duplicate, and cross-purpose key material" do
    key = random_key()
    encoded = Base.url_encode64(key, padding: false)

    base = [
      keys: [{"key-1", encoded}],
      current: "key-1",
      write_mode: :dedicated,
      legacy_read: :allow
    ]

    assert {:ok, %Context{state: :valid}} = Context.resolve({:present, base}, [])

    assert {:ok, %Context{state: :invalid}} =
             Context.resolve({:present, Keyword.delete(base, :current)}, [])

    assert {:ok, %Context{state: :invalid}} =
             Context.resolve({:present, base ++ [extra: true]}, [])

    assert {:ok, %Context{state: :invalid}} = Context.resolve({:present, base}, [key])
  end

  defp context(key_id, key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{key_id, Base.url_encode64(key, padding: false)}],
           current: key_id,
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    context
  end

  defp independent_envelope(key_id, key, client_id, secret_or_opts, opts \\ []) do
    {secret, opts} =
      if is_list(secret_or_opts),
        do: {Keyword.get(secret_or_opts, :secret, <<>>), secret_or_opts},
        else: {secret_or_opts, opts}

    plaintext =
      Keyword.get(opts, :plaintext, <<1, byte_size(secret)::unsigned-big-32, secret::binary, 0>>)

    iv = Keyword.get(opts, :iv, :crypto.strong_rand_bytes(12))
    aad_label = Keyword.get(opts, :aad_label, @aad_label)
    aad = aad_label <> <<0>> <> @header <> <<0>> <> key_id <> <<0>> <> client_id

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)

    @header <> "." <> key_id <> "." <> Base.url_encode64(iv <> tag <> ciphertext, padding: false)
  end

  defp open_matches?(context, client_id, envelope, secret) do
    case ClientSecretVerifier.open(context, client_id, envelope, []) do
      {:ok, actual} -> actual == secret
      _ -> false
    end
  end

  defp open_error(context, client_id, envelope, opts \\ []) do
    case ClientSecretVerifier.open(context, client_id, envelope, opts) do
      {:ok, _secret} -> :ok
      {:error, reason} -> reason
      _ -> :unexpected
    end
  end

  defp replace_payload(envelope, transform) do
    [prefix, payload] = split_final_payload(envelope)
    prefix <> "." <> transform.(payload)
  end

  defp replace_key_id(envelope, replacement) do
    [header | pieces] = String.split(envelope, ".")
    payload = List.last(pieces)
    header <> "." <> replacement <> "." <> payload
  end

  defp split_final_payload(envelope) do
    pieces = String.split(envelope, ".")
    payload = List.last(pieces)
    prefix = pieces |> Enum.drop(-1) |> Enum.join(".")
    [prefix, payload]
  end

  defp payload_iv(envelope) do
    [_, payload] = split_final_payload(envelope)
    {:ok, decoded} = Base.url_decode64(payload, padding: false)
    binary_part(decoded, 0, 12)
  end

  defp flip_byte(payload, index) do
    {:ok, bytes} = Base.url_decode64(payload, padding: false)
    <<before::binary-size(index), byte, after_bytes::binary>> = bytes
    Base.url_encode64(before <> <<Bitwise.bxor(byte, 1)>> <> after_bytes, padding: false)
  end

  defp noncanonical_payload(payload) do
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    last = String.last(payload)
    index = :binary.match(alphabet, last) |> elem(0)

    replacement =
      if rem(byte_size(Base.url_decode64!(payload, padding: false)), 3) == 1,
        do: Bitwise.band(index, 48) + 1,
        else: Bitwise.band(index, 60) + 1

    String.slice(payload, 0, byte_size(payload) - 1) <> String.at(alphabet, replacement)
  end

  defp random_key, do: :crypto.strong_rand_bytes(32)
end
