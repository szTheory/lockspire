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

    assert function_exported?(ClientSecretVerifier, :inspect_custody, 5)
    assert function_exported?(ClientSecretVerifier, :prepare_rewrap, 5)

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

    assert {:ok, replacement} =
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

    assert {:error, :client_secret_verifier_unavailable} =
             ClientSecretVerifier.open(new_context, client_id, replacement,
               verifier_now_ms: deadline_ms + 1
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
