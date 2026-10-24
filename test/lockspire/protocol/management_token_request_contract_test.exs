defmodule Lockspire.Protocol.ManagementTokenRequestContractTest do
  use ExUnit.Case, async: false

  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    server_policy = DcrFixtures.server_policy(%{registration_policy: :open})
    Repository.put_server_policy(server_policy)

    {:ok, success} =
      Registration.register(%{
        metadata: DcrFixtures.valid_metadata(),
        iat: nil,
        server_policy: server_policy,
        source: %{ip: "127.0.0.1"}
      })

    %{
      client: success.client,
      client_id: success.client.client_id,
      client_secret: success.client_secret_plaintext,
      server_policy: server_policy
    }
  end

  defp update_metadata(metadata, client_id),
    do: Map.put(metadata, "client_id", client_id)

  test "rejects registration_access_token in replacement metadata without rotating authority", %{
    client: client,
    client_id: client_id,
    server_policy: server_policy
  } do
    {:ok, before} = Repository.fetch_client_by_id(client_id)
    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    for {field, value} <- [
          {"registration_access_token", "forged-management-token"},
          {"registration_client_uri", "https://attacker.example/register"},
          {"client_secret_expires_at", 1},
          {"client_id_issued_at", 1}
        ] do
      metadata =
        DcrFixtures.valid_metadata()
        |> update_metadata(client_id)
        |> Map.put(field, value)

      assert {:error, %Registration.Error{code: :invalid_client_metadata, field: error_field}} =
               RegistrationManagement.update(client_id, %{
                 metadata: metadata,
                 server_policy: server_policy,
                 client: client
               })

      assert Atom.to_string(error_field) == field
      assert {:ok, ^before} = Repository.fetch_client_by_id(client_id)
      assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count
    end
  end

  test "an included client_secret must match current material and never rotates it", %{
    client: client,
    client_id: client_id,
    client_secret: client_secret,
    server_policy: server_policy
  } do
    wrong_metadata =
      DcrFixtures.valid_metadata()
      |> update_metadata(client_id)
      |> Map.put("client_secret", "not-the-current-secret")

    assert {:error, %Registration.Error{code: :invalid_client_metadata, field: :client_secret}} =
             RegistrationManagement.update(client_id, %{
               metadata: wrong_metadata,
               server_policy: server_policy,
               client: client
             })

    matching_metadata =
      DcrFixtures.valid_metadata()
      |> update_metadata(client_id)
      |> Map.put("client_secret", client_secret)

    assert {:ok, success} =
             RegistrationManagement.update(client_id, %{
               metadata: matching_metadata,
               server_policy: server_policy,
               client: client
             })

    assert success.client.client_secret_hash == client.client_secret_hash
    assert success.client.client_secret_expires_at == client.client_secret_expires_at
  end

  @tag :management_request_red
  test "registration intake rejects server-owned lifecycle extensions", %{
    server_policy: server_policy
  } do
    metadata = Map.put(DcrFixtures.valid_metadata(), "lockspire_client_expires_at", 1)

    assert {:error,
            %Registration.Error{
              code: :invalid_client_metadata,
              field: :lockspire_client_expires_at
            }} =
             Registration.register(%{
               metadata: metadata,
               iat: nil,
               server_policy: server_policy,
               source: %{ip: "127.0.0.1"}
             })
  end

  test "lifecycle extensions are server-owned and intake cannot set them", %{
    client: client,
    client_id: client_id,
    server_policy: server_policy
  } do
    {:ok, app_deadline} = Lockspire.Domain.Client.effective_app_deadline(client)
    {:ok, management_deadline} = Lockspire.Domain.Client.effective_management_deadline(client)
    app_value = if app_deadline, do: DateTime.to_unix(app_deadline), else: 0
    management_value = if management_deadline, do: DateTime.to_unix(management_deadline), else: 0

    matching =
      DcrFixtures.valid_metadata()
      |> update_metadata(client_id)
      |> Map.put("lockspire_client_expires_at", app_value)
      |> Map.put("lockspire_registration_access_token_expires_at", management_value)

    assert {:ok, _success} =
             RegistrationManagement.update(client_id, %{
               metadata: matching,
               server_policy: server_policy,
               client: client
             })

    for extension <- [
          "lockspire_client_expires_at",
          "lockspire_registration_access_token_expires_at"
        ] do
      before_count = Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.ClientRecord, :count)

      assert {:error, %Registration.Error{code: :invalid_client_metadata, field: field}} =
               Registration.register(%{
                 metadata: Map.put(DcrFixtures.valid_metadata(), extension, 1),
                 iat: nil,
                 server_policy: server_policy,
                 source: %{ip: "127.0.0.1"}
               })

      assert Atom.to_string(field) == extension

      assert Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.ClientRecord, :count) ==
               before_count
    end
  end

  test "rejected replacements leave the client and audit record unchanged", %{
    client: client,
    client_id: client_id,
    server_policy: server_policy
  } do
    {:ok, before} = Repository.fetch_client_by_id(client_id)
    audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    for metadata <- [
          Map.delete(DcrFixtures.valid_metadata(), "client_id"),
          DcrFixtures.valid_metadata() |> update_metadata("different-client-id"),
          DcrFixtures.valid_metadata()
          |> update_metadata(client_id)
          |> Map.put("lockspire_client_expires_at", "0"),
          DcrFixtures.valid_metadata()
          |> update_metadata(client_id)
          |> Map.put("lockspire_registration_access_token_expires_at", 0)
        ] do
      assert {:error, %Registration.Error{code: :invalid_client_metadata}} =
               RegistrationManagement.update(client_id, %{
                 metadata: metadata,
                 server_policy: server_policy,
                 client: client
               })

      assert {:ok, ^before} = Repository.fetch_client_by_id(client_id)
      assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == audit_count
    end
  end
end
