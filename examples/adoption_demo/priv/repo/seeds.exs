alias Lockspire.Domain.Client
alias Lockspire.Domain.ConsentGrant
alias Lockspire.Domain.DeviceAuthorization
alias Lockspire.Domain.InitialAccessToken
alias Lockspire.Domain.Interaction
alias Lockspire.Domain.LogoutDelivery
alias Lockspire.Domain.LogoutEvent
alias Lockspire.Domain.ServerPolicy
alias Lockspire.Domain.SigningKey
alias Lockspire.Domain.Token
alias Lockspire.Storage.Ecto.Repository
alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
alias Lockspire.Storage.Ecto.LogoutEventRecord

repo = AdoptionDemo.Repo

lockspire_tables =
  ~w(
    lockspire_audit_events
    lockspire_ciba_authorizations
    lockspire_consent_grants
    lockspire_device_authorizations
    lockspire_dpop_replay
    lockspire_initial_access_tokens
    lockspire_interactions
    lockspire_logout_deliveries
    lockspire_logout_events
    lockspire_pushed_authorization_requests
    lockspire_server_policies
    lockspire_signing_keys
    lockspire_tokens
    lockspire_used_jtis
    lockspire_clients
  )
  |> Enum.map_join(",\n    ", &Lockspire.Storage.Ecto.Migration.qualified_lockspire_table/1)

oban_table =
  case Lockspire.Config.oban_prefix() do
    nil -> ~s("oban_jobs")
    prefix -> Lockspire.Storage.Ecto.Prefix.quoted_identifier(prefix) <> ~s(."oban_jobs")
  end

Ecto.Adapters.SQL.query!(
  repo,
  """
  TRUNCATE
    #{oban_table},
    #{lockspire_tables}
  RESTART IDENTITY CASCADE
  """,
  []
)

now = DateTime.utc_now()
demo_base_url = Application.fetch_env!(:adoption_demo, :demo_base_url)
oauth_callback_url = demo_base_url <> "/oauth/callback"
lockspire_base_url = demo_base_url <> "/lockspire"

