alias Lockspire.Domain.Client
alias Lockspire.Domain.ServerPolicy
alias Lockspire.Domain.SigningKey
alias Lockspire.Storage.Ecto.Repository

repo = AdoptionDemo.Repo

Ecto.Adapters.SQL.query!(
  repo,
  """
  TRUNCATE
    oban_jobs,
    lockspire_audit_events,
    lockspire_ciba_authorizations,
    lockspire_consent_grants,
    lockspire_device_authorizations,
    lockspire_dpop_replay,
    lockspire_initial_access_tokens,
    lockspire_interactions,
    lockspire_logout_deliveries,
    lockspire_logout_events,
    lockspire_pushed_authorization_requests,
    lockspire_server_policies,
    lockspire_signing_keys,
    lockspire_tokens,
    lockspire_used_jtis,
    lockspire_clients
  RESTART IDENTITY CASCADE
  """,
  []
)

now = DateTime.utc_now()

{:ok, _policy} =
  Repository.put_server_policy(%ServerPolicy{
    par_policy: :optional,
    dpop_policy: :bearer,
    security_profile: :none,
    registration_policy: :disabled,
    dcr_allowed_scopes: ["openid", "email", "profile", "read:billing"],
    dcr_allowed_grant_types: ["authorization_code", "refresh_token"],
    dcr_allowed_response_types: ["code"],
    dcr_allowed_redirect_uri_schemes: ["http", "https"],
    dcr_allowed_redirect_uri_hosts: ["127.0.0.1", "localhost", "client.example.com"],
    dcr_allowed_token_endpoint_auth_methods: ["none", "client_secret_basic"]
  })

key = JOSE.JWK.generate_key({:rsa, 2048})
{_fields, jwk} = JOSE.JWK.to_map(key)

{:ok, _key} =
  Repository.publish_key(%SigningKey{
    kid: "adoption-demo-rs256",
    kty: :RSA,
    alg: "RS256",
    use: "sig",
    public_jwk:
      jwk
      |> Map.take(["kty", "n", "e"])
      |> Map.put("kid", "adoption-demo-rs256")
      |> Map.put("alg", "RS256")
      |> Map.put("use", "sig"),
    private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", "adoption-demo-rs256")),
    status: :active,
    published_at: now,
    activated_at: now,
    metadata: %{"demo" => true}
  })

clients = [
  %Client{
    client_id: "acme-ledger-public",
    client_secret_hash: nil,
    client_type: :public,
    name: "Acme Ledger Demo SPA",
    redirect_uris: ["http://127.0.0.1:4100/oauth/callback"],
    allowed_scopes: ["openid", "email", "profile", "read:billing"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    token_endpoint_auth_method: :none,
    pkce_required: true,
    subject_type: :public,
    created_by: "seed",
    created_at: now,
    metadata: %{"demo" => true}
  },
  %Client{
    client_id: "acme-tv-device",
    client_secret_hash: nil,
    client_type: :public,
    name: "Acme Boardroom TV",
    redirect_uris: [],
    allowed_scopes: ["openid", "profile", "read:billing"],
    allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
    allowed_response_types: [],
    token_endpoint_auth_method: :none,
    pkce_required: true,
    subject_type: :public,
    created_by: "seed",
    created_at: now,
    metadata: %{"demo" => true}
  },
  %Client{
    client_id: "acme-ledger-backend",
    client_secret_hash: Lockspire.Security.Policy.hash_client_secret("demo-backend-secret"),
    client_type: :confidential,
    name: "Acme Ledger Backend",
    redirect_uris: ["http://127.0.0.1:4100/oauth/callback"],
    allowed_scopes: ["openid", "email", "profile", "read:billing", "write:reports"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    token_endpoint_auth_method: :client_secret_basic,
    pkce_required: true,
    subject_type: :public,
    created_by: "seed",
    created_at: now,
    metadata: %{"demo" => true}
  }
]

Enum.each(clients, fn client ->
  {:ok, _client} = Repository.register_client(client)
end)

IO.puts("""

Acme Ledger demo seeded.

Accounts:
  alice / bob: tenant users
  ops: operator admin

OAuth:
  public client: acme-ledger-public
  device client: acme-tv-device
  redirect URI: http://127.0.0.1:4100/oauth/callback
""")
