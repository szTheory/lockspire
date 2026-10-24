defmodule Lockspire.Storage.ClientSecretLifetimeRotationRaceTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Admin.Clients
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.ServerPolicyRecord

  @moduletag :integration
  @moduletag :postgres_race

  test "two authorized replacements serialize and only the last committed secret remains current" do
    suffix = suffix()
    client_id = "secret-rotation-serial-#{suffix}"
    app_deadline = DateTime.add(decision_time(), 10_000, :second)
    management_deadline = DateTime.add(decision_time(), 20_000, :second)

    _client =
      committed_client(client_id, "serial-old-#{suffix}", :self_registered, 1, %{
        client_expires_at: app_deadline,
        registration_access_token_expires_at: management_deadline
      })

    previous_policy = snapshot_server_policy()
    set_secret_policy(37)

    on_exit(fn ->
      cleanup(client_id)
      restore_server_policy(previous_policy)
    end)

    parent = self()
    first_time = decision_time()
    second_time = DateTime.add(first_time, 1, :second)
    first = start_rotation(:first, client_id, first_time, parent)
    {first_pid, first_backend_pid} = Race.await_session!({:rotation, :first})
    assert_receive {:rotation_clock_waiting, :first, ^first_pid, ^first_backend_pid}, 5_000

    second = start_rotation(:second, client_id, second_time, parent)
    {second_pid, second_backend_pid} = Race.await_session!({:rotation, :second})
    refute first_backend_pid == second_backend_pid
    Race.await_blocker!(Lockspire.TestRepo, second_backend_pid, first_backend_pid)

    Race.assert_locked_nowait!(
      Lockspire.TestRepo,
      "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
      [client_id]
    )

    Race.release(first_pid, {:sample_rotation, :first})
    assert {:ok, first_result} = Race.await_task!(first, 10_000)
    assert DateTime.compare(first_result.client.last_secret_rotated_at, first_time) == :eq
    assert_receive {:rotation_clock_waiting, :second, _pid, ^second_backend_pid}, 5_000
    assert {:ok, first_is_current} = Repository.fetch_client_by_id(client_id)

    assert Policy.verify_client_secret(
             first_is_current.client_secret_hash,
             first_result.client_secret
           )

    Race.release(second_pid, {:sample_rotation, :second})
    assert {:ok, second_result} = Race.await_task!(second, 10_000)

    assert DateTime.compare(second_result.client.last_secret_rotated_at, second_time) == :eq

    assert DateTime.compare(
             second_result.client.client_secret_expires_at,
             DateTime.add(second_time, 37, :second)
           ) == :eq

    assert DateTime.compare(second_result.client.client_expires_at, app_deadline) == :eq

    assert DateTime.compare(
             second_result.client.registration_access_token_expires_at,
             management_deadline
           ) == :eq

    assert {:ok, current} = Repository.fetch_client_by_id(client_id)
    assert Policy.verify_client_secret(current.client_secret_hash, second_result.client_secret)
    refute Policy.verify_client_secret(current.client_secret_hash, first_result.client_secret)

    assert current.client_secret_jwt_verifier_encrypted ==
             second_result.client.client_secret_jwt_verifier_encrypted

    audits = rotation_audits(client_id)
    assert length(audits) == 2
    assert Enum.map(audits, & &1.actor_id) |> Enum.sort() == ["first", "second"]
  end

  test "a waiting replacement uses current provenance, policy, time and v0 row state" do
    suffix = suffix()
    client_id = "secret-rotation-current-#{suffix}"
    old = decision_time()

    _client =
      committed_client(client_id, "current-old-#{suffix}", :operator, 0, %{
        client_expires_at: DateTime.add(old, 400, :second),
        client_secret_expires_at: DateTime.add(old, 300, :second),
        registration_access_token_expires_at: DateTime.add(old, 200, :second)
      })

    previous_policy = snapshot_server_policy()
    set_secret_policy(11)

    on_exit(fn ->
      cleanup(client_id)
      restore_server_policy(previous_policy)
    end)

    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, :current_state_holder, parent, fn _ ->
        Repository.transact(fn ->
          {:ok, [_]} = Repository.lock_clients([client_id])
          send(parent, {:current_state_locked, self()})

          receive do
            {:update_current_state, new_policy} ->
              {1, _} =
                Lockspire.TestRepo.update_all(
                  from(record in ClientRecord, where: record.client_id == ^client_id),
                  set: [
                    provenance: :self_registered,
                    active: false,
                    disabled_at: new_policy.disabled_at,
                    disabled_by: "disabled-during-secret-wait",
                    metadata: %{"changed_while_waiting" => true}
                  ]
                )

              {:ok, _policy} = Repository.put_server_policy(new_policy.policy)
              {:ok, :updated}
          after
            5_000 -> {:error, :holder_release_timeout}
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!(:current_state_holder)
    assert_receive {:current_state_locked, ^holder_pid}, 5_000

    sampled_at = DateTime.add(decision_time(), 2, :second)

    contender =
      Race.start_session(Lockspire.TestRepo, :current_state_rotation, parent, fn _ ->
        Clients.rotate_client_secret(client_id, %{
          now: fn ->
            send(
              parent,
              {:current_state_clock_sampled, self(), Race.backend_pid!(Lockspire.TestRepo)}
            )

            sampled_at
          end,
          actor: %{type: :operator, id: "current-state-test"}
        })
      end)

    {contender_pid, contender_backend_pid} = Race.await_session!(:current_state_rotation)
    refute holder_backend_pid == contender_backend_pid
    Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)

    Race.assert_locked_nowait!(
      Lockspire.TestRepo,
      "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
      [client_id]
    )

    new_policy = %ServerPolicy{dcr_default_client_secret_lifetime_seconds: 73}

    Race.release(
      holder_pid,
      {:update_current_state, %{policy: new_policy, disabled_at: decision_time()}}
    )

    assert {:ok, :updated} = Race.await_task!(holder, 10_000)

    assert {:ok, %{client: rotated, client_secret: plaintext}} =
             Race.await_task!(contender, 10_000)

    assert_receive {:current_state_clock_sampled, ^contender_pid, ^contender_backend_pid}, 5_000
    assert DateTime.compare(rotated.last_secret_rotated_at, sampled_at) == :eq

    assert DateTime.compare(
             rotated.client_secret_expires_at,
             DateTime.add(sampled_at, 73, :second)
           ) == :eq

    assert is_nil(rotated.client_expires_at)
    assert is_nil(rotated.registration_access_token_expires_at)
    refute rotated.active
    assert rotated.disabled_by == "disabled-during-secret-wait"
    assert rotated.metadata == %{"changed_while_waiting" => true}
    assert rotated.provenance == :self_registered
    assert Policy.verify_client_secret(rotated.client_secret_hash, plaintext)

    assert {:ok, current} = Repository.fetch_client_by_id(client_id)
    assert current == rotated
    [audit] = rotation_audits(client_id)
    assert {:ok, audit_time, 0} = DateTime.from_iso8601(audit.metadata["rotated_at"])
    assert DateTime.compare(audit_time, sampled_at) == :eq
  end

  test "client-write failure under a confirmed row wait rolls credential and audit state back" do
    assert_rotation_failure_rolls_back(:write)
  end

  test "audit failure under a confirmed row wait rolls credential and audit state back" do
    assert_rotation_failure_rolls_back(:audit)
  end

  defp assert_rotation_failure_rolls_back(failure) do
    suffix = suffix()
    client_id = "secret-rotation-rollback-#{failure}-#{suffix}"
    _client = committed_client(client_id, "rollback-old-#{suffix}", :operator, 1, %{})
    on_exit(fn -> cleanup(client_id) end)
    install_failure_trigger(failure, client_id)

    try do
      before_client = client_row(client_id)
      before_audits = rotation_audits(client_id)
      parent = self()

      holder =
        Race.start_session(Lockspire.TestRepo, {:rollback_holder, failure}, parent, fn _ ->
          Repository.transact(fn ->
            {:ok, [_]} = Repository.lock_clients([client_id])
            send(parent, {{:rollback_locked, failure}, self()})

            receive do
              {:release_rollback, ^failure} -> {:ok, :released}
            after
              5_000 -> {:error, :holder_release_timeout}
            end
          end)
        end)

      {holder_pid, holder_backend_pid} = Race.await_session!({:rollback_holder, failure})
      assert_receive {{:rollback_locked, ^failure}, ^holder_pid}, 5_000

      contender =
        Race.start_session(Lockspire.TestRepo, {:rollback_contender, failure}, parent, fn _ ->
          Clients.rotate_client_secret(client_id, %{
            actor: %{type: :operator, id: "rollback-test"}
          })
        end)

      {_contender_pid, contender_backend_pid} =
        Race.await_session!({:rollback_contender, failure})

      refute holder_backend_pid == contender_backend_pid
      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)

      Race.assert_locked_nowait!(
        Lockspire.TestRepo,
        "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
        [client_id]
      )

      Race.release(holder_pid, {:release_rollback, failure})
      assert {:ok, :released} = Race.await_task!(holder, 5_000)
      assert {:error, reason} = Race.await_task!(contender, 10_000)
      assert inspect(reason) =~ "164-05 injected #{failure} failure"
      assert client_row(client_id) == before_client
      assert rotation_audits(client_id) == before_audits
    after
      remove_failure_trigger(failure)
    end
  end

  defp start_rotation(label, client_id, sampled_at, owner) do
    Race.start_session(Lockspire.TestRepo, {:rotation, label}, owner, fn _ ->
      Clients.rotate_client_secret(client_id, %{
        now: fn ->
          backend_pid = Race.backend_pid!(Lockspire.TestRepo)
          send(owner, {:rotation_clock_waiting, label, self(), backend_pid})

          receive do
            {:sample_rotation, ^label} -> sampled_at
          after
            5_000 -> raise "timed out waiting to sample #{label} rotation time"
          end
        end,
        actor: %{type: :operator, id: Atom.to_string(label)}
      })
    end)
  end

  defp committed_client(client_id, secret, provenance, version, attrs) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        Repository.register_client(%Client{
          lifetime_version: version,
          client_id: client_id,
          client_secret_hash: Policy.hash_client_secret(secret),
          client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret),
          client_type: :confidential,
          name: "Secret Rotation Race #{client_id}",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["email"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          provenance: provenance,
          active: true,
          created_at: DateTime.utc_now(),
          metadata: %{},
          client_expires_at: Map.get(attrs, :client_expires_at),
          client_secret_expires_at: Map.get(attrs, :client_secret_expires_at),
          registration_access_token_expires_at:
            Map.get(attrs, :registration_access_token_expires_at)
        })

      client
    end)
  end

  defp set_secret_policy(seconds) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, policy} =
        Repository.put_server_policy(%ServerPolicy{
          dcr_default_client_secret_lifetime_seconds: seconds
        })

      policy
    end)
  end

  defp snapshot_server_policy do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.get(ServerPolicyRecord, ServerPolicyRecord.singleton_id())
    end)
  end

  defp restore_server_policy(previous_policy) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      case previous_policy do
        nil ->
          Lockspire.TestRepo.delete_all(
            from(policy in ServerPolicyRecord,
              where: policy.id == ^ServerPolicyRecord.singleton_id()
            )
          )

        %ServerPolicyRecord{} = policy ->
          Lockspire.TestRepo.insert_or_update!(Ecto.Changeset.change(policy))
      end
    end)
  end

  defp install_failure_trigger(failure, client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      case failure do
        :write ->
          Lockspire.TestRepo.query!(
            "DROP TRIGGER IF EXISTS lockspire_16405_client_failure ON lockspire_clients"
          )

          Lockspire.TestRepo.query!("""
          CREATE OR REPLACE FUNCTION lockspire_16405_reject_client() RETURNS trigger AS $$
          BEGIN
            IF NEW.client_id = '#{client_id}' THEN
              RAISE EXCEPTION '164-05 injected write failure for %', NEW.client_id;
            END IF;
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql
          """)

          Lockspire.TestRepo.query!("""
          CREATE TRIGGER lockspire_16405_client_failure
          BEFORE UPDATE ON lockspire_clients
          FOR EACH ROW EXECUTE FUNCTION lockspire_16405_reject_client()
          """)

        :audit ->
          Lockspire.TestRepo.query!(
            "DROP TRIGGER IF EXISTS lockspire_16405_audit_failure ON lockspire_audit_events"
          )

          Lockspire.TestRepo.query!("""
          CREATE OR REPLACE FUNCTION lockspire_16405_reject_audit() RETURNS trigger AS $$
          BEGIN
            IF NEW.resource_id = '#{client_id}' AND NEW.action = 'client_secret_rotated' THEN
              RAISE EXCEPTION '164-05 injected audit failure for %', NEW.resource_id;
            END IF;
            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql
          """)

          Lockspire.TestRepo.query!("""
          CREATE TRIGGER lockspire_16405_audit_failure
          BEFORE INSERT ON lockspire_audit_events
          FOR EACH ROW EXECUTE FUNCTION lockspire_16405_reject_audit()
          """)
      end
    end)
  end

  defp remove_failure_trigger(:write) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lockspire_16405_client_failure ON lockspire_clients"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_16405_reject_client()")
    end)
  end

  defp remove_failure_trigger(:audit) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.query!(
        "DROP TRIGGER IF EXISTS lockspire_16405_audit_failure ON lockspire_audit_events"
      )

      Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_16405_reject_audit()")
    end)
  end

  defp client_row(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.get_by!(ClientRecord, client_id: client_id)
    end)
  end

  defp rotation_audits(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.all(
        from(event in AuditEventRecord,
          where: event.resource_id == ^client_id and event.action == "client_secret_rotated",
          order_by: [asc: event.id]
        )
      )
    end)
  end

  defp cleanup(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.delete_all(
        from(event in AuditEventRecord, where: event.resource_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(client in ClientRecord, where: client.client_id == ^client_id)
      )
    end)
  end

  defp decision_time,
    do: DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)

  defp suffix, do: Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
end
