defmodule Lockspire.Storage.Ecto.SigningKeyRecordTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord
  alias Lockspire.TestSupport.KeyMaterialMatcher

  @sentinel "SENTINEL-RECORD-D-0002"
  @envelope <<"LSK", 1, 9, 8, 7, 6, @sentinel::binary>>

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

  defp key(overrides \\ []) do
    struct!(
      %SigningKey{
        kid: "record-kid",
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk: %{"kty" => "RSA", "kid" => "record-kid"},
        private_jwk_encrypted: @envelope,
        status: :upcoming
      },
      overrides
    )
  end

  test "an invalid changeset never shows the stored bytes in params, inspect or the record" do
    changeset = SigningKeyRecord.changeset(%SigningKeyRecord{}, key(kid: nil))

    refute changeset.valid?
    assert {"can't be blank", _} = changeset.errors[:kid]

    KeyMaterialMatcher.refute_leak!("changeset params", changeset.params, [@sentinel])
    KeyMaterialMatcher.refute_leak!("changeset inspect", inspect(changeset), [@sentinel])

    record = Ecto.Changeset.apply_changes(changeset)
    KeyMaterialMatcher.refute_leak!("record inspect", inspect(record), [@sentinel])
  end

  test "the column is still written as a change" do
    changeset = SigningKeyRecord.changeset(%SigningKeyRecord{}, key())

    assert changeset.valid?
    assert changeset.changes.private_jwk_encrypted == @envelope
  end

  test "a nil private column leaves no change" do
    changeset = SigningKeyRecord.changeset(%SigningKeyRecord{}, key(private_jwk_encrypted: nil))

    refute Map.has_key?(changeset.changes, :private_jwk_encrypted)
  end

  test "publish_key round-trips the sealed bytes unchanged" do
    assert {:ok, stored} = Repository.publish_key(key())
    assert stored.private_jwk_encrypted == @envelope

    assert {:ok, fetched} = Repository.fetch_signing_key_by_id(stored.id)
    assert fetched.private_jwk_encrypted == @envelope
  end
end
