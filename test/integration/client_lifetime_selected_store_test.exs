defmodule Lockspire.Integration.ClientLifetimeSelectedStoreTest do
  use Lockspire.TokenExchangeCase

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  setup do
    client =
      create_public_client("selected-store-#{System.unique_integer([:positive])}", [
        "authorization_code"
      ])

    {:ok, client} = Repository.update_client(client, %{access_token_format: :opaque})
    raw_code = "selected-code-#{System.unique_integer([:positive])}"

    {:ok, code} =
      create_authorization_code(client,
        raw_code: raw_code,
        code_verifier: "selected-store-verifier"
      )

    %{client: client, code: code, raw_code: raw_code}
  end

  test "configured store callbacks participate in production token issuance", %{
    client: client,
    code: code,
    raw_code: raw_code
  } do
    preserve_store_config()
    Process.put(:selected_store_test_owner, self())
    Application.put_env(:lockspire, :client_store, SelectedClientStore)
    Application.put_env(:lockspire, :transaction_store, SelectedTransactionStore)

    conn = token_request(client, raw_code)

    assert conn.status == 200

    assert_received {:selected_store, :fetch_client_by_id, client_id}
                    when client_id == client.client_id

    assert_received {:selected_store, :lock_clients, _ids}
    assert_received {:selected_store, :transact}

    response = Jason.decode!(conn.resp_body)
    assert is_binary(response["access_token"])
    assert {:ok, redeemed} = Repository.fetch_authorization_code(code.token_hash)
    assert not is_nil(redeemed.redeemed_at)
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 2
  end

  test "an invalid configured store fails closed without consuming its code", %{
    client: client,
    code: code,
    raw_code: raw_code
  } do
    preserve_store_config()
    Application.put_env(:lockspire, :client_store, :missing_store)
    previous_logger_level = Logger.level()
    Logger.configure(level: :warning)
    on_exit(fn -> Logger.configure(level: previous_logger_level) end)

    conn = token_request(client, raw_code)

    assert conn.status == 500
    assert Jason.decode!(conn.resp_body)["error"] == "server_error"
    assert {:ok, persisted} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(persisted.redeemed_at)
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 1
  end

  test "a client store with a different authority fails closed without consuming its code", %{
    client: client,
    code: code,
    raw_code: raw_code
  } do
    preserve_store_config()
    Application.put_env(:lockspire, :client_store, MismatchedClientStore)
    Application.put_env(:lockspire, :transaction_store, SelectedTransactionStore)

    conn = token_request(client, raw_code)

    assert conn.status == 500
    assert Jason.decode!(conn.resp_body)["error"] == "server_error"
    assert {:ok, persisted} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(persisted.redeemed_at)
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 1
  end

  defp token_request(client, raw_code) do
    build_conn(:post, "/token", %{
      "grant_type" => "authorization_code",
      "client_id" => client.client_id,
      "code" => raw_code,
      "redirect_uri" => "https://client.example.com/callback",
      "code_verifier" => "selected-store-verifier"
    })
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp preserve_store_config do
    original = %{
      client_store: Application.fetch_env(:lockspire, :client_store),
      transaction_store: Application.fetch_env(:lockspire, :transaction_store)
    }

    on_exit(fn ->
      Enum.each(original, fn
        {key, {:ok, value}} -> Application.put_env(:lockspire, key, value)
        {key, :error} -> Application.delete_env(:lockspire, key)
      end)
    end)
  end

  defmodule SelectedClientStore do
    def lifetime_contract do
      %{
        version: 1,
        transaction_authority:
          Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedTransactionStore.transaction_authority()
      }
    end

    def fetch_client_by_id(client_id) do
      send(
        Process.get(:selected_store_test_owner),
        {:selected_store, :fetch_client_by_id, client_id}
      )

      Lockspire.Storage.Ecto.Repository.fetch_client_by_id(client_id)
    end

    def lock_clients(ids) do
      send(Process.get(:selected_store_test_owner), {:selected_store, :lock_clients, ids})
      Lockspire.Storage.Ecto.Repository.lock_clients(ids)
    end
  end

  defmodule SelectedTransactionStore do
    def transaction_authority do
      authority = Lockspire.Storage.Ecto.Repository.transaction_authority()

      %{
        authority
        | participants:
            authority.participants
            |> Map.put(:client_store, SelectedClientStore)
            |> Map.put(:transaction_store, __MODULE__)
      }
    end

    def transact(fun) do
      send(Process.get(:selected_store_test_owner), {:selected_store, :transact})
      Lockspire.Storage.Ecto.Repository.transact(fun)
    end

    def rollback(reason), do: Lockspire.Storage.Ecto.Repository.rollback(reason)
  end

  defmodule MismatchedClientStore do
    def lifetime_contract do
      authority =
        Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedTransactionStore.transaction_authority()

      %{version: 1, transaction_authority: %{authority | identity: {:different_repo, :wrong}}}
    end

    def fetch_client_by_id(client_id),
      do: Lockspire.Storage.Ecto.Repository.fetch_client_by_id(client_id)

    def lock_clients(ids),
      do: Lockspire.Storage.Ecto.Repository.lock_clients(ids)
  end
end
