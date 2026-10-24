defmodule Lockspire.Integration.ClientLifetimeInteractionsTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Admin.Clients
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures

  @issued_at DateTime.from_unix!(100)
  @app_deadline DateTime.from_unix!(160)
  @secret_deadline DateTime.from_unix!(110)
  @management_deadline DateTime.from_unix!(120)

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

  defp policy(app_seconds, secret_seconds, management_seconds) do
    DcrFixtures.server_policy(%{
      dcr_default_client_lifetime_seconds: app_seconds,
      dcr_default_client_secret_lifetime_seconds: secret_seconds,
      dcr_default_registration_access_token_lifetime_seconds: management_seconds
    })
  end

  defp register_at(policy, attrs \\ %{}) do
    metadata = Map.merge(DcrFixtures.valid_metadata(), attrs)

    request =
      DcrFixtures.register_request(server_policy: policy, metadata: metadata)
      |> Map.put(:now, @issued_at)

    assert {:ok, %Registration.Success{} = success} = Registration.register(request)
    success
  end

  defp persist_deadlines!(%Client{} = client, app, secret, management) do
    assert {:ok, updated} =
             Repository.update_client(client, %{
               lifetime_version: 1,
               client_expires_at: app,
               client_secret_expires_at: secret,
               registration_access_token_expires_at: management
             })

    updated
  end

  test "C-POL-01 C-POL-07: replacement events renew only their own snapshot" do
    initial_policy = policy(60, 10, 20)
    assert {:ok, _} = Repository.put_server_policy(initial_policy)
    registered = register_at(initial_policy)
    client_id = registered.client.client_id

    assert DateTime.compare(registered.client.client_expires_at, @app_deadline) == :eq
    assert DateTime.compare(registered.client.client_secret_expires_at, @secret_deadline) == :eq

    assert DateTime.compare(
             registered.client.registration_access_token_expires_at,
             @management_deadline
           ) == :eq

    replacement_policy = policy(1, 30, 40)
    assert {:ok, _} = Repository.put_server_policy(replacement_policy)

    assert {:ok, %{client: rotated}} =
             Clients.rotate_client_secret(client_id, %{
               now: fn -> DateTime.from_unix!(107) end,
               actor: %{type: :operator, id: "lifetime-interaction-test"}
             })

    assert DateTime.compare(rotated.client_expires_at, @app_deadline) == :eq
    assert DateTime.compare(rotated.client_secret_expires_at, DateTime.from_unix!(137)) == :eq

    assert DateTime.compare(
             rotated.registration_access_token_expires_at,
             @management_deadline
           ) == :eq

    assert {:ok, current} = Repository.fetch_client_by_id(client_id)

    assert {:ok, _recovered_token, recovered} =
             RegistrationManagement.rotate_registration_access_token(current,
               now: DateTime.from_unix!(125)
             )

    assert DateTime.compare(recovered.client_expires_at, @app_deadline) == :eq
    assert DateTime.compare(recovered.client_secret_expires_at, DateTime.from_unix!(137)) == :eq

    assert DateTime.compare(
             recovered.registration_access_token_expires_at,
             DateTime.from_unix!(165)
           ) == :eq
  end

  test "C-APP-14 C-APP-15 C-APP-16 C-MGMT-03 C-MGMT-04 C-MGMT-09: independent app and management gates" do
    server_policy = policy(60, 10, 40)
    assert {:ok, _} = Repository.put_server_policy(server_policy)
    registered = register_at(server_policy)

    original =
      persist_deadlines!(registered.client, @app_deadline, @secret_deadline, @management_deadline)

    assert {:ok, _new_token, recovered} =
             RegistrationManagement.rotate_registration_access_token(original,
               now: DateTime.from_unix!(125)
             )

    assert {:ok, read_client} =
             RegistrationManagement.read(recovered.client_id, recovered,
               now: DateTime.from_unix!(160)
             )

    assert DateTime.compare(read_client.client_expires_at, @app_deadline) == :eq
    assert DateTime.compare(read_client.client_secret_expires_at, @secret_deadline) == :eq

    assert {:error, %Registration.Error{code: :registration_expired}} =
             RegistrationManagement.update(recovered.client_id, %{
               metadata: Map.put(DcrFixtures.valid_metadata(), "client_id", recovered.client_id),
               server_policy: server_policy,
               client: recovered,
               now: DateTime.from_unix!(160)
             })

    assert {:ok, unchanged} = Repository.fetch_client_by_id(recovered.client_id)
    assert unchanged == recovered

    assert :ok =
             RegistrationManagement.delete(recovered.client_id, recovered,
               now: DateTime.from_unix!(160)
             )

    assert {:ok, deleted} = Repository.fetch_client_by_id(recovered.client_id)
    refute deleted.active

    disabled_case = register_at(server_policy)

    disabled =
      persist_deadlines!(
        disabled_case.client,
        @app_deadline,
        @secret_deadline,
        @management_deadline
      )

    assert {:ok, _token, current} =
             RegistrationManagement.rotate_registration_access_token(disabled,
               now: DateTime.from_unix!(125)
             )

    assert {:ok, _} = Repository.set_client_active(current, false, %{})
    assert {:ok, disabled_row} = Repository.fetch_client_by_id(current.client_id)

    assert {:error, :invalid_token} =
             RegistrationManagement.read(disabled.client_id, disabled_row,
               now: DateTime.from_unix!(150)
             )

    assert {:ok, enabled} = Repository.set_client_active(disabled_row, true, %{})
    assert enabled.active
    assert DateTime.compare(enabled.client_expires_at, @app_deadline) == :eq

    assert {:ok, _expired_but_enabled} =
             RegistrationManagement.read(enabled.client_id, enabled,
               now: DateTime.from_unix!(160)
             )
  end
end
