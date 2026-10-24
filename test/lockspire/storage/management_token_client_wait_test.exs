defmodule Lockspire.Storage.ManagementTokenClientWaitTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Protocol.RegistrationManagement
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
      DcrFixtures.server_policy(%{dcr_default_registration_access_token_lifetime_seconds: 60})

    {:ok, _} = Repository.put_server_policy(policy)
    %{policy: policy}
  end

  test "GET, PUT, and DELETE reject equality and after expiry only after a confirmed row wait" do
    for operation <- [:get, :put, :delete], boundary <- [:equality, :after] do
      suffix = suffix()
      {client, policy} = committed_client("management-expiry-#{operation}-#{suffix}")
      on_exit(fn -> cleanup(client.client_id) end)

      before = DateTime.add(DateTime.utc_now(), 30, :second) |> DateTime.truncate(:second)
      deadline = DateTime.add(before, 1, :second)

      after_wait =
        if boundary == :equality, do: deadline, else: DateTime.add(deadline, 1, :second)

      assert {1, _} =
               unboxed(fn ->
                 Lockspire.TestRepo.update_all(
                   from(row in ClientRecord, where: row.client_id == ^client.client_id),
                   set: [registration_access_token_expires_at: deadline]
                 )
               end)

      {:ok, snapshot} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
      before_row = client_row(client.client_id)
      before_audits = management_audits(client.client_id)
      {clock, advance} = Race.barrier_clock(before, after_wait)
      parent = self()

      holder = lock_holder(client.client_id, {:expiry_holder, operation, boundary}, parent)
      {holder_pid, holder_backend} = Race.await_session!({:expiry_holder, operation, boundary})
      assert_receive {{:row_locked, operation, boundary}, ^holder_pid}, 5_000

      contender =
        Race.start_session(
          Lockspire.TestRepo,
          {:expiry_contender, operation, boundary},
          parent,
          fn _ ->
            call(operation, client.client_id, snapshot, policy, clock)
          end
        )

      {_contender_pid, contender_backend} =
        Race.await_session!({:expiry_contender, operation, boundary})

      refute holder_backend == contender_backend

      try do
        Race.await_blocker!(Lockspire.TestRepo, contender_backend, holder_backend)
        advance.()
      after
        Race.release(holder_pid, {:release, operation, boundary})
      end

      assert {:ok, :released} = Race.await_task!(holder)
      assert_expired(operation, Race.await_task!(contender, 10_000))
      assert client_row(client.client_id) == before_row
      assert management_audits(client.client_id) == before_audits
    end
  end

  test "GET, PUT, and DELETE lose authority after a real replacement commits" do
    for operation <- [:get, :put, :delete] do
      suffix = suffix()
      {client, policy} = committed_client("management-stale-#{operation}-#{suffix}")
      on_exit(fn -> cleanup(client.client_id) end)
      {:ok, stale} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
      previous_audits = management_audits(client.client_id)
      parent = self()
      replacement_time = decision_time()

      winner =
        update_holder(
          client.client_id,
          stale,
          policy,
          replacement_time,
          {:winner, operation},
          parent
        )

      {winner_pid, winner_backend} = Race.await_session!({:winner, operation})
      assert_receive {{:clock_waiting, operation}, ^winner_pid, ^winner_backend}, 5_000

      contender =
        Race.start_session(Lockspire.TestRepo, {:stale_contender, operation}, parent, fn _ ->
          call(operation, client.client_id, stale, policy, replacement_time)
        end)

      {_contender_pid, contender_backend} = Race.await_session!({:stale_contender, operation})
      refute winner_backend == contender_backend

      winner_result =
        try do
          Race.await_blocker!(Lockspire.TestRepo, contender_backend, winner_backend)
          Race.release(winner_pid, {:sample, operation})

          assert {:ok, %RegistrationManagement.UpdateSuccess{} = success} =
                   Race.await_task!(winner, 10_000)

          success
        after
          Race.release(winner_pid, {:sample, operation})
        end

      assert {:error, :invalid_token} = Race.await_task!(contender, 10_000)
      {:ok, current} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
      refute current.registration_access_token_hash == stale.registration_access_token_hash
      assert length(management_audits(client.client_id)) == length(previous_audits) + 1
      assert current.name == "winner #{operation}"

      assert RegistrationAccessToken.verify(
               current.registration_access_token_hash,
               winner_result.registration_access_token_plaintext
             )
    end
  end

  test "a GET that passed current-row authority before replacement may finish its response" do
    suffix = suffix()
    {client, policy} = committed_client("management-read-linearized-#{suffix}")
    on_exit(fn -> cleanup(client.client_id) end)
    {:ok, snapshot} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
    parent = self()
    read_time = decision_time()

    reader =
      Race.start_session(Lockspire.TestRepo, :linearized_reader, parent, fn _ ->
        RegistrationManagement.read(client.client_id, snapshot,
          now: fn ->
            send(parent, {:read_clock_waiting, self(), Race.backend_pid!(Lockspire.TestRepo)})

            receive do
              :finish_read -> read_time
            after
              5_000 -> raise "read clock release timed out"
            end
          end
        )
      end)

    {reader_pid, reader_backend} = Race.await_session!(:linearized_reader)
    assert_receive {:read_clock_waiting, ^reader_pid, ^reader_backend}, 5_000

    replacement =
      update_holder(
        client.client_id,
        snapshot,
        policy,
        DateTime.add(read_time, 1, :second),
        :linearized_winner,
        parent
      )

    {replacement_pid, replacement_backend} = Race.await_session!(:linearized_winner)

    refute reader_backend == replacement_backend

    try do
      Race.await_blocker!(Lockspire.TestRepo, replacement_backend, reader_backend)
      send(reader_pid, :finish_read)
      assert {:ok, %Client{client_id: id}} = Race.await_task!(reader, 10_000)
      assert id == client.client_id

      assert_receive {{:clock_waiting, :linearized_winner}, ^replacement_pid,
                      ^replacement_backend},
                     5_000

      Race.release(replacement_pid, {:sample, :linearized_winner})

      assert {:ok, %RegistrationManagement.UpdateSuccess{}} =
               Race.await_task!(replacement, 10_000)
    after
      send(reader_pid, :finish_read)
      Race.release(replacement_pid, {:sample, :linearized_winner})
    end

    {:ok, current} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
    refute current.registration_access_token_hash == snapshot.registration_access_token_hash
  end

  defp call(:get, client_id, snapshot, _policy, now),
    do: RegistrationManagement.read(client_id, snapshot, now: now)

  defp call(:put, client_id, snapshot, policy, now) do
    metadata =
      DcrFixtures.valid_metadata()
      |> Map.put("client_id", client_id)
      |> Map.put("client_name", "stale put")

    RegistrationManagement.update(client_id, %{
      client: snapshot,
      metadata: metadata,
      server_policy: policy,
      now: now
    })
  end

  defp call(:delete, client_id, snapshot, _policy, now),
    do: RegistrationManagement.delete(client_id, snapshot, now: now)

  defp assert_expired(_operation, {:error, :invalid_token}), do: :ok

  defp assert_expired(operation, result),
    do: flunk("#{operation} should reject expired management authority, got #{inspect(result)}")

  defp lock_holder(client_id, label, owner) do
    Race.start_session(Lockspire.TestRepo, label, owner, fn _ ->
      Repository.transact(fn ->
        {:ok, [_]} = Repository.lock_clients([client_id])
        send(owner, {{:row_locked, elem(label, 1), elem(label, 2)}, self()})

        receive do
          {:release, operation, boundary}
          when elem(label, 1) == operation and elem(label, 2) == boundary ->
            {:ok, :released}
        after
          5_000 -> {:error, :holder_release_timeout}
        end
      end)
    end)
  end

  defp update_holder(client_id, snapshot, policy, now, label, owner) do
    Race.start_session(Lockspire.TestRepo, label, owner, fn _ ->
      operation = operation_from(label)

      metadata =
        DcrFixtures.valid_metadata()
        |> Map.put("client_id", client_id)
        |> Map.put("client_name", "winner #{operation}")

      RegistrationManagement.update(client_id, %{
        client: snapshot,
        metadata: metadata,
        server_policy: policy,
        now: fn ->
          backend = Race.backend_pid!(Lockspire.TestRepo)
          send(owner, {{:clock_waiting, operation}, self(), backend})

          receive do
            {:sample, ^operation} -> now
          after
            5_000 -> raise "replacement clock release timed out"
          end
        end
      })
    end)
  end

  defp operation_from({:winner, operation}), do: operation
  defp operation_from(:linearized_winner), do: :linearized_winner

  defp committed_client(client_id) do
    unboxed(fn ->
      policy =
        DcrFixtures.server_policy(%{dcr_default_registration_access_token_lifetime_seconds: 60})

      {:ok, _} = Repository.put_server_policy(policy)

      {:ok, %Registration.Success{client: client}} =
        Registration.register(%{
          metadata: DcrFixtures.valid_metadata() |> Map.put("client_name", client_id),
          iat: nil,
          server_policy: policy,
          source: %{ip: "127.0.0.1"}
        })

      {client, policy}
    end)
  end

  defp client_row(client_id),
    do: unboxed(fn -> Lockspire.TestRepo.get_by!(ClientRecord, client_id: client_id) end)

  defp management_audits(client_id) do
    unboxed(fn ->
      Lockspire.TestRepo.all(
        from(event in AuditEventRecord,
          where:
            event.resource_id == ^client_id and
              event.action in [
                "dcr_management_updated",
                "dcr_management_rat_rotated",
                "dcr_management_deleted"
              ],
          order_by: [asc: event.id]
        )
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

  defp suffix, do: Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
end
