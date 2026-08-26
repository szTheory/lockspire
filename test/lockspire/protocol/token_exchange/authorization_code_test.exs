defmodule Lockspire.Protocol.TokenExchange.AuthorizationCodeTest do
  use Lockspire.TokenExchangeCase

  test "redeems a confidential-client authorization code into an opaque bearer access token", %{
    events: events
  } do
    secret = "super-secret-value"

    {:ok, client} =
      create_client("client-basic", :client_secret_basic, secret, ["authorization_code"], %{
        access_token_format: :opaque
      })

    _code =
      create_authorization_code(client, raw_code: "code-basic", code_verifier: "verifier-basic")

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-basic",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-basic"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert success.access_token
    assert success.token_type == "Bearer"
    assert success.expires_in == 3600
    assert success.scope == "email profile"

    assert {:ok, nil} =
             Repository.fetch_active_authorization_code(TokenFormatter.hash_token("code-basic"))

    persisted_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where: token.token_type == :access_token and token.client_id == ^client.client_id
        )
      )

    assert persisted_token.account_id == "subject-123"
    assert persisted_token.token_hash == TokenFormatter.hash_token(success.access_token)
    assert persisted_token.cnf == nil
    refute persisted_token.token_hash == success.access_token
    # Opaque opt-in: the issued token is NOT a JOSE-verifiable at+jwt.
    refute opaque_token_is_at_jwt?(success.access_token)

    event_names = recorded_event_names(events)
    assert [:lockspire, :authorization_code, :redeemed] in event_names
    assert [:lockspire, :token, :issued] in event_names
  end

  test "AC flow mints an at+jwt access token by default and re-points the persisted hash to the signer's hash" do
    secret = "ac-jwt-default-secret"
    publish_signing_key("kid-ac-jwt")
    {:ok, client} = create_client("client-ac-jwt", :client_secret_basic, secret)

    _code =
      create_authorization_code(client, raw_code: "code-ac-jwt", code_verifier: "verifier-ac-jwt")

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-ac-jwt",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-ac-jwt"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    {header, claims} = verify_at_jwt(success.access_token)
    assert header["typ"] == "at+jwt"
    assert claims["iss"] == "https://example.test/lockspire"
    assert claims["sub"] == "subject-123"
    assert claims["client_id"] == client.client_id
    # AUD-02: absent resource= yields aud == [client_id] (list form).
    assert claims["aud"] == [client.client_id]

    persisted_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where: token.token_type == :access_token and token.client_id == ^client.client_id
        )
      )

    # T-99-12: the persisted hash must equal the hash of the issued raw token so
    # introspection/revocation by hash still resolves.
    assert persisted_token.token_hash ==
             Lockspire.Security.Policy.hash_token(success.access_token)
  end

  test "AC flow with resource= mints an at+jwt whose aud == [resource] (AUD-01)" do
    secret = "ac-jwt-resource-secret"
    publish_signing_key("kid-ac-resource")
    {:ok, client} = create_client("client-ac-resource", :client_secret_basic, secret)

    _code =
      create_authorization_code(client,
        raw_code: "code-ac-resource",
        code_verifier: "verifier-ac-resource",
        audience: ["https://billing.example.com"]
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-ac-resource",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-ac-resource",
                 "resource" => "https://billing.example.com"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    {_header, claims} = verify_at_jwt(success.access_token)
    assert claims["aud"] == ["https://billing.example.com"]
  end

  test "AC flow honors a per-client :opaque override even though the server default is :jwt" do
    secret = "ac-opaque-optin-secret"

    {:ok, client} =
      create_client("client-ac-opaque", :client_secret_basic, secret, ["authorization_code"], %{
        access_token_format: :opaque
      })

    _code =
      create_authorization_code(client,
        raw_code: "code-ac-opaque",
        code_verifier: "verifier-ac-opaque"
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-ac-opaque",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-ac-opaque"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    refute opaque_token_is_at_jwt?(success.access_token)

    persisted_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where: token.token_type == :access_token and token.client_id == ^client.client_id
        )
      )

    assert persisted_token.token_hash == TokenFormatter.hash_token(success.access_token)
  end

  test "issues an RS256 id token for openid code flow using the linked interaction nonce" do
    secret = "openid-secret"
    {:ok, client} = create_client("client-openid", :client_secret_basic, secret)
    publish_signing_key("kid-openid")

    _code =
      create_authorization_code(client,
        raw_code: "code-openid",
        code_verifier: "verifier-openid",
        scopes: ["openid", "email", "profile"],
        nonce: "nonce-from-interaction"
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-openid",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-openid"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert is_binary(success.id_token)

    assert %{"alg" => "RS256", "kid" => "kid-openid", "typ" => "JWT"} =
             decode_jwt_section(success.id_token, 0)

    claims = decode_jwt_section(success.id_token, 1)

    assert claims["iss"] == "https://example.test/lockspire"
    assert claims["aud"] == client.client_id
    assert claims["sub"] == "subject-123"
    assert claims["nonce"] == "nonce-from-interaction"
    assert claims["at_hash"] == at_hash(success.access_token)
  end

  test "token exchange emits auth_time only when openid was granted and max_age was persisted on the interaction" do
    secret = "openid-auth-time-secret"
    {:ok, client} = create_client("client-openid-auth-time", :client_secret_basic, secret)
    publish_signing_key("kid-openid-auth-time")
    auth_time = DateTime.add(DateTime.utc_now(), -45, :second)

    _code =
      create_authorization_code(client,
        raw_code: "code-openid-auth-time",
        code_verifier: "verifier-openid-auth-time",
        scopes: ["openid", "email"],
        auth_time: auth_time,
        max_age: 120
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-openid-auth-time",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-openid-auth-time"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    claims = decode_jwt_section(success.id_token, 1)
    assert claims["auth_time"] == DateTime.to_unix(auth_time)
  end

  test "token exchange emits auth_time for explicit auth_time_requested and preserves nonce unchanged" do
    secret = "openid-auth-time-requested-secret"

    {:ok, client} =
      create_client("client-openid-auth-time-requested", :client_secret_basic, secret)

    publish_signing_key("kid-openid-auth-time-requested")
    auth_time = DateTime.add(DateTime.utc_now(), -30, :second)

    _code =
      create_authorization_code(client,
        raw_code: "code-openid-auth-time-requested",
        code_verifier: "verifier-openid-auth-time-requested",
        scopes: ["openid", "email"],
        nonce: "nonce-with-auth-time",
        auth_time: auth_time,
        auth_time_requested: true
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-openid-auth-time-requested",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-openid-auth-time-requested"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    claims = decode_jwt_section(success.id_token, 1)
    assert claims["auth_time"] == DateTime.to_unix(auth_time)
    assert claims["nonce"] == "nonce-with-auth-time"
  end

  test "token exchange fails closed with missing_interaction_auth_time when auth_time was requested but missing" do
    secret = "openid-auth-time-missing-secret"
    {:ok, client} = create_client("client-openid-auth-time-missing", :client_secret_basic, secret)
    publish_signing_key("kid-openid-auth-time-missing")

    _code =
      create_authorization_code(client,
        raw_code: "code-openid-auth-time-missing",
        code_verifier: "verifier-openid-auth-time-missing",
        scopes: ["openid", "email"],
        max_age: 120
      )

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-openid-auth-time-missing",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-openid-auth-time-missing"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.error == "server_error"
    assert error.reason_code == :missing_interaction_auth_time
  end

  test "does not issue an id token when openid is not granted" do
    secret = "oauth-secret"
    {:ok, client} = create_client("client-oauth", :client_secret_basic, secret)
    publish_signing_key("kid-oauth")

    _code =
      create_authorization_code(client, raw_code: "code-oauth", code_verifier: "verifier-oauth")

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-oauth",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-oauth"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert success.id_token == nil
  end

  test "rejects authorization-code exchange with invalid_dpop_proof when DPoP is required but missing" do
    secret = "missing-dpop-secret"

    {:ok, client} =
      create_client(
        "client-dpop-missing",
        :client_secret_basic,
        secret,
        ["authorization_code"],
        %{
          dpop_policy: :dpop
        }
      )

    _code =
      create_authorization_code(client,
        raw_code: "code-dpop-missing",
        code_verifier: "verifier-dpop-missing"
      )

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-dpop-missing",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-dpop-missing"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.error == "invalid_dpop_proof"
    assert error.reason_code == :missing_dpop_proof
  end

  test "returns token_type DPoP and persists matching cnf on access and refresh tokens" do
    secret = "dpop-issue-secret"

    {:ok, client} =
      create_client(
        "client-dpop-issue",
        :client_secret_basic,
        secret,
        ["authorization_code", "refresh_token"],
        %{
          allowed_scopes: ["email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    _code =
      create_authorization_code(client,
        raw_code: "code-dpop-issue",
        code_verifier: "verifier-dpop-issue",
        scopes: ["email", "profile", "offline_access"]
      )

    %{jwt: proof_jwt, validated: validated_proof} = dpop_proof_fixture()

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-dpop-issue",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-dpop-issue"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_jwt,
               dpop_replay_store: Repository,
               method: "POST",
               access_token_generator: fn -> "issued-dpop-access-token" end,
               refresh_token_generator: fn -> "issued-dpop-refresh-token" end
             )

    assert success.token_type == "DPoP"

    assert {:ok, %Token{} = persisted_refresh_token} =
             Repository.fetch_refresh_token(
               TokenFormatter.hash_token("issued-dpop-refresh-token")
             )

    persisted_access_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where:
            token.token_type == :access_token and
              token.client_id == ^client.client_id and
              token.token_hash == ^TokenFormatter.hash_token(success.access_token)
        )
      )

    assert persisted_access_token.cnf["jkt"] == validated_proof.jkt
    assert persisted_refresh_token.cnf["jkt"] == validated_proof.jkt
  end

  test "returns use_dpop_nonce for authorization-code exchange before succeeding with the supplied nonce" do
    secret = "auth-code-nonce-secret"

    {:ok, client} =
      create_client(
        "client-auth-code-nonce",
        :client_secret_basic,
        secret,
        ["authorization_code", "refresh_token"],
        %{
          allowed_scopes: ["email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    _code =
      create_authorization_code(client,
        raw_code: "code-dpop-nonce",
        code_verifier: "verifier-dpop-nonce",
        scopes: ["email", "profile", "offline_access"]
      )

    %{jwt: proof_without_nonce} = dpop_proof_fixture(nonce: nil)

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-dpop-nonce",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-dpop-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_without_nonce,
               dpop_replay_store: Repository,
               method: "POST"
             )

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :missing_dpop_nonce
    assert is_binary(error.dpop_nonce)

    %{jwt: proof_with_nonce, validated: validated_proof} = dpop_proof_fixture(error.dpop_nonce)

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-dpop-nonce",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-dpop-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_with_nonce,
               dpop_replay_store: Repository,
               method: "POST",
               access_token_generator: fn -> "auth-code-nonce-access-token" end,
               refresh_token_generator: fn -> "auth-code-nonce-refresh-token" end
             )

    assert success.token_type == "DPoP"

    persisted_access_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where:
            token.token_type == :access_token and
              token.client_id == ^client.client_id and
              token.token_hash == ^TokenFormatter.hash_token(success.access_token)
        )
      )

    assert persisted_access_token.cnf["jkt"] == validated_proof.jkt
  end

  test "accepts the first validated proof and rejects a replayed proof as invalid_dpop_proof" do
    secret = "replayed-dpop-secret"

    {:ok, client} =
      create_client("client-dpop-replay", :client_secret_basic, secret, ["authorization_code"], %{
        dpop_policy: :dpop,
        access_token_format: :opaque
      })

    _first_code =
      create_authorization_code(client,
        raw_code: "code-dpop-first",
        code_verifier: "verifier-dpop-first"
      )

    _second_code =
      create_authorization_code(client,
        raw_code: "code-dpop-second",
        code_verifier: "verifier-dpop-second"
      )

    %{jwt: proof_jwt} = dpop_proof_fixture()

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-dpop-first",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-dpop-first"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_jwt,
               dpop_replay_store: Repository,
               method: "POST"
             )

    assert success.token_type == "DPoP"

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-dpop-second",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-dpop-second"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_jwt,
               dpop_replay_store: Repository,
               method: "POST"
             )

    assert error.error == "invalid_dpop_proof"
    assert error.reason_code == :dpop_proof_replayed
  end

  test "issues a refresh token when the client allows refresh grants" do
    secret = "refresh-secret"

    {:ok, client} =
      create_client(
        "client-refresh-issuer",
        :client_secret_basic,
        secret,
        ["authorization_code", "refresh_token"],
        %{access_token_format: :opaque}
      )

    _code =
      create_authorization_code(client,
        raw_code: "code-refresh-issue",
        code_verifier: "verifier-refresh-issue",
        scopes: ["email", "offline_access"]
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-refresh-issue",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-refresh-issue"
               },
               authorization: basic_auth(client.client_id, secret),
               access_token_generator: fn -> "issued-access-token" end,
               refresh_token_generator: fn -> "issued-refresh-token" end
             )

    assert success.refresh_token == "issued-refresh-token"

    assert {:ok, %Token{} = persisted_refresh_token} =
             Repository.fetch_refresh_token(TokenFormatter.hash_token("issued-refresh-token"))

    persisted_access_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where:
            token.token_type == :access_token and
              token.client_id == ^client.client_id and
              token.token_hash == ^TokenFormatter.hash_token(success.access_token)
        )
      )

    assert success.token_type == "Bearer"
    assert persisted_access_token.cnf == nil
    assert persisted_refresh_token.cnf == nil
    assert persisted_refresh_token.family_id == TokenFormatter.hash_token("issued-refresh-token")
    assert persisted_refresh_token.scopes == ["email", "offline_access"]
  end

  test "accepts form-encoded basic auth credentials containing reserved characters and colons" do
    client_id = "client:with/slash"
    secret = "sec:ret?/+= value:tail"
    publish_signing_key("kid-encoded-basic")
    {:ok, client} = create_client(client_id, :client_secret_basic, secret)

    _code =
      create_authorization_code(client,
        raw_code: "code-encoded-basic",
        code_verifier: "verifier-encoded-basic"
      )

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-encoded-basic",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-encoded-basic"
               },
               authorization: basic_auth_form_encoded(client_id, secret)
             )

    assert success.access_token
    assert success.token_type == "Bearer"
  end

  test "rejects replayed authorization code redemption and emits replay telemetry", %{
    events: events
  } do
    secret = "replay-secret"
    publish_signing_key("kid-replay")
    {:ok, client} = create_client("client-replay", :client_secret_basic, secret)

    _code =
      create_authorization_code(client, raw_code: "code-replay", code_verifier: "verifier-replay")

    assert {:ok, _success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-replay",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-replay"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-replay",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-replay"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.error == "invalid_grant"
    assert error.reason_code == :authorization_code_replayed
    assert [:lockspire, :authorization_code, :replay_detected] in recorded_event_names(events)
  end

  test "successful redemption and replay attempts append durable audit rows with client attribution",
       %{events: events} do
    secret = "audit-secret"
    publish_signing_key("kid-audit")
    {:ok, client} = create_client("client-audit", :client_secret_basic, secret)

    {:ok, authorization_code} =
      create_authorization_code(client, raw_code: "code-audit", code_verifier: "verifier-audit")

    assert {:ok, _success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-audit",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-audit"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert {:error, replay_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-audit",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-audit"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert replay_error.reason_code == :authorization_code_replayed

    audits =
      Lockspire.TestRepo.all(AuditEventRecord)
      |> Enum.filter(&(&1.actor_id == client.client_id))

    assert Enum.any?(audits, fn audit ->
             audit.action == "authorization_code_redeemed" and
               audit.resource_type == "authorization_code" and
               audit.resource_id == Integer.to_string(authorization_code.id) and
               audit.actor_type == "client" and
               audit.reason_code == "authorization_code_redeemed"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "authorization_code_replay_detected" and
               audit.resource_type == "authorization_code" and
               audit.resource_id == Integer.to_string(authorization_code.id) and
               audit.actor_type == "client" and
               audit.reason_code == "authorization_code_replayed"
           end)

    assert {[:lockspire, :authorization_code, :redeemed],
            %{reason_code: :authorization_code_redeemed}} =
             Enum.find(recorded_events(events), fn {event, metadata} ->
               event == [:lockspire, :authorization_code, :redeemed] and
                 metadata[:reason_code] == :authorization_code_redeemed
             end)

    assert {[:lockspire, :authorization_code, :replay_detected],
            %{reason_code: :authorization_code_replayed}} =
             Enum.find(recorded_events(events), fn {event, metadata} ->
               event == [:lockspire, :authorization_code, :replay_detected] and
                 metadata[:reason_code] == :authorization_code_replayed
             end)
  end

  test "rejects authorization codes issued with an unsupported PKCE challenge method" do
    secret = "plain-method-secret"
    {:ok, client} = create_client("client-plain-method", :client_secret_basic, secret)
    raw_code = "code-plain-method"

    PlainMethodTokenStore.use_token(%Token{
      id: 123,
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: "subject-123",
      interaction_id: "interaction-code-plain-method",
      redirect_uri: "https://client.example.com/callback",
      scopes: ["email", "profile"],
      code_challenge: code_challenge("verifier-plain-method"),
      code_challenge_method: :plain,
      issued_at: DateTime.utc_now(),
      expires_at: DateTime.add(DateTime.utc_now(), 300, :second)
    })

    assert {:error, error} =
             exchange_with_store(
               %{
                 "grant_type" => "authorization_code",
                 "code" => raw_code,
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-plain-method"
               },
               PlainMethodTokenStore,
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.reason_code == :unsupported_code_challenge_method
  end

  test "rejects expired, verifier-mismatched, client-mismatched, and redirect-mismatched exchanges" do
    secret = "negative-secret"
    {:ok, client} = create_client("client-negative", :client_secret_basic, secret)

    create_authorization_code(client,
      raw_code: "code-expired",
      code_verifier: "expired-verifier",
      expires_at: DateTime.add(DateTime.utc_now(), -60, :second)
    )

    assert {:error, expired_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-expired",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "expired-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert expired_error.reason_code == :authorization_code_expired

    create_authorization_code(client,
      raw_code: "code-verifier",
      code_verifier: "correct-verifier"
    )

    assert {:error, verifier_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-verifier",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "wrong-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert verifier_error.reason_code == :code_verifier_mismatch

    secret_two = "other-secret"
    {:ok, other_client} = create_client("client-other", :client_secret_basic, secret_two)

    create_authorization_code(client,
      raw_code: "code-client-mismatch",
      code_verifier: "client-verifier"
    )

    assert {:error, client_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-client-mismatch",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "client-verifier"
               },
               authorization: basic_auth(other_client.client_id, secret_two)
             )

    assert client_error.reason_code == :client_mismatch

    create_authorization_code(client,
      raw_code: "code-redirect-mismatch",
      code_verifier: "redirect-verifier"
    )

    assert {:error, redirect_error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-redirect-mismatch",
                 "redirect_uri" => "https://attacker.example.com/callback",
                 "code_verifier" => "redirect-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert redirect_error.reason_code == :redirect_uri_mismatch
  end

  test "AC flow with an unauthorized resource returns invalid_target (:invalid_resource, 400)" do
    # validate_requested_resources/2 (AC) and validate_grant_resources/2 (device/CIBA)
    # share the identical membership-rejection cond: when the grant carries a
    # recorded authorized audience and the requested resource is not a member, the
    # request is rejected with invalid_target (:invalid_resource, 400) — T-99-11.
    # AC is the reachable surface for the rejection branch because the authorization
    # code records an authorized audience; device/CIBA record none today, so their
    # reachable behavior is the accept-any-when-empty AUD-01 path proven above.
    secret = "ac-unauthorized-resource-secret"
    {:ok, client} = create_client("client-ac-unauthorized", :client_secret_basic, secret)

    _code =
      create_authorization_code(client,
        raw_code: "code-ac-unauthorized",
        code_verifier: "verifier-ac-unauthorized",
        audience: ["https://api.allowed.example.com"]
      )

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "code-ac-unauthorized",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-ac-unauthorized",
                 "resource" => "https://api.evil.example.com"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.status == 400
    assert error.error == "invalid_target"
    assert error.reason_code == :invalid_resource
  end
end
