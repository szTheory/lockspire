defmodule Lockspire.Storage.ClientSecretLifetimeClientWaitTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Admin.Clients
  alias Lockspire.ClientLifetimeRaceHelpers, as: Race
  alias Lockspire.Domain.Client
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.InteractionRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.UsedJtiRecord

  @moduletag :integration
  @moduletag :postgres_race

  test "a preverified secret is rejected at equality after a confirmed client-row wait" do
    suffix = suffix()
    client_id = "secret-client-wait-#{suffix}"
    secret = "secret-wait-basic-#{suffix}"
    raw_code = "secret-wait-code-#{suffix}"
    verifier = "secret-wait-verifier-#{suffix}"
    client = committed_client(client_id, secret, :client_secret_basic)
    {:ok, _code} = committed_code(client, raw_code, verifier)
    on_exit(fn -> cleanup(client_id) end)

    decision_time = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
    equality = DateTime.add(decision_time, 1, :second)
    {clock, advance_clock} = Race.barrier_clock(decision_time, equality)

    assert {1, _} =
             Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
               Lockspire.TestRepo.update_all(
                 from(record in ClientRecord, where: record.client_id == ^client_id),
                 set: [lifetime_version: 1, client_secret_expires_at: equality]
               )
             end)

    before = issuance_snapshot(client_id, raw_code)
    parent = self()

    holder =
      Race.start_session(Lockspire.TestRepo, :expiry_holder, parent, fn _ ->
        Repository.transact(fn ->
          {:ok, [_]} = Repository.lock_clients([client_id])
          send(parent, {:expiry_client_locked, self()})

          receive do
            :release -> {:ok, :released}
          after
            5_000 -> {:error, :holder_release_timeout}
          end
        end)
      end)

    {holder_pid, holder_backend_pid} = Race.await_session!(:expiry_holder)
    assert_receive {:expiry_client_locked, ^holder_pid}, 5_000

    contender =
      Race.start_session(Lockspire.TestRepo, :expiry_contender, parent, fn _ ->
        exchange(
          code_params(raw_code, verifier),
          authorization: basic_auth(client_id, secret),
          now: clock
        )
      end)

    {_contender_pid, contender_backend_pid} = Race.await_session!(:expiry_contender)
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

    assert {:ok, :released} = Race.await_task!(holder)

    assert {:error, %{status: 401, error: "invalid_client", reason_code: :client_secret_expired}} =
             Race.await_task!(contender, 10_000)

    assert issuance_snapshot(client_id, raw_code) == before
    assert {:ok, code} = Repository.fetch_authorization_code(TokenFormatter.hash_token(raw_code))
    assert is_nil(code.redeemed_at)
    assert {:ok, current} = Repository.fetch_client_by_id(client_id)
    assert DateTime.compare(current.client_secret_expires_at, equality) == :eq
  end

  test "a committed operator rotation invalidates preverified Basic and secret-JWT identities" do
    for method <- [:client_secret_basic, :client_secret_jwt] do
      suffix = suffix()
      client_id = "secret-rotation-wait-#{method}-#{suffix}"
      secret = "secret-rotation-old-#{suffix}"
      raw_code = "secret-rotation-code-#{suffix}"
      verifier = "secret-rotation-verifier-#{suffix}"
      {client, assertion, jti} = committed_authenticated_client(client_id, secret, method)
      {:ok, _code} = committed_code(client, raw_code, verifier)
      on_exit(fn -> cleanup(client_id) end)

      decision_time = DateTime.add(DateTime.utc_now(), 5, :second) |> DateTime.truncate(:second)
      before = issuance_snapshot(client_id, raw_code)
      parent = self()

      holder =
        Race.start_session(Lockspire.TestRepo, {:rotation_holder, method}, parent, fn _ ->
          Repository.transact(fn ->
            {:ok, [_]} = Repository.lock_clients([client_id])
            send(parent, {{:rotation_client_locked, method}, self()})

            receive do
              {:rotate, rotation_now} ->
                result =
                  Clients.rotate_client_secret(client_id, %{
                    now: fn -> rotation_now end,
                    actor: %{type: :operator, id: "postgres-race-test"}
                  })

                send(parent, {{:rotation_result, method}, self(), result})
                {:ok, :released}
            after
              5_000 -> {:error, :holder_release_timeout}
            end
          end)
        end)

      {holder_pid, holder_backend_pid} = Race.await_session!({:rotation_holder, method})
      assert_receive {{:rotation_client_locked, ^method}, ^holder_pid}, 5_000

      contender =
        Race.start_session(Lockspire.TestRepo, {:rotation_contender, method}, parent, fn _ ->
          exchange(
            code_params(raw_code, verifier, assertion),
            Keyword.put(auth_opts(client_id, secret, method), :now, fn -> decision_time end)
          )
        end)

      {_contender_pid, contender_backend_pid} = Race.await_session!({:rotation_contender, method})
      refute holder_backend_pid == contender_backend_pid

      rotation =
        try do
          Race.await_blocker!(Lockspire.TestRepo, contender_backend_pid, holder_backend_pid)

          Race.assert_locked_nowait!(
            Lockspire.TestRepo,
            "SELECT id FROM lockspire_clients WHERE client_id = $1 FOR UPDATE NOWAIT",
            [client_id]
          )

          Race.release(holder_pid, {:rotate, decision_time})

          assert_receive {{:rotation_result, ^method}, ^holder_pid,
                          {:ok, %{client_secret: replacement, client: rotated}}},
                         5_000

          assert Policy.verify_client_secret(rotated.client_secret_hash, replacement)
          %{client_secret: replacement}
        after
          Race.release(holder_pid, {:rotate, decision_time})
        end

      replacement = rotation.client_secret

      assert {:ok, :released} = Race.await_task!(holder)

      assert {:error, %{status: 401, error: "invalid_client", reason_code: :credential_changed}} =
               Race.await_task!(contender, 10_000)

      assert issuance_snapshot(client_id, raw_code) == before
      assert {:ok, current} = Repository.fetch_client_by_id(client_id)
      assert Policy.verify_client_secret(current.client_secret_hash, replacement)
      refute Policy.verify_client_secret(current.client_secret_hash, secret)

      rotation_audits =
        Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
          Lockspire.TestRepo.all(
            from(event in AuditEventRecord,
              where: event.resource_id == ^client_id and event.action == "client_secret_rotated"
            )
          )
        end)

      assert length(rotation_audits) == 1

      if method == :client_secret_jwt do
        assert Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
                 Lockspire.TestRepo.get_by(UsedJtiRecord, client_id: client_id, jti: jti)
               end)

        refute_receive {:token_exchange, :replay_detected, _}, 0
      end
    end
  end

  defp committed_client(client_id, secret, method) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        create_client(client_id, method, secret, ["authorization_code"], %{
          access_token_format: :opaque
        })

      client
    end)
  end

  defp committed_authenticated_client(client_id, secret, :client_secret_basic) do
    {committed_client(client_id, secret, :client_secret_basic), nil, nil}
  end

  defp committed_authenticated_client(client_id, secret, :client_secret_jwt) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      {:ok, client} =
        Repository.register_client(%Client{
          lifetime_version: 1,
          client_id: client_id,
          client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret),
          client_type: :confidential,
          name: "Secret JWT Wait #{client_id}",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["email", "profile"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_jwt,
          pkce_required: true,
          access_token_format: :opaque,
          subject_type: :public,
          created_at: DateTime.utc_now(),
          metadata: %{}
        })

      now = DateTime.utc_now() |> DateTime.truncate(:second)
      jti = "secret-rotation-jti-#{client_id}"

      assertion =
        Lockspire.JarTestHelpers.sign_jar(
          JOSE.JWK.from_oct(secret),
          %{
            "iss" => client_id,
            "sub" => client_id,
            "aud" => Lockspire.Config.issuer!(),
            "jti" => jti,
            "iat" => DateTime.to_unix(now),
            "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
          },
          alg: "HS256"
        )

      {client, assertion, jti}
    end)
  end

  defp committed_code(client, raw_code, verifier) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      create_authorization_code(client, raw_code: raw_code, code_verifier: verifier)
    end)
  end

  defp code_params(raw_code, verifier, nil), do: code_params(raw_code, verifier)

  defp code_params(raw_code, verifier, assertion) do
    code_params(raw_code, verifier)
    |> Map.merge(%{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
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

  defp auth_opts(client_id, secret, :client_secret_basic),
    do: [authorization: basic_auth(client_id, secret)]

  defp auth_opts(_client_id, _secret, :client_secret_jwt), do: []

  defp issuance_snapshot(client_id, raw_code) do
    Sandbox.unboxed_run(Lockspire.TestRepo, fn ->
      code_hash = TokenFormatter.hash_token(raw_code)

      {Lockspire.TestRepo.get_by!(TokenRecord, token_hash: code_hash),
       Lockspire.TestRepo.all(from(token in TokenRecord, where: token.client_id == ^client_id)),
       Lockspire.TestRepo.all(
         from(event in AuditEventRecord,
           where:
             event.resource_type == "client" and event.resource_id == ^client_id and
               event.action != "client_secret_rotated"
         )
       )}
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
        from(jti in UsedJtiRecord, where: jti.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(interaction in InteractionRecord, where: interaction.client_id == ^client_id)
      )

      Lockspire.TestRepo.delete_all(
        from(client in ClientRecord, where: client.client_id == ^client_id)
      )
    end)
  end

  defp suffix, do: Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
end
