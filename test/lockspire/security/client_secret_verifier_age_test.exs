defmodule Lockspire.Security.ClientSecretVerifierAgeTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @salt "lockspire client_secret_jwt verifier"
  @age_ms 86_400_000

  test "migration preparation exposes the planned pure reader API" do
    assert function_exported?(ClientSecretVerifier, :prepare_migrated, 5)
  end

  test "native dedicated material has no storage age timer" do
    context = context()
    secret = "native-secret-with-no-storage-timer"
    assert {:ok, text} = ClientSecretVerifier.seal(context, "native-client", secret)

    assert {:ok, ^secret} =
             ClientSecretVerifier.open(context, "native-client", text, verifier_now_ms: 0)
  end

  test "independent age-kind-one vector carries the signed timestamp and deadline" do
    key_id = "independent-age-key"
    key = :crypto.strong_rand_bytes(32)
    client_id = "independent-age-client"
    secret = "independent-migrated-secret"
    signed_at_ms = 1_700_000_000_123
    deadline_ms = 1_700_086_400_123

    aad =
      "lockspire-client-secret-jwt-verifier" <>
        <<0>> <> "LSCV1" <> <<0>> <> key_id <> <<0>> <> client_id

    plaintext =
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1, signed_at_ms::signed-big-64,
        deadline_ms::signed-big-64>>

    iv = :crypto.strong_rand_bytes(12)

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)

    encoded = Base.url_encode64(iv <> tag <> ciphertext, padding: false)
    envelope = "LSCV1." <> key_id <> "." <> encoded
    context = context_with_key(key_id, key)

    assert {:ok, ^secret} =
             ClientSecretVerifier.open(context, client_id, envelope, verifier_now_ms: deadline_ms)

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.open(context, client_id, envelope,
               verifier_now_ms: deadline_ms + 1
             )
  end

  test "migrated fractional deadline preserves original timestamp and equality" do
    context = context()
    secret = "legacy-secret"
    signed_at_ms = 1_700_000_000_123
    now_ms = signed_at_ms + 1_249
    legacy = encrypt_legacy({secret, signed_at_ms, 1.25})
    expected_hash = Policy.hash_client_secret(secret)

    assert {:ok, migrated} =
             ClientSecretVerifier.prepare_migrated(
               context,
               "migrated-client",
               legacy,
               expected_hash,
               now_ms: now_ms,
               legacy_secret_key_base: legacy_key_base()
             )

    deadline_ms = signed_at_ms + trunc(1.25 * 1000)

    assert {:ok, ^secret} =
             ClientSecretVerifier.open(context, "migrated-client", migrated,
               verifier_now_ms: deadline_ms
             )

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.open(context, "migrated-client", migrated,
               verifier_now_ms: deadline_ms + 1
             )

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.open(context, "migrated-client", migrated,
               verifier_now_ms: signed_at_ms - 1
             )
  end

  test "tuple-two and map historical metadata use the pinned default age" do
    context = context()
    secret = "legacy-default-age-secret"
    signed_at_ms = 1_700_000_000_000
    expected_hash = Policy.hash_client_secret(secret)

    for term <- [{secret, signed_at_ms}, %{data: secret, signed: signed_at_ms}] do
      legacy = encrypt_legacy(term)

      assert {:ok, migrated} =
               ClientSecretVerifier.prepare_migrated(
                 context,
                 "default-age-client",
                 legacy,
                 expected_hash,
                 now_ms: signed_at_ms + @age_ms,
                 legacy_secret_key_base: legacy_key_base()
               )

      assert {:ok, ^secret} =
               ClientSecretVerifier.open(context, "default-age-client", migrated,
                 verifier_now_ms: signed_at_ms + @age_ms
               )
    end
  end

  test "unsupported ages and hash disagreement produce no replacement" do
    context = context()
    signed_at_ms = 1_700_000_000_000
    secret = "sentinel-secret-never-reported"

    for max_age <- [:infinity, 0, -1, 1.0e100] do
      legacy = encrypt_legacy({secret, signed_at_ms, max_age})

      assert {:error, :client_secret_verifier_unsupported_format} =
               ClientSecretVerifier.prepare_migrated(
                 context,
                 "unsupported-age-client",
                 legacy,
                 Policy.hash_client_secret(secret),
                 now_ms: signed_at_ms,
                 legacy_secret_key_base: legacy_key_base()
               )
    end

    legacy = encrypt_legacy({secret, signed_at_ms, 60})

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.prepare_migrated(
               context,
               "mismatched-hash-client",
               legacy,
               "sha256:divergent:hash",
               now_ms: signed_at_ms,
               legacy_secret_key_base: legacy_key_base()
             )

    assert {:error, :client_secret_verifier_unsupported_format} =
             ClientSecretVerifier.prepare_migrated(
               context,
               "future-client",
               encrypt_legacy({secret, signed_at_ms + 1, 60}),
               Policy.hash_client_secret(secret),
               now_ms: signed_at_ms,
               legacy_secret_key_base: legacy_key_base()
             )
  end

  test "only allowed nonreserved legacy material reads through the qualified Plug helper" do
    key = "legacy-endpoint-key-for-test"
    legacy = Policy.seal_client_secret_jwt_verifier("legacy-readable-secret", key)

    assert {:ok, "legacy-readable-secret"} =
             ClientSecretVerifier.open(context(legacy_read: :allow), "legacy-client", legacy,
               legacy_secret_key_base: key
             )

    assert {:error, :client_secret_verifier_legacy_rejected} =
             ClientSecretVerifier.open(context(legacy_read: :reject), "legacy-client", legacy,
               legacy_secret_key_base: key
             )
  end

  test "preparation rejects tampered and malformed ciphertext without returning input" do
    context = context()
    secret = "private-secret-fixture"
    valid = encrypt_legacy({secret, 1_700_000_000_000, 60})

    for legacy <- [valid <> "A", "not-a-ciphertext"] do
      result =
        ClientSecretVerifier.prepare_migrated(
          context,
          "malformed-client",
          legacy,
          Policy.hash_client_secret(secret),
          now_ms: 1_700_000_000_000,
          legacy_secret_key_base: legacy_key_base()
        )

      assert {:error, :client_secret_verifier_unsupported_format} = result
      refute inspect(result) =~ secret
      refute inspect(result) =~ legacy
    end
  end

  defp context(opts \\ []) do
    key = :crypto.strong_rand_bytes(32)
    key_id = "age-test-key"

    context_with_key(key_id, key, opts)
  end

  defp context_with_key(key_id, key, opts \\ []) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{key_id, Base.url_encode64(key, padding: false)}],
           current: key_id,
           write_mode: :dedicated,
           legacy_read: Keyword.get(opts, :legacy_read, :allow)
         ]},
        []
      )

    context
  end

  defp encrypt_legacy(term) do
    key_base = legacy_key_base()
    key = Plug.Crypto.KeyGenerator.generate(key_base, @salt)
    payload = :erlang.term_to_binary(term)
    Plug.Crypto.MessageEncryptor.encrypt(payload, key, "")
  end

  defp legacy_key_base,
    do: Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]
end
