defmodule Lockspire.Security.SealedSeedersTest do
  use Lockspire.DataCase, async: false

  alias Lockspire.Protocol.PrivateJwk
  alias Lockspire.SeedingHelpers
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TokenExchangeCase

  setup_all do
    unless Process.whereis(Lockspire.TestRepo), do: start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  test "SeedingHelpers.seed_signing_key/1 writes an envelope that decodes" do
    key = SeedingHelpers.seed_signing_key()

    assert {:ok, row} = Repository.fetch_signing_key_by_id(key.id)
    assert KeyEncryption.classify(row.private_jwk_encrypted) == :envelope
    assert {:ok, %{"kid" => kid}} = PrivateJwk.decode(row)
    assert kid == row.kid
  end

  test "TokenExchangeCase.publish_signing_key/1 writes an envelope that decodes" do
    assert {:ok, key} = TokenExchangeCase.publish_signing_key("sealed-seeder-kid")

    assert {:ok, row} = Repository.fetch_signing_key_by_id(key.id)
    assert KeyEncryption.classify(row.private_jwk_encrypted) == :envelope
    assert {:ok, %{"kid" => "sealed-seeder-kid"}} = PrivateJwk.decode(row)
  end
end