# Phase 110 screenshot proof state matrix:
# healthy, warning, incident, disabled, self-registered, retryable, revoked,
# expired, long-value, and copy-once states are all artificial demo fixtures.
# Copy-once plaintext is not stored or shown again as plaintext after creation.

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
    client_id: "billingo-dashboard-public",
    client_secret_hash: nil,
    client_type: :public,
    name: "Billingo Dashboard SPA",
    redirect_uris: [oauth_callback_url],
    allowed_scopes: ["openid", "email", "profile", "read:billing"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    token_endpoint_auth_method: :none,
    pkce_required: true,
    subject_type: :public,
    created_by: "seed",
    created_at: now,
    metadata: %{"demo" => true, "phase110_state" => "healthy"}
  },
  %Client{
    client_id: "billingo-display-device",
    client_secret_hash: nil,
    client_type: :public,
    name: "Billingo Lobby Display",
    redirect_uris: [],
    allowed_scopes: ["openid", "profile", "read:billing"],
    allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
    allowed_response_types: [],
    token_endpoint_auth_method: :none,
    pkce_required: true,
    subject_type: :public,
    created_by: "seed",
    created_at: now,
    metadata: %{"demo" => true, "phase110_state" => "warning pending device"}
  },
  %Client{
    client_id: "billingo-reports-backend",
    client_secret_hash: Lockspire.Security.Policy.hash_client_secret("demo-backend-secret"),
    client_type: :confidential,
    name: "Billingo Reports Backend",
    redirect_uris: [oauth_callback_url],
    allowed_scopes: ["openid", "email", "profile", "read:billing", "write:reports"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    token_endpoint_auth_method: :client_secret_basic,
    pkce_required: true,
    subject_type: :public,
    created_by: "seed",
    created_at: now,
    metadata: %{"demo" => true, "phase110_state" => "copy-once client secret rotation"}
  },
  %Client{
    client_id: "northstar-payables-portal",
    client_secret_hash: Lockspire.Security.Policy.hash_client_secret("demo-rat-secret"),
    client_type: :confidential,
    name: "Northstar Payables Portal (self-registered)",
    redirect_uris: [
      "https://partners.northstar.example.com/oauth/callback",
      "https://partners.northstar.example.com/oauth/callback/backup"
    ],
    post_logout_redirect_uris: ["https://partners.northstar.example.com/logout/complete"],
    backchannel_logout_uri: "https://partners.northstar.example.com/backchannel-logout",
    backchannel_logout_session_required: true,
    frontchannel_logout_uri: "https://partners.northstar.example.com/frontchannel-logout",
    frontchannel_logout_session_required: false,
    allowed_scopes: ["openid", "email", "profile", "read:billing", "write:reports"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    token_endpoint_auth_method: :client_secret_basic,
    pkce_required: true,
    par_policy: :required,
    dpop_policy: :dpop,
    security_profile: :fapi_2_0_message_signing,
    subject_type: :public,
    created_by: "dcr",
    created_at: now,
    provenance: :self_registered,
    registration_client_uri: lockspire_base_url <> "/register/northstar-payables-portal",
    registration_access_token_hash: Lockspire.Security.Policy.hash_token("demo-rat-northstar"),
    contacts: ["security@northstar.example.com", "integrations@northstar.example.com"],
    metadata: %{
      "demo" => true,
      "journey" => "dcr",
      "phase110_state" => "self-registered long-value copy-once RAT rotation"
    }
  },
  %Client{
    client_id: "legacy-csv-reporter",
    client_secret_hash: Lockspire.Security.Policy.hash_client_secret("demo-disabled-secret"),
    client_type: :confidential,
    name: "Legacy CSV Reporter With A Long Name",
    redirect_uris: ["https://legacy-reporter.example.com/oauth/callback"],
    allowed_scopes: ["openid", "profile", "read:billing"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    token_endpoint_auth_method: :client_secret_basic,
    pkce_required: true,
    subject_type: :public,
    active: false,
    disabled_at: DateTime.add(now, -86_400, :second),
    disabled_by: "ops",
    created_by: "seed",
    created_at: DateTime.add(now, -604_800, :second),
    metadata: %{"demo" => true, "risk" => "disabled", "phase110_state" => "disabled incident"}
  }
]

Enum.each(clients, fn client ->
  {:ok, _client} = Repository.register_client(client)
end)

Enum.each(
  [
    %SigningKey{
      kid: "adoption-demo-es256-upcoming",
      kty: :EC,
      alg: "ES256",
      use: :sig,
      public_jwk: %{
        "kty" => "EC",
        "crv" => "P-256",
        "x" => "demo-x",
        "y" => "demo-y",
        "kid" => "adoption-demo-es256-upcoming",
        "alg" => "ES256",
        "use" => "sig"
      },
      private_jwk_encrypted: <<1>>,
      status: :upcoming,
      metadata: %{"demo" => true}
    },
    %SigningKey{
      kid: "adoption-demo-rs256-retiring",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "n" => "demo-n", "e" => "AQAB"},
      private_jwk_encrypted: <<1>>,
      status: :retiring,
      published_at: DateTime.add(now, -172_800, :second),
      activated_at: DateTime.add(now, -86_400, :second),
      retiring_at: now,
      metadata: %{"demo" => true}
    },
    %SigningKey{
      kid: "adoption-demo-rs256-retired",
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk: %{"kty" => "RSA", "n" => "demo-retired-n", "e" => "AQAB"},
      private_jwk_encrypted: <<1>>,
      status: :retired,
      published_at: DateTime.add(now, -604_800, :second),
      activated_at: DateTime.add(now, -518_400, :second),
      retired_at: DateTime.add(now, -86_400, :second),
      metadata: %{"demo" => true}
    }
  ],
  fn signing_key ->
    {:ok, _key} = Repository.publish_key(signing_key)
  end
)

# Consent grants are keyed by the subject Lockspire records during a real
# authorization (`AdoptionDemo.Lockspire.AccountResolver.subject_for/1`), not by
# the bare Billingo account id, so seeded rows match what live flows produce.
{:ok, remembered_consent} =
  Repository.grant_consent(%ConsentGrant{
    account_id: "user:acct-alice",
    client_id: "billingo-dashboard-public",
    scopes: ["openid", "email", "profile", "read:billing"],
    granted_at: DateTime.add(now, -3_600, :second),
    kind: :remembered,
    metadata: %{"demo" => true}
  })

{:ok, _revoked_consent} =
  Repository.grant_consent(%ConsentGrant{
    account_id: "user:acct-bob",
    client_id: "legacy-csv-reporter",
    scopes: ["openid", "profile"],
    granted_at: DateTime.add(now, -172_800, :second),
    status: :revoked,
    revoked_at: DateTime.add(now, -86_400, :second),
    revoked_by: "ops",
    revoked_reason: "partner offboarding",
    kind: :one_time,
    metadata: %{"demo" => true}
  })

tokens = [
  %Token{
    token_hash: Lockspire.Security.Policy.hash_token("demo-access-active"),
    token_type: :access_token,
    jti: "demo-active-jti",
    client_id: "billingo-dashboard-public",
    account_id: "acct-alice",
    interaction_id: "interaction-pending-consent",
    consent_grant_id: remembered_consent.id,
    scopes: ["openid", "email", "read:billing"],
    audience: ["https://api.billingo.test/billing"],
    issued_at: DateTime.add(now, -900, :second),
    expires_at: DateTime.add(now, 2_700, :second)
  },
  %Token{
    token_hash: Lockspire.Security.Policy.hash_token("demo-refresh-active"),
    token_type: :refresh_token,
    family_id: "family-demo-1",
    generation: 1,
    client_id: "billingo-dashboard-public",
    account_id: "acct-alice",
    scopes: ["openid", "email", "read:billing"],
    issued_at: DateTime.add(now, -900, :second),
    expires_at: DateTime.add(now, 86_400, :second)
  },
  %Token{
    token_hash: Lockspire.Security.Policy.hash_token("demo-refresh-reuse-detected"),
    token_type: :refresh_token,
    family_id: "family-demo-reuse",
    generation: 2,
    client_id: "northstar-payables-portal",
    account_id: "acct-bob",
    scopes: ["openid", "profile", "write:reports"],
    issued_at: DateTime.add(now, -7_200, :second),
    expires_at: DateTime.add(now, 86_400, :second),
    reuse_detected_at: DateTime.add(now, -1_200, :second)
  },
  %Token{
    token_hash: Lockspire.Security.Policy.hash_token("demo-access-revoked"),
    token_type: :access_token,
    client_id: "legacy-csv-reporter",
    account_id: "acct-bob",
    scopes: ["openid", "profile"],
    issued_at: DateTime.add(now, -86_400, :second),
    expires_at: DateTime.add(now, 600, :second),
    revoked_at: DateTime.add(now, -3_600, :second)
  },
  %Token{
    token_hash: Lockspire.Security.Policy.hash_token("demo-access-expired"),
    token_type: :access_token,
    client_id: "billingo-reports-backend",
    account_id: "acct-alice",
    scopes: ["openid", "read:billing"],
    issued_at: DateTime.add(now, -7_200, :second),
    expires_at: DateTime.add(now, -3_600, :second)
  },
  %Token{
    token_hash: Lockspire.Security.Policy.hash_token("demo-refresh-long-family-expired"),
    token_type: :refresh_token,
    family_id: "family-demo-long-value-refresh-token-family-id-for-mobile-wrapping-proof-001",
    generation: 3,
    client_id: "northstar-payables-portal",
    account_id: "acct-phase110-long-value-subject-for-mobile-proof",
    scopes: ["openid", "email", "profile", "read:billing", "write:reports"],
    audience: ["https://very-long-resource-indicator.partners.northstar.example.com/billing"],
    issued_at: DateTime.add(now, -172_800, :second),
    expires_at: DateTime.add(now, -86_400, :second),
    revoked_at: DateTime.add(now, -43_200, :second)
  }
]

Enum.each(tokens, fn token ->
  {:ok, _token} = Repository.store_token(token)
end)

Enum.each(
  [
    %Interaction{
      interaction_id: "interaction-pending-login",
      client_id: "billingo-dashboard-public",
      return_to: lockspire_base_url <> "/interactions/interaction-pending-login",
      status: :pending_login,
      scopes_requested: ["openid", "email"],
      expires_at: DateTime.add(now, 600, :second),
      inserted_at: DateTime.add(now, -60, :second),
      updated_at: DateTime.add(now, -60, :second)
    },
    %Interaction{
      interaction_id: "interaction-pending-consent",
      client_id: "northstar-payables-portal",
      account_id: "acct-alice",
      return_to: lockspire_base_url <> "/interactions/interaction-pending-consent",
      status: :pending_consent,
      scopes_requested: ["openid", "profile", "write:reports"],
      resources_requested: ["https://api.billingo.test/billing"],
      expires_at: DateTime.add(now, 600, :second),
      inserted_at: DateTime.add(now, -120, :second),
      updated_at: DateTime.add(now, -120, :second)
    },
    %Interaction{
      interaction_id: "interaction-denied",
      client_id: "legacy-csv-reporter",
      account_id: "acct-bob",
      return_to: "https://legacy-reporter.example.com/callback",
      status: :denied,
      denied_at: DateTime.add(now, -3_600, :second),
      denial_reason: "operator denied demo request",
      expires_at: DateTime.add(now, -3_000, :second),
      inserted_at: DateTime.add(now, -4_000, :second),
      updated_at: DateTime.add(now, -3_600, :second)
    },
    %Interaction{
      interaction_id: "interaction-expired",
      client_id: "billingo-reports-backend",
      account_id: "acct-phase110-long-value-subject-for-mobile-proof",
      return_to: "https://reports.billingo.example.com/very/long/oauth/callback/path",
      status: :expired,
      scopes_requested: ["openid", "email", "profile", "read:billing"],
      expired_at: DateTime.add(now, -900, :second),
      expires_at: DateTime.add(now, -900, :second),
      inserted_at: DateTime.add(now, -7_200, :second),
      updated_at: DateTime.add(now, -900, :second)
    }
  ],
  fn interaction ->
    {:ok, _interaction} = Repository.put_interaction(interaction)
  end
)

Enum.each(
  [
    %DeviceAuthorization{
      device_code_hash: Lockspire.Security.Policy.hash_token("demo-device-pending"),
      user_code_hash: Lockspire.Security.Policy.hash_token("ABCD1234"),
      verification_handle: "demo-device-pending",
      client_id: "billingo-display-device",
      scopes: ["openid", "profile"],
      status: :pending,
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, 5, :second),
      expires_at: DateTime.add(now, 600, :second)
    },
    %DeviceAuthorization{
      device_code_hash: Lockspire.Security.Policy.hash_token("demo-device-approved"),
      user_code_hash: Lockspire.Security.Policy.hash_token("EFGH5678"),
      verification_handle: "demo-device-approved",
      client_id: "billingo-display-device",
      scopes: ["openid", "profile"],
      status: :approved,
      subject_id: "acct-alice",
      approved_at: DateTime.add(now, -120, :second),
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, -115, :second),
      expires_at: DateTime.add(now, 600, :second)
    },
    %DeviceAuthorization{
      device_code_hash: Lockspire.Security.Policy.hash_token("demo-device-expired"),
      user_code_hash: Lockspire.Security.Policy.hash_token("IJKL9012"),
      verification_handle: "demo-device-expired",
      client_id: "billingo-display-device",
      scopes: ["openid"],
      status: :expired,
      expired_at: DateTime.add(now, -60, :second),
      effective_poll_interval_seconds: 10,
      next_poll_allowed_at: DateTime.add(now, -55, :second),
      expires_at: DateTime.add(now, -60, :second)
    },
    %DeviceAuthorization{
      device_code_hash: Lockspire.Security.Policy.hash_token("demo-device-denied"),
      user_code_hash: Lockspire.Security.Policy.hash_token("MNOP3456"),
      verification_handle: "demo-device-denied-long-value-handle-for-mobile-proof",
      client_id: "billingo-display-device",
      scopes: ["openid", "profile"],
      status: :denied,
      subject_id: "acct-bob",
      denied_at: DateTime.add(now, -300, :second),
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, -295, :second),
      expires_at: DateTime.add(now, 300, :second)
    },
    %DeviceAuthorization{
      device_code_hash: Lockspire.Security.Policy.hash_token("demo-device-consumed"),
      user_code_hash: Lockspire.Security.Policy.hash_token("QRST7890"),
      verification_handle: "demo-device-consumed",
      client_id: "billingo-display-device",
      scopes: ["openid", "profile"],
      status: :consumed,
      subject_id: "acct-alice",
      approved_at: DateTime.add(now, -600, :second),
      consumed_at: DateTime.add(now, -120, :second),
      effective_poll_interval_seconds: 5,
      next_poll_allowed_at: DateTime.add(now, -595, :second),
      expires_at: DateTime.add(now, 300, :second)
    }
  ],
  fn auth ->
    {:ok, _auth} = Repository.put_device_authorization(auth)
  end
)

