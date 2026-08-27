defmodule Lockspire.Storage.RepositoryAtomicityTest do
  use Lockspire.TokenExchangeCase, async: false

  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  @moduletag :integration

  test "authorization-code redemption has one DB-backed winner" do
    {:ok, client} = create_client("atomic-code-client", :client_secret_basic, "atomic-secret")

    assert {:ok, authorization_code} =
             create_authorization_code(client,
               raw_code: "atomic-code",
               code_verifier: "atomic-verifier"
             )

    access_token = %Token{
      token_hash: TokenFormatter.hash_token("atomic-access-token"),
      token_type: :access_token,
      client_id: client.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      scopes: authorization_code.scopes,
      issued_at: DateTime.utc_now(),
      expires_at: DateTime.add(DateTime.utc_now(), 300, :second)
    }

    assert {:ok, %{authorization_code: redeemed, access_token: persisted}} =
             Repository.redeem_authorization_code(
               TokenFormatter.hash_token("atomic-code"),
               DateTime.utc_now(),
               access_token
             )

    assert redeemed.redeemed_at
    assert persisted.token_hash == access_token.token_hash

    assert {:error, :already_redeemed} =
             Repository.redeem_authorization_code(
               TokenFormatter.hash_token("atomic-code"),
               DateTime.utc_now(),
               access_token
             )
  end
end
