defmodule Lockspire.Storage.ClientSecretLifetimeGrantWaitTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.CibaAuthorizationRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.DeviceAuthorizationRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.TokenRecord

  @moduletag :integration
  @moduletag :postgres_race

  defmodule ExchangeValidator do
    def validate(_context), do: :ok
  end

  defmodule BlockingPollStore do
    alias Lockspire.Storage.Ecto.Repository

    def lifetime_contract do
      %{version: 1, transaction_authority: transaction_authority()}
    end

    def transaction_authority do
      authority = Repository.transaction_authority()

      participants =
        authority.participants
        |> Map.put(:client_store, __MODULE__)
        |> Map.put(:device_authorization_store, __MODULE__)
        |> Map.put(:ciba_authorization_store, __MODULE__)
        |> Map.put(:transaction_store, __MODULE__)

      %{authority | participants: participants}
    end

    def fetch_client_by_id(client_id), do: Repository.fetch_client_by_id(client_id)
    def lock_clients(client_ids), do: Repository.lock_clients(client_ids)
    def transact(fun), do: Repository.transact(fun)
    def store_token(token), do: Repository.store_token(token)
    def append_audit_event(event), do: Repository.append_audit_event(event)

    def record_device_poll(hash, client_id, now) do
      result = Repository.record_device_poll(hash, client_id, now)
      poll_preflight_barrier(:device)
      result
    end

    def record_ciba_poll(hash, client_id, now) do
      result = Repository.record_ciba_poll(hash, client_id, now)
      poll_preflight_barrier(:ciba)
      result
    end

    def transition_device_authorization(handle, expected, attrs) do
      poll_finalizer_barrier(:device)
      Repository.transition_device_authorization(handle, expected, attrs)
    end

    def transition_ciba_authorization(hash, expected, attrs) do
      poll_finalizer_barrier(:ciba)
      Repository.transition_ciba_authorization(hash, expected, attrs)
    end

    defp poll_preflight_barrier(kind) do
      case Process.get({__MODULE__, :poll_barrier}) do
        {owner, ^kind} ->
          send(owner, {:poll_preflight_passed, kind, self()})

          receive do
            {:continue_poll, ^kind} -> :ok
          after
            5_000 -> raise "timed out waiting to continue #{kind} poll"
          end

        _other ->
          :ok
      end
    end

    defp poll_finalizer_barrier(kind) do
      case Process.get({__MODULE__, :poll_barrier}) do
        {owner, ^kind} ->
          send(
            owner,
            {:poll_finalizer_attempt, kind, self(),
             Lockspire.ClientLifetimeRaceHelpers.backend_pid!(Lockspire.TestRepo)}
          )

        _other ->
          :ok
      end
    end
  end

  test "authorization-code redemption rejects secret equality after the code-row wait" do
    suffix = suffix()
    client_id = "secret-code-wait-#{suffix}"
    secret = "secret-code-wait-secret-#{suffix}"
    raw_code = "secret-code-wait-code-#{suffix}"
    verifier = "secret-code-wait-verifier-#{suffix}"
    client = committed_client(client_id, secret, ["authorization_code"])
    {:ok, _code} = committed_code(client, raw_code, verifier)
    on_exit(fn -> cleanup(client_id) end)

    decision_time = decision_time()
    equality = DateTime.add(decision_time, 1, :second)
    set_secret_deadline(client_id, equality)
    before = token_snapshot(client_id, [TokenFormatter.hash_token(raw_code)])

    result =
      run_wait(
        :code,
        client_id,
        "SELECT id FROM lockspire_tokens WHERE token_hash = $1 FOR UPDATE",
        [TokenFormatter.hash_token(raw_code)],
        decision_time,
        equality,
        fn clock ->
          exchange(code_params(raw_code, verifier),
            authorization: basic_auth(client_id, secret),
            now: clock
          )
        end
      )

    assert secret_expired?(result)
    assert token_snapshot(client_id, [TokenFormatter.hash_token(raw_code)]) == before
    assert {:ok, code} = Repository.fetch_authorization_code(TokenFormatter.hash_token(raw_code))
    assert is_nil(code.redeemed_at)
  end

  test "refresh-family rotation rejects secret equality after its family-row wait" do
    suffix = suffix()
    client_id = "secret-refresh-wait-#{suffix}"
    secret = "secret-refresh-wait-secret-#{suffix}"
    raw_refresh = "secret-refresh-wait-token-#{suffix}"
    family_id = "secret-refresh-wait-family-#{suffix}"
    client = committed_client(client_id, secret, ["refresh_token"])
    refresh = committed_refresh(client, raw_refresh, family_id)
    on_exit(fn -> cleanup(client_id) end)

    decision_time = decision_time()
    equality = DateTime.add(decision_time, 1, :second)
    set_secret_deadline(client_id, equality)
    before = token_snapshot(client_id, [refresh.token_hash])

    result =
      run_wait(
        :refresh_family,
        client_id,
        "SELECT id FROM lockspire_tokens WHERE family_id = $1 FOR UPDATE",
        [family_id],
        decision_time,
        equality,
        fn clock ->
          TokenExchange.exchange(%{
            params: %{"grant_type" => "refresh_token", "refresh_token" => raw_refresh},
            authorization: basic_auth(client_id, secret),
            opts: exchange_options(clock)
          })
        end
      )

    assert secret_expired?(result)
    assert token_snapshot(client_id, [refresh.token_hash]) == before
    assert {:ok, current} = Repository.fetch_refresh_token(refresh.token_hash)
    assert is_nil(current.redeemed_at)
    assert is_nil(current.revoked_at)
    assert {:ok, [^current]} = Repository.list_token_family(family_id)
  end

  test "device-code polling rejects secret equality after its authorization-row wait" do
    suffix = suffix()
    client_id = "secret-device-wait-#{suffix}"
    secret = "secret-device-wait-secret-#{suffix}"
    raw_device_code = "secret-device-wait-code-#{suffix}"
    client = committed_client(client_id, secret, ["urn:ietf:params:oauth:grant-type:device_code"])
    authorization = committed_device_authorization(client, raw_device_code, suffix)
    on_exit(fn -> cleanup(client_id) end)

    decision_time = decision_time()
    equality = DateTime.add(decision_time, 1, :second)
    set_secret_deadline(client_id, equality)
    before = token_snapshot(client_id, [])

    result =
      run_poll_wait(
        :device_authorization,
        client_id,
        "SELECT id FROM lockspire_device_authorizations WHERE device_code_hash = $1 FOR UPDATE",
        [authorization.device_code_hash],
        decision_time,
        equality,
        fn clock, owner ->
          poll_exchange(
            client,
            secret,
            "urn:ietf:params:oauth:grant-type:device_code",
            raw_device_code,
            clock,
            owner,
            :device
          )
        end
      )

    assert secret_expired?(result)
    assert token_snapshot(client_id, []) == before

    assert {:ok, current} =
             Repository.fetch_device_authorization_by_verification_handle(
               authorization.verification_handle
             )

    assert current.status == :approved
  end

  test "CIBA polling rejects secret equality after its authorization-row wait" do
    suffix = suffix()
    client_id = "secret-ciba-wait-#{suffix}"
    secret = "secret-ciba-wait-secret-#{suffix}"
    auth_req_id = "secret-ciba-wait-id-#{suffix}"
    client = committed_client(client_id, secret, ["urn:openid:params:grant-type:ciba"])
    authorization = committed_ciba_authorization(client, auth_req_id, suffix)
    on_exit(fn -> cleanup(client_id) end)

    decision_time = decision_time()
    equality = DateTime.add(decision_time, 1, :second)
    set_secret_deadline(client_id, equality)
    before = token_snapshot(client_id, [])

    result =
      run_poll_wait(
        :ciba_authorization,
        client_id,
        "SELECT id FROM lockspire_ciba_authorizations WHERE auth_req_id_hash = $1 FOR UPDATE",
        [authorization.auth_req_id_hash],
        decision_time,
        equality,
        fn clock, owner ->
          poll_exchange(
            client,
            secret,
            "urn:openid:params:grant-type:ciba",
            auth_req_id,
            clock,
            owner,
            :ciba
          )
        end
      )

    assert secret_expired?(result)
    assert token_snapshot(client_id, []) == before

    assert {:ok, current} =
             Repository.fetch_ciba_authorization_by_auth_req_id_hash(
               authorization.auth_req_id_hash
             )

    assert current.status == :approved
  end

  test "RFC 8693 requester rejects secret equality after the input-token wait" do
    suffix = suffix()
    requester_id = "secret-rfc-requester-#{suffix}"
    issuer_id = "secret-rfc-issuer-#{suffix}"
    secret = "secret-rfc-requester-secret-#{suffix}"
    raw_token = "secret-rfc-input-#{suffix}"

    _requester =
      committed_client(requester_id, secret, ["urn:ietf:params:oauth:grant-type:token-exchange"])

    issuer = committed_client(issuer_id, "secret-rfc-issuer-secret-#{suffix}", [])
    input = committed_input_token(issuer, raw_token)

    on_exit(fn ->
      cleanup(requester_id)
      cleanup(issuer_id)
    end)

    decision_time = decision_time()
    equality = DateTime.add(decision_time, 1, :second)
    set_secret_deadline(requester_id, equality)
    before = token_snapshot(requester_id, [input.token_hash])

    result =
      run_wait(
        :rfc_input_token,
        requester_id,
        "SELECT id FROM lockspire_tokens WHERE token_hash = $1 FOR UPDATE",
        [input.token_hash],
        decision_time,
        equality,
        fn clock ->
          TokenExchange.exchange(%{
            params: %{
              "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
              "client_id" => requester_id,
              "subject_token" => raw_token,
              "scope" => "read"
            },
            authorization: basic_auth(requester_id, secret),
            opts: exchange_options(clock)
          })
        end
      )

    assert secret_expired?(result)
    assert token_snapshot(requester_id, [input.token_hash]) == before
    assert {:ok, unchanged} = Repository.fetch_lifecycle_token(input.token_hash)
    assert unchanged == input
  end

  defp run_wait(label, client_id, lock_query, lock_params, before_time, equality, contender_fun) do
    {clock, advance_clock} = Race.barrier_clock(before_time, equality)
    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, {:holder, label}, parent, fn _ ->
        Lockspire.TestRepo.transaction(fn ->
          Lockspire.TestRepo.query!(lock_query, lock_params)
          send(parent, {{:later_row_locked, label}, self()})

          receive do
            :release -> :released
          after
            5_000 -> Lockspire.TestRepo.rollback(:holder_release_timeout)
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!({:holder, label})
    assert_receive {{:later_row_locked, ^label}, ^holder_pid}, 5_000

    contender =
      Race.start_session(Lockspire.TestRepo, {:contender, label}, parent, fn _ ->
        contender_fun.(clock)
      end)

    {_contender_pid, contender_backend_pid} = Race.await_session!({:contender, label})
    refute holder_backend_pid == contender_backend_pid

    try do
      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)

      Race.assert_locked_nowait!(
        Lockspire.TestRepo,
        "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
        [client_id]
      )

      advance_clock.()
    after
      Race.release(holder_pid)
    end

    assert {:ok, :released} = Race.await_task!(holder, 5_000)
    Race.await_task!(contender, 10_000)
  end

  defp run_poll_wait(label, client_id, lock_query, lock_params, before_time, equality, poll_fun) do
    kind = if label == :device_authorization, do: :device, else: :ciba
    {clock, advance_clock} = Race.barrier_clock(before_time, equality)
    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, {:poll_holder, kind}, parent, fn _ ->
        Lockspire.TestRepo.transaction(fn ->
          receive do
            {:acquire_poll_row, ^kind} ->
              Lockspire.TestRepo.query!(lock_query, lock_params)
              send(parent, {:poll_row_locked, kind, self()})

              receive do
                {:release_poll_row, ^kind} -> :released
              after
                5_000 -> Lockspire.TestRepo.rollback(:holder_release_timeout)
              end
          after
            5_000 -> Lockspire.TestRepo.rollback(:holder_acquire_timeout)
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!({:poll_holder, kind})

    contender =
      Race.start_session(Lockspire.TestRepo, {:poll_contender, kind}, parent, fn _ ->
        poll_fun.(clock, parent)
      end)

    {contender_pid, contender_backend_pid} = Race.await_session!({:poll_contender, kind})
    refute holder_backend_pid == contender_backend_pid

    try do
      assert_receive {:poll_preflight_passed, ^kind, ^contender_pid}, 5_000
      Race.release(holder_pid, {:acquire_poll_row, kind})
      assert_receive {:poll_row_locked, ^kind, ^holder_pid}, 5_000
      Race.release(contender_pid, {:continue_poll, kind})

      assert_receive {:poll_finalizer_attempt, ^kind, ^contender_pid, ^contender_backend_pid},
                     5_000

      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)

      Race.assert_locked_nowait!(
        Lockspire.TestRepo,
        "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
        [client_id]
      )

      advance_clock.()
    after
      Race.release(contender_pid, {:continue_poll, kind})
      Race.release(holder_pid, {:release_poll_row, kind})
    end

    assert {:ok, :released} = Race.await_task!(holder, 5_000)
    Race.await_task!(contender, 10_000)
  end

  defp committed_client(client_id, secret, grants) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        create_client(client_id, :client_secret_basic, secret, grants, %{
          access_token_format: :opaque,
          allowed_scopes: ["email", "read", "offline_access"]
        })

      client
    end)
  end

  defp committed_code(client, raw_code, verifier) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      create_authorization_code(client, raw_code: raw_code, code_verifier: verifier)
    end)
  end

  defp committed_refresh(client, raw, family_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, token} =
        Repository.store_token(%Token{
          token_hash: TokenFormatter.hash_token(raw),
          token_type: :refresh_token,
          family_id: family_id,
          generation: 0,
          client_id: client.client_id,
          account_id: "subject-#{client.client_id}",
          scopes: ["email", "offline_access"],
          audience: [],
          issued_at: DateTime.utc_now(),
          expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
        })

      token
    end)
  end

  defp committed_device_authorization(client, raw_device_code, suffix) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      now = DateTime.add(DateTime.utc_now(), 600, :second) |> DateTime.truncate(:second)

      authorization =
        DeviceAuthorization.issue(
          %{
            client_id: client.client_id,
            device_code: raw_device_code,
            user_code: "BCDFGH#{System.unique_integer([:positive])}",
            scopes: ["email"]
          },
          now: DateTime.add(now, -10, :second)
        )

      {:ok, _} = Repository.put_device_authorization(authorization)

      {:ok, approved} =
        Repository.transition_device_authorization(
          authorization.verification_handle,
          [:pending],
          %{status: :approved, subject_id: "subject-#{suffix}", approved_at: now}
        )

      approved
    end)
  end

  defp committed_ciba_authorization(client, auth_req_id, suffix) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      now = DateTime.add(DateTime.utc_now(), 600, :second) |> DateTime.truncate(:second)

      authorization =
        CibaAuthorization.issue(
          %{auth_req_id: auth_req_id, client_id: client.client_id, scopes: ["email"]},
          now: DateTime.add(now, -10, :second)
        )

      {:ok, _} = Repository.put_ciba_authorization(authorization)

      {:ok, approved} =
        Repository.transition_ciba_authorization(
          authorization.auth_req_id_hash,
          [:pending],
          %{status: :approved, subject_id: "subject-#{suffix}", approved_at: now}
        )

      approved
    end)
  end

  defp committed_input_token(issuer, raw_token) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, token} =
        Repository.store_token(%Token{
          token_hash: Policy.hash_token(raw_token),
          token_type: :access_token,
          family_id: "family-#{raw_token}",
          generation: 1,
          client_id: issuer.client_id,
          account_id: "account-#{raw_token}",
          scopes: ["read"],
          audience: ["api.example.test"],
          issued_at: DateTime.add(DateTime.utc_now(), -1, :second),
          expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
        })

      token
    end)
  end

  defp set_secret_deadline(client_id, deadline) do
    assert {1, _} =
             Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
               Lockspire.TestRepo.update_all(
                 from(record in ClientRecord, where: record.client_id == ^client_id),
                 set: [lifetime_version: 1, client_secret_expires_at: deadline]
               )
             end)
  end

  defp exchange_options(clock) do
    [
      client_store: Repository,
      token_store: Repository,
      transaction_store: Repository,
      audit_store: Repository,
      interaction_store: Repository,
      key_store: Repository,
      server_policy_store: Repository,
      token_exchange_validator: ExchangeValidator,
      now: clock,
      access_token_generator: fn -> "opaque-access-#{Ecto.UUID.generate()}" end,
      refresh_token_generator: fn -> "opaque-refresh-#{Ecto.UUID.generate()}" end
    ]
  end

  defp poll_exchange(client, secret, grant_type, raw_grant, clock, owner, kind) do
    param = if String.contains?(grant_type, "ciba"), do: "auth_req_id", else: "device_code"
    Process.put({BlockingPollStore, :poll_barrier}, {owner, kind})

    store_key = if kind == :ciba, do: :ciba_authorization_store, else: :device_authorization_store

    TokenExchange.exchange(%{
      params: %{"grant_type" => grant_type, "client_id" => client.client_id, param => raw_grant},
      authorization: basic_auth(client.client_id, secret),
      opts:
        exchange_options(clock)
        |> Keyword.put(:client_store, BlockingPollStore)
        |> Keyword.put(:transaction_store, BlockingPollStore)
        |> Keyword.put(store_key, BlockingPollStore)
    })
  end

  defp code_params(raw_code, verifier) do
    %{
      "grant_type" => "authorization_code",
      "code" => raw_code,
      "code_verifier" => verifier,
      "redirect_uri" => "https://client.example.com/callback"
    }
  end

  defp token_snapshot(client_id, token_hashes) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {Lockspire.TestRepo.all(
         from(token in TokenRecord,
           where: token.client_id == ^client_id or token.token_hash in ^token_hashes,
           order_by: [asc: token.token_hash]
         )
       ),
       Lockspire.TestRepo.all(
         from(event in AuditEventRecord,
           where: event.resource_type == "client" and event.resource_id == ^client_id,
           order_by: [asc: event.id]
         )
       )}
    end)
  end

  defp secret_expired?(
         {:error, %{status: 401, error: "invalid_client", reason_code: :client_secret_expired}}
       ),
       do: true

  defp secret_expired?(_result), do: false

  defp cleanup(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      Lockspire.TestRepo.delete_all(
        from(event in AuditEventRecord, where: event.resource_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(token in TokenRecord, where: token.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(record in DeviceAuthorizationRecord, where: record.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(record in CibaAuthorizationRecord, where: record.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(interaction in InteractionRecord, where: interaction.client_id == ^client_id)
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
