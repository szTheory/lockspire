defmodule Lockspire.Storage.ManagementTokenMutationRaceTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Admin.Clients
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Test.Fixtures.DcrFixtures

  @moduletag :integration
  @moduletag :postgres_race

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Sandbox.checkout(Lockspire.TestRepo)

    policy =
      DcrFixtures.server_policy(%{dcr_default_registration_access_token_lifetime_seconds: 90})

    {:ok, _} = Repository.put_server_policy(policy)
    %{policy: policy}
  end

  test "a waiting PUT rejects stale included secret material and preserves a committed secret rotation",
       %{policy: server_policy} do
    {client, token, secret} = committed_client("management-secret-reject")
    on_exit(fn -> cleanup(client.client_id) end)
    parent = self()
    at = decision_time()
    holder = secret_rotation_holder(client.client_id, parent, at, :secret_change)
    {holder_pid, holder_backend} = Race.await_session!(:secret_change)

    assert_receive {{:secret_rotation_clock_waiting, :secret_change}, ^holder_pid,
                    ^holder_backend},
                   5_000

    contender =
      Race.start_session(Lockspire.TestRepo, :stale_secret_put, parent, fn _ ->
        RegistrationManagement.update(client.client_id, %{
          client: client,
          server_policy: server_policy,
          now: at,
          metadata:
            metadata(client.client_id, "stale secret put") |> Map.put("client_secret", secret)
        })
      end)

    {_contender_pid, contender_backend} = Race.await_session!(:stale_secret_put)

    rotated_and_secret =
      try do
        Race.await_blocker!(Lockspire.TestRepo, contender_backend, holder_backend)
        Race.release(holder_pid, :rotate_secret)

        assert {:ok, %{client: rotated, client_secret: new_secret}} =
                 Race.await_task!(holder, 10_000)

        {rotated, new_secret}
      after
        Race.release(holder_pid, :rotate_secret)
      end

    assert {:error, %Registration.Error{code: :invalid_client_metadata, field: :client_secret}} =
             Race.await_task!(contender, 10_000)

    {_rotated, new_secret} = rotated_and_secret
    current = client!(client.client_id)
    assert Policy.verify_client_secret(current.client_secret_hash, new_secret)
    refute Policy.verify_client_secret(current.client_secret_hash, secret)
    assert RegistrationAccessToken.verify(current.registration_access_token_hash, token)
    assert audit_count(client.client_id, "dcr_management_updated") == 0
    assert token != ""
  end

  test "omitted secret material cannot overwrite the concurrently rotated secret", %{
    policy: server_policy
  } do
    {client, _token, old_secret} = committed_client("management-secret-preserve")
    on_exit(fn -> cleanup(client.client_id) end)
    parent = self()
    at = decision_time()
    holder = secret_rotation_holder(client.client_id, parent, at, :secret_preserve)
    {holder_pid, holder_backend} = Race.await_session!(:secret_preserve)

    assert_receive {{:secret_rotation_clock_waiting, :secret_preserve}, ^holder_pid,
                    ^holder_backend},
                   5_000

    contender =
      Race.start_session(Lockspire.TestRepo, :omitted_secret_put, parent, fn _ ->
        RegistrationManagement.update(client.client_id, %{
          client: client,
          server_policy: server_policy,
          now: at,
          metadata: metadata(client.client_id, "omitted secret put")
        })
      end)

    {_contender_pid, contender_backend} = Race.await_session!(:omitted_secret_put)

    rotated_and_secret =
      try do
        Race.await_blocker!(Lockspire.TestRepo, contender_backend, holder_backend)
        Race.release(holder_pid, :rotate_secret)

        assert {:ok, %{client: rotated, client_secret: new_secret}} =
                 Race.await_task!(holder, 10_000)

        {rotated, new_secret}
      after
        Race.release(holder_pid, :rotate_secret)
      end

    {rotated, new_secret} = rotated_and_secret

    assert {:ok, %RegistrationManagement.UpdateSuccess{client: updated}} =
             Race.await_task!(contender, 10_000)

    assert Policy.verify_client_secret(updated.client_secret_hash, new_secret)
    assert updated.client_secret_hash == rotated.client_secret_hash
    refute Policy.verify_client_secret(updated.client_secret_hash, old_secret)
    assert client!(client.client_id).client_secret_hash == rotated.client_secret_hash
  end

  test "host recovery after a confirmed wait preserves a committed secret rotation" do
    {client, _token, _secret} = committed_client("management-recovery-secret")
    on_exit(fn -> cleanup(client.client_id) end)
    parent = self()
    at = decision_time()
    holder = secret_rotation_holder(client.client_id, parent, at, :secret_recovery)
    {holder_pid, holder_backend} = Race.await_session!(:secret_recovery)

    assert_receive {{:secret_rotation_clock_waiting, :secret_recovery}, ^holder_pid,
                    ^holder_backend},
                   5_000

    recovery =
      Race.start_session(Lockspire.TestRepo, :recovery_after_secret, parent, fn _ ->
        RegistrationManagement.rotate_registration_access_token(client, now: at)
      end)

    {_recovery_pid, recovery_backend} = Race.await_session!(:recovery_after_secret)

    rotated_and_secret =
      try do
        Race.await_blocker!(Lockspire.TestRepo, recovery_backend, holder_backend)
        Race.release(holder_pid, :rotate_secret)

        assert {:ok, %{client: rotated, client_secret: new_secret}} =
                 Race.await_task!(holder, 10_000)

        {rotated, new_secret}
      after
        Race.release(holder_pid, :rotate_secret)
      end

    {rotated, new_secret} = rotated_and_secret
    assert {:ok, token, recovered} = Race.await_task!(recovery, 10_000)
    assert is_binary(token)
    assert recovered.client_secret_hash == rotated.client_secret_hash

    assert recovered.client_secret_jwt_verifier_encrypted ==
             rotated.client_secret_jwt_verifier_encrypted

    assert recovered.client_secret_expires_at == rotated.client_secret_expires_at
    assert Policy.verify_client_secret(recovered.client_secret_hash, new_secret)
    assert recovered.active
  end

  test "disablement that commits while PUT waits survives rejection, and host recovery never re-enables it",
       %{policy: server_policy} do
    for operation <- [:put, :recovery] do
      {client, _token, _secret} = committed_client("management-disable-#{operation}")
      on_exit(fn -> cleanup(client.client_id) end)
      parent = self()
      at = decision_time()
      holder = disable_holder(client.client_id, parent, operation)
      {holder_pid, holder_backend} = Race.await_session!({:disable_holder, operation})
      assert_receive {{:disable_locked, operation}, ^holder_pid}, 5_000

      contender =
        Race.start_session(Lockspire.TestRepo, {:disable_contender, operation}, parent, fn _ ->
          case operation do
            :put ->
              RegistrationManagement.update(client.client_id, %{
                client: client,
                server_policy: server_policy,
                now: at,
                metadata: metadata(client.client_id, "disabled contender")
              })

            :recovery ->
              RegistrationManagement.rotate_registration_access_token(client, now: at)
          end
        end)

      {_contender_pid, contender_backend} = Race.await_session!({:disable_contender, operation})

      try do
        Race.await_blocker!(Lockspire.TestRepo, contender_backend, holder_backend)
        Race.release(holder_pid, {:commit_disable, operation})
        assert {:ok, :disabled} = Race.await_task!(holder, 10_000)
      after
        Race.release(holder_pid, {:commit_disable, operation})
      end

      case operation do
        :put ->
          assert {:error, :invalid_token} = Race.await_task!(contender, 10_000)

        :recovery ->
          assert {:ok, _token, recovered} = Race.await_task!(contender, 10_000)
          refute recovered.active

          assert {:error, :invalid_token} =
                   unboxed(fn ->
                     RegistrationManagement.read(client.client_id, recovered, now: at)
                   end)
      end

      current = client!(client.client_id)
      refute current.active
      assert current.client_secret_hash == client.client_secret_hash
    end
  end

  test "contended write and audit failures roll back legacy promotion and disclose no token", %{
    policy: server_policy
  } do
    for operation <- [:put, :recovery], failure <- [:write, :audit] do
      {client, _token, _secret} = committed_client("management-fault-#{operation}-#{failure}")
      on_exit(fn -> cleanup(client.client_id) end)
      old = decision_time()
      advisory = DateTime.add(old, -20, :second)

      assert {1, _} =
               unboxed(fn ->
                 Lockspire.TestRepo.update_all(
                   from(row in ClientRecord, where: row.client_id == ^client.client_id),
                   set: [
                     lifetime_version: 0,
                     client_expires_at: advisory,
                     client_secret_expires_at: advisory,
                     registration_access_token_expires_at: advisory
                   ]
                 )
               end)

      {:ok, legacy} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
      install_failure_trigger(failure, client.client_id)
      on_exit(fn -> remove_failure_trigger(failure) end)
      parent = self()
      holder = committed_metadata_holder(client.client_id, parent, operation, failure)
      {holder_pid, holder_backend} = Race.await_session!({:mutation_holder, operation, failure})
      assert_receive {{:mutation_locked, operation, failure}, ^holder_pid}, 5_000

      contender =
        Race.start_session(
          Lockspire.TestRepo,
          {:mutation_contender, operation, failure},
          parent,
          fn _ ->
            case operation do
              :put ->
                RegistrationManagement.update(client.client_id, %{
                  client: legacy,
                  server_policy: server_policy,
                  now: old,
                  metadata: metadata(client.client_id, "fault target")
                })

              :recovery ->
                RegistrationManagement.rotate_registration_access_token(legacy, now: old)
            end
          end
        )

      {_contender_pid, contender_backend} =
        Race.await_session!({:mutation_contender, operation, failure})

      try do
        Race.await_blocker!(Lockspire.TestRepo, contender_backend, holder_backend)
        Race.release(holder_pid, {:commit_mutation, operation, failure})
        assert {:ok, :metadata_committed} = Race.await_task!(holder, 10_000)
      after
        Race.release(holder_pid, {:commit_mutation, operation, failure})
      end

      assert {:error, _reason} = Race.await_task!(contender, 10_000)
      current = client!(client.client_id)
      assert current.metadata == %{"committed_while_waiting" => true}
      assert current.registration_access_token_hash == legacy.registration_access_token_hash
      assert current.lifetime_version == 0
      assert DateTime.compare(current.client_expires_at, advisory) == :eq
      assert DateTime.compare(current.client_secret_expires_at, advisory) == :eq
      assert DateTime.compare(current.registration_access_token_expires_at, advisory) == :eq
      assert audit_count(client.client_id, "dcr_management_updated") == 0
      assert audit_count(client.client_id, "dcr_management_rat_rotated") == 0

      remove_failure_trigger(failure)
      {:ok, refreshed} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)

      retry =
        case operation do
          :put ->
            unboxed(fn ->
              RegistrationManagement.update(client.client_id, %{
                client: refreshed,
                server_policy: server_policy,
                now: DateTime.add(old, 1, :second),
                metadata: metadata(client.client_id, "fault retry")
              })
            end)

          :recovery ->
            unboxed(fn ->
              RegistrationManagement.rotate_registration_access_token(refreshed,
                now: DateTime.add(old, 1, :second)
              )
            end)
        end

      assert success_result?(operation, retry)
      assert client!(client.client_id).lifetime_version == 1
    end
  end

  defp committed_client(name) do
    unboxed(fn ->
      policy =
        DcrFixtures.server_policy(%{dcr_default_registration_access_token_lifetime_seconds: 90})

      {:ok, _} = Repository.put_server_policy(policy)

      {:ok,
       %Registration.Success{
         client: client,
         client_secret_plaintext: secret,
         registration_access_token_plaintext: token
       }} =
        Registration.register(%{
          metadata: DcrFixtures.valid_metadata() |> Map.put("client_name", name),
          iat: nil,
          server_policy: policy,
          source: %{ip: "127.0.0.1"}
        })

      {client, token, secret}
    end)
  end

  defp secret_rotation_holder(client_id, owner, at, label) do
    Race.start_session(Lockspire.TestRepo, label, owner, fn _ ->
      Clients.rotate_client_secret(client_id, %{
        actor: %{type: :operator, id: "management-race"},
        now: fn ->
          backend = Race.backend_pid!(Lockspire.TestRepo)
          send(owner, {{:secret_rotation_clock_waiting, label}, self(), backend})

          receive do
            :rotate_secret -> at
          after
            5_000 -> raise "secret rotation release timed out"
          end
        end
      })
    end)
  end

  defp disable_holder(client_id, owner, operation) do
    Race.start_session(Lockspire.TestRepo, {:disable_holder, operation}, owner, fn _ ->
      Repository.transact(fn ->
        {:ok, [_]} = Repository.lock_clients([client_id])
        send(owner, {{:disable_locked, operation}, self()})

        receive do
          {:commit_disable, ^operation} ->
            Lockspire.TestRepo.update_all(
              from(row in ClientRecord, where: row.client_id == ^client_id),
              set: [active: false, disabled_at: decision_time(), disabled_by: "race-test"]
            )

            {:ok, :disabled}
        after
          5_000 -> {:error, :holder_release_timeout}
        end
      end)
    end)
  end

  defp committed_metadata_holder(client_id, owner, operation, failure) do
    Race.start_session(Lockspire.TestRepo, {:mutation_holder, operation, failure}, owner, fn _ ->
      Repository.transact(fn ->
        {:ok, [_]} = Repository.lock_clients([client_id])
        send(owner, {{:mutation_locked, operation, failure}, self()})

        receive do
          {:commit_mutation, ^operation, ^failure} ->
            Lockspire.TestRepo.update_all(
              from(row in ClientRecord, where: row.client_id == ^client_id),
              set: [metadata: %{"committed_while_waiting" => true}]
            )

            {:ok, :metadata_committed}
        after
          5_000 -> {:error, :holder_release_timeout}
        end
      end)
    end)
  end

  defp install_failure_trigger(:write, client_id) do
    unboxed(fn ->
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lsp_mgmt_write_failure ON lockspire_clients"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lsp_mgmt_reject_write()")

      Lockspire.TestRepo.query!("""
      CREATE FUNCTION lsp_mgmt_reject_write() RETURNS trigger AS $$
      BEGIN
        IF NEW.client_id = '#{client_id}' AND NEW.registration_access_token_hash IS DISTINCT FROM OLD.registration_access_token_hash THEN
          RAISE EXCEPTION '165-05 injected management write failure';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """)

      Lockspire.TestRepo.query!(
        "CREATE TRIGGER lsp_mgmt_write_failure BEFORE UPDATE ON lockspire_clients FOR EACH ROW EXECUTE FUNCTION lsp_mgmt_reject_write()"
      )
    end)
  end

  defp install_failure_trigger(:audit, client_id) do
    unboxed(fn ->
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lsp_mgmt_audit_failure ON lockspire_audit_events"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lsp_mgmt_reject_audit()")

      Lockspire.TestRepo.query!("""
      CREATE FUNCTION lsp_mgmt_reject_audit() RETURNS trigger AS $$
      BEGIN
        IF NEW.resource_id = '#{client_id}' AND NEW.action IN ('dcr_management_updated', 'dcr_management_rat_rotated') THEN
          RAISE EXCEPTION '165-05 injected management audit failure';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """)

      Lockspire.TestRepo.query!(
        "CREATE TRIGGER lsp_mgmt_audit_failure BEFORE INSERT ON lockspire_audit_events FOR EACH ROW EXECUTE FUNCTION lsp_mgmt_reject_audit()"
      )
    end)
  end

  defp remove_failure_trigger(:write) do
    unboxed(fn ->
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lsp_mgmt_write_failure ON lockspire_clients"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lsp_mgmt_reject_write()")
    end)
  end

  defp remove_failure_trigger(:audit) do
    unboxed(fn ->
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lsp_mgmt_audit_failure ON lockspire_audit_events"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lsp_mgmt_reject_audit()")
    end)
  end

  defp success_result?(:put, {:ok, %RegistrationManagement.UpdateSuccess{}}), do: true
  defp success_result?(:recovery, {:ok, token, %Client{}}) when is_binary(token), do: true
  defp success_result?(_, _), do: false

  defp metadata(client_id, name),
    do:
      DcrFixtures.valid_metadata()
      |> Map.put("client_id", client_id)
      |> Map.put("client_name", name)

  defp client!(client_id),
    do: elem(unboxed(fn -> Repository.fetch_client_by_id(client_id) end), 1)

  defp audit_count(client_id, action) do
    unboxed(fn ->
      Lockspire.TestRepo.aggregate(
        from(event in AuditEventRecord,
          where: event.resource_id == ^client_id and event.action == ^action
        ),
        :count
      )
    end)
  end

  defp cleanup(client_id) do
    unboxed(fn ->
      Lockspire.TestRepo.delete_all(
        from(event in AuditEventRecord, where: event.resource_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(from(row in ClientRecord, where: row.client_id == ^client_id))
    end)
  end

  defp unboxed(fun), do: Sandbox.unboxed_run(Lockspire.TestRepo, fun)

  defp decision_time,
    do: DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
end
