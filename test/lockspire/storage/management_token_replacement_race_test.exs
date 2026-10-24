defmodule Lockspire.Storage.ManagementTokenReplacementRaceTest do
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
      DcrFixtures.server_policy(%{dcr_default_registration_access_token_lifetime_seconds: 90})

    {:ok, _} = Repository.put_server_policy(policy)
    %{policy: policy}
  end

  test "same-fingerprint PUT/PUT, PUT/recovery, recovery/PUT, and recovery/recovery have one winner",
       %{policy: server_policy} do
    for {first, second} <- [
          {:put, :put},
          {:put, :recovery},
          {:recovery, :put},
          {:recovery, :recovery}
        ] do
      suffix = suffix()
      {client, old_token} = committed_client("management-one-winner-#{first}-#{second}-#{suffix}")
      on_exit(fn -> cleanup(client.client_id) end)
      {:ok, original} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
      before_audits = audit_events(client.client_id)
      first_time = decision_time()
      parent = self()

      winner =
        start_operation(
          {:winner, first, second},
          first,
          client.client_id,
          original,
          server_policy,
          parent,
          first_time
        )

      {winner_pid, winner_backend} = Race.await_session!({:winner, first, second})

      assert_receive {{:operation_clock_waiting, first, second}, ^winner_pid, ^winner_backend},
                     5_000

      loser =
        Race.start_session(Lockspire.TestRepo, {:loser, first, second}, parent, fn _ ->
          operation(second, client.client_id, original, server_policy, first_time)
        end)

      {_loser_pid, loser_backend} = Race.await_session!({:loser, first, second})
      refute winner_backend == loser_backend

      first_result =
        try do
          Race.await_blocker!(Lockspire.TestRepo, loser_backend, winner_backend)
          Race.release(winner_pid, {:sample_operation, first, second})
          result = Race.await_task!(winner, 10_000)
          assert success?(first, result), "expected #{first} to commit, got #{inspect(result)}"
          result
        after
          Race.release(winner_pid, {:sample_operation, first, second})
        end

      assert {:error, :invalid_token} = Race.await_task!(loser, 10_000)
      current = client!(client.client_id)
      winner_plaintext = plaintext(first, first_result)

      assert RegistrationAccessToken.verify(
               current.registration_access_token_hash,
               winner_plaintext
             )

      refute RegistrationAccessToken.verify(current.registration_access_token_hash, old_token)
      assert length(audit_events(client.client_id)) == length(before_audits) + 1
      assert_current_lifecycle(current, original, first_time)

      assert {:error, :invalid_token} =
               unboxed(fn ->
                 operation(second, client.client_id, original, server_policy, first_time)
               end)

      assert length(audit_events(client.client_id)) == length(before_audits) + 1

      {:ok, refreshed} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
      retry_time = DateTime.add(first_time, 2, :second)

      assert {:ok, _token, recovered} =
               unboxed(fn ->
                 RegistrationManagement.rotate_registration_access_token(refreshed,
                   now: retry_time
                 )
               end)

      assert recovered.registration_access_token_hash != current.registration_access_token_hash
      assert length(audit_events(client.client_id)) == length(before_audits) + 2
    end
  end

  test "a losing legacy promotion cannot restore advisory dates or version zero", %{
    policy: server_policy
  } do
    suffix = suffix()
    {client, old_token} = committed_client("management-legacy-race-#{suffix}")
    on_exit(fn -> cleanup(client.client_id) end)
    old = decision_time()
    advisory = DateTime.add(old, -30, :second)

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

    {:ok, snapshot} = unboxed(fn -> Repository.fetch_client_by_id(client.client_id) end)
    parent = self()

    winner =
      start_operation(
        :legacy_winner,
        :put,
        client.client_id,
        snapshot,
        server_policy,
        parent,
        old
      )

    {winner_pid, winner_backend} = Race.await_session!(:legacy_winner)

    assert_receive {{:operation_clock_waiting, :put, :legacy_winner}, ^winner_pid,
                    ^winner_backend},
                   5_000

    loser =
      Race.start_session(Lockspire.TestRepo, :legacy_loser, parent, fn _ ->
        RegistrationManagement.rotate_registration_access_token(snapshot, now: old)
      end)

    {_loser_pid, loser_backend} = Race.await_session!(:legacy_loser)

    winner_result =
      try do
        Race.await_blocker!(Lockspire.TestRepo, loser_backend, winner_backend)
        Race.release(winner_pid, {:sample_operation, :put, :legacy_winner})

        assert {:ok, %RegistrationManagement.UpdateSuccess{} = result} =
                 Race.await_task!(winner, 10_000)

        result
      after
        Race.release(winner_pid, {:sample_operation, :put, :legacy_winner})
      end

    assert {:error, :invalid_token} = Race.await_task!(loser, 10_000)
    current = client!(client.client_id)

    assert RegistrationAccessToken.verify(
             current.registration_access_token_hash,
             winner_result.registration_access_token_plaintext
           )

    refute RegistrationAccessToken.verify(current.registration_access_token_hash, old_token)
    assert length(audit_events(client.client_id)) == 1
    assert current.lifetime_version == 1
    assert is_nil(current.client_expires_at)
    assert is_nil(current.client_secret_expires_at)

    assert DateTime.compare(
             current.registration_access_token_expires_at,
             DateTime.add(old, 90, :second)
           ) == :eq
  end

  defp start_operation(label, operation_name, client_id, snapshot, server_policy, owner, now) do
    Race.start_session(Lockspire.TestRepo, label, owner, fn _ ->
      operation_with_clock(operation_name, client_id, snapshot, server_policy, now, label, owner)
    end)
  end

  defp operation_with_clock(:put, client_id, snapshot, server_policy, now, label, owner) do
    metadata = metadata(client_id, "winner #{inspect(label)}")

    RegistrationManagement.update(client_id, %{
      client: snapshot,
      metadata: metadata,
      server_policy: server_policy,
      now: waiting_clock(now, label, owner)
    })
  end

  defp operation_with_clock(:recovery, _client_id, snapshot, _server_policy, now, label, owner) do
    RegistrationManagement.rotate_registration_access_token(snapshot,
      now: waiting_clock(now, label, owner)
    )
  end

  defp operation(:put, client_id, snapshot, server_policy, now) do
    RegistrationManagement.update(client_id, %{
      client: snapshot,
      metadata: metadata(client_id, "competing stale PUT"),
      server_policy: server_policy,
      now: now
    })
  end

  defp operation(:recovery, _client_id, snapshot, _server_policy, now),
    do: RegistrationManagement.rotate_registration_access_token(snapshot, now: now)

  defp waiting_clock(now, label, owner) do
    fn ->
      backend = Race.backend_pid!(Lockspire.TestRepo)
      operation = if match?({:winner, _, _}, label), do: elem(label, 1), else: :put
      second = if match?({:winner, _, _}, label), do: elem(label, 2), else: label
      send(owner, {{:operation_clock_waiting, operation, second}, self(), backend})

      receive do
        {:sample_operation, ^operation, ^second} -> now
      after
        5_000 -> raise "operation clock release timed out"
      end
    end
  end

  defp success?(:put, {:ok, %RegistrationManagement.UpdateSuccess{}}), do: true
  defp success?(:recovery, {:ok, token, %Client{}}) when is_binary(token), do: true
  defp success?(_, _), do: false

  defp plaintext(
         :put,
         {:ok, %RegistrationManagement.UpdateSuccess{registration_access_token_plaintext: token}}
       ),
       do: token

  defp plaintext(:recovery, {:ok, token, %Client{}}), do: token

  defp assert_current_lifecycle(current, original, now) do
    assert DateTime.compare(
             current.registration_access_token_expires_at,
             DateTime.add(now, 90, :second)
           ) == :eq

    assert current.client_expires_at == original.client_expires_at
    assert current.client_secret_expires_at == original.client_secret_expires_at
    assert current.client_secret_hash == original.client_secret_hash
    assert current.active == original.active
  end

  defp committed_client(name) do
    unboxed(fn ->
      policy =
        DcrFixtures.server_policy(%{dcr_default_registration_access_token_lifetime_seconds: 90})

      {:ok, _} = Repository.put_server_policy(policy)

      {:ok, %Registration.Success{client: client, registration_access_token_plaintext: token}} =
        Registration.register(%{
          metadata: DcrFixtures.valid_metadata() |> Map.put("client_name", name),
          iat: nil,
          server_policy: policy,
          source: %{ip: "127.0.0.1"}
        })

      {client, token}
    end)
  end

  defp metadata(client_id, name),
    do:
      DcrFixtures.valid_metadata()
      |> Map.put("client_id", client_id)
      |> Map.put("client_name", name)

  defp client!(client_id),
    do: elem(unboxed(fn -> Repository.fetch_client_by_id(client_id) end), 1)

  defp audit_events(client_id) do
    unboxed(fn ->
      Lockspire.TestRepo.all(
        from(event in AuditEventRecord,
          where:
            event.resource_id == ^client_id and
              event.action in ["dcr_management_updated", "dcr_management_rat_rotated"],
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
