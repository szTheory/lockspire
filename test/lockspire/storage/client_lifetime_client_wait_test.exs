defmodule Lockspire.Storage.ClientLifetimeClientWaitTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.TokenRecord

  @moduletag :integration

  test "code redemption samples equality only after the confirmed current-client lock wait" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-client-wait-#{suffix}"
    raw_code = "client-wait-code-#{suffix}"
    verifier = "client-wait-verifier-#{suffix}"
    raw_secret = "client-wait-secret-#{suffix}"
    _client = fixture(client_id, raw_secret, raw_code, verifier)

    on_exit(fn -> cleanup(client_id) end)

    decision_time = DateTime.add(DateTime.utc_now(), 3, :second) |> DateTime.truncate(:second)
    equality = DateTime.add(decision_time, 1, :second)
    {clock, advance_clock} = Race.barrier_clock(decision_time, equality)

    assert {1, _} =
             Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
               Lockspire.TestRepo.update_all(
                 from(record in ClientRecord, where: record.client_id == ^client_id),
                 set: [client_expires_at: equality]
               )
             end)

    before = durable_counts(client_id)
    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, :client_holder, parent, fn _holder_backend_pid ->
        result =
          Repository.transact(fn ->
            lock_result = Repository.lock_clients([client_id])
            send(parent, {:holder_lock_result, self(), lock_result})

            {:ok, [_current]} = lock_result

            receive do
              :release_holder -> {:ok, :released}
            after
              5_000 -> {:error, :holder_release_timeout}
            end
          end)

        result
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!(:client_holder)
    assert_receive {:holder_lock_result, ^holder_pid, {:ok, [_]}}, 5_000

    contender =
      Race.start_session(Lockspire.TestRepo, :code_contender, parent, fn _contender_backend_pid ->
        exchange(
          %{
            "grant_type" => "authorization_code",
            "code" => raw_code,
            "code_verifier" => verifier,
            "redirect_uri" => "https://client.example.com/callback"
          },
          authorization: basic_auth(client_id, raw_secret),
          now: clock
        )
      end)

    {_contender_pid, contender_backend_pid} = Race.await_session!(:code_contender)
    refute holder_backend_pid == contender_backend_pid

    try do
      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)
      advance_clock.()
      send(parent, {:confirmed_client_blocker, holder_backend_pid, contender_backend_pid})
      assert_receive {:confirmed_client_blocker, ^holder_backend_pid, ^contender_backend_pid}, 500
    after
      Race.release(holder_pid, :release_holder)
    end

    assert {:ok, :released} = Race.await_task!(holder, 5_000)
    assert {:error, error} = Race.await_task!(contender, 10_000)
    assert error.error in ["invalid_client", "invalid_grant"]

    assert durable_counts(client_id) == before

    assert {:ok, stored_code} =
             Repository.fetch_authorization_code(
               Lockspire.Protocol.TokenFormatter.hash_token(raw_code)
             )

    assert is_nil(stored_code.redeemed_at)
  end

  test "a waiting code redemption rejects a client disabled by the lock holder" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-disable-wait-#{suffix}"
    raw_code = "disable-wait-code-#{suffix}"
    verifier = "disable-wait-verifier-#{suffix}"
    raw_secret = "disable-wait-secret-#{suffix}"
    _client = fixture(client_id, raw_secret, raw_code, verifier)
    on_exit(fn -> cleanup(client_id) end)
    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, :disable_holder, parent, fn _ ->
        Repository.transact(fn ->
          {:ok, [_]} = Repository.lock_clients([client_id])
          send(parent, {:holder_locked_client, self()})

          receive do
            :disable_and_release ->
              {1, _} =
                Lockspire.TestRepo.update_all(
                  from(record in ClientRecord, where: record.client_id == ^client_id),
                  set: [active: false]
                )

              {:ok, :disabled}
          after
            5_000 -> {:error, :holder_release_timeout}
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!(:disable_holder)
    assert_receive {:holder_locked_client, ^holder_pid}, 5_000
    decision_time = DateTime.add(DateTime.utc_now(), 3, :second) |> DateTime.truncate(:second)

    contender =
      Race.start_session(Lockspire.TestRepo, :disabled_contender, parent, fn _ ->
        exchange(
          %{
            "grant_type" => "authorization_code",
            "code" => raw_code,
            "code_verifier" => verifier,
            "redirect_uri" => "https://client.example.com/callback"
          },
          authorization: basic_auth(client_id, raw_secret),
          now: fn -> decision_time end
        )
      end)

    {_contender_pid, contender_backend_pid} = Race.await_session!(:disabled_contender)
    refute holder_backend_pid == contender_backend_pid

    try do
      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)
    after
      Race.release(holder_pid, :disable_and_release)
    end

    assert {:ok, :disabled} = Race.await_task!(holder, 5_000)
    assert {:error, error} = Race.await_task!(contender, 10_000)
    assert error.error in ["invalid_client", "invalid_grant"]

    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
    refute stored.active

    assert {:ok, stored_code} =
             Repository.fetch_authorization_code(
               Lockspire.Protocol.TokenFormatter.hash_token(raw_code)
             )

    assert is_nil(stored_code.redeemed_at)
  end

  test "a preverified code request rejects the secret rotated before current-client acquisition" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-rotation-wait-#{suffix}"
    raw_code = "rotation-wait-code-#{suffix}"
    verifier = "rotation-wait-verifier-#{suffix}"
    raw_secret = "rotation-wait-secret-#{suffix}"
    _client = fixture(client_id, raw_secret, raw_code, verifier)
    on_exit(fn -> cleanup(client_id) end)
    before = durable_counts(client_id)
    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, :rotation_holder, parent, fn _ ->
        Repository.transact(fn ->
          {:ok, [_]} = Repository.lock_clients([client_id])
          send(parent, {:holder_locked_client, self()})

          receive do
            :rotate_and_release ->
              {1, _} =
                Lockspire.TestRepo.update_all(
                  from(record in ClientRecord, where: record.client_id == ^client_id),
                  set: [client_secret_hash: "committed-rotated-secret-#{suffix}"]
                )

              {:ok, :rotated}
          after
            5_000 -> {:error, :holder_release_timeout}
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!(:rotation_holder)
    assert_receive {:holder_locked_client, ^holder_pid}, 5_000
    decision_time = DateTime.add(DateTime.utc_now(), 3, :second) |> DateTime.truncate(:second)

    contender =
      Race.start_session(Lockspire.TestRepo, :rotation_contender, parent, fn _ ->
        exchange(
          %{
            "grant_type" => "authorization_code",
            "code" => raw_code,
            "code_verifier" => verifier,
            "redirect_uri" => "https://client.example.com/callback"
          },
          authorization: basic_auth(client_id, raw_secret),
          now: fn -> decision_time end
        )
      end)

    {_contender_pid, contender_backend_pid} = Race.await_session!(:rotation_contender)
    refute holder_backend_pid == contender_backend_pid

    try do
      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)
    after
      Race.release(holder_pid, :rotate_and_release)
    end

    assert {:ok, :rotated} = Race.await_task!(holder, 5_000)
    assert {:error, error} = Race.await_task!(contender, 10_000)
    assert error.error in ["invalid_client", "invalid_grant"]
    assert durable_counts(client_id) == before

    assert {:ok, stored} = Repository.fetch_client_by_id(client_id)
    assert stored.client_secret_hash == "committed-rotated-secret-#{suffix}"

    assert {:ok, stored_code} =
             Repository.fetch_authorization_code(
               Lockspire.Protocol.TokenFormatter.hash_token(raw_code)
             )

    assert is_nil(stored_code.redeemed_at)
  end

  defp fixture(client_id, secret, raw_code, verifier) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        create_client(client_id, :client_secret_basic, secret, ["authorization_code"], %{
          access_token_format: :opaque
        })

      {:ok, _code} =
        create_authorization_code(client, raw_code: raw_code, code_verifier: verifier)

      {1, _} =
        Lockspire.TestRepo.update_all(
          from(record in ClientRecord, where: record.client_id == ^client_id),
          set: [lifetime_version: 1, client_expires_at: nil]
        )

      client
    end)
  end

  defp durable_counts(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      tokens =
        Lockspire.TestRepo.aggregate(
          from(t in TokenRecord, where: t.client_id == ^client_id),
          :count
        )

      audits =
        Lockspire.TestRepo.aggregate(
          from(event in AuditEventRecord,
            where: event.resource_type == "client" and event.resource_id == ^client_id
          ),
          :count
        )

      {tokens, audits}
    end)
  end

  defp cleanup(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.delete_all(
        from(event in AuditEventRecord, where: event.resource_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(token in TokenRecord, where: token.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(interaction in InteractionRecord, where: interaction.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(client in ClientRecord, where: client.client_id == ^client_id)
      )
    end)
  end
end
