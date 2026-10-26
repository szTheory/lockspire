defmodule Lockspire.Security.ClientSecretVerifierMaintenanceTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

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

  test "reserved dedicated prefixes never retry through the legacy reader" do
    context = context([{"known", :crypto.strong_rand_bytes(32)}], "known")

    assert {:error, :client_secret_verifier_unsupported_format} =
             ClientSecretVerifier.open(context, "reserved-prefix-client", "LSCV2.legacy-looking",
               legacy_secret_key_base: "configured-legacy-key"
             )
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
    key = context.keys[context.current_id]
    iv = :crypto.strong_rand_bytes(12)

    plaintext =
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1, signed_at_ms::signed-big-64,
        deadline_ms::signed-big-64>>

    aad =
      "lockspire-client-secret-jwt-verifier" <>
        <<0>> <> "LSCV1" <> <<0>> <> context.current_id <> <<0>> <> client_id

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)

    "LSCV1." <>
      context.current_id <>
      "." <> Base.url_encode64(iv <> tag <> ciphertext, padding: false)
  end
end
