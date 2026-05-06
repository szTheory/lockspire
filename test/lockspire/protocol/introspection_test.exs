defmodule Lockspire.Protocol.IntrospectionTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.RefreshExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    secret = "introspection-secret"

    {:ok, confidential_client} =
      Repository.register_client(%Client{
        client_id: "client-introspection",
        client_secret_hash: client_secret_hash(secret),
        client_type: :confidential,
        name: "Introspection Client",
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
        client_id: "client-introspection-other",
        client_secret_hash: client_secret_hash("other-introspection-secret"),
        client_type: :confidential,
        name: "Other Introspection Client",
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

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public Introspection Client",
        redirect_uris: ["https://public.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()

    authorization_details = [
      %{
        "type" => "payment_initiation",
        "locations" => ["https://resource.example.com/payments"],
        "actions" => ["create"],
        "instructedAmount" => %{"currency" => "USD", "amount" => "12.34"}
      }
    ]

    {:ok, consent_grant} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "subject-introspection",
        client_id: confidential_client.client_id,
        scopes: ["email", "offline_access"],
        granted_at: now,
        status: :active,
        kind: :one_time,
        authorization_details: authorization_details,
        metadata: %{}
      })

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("introspect-access-token"),
        token_type: :access_token,
        client_id: confidential_client.client_id,
        account_id: "subject-introspection",
        interaction_id: "interaction-introspection-access",
        scopes: ["email"],
        audience: ["api.example.com"],
        consent_grant_id: consent_grant.id,
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _refresh_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("introspect-refresh-token"),
        token_type: :refresh_token,
        family_id: "family-introspection-refresh",
        generation: 0,
        client_id: confidential_client.client_id,
        account_id: "subject-introspection",
        interaction_id: "interaction-introspection-refresh",
        scopes: ["email", "offline_access"],
        audience: ["api.example.com"],
        consent_grant_id: consent_grant.id,
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, _token_without_grant} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("introspect-no-grant-token"),
        token_type: :access_token,
        client_id: confidential_client.client_id,
        account_id: "subject-introspection",
        interaction_id: "interaction-introspection-no-grant",
        scopes: ["email"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _expired_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("introspect-expired-token"),
        token_type: :access_token,
        client_id: confidential_client.client_id,
        account_id: "subject-introspection",
        interaction_id: "interaction-introspection-expired",
        scopes: ["email"],
        issued_at: DateTime.add(now, -7200, :second),
        expires_at: DateTime.add(now, -3600, :second)
      })

    {:ok, _revoked_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("introspect-revoked-token"),
        token_type: :access_token,
        client_id: confidential_client.client_id,
        account_id: "subject-introspection",
        interaction_id: "interaction-introspection-revoked",
        scopes: ["email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second),
        revoked_at: now
      })

    {:ok, _bound_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("introspect-bound-token"),
        token_type: :access_token,
        client_id: confidential_client.client_id,
        account_id: "subject-introspection-bound",
        interaction_id: "interaction-introspection-bound",
        scopes: ["email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second),
        cnf: %{"jkt" => "test-thumbprint"}
      })

    %{
      confidential_client: confidential_client,
      secret: secret,
      other_client: other_client,
      public_client: public_client,
      authorization_details: authorization_details,
      consent_grant_id: consent_grant.id
    }
  end

  test "returns active token details for authorized confidential callers", %{
    confidential_client: client,
    secret: secret,
    authorization_details: authorization_details
  } do
    assert {:ok, response} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-access-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert response.active == true
    assert response.client_id == client.client_id
    assert response.token_type == "access_token"
    assert response.scope == "email"
    assert response.sub == "subject-introspection"
    assert response.aud == ["api.example.com"]
    assert response.authorization_details == authorization_details
  end

  test "returns granted authorization_details for active refresh tokens", %{
    confidential_client: client,
    secret: secret,
    authorization_details: authorization_details
  } do
    assert {:ok, response} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-refresh-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert response.active == true
    assert response.token_type == "refresh_token"
    assert response.authorization_details == authorization_details
  end

  test "keeps tokens compact-by-reference and omits authorization_details when the grant is missing", %{
    confidential_client: client,
    secret: secret,
    consent_grant_id: consent_grant_id
  } do
    assert {:ok, %Token{} = token} =
             Repository.fetch_lifecycle_token(TokenFormatter.hash_token("introspect-access-token"))

    assert token.consent_grant_id == consent_grant_id
    refute Map.has_key?(Map.from_struct(token), :authorization_details)

    assert {:ok, response} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-no-grant-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert response.active == true
    refute Map.has_key?(response, :authorization_details)
  end

  test "returns cnf when token is DPoP-bound", %{
    confidential_client: client,
    secret: secret
  } do
    assert {:ok, response} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-bound-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })

    assert response.active == true
    assert response.cnf == %{"jkt" => "test-thumbprint"}
  end

  test "returns inactive false for unauthorized public callers", %{public_client: client} do
    assert {:ok, %{active: false}} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-access-token", "client_id" => client.client_id},
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  test "returns inactive false for client mismatch", %{other_client: client} do
    assert {:ok, %{active: false}} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-access-token"},
               authorization: basic_auth(client.client_id, "other-introspection-secret"),
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  test "returns inactive false for expired tokens", %{
    confidential_client: client,
    secret: secret
  } do
    assert {:ok, %{active: false}} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-expired-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  test "returns inactive false for revoked tokens", %{
    confidential_client: client,
    secret: secret
  } do
    assert {:ok, %{active: false}} =
             Introspection.introspect(%{
               params: %{"token" => "introspect-revoked-token"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  test "returns inactive false after refresh family reuse invalidation", %{
    confidential_client: client,
    secret: secret
  } do
    assert {:ok, _success} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "introspect-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "introspection-family-access" end,
                 refresh_token_generator: fn -> "introspection-family-refresh" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert {:error, _error} =
             RefreshExchange.exchange_refresh_token(client, %{
               params: %{"refresh_token" => "introspect-refresh-token"},
               opts: [
                 token_store: Repository,
                 access_token_generator: fn -> "introspection-family-access-2" end,
                 refresh_token_generator: fn -> "introspection-family-refresh-2" end,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert {:ok, %{active: false}} =
             Introspection.introspect(%{
               params: %{"token" => "introspection-family-refresh"},
               authorization: basic_auth(client.client_id, secret),
               opts: [client_store: Repository, token_store: Repository]
             })
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end
end
