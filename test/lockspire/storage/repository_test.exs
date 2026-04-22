defmodule Lockspire.Storage.RepositoryTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository

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

  test "publishes keys and lists active keys through the repository contract" do
    key = %SigningKey{
      kid: "kid_123",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "kid" => "kid_123"},
      private_jwk_encrypted: <<1, 2, 3>>,
      status: :active,
      published_at: DateTime.utc_now(),
      activated_at: DateTime.utc_now()
    }

    assert {:ok, %SigningKey{} = stored_key} = Repository.publish_key(key)

    assert {:ok, [%SigningKey{} = listed_key]} = Repository.list_active_keys()

    assert listed_key.kid == stored_key.kid
    assert listed_key.alg == "RS256"
    assert listed_key.status == :active
  end
end
