defmodule Lockspire.Storage.RepositoryConcurrencyTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Lockspire.TokenExchangeCase

  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  setup_all do
    unless Process.whereis(Lockspire.TestRepo) do
      start_supervised!(Lockspire.TestRepo)
    end

    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  test "concurrent authorization-code redemption has exactly one committed winner" do
    suffix = System.unique_integer([:positive])
    raw_code = "atomic-concurrent-code-#{suffix}"
    client_id = "atomic-concurrent-client-#{suffix}"

    {client, authorization_code} =
      unboxed(fn ->
        {:ok, client} = create_client(client_id, :client_secret_basic, "atomic-secret")

        {:ok, authorization_code} =
          create_authorization_code(client,
            raw_code: raw_code,
            code_verifier: "atomic-concurrent-verifier"
          )

        {client, authorization_code}
      end)

    parent = self()

    tasks =
      for contender <- 1..10 do
        Task.async(fn ->
          send(parent, {:ready_to_redeem, self()})

          receive do
            :redeem ->
              unboxed(fn ->
                Repository.redeem_authorization_code(
                  TokenFormatter.hash_token(raw_code),
                  DateTime.utc_now(),
                  access_token_for(client, authorization_code, suffix, contender)
                )
              end)
          end
        end)
      end

    for _ <- tasks do
      assert_receive {:ready_to_redeem, pid}, 5_000
      send(pid, :redeem)
    end

    results = Task.await_many(tasks, 5_000)

    assert Enum.count(results, &match?({:ok, %{authorization_code: _, access_token: _}}, &1)) == 1,
           "expected one successful redemption, got: #{inspect(results)}"

    assert Enum.count(results, &match?({:error, :already_redeemed}, &1)) == 9,
           "expected nine rejected contenders, got: #{inspect(results)}"

    assert {:ok, %{redeemed_at: %DateTime{}}} =
             unboxed(fn ->
               Repository.fetch_authorization_code(TokenFormatter.hash_token(raw_code))
             end)

    unboxed(fn ->
      Lockspire.TestRepo.delete_all(
        from(token in TokenRecord,
          where: token.client_id == ^client_id
        )
      )

      Lockspire.TestRepo.delete_all(
        from(interaction in InteractionRecord,
          where: interaction.client_id == ^client_id
        )
      )

      Lockspire.TestRepo.delete_all(
        from(client in ClientRecord,
          where: client.client_id == ^client_id
        )
      )
    end)
  end

  defp access_token_for(client, authorization_code, suffix, contender) do
    now = DateTime.utc_now()

    %Token{
      token_hash: TokenFormatter.hash_token("atomic-concurrent-access-#{suffix}-#{contender}"),
      token_type: :access_token,
      client_id: client.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      scopes: authorization_code.scopes,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second)
    }
  end

  defp unboxed(fun), do: Ecto.Adapters.SQL.Sandbox.unboxed_run(Lockspire.TestRepo, fun)
end
