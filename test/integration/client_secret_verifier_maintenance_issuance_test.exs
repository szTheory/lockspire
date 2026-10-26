defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceIssuanceTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.ConsentGrantRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.UsedJtiRecord
  alias Lockspire.TestRepo
  alias Lockspire.TestSupport.ClientVerifierMaintenanceConcurrency, as: Concurrency

  @moduletag :integration

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
    old_context = verifier_context([{"race-old", old_key}], "race-old")
    current_context = verifier_context([{"race-old", old_key}, {"race-new", new_key}], "race-new")
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)
    :persistent_term.put(cache_key, current_context)

    on_exit(fn ->
      if previous_context == :missing,
        do: :persistent_term.erase(cache_key),
        else: :persistent_term.put(cache_key, previous_context)
    end)

    %{old_context: old_context}
  end

  test "committed maintenance between JWT authentication and issuance rejects stale identity and permits a fresh-JTI retry",
       %{old_context: old_context} do
    fixture = persisted_jwt_client(old_context)
    before = effects(fixture.client.client_id)
    parent = self()
    barrier_ref = make_ref()

    exchange =
      Task.async(fn ->
        Sandbox.unboxed_run(TestRepo, fn ->
          Process.put(:maintenance_issuance_barrier, {parent, barrier_ref})

          try do
            exchange_guarded(fixture, "maintenance-race-jti")
          after
            Process.delete(:maintenance_issuance_barrier)
          end
        end)
      end)

    assert_receive {:issuance_barrier, ^barrier_ref, :authenticated, exchange_pid,
                    exchange_backend, client_id},
                   10_000

    assert exchange_pid == exchange.pid
    assert client_id == fixture.client.client_id
    send(exchange_pid, {:continue_issuance, barrier_ref, :authenticated})

    assert_receive {:issuance_barrier, ^barrier_ref, :current_row_guard, ^exchange_pid,
                    ^exchange_backend, ^client_id},
                   10_000

    after_authentication = effects(client_id)
    assert after_authentication.jtis == before.jtis + 1
    assert after_authentication.tokens == before.tokens
    assert after_authentication.grants == before.grants
    assert after_authentication.code_redeemed_at == before.code_redeemed_at

    maintenance =
      Concurrency.run(TestRepo, self(), :maintenance, fn ->
        Lockspire.Storage.ClientVerifierMaintenance.rewrap_client(client_id)
      end)

    assert_receive {:operation_ready, :maintenance, maintenance_pid, maintenance_backend}, 10_000
    assert maintenance_pid == maintenance.pid
    refute maintenance_backend == exchange_backend
    assert_receive {:operation_done, :maintenance, {:ok, :changed}}, 10_000
    assert {:ok, :changed} = Task.await(maintenance, 10_000)

    assert {:ok, maintained} = fetch_client(client_id)
    assert maintained.client_secret_hash == fixture.client.client_secret_hash
    refute maintained.client_secret_jwt_verifier_encrypted == fixture.encrypted

    send(exchange_pid, {:continue_issuance, barrier_ref, :current_row_guard})

    assert {:error,
            %TokenExchange.Error{error: "invalid_client", reason_code: :credential_changed}} =
             Task.await(exchange, 10_000)

    after_guard = effects(client_id)
    assert after_guard.jtis == before.jtis + 1
    assert after_guard.tokens == before.tokens
    assert after_guard.grants == before.grants
    assert after_guard.code_redeemed_at == before.code_redeemed_at

    replay =
      Sandbox.unboxed_run(TestRepo, fn -> exchange_guarded(fixture, "maintenance-race-jti") end)

    assert {:error,
            %TokenExchange.Error{error: "invalid_client", reason_code: :client_assertion_replayed}} =
             replay

    assert effects(client_id) == after_guard

    retry =
      Sandbox.unboxed_run(TestRepo, fn -> exchange_guarded(fixture, "maintenance-fresh-jti") end)

    assert {:ok, %{access_token: access_token}} = retry
    assert is_binary(access_token)

    after_retry = effects(client_id)
    assert after_retry.jtis == after_guard.jtis + 1
    assert after_retry.tokens == after_guard.tokens + 1
    assert %DateTime{} = after_retry.code_redeemed_at
    assert after_retry.grants >= after_guard.grants
  end

  defmodule ClientStore do
    alias Lockspire.Storage.Ecto.Repository
    alias Lockspire.TestSupport.ClientVerifierMaintenanceConcurrency, as: Concurrency

    def lifetime_contract,
      do: %{
        version: 1,
        transaction_authority:
          Lockspire.Integration.ClientSecretVerifierMaintenanceIssuanceTest.TransactionStore.transaction_authority()
      }

    def fetch_client_by_id(client_id), do: Repository.fetch_client_by_id(client_id)

    def record_used_jti(jti) do
      result = Repository.record_used_jti(jti)

      case {Process.get(:maintenance_issuance_barrier), result} do
        {{parent, ref}, {:ok, :accepted}} ->
          Concurrency.pause_at(Lockspire.TestRepo, parent, ref, :authenticated, jti.client_id)
          result

        _ ->
          result
      end
    end

    def lock_clients(ids) do
      case Process.get(:maintenance_issuance_barrier) do
        {parent, ref} ->
          [client_id] = ids
          Concurrency.pause_at(Lockspire.TestRepo, parent, ref, :current_row_guard, client_id)

        _ ->
          :ok
      end

      Repository.lock_clients(ids)
    end
  end

  defmodule TransactionStore do
    alias Lockspire.Storage.Ecto.Repository

    def transaction_authority do
      base = Repository.transaction_authority()

      %{
        base
        | identity: {:client_secret_verifier_maintenance_issuance, base.identity},
          participants:
            base.participants
            |> Map.put(
              :client_store,
              Lockspire.Integration.ClientSecretVerifierMaintenanceIssuanceTest.ClientStore
            )
            |> Map.put(:transaction_store, __MODULE__)
      }
    end

    def transact(fun), do: Repository.transact(fun)
    def rollback(reason), do: Repository.rollback(reason)
  end

  defp persisted_jwt_client(old_context) do
    suffix = Ecto.UUID.generate()
    client_id = "maintenance-race-client-#{suffix}"
    secret = "maintenance-race-secret-#{suffix}"

    {:ok, client} =
      Sandbox.unboxed_run(TestRepo, fn ->
        Lockspire.TokenExchangeCase.create_client(client_id, :client_secret_jwt, secret)
      end)

    encrypted = seal(old_context, client_id, secret)

    Sandbox.unboxed_run(TestRepo, fn ->
      from(row in ClientRecord, where: row.client_id == ^client_id)
      |> TestRepo.update_all(set: [client_secret_jwt_verifier_encrypted: encrypted])

      Lockspire.TokenExchangeCase.publish_signing_key("maintenance-race-kid-#{suffix}")

      raw_code = "maintenance-race-code-#{suffix}"
      code_verifier = "maintenance-race-pkce-#{suffix}"

      {:ok, _} =
        Lockspire.TokenExchangeCase.create_authorization_code(client,
          raw_code: raw_code,
          code_verifier: code_verifier
        )

      %{raw_code: raw_code, code_verifier: code_verifier}
    end)
    |> then(fn code ->
      on_exit(fn -> cleanup(client_id, "maintenance-race-kid-#{suffix}") end)
      Map.merge(%{client: client, secret: secret, encrypted: encrypted}, code)
    end)
  end

  defp exchange_guarded(fixture, jti) do
    assertion = signed_assertion(fixture.client.client_id, fixture.secret, jti)

    TokenExchange.exchange_authorization_code(%{
      params: %{
        "grant_type" => "authorization_code",
        "code" => fixture.raw_code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => fixture.code_verifier,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => assertion
      },
      opts: [
        client_store: ClientStore,
        token_store: Repository,
        transaction_store: TransactionStore,
        audit_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        server_policy_store: Repository,
        now: fn -> DateTime.utc_now() end,
        access_token_generator: fn -> "maintenance-race-access-#{Ecto.UUID.generate()}" end,
        refresh_token_generator: fn -> "maintenance-race-refresh-#{Ecto.UUID.generate()}" end
      ]
    })
  end

  defp effects(client_id) do
    Sandbox.unboxed_run(TestRepo, fn ->
      %{
        jtis:
          TestRepo.aggregate(
            from(jti in UsedJtiRecord, where: jti.client_id == ^client_id),
            :count
          ),
        tokens:
          TestRepo.aggregate(
            from(token in TokenRecord,
              where: token.client_id == ^client_id and token.token_type != :authorization_code
            ),
            :count
          ),
        grants:
          TestRepo.aggregate(
            from(grant in ConsentGrantRecord, where: grant.client_id == ^client_id),
            :count
          ),
        code_redeemed_at:
          TestRepo.one(
            from(token in TokenRecord,
              where: token.client_id == ^client_id and token.token_type == :authorization_code,
              select: token.redeemed_at
            )
          )
      }
    end)
  end

  defp fetch_client(client_id),
    do: Sandbox.unboxed_run(TestRepo, fn -> Repository.fetch_client_by_id(client_id) end)

  defp cleanup(client_id, kid) do
    Sandbox.unboxed_run(TestRepo, fn ->
      interaction_ids =
        TestRepo.all(
          from(token in TokenRecord,
            where: token.client_id == ^client_id,
            select: token.interaction_id
          )
        )

      TestRepo.delete_all(from(event in AuditEventRecord, where: event.resource_id == ^client_id))
      TestRepo.delete_all(from(grant in ConsentGrantRecord, where: grant.client_id == ^client_id))
      TestRepo.delete_all(from(jti in UsedJtiRecord, where: jti.client_id == ^client_id))
      TestRepo.delete_all(from(token in TokenRecord, where: token.client_id == ^client_id))

      TestRepo.delete_all(
        from(interaction in InteractionRecord,
          where: interaction.interaction_id in ^interaction_ids
        )
      )

      TestRepo.delete_all(from(client in ClientRecord, where: client.client_id == ^client_id))

      TestRepo.delete_all(
        from(key in Lockspire.Storage.Ecto.SigningKeyRecord, where: key.kid == ^kid)
      )
    end)
  end

  defp signed_assertion(client_id, secret, jti) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    JOSE.JWK.from_oct(secret)
    |> JOSE.JWT.sign(%{"alg" => "HS256"}, %{
      "iss" => client_id,
      "sub" => client_id,
      "aud" => "https://example.test/lockspire",
      "jti" => jti,
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.to_unix(DateTime.add(now, 300, :second))
    })
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp seal(context, client_id, secret) do
    {:ok, encrypted} = ClientSecretVerifier.seal(context, client_id, secret)
    encrypted
  end

  defp verifier_context(keys, current) do
    {:ok, context} =
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

    {:ok, validated} = Context.validate(context)
    validated
  end
end
