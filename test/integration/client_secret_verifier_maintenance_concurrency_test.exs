defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceConcurrencyTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Admin.Clients
  alias Lockspire.Clients, as: ClientCredentials
  alias Lockspire.Domain.Client
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TestRepo
  alias Lockspire.TestSupport.ClientVerifierMaintenanceConcurrency, as: Concurrency

  @moduletag :integration
  @moduletag :phase177_maintenance_concurrency

  setup_all do
    Application.put_env(:lockspire, :repo, TestRepo)

    unless Process.whereis(TestRepo) do
      start_supervised!(TestRepo)
    end

    Sandbox.mode(TestRepo, :manual)
    :ok
  end

  setup do
    old_key = :crypto.strong_rand_bytes(32)
    new_key = :crypto.strong_rand_bytes(32)
    old_context = context([{"race-old", old_key}], "race-old")
    current_context = context([{"race-old", old_key}, {"race-new", new_key}], "race-new")
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_cache = :persistent_term.get(cache_key, :missing)
    :persistent_term.put(cache_key, current_context)

    on_exit(fn ->
      case previous_cache do
        :missing -> :persistent_term.erase(cache_key)
        previous -> :persistent_term.put(cache_key, previous)
      end
    end)

    %{old_context: old_context, current_context: current_context}
  end

  @tag :rotation_first
  test "stale maintenance conflicts after authorized rotation commits", %{
    old_context: old_context
  } do
    {client, secret} = seed_client(old_context)
    before = persisted_row(client.client_id)

    holder =
      Concurrency.hold_transaction(TestRepo, self(), :rotation, fn ->
        assert {:ok, %{client: rotated, client_secret: new_secret}} =
                 Clients.rotate_client_secret(client.client_id, %{
                   actor: %{type: :operator, id: "phase177"}
                 })

        {:rotated, rotated, new_secret}
      end)

    assert_receive {:transaction_ready, :rotation, holder_process, holder_backend}, 10_000
    assert holder_process == holder.pid
    assert_receive {:transaction_provisional, :rotation, {:rotated, rotated, new_secret}}, 10_000
    refute new_secret == secret

    contender =
      Concurrency.run(TestRepo, self(), :maintenance, fn ->
        Lockspire.Storage.ClientVerifierMaintenance.rewrap_client(client.client_id)
      end)

    assert_receive {:operation_ready, :maintenance, contender_process, contender_backend}, 10_000
    assert contender_process == contender.pid
    assert contender_backend != holder_backend

    assert {:ok, blockers} =
             Concurrency.wait_for_blocker(TestRepo, contender_backend, holder_backend)

    send(holder.pid, {:release_transaction, :rotation, :commit})

    assert_receive {:transaction_done, :rotation, {:ok, {:rotated, ^rotated, ^new_secret}}},
                   10_000

    assert_receive {:operation_done, :maintenance, {:ok, :material_conflict}}, 10_000
    assert {:ok, {:rotated, ^rotated, ^new_secret}} = Task.await(holder, 10_000)
    assert {:ok, :material_conflict} = Task.await(contender, 10_000)

    after_row = persisted_row(client.client_id)
    assert after_row.client_secret_hash == rotated.client_secret_hash

    assert after_row.client_secret_jwt_verifier_encrypted ==
             rotated.client_secret_jwt_verifier_encrypted

    assert after_row.client_secret_expires_at == rotated.client_secret_expires_at
    assert after_row.last_secret_rotated_at == rotated.last_secret_rotated_at
    assert after_row.updated_at == rotated.updated_at

    assert_noncredential_fields_preserved(before, after_row, [
      :client_secret_hash,
      :client_secret_jwt_verifier_encrypted,
      :client_secret_expires_at,
      :last_secret_rotated_at,
      :updated_at
    ])

    assert blockers != []
  end

  @tag :maintenance_first
  test "rotation waits for maintenance then writes coherent credential fields", %{
    old_context: old_context
  } do
    {client, _secret} = seed_client(old_context)
    before = persisted_row(client.client_id)
    replacement = seal_current!(client.client_id, old_context, before.client_secret_hash)
    audit = audit_attrs(client.client_id)

    holder =
      Concurrency.hold_transaction(TestRepo, self(), :maintenance, fn ->
        assert {:ok, :changed} =
                 Repository.compare_and_rewrap(
                   client.client_id,
                   before.client_secret_hash,
                   before.client_secret_jwt_verifier_encrypted,
                   replacement,
                   audit
                 )

        {:ok, inside} = Repository.fetch_client_by_id(client.client_id)
        assert inside.client_secret_jwt_verifier_encrypted == replacement
        assert inside.client_secret_hash == before.client_secret_hash
        assert inside.name == before.name
        assert inside.metadata == before.metadata
        assert inside.updated_at == before.updated_at

        :changed
      end)

    assert_receive {:transaction_ready, :maintenance, holder_process, holder_backend}, 10_000
    assert holder_process == holder.pid
    assert_receive {:transaction_provisional, :maintenance, :changed}, 10_000

    contender =
      Concurrency.run(TestRepo, self(), :rotation, fn ->
        Clients.rotate_client_secret(client.client_id, %{
          actor: %{type: :operator, id: "phase177"}
        })
      end)

    assert_receive {:operation_ready, :rotation, contender_process, contender_backend}, 10_000
    assert contender_process == contender.pid
    assert contender_backend != holder_backend

    assert {:ok, blockers} =
             Concurrency.wait_for_blocker(TestRepo, contender_backend, holder_backend)

    send(holder.pid, {:release_transaction, :maintenance, :commit})
    assert_receive {:transaction_done, :maintenance, {:ok, :changed}}, 10_000

    assert_receive {:operation_done, :rotation,
                    {:ok, %{client: rotated, client_secret: new_secret}}},
                   10_000

    assert {:ok, %{client: ^rotated, client_secret: ^new_secret}} =
             Task.await(contender, 10_000)

    assert {:ok, :changed} = Task.await(holder, 10_000)

    after_row = persisted_row(client.client_id)
    assert after_row.client_secret_hash == rotated.client_secret_hash

    assert after_row.client_secret_jwt_verifier_encrypted ==
             rotated.client_secret_jwt_verifier_encrypted

    assert after_row.client_secret_jwt_verifier_encrypted != replacement
    assert after_row.client_secret_expires_at == rotated.client_secret_expires_at
    assert after_row.last_secret_rotated_at == rotated.last_secret_rotated_at
    assert after_row.updated_at == rotated.updated_at
    assert audit_count(client.client_id) == 1
    assert blockers != []
  end

  @tag :metadata_before
  test "metadata committed before maintenance reload survives verifier-only update", %{
    old_context: old_context
  } do
    {client, _secret} = seed_client(old_context)
    before = persisted_row(client.client_id)

    assert {:ok, edited} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Clients.update_client(client.client_id, %{
                 metadata: %{"host" => "edited"},
                 name: "Edited before maintenance"
               })
             end)

    assert edited.metadata == %{"host" => "edited"}

    assert {:ok, :changed} =
             Sandbox.unboxed_run(TestRepo, fn ->
               Lockspire.Storage.ClientVerifierMaintenance.rewrap_client(client.client_id)
             end)

    after_row = persisted_row(client.client_id)

    assert after_row.metadata == edited.metadata
    assert after_row.name == edited.name
    assert after_row.client_secret_hash == before.client_secret_hash
    assert after_row.client_secret_expires_at == before.client_secret_expires_at
    assert after_row.last_secret_rotated_at == before.last_secret_rotated_at
    assert after_row.updated_at == edited.updated_at
  end

  @tag :metadata_after
  test "metadata edit blocked behind maintenance preserves both committed changes", %{
    old_context: old_context
  } do
    {client, _secret} = seed_client(old_context)
    before = persisted_row(client.client_id)
    replacement = seal_current!(client.client_id, old_context, before.client_secret_hash)

    holder =
      Concurrency.hold_transaction(TestRepo, self(), :maintenance_with_edit, fn ->
        assert {:ok, :changed} =
                 Repository.compare_and_rewrap(
                   client.client_id,
                   before.client_secret_hash,
                   before.client_secret_jwt_verifier_encrypted,
                   replacement,
                   audit_attrs(client.client_id)
                 )

        :changed
      end)

    assert_receive {:transaction_ready, :maintenance_with_edit, holder_process, holder_backend},
                   10_000

    assert holder_process == holder.pid
    assert_receive {:transaction_provisional, :maintenance_with_edit, :changed}, 10_000

    editor =
      Concurrency.run(TestRepo, self(), :metadata_edit, fn ->
        Clients.update_client(client.client_id, %{
          name: "Edited while maintenance held lock",
          metadata: %{"host" => "concurrent-edit"}
        })
      end)

    assert_receive {:operation_ready, :metadata_edit, editor_process, editor_backend}, 10_000
    assert editor_process == editor.pid
    assert editor_backend != holder_backend

    assert {:ok, blockers} =
             Concurrency.wait_for_blocker(TestRepo, editor_backend, holder_backend)

    send(holder.pid, {:release_transaction, :maintenance_with_edit, :commit})

    assert_receive {:transaction_done, :maintenance_with_edit, {:ok, :changed}}, 10_000
    assert_receive {:operation_done, :metadata_edit, {:ok, edited}}, 10_000
    assert {:ok, :changed} = Task.await(holder, 10_000)
    assert {:ok, edited} = Task.await(editor, 10_000)

    after_row = persisted_row(client.client_id)
    assert after_row.client_secret_jwt_verifier_encrypted == replacement
    assert after_row.client_secret_hash == before.client_secret_hash
    assert after_row.name == edited.name
    assert after_row.metadata == edited.metadata
    assert after_row.updated_at == edited.updated_at
    assert audit_count(client.client_id) == 1
    assert blockers != []
  end

  defp seed_client(old_context) do
    {hash, secret} = ClientCredentials.rotate_secret_hash()
    client_id = unique_id()
    assert {:ok, verifier} = ClientSecretVerifier.seal(old_context, client_id, secret)
    deadline = DateTime.add(DateTime.utc_now() |> DateTime.truncate(:second), 86_400, :second)

    client = %Client{
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Verifier maintenance race",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      metadata: %{"seed" => "owned"},
      lifetime_version: 1,
      client_expires_at: DateTime.add(deadline, 30, :day),
      client_secret_expires_at: deadline,
      last_secret_rotated_at: DateTime.add(deadline, -1, :day)
    }

    assert {:ok, _persisted} =
             Sandbox.unboxed_run(TestRepo, fn -> Repository.register_client(client) end)

    on_exit(fn -> cleanup(client_id) end)
    {client, secret}
  end

  defp persisted_row(client_id) do
    Sandbox.unboxed_run(TestRepo, fn -> TestRepo.get_by!(ClientRecord, client_id: client_id) end)
  end

  defp cleanup(client_id) do
    Sandbox.unboxed_run(TestRepo, fn ->
      TestRepo.delete_all(from(event in AuditEventRecord, where: event.resource_id == ^client_id))
      TestRepo.delete_all(from(client in ClientRecord, where: client.client_id == ^client_id))
    end)
  end

  defp audit_count(client_id) do
    Sandbox.unboxed_run(TestRepo, fn ->
      TestRepo.aggregate(
        from(event in AuditEventRecord,
          where:
            event.action == "client_secret_verifier_rewrapped" and
              event.resource_id == ^client_id
        ),
        :count
      )
    end)
  end

  defp seal_current!(client_id, old_context, hash) do
    {:ok, secret} =
      ClientSecretVerifier.open(old_context, client_id, verifier_for(client_id), [])

    {:ok, verifier} = ClientSecretVerifier.seal(current_context(), client_id, secret)
    assert Policy.verify_client_secret(hash, secret)
    verifier
  end

  defp verifier_for(client_id) do
    Sandbox.unboxed_run(TestRepo, fn ->
      {:ok, client} = Repository.fetch_client_by_id(client_id)
      client.client_secret_jwt_verifier_encrypted
    end)
  end

  defp current_context do
    :persistent_term.get(Lockspire.Config.client_secret_verifier_cache_key())
  end

  defp audit_attrs(client_id) do
    %{
      action: :client_secret_verifier_rewrapped,
      outcome: :succeeded,
      actor: %{type: :system},
      resource: %{type: :client, id: client_id},
      metadata: %{
        old_key_id: "race-old",
        new_key_id: "race-new",
        maintenance_at: DateTime.utc_now()
      }
    }
  end

  defp assert_noncredential_fields_preserved(before, after_row, mutable_fields) do
    before
    |> Map.from_struct()
    |> Map.drop(mutable_fields)
    |> then(fn expected ->
      actual = after_row |> Map.from_struct() |> Map.drop(mutable_fields)
      assert actual == expected
    end)
  end

  defp context(keys, current) do
    {:ok, resolved} =
      Context.resolve(
        {:present,
         [
           keys: Enum.map(keys, fn {id, key} -> {id, Base.url_encode64(key, padding: false)} end),
           current: current,
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, valid} = Context.validate(resolved)
    valid
  end

  defp unique_id,
    do:
      "phase177-maintenance-race-" <>
        Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)
end
