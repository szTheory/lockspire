defmodule Lockspire.Domain.InitialAccessTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Security.Policy
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  test "empty struct defaults match D-11 / D-13" do
    iat = %InitialAccessToken{}

    assert iat.id == nil
    assert iat.token_hash == nil
    assert iat.expires_at == nil
    assert iat.single_use == true
    assert iat.used_at == nil
    assert iat.revoked_at == nil
    assert iat.policy_overrides == nil
    assert iat.created_by == nil
    assert iat.inserted_at == nil
    assert iat.updated_at == nil
  end

  test "fixture/1 hashes the plaintext via Lockspire.Security.Policy.hash_token/1" do
    plaintext = "iat_test_plaintext_value"

    iat = InitialAccessTokenFixtures.initial_access_token(%{plaintext: plaintext})

    assert iat.token_hash == Policy.hash_token(plaintext)
    # sha256 lowercase hex is 64 chars
    assert String.length(iat.token_hash) == 64
    assert iat.token_hash == String.downcase(iat.token_hash)
    assert iat.single_use == true
    refute is_nil(iat.expires_at)
  end

  test "fixture/1 lets attrs override defaults but never widens via :plaintext" do
    iat =
      InitialAccessTokenFixtures.initial_access_token(%{
        plaintext: "p",
        single_use: false,
        policy_overrides: %{"allowed_scopes" => ["openid"]},
        created_by: "operator-42"
      })

    assert iat.single_use == false
    assert iat.policy_overrides == %{"allowed_scopes" => ["openid"]}
    assert iat.created_by == "operator-42"
    # :plaintext is consumed for the hash and not re-applied as a struct key
    refute Map.has_key?(Map.from_struct(iat), :plaintext)
  end

  test "fixture/0 returns a unique random token hash on each call" do
    iat_a = InitialAccessTokenFixtures.initial_access_token()
    iat_b = InitialAccessTokenFixtures.initial_access_token()

    refute iat_a.token_hash == iat_b.token_hash
  end
end
