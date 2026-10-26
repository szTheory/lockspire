defmodule Lockspire.Security.ClientSecretVerifierMaintenanceTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @salt "lockspire client_secret_jwt verifier"
  @legacy_key "maintenance-test-legacy-secret-key-base"

  test "authenticated migrated custody inspection retains age metadata after expiry" do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    client_id = "maintenance-expired-migrated-client"
    secret = "secret-for-expired-migrated-custody"
    signed_at_ms = 1_700_000_000_123
    deadline_ms = signed_at_ms + 1_250
    expected_hash = Policy.hash_client_secret(secret)
    old_context = context([{"old", old_key}], "old")
    new_context = context([{"old", old_key}, {"new", new_key}], "new")
    original = encrypt_migrated(old_context, client_id, secret, signed_at_ms, deadline_ms)

    assert {:ok, before} =
             ClientSecretVerifier.inspect_custody(
               new_context,
               client_id,
               original,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert before.classification == :old_key
    assert before.authenticated?
    assert before.age_kind == :migrated
    assert before.signed_at_ms == signed_at_ms
    assert before.deadline_ms == deadline_ms
    refute before.authentication_eligible?

    assert {:ok, replacement, "old", "new"} =
             ClientSecretVerifier.prepare_rewrap(
               new_context,
               client_id,
               original,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert replacement != original

    assert {:ok, after_rewrap} =
             ClientSecretVerifier.inspect_custody(
               new_context,
               client_id,
               replacement,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert Map.take(after_rewrap, [:age_kind, :signed_at_ms, :deadline_ms]) ==
             Map.take(before, [:age_kind, :signed_at_ms, :deadline_ms])

    assert after_rewrap.classification == :current_key
    refute after_rewrap.authentication_eligible?

    assert {:ok, :already_current, "new", "new"} =
             ClientSecretVerifier.prepare_rewrap(
               new_context,
               client_id,
               replacement,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.open(new_context, client_id, replacement,
               verifier_now_ms: deadline_ms + 1
             )
  end

  test "custody preparation preserves expired metadata and generates fresh IVs" do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    client_id = "maintenance-repeated-expired-client"
    secret = "repeatable-expired-custody-secret"
    signed_at_ms = 1_700_000_000_123
    deadline_ms = signed_at_ms + 60_000
    old_context = context([{"old", old_key}], "old")
    new_context = context([{"old", old_key}, {"new", new_key}], "new")
    expected_hash = Policy.hash_client_secret(secret)
    original = encrypt_migrated(old_context, client_id, secret, signed_at_ms, deadline_ms)

    assert {:ok, first, "old", "new"} =
             ClientSecretVerifier.prepare_rewrap(
               new_context,
               client_id,
               original,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert {:ok, second, "old", "new"} =
             ClientSecretVerifier.prepare_rewrap(
               new_context,
               client_id,
               original,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert first != second

    assert {:ok, first_metadata} =
             ClientSecretVerifier.inspect_custody(
               new_context,
               client_id,
               first,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert {:ok, second_metadata} =
             ClientSecretVerifier.inspect_custody(
               new_context,
               client_id,
               second,
               expected_hash,
               now_ms: deadline_ms + 1
             )

    assert first_metadata.signed_at_ms == signed_at_ms
    assert first_metadata.deadline_ms == deadline_ms
    assert second_metadata.signed_at_ms == signed_at_ms
    assert second_metadata.deadline_ms == deadline_ms
  end

  test "custody inspection rejects tampering, wrong identity, unknown keys, future age, and hash mismatch" do
    key = :crypto.strong_rand_bytes(32)
    client_id = "maintenance-adversarial-client"
    secret = "maintenance-adversarial-secret"
    signed_at_ms = 1_700_000_000_123
    deadline_ms = signed_at_ms + 60_000
    context = context([{"known", key}], "known")
    hash = Policy.hash_client_secret(secret)
    valid = encrypt_migrated(context, client_id, secret, signed_at_ms, deadline_ms)
    [header, key_id, payload] = String.split(valid, ".", parts: 3)
    <<first, rest::binary>> = payload
    replacement = if first == ?A, do: ?B, else: ?A
    tampered = header <> "." <> key_id <> "." <> <<replacement, rest::binary>>
    future = encrypt_migrated(context, client_id, secret, 1_700_100_000_000, 1_700_100_060_000)

    for {candidate_client_id, candidate_verifier, candidate_hash, candidate_now} <- [
          {client_id, tampered, hash, deadline_ms},
          {client_id <> "-other", valid, hash, deadline_ms},
          {client_id, valid, "sha256:wrong-hash", deadline_ms},
          {client_id, future, hash, deadline_ms},
          {client_id, String.replace_prefix(valid, "LSCV1.known.", "LSCV1.unknown."), hash,
           deadline_ms}
        ] do
      result =
        ClientSecretVerifier.inspect_custody(
          context,
          candidate_client_id,
          candidate_verifier,
          candidate_hash,
          now_ms: candidate_now
        )

      assert match?({:error, _reason}, result)
      refute inspect(result) =~ secret
      refute inspect(result) =~ candidate_verifier
      refute inspect(result) =~ Base.encode64(key)
    end
  end

  test "authenticated dedicated payloads with invalid structure cannot establish custody" do
    key = :crypto.strong_rand_bytes(32)
    client_id = "maintenance-structure-client"
    secret = "maintenance-structure-secret"
    context = context([{"structure-key", key}], "structure-key")
    hash = Policy.hash_client_secret(secret)
    oversized_secret = String.duplicate("x", 1_048_577)

    invalid_plaintexts = [
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 0, 0>>,
      <<1, byte_size(secret) + 1::unsigned-big-32, secret::binary, 0>>,
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 2>>,
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1,
        1_700_000_000_124::signed-big-64, 1_700_000_000_123::signed-big-64>>,
      <<1, byte_size(oversized_secret)::unsigned-big-32, oversized_secret::binary, 0>>
    ]

    for plaintext <- invalid_plaintexts do
      encrypted = encrypt_plaintext(context, client_id, plaintext)

      assert {:error, :client_secret_verifier_unavailable} =
               ClientSecretVerifier.inspect_custody(
                 context,
                 client_id,
                 encrypted,
                 hash,
                 now_ms: 1_800_000_000_000
               )

      assert {:error, :client_secret_verifier_unavailable} =
               ClientSecretVerifier.prepare_rewrap(
                 context,
                 client_id,
                 encrypted,
                 hash,
                 now_ms: 1_800_000_000_000
               )
    end
  end

  test "reserved dedicated prefixes never retry through the legacy reader" do
    context = context([{"known", :crypto.strong_rand_bytes(32)}], "known")

    assert {:error, :client_secret_verifier_unsupported_format} =
             ClientSecretVerifier.open(context, "reserved-prefix-client", "LSCV2.legacy-looking",
               legacy_secret_key_base: "configured-legacy-key"
             )
  end

  test "qualified tuple-three tuple-two and map legacy metadata keep their original deadline" do
    key = :crypto.strong_rand_bytes(32)
    context = context([{"current", key}], "current")
    client_id = "maintenance-qualified-legacy-client"
    secret = "qualified-legacy-secret"
    signed_at_ms = 1_700_000_000_123

    cases = [
      {{secret, signed_at_ms, 1.25}, signed_at_ms + 1_249, signed_at_ms + 1_250},
      {{secret, signed_at_ms}, signed_at_ms + 86_400_000, signed_at_ms + 86_400_000},
      {%{data: secret, signed: signed_at_ms}, signed_at_ms + 86_400_000,
       signed_at_ms + 86_400_000}
    ]

    for {legacy_term, now_ms, expected_deadline_ms} <- cases do
      legacy = encrypt_legacy(legacy_term)

      assert {:ok, replacement, "legacy", "current"} =
               ClientSecretVerifier.prepare_rewrap(
                 context,
                 client_id,
                 legacy,
                 Policy.hash_client_secret(secret),
                 now_ms: now_ms,
                 legacy_secret_key_base: @legacy_key
               )

      assert {:ok, metadata} =
               ClientSecretVerifier.inspect_custody(
                 context,
                 client_id,
                 replacement,
                 Policy.hash_client_secret(secret),
                 now_ms: now_ms
               )

      assert metadata.classification == :current_key
      assert metadata.age_kind == :migrated
      assert metadata.signed_at_ms == signed_at_ms
      assert metadata.deadline_ms == expected_deadline_ms
      assert metadata.authentication_eligible?
    end
  end

  test "unqualified legacy material and divergent hashes cannot be prepared" do
    key = :crypto.strong_rand_bytes(32)
    context = context([{"current", key}], "current")
    client_id = "maintenance-rejected-legacy-client"
    signed_at_ms = 1_700_000_000_000
    secret = "rejected-legacy-secret"

    rejected = [
      {encrypt_legacy({secret, signed_at_ms - 60_001, 60}), signed_at_ms},
      {encrypt_legacy({secret, signed_at_ms + 1, 60}), signed_at_ms},
      {encrypt_legacy({secret, signed_at_ms, 0}), signed_at_ms},
      {encrypt_legacy({secret, signed_at_ms, :infinity}), signed_at_ms},
      {encrypt_legacy({:unsupported, signed_at_ms}), signed_at_ms},
      {encrypt_legacy({secret, signed_at_ms, 60}), signed_at_ms, "wrong-legacy-key"},
      {encrypt_legacy({secret, signed_at_ms, 60}), signed_at_ms, @legacy_key,
       "sha256:divergent-hash"},
      {encrypt_legacy({String.duplicate("x", 1_048_577), signed_at_ms, 60}), signed_at_ms}
    ]

    for rejection <- rejected do
      {encrypted, now_ms, legacy_key, expected_hash} =
        case rejection do
          {encrypted, now_ms} ->
            {encrypted, now_ms, @legacy_key, Policy.hash_client_secret(secret)}

          {encrypted, now_ms, legacy_key} ->
            {encrypted, now_ms, legacy_key, Policy.hash_client_secret(secret)}

          {encrypted, now_ms, legacy_key, expected_hash} ->
            {encrypted, now_ms, legacy_key, expected_hash}
        end

      result =
        ClientSecretVerifier.prepare_rewrap(
          context,
          client_id,
          encrypted,
          expected_hash,
          now_ms: now_ms,
          legacy_secret_key_base: legacy_key
        )

      assert match?({:error, _reason}, result)
      refute inspect(result) =~ secret
      refute inspect(result) =~ encrypted
    end
  end

  defp context(keys, current) do
    {:ok, resolved} =
      Context.resolve(
        {:present,
         [
           keys:
             Enum.map(keys, fn {key_id, key} ->
               {key_id, Base.url_encode64(key, padding: false)}
             end),
           current: current,
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, context} = Context.validate(resolved)
    context
  end

  defp encrypt_migrated(context, client_id, secret, signed_at_ms, deadline_ms) do
    plaintext =
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1, signed_at_ms::signed-big-64,
        deadline_ms::signed-big-64>>

    encrypt_plaintext(context, client_id, plaintext)
  end

  defp encrypt_plaintext(context, client_id, plaintext) do
    key = context.keys[context.current_id]
    iv = :crypto.strong_rand_bytes(12)

    aad =
      "lockspire-client-secret-jwt-verifier" <>
        <<0>> <> "LSCV1" <> <<0>> <> context.current_id <> <<0>> <> client_id

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)

    "LSCV1." <>
      context.current_id <>
      "." <> Base.url_encode64(iv <> tag <> ciphertext, padding: false)
  end

  defp encrypt_legacy(term) do
    key = Plug.Crypto.KeyGenerator.generate(@legacy_key, @salt)
    payload = :erlang.term_to_binary(term)
    Plug.Crypto.MessageEncryptor.encrypt(payload, key, "")
  end
end
