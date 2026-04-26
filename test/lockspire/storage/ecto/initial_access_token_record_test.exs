defmodule Lockspire.Storage.Ecto.InitialAccessTokenRecordTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Storage.Ecto.InitialAccessTokenRecord
  alias Lockspire.Test.Fixtures.InitialAccessTokenFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end

  test "round-trip persists IAT with policy_overrides jsonb and reloads it as map" do
    repo = Lockspire.TestRepo

    iat =
      InitialAccessTokenFixtures.initial_access_token(%{
        plaintext: "round_trip_plaintext",
        policy_overrides: %{
          "allowed_scopes" => ["openid", "profile"],
          "allowed_grant_types" => ["authorization_code"]
        },
        created_by: "operator-1"
      })

    {:ok, inserted} =
      %InitialAccessTokenRecord{}
      |> InitialAccessTokenRecord.changeset(iat)
      |> repo.insert()

    out = InitialAccessTokenRecord.to_domain(repo.get!(InitialAccessTokenRecord, inserted.id))

    assert out.token_hash == iat.token_hash
    assert out.single_use == true
    assert out.used_at == nil
    assert out.revoked_at == nil
    assert out.created_by == "operator-1"

    assert out.policy_overrides == %{
             "allowed_scopes" => ["openid", "profile"],
             "allowed_grant_types" => ["authorization_code"]
           }

    assert is_struct(out, InitialAccessToken)
  end

  test "unique_constraint on token_hash rejects duplicates" do
    repo = Lockspire.TestRepo

    iat = InitialAccessTokenFixtures.initial_access_token(%{plaintext: "dupe_plaintext"})

    {:ok, _first} =
      %InitialAccessTokenRecord{}
      |> InitialAccessTokenRecord.changeset(iat)
      |> repo.insert()

    duplicate = InitialAccessTokenFixtures.initial_access_token(%{plaintext: "dupe_plaintext"})

    assert duplicate.token_hash == iat.token_hash,
           "fixture sanity check: same plaintext → same hash"

    {:error, changeset} =
      %InitialAccessTokenRecord{}
      |> InitialAccessTokenRecord.changeset(duplicate)
      |> repo.insert()

    refute changeset.valid?
    assert Keyword.get(changeset.errors, :token_hash) != nil
  end

  test "validate_required catches missing token_hash and expires_at" do
    incomplete = %InitialAccessToken{single_use: true}

    changeset = InitialAccessTokenRecord.changeset(%InitialAccessTokenRecord{}, incomplete)

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :token_hash)
    assert Keyword.has_key?(changeset.errors, :expires_at)
  end
end
