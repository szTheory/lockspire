defmodule Lockspire.Storage.RepositoryTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @moduletag :integration

  alias Lockspire.Audit.Event
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Lockspire.Storage.Ecto.Repository

  require Logger

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  end

  test "registers and fetches a client through the repository contract" do
    client = %Client{
      client_id: "client_123",
      client_secret_hash: "argon2id$hash",
      client_secret_jwt_verifier_encrypted: "sealed-verifier-123",
      client_type: :confidential,
      name: "Acme Integrations",
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid", "profile"],
      allowed_grant_types: ["authorization_code", "refresh_token"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{"tier" => "sandbox"}
    }

    assert {:ok, %Client{} = stored_client} = Repository.register_client(client)
    assert stored_client.id

    assert {:ok, %Client{} = fetched_client} = Repository.fetch_client_by_id("client_123")
    assert fetched_client.client_id == stored_client.client_id
    assert fetched_client.redirect_uris == ["https://client.example.com/callback"]
    assert fetched_client.allowed_grant_types == ["authorization_code", "refresh_token"]
    assert fetched_client.pkce_required
    assert fetched_client.active
    assert fetched_client.metadata == %{"tier" => "sandbox"}
    assert fetched_client.client_secret_jwt_verifier_encrypted == "sealed-verifier-123"
  end

  test "lists, updates, rotates, and toggles client lifecycle state" do
    now = DateTime.utc_now()

    assert {:ok, %Client{} = first_client} =
             Repository.register_client(%Client{
               client_id: "alpha-client",
               client_secret_hash: "argon2id$hash",
               client_secret_jwt_verifier_encrypted: "sealed-alpha",
               client_type: :confidential,
               name: "Alpha Client",
               redirect_uris: ["https://alpha.example.com/callback"],
               allowed_scopes: ["email"],
               allowed_grant_types: ["authorization_code"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               created_at: now,
               metadata: %{"tier" => "sandbox"}
             })

    assert {:ok, _second_client} =
             Repository.register_client(%Client{
               client_id: "beta-client",
               client_type: :public,
               name: "Beta Client",
               redirect_uris: ["https://beta.example.com/callback"],
               allowed_scopes: ["profile"],
               allowed_grant_types: ["authorization_code"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :none,
               pkce_required: true,
               subject_type: :public,
               created_at: now,
               metadata: %{}
             })

    assert {:ok, clients} = Repository.list_clients(search: "Alpha", active: true)
    assert Enum.map(clients, & &1.client_id) == ["alpha-client"]

    assert {:ok, %Client{} = updated_client} =
             Repository.update_client(first_client, %{
               name: "Alpha Client Updated",
               redirect_uris: ["https://alpha.example.com/oidc/callback"],
               allowed_scopes: ["email", "profile"],
               metadata: %{"tier" => "production"}
             })

    assert updated_client.name == "Alpha Client Updated"
    assert updated_client.redirect_uris == ["https://alpha.example.com/oidc/callback"]
    assert updated_client.allowed_scopes == ["email", "profile"]
    assert updated_client.metadata == %{"tier" => "production"}

    assert {:ok, %Client{} = rotated_client} =
             Repository.rotate_client_secret(
               updated_client,
               "sha256:new-salt:new-hash",
               "sealed-new-verifier",
               now
             )

    assert rotated_client.client_secret_hash == "sha256:new-salt:new-hash"
    assert rotated_client.client_secret_jwt_verifier_encrypted == "sealed-new-verifier"
    assert rotated_client.last_secret_rotated_at == now

    assert {:ok, %Client{} = disabled_client} =
             Repository.set_client_active(rotated_client, false, %{
               disabled_at: now,
               disabled_by: "ops@example.com"
             })

    refute disabled_client.active
    assert disabled_client.disabled_at == now
    assert disabled_client.disabled_by == "ops@example.com"

    assert {:ok, [%Client{client_id: "beta-client"}]} = Repository.list_clients(active: true)
    assert {:ok, [%Client{client_id: "alpha-client"}]} = Repository.list_clients(active: false)

    assert {:ok, %Client{} = enabled_client} =
             Repository.set_client_active(disabled_client, true, %{
               disabled_at: nil,
               disabled_by: nil
             })

    assert enabled_client.active
    assert is_nil(enabled_client.disabled_at)
    assert is_nil(enabled_client.disabled_by)
  end

  test "rolls back the durable mutation and appended audit row when the wrapped write fails" do
    client = %Client{
      client_id: "rolled-back-client",
      client_secret_hash: "argon2id$hash",
      client_type: :confidential,
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }

    audit_event = %{
      action: :client_created,
      outcome: :failed,
      reason_code: :forced_failure,
      actor: %{type: :operator, id: "ops_456", display: "Ops User"},
      resource: %{type: :client, id: client.client_id}
    }

    assert {:error, :forced_failure} =
             Repository.transact_with_audit(audit_event, fn ->
               assert {:ok, %ClientRecord{}} =
                        %ClientRecord{}
                        |> ClientRecord.changeset(client)
                        |> Lockspire.TestRepo.insert()

               {:error, :forced_failure}
             end)

    assert [] = Lockspire.TestRepo.all(AuditEventRecord)
    assert [] = Lockspire.TestRepo.all(ClientRecord)
  end

  test "rolls back the durable mutation when the appended audit row is invalid" do
    client = %Client{
      client_id: "invalid-audit-client",
      client_secret_hash: "argon2id$hash",
      client_type: :confidential,
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }

    invalid_audit_event =
      struct!(Event,
        action: "client_created",
        outcome: "succeeded",
        resource_type: "client",
        resource_id: nil,
        metadata: %{}
      )

    assert {:error, changeset} =
             Repository.transact_with_audit(invalid_audit_event, fn ->
               %ClientRecord{}
               |> ClientRecord.changeset(client)
               |> Lockspire.TestRepo.insert()
             end)

    assert %{resource_id: ["can't be blank"]} = errors_on(changeset)
    assert [] = Lockspire.TestRepo.all(AuditEventRecord)
    assert [] = Lockspire.TestRepo.all(ClientRecord)
  end

  test "suppresses SQL bind logging for sensitive token lookup and audit insert paths" do
    previous_level = Logger.level()
    Logger.configure(level: :debug)

    on_exit(fn -> Logger.configure(level: previous_level) end)

    now = DateTime.utc_now()

    assert {:ok, _client} =
             Repository.register_client(%Client{
               client_id: "sensitive-client",
               client_secret_hash: "argon2id$top-secret-hash",
               client_type: :confidential,
               name: "Sensitive Client",
               redirect_uris: ["https://client.example.com/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               created_at: now
             })

    assert {:ok, _token} =
             Repository.store_token(%Token{
               token_hash: "sensitive-token-hash",
               token_type: :authorization_code,
               client_id: "sensitive-client",
               interaction_id: "interaction-sensitive",
               redirect_uri: "https://client.example.com/callback",
               code_challenge: "challenge",
               code_challenge_method: :S256,
               expires_at: DateTime.add(now, 300, :second)
             })

    sensitive_log =
      capture_log(fn ->
        assert {:ok, %Token{}} = Repository.fetch_authorization_code("sensitive-token-hash")

        assert {:ok, %Event{}} =
                 Repository.append_audit_event(%{
                   action: :token_introspected,
                   outcome: :succeeded,
                   actor: %{type: :client, id: "sensitive-client"},
                   resource: %{type: :authorization_code, id: "interaction-sensitive"},
                   metadata: %{token_hash: "sensitive-token-hash"}
                 })
      end)

    refute sensitive_log =~ "sensitive-token-hash"
    refute sensitive_log =~ "argon2id$top-secret-hash"
    refute sensitive_log =~ "INSERT INTO \"lockspire_audit_events\""
    refute sensitive_log =~ "FROM \"lockspire_tokens\""
  end

  test "keeps ordinary repository debugging available for non-sensitive client paths" do
    previous_level = Logger.level()
    Logger.configure(level: :debug)

    on_exit(fn -> Logger.configure(level: previous_level) end)

    now = DateTime.utc_now()

    assert {:ok, _client} =
             Repository.register_client(%Client{
               client_id: "debug-client",
               client_secret_hash: "argon2id$hash",
               client_type: :confidential,
               name: "Debug Client",
               redirect_uris: ["https://debug.example.com/callback"],
               allowed_scopes: ["openid"],
               allowed_grant_types: ["authorization_code"],
               allowed_response_types: ["code"],
               token_endpoint_auth_method: :client_secret_basic,
               pkce_required: true,
               subject_type: :public,
               created_at: now
             })

    debug_log =
      capture_log(fn ->
        assert {:ok, %Client{client_id: "debug-client"}} =
                 Repository.fetch_client_by_id("debug-client")
      end)

    assert debug_log =~ "SELECT"
    assert debug_log =~ "lockspire_clients"
    assert debug_log =~ "debug-client"
  end

  test "stores and fetches an active interaction through the repository contract" do
    interaction = %Interaction{
      interaction_id: "interaction_123",
      client_id: "client_123",
      account_id: "account_456",
      scopes_requested: ["openid", "email"],
      prompt: ["login", "consent"],
      nonce: "nonce-123",
      redirect_uri: "https://client.example.com/callback",
      return_to: "/lockspire/authorize/continue",
      state: "state-123",
      code_challenge: "challenge-123",
      code_challenge_method: :S256,
      expires_at: DateTime.add(DateTime.utc_now(), 300, :second)
    }

    assert {:ok, %Interaction{} = stored_interaction} = Repository.put_interaction(interaction)

    assert {:ok, %Interaction{} = fetched_interaction} =
             Repository.fetch_active_interaction("interaction_123")

    assert fetched_interaction.interaction_id == stored_interaction.interaction_id
    assert fetched_interaction.scopes_requested == ["openid", "email"]
    assert fetched_interaction.prompt == ["login", "consent"]
    assert fetched_interaction.return_to == "/lockspire/authorize/continue"
  end

  test "persists interaction lifecycle transitions and only fetches active interactions" do
    now = DateTime.utc_now()

    interaction = %Interaction{
      interaction_id: "interaction_lifecycle",
      client_id: "client_123",
      scopes_requested: ["email"],
      redirect_uri: "https://client.example.com/callback",
      return_to: "/lockspire/authorize/continue",
      state: "state-123",
      code_challenge: "challenge-123",
      code_challenge_method: :S256,
      status: :pending_login,
      login_required_at: now,
      expires_at: DateTime.add(now, 300, :second)
    }

    assert {:ok, %Interaction{} = stored_interaction} = Repository.put_interaction(interaction)
    assert stored_interaction.status == :pending_login
    assert stored_interaction.login_required_at

    assert {:ok, %Interaction{} = pending_login} =
             Repository.fetch_active_interaction("interaction_lifecycle")

    assert pending_login.status == :pending_login

    assert {:ok, %Interaction{} = pending_consent} =
             Repository.transition_interaction("interaction_lifecycle", [:pending_login], %{
               status: :pending_consent,
               account_id: "subject_123",
               consent_requested_at: now
             })

    assert pending_consent.status == :pending_consent
    assert pending_consent.account_id == "subject_123"
    assert pending_consent.consent_requested_at

    assert {:ok, %Interaction{} = completed} =
             Repository.transition_interaction("interaction_lifecycle", [:pending_consent], %{
               status: :completed,
               completed_at: now
             })

    assert completed.status == :completed
    assert completed.completed_at

    assert {:ok, nil} = Repository.fetch_active_interaction("interaction_lifecycle")

    expired_interaction = %Interaction{
      interaction_id: "interaction_expired",
      client_id: "client_123",
      scopes_requested: ["email"],
      redirect_uri: "https://client.example.com/callback",
      return_to: "/lockspire/authorize/continue",
      status: :pending_login,
      expires_at: DateTime.add(now, -5, :second)
    }

    assert {:ok, _expired} = Repository.put_interaction(expired_interaction)
    assert {:ok, nil} = Repository.fetch_active_interaction("interaction_expired")
  end

  test "grants and lists consents through the repository contract" do
    grant = %ConsentGrant{
      account_id: "account_456",
      client_id: "client_123",
      scopes: ["openid", "email"],
      granted_at: DateTime.utc_now(),
      metadata: %{"source" => "consent-ui"}
    }

    assert {:ok, %ConsentGrant{} = stored_grant} = Repository.grant_consent(grant)

    assert {:ok, [%ConsentGrant{} = listed_grant]} =
             Repository.list_consents_for_account("account_456")

    assert listed_grant.id == stored_grant.id
    assert listed_grant.scopes == ["openid", "email"]
    assert listed_grant.metadata == %{"source" => "consent-ui"}
  end

  test "lists and fetches consents through filterable durable queries" do
    now = DateTime.utc_now()

    assert {:ok, %ConsentGrant{} = active_grant} =
             Repository.grant_consent(%ConsentGrant{
               account_id: "account_active",
               client_id: "client_alpha",
               scopes: ["openid"],
               granted_at: now,
               status: :active
             })

    assert {:ok, %ConsentGrant{} = _revoked_grant} =
             Repository.grant_consent(%ConsentGrant{
               account_id: "account_active",
               client_id: "client_beta",
               scopes: ["email"],
               granted_at: now,
               status: :revoked,
               revoked_at: now,
               revoked_by: "ops@example.com",
               revoked_reason: "support_request"
             })

    assert {:ok, [%ConsentGrant{client_id: "client_alpha"}]} =
             Repository.list_consents(account_id: "account_active", client_id: "client_alpha")

    assert {:ok, [%ConsentGrant{client_id: "client_beta", status: :revoked}]} =
             Repository.list_consents(status: :revoked, limit: 1)

    assert {:ok, %ConsentGrant{} = fetched_grant} =
             Repository.fetch_consent_grant(active_grant.id)

    assert fetched_grant.id == active_grant.id
  end

  test "persists reusable remembered consents and excludes revoked grants" do
    now = DateTime.utc_now()

    remembered_grant = %ConsentGrant{
      account_id: "subject_123",
      client_id: "client_123",
      scopes: ["email", "profile"],
      granted_at: now,
      status: :active,
      kind: :remembered,
      metadata: %{"source" => "consent-ui"}
    }

    one_time_grant = %ConsentGrant{
      account_id: "subject_123",
      client_id: "client_123",
      scopes: ["email"],
      granted_at: now,
      status: :active,
      kind: :one_time
    }

    revoked_grant = %ConsentGrant{
      account_id: "subject_123",
      client_id: "client_123",
      scopes: ["email"],
      granted_at: now,
      status: :revoked,
      kind: :remembered,
      revoked_at: now,
      revoked_reason: "operator_revoked"
    }

    assert {:ok, %ConsentGrant{} = stored_remembered} = Repository.grant_consent(remembered_grant)
    assert {:ok, _one_time} = Repository.grant_consent(one_time_grant)
    assert {:ok, _revoked} = Repository.grant_consent(revoked_grant)

    assert {:ok, [%ConsentGrant{} = reusable]} =
             Repository.list_reusable_consents("subject_123", "client_123")

    assert reusable.id == stored_remembered.id
    assert reusable.kind == :remembered
    assert reusable.status == :active

    assert {:ok, %ConsentGrant{} = revoked} =
             Repository.revoke_consent_grant(stored_remembered.id, %{
               revoked_at: DateTime.add(now, 60, :second),
               revoked_reason: "subject_revoked"
             })

    assert revoked.status == :revoked
    assert revoked.revoked_reason == "subject_revoked"
    assert {:ok, []} = Repository.list_reusable_consents("subject_123", "client_123")
  end

  test "revoke_consent_grant/2 stays idempotent for repeated revocations" do
    now = DateTime.utc_now()

    assert {:ok, %ConsentGrant{} = grant} =
             Repository.grant_consent(%ConsentGrant{
               account_id: "subject_123",
               client_id: "client_123",
               scopes: ["openid"],
               granted_at: now,
               status: :active
             })

    assert {:ok, %ConsentGrant{} = revoked} =
             Repository.revoke_consent_grant(grant.id, %{
               revoked_at: now,
               revoked_by: "ops@example.com",
               revoked_reason: "support_request"
             })

    later = DateTime.add(now, 60, :second)

    assert {:ok, %ConsentGrant{} = repeated} =
             Repository.revoke_consent_grant(grant.id, %{
               revoked_at: later,
               revoked_by: "other@example.com",
               revoked_reason: "ignored"
             })

    assert repeated.revoked_at == revoked.revoked_at
    assert repeated.revoked_by == revoked.revoked_by
    assert repeated.revoked_reason == revoked.revoked_reason
  end

  test "stores token families and revokes them through the repository contract" do
    refresh_token = %Token{
      token_hash: "token_hash_123",
      token_type: :refresh_token,
      family_id: "family_123",
      generation: 1,
      client_id: "client_123",
      account_id: "account_456",
      scopes: ["offline_access"],
      audience: ["api.example.com"],
      expires_at: DateTime.add(DateTime.utc_now(), 86_400, :second)
    }

    assert {:ok, %Token{} = stored_token} = Repository.store_token(refresh_token)
    assert stored_token.family_id == "family_123"

    assert {:ok, 1} = Repository.revoke_token_family("family_123")
  end

  test "rotates a refresh token into child refresh and access tokens transactionally" do
    now = DateTime.utc_now()

    assert {:ok, %Token{} = parent_refresh_token} =
             Repository.store_token(%Token{
               token_hash: "refresh_parent_hash",
               token_type: :refresh_token,
               family_id: "family_rotate_123",
               generation: 0,
               client_id: "client_123",
               account_id: "account_456",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               issued_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:ok,
            %{
              presented_refresh_token: %Token{} = rotated_parent,
              refresh_token: %Token{} = child_refresh_token,
              access_token: %Token{} = child_access_token
            }} =
             Repository.rotate_refresh_token(
               "refresh_parent_hash",
               "client_123",
               now,
               %Token{
                 token_hash: "refresh_child_hash",
                 token_type: :refresh_token,
                 client_id: "client_123",
                 account_id: "account_456",
                 scopes: ["email", "offline_access"],
                 audience: ["api.example.com"],
                 expires_at: DateTime.add(now, 86_400, :second)
               },
               %Token{
                 token_hash: "access_child_hash",
                 token_type: :access_token,
                 client_id: "client_123",
                 account_id: "account_456",
                 scopes: ["email", "offline_access"],
                 audience: ["api.example.com"],
                 expires_at: DateTime.add(now, 3600, :second)
               }
             )

    assert rotated_parent.id == parent_refresh_token.id
    assert rotated_parent.redeemed_at == now
    assert rotated_parent.revoked_at == now
    assert child_refresh_token.family_id == "family_rotate_123"
    assert child_refresh_token.generation == 1
    assert child_refresh_token.parent_token_id == parent_refresh_token.id
    assert child_access_token.family_id == "family_rotate_123"
    assert child_access_token.generation == 1
    assert child_access_token.parent_token_id == child_refresh_token.id
  end

  test "marks refresh-token reuse and revokes the full family including access tokens" do
    now = DateTime.utc_now()

    assert {:ok, %Token{} = replayed_refresh_token} =
             Repository.store_token(%Token{
               token_hash: "refresh_replayed_hash",
               token_type: :refresh_token,
               family_id: "family_reuse_123",
               generation: 0,
               client_id: "client_123",
               account_id: "account_456",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               issued_at: DateTime.add(now, -60, :second),
               redeemed_at: DateTime.add(now, -30, :second),
               revoked_at: DateTime.add(now, -30, :second),
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: "refresh_active_hash",
               token_type: :refresh_token,
               family_id: "family_reuse_123",
               generation: 1,
               parent_token_id: replayed_refresh_token.id,
               client_id: "client_123",
               account_id: "account_456",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               issued_at: DateTime.add(now, -30, :second),
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: "access_active_hash",
               token_type: :access_token,
               family_id: "family_reuse_123",
               generation: 1,
               client_id: "client_123",
               account_id: "account_456",
               scopes: ["email", "offline_access"],
               audience: ["api.example.com"],
               issued_at: DateTime.add(now, -30, :second),
               expires_at: DateTime.add(now, 3600, :second)
             })

    assert {:error, :reuse_detected} =
             Repository.rotate_refresh_token(
               "refresh_replayed_hash",
               "client_123",
               now,
               %Token{
                 token_hash: "refresh_unused_hash",
                 token_type: :refresh_token,
                 client_id: "client_123",
                 account_id: "account_456",
                 scopes: ["email", "offline_access"],
                 audience: ["api.example.com"],
                 expires_at: DateTime.add(now, 86_400, :second)
               },
               %Token{
                 token_hash: "access_unused_hash",
                 token_type: :access_token,
                 client_id: "client_123",
                 account_id: "account_456",
                 scopes: ["email", "offline_access"],
                 audience: ["api.example.com"],
                 expires_at: DateTime.add(now, 3600, :second)
               }
             )

    assert {:ok, %Token{} = persisted_replayed_refresh_token} =
             Repository.fetch_refresh_token("refresh_replayed_hash")

    assert persisted_replayed_refresh_token.reuse_detected_at == now

    assert {:ok, %Token{} = persisted_active_refresh_token} =
             Repository.fetch_refresh_token("refresh_active_hash")

    assert persisted_active_refresh_token.revoked_at == now

    assert {:ok, nil} = Repository.fetch_active_access_token("access_active_hash")
  end

  test "persists authorization codes with pkce fields and marks them single-use on redemption" do
    now = DateTime.utc_now()

    authorization_code = %Token{
      token_hash: "code_hash_123",
      token_type: :authorization_code,
      client_id: "client_123",
      account_id: "subject_123",
      interaction_id: "interaction_123",
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      code_challenge: "challenge-123",
      code_challenge_method: :S256,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second)
    }

    assert {:ok, %Token{} = stored_code} = Repository.store_token(authorization_code)
    assert stored_code.token_type == :authorization_code
    assert stored_code.redirect_uri == "https://client.example.com/callback"
    assert stored_code.interaction_id == "interaction_123"
    assert stored_code.code_challenge_method == :S256
    assert stored_code.redeemed_at == nil

    assert {:ok, %Token{} = active_code} =
             Repository.fetch_active_authorization_code("code_hash_123")

    assert active_code.id == stored_code.id

    assert {:ok, %Token{} = redeemed_code} =
             Repository.mark_authorization_code_redeemed("code_hash_123", now)

    assert redeemed_code.redeemed_at

    assert {:ok, nil} = Repository.fetch_active_authorization_code("code_hash_123")
  end

  test "lists publishable keys, keeps active listing strict, and strips private key material" do
    now = DateTime.utc_now()

    active_key = %SigningKey{
      kid: "kid_active",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => "kid_active", "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: <<1, 2, 3>>,
      status: :active,
      published_at: now,
      activated_at: now
    }

    retiring_key = %SigningKey{
      kid: "kid_retiring",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => "kid_retiring", "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: <<4, 5, 6>>,
      status: :retiring,
      published_at: now,
      activated_at: now,
      retiring_at: now
    }

    upcoming_key = %SigningKey{
      kid: "kid_upcoming",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => "kid_upcoming", "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: <<7, 8, 9>>,
      status: :upcoming,
      published_at: now
    }

    retired_key = %SigningKey{
      kid: "kid_retired",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => "kid_retired", "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: <<10, 11, 12>>,
      status: :retired,
      published_at: now,
      activated_at: now,
      retired_at: now
    }

    assert {:ok, _stored_active} = Repository.publish_key(active_key)
    assert {:ok, _stored_retiring} = Repository.publish_key(retiring_key)
    assert {:ok, _stored_upcoming} = Repository.publish_key(upcoming_key)
    assert {:ok, _stored_retired} = Repository.publish_key(retired_key)

    assert {:ok, listed_keys} = Repository.list_publishable_keys()

    assert Enum.map(listed_keys, & &1.kid) == ["kid_active", "kid_retiring", "kid_upcoming"]

    assert Enum.all?(listed_keys, fn key ->
             key.status in [:active, :retiring, :upcoming] and is_nil(key.private_jwk_encrypted)
           end)

    assert {:ok, listed_active_keys} = Repository.list_active_keys()
    assert Enum.map(listed_active_keys, & &1.kid) == ["kid_active", "kid_retiring"]
  end

  test "runs guided signing key transitions transactionally" do
    now = DateTime.utc_now()

    assert {:ok, active_key} =
             Repository.publish_key(%SigningKey{
               kid: "guided-active",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: %{"kty" => "RSA", "kid" => "guided-active", "alg" => "RS256"},
               private_jwk_encrypted: <<1, 2, 3>>,
               status: :active,
               published_at: now,
               activated_at: now
             })

    assert {:ok, upcoming_key} =
             Repository.publish_key(%SigningKey{
               kid: "guided-upcoming",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: %{"kty" => "RSA", "kid" => "guided-upcoming", "alg" => "RS256"},
               private_jwk_encrypted: <<4, 5, 6>>,
               status: :upcoming
             })

    assert {:error, :not_published} = Repository.activate_signing_key(upcoming_key.id, now)

    assert {:ok, %SigningKey{} = published_key} =
             Repository.publish_signing_key(upcoming_key.id, DateTime.add(now, 10, :second))

    assert published_key.published_at
    assert {:error, :already_published} = Repository.publish_signing_key(upcoming_key.id, now)

    assert {:ok, %{activated_key: activated_key, retiring_key: retiring_key}} =
             Repository.activate_signing_key(upcoming_key.id, DateTime.add(now, 20, :second))

    assert activated_key.status == :active
    assert retiring_key.status == :retiring

    assert {:ok, %SigningKey{} = refreshed_active_key} =
             Repository.fetch_signing_key_by_id(active_key.id)

    assert refreshed_active_key.status == :retiring

    assert {:ok, %SigningKey{} = retired_key} =
             Repository.retire_signing_key(active_key.id, DateTime.add(now, 30, :second))

    assert retired_key.status == :retired
    assert {:error, :already_retired} = Repository.retire_signing_key(active_key.id, now)
  end

  test "list_decryption_keys and fetch_active_signing_key isolate by use type" do
    now = DateTime.utc_now()

    assert {:ok, _} =
             Repository.publish_key(%SigningKey{
               kid: "sig_active_iso",
               use: :sig,
               status: :active,
               published_at: now,
               activated_at: now,
               public_jwk: %{
                 "kty" => "RSA",
                 "kid" => "sig_active_iso",
                 "alg" => "RS256",
                 "use" => "sig"
               },
               private_jwk_encrypted: <<1>>,
               kty: :RSA,
               alg: "RS256"
             })

    assert {:ok, _} =
             Repository.publish_key(%SigningKey{
               kid: "enc_active_iso",
               use: :enc,
               status: :active,
               published_at: now,
               activated_at: now,
               public_jwk: %{
                 "kty" => "RSA",
                 "kid" => "enc_active_iso",
                 "alg" => "RS256",
                 "use" => "enc"
               },
               private_jwk_encrypted: <<2>>,
               kty: :RSA,
               alg: "RS256"
             })

    assert {:ok, dec_keys} = Repository.list_decryption_keys()
    assert Enum.map(dec_keys, & &1.kid) == ["enc_active_iso"]

    assert {:ok, sig_key} = Repository.fetch_active_signing_key()
    assert sig_key.kid == "sig_active_iso"
  end

  test "validate_fapi_signing_readiness/0 fails when there are no keys" do
    assert {:error, :missing_compliant_publishable_key} =
             Repository.validate_fapi_signing_readiness()
  end

  test "validate_fapi_signing_readiness/0 fails when only publishable ES256 key exists but no active" do
    now = DateTime.utc_now()

    Repository.publish_key(%SigningKey{
      kid: "pub-only",
      use: :sig,
      status: :upcoming,
      published_at: now,
      public_jwk: %{
        "kty" => "EC",
        "crv" => "P-256",
        "kid" => "pub-only",
        "alg" => "ES256",
        "use" => "sig"
      },
      private_jwk_encrypted: <<1>>,
      kty: :EC,
      alg: "ES256"
    })

    assert {:error, :missing_compliant_active_key} = Repository.validate_fapi_signing_readiness()
  end

  test "validate_fapi_signing_readiness/0 fails when active key is RS256 (not FAPI compliant)" do
    now = DateTime.utc_now()

    Repository.publish_key(%SigningKey{
      kid: "active-rs256",
      use: :sig,
      status: :active,
      published_at: now,
      activated_at: now,
      public_jwk: %{"kty" => "RSA", "kid" => "active-rs256", "alg" => "RS256", "use" => "sig"},
      private_jwk_encrypted: <<1>>,
      kty: :RSA,
      alg: "RS256"
    })

    assert {:error, :missing_compliant_publishable_key} =
             Repository.validate_fapi_signing_readiness()
  end

  test "validate_fapi_signing_readiness/0 succeeds when there is an active compliant key" do
    now = DateTime.utc_now()

    Repository.publish_key(%SigningKey{
      kid: "active-es256",
      use: :sig,
      status: :active,
      published_at: now,
      activated_at: now,
      public_jwk: %{
        "kty" => "EC",
        "crv" => "P-256",
        "kid" => "active-es256",
        "alg" => "ES256",
        "use" => "sig"
      },
      private_jwk_encrypted: <<1>>,
      kty: :EC,
      alg: "ES256"
    })

    assert :ok = Repository.validate_fapi_signing_readiness()
  end

  test "prune_expired_records/3 chunks deletions recursively" do
    now = DateTime.utc_now()
    past = DateTime.add(now, -100, :second)
    future = DateTime.add(now, 100, :second)

    expired_records =
      for i <- 1..1500 do
        %{
          token_hash: "exp_#{i}",
          token_type: :access_token,
          client_id: "c1",
          expires_at: past,
          inserted_at: now,
          updated_at: now
        }
      end

    future_records =
      for i <- 1..50 do
        %{
          token_hash: "fut_#{i}",
          token_type: :access_token,
          client_id: "c1",
          expires_at: future,
          inserted_at: now,
          updated_at: now
        }
      end

    Lockspire.TestRepo.insert_all(Lockspire.Storage.Ecto.TokenRecord, expired_records)
    Lockspire.TestRepo.insert_all(Lockspire.Storage.Ecto.TokenRecord, future_records)

    total_deleted = Repository.prune_expired_records(Lockspire.Storage.Ecto.TokenRecord, now)

    assert total_deleted == 1500

    remaining = Lockspire.TestRepo.aggregate(Lockspire.Storage.Ecto.TokenRecord, :count)
    assert remaining == 50
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
