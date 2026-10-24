defmodule Lockspire.Integration.ClientLifetimeSelectedStoreTest do
  use Lockspire.TokenExchangeCase

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Admin.Clients
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.InitialAccessTokenRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  test "configured stores own registration and routed management lifecycle" do
    preserve_store_config()
    Process.put(:selected_store_test_owner, self())

    assert {:ok, _policy} =
             Repository.put_server_policy(
               Lockspire.Test.Fixtures.DcrFixtures.server_policy(%{registration_policy: :open})
             )

    Application.put_env(
      :lockspire,
      :client_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedClientStore
    )

    Application.put_env(
      :lockspire,
      :transaction_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedTransactionStore
    )

    registration =
      build_conn(:post, "/register", Lockspire.Test.Fixtures.DcrFixtures.valid_metadata())
      |> dispatch_registration()

    assert registration.status == 201
    registration_response = Jason.decode!(registration.resp_body)
    client_id = registration_response["client_id"]
    rat = registration_response["registration_access_token"]

    assert_received {:selected_store, :register_client, registered_id}
                    when registered_id == client_id

    assert_received {:selected_store, :transact}

    get_conn =
      build_conn(:get, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch_registration()

    assert get_conn.status == 200
    assert_received {:selected_store, :get_client_by_rat, _hash}
    assert_received {:selected_store, :lock_clients, [locked_id]} when locked_id == client_id
    assert_received {:selected_store, :transact}

    update_conn =
      build_conn(
        :put,
        "/register/#{client_id}",
        Lockspire.Test.Fixtures.DcrFixtures.valid_metadata() |> Map.put("client_id", client_id)
      )
      |> put_req_header("authorization", "Bearer #{rat}")
      |> dispatch_registration()

    assert update_conn.status == 200
    updated = Jason.decode!(update_conn.resp_body)
    assert_received {:selected_store, :replace_client_registration}
    assert_received {:selected_store, :transact}

    delete_conn =
      build_conn(:delete, "/register/#{client_id}")
      |> put_req_header("authorization", "Bearer #{updated["registration_access_token"]}")
      |> dispatch_registration()

    assert delete_conn.status == 204
    assert_received {:selected_store, :set_client_active}
    assert_received {:selected_store, :transact}
  end

  test "selected secret rotation and host recovery use configured callbacks" do
    install_selected_stores()
    enable_registration()
    registered = register_dcr_client()
    client_id = registered["client_id"]
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    assert {:ok, original} = Repository.fetch_client_by_id(client_id)

    assert {:ok, %{client: rotated, client_secret: plaintext}} =
             Clients.rotate_client_secret(client_id,
               now: now,
               actor: %{type: :operator, id: "selected-store-test"}
             )

    assert is_binary(plaintext)
    assert rotated.client_secret_hash != original.client_secret_hash
    assert_received {:selected_store, :rotate_client_secret}
    assert_received {:selected_store, :transact}

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(row in ClientRecord, where: row.client_id == ^client_id),
               set: [registration_access_token_expires_at: DateTime.add(now, -1, :second)]
             )

    assert {:ok, recovery_snapshot} = Repository.fetch_client_by_id(client_id)

    assert {:ok, recovery_token, recovered} =
             RegistrationManagement.rotate_registration_access_token(recovery_snapshot, now: now)

    assert is_binary(recovery_token)

    assert recovered.registration_access_token_hash !=
             recovery_snapshot.registration_access_token_hash

    assert_received {:selected_store, :lock_clients, [locked_id]} when locked_id == client_id
    assert_received {:selected_store, :rotate_registration_access_token}
    assert_received {:selected_store, :transact}
  end

  test "late audit failure rolls selected DCR replacement back durably" do
    install_selected_stores()
    enable_registration()
    registered = register_dcr_client()
    client_id = registered["client_id"]
    before = client_row(client_id)
    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)
    token_count = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    Process.put(:selected_store_fail_replace_audit, true)

    update_conn =
      build_conn(
        :put,
        "/register/#{client_id}",
        Lockspire.Test.Fixtures.DcrFixtures.valid_metadata() |> Map.put("client_id", client_id)
      )
      |> put_req_header("authorization", "Bearer #{registered["registration_access_token"]}")
      |> dispatch_registration()

    Process.delete(:selected_store_fail_replace_audit)
    assert update_conn.status == 500
    assert Jason.decode!(update_conn.resp_body) == %{"error" => "server_error"}
    assert client_row(client_id) == before
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == token_count
    assert_received {:selected_store, :replace_client_registration}
    assert_received {:selected_store, :transact}
  end

  test "host recovery rejects an unknown lifetime version without changing the row" do
    install_selected_stores()
    enable_registration()
    registered = register_dcr_client()
    client_id = registered["client_id"]

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(row in ClientRecord, where: row.client_id == ^client_id),
               set: [lifetime_version: 7]
             )

    assert {:ok, snapshot} = Repository.fetch_client_by_id(client_id)
    before = client_row(client_id)

    assert {:error, %Registration.Error{code: :server_error}} =
             RegistrationManagement.rotate_registration_access_token(snapshot,
               now: DateTime.utc_now() |> DateTime.truncate(:second)
             )

    assert client_row(client_id) == before
    refute_received {:selected_store, :rotate_registration_access_token}
  end

  test "invalid selected composition fails before consuming an initial access token" do
    preserve_store_config()
    Application.put_env(:lockspire, :client_store, :missing_store)

    {plaintext, initial_token} =
      Lockspire.Test.Fixtures.InitialAccessTokenFixtures.persist_with_plaintext(%{})

    request = %{
      metadata: Lockspire.Test.Fixtures.DcrFixtures.valid_metadata(),
      server_policy:
        Lockspire.Test.Fixtures.DcrFixtures.server_policy(%{
          registration_policy: :initial_access_token
        }),
      source: %{ip: "127.0.0.1", user_agent: "selected-store-test"},
      iat: plaintext
    }

    assert {:error, %Registration.Error{}} = Registration.register(request)
    assert is_nil(Lockspire.TestRepo.get!(InitialAccessTokenRecord, initial_token.id).used_at)
  end

  defp dispatch_registration(conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))
  end

  defp install_selected_stores do
    preserve_store_config()
    Process.put(:selected_store_test_owner, self())

    Application.put_env(
      :lockspire,
      :client_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedClientStore
    )

    Application.put_env(
      :lockspire,
      :transaction_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedTransactionStore
    )
  end

  defp enable_registration do
    assert {:ok, _policy} =
             Repository.put_server_policy(
               Lockspire.Test.Fixtures.DcrFixtures.server_policy(%{registration_policy: :open})
             )
  end

  defp register_dcr_client do
    conn =
      build_conn(:post, "/register", Lockspire.Test.Fixtures.DcrFixtures.valid_metadata())
      |> dispatch_registration()

    assert conn.status == 201
    Jason.decode!(conn.resp_body)
  end

  defp client_row(client_id),
    do: Lockspire.TestRepo.get_by!(ClientRecord, client_id: client_id)

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

    Application.put_env(
      :lockspire,
      :client_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedClientStore
    )

    Application.put_env(
      :lockspire,
      :transaction_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedTransactionStore
    )

    conn = token_request(client, raw_code)

    assert conn.status == 200, conn.resp_body

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

    Application.put_env(
      :lockspire,
      :client_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.MismatchedClientStore
    )

    Application.put_env(
      :lockspire,
      :transaction_store,
      Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedTransactionStore
    )

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

    def register_client(client) do
      send(
        Process.get(:selected_store_test_owner),
        {:selected_store, :register_client, client.client_id}
      )

      Lockspire.Storage.Ecto.Repository.register_client(client)
    end

    def get_client_by_registration_access_token_hash(hash) do
      send(Process.get(:selected_store_test_owner), {:selected_store, :get_client_by_rat, hash})
      Lockspire.Storage.Ecto.Repository.get_client_by_registration_access_token_hash(hash)
    end

    def replace_client_registration(client, replacement, rat_hash, audit_attrs) do
      send(
        Process.get(:selected_store_test_owner),
        {:selected_store, :replace_client_registration}
      )

      audit_attrs =
        if Process.get(:selected_store_fail_replace_audit),
          do: Map.put(audit_attrs, :action, nil),
          else: audit_attrs

      Lockspire.Storage.Ecto.Repository.replace_client_registration(
        client,
        replacement,
        rat_hash,
        audit_attrs
      )
    end

    def rotate_registration_access_token(client, rat_hash, audit_attrs) do
      send(
        Process.get(:selected_store_test_owner),
        {:selected_store, :rotate_registration_access_token}
      )

      Lockspire.Storage.Ecto.Repository.rotate_registration_access_token(
        client,
        rat_hash,
        audit_attrs
      )
    end

    def rotate_client_secret(client, hash, encrypted_verifier, rotated_at) do
      send(Process.get(:selected_store_test_owner), {:selected_store, :rotate_client_secret})

      Lockspire.Storage.Ecto.Repository.rotate_client_secret(
        client,
        hash,
        encrypted_verifier,
        rotated_at
      )
    end

    def set_client_active(client, active, attrs) do
      send(Process.get(:selected_store_test_owner), {:selected_store, :set_client_active})
      Lockspire.Storage.Ecto.Repository.set_client_active(client, active, attrs)
    end
  end

  defmodule SelectedTransactionStore do
    def transaction_authority do
      authority = Lockspire.Storage.Ecto.Repository.transaction_authority()

      %{
        authority
        | participants:
            authority.participants
            |> Map.put(
              :client_store,
              Lockspire.Integration.ClientLifetimeSelectedStoreTest.SelectedClientStore
            )
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