Enum.each(
  [
    %InitialAccessToken{
      token_hash: Lockspire.Security.Policy.hash_token("demo-iat-active"),
      expires_at: DateTime.add(now, 86_400, :second),
      single_use: true,
      created_by: "ops"
    },
    %InitialAccessToken{
      token_hash: Lockspire.Security.Policy.hash_token("demo-iat-revoked"),
      expires_at: DateTime.add(now, 86_400, :second),
      revoked_at: DateTime.add(now, -600, :second),
      single_use: false,
      created_by: "ops"
    },
    %InitialAccessToken{
      token_hash: Lockspire.Security.Policy.hash_token("demo-iat-used"),
      expires_at: DateTime.add(now, 86_400, :second),
      used_at: DateTime.add(now, -3_600, :second),
      single_use: true,
      created_by: "ops"
    },
    %InitialAccessToken{
      token_hash: Lockspire.Security.Policy.hash_token("demo-iat-expired"),
      expires_at: DateTime.add(now, -600, :second),
      single_use: true,
      created_by: "ops"
    }
  ],
  fn iat ->
    {:ok, _iat} = Repository.save_initial_access_token(iat)
  end
)

{:ok, logout_event} =
  %LogoutEventRecord{}
  |> LogoutEventRecord.changeset(%LogoutEvent{
    event_id: "demo-logout-event",
    sid: "sid-demo-1",
    account_id: "acct-alice",
    subject: "acct-alice",
    completed_at: now,
    post_logout_redirect_uri: demo_base_url <> "/"
  })
  |> repo.insert()
  |> case do
    {:ok, record} -> {:ok, LogoutEventRecord.to_domain(record)}
    other -> other
  end

