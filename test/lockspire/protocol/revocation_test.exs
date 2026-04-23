defmodule Lockspire.Protocol.RevocationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    confidential_secret = "revocation-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-revocation",
        client_secret_hash: client_secret_hash(confidential_secret),
        client_type: :confidential,
        name: "Revocation Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, other_client} =
      Repository.register_client(%Client{
        client_id: "client-revocation-other",
        client_secret_hash: client_secret_hash("other-secret"),
        client_type: :confidential,
        name: "Other Client",
        redirect_uris: ["https://other.example.com/callback"],
        allowed_scopes: ["email", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()

    {:ok, access_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("revoke-access-token"),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-revoke",
        interaction_id: "interaction-revoke-access",
        scopes: ["email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("revoke-refresh-token"),
        token_type: :refresh_token,
        family_id: "family-revoke",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-revoke",
        interaction_id: "interaction-revoke-refresh",
        scopes: ["email", "offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    %{
      client: client,
      client_secret: confidential_secret,
      other_client: other_client,
      access_token: access_token,
      refresh_token: refresh_token
    }
  end

  test "revokes access tokens for the authenticated client", %{
    client: client,
    client_secret: secret
  } do
    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "revoke-access-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert {:ok, %Token{revoked_at: %DateTime{}}} =
             Repository.fetch_lifecycle_token(TokenFormatter.hash_token("revoke-access-token"))
  end

  test "revokes refresh tokens for the authenticated client", %{
    client: client,
    client_secret: secret
  } do
    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "revoke-refresh-token", "token_type_hint" => "bogus_hint"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert {:ok, %Token{revoked_at: %DateTime{}}} =
             Repository.fetch_lifecycle_token(TokenFormatter.hash_token("revoke-refresh-token"))
  end

  test "returns success for unknown lifecycle tokens", %{client: client, client_secret: secret} do
    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "unknown-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  test "returns success and leaves mismatched tokens active", %{
    other_client: other_client,
    access_token: access_token
  } do
    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "revoke-access-token"},
               authorization: basic_auth(other_client.client_id, "other-secret"),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert {:ok, %Token{id: id, revoked_at: nil}} =
             Repository.fetch_lifecycle_token(TokenFormatter.hash_token("revoke-access-token"))

    assert id == access_token.id
  end

  test "returns success for already revoked tokens", %{client: client, client_secret: secret} do
    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "revoke-access-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "revoke-access-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  test "matched revocations append durable audit rows and unknown tokens do not append orphan rows",
       %{
         client: client,
         client_secret: secret
       } do
    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "revoke-refresh-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "unknown-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    audits = Lockspire.TestRepo.all(AuditEventRecord)

    assert Enum.any?(audits, fn audit ->
             audit.action == "token_revoked" and
               audit.actor_type == "client" and
               audit.actor_id == client.client_id and
               audit.reason_code == "token_revoked" and
               audit.resource_type == "refresh_token"
           end)

    assert Enum.count(audits, &(&1.action == "token_revoked")) == 1
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end
end
