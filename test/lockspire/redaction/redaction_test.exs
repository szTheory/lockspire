defmodule Lockspire.RedactionTest do
  use ExUnit.Case, async: true

  alias Lockspire.Redaction

  test "for_telemetry drops bearer artifacts, secrets, and raw payloads while keeping stable handles" do
    metadata = %{
      access_token: "access-token-value",
      refresh_token: "refresh-token-value",
      authorization_code: "authorization-code-value",
      code_verifier: "plain-code-verifier",
      client_secret: "super-secret",
      client_secret_hash: "argon2id$hash",
      client_assertion: "header.payload.signature",
      jwt_header: %{"alg" => "RS256"},
      jwt_claims: %{"sub" => "client_123"},
      jwks_body: %{"keys" => [%{"kid" => "kid-1"}]},
      token_hash: "sha256$hash",
      family_id: "family-secret-hash",
      params: %{"token" => "access-token-value", "scope" => "openid"},
      payload: %{request: %{headers: %{"authorization" => "Bearer raw"}}},
      client_id: "client_123",
      reason_code: :refresh_token_reuse_detected
    }

    redacted = Redaction.for_telemetry(metadata)

    assert redacted.client_id == "client_123"
    assert redacted.reason_code == :refresh_token_reuse_detected
    assert redacted.family_handle == Redaction.handle(:family, "family-secret-hash")

    refute Map.has_key?(redacted, :access_token)
    refute Map.has_key?(redacted, :refresh_token)
    refute Map.has_key?(redacted, :authorization_code)
    refute Map.has_key?(redacted, :code_verifier)
    refute Map.has_key?(redacted, :client_secret)
    refute Map.has_key?(redacted, :client_secret_hash)
    refute Map.has_key?(redacted, :client_assertion)
    refute Map.has_key?(redacted, :jwt_header)
    refute Map.has_key?(redacted, :jwt_claims)
    refute Map.has_key?(redacted, :jwks_body)
    refute Map.has_key?(redacted, :token_hash)
    refute Map.has_key?(redacted, :family_id)
    refute Map.has_key?(redacted, :params)
    refute Map.has_key?(redacted, :payload)
  end

  test "handles are stable for the same value and differ for different values" do
    assert Redaction.handle(:token, "same-value") == Redaction.handle(:token, "same-value")
    refute Redaction.handle(:token, "same-value") == Redaction.handle(:token, "other-value")
  end

  describe "for_telemetry/1 — Phase 26 DCR drop list extension" do
    test "drops :registration_access_token (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{registration_access_token: "secret_rat", a: 1}) ==
               %{a: 1}
    end

    test ~s|drops "registration_access_token" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{
               "registration_access_token" => "secret_rat",
               "a" => 1
             }) == %{"a" => 1}
    end

    test "drops :initial_access_token (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{initial_access_token: "secret_iat", a: 1}) == %{
               a: 1
             }
    end

    test ~s|drops "initial_access_token" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{
               "initial_access_token" => "secret_iat",
               "a" => 1
             }) == %{"a" => 1}
    end

    test "drops :rat (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{rat: "secret_rat", a: 1}) == %{a: 1}
    end

    test ~s|drops "rat" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{"rat" => "secret_rat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :iat (atom)" do
      assert Lockspire.Redaction.for_telemetry(%{iat: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "iat" (string)| do
      assert Lockspire.Redaction.for_telemetry(%{"iat" => "secret_iat", "a" => 1}) == %{"a" => 1}
    end
  end

  describe "for_audit/1 — Phase 26 DCR drop list extension" do
    test "drops :registration_access_token (atom)" do
      assert Lockspire.Redaction.for_audit(%{registration_access_token: "secret_rat", a: 1}) == %{
               a: 1
             }
    end

    test ~s|drops "registration_access_token" (string)| do
      assert Lockspire.Redaction.for_audit(%{
               "registration_access_token" => "secret_rat",
               "a" => 1
             }) == %{"a" => 1}
    end

    test "drops :initial_access_token (atom)" do
      assert Lockspire.Redaction.for_audit(%{initial_access_token: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "initial_access_token" (string)| do
      assert Lockspire.Redaction.for_audit(%{"initial_access_token" => "secret_iat", "a" => 1}) ==
               %{"a" => 1}
    end

    test "drops :rat (atom)" do
      assert Lockspire.Redaction.for_audit(%{rat: "secret_rat", a: 1}) == %{a: 1}
    end

    test ~s|drops "rat" (string)| do
      assert Lockspire.Redaction.for_audit(%{"rat" => "secret_rat", "a" => 1}) == %{"a" => 1}
    end

    test "drops :iat (atom)" do
      assert Lockspire.Redaction.for_audit(%{iat: "secret_iat", a: 1}) == %{a: 1}
    end

    test ~s|drops "iat" (string)| do
      assert Lockspire.Redaction.for_audit(%{"iat" => "secret_iat", "a" => 1}) == %{"a" => 1}
    end
  end

  describe "key material" do
    @key_names ~w(private_jwk_encrypted private_jwk private_key jwk kek key_encryption
                  key_encryption_key envelope ciphertext)
    @envelope <<"LSK", 1, 5, 5, 5>>

    for surface <- [:for_telemetry, :for_audit] do
      test "#{surface} drops every key material name in atom and string form" do
        for name <- @key_names do
          atom_map = %{String.to_atom(name) => "secret", kept: 1}
          string_map = %{name => "secret", "kept" => 1}

          assert apply(Redaction, unquote(surface), [atom_map]) == %{kept: 1}, "atom #{name}"

          assert apply(Redaction, unquote(surface), [string_map]) == %{"kept" => 1},
                 "string #{name}"
        end
      end

      test "#{surface} drops a value that starts with the sealed envelope header" do
        result =
          apply(Redaction, unquote(surface), [
            %{note: @envelope, nested: %{blob: @envelope, ok: "fine"}, list: [@envelope, "fine"]}
          ])

        assert result == %{nested: %{ok: "fine"}, list: ["fine"]}
      end

      test "#{surface} keeps operator key identifiers" do
        metadata = %{kid: "k-1", kek_id: "kek-1", previous_kek_id: "kek-0", key_id: "key-1"}

        assert apply(Redaction, unquote(surface), [metadata]) == metadata
      end
    end
  end
end
