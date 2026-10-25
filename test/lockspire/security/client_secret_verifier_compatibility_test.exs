defmodule Lockspire.Security.ClientSecretVerifierCompatibilityTest do
  use ExUnit.Case, async: true

  unless Code.ensure_loaded?(Lockspire.TestSupport.ClientSecretVerifierFixtures) do
    Code.require_file(Path.expand("../../support/client_secret_verifier_fixtures.ex", __DIR__))
  end

  alias Lockspire.Clients
  alias Lockspire.Security.Policy
  alias Lockspire.TestSupport.ClientSecretVerifierFixtures, as: Fixtures

  test "exported hash and material helpers retain the legacy tuple, map, overloads, and error" do
    assert {hash, plaintext} = Clients.rotate_secret_hash()
    assert is_binary(hash) and hash != ""
    assert is_binary(plaintext) and plaintext != ""
    assert Policy.verify_client_secret(hash, plaintext)

    material = Clients.rotate_secret_material()

    assert Map.keys(material) |> Enum.sort() ==
             [:client_secret, :client_secret_hash, :client_secret_jwt_verifier_encrypted]

    assert Policy.verify_client_secret(material.client_secret_hash, material.client_secret)

    material_secret = material.client_secret

    assert {:ok, ^material_secret} =
             Policy.unseal_client_secret_jwt_verifier(
               material.client_secret_jwt_verifier_encrypted
             )

    key_base = Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]
    binary_sealed = Policy.seal_client_secret_jwt_verifier("binary-overload", key_base)

    keyword_sealed =
      Policy.seal_client_secret_jwt_verifier("keyword-overload", secret_key_base: key_base)

    assert {:ok, "binary-overload"} =
             Policy.unseal_client_secret_jwt_verifier(binary_sealed, key_base)

    assert {:ok, "keyword-overload"} =
             Policy.unseal_client_secret_jwt_verifier(keyword_sealed, secret_key_base: key_base)

    assert {:error, :invalid_client_secret_jwt_verifier} =
             Policy.unseal_client_secret_jwt_verifier("not-valid")

    # Dedicated missing identity/config failures remain future Phase 176 contract obligations.
  end

  test "public authentication-before-decode reader accepts the three pinned Plug payload forms" do
    now = System.os_time(:second)

    secret = "phase175-synthetic-metadata"

    for {shape, expected_shape} <- [tuple3: :tuple3, tuple2: :tuple2, map: :map] do
      encrypted =
        Fixtures.legacy_verifier(secret, legacy_shape: shape, signed_at: now, max_age: 60)

      assert {:ok,
              %{
                data: ^secret,
                signed_at_ms: signed_at_ms,
                max_age_seconds: max_age,
                shape: ^expected_shape
              }} = Fixtures.authenticated_metadata(encrypted)

      assert signed_at_ms == now * 1000
      assert max_age == if(shape == :tuple3, do: 60, else: 86_400)
    end
  end

  test "LEG175-METADATA-TAMPER and wrong key fail closed without exposing ciphertext" do
    encrypted = Fixtures.legacy_verifier("phase175-synthetic-metadata")
    tampered = encrypted <> "A"

    other_key =
      Plug.Crypto.encrypt(
        String.duplicate("z", 64),
        "lockspire client_secret_jwt verifier",
        "synthetic"
      )

    assert {:error, :unsupported_or_invalid_legacy_verifier} =
             Fixtures.authenticated_metadata(tampered)

    assert {:error, :unsupported_or_invalid_legacy_verifier} =
             Fixtures.authenticated_metadata(other_key)

    assert {:error, :unsupported_or_invalid_legacy_verifier} =
             Fixtures.authenticated_metadata("")
  end

  test "LEG175-METADATA-SHAPE rejects authenticated unknown payloads and executable terms" do
    for unsupported <- [
          Fixtures.encrypt_raw_term({"synthetic-secret", "not-a-timestamp", 86_400}),
          Fixtures.encrypt_raw_term(%{data: "synthetic-secret", signed: "bad"}),
          Fixtures.encrypt_raw_term(fn -> :never_execute end)
        ] do
      assert {:error, :unsupported_or_invalid_legacy_verifier} =
               Fixtures.authenticated_metadata(unsupported)
    end
  end

  test "LEG175-DEADLINE preserves finite timestamp and expires strictly after equality" do
    encrypted =
      Fixtures.legacy_verifier("phase175-synthetic-metadata",
        signed_at: 1_798_000_000,
        max_age: 86_400
      )

    assert {:ok, metadata} = Fixtures.authenticated_metadata(encrypted)
    deadline = Fixtures.metadata_deadline(metadata)
    assert deadline == 1_798_000_000_000 + 86_400_000
    refute Fixtures.expired_at?(metadata, deadline)
    assert Fixtures.expired_at?(metadata, deadline + 1)

    old_verifier =
      Fixtures.legacy_verifier("phase175-synthetic-metadata",
        signed_at: System.os_time(:second) - 23 * 60 * 60
      )

    assert {:ok, old_metadata} = Fixtures.authenticated_metadata(old_verifier)
    original_deadline = Fixtures.metadata_deadline(old_metadata)
    assert original_deadline == old_metadata.signed_at_ms + 86_400_000
    assert Fixtures.metadata_deadline(old_metadata) == original_deadline
  end

  test "LEG175-METADATA-UNITS and range controls retain milliseconds and classify nonpositive ages" do
    signed_at = 1_700_000_123
    secret = "phase175-synthetic-metadata"

    finite = Fixtures.legacy_verifier(secret, signed_at: signed_at, max_age: 0.5)
    assert {:ok, fractional} = Fixtures.authenticated_metadata(finite)
    assert fractional.signed_at_ms == signed_at * 1000
    assert fractional.max_age_seconds == 0.5
    assert Fixtures.metadata_deadline(fractional) == signed_at * 1000 + 500

    for max_age <- [0, -1] do
      encrypted = Fixtures.legacy_verifier(secret, signed_at: signed_at, max_age: max_age)
      assert {:ok, metadata} = Fixtures.authenticated_metadata(encrypted)
      assert Fixtures.metadata_deadline(metadata) == {:error, :unsupported_age}
    end

    old = Fixtures.legacy_verifier(secret, signed_at: -1, max_age: 1)
    assert {:ok, negative_timestamp} = Fixtures.authenticated_metadata(old)
    assert negative_timestamp.signed_at_ms == -1000
    refute Fixtures.expired_at?(negative_timestamp, 0)
    assert Fixtures.expired_at?(negative_timestamp, 1)
  end

  test "LEG175-METADATA-INFINITY preserves the Plug infinity marker as unsupported policy" do
    encrypted = Fixtures.legacy_verifier("phase175-synthetic-metadata", max_age: :infinity)
    assert {:ok, metadata} = Fixtures.authenticated_metadata(encrypted)
    assert metadata.max_age_seconds == :infinity
    assert Fixtures.metadata_deadline(metadata) == :infinity
    refute Fixtures.expired_at?(metadata, System.os_time(:millisecond))
  end

  test "LEG175-AGE-CONTROLS records future, finite, and infinity policy shape distinctions" do
    now = System.os_time(:second)

    key_base = Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)[:secret_key_base]

    future =
      Plug.Crypto.encrypt(key_base, "lockspire client_secret_jwt verifier", "payload",
        signed_at: now + 60,
        max_age: 86_400
      )

    finite_old =
      Plug.Crypto.encrypt(key_base, "lockspire client_secret_jwt verifier", "payload",
        signed_at: now - 2 * 86_400,
        max_age: 86_400
      )

    nonpositive_ages =
      Enum.map([0, -1], fn max_age ->
        Plug.Crypto.encrypt(key_base, "lockspire client_secret_jwt verifier", "payload",
          signed_at: now,
          max_age: max_age
        )
      end)

    infinite_future =
      Plug.Crypto.encrypt(key_base, "lockspire client_secret_jwt verifier", "payload",
        signed_at: now + 60,
        max_age: :infinity
      )

    salt = "lockspire client_secret_jwt verifier"
    assert {:error, :invalid} = Plug.Crypto.decrypt(key_base, salt, future)
    assert {:error, :expired} = Plug.Crypto.decrypt(key_base, salt, finite_old)

    assert Enum.all?(
             nonpositive_ages,
             &(Plug.Crypto.decrypt(key_base, salt, &1) == {:error, :expired})
           )

    assert {:ok, "payload"} = Plug.Crypto.decrypt(key_base, salt, infinite_future)
  end

  test "hash/verifier disagreement is detectable as a non-ready migration disposition" do
    assert Fixtures.secret_hash_matches?("sha256:salt:hash", "secret") == false
    assert Fixtures.secret_hash_matches?(nil, "secret") == false
  end
end
