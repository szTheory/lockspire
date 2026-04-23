defmodule Lockspire.Storage.RepositoryTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository

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
    assert fetched_client.metadata == %{"tier" => "sandbox"}
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

  test "lists only publishable keys and strips private key material" do
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

    assert Enum.map(listed_keys, & &1.kid) == ["kid_active", "kid_retiring"]

    assert Enum.all?(listed_keys, fn key ->
             key.status in [:active, :retiring] and is_nil(key.private_jwk_encrypted)
           end)

    assert {:ok, listed_active_keys} = Repository.list_active_keys()
    assert Enum.map(listed_active_keys, & &1.kid) == ["kid_active", "kid_retiring"]
  end
end
