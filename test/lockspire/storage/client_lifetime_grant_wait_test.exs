defmodule Lockspire.Storage.ClientLifetimeGrantWaitTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Domain.Token
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.CibaAuthorizationRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.TokenRecord

  @moduletag :integration

  defmodule OpposingOrderValidator do
    def validate(context) do
      owner = Process.get({__MODULE__, :owner})
      request = Process.get({__MODULE__, :request})
      send(owner, {:rfc_validated, self(), request, context})

      receive do
        :continue -> :ok
      after
        5_000 -> {:error, :validator_barrier_timeout}
      end
    end
  end

  test "code redemption resamples app eligibility after a confirmed grant-row wait" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-grant-wait-#{suffix}"
    raw_code = "grant-wait-code-#{suffix}"
    verifier = "grant-wait-verifier-#{suffix}"
    raw_secret = "grant-wait-secret-#{suffix}"
    code_hash = Lockspire.Protocol.TokenFormatter.hash_token(raw_code)
    fixture(client_id, raw_secret, raw_code, verifier)
    on_exit(fn -> cleanup(client_id) end)

    decision_time = DateTime.add(DateTime.utc_now(), 3, :second) |> DateTime.truncate(:second)
    equality = DateTime.add(decision_time, 1, :second)
    {clock, advance_clock} = Race.barrier_clock(decision_time, equality)

    assert {1, _} =
             Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
               Lockspire.TestRepo.update_all(
                 from(record in ClientRecord, where: record.client_id == ^client_id),
                 set: [lifetime_version: 1, client_expires_at: equality]
               )
             end)

    before = durable_counts(client_id)
    parent = self()

    grant_holder =
      Race.start_session(Lockspire.TestRepo, :grant_holder, parent, fn _ ->
        Lockspire.TestRepo.transaction(fn ->
          code =
            TokenRecord
            |> where([token], token.token_hash == ^code_hash)
            |> lock("FOR UPDATE")
            |> Lockspire.TestRepo.one!()

          send(parent, {:grant_row_locked, self(), code.id})

          receive do
            :release_grant -> :released
          after
            5_000 -> Lockspire.TestRepo.rollback(:holder_release_timeout)
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!(:grant_holder)
    assert_receive {:grant_row_locked, ^holder_pid, _grant_id}, 5_000

    contender =
      Race.start_session(Lockspire.TestRepo, :grant_contender, parent, fn _ ->
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

    {_contender_pid, contender_backend_pid} = Race.await_session!(:grant_contender)
    refute holder_backend_pid == contender_backend_pid

    try do
      Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)

      Race.assert_locked_nowait!(
        Lockspire.TestRepo,
        "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
        [client_id]
      )

      advance_clock.()
      send(parent, {:grant_wait_proven, holder_backend_pid, contender_backend_pid})
      assert_receive {:grant_wait_proven, ^holder_backend_pid, ^contender_backend_pid}, 500
    after
      Race.release(holder_pid, :release_grant)
    end

    assert {:ok, :released} = Race.await_task!(grant_holder, 5_000)
    assert {:error, error} = Race.await_task!(contender, 10_000)
    assert error.error in ["invalid_client", "invalid_grant"]
    assert durable_counts(client_id) == before

    assert {:ok, code} = Repository.fetch_authorization_code(code_hash)
    assert is_nil(code.redeemed_at)
  end

  test "queued push delivery begins after client and CIBA issuance locks are released", context do
    Req.Test.verify_on_exit!(context)
    Req.Test.set_req_test_from_context(context)

    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-push-lock-release-#{suffix}"
    now = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
    deadline = DateTime.add(now, 20, :second)
    {_client, ciba_authorization_id} = push_fixture(client_id, now, deadline)
    on_exit(fn -> cleanup(client_id) end)
    Application.put_env(:lockspire, :ciba_notification_now, fn -> now end)

    Application.put_env(:lockspire, :backchannel_ciba_req,
      plug: {Req.Test, __MODULE__},
      retry: false
    )

    Req.Test.expect(__MODULE__, fn request ->
      Race.assert_available_nowait!(
        Lockspire.TestRepo,
        "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
        [client_id]
      )

      Race.assert_available_nowait!(
        Lockspire.TestRepo,
        "SELECT id FROM lockspire_ciba_authorizations WHERE id = $1 FOR UPDATE NOWAIT",
        [ciba_authorization_id]
      )

      assert request.body_params["expires_in"] == 20
      Req.Test.json(request, %{status: "ok"})
    end)

    assert :ok =
             Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
               Lockspire.Workers.CibaNotificationWorker.perform(%Oban.Job{
                 args: %{"ciba_authorization_id" => ciba_authorization_id}
               })
             end)
  end

  test "opposing RFC 8693 subject and actor orders complete with both current identities" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    now = DateTime.add(DateTime.utc_now(), 30, :second) |> DateTime.truncate(:second)
    requester_a = rfc_client("rfc-order-a-#{suffix}")
    requester_b = rfc_client("rfc-order-b-#{suffix}")
    issuer_a = rfc_client("rfc-order-issuer-a-#{suffix}")
    issuer_b = rfc_client("rfc-order-issuer-b-#{suffix}")

    on_exit(fn ->
      Enum.each([requester_a, requester_b, issuer_a, issuer_b], &cleanup(&1.client_id))
    end)

    {subject_a, raw_a} = rfc_input_token(issuer_a, "rfc-order-subject-a-#{suffix}", now)
    {subject_b, raw_b} = rfc_input_token(issuer_b, "rfc-order-subject-b-#{suffix}", now)

    owner = self()
    parent = self()

    task_a =
      Race.start_session(Lockspire.TestRepo, :rfc_order_a, parent, fn _ ->
        Process.put({OpposingOrderValidator, :owner}, owner)
        Process.put({OpposingOrderValidator, :request}, :a)
        rfc_exchange(requester_a, raw_a, raw_b, now)
      end)

    task_b =
      Race.start_session(Lockspire.TestRepo, :rfc_order_b, parent, fn _ ->
        Process.put({OpposingOrderValidator, :owner}, owner)
        Process.put({OpposingOrderValidator, :request}, :b)
        rfc_exchange(requester_b, raw_b, raw_a, now)
      end)

    {_pid_a, backend_a} = Race.await_session!(:rfc_order_a)
    {_pid_b, backend_b} = Race.await_session!(:rfc_order_b)
    refute backend_a == backend_b

    validated = Map.new([await_validated(), await_validated()], fn {request, pid, context} ->
      {request, {pid, context}}
    end)
    {validator_a, context_a} = Map.fetch!(validated, :a)
    {validator_b, context_b} = Map.fetch!(validated, :b)

    assert context_a.subject_token.client_id == issuer_a.client_id
    assert context_a.actor_token_identity.client_id == issuer_b.client_id
    assert context_b.subject_token.client_id == issuer_b.client_id
    assert context_b.actor_token_identity.client_id == issuer_a.client_id

    send(validator_a, :continue)
    send(validator_b, :continue)

    assert {:ok, _} = Race.await_task!(task_a, 10_000)
    assert {:ok, _} = Race.await_task!(task_b, 10_000)

    assert {:ok, current_a} = Repository.fetch_lifecycle_token(subject_a.token_hash)
    assert {:ok, current_b} = Repository.fetch_lifecycle_token(subject_b.token_hash)
    assert current_a.client_id == issuer_a.client_id
    assert current_b.client_id == issuer_b.client_id
  end

  defp fixture(client_id, secret, raw_code, verifier) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        create_client(client_id, :client_secret_basic, secret, ["authorization_code"], %{
          access_token_format: :opaque
        })

      {:ok, _code} =
        create_authorization_code(client, raw_code: raw_code, code_verifier: verifier)

      :ok
    end)
  end

  defp push_fixture(client_id, now, deadline) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        Repository.register_client(%Lockspire.Domain.Client{
          lifetime_version: 1,
          client_id: client_id,
          name: client_id,
          client_type: :public,
          token_endpoint_auth_method: :none,
          allowed_grant_types: ["urn:openid:params:grant-type:ciba"],
          allowed_scopes: ["email"],
          backchannel_token_delivery_mode: :push,
          backchannel_client_notification_endpoint: "https://rp.example.test/push",
          access_token_format: :opaque,
          client_expires_at: deadline,
          created_at: now
        })

      auth_req_id = "#{client_id}-request"

      authorization =
        Lockspire.Domain.CibaAuthorization.issue(
          %{
            auth_req_id: auth_req_id,
            client_id: client_id,
            scopes: ["email"],
            delivery_mode: :push,
            client_notification_endpoint: "https://rp.example.test/push",
            client_notification_token_encrypted: "notification-token"
          },
          now: DateTime.add(now, -10, :second)
        )

      {:ok, _stored} = Repository.put_ciba_authorization(authorization)

      {:ok, approved} =
        Repository.transition_ciba_authorization(
          authorization.auth_req_id_hash,
          [:pending],
          %{status: :approved, subject_id: "subject-#{client_id}", approved_at: now}
        )

      {client, approved.id}
    end)
  end

  defp rfc_client(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        Repository.register_client(%Lockspire.Domain.Client{
          lifetime_version: 1,
          client_id: client_id,
          name: client_id,
          client_type: :public,
          token_endpoint_auth_method: :none,
          allowed_grant_types: ["urn:ietf:params:oauth:grant-type:token-exchange"],
          allowed_scopes: ["read"],
          access_token_format: :opaque,
          created_at: DateTime.utc_now()
        })

      client
    end)
  end

  defp rfc_input_token(issuer, raw, now) do
    token = %Token{
      token_hash: Policy.hash_token(raw),
      token_type: :access_token,
      family_id: "family-#{raw}",
      generation: 1,
      client_id: issuer.client_id,
      account_id: "account-#{issuer.client_id}",
      scopes: ["read"],
      audience: ["api.example.test"],
      issued_at: DateTime.add(now, -1, :second),
      expires_at: DateTime.add(now, 600, :second)
    }

    assert {:ok, stored} =
             Sandbox.unboxed_run(Lockspire.TestRepo, fn -> Repository.store_token(token) end)

    {stored, raw}
  end

  defp rfc_exchange(requester, subject_raw, actor_raw, now) do
    TokenExchange.exchange(%{
      params: %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
        "subject_token" => subject_raw,
        "actor_token" => actor_raw,
        "scope" => "read",
        "client_id" => requester.client_id
      },
      authorization: nil,
      opts: [
        client_store: Repository,
        client_lifetime: nil,
        token_store: Repository,
        transaction_store: Repository,
        audit_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        server_policy_store: Repository,
        token_exchange_validator: OpposingOrderValidator,
        now: fn -> now end
      ]
    })
  end

  defp await_validated do
    receive do
      {:rfc_validated, pid, request, context} -> {request, pid, context}
    after
      5_000 -> flunk("RFC 8693 request did not reach its pre-lock barrier")
    end
  end

  defp durable_counts(client_id) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      tokens =
        Lockspire.TestRepo.aggregate(
          from(token in TokenRecord, where: token.client_id == ^client_id),
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
        from(authorization in CibaAuthorizationRecord,
          where: authorization.client_id == ^client_id
        )
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