{:ok, pending_logout_event} =
  %LogoutEventRecord{}
  |> LogoutEventRecord.changeset(%LogoutEvent{
    event_id: "demo-logout-event-pending",
    sid: "sid-demo-pending",
    account_id: "acct-alice",
    subject: "acct-alice",
    completed_at: now,
    post_logout_redirect_uri: demo_base_url <> "/"
  })
  |> repo.insert()
  |> case do
    {:ok, record} -> {:ok, LogoutEventRecord.to_domain(record)}
    other -> other
  end

{:ok, discarded_logout_event} =
  %LogoutEventRecord{}
  |> LogoutEventRecord.changeset(%LogoutEvent{
    event_id: "demo-logout-event-discarded",
    sid: "sid-demo-discarded",
    account_id: "acct-bob",
    subject: "acct-bob",
    completed_at: now,
    post_logout_redirect_uri: demo_base_url <> "/"
  })
  |> repo.insert()
  |> case do
    {:ok, record} -> {:ok, LogoutEventRecord.to_domain(record)}
    other -> other
  end

Enum.each(
  [
    %LogoutDelivery{
      delivery_id: "demo-logout-backchannel-succeeded",
      logout_event_id: logout_event.id,
      client_id: "northstar-payables-portal",
      channel: :backchannel,
      target_uri: "https://partners.northstar.example.com/backchannel-logout",
      session_required: true,
      status: :succeeded,
      attempt_count: 1,
      delivered_at: DateTime.add(now, -60, :second),
      finalized_at: DateTime.add(now, -60, :second),
      http_status: 200
    },
    %LogoutDelivery{
      delivery_id: "demo-logout-backchannel-retryable",
      logout_event_id: logout_event.id,
      client_id: "legacy-csv-reporter",
      channel: :backchannel,
      target_uri: "https://legacy-reporter.example.com/backchannel-logout",
      session_required: false,
      status: :retryable,
      attempt_count: 3,
      last_attempted_at: DateTime.add(now, -120, :second),
      http_status: 503,
      failure_reason: "upstream unavailable"
    },
    %LogoutDelivery{
      delivery_id: "demo-logout-frontchannel-rendered",
      logout_event_id: logout_event.id,
      client_id: "northstar-payables-portal",
      channel: :frontchannel,
      target_uri: "https://partners.northstar.example.com/frontchannel-logout",
      session_required: false,
      status: :rendered,
      attempt_count: 0,
      rendered_at: DateTime.add(now, -30, :second)
    },
    %LogoutDelivery{
      delivery_id: "demo-logout-backchannel-pending-long-value-delivery-id-for-mobile-proof",
      logout_event_id: pending_logout_event.id,
      client_id: "northstar-payables-portal",
      channel: :backchannel,
      target_uri:
        "https://partners.northstar.example.com/backchannel-logout/very/long/path/for/mobile-proof",
      session_required: true,
      status: :pending,
      attempt_count: 0
    },
    %LogoutDelivery{
      delivery_id: "demo-logout-backchannel-discarded",
      logout_event_id: discarded_logout_event.id,
      client_id: "legacy-csv-reporter",
      channel: :backchannel,
      target_uri: "https://legacy-reporter.example.com/backchannel-logout",
      session_required: false,
      status: :discarded,
      attempt_count: 5,
      last_attempted_at: DateTime.add(now, -600, :second),
      finalized_at: DateTime.add(now, -300, :second),
      http_status: 500,
      failure_reason: "operator discarded demo delivery after repeated failures"
    }
  ],
  fn delivery ->
    %LogoutDeliveryRecord{}
    |> LogoutDeliveryRecord.changeset(delivery)
    |> repo.insert!()
  end
)

IO.puts("""

Billingo demo seeded.

Accounts:
  alice / bob: tenant users
  ops: operator admin

OAuth:
  public client: billingo-dashboard-public
  device client: billingo-display-device
  redirect URI: #{oauth_callback_url}
""")
