defmodule Lockspire.Storage.ClientLifetimeRollbackTest do
  use Lockspire.TokenExchangeCase, async: false

  import Ecto.Query

  alias Lockspire.Domain.Token
  alias Lockspire.Admin.Clients
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Security.Policy

  @moduletag :integration

  defmodule AuditFailureValidator do
    def validate(_context), do: :ok
  end

  test "grant consumption and output token both roll back when audit insertion fails" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-rollback-code-#{suffix}"
    raw_code = "rollback-code-#{suffix}"
    {:ok, client} = create_client(client_id, :client_secret_basic, "secret-#{suffix}")

    {:ok, code} =
      create_authorization_code(client,
        raw_code: raw_code,
        code_verifier: "rollback-verifier-#{suffix}"
      )

    before_token_count = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audit_count = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    access = %Token{
      token_hash: TokenFormatter.hash_token("rollback-access-#{suffix}"),
      token_type: :access_token,
      client_id: client_id,
      account_id: code.account_id,
      interaction_id: code.interaction_id,
      scopes: code.scopes,
      issued_at: now,
      expires_at: DateTime.add(now, 60, :second)
    }

    assert {:error, _reason} =
             Repository.transact(fn ->
               with {:ok, _redeemed} <-
                      Repository.mark_authorization_code_redeemed(code.token_hash, now),
                    {:ok, _stored} <- Repository.store_token(access),
                    {:ok, _audit} <- Repository.append_audit_event(%{action: nil}) do
                 {:ok, :unexpected_success}
               else
                 {:error, reason} -> {:error, reason}
               end
             end)

    assert {:ok, current_code} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(current_code.redeemed_at)
    assert {:ok, nil} = Repository.fetch_lifecycle_token(access.token_hash)
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_token_count
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audit_count
  end

  test "failed token persistence rolls back an earlier grant transition" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-rollback-token-#{suffix}"
    {:ok, client} = create_client(client_id, :client_secret_basic, "secret-#{suffix}")

    {:ok, code} =
      create_authorization_code(client,
        raw_code: "rollback-code-#{suffix}",
        code_verifier: "rollback-verifier-#{suffix}"
      )

    assert {:error, _reason} =
             Repository.transact(fn ->
               with {:ok, _redeemed} <-
                      Repository.mark_authorization_code_redeemed(
                        code.token_hash,
                        DateTime.utc_now()
                      ),
                    {:ok, _stored} <- Repository.store_token(%Token{token_type: :access_token}) do
                 {:ok, :unexpected_success}
               else
                 {:error, reason} -> {:error, reason}
               end
             end)

    assert {:ok, current_code} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(current_code.redeemed_at)

    assert Lockspire.TestRepo.aggregate(
             from(token in TokenRecord, where: token.client_id == ^client_id),
             :count
           ) == 1
  end

  test "a rejected promotion audit restores every client credential and lifetime field" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-rollback-client-#{suffix}"
    old_secret_hash = "old-secret-hash-#{suffix}"
    old_verifier = "old-verifier-#{suffix}"
    old_rat_hash = "old-rat-hash-#{suffix}"
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    app_deadline = DateTime.add(now, 80, :second)
    secret_deadline = DateTime.add(now, 70, :second)
    management_deadline = DateTime.add(now, 60, :second)

    {:ok, client} =
      Repository.register_client(%Lockspire.Domain.Client{
        client_id: client_id,
        lifetime_version: 0,
        client_secret_hash: old_secret_hash,
        client_secret_jwt_verifier_encrypted: old_verifier,
        registration_access_token_hash: old_rat_hash,
        client_expires_at: nil,
        client_secret_expires_at: secret_deadline,
        registration_access_token_expires_at: nil,
        client_type: :confidential,
        name: "Before #{client_id}",
        redirect_uris: ["https://client.example/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic
      })

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client_id),
               set: [
                 client_expires_at: app_deadline,
                 registration_access_token_expires_at: management_deadline
               ]
             )

    before = client_row(client_id)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    assert {:error, _reason} =
             Repository.replace_client_registration(
               %{client | registration_access_token_hash: old_rat_hash},
               %{
                 client
                 | registration_access_token_hash: old_rat_hash,
                   name: "After #{client_id}"
               },
               "replacement-rat-#{suffix}",
               %{action: nil}
             )

    assert client_row(client_id) == before
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "secret replacement write failure leaves the complete stored client unchanged" do
    client_id = "lifetime-rotation-write-#{System.unique_integer([:positive])}"
    {:ok, _client} = create_client(client_id, :client_secret_basic, "old-rotation-secret")
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    old_verifier = "old-rotation-verifier"
    old_last_rotated_at = DateTime.add(now, -900, :second)
    historical = DateTime.add(now, 900, :second)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client_id),
               set: [
                 client_secret_jwt_verifier_encrypted: old_verifier,
                 last_secret_rotated_at: old_last_rotated_at,
                 client_expires_at: historical,
                 client_secret_expires_at: historical,
                 registration_access_token_expires_at: historical
               ]
             )

    before = client_row(client_id)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    with_client_rotation_write_failure(fn ->
      result =
        Clients.rotate_client_secret(client_id, %{
          actor: %{type: :operator, id: "rotation-write-test"}
        })

      assert {:error, reason} = result
      assert reason == :storage_error
      refute match?({:ok, %{client_secret: _plaintext}}, result)
    end)

    assert client_row(client_id) == before
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits

    remove_failure_triggers()

    assert {:ok, %{client: rotated, client_secret: _plaintext}} =
             Clients.rotate_client_secret(client_id, %{
               actor: %{type: :operator, id: "rotation-write-control"}
             })

    refute client_row(client_id).client_secret_hash == before.client_secret_hash
    assert rotated.client_secret_hash == client_row(client_id).client_secret_hash
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits + 1
  end

  test "required audit failure rolls back every secret replacement field and handoff" do
    client_id = "lifetime-rotation-audit-#{System.unique_integer([:positive])}"
    {:ok, _client} = create_client(client_id, :client_secret_basic, "old-audit-secret")
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    assert {1, _} =
             Lockspire.TestRepo.update_all(
               from(record in ClientRecord, where: record.client_id == ^client_id),
               set: [
                 client_secret_jwt_verifier_encrypted: "old-audit-verifier",
                 last_secret_rotated_at: DateTime.add(now, -600, :second),
                 client_secret_expires_at: DateTime.add(now, 400, :second)
               ]
             )

    before = client_row(client_id)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    with_audit_failure(fn ->
      result =
        Clients.rotate_client_secret(client_id, %{
          actor: %{type: :operator, id: "rotation-audit-test"}
        })

      assert {:error, reason} = result
      assert reason == :storage_error
      refute match?({:ok, %{client_secret: _plaintext}}, result)
    end)

    assert client_row(client_id) == before
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "authorization-code token insert failure preserves its grant, token rows, and audits" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-fail-code-#{suffix}"
    raw_secret = "secret-#{suffix}"
    raw_code = "code-#{suffix}"
    verifier = "verifier-#{suffix}"

    {:ok, client} =
      create_client(client_id, :client_secret_basic, raw_secret, ["authorization_code"], %{
        access_token_format: :opaque
      })

    {:ok, code} = create_authorization_code(client, raw_code: raw_code, code_verifier: verifier)
    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    with_access_token_failure(fn ->
      assert {:error, error} =
               exchange(
                 %{
                   "grant_type" => "authorization_code",
                   "code" => raw_code,
                   "code_verifier" => verifier,
                   "redirect_uri" => "https://client.example.com/callback"
                 },
                 authorization: basic_auth(client_id, raw_secret),
                 now: fn -> now end
               )

      assert error.error == "server_error"
    end)

    assert {:ok, current_code} = Repository.fetch_authorization_code(code.token_hash)
    assert is_nil(current_code.redeemed_at)
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "device and CIBA request transitions roll back when their audit writes fail" do
    now = DateTime.add(DateTime.utc_now(), 10, :second) |> DateTime.truncate(:second)

    for {grant_type, suffix} <- [
          {"urn:ietf:params:oauth:grant-type:device_code", "device"},
          {"urn:openid:params:grant-type:ciba", "ciba"}
        ] do
      client_id = "lifetime-fail-#{suffix}-#{System.unique_integer([:positive])}"

      {:ok, client} =
        Repository.register_client(%Client{
          lifetime_version: 1,
          client_id: client_id,
          name: client_id,
          client_type: :public,
          token_endpoint_auth_method: :none,
          allowed_grant_types: [grant_type],
          allowed_scopes: ["email"],
          access_token_format: :opaque,
          created_at: now
        })

      {raw_grant, request_hash, fetch_current} = seed_approved_poll(grant_type, client, now)
      before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
      before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

      with_audit_failure(fn ->
        assert {:error, error} = poll_exchange(client, grant_type, raw_grant, fn -> now end)
        assert error.error == "server_error"
      end)

      assert {:ok, current_request} = fetch_current.()
      assert current_request.status == :approved
      assert is_binary(request_hash)
      assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
      assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
    end
  end

  test "refresh rotation leaves the presented family unchanged when audit insertion fails" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    client_id = "lifetime-fail-refresh-#{suffix}"
    raw_secret = "secret-#{suffix}"
    raw_refresh = "refresh-#{suffix}"
    now = DateTime.utc_now() |> DateTime.add(5, :second) |> DateTime.truncate(:second)

    {:ok, _client} =
      create_client(client_id, :client_secret_basic, raw_secret, ["refresh_token"], %{
        allowed_scopes: ["email", "offline_access"],
        access_token_format: :opaque
      })

    {:ok, refresh} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw_refresh),
        token_type: :refresh_token,
        family_id: "family-#{suffix}",
        generation: 0,
        client_id: client_id,
        account_id: "subject-#{client_id}",
        scopes: ["email", "offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 600, :second)
      })

    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    with_audit_failure(fn ->
      assert {:error, error} =
               TokenExchange.exchange(%{
                 params: %{"grant_type" => "refresh_token", "refresh_token" => raw_refresh},
                 authorization: basic_auth(client_id, raw_secret),
                 opts: token_exchange_opts(now)
               })

      assert error.error == "server_error"
    end)

    assert {:ok, current_refresh} = Repository.fetch_refresh_token(refresh.token_hash)
    assert is_nil(current_refresh.redeemed_at)
    assert is_nil(current_refresh.revoked_at)
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  test "RFC 8693 output insertion failure preserves both durable input identities" do
    suffix = Base.url_encode64(:crypto.strong_rand_bytes(8), padding: false)
    now = DateTime.utc_now() |> DateTime.add(10, :second) |> DateTime.truncate(:second)
    requester = public_exchange_client("lifetime-fail-rfc-requester-#{suffix}")
    subject_issuer = public_exchange_client("lifetime-fail-rfc-subject-#{suffix}")
    actor_issuer = public_exchange_client("lifetime-fail-rfc-actor-#{suffix}")
    {subject, subject_raw} = seed_exchange_input(subject_issuer, "subject-#{suffix}", now)
    {actor, actor_raw} = seed_exchange_input(actor_issuer, "actor-#{suffix}", now)
    before_tokens = Lockspire.TestRepo.aggregate(TokenRecord, :count)
    before_audits = Lockspire.TestRepo.aggregate(AuditEventRecord, :count)

    with_access_token_failure(fn ->
      assert {:error, error} =
               TokenExchange.exchange(%{
                 params: %{
                   "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
                   "client_id" => requester.client_id,
                   "subject_token" => subject_raw,
                   "actor_token" => actor_raw,
                   "scope" => "read"
                 },
                 authorization: nil,
                 opts:
                   Keyword.put(
                     token_exchange_opts(now),
                     :token_exchange_validator,
                     AuditFailureValidator
                   )
               })

      assert error.error == "server_error"
    end)

    assert {:ok, current_subject} = Repository.fetch_lifecycle_token(subject.token_hash)
    assert {:ok, current_actor} = Repository.fetch_lifecycle_token(actor.token_hash)
    assert current_subject.client_id == subject_issuer.client_id
    assert current_actor.client_id == actor_issuer.client_id
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == before_tokens
    assert Lockspire.TestRepo.aggregate(AuditEventRecord, :count) == before_audits
  end

  defp seed_approved_poll("urn:ietf:params:oauth:grant-type:device_code", client, now) do
    request =
      DeviceAuthorization.issue(
        %{
          client_id: client.client_id,
          device_code: "device-#{client.client_id}",
          user_code: "BCDFG#{System.unique_integer([:positive])}",
          scopes: ["email"]
        },
        now: DateTime.add(now, -10, :second)
      )

    assert {:ok, _} = Repository.put_device_authorization(request)

    assert {:ok, _} =
             Repository.transition_device_authorization(
               request.verification_handle,
               [:pending],
               %{status: :approved, subject_id: "subject-#{client.client_id}", approved_at: now}
             )

    {request.device_code, request.device_code_hash,
     fn ->
       Repository.fetch_device_authorization_by_verification_handle(request.verification_handle)
     end}
  end

  defp seed_approved_poll("urn:openid:params:grant-type:ciba", client, now) do
    auth_req_id = "auth-req-#{client.client_id}"

    request =
      CibaAuthorization.issue(
        %{auth_req_id: auth_req_id, client_id: client.client_id, scopes: ["email"]},
        now: DateTime.add(now, -10, :second)
      )

    assert {:ok, _} = Repository.put_ciba_authorization(request)

    assert {:ok, _} =
             Repository.transition_ciba_authorization(
               request.auth_req_id_hash,
               [:pending],
               %{status: :approved, subject_id: "subject-#{client.client_id}", approved_at: now}
             )

    {auth_req_id, request.auth_req_id_hash,
     fn -> Repository.fetch_ciba_authorization_by_auth_req_id_hash(request.auth_req_id_hash) end}
  end

  defp poll_exchange(client, grant_type, raw_grant, now) do
    {param, grant} =
      if grant_type == "urn:openid:params:grant-type:ciba",
        do: {"auth_req_id", raw_grant},
        else: {"device_code", raw_grant}

    TokenExchange.exchange(%{
      params:
        Map.merge(%{"grant_type" => grant_type, "client_id" => client.client_id}, %{
          param => grant
        }),
      authorization: nil,
      opts: token_exchange_opts(now)
    })
  end

  defp token_exchange_opts(now) do
    [
      client_store: Repository,
      token_store: Repository,
      transaction_store: Repository,
      audit_store: Repository,
      device_authorization_store: Repository,
      ciba_authorization_store: Repository,
      interaction_store: Repository,
      key_store: Repository,
      server_policy_store: Repository,
      token_exchange_validator: AuditFailureValidator,
      now: fn -> now end,
      access_token_generator: fn -> "opaque-failed-access-#{Ecto.UUID.generate()}" end,
      refresh_token_generator: fn -> "opaque-failed-refresh-#{Ecto.UUID.generate()}" end
    ]
  end

  defp public_exchange_client(client_id) do
    {:ok, client} =
      Repository.register_client(%Client{
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
  end

  defp seed_exchange_input(issuer, raw, now) do
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

    assert {:ok, stored} = Repository.store_token(token)
    {stored, raw}
  end

  defp with_audit_failure(fun) do
    install_audit_failure_trigger()

    try do
      fun.()
    after
      remove_failure_triggers()
    end
  end

  defp with_access_token_failure(fun) do
    install_access_token_failure_trigger()

    try do
      fun.()
    after
      remove_failure_triggers()
    end
  end

  defp install_audit_failure_trigger do
    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan12_audit_failure ON lockspire_audit_events"
    )

    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_plan12_reject_audit() RETURNS trigger AS $$
    BEGIN
        RAISE EXCEPTION 'plan12 forced audit write failure for %', NEW.resource_id;
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lockspire_plan12_audit_failure
    BEFORE INSERT ON lockspire_audit_events
    FOR EACH ROW EXECUTE FUNCTION lockspire_plan12_reject_audit()
    """)
  end

  defp with_client_rotation_write_failure(fun) do
    install_client_rotation_write_failure_trigger()

    try do
      fun.()
    after
      remove_failure_triggers()
    end
  end

  defp install_client_rotation_write_failure_trigger do
    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_plan03_reject_client_rotation() RETURNS trigger AS $$
    BEGIN
        RAISE EXCEPTION 'plan03 forced client rotation write failure for %', NEW.client_id;
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lockspire_plan03_client_rotation_failure
    BEFORE UPDATE ON lockspire_clients
    FOR EACH ROW EXECUTE FUNCTION lockspire_plan03_reject_client_rotation()
    """)
  end

  defp install_access_token_failure_trigger do
    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan12_token_failure ON lockspire_tokens"
    )

    Lockspire.TestRepo.query!("""
    CREATE OR REPLACE FUNCTION lockspire_plan12_reject_access_token() RETURNS trigger AS $$
    BEGIN
        IF NEW.token_type = 'access_token' THEN
        RAISE EXCEPTION 'plan12 forced token write failure';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """)

    Lockspire.TestRepo.query!("""
    CREATE TRIGGER lockspire_plan12_token_failure
    BEFORE INSERT ON lockspire_tokens
    FOR EACH ROW EXECUTE FUNCTION lockspire_plan12_reject_access_token()
    """)
  end

  defp remove_failure_triggers do
    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan03_client_rotation_failure ON lockspire_clients"
    )

    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan12_audit_failure ON lockspire_audit_events"
    )

    Lockspire.TestRepo.query!(
      "DROP TRIGGER IF EXISTS lockspire_plan12_token_failure ON lockspire_tokens"
    )

    Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_plan12_reject_audit()")
    Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_plan12_reject_access_token()")
    Lockspire.TestRepo.query!("DROP FUNCTION IF EXISTS lockspire_plan03_reject_client_rotation()")
  end

  defp client_row(client_id) do
    Lockspire.TestRepo.one!(from(record in ClientRecord, where: record.client_id == ^client_id))
  end
end
