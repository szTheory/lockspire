defmodule Lockspire.Protocol.TokenExchangeTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.DPoPNonce
  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  defmodule Resolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    @impl true
    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-123"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: account.id,
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{"email" => "#{account.id}@example.test", "name" => "Subject #{account.id}"}
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context) do
      %InteractionResult{login_path: "/sign-in", return_to: "/authorize", params: %{}}
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Resolver)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :telemetry.detach("token-exchange-test-handler")

    events = start_supervised!({Agent, fn -> [] end})

    :telemetry.attach_many(
      "token-exchange-test-handler",
      [
        [:lockspire, :authorization_code, :redeemed],
        [:lockspire, :token, :issued],
        [:lockspire, :authorization_code, :replay_detected],
        [:lockspire, :token_exchange, :failed]
      ],
      fn event, _measurements, metadata, pid ->
        Agent.update(pid, fn current -> [{event, metadata} | current] end)
      end,
      events
    )

    on_exit(fn -> :telemetry.detach("token-exchange-test-handler") end)

    %{events: events}
  end

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
    assert persisted_token.token_hash == Lockspire.Security.Policy.hash_token(success.access_token)
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

    __MODULE__.PlainMethodTokenStore.use_token(%Token{
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
               __MODULE__.PlainMethodTokenStore,
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

  test "rejects unsupported grant types and unsupported token-endpoint auth methods" do
    secret = "post-secret"
    {:ok, basic_client} = create_client("client-basic-only", :client_secret_basic, secret)

    _code =
      create_authorization_code(basic_client,
        raw_code: "code-post",
        code_verifier: "verifier-post"
      )

    assert {:error, grant_error} =
             exchange(
               %{
                 "grant_type" => "refresh_token",
                 "code" => "code-post",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "verifier-post"
               },
               authorization: basic_auth(basic_client.client_id, secret)
             )

    assert grant_error.error == "unsupported_grant_type"

    assert {:error, auth_error} =
             exchange(%{
               "grant_type" => "authorization_code",
               "client_id" => basic_client.client_id,
               "client_secret" => secret,
               "code" => "code-post",
               "redirect_uri" => "https://client.example.com/callback",
               "code_verifier" => "verifier-post"
             })

    assert auth_error.error == "invalid_client"
    assert auth_error.reason_code == :unsupported_token_endpoint_auth_method
  end

  test "maps pending, slow_down, denied, expired, and unknown device polls into RFC 8628 token errors" do
    public_client =
      create_public_client("device-public-client", [
        "urn:ietf:params:oauth:grant-type:device_code"
      ])

    dpop_public_client =
      create_public_client("device-dpop-public-client", [
        "urn:ietf:params:oauth:grant-type:device_code"
      ])

    update_client_dpop_policy!(dpop_public_client.client_id, :dpop)

    confidential_secret = "device-confidential-secret"

    {:ok, confidential_client} =
      create_client(
        "device-confidential-client",
        :client_secret_basic,
        confidential_secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, pending} =
      create_device_authorization(public_client,
        device_code: "device-code-pending",
        user_code: "PEND-ING1"
      )

    assert {:error, pending_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "client_id" => public_client.client_id,
                 "device_code" => "device-code-pending"
               },
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> pending.next_poll_allowed_at end
               ]
             })

    assert pending_error.error == "authorization_pending"
    assert pending_error.reason_code == :device_authorization_pending

    {:ok, dpop_pending} =
      create_device_authorization(dpop_public_client,
        device_code: "device-code-dpop-pending",
        user_code: "DPND-ING1"
      )

    assert {:error, dpop_pending_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "client_id" => dpop_public_client.client_id,
                 "device_code" => "device-code-dpop-pending"
               },
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> dpop_pending.next_poll_allowed_at end
               ]
             })

    assert dpop_pending_error.error == "authorization_pending"
    assert dpop_pending_error.reason_code == :device_authorization_pending

    {:ok, too_early} =
      create_device_authorization(confidential_client,
        device_code: "device-code-too-early",
        user_code: "SLOW-DOWN"
      )

    assert {:error, slow_down_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-too-early"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> DateTime.add(too_early.next_poll_allowed_at, -1, :second) end
               ]
             })

    assert slow_down_error.error == "slow_down"
    assert slow_down_error.reason_code == :device_authorization_slow_down

    {:ok, denied} =
      create_device_authorization(confidential_client,
        device_code: "device-code-denied",
        user_code: "DENI-ED01",
        transition: %{status: :denied, denied_at: DateTime.utc_now()}
      )

    assert {:error, denied_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-denied"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository
               ]
             })

    assert denied_error.error == "access_denied"
    assert denied_error.reason_code == :device_authorization_denied

    {:ok, _expired} =
      create_device_authorization(confidential_client,
        device_code: "device-code-expired",
        user_code: "EXPI-RED1",
        transition: %{status: :expired, expired_at: DateTime.utc_now()}
      )

    assert {:error, expired_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-expired"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository
               ]
             })

    assert expired_error.error == "expired_token"
    assert expired_error.reason_code == :device_authorization_expired

    assert {:error, invalid_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "unknown-device-code"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository
               ]
             })

    assert invalid_error.error == "invalid_grant"
    assert invalid_error.reason_code == :device_authorization_not_found

    refute pending.verification_handle == denied.verification_handle
  end

  test "maps approved-but-expired device authorizations to expired_token" do
    secret = "device-approved-expired-secret"

    {:ok, client} =
      create_client(
        "device-approved-expired-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    issued_at = DateTime.add(DateTime.utc_now(), -310, :second)

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-approved-expired",
        user_code: "EXPR-APPR",
        now: issued_at,
        transition: %{
          status: :approved,
          approved_at: issued_at,
          subject_id: "subject-123"
        }
      )

    assert {:error, expired_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-approved-expired"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert expired_error.error == "expired_token"
    assert expired_error.reason_code == :device_authorization_expired
  end

  test "redeems an approved device authorization through the shared token success pipeline" do
    secret = "device-success-secret"

    {:ok, client} =
      create_client(
        "device-success-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"],
        %{access_token_format: :opaque}
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-approved",
        user_code: "APPR-OVED",
        scopes: ["email", "profile"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-approved"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    # :opaque opt-in: the signer mints the opaque token (the legacy
    # access_token_generator seam no longer drives access-token minting), so the
    # issued token is a non-empty binary that is not a JOSE at+jwt.
    assert is_binary(success.access_token)
    refute opaque_token_is_at_jwt?(success.access_token)
    assert success.token_type == "Bearer"
    assert success.scope == "email profile"
    assert success.refresh_token == nil
    assert success.id_token == nil

    assert {:ok, %DeviceAuthorization{status: :consumed}} =
             Repository.fetch_device_authorization_by_device_code_hash(
               TokenFormatter.hash_token("device-code-approved")
             )
  end

  test "redeems an approved DPoP device authorization with token_type DPoP and persisted cnf" do
    secret = "device-dpop-secret"

    {:ok, client} =
      create_client(
        "device-dpop-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
        %{
          allowed_scopes: ["email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-dpop-approved",
        user_code: "DP0P-000",
        scopes: ["email", "profile", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    %{jwt: proof_jwt, validated: validated_proof} = dpop_proof_fixture()

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-dpop-approved"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_jwt,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "device-dpop-access-token" end,
                 refresh_token_generator: fn -> "device-dpop-refresh-token" end
               ]
             })

    assert success.token_type == "DPoP"

    assert {:ok, %Token{} = persisted_refresh_token} =
             Repository.fetch_refresh_token(
               TokenFormatter.hash_token("device-dpop-refresh-token")
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

  test "returns use_dpop_nonce for device-code exchange before succeeding with the supplied nonce" do
    secret = "device-nonce-secret"

    {:ok, client} =
      create_client(
        "device-dpop-nonce-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
        %{
          allowed_scopes: ["email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-dpop-nonce",
        user_code: "DPOP-NNC",
        scopes: ["email", "profile", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    %{jwt: proof_without_nonce} = dpop_proof_fixture(nonce: nil)

    assert {:error, error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-dpop-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_without_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository
               ]
             })

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :missing_dpop_nonce
    assert is_binary(error.dpop_nonce)

    %{jwt: proof_with_nonce, validated: validated_proof} = dpop_proof_fixture(error.dpop_nonce)

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-dpop-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_with_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "device-nonce-access-token" end,
                 refresh_token_generator: fn -> "device-nonce-refresh-token" end
               ]
             })

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

  test "returns use_dpop_nonce for ciba exchange before succeeding with the supplied nonce" do
    secret = "ciba-nonce-secret"

    {:ok, client} =
      create_client(
        "client-ciba-nonce",
        :client_secret_basic,
        secret,
        ["urn:openid:params:grant-type:ciba", "refresh_token"],
        %{
          allowed_scopes: ["openid", "email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    {:ok, _authorization} =
      create_ciba_authorization(client,
        auth_req_id: "ciba-auth-req-nonce",
        scopes: ["email", "profile", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    %{jwt: proof_without_nonce} = dpop_proof_fixture(nonce: nil)

    assert {:error, error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "ciba-auth-req-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_without_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 ciba_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository
               ]
             })

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :missing_dpop_nonce
    assert is_binary(error.dpop_nonce)

    %{jwt: proof_with_nonce, validated: validated_proof} = dpop_proof_fixture(error.dpop_nonce)

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "ciba-auth-req-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_with_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 ciba_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "ciba-nonce-access-token" end,
                 refresh_token_generator: fn -> "ciba-nonce-refresh-token" end
               ]
             })

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

  test "preserves bearer token_type for approved bearer-mode device authorization" do
    secret = "device-bearer-secret"
    publish_signing_key("kid-device-bearer")

    {:ok, client} =
      create_client(
        "device-bearer-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-bearer-approved",
        user_code: "BEAR-000",
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-bearer-approved"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 access_token_generator: fn -> "device-bearer-access-token" end
               ]
             })

    assert success.token_type == "Bearer"
  end

  test "device grants redeem once, collapse replay to invalid_grant, and append durable device audit rows" do
    secret = "device-replay-secret"
    publish_signing_key("kid-device-replay")

    {:ok, client} =
      create_client(
        "device-replay-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, authorization} =
      create_device_authorization(client,
        device_code: "device-code-replay",
        user_code: "REPL-AY01",
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    request = %{
      params: %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "device-code-replay"
      },
      authorization: basic_auth(client.client_id, secret),
      opts: [
        client_store: Repository,
        token_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        device_authorization_store: Repository,
        access_token_generator: fn -> "device-replay-access-token" end
      ]
    }

    assert {:ok, _success} = TokenExchange.exchange(request)
    assert {:error, replay_error} = TokenExchange.exchange(request)
    assert replay_error.error == "invalid_grant"
    assert replay_error.reason_code == :device_authorization_consumed

    audits =
      Lockspire.TestRepo.all(AuditEventRecord)
      |> Enum.filter(&(&1.actor_id == client.client_id))

    assert Enum.any?(audits, fn audit ->
             audit.action == "device_authorization_redeemed" and
               audit.resource_type == "device_authorization" and
               audit.resource_id == Integer.to_string(authorization.id) and
               audit.reason_code == "device_authorization_redeemed"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "device_authorization_replay_detected" and
               audit.resource_type == "device_authorization" and
               audit.resource_id == Integer.to_string(authorization.id) and
               audit.reason_code == "device_authorization_consumed"
           end)
  end

  test "device grants preserve shared refresh and id_token policy while collapsing client mismatch to invalid_grant" do
    publish_signing_key("kid-device-openid")

    refresh_secret = "device-openid-secret"

    {:ok, refresh_client} =
      create_client(
        "device-openid-client",
        :client_secret_basic,
        refresh_secret,
        ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"]
      )

    {:ok, _approved_openid} =
      create_device_authorization(refresh_client,
        device_code: "device-code-openid",
        user_code: "OPEN-ID01",
        scopes: ["openid", "email", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, refresh_success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-openid"
               },
               authorization: basic_auth(refresh_client.client_id, refresh_secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 access_token_generator: fn -> "device-openid-access-token" end,
                 refresh_token_generator: fn -> "device-openid-refresh-token" end
               ]
             })

    assert refresh_success.refresh_token == "device-openid-refresh-token"
    assert is_binary(refresh_success.id_token)

    {:ok, no_refresh_client} =
      create_client(
        "device-no-refresh-client",
        :client_secret_basic,
        "device-no-refresh-secret",
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _approved_no_refresh} =
      create_device_authorization(no_refresh_client,
        device_code: "device-code-no-refresh",
        user_code: "NORE-FRSH",
        scopes: ["offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, no_refresh_success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-no-refresh"
               },
               authorization: basic_auth(no_refresh_client.client_id, "device-no-refresh-secret"),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    assert no_refresh_success.refresh_token == nil

    mismatch_secret = "device-mismatch-secret"

    {:ok, other_client} =
      create_client(
        "device-other-client",
        :client_secret_basic,
        mismatch_secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _mismatch_approved} =
      create_device_authorization(refresh_client,
        device_code: "device-code-mismatch",
        user_code: "MISM-ATCH",
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:error, mismatch_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-mismatch"
               },
               authorization: basic_auth(other_client.client_id, mismatch_secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    assert mismatch_error.error == "invalid_grant"
    assert mismatch_error.reason_code == :device_authorization_client_mismatch
  end

  defp exchange(params, opts \\ []) do
    exchange_with_store(params, Repository, opts)
  end

  defp exchange_with_store(params, token_store, opts) do
    TokenExchange.exchange_authorization_code(%{
      params: params,
      authorization: Keyword.get(opts, :authorization),
      dpop: Keyword.get(opts, :dpop),
      method: Keyword.get(opts, :method, "POST"),
      opts: [
        client_store: Repository,
        token_store: token_store,
        interaction_store: Repository,
        key_store: Repository,
        server_policy_store: Keyword.get(opts, :server_policy_store, Repository),
        dpop_replay_store: Keyword.get(opts, :dpop_replay_store),
        now: Keyword.get(opts, :now, fn -> DateTime.utc_now() end),
        access_token_generator:
          Keyword.get(opts, :access_token_generator, fn -> "opaque-access-token-123" end),
        refresh_token_generator:
          Keyword.get(opts, :refresh_token_generator, fn -> "opaque-refresh-token-123" end)
      ]
    })
  end

  defp create_client(
         client_id,
         auth_method,
         client_secret,
         allowed_grant_types \\ ["authorization_code"],
         attrs \\ %{}
       ) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: client_secret_hash(client_secret),
      client_type: Map.get(attrs, :client_type, :confidential),
      name: Map.get(attrs, :name, "Client #{client_id}"),
      redirect_uris: Map.get(attrs, :redirect_uris, ["https://client.example.com/callback"]),
      allowed_scopes: Map.get(attrs, :allowed_scopes, ["email", "profile", "openid"]),
      allowed_grant_types: allowed_grant_types,
      allowed_response_types: Map.get(attrs, :allowed_response_types, ["code"]),
      token_endpoint_auth_method: auth_method,
      pkce_required: Map.get(attrs, :pkce_required, true),
      dpop_policy: Map.get(attrs, :dpop_policy, :inherit),
      access_token_format: Map.get(attrs, :access_token_format),
      subject_type: Map.get(attrs, :subject_type, :public),
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp create_public_client(client_id, allowed_grant_types) do
    {:ok, client} =
      create_client(
        client_id,
        :none,
        "unused-public-secret",
        allowed_grant_types,
        %{
          client_type: :public,
          allowed_response_types: [],
          pkce_required: false,
          redirect_uris: [],
          name: "Public Client #{client_id}"
        }
      )

    client
  end

  defp create_authorization_code(client, opts) do
    verifier = Keyword.fetch!(opts, :code_verifier)
    raw_code = Keyword.fetch!(opts, :raw_code)
    now = DateTime.utc_now()
    interaction_id = "interaction-#{raw_code}"
    code_challenge_method = Keyword.get(opts, :code_challenge_method, :S256)
    code_challenge = code_challenge(verifier)

    {:ok, _interaction} =
      Repository.put_interaction(%Interaction{
        interaction_id: interaction_id,
        client_id: client.client_id,
        account_id: "subject-123",
        scopes_requested: Keyword.get(opts, :scopes, ["email", "profile"]),
        nonce: Keyword.get(opts, :nonce),
        auth_time: Keyword.get(opts, :auth_time),
        max_age: Keyword.get(opts, :max_age),
        auth_time_requested: Keyword.get(opts, :auth_time_requested, false),
        redirect_uri: "https://client.example.com/callback",
        return_to: "/authorize",
        state: "state-123",
        code_challenge: code_challenge,
        code_challenge_method: code_challenge_method,
        status: :completed,
        completed_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: "subject-123",
      interaction_id: interaction_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: Keyword.get(opts, :scopes, ["email", "profile"]),
      audience: Keyword.get(opts, :audience, []),
      code_challenge: code_challenge,
      code_challenge_method: code_challenge_method,
      issued_at: now,
      expires_at: Keyword.get(opts, :expires_at, DateTime.add(now, 300, :second))
    })
  end

  defp dpop_proof_fixture(overrides \\ []) do
    keys = JarTestHelpers.generate_ec_keys()
    now = DateTime.utc_now()
    target_uri = "https://example.test/lockspire/token"
    overrides = if is_list(overrides), do: overrides, else: [nonce: overrides]

    nonce =
      Keyword.get_lazy(overrides, :nonce, fn -> DPoPNonce.issue(:authorization_server) end)

    claims =
      %{
        "htm" => "POST",
        "htu" => target_uri,
        "iat" => DateTime.to_unix(now),
        "jti" => Ecto.UUID.generate(),
        "nonce" => nonce
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    assert {:ok, %DPoP{} = validated} =
             DPoP.validate_proof(proof,
               method: "POST",
               target_uri: target_uri,
               now: now,
               max_age: 300,
               clock_skew: 30
             )

    %{jwt: proof, validated: validated}
  end

  defp create_device_authorization(client, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    authorization =
      DeviceAuthorization.issue(
        %{
          client_id: client.client_id,
          device_code: Keyword.fetch!(opts, :device_code),
          user_code: Keyword.fetch!(opts, :user_code),
          scopes: Keyword.get(opts, :scopes, ["email", "profile"])
        },
        now: now
      )

    with {:ok, stored} <- Repository.put_device_authorization(authorization) do
      case Keyword.get(opts, :transition) do
        nil ->
          {:ok, stored}

        attrs ->
          Repository.transition_device_authorization(
            stored.verification_handle,
            [stored.status],
            attrs
          )
      end
    end
  end

  defp create_ciba_authorization(client, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    authorization =
      Lockspire.Domain.CibaAuthorization.issue(
        %{
          auth_req_id: Keyword.fetch!(opts, :auth_req_id),
          client_id: client.client_id,
          scopes: Keyword.get(opts, :scopes, ["openid", "email", "profile"])
        },
        now: now
      )

    with {:ok, stored} <- Repository.put_ciba_authorization(authorization) do
      case Keyword.get(opts, :transition) do
        nil ->
          {:ok, stored}

        attrs ->
          Repository.transition_ciba_authorization(
            stored.auth_req_id_hash,
            [stored.status],
            attrs
          )
      end
    end
  end

  defp update_client_dpop_policy!(client_id, policy) do
    from(client in Lockspire.Storage.Ecto.ClientRecord, where: client.client_id == ^client_id)
    |> Lockspire.TestRepo.update_all(set: [dpop_policy: policy])

    :ok
  end

  defp publish_signing_key(kid) do
    jwk = JOSE.JWK.generate_key({:rsa, 2048}) |> JOSE.JWK.to_map() |> elem(1)

    Repository.publish_key(%SigningKey{
      kid: kid,
      kty: :RSA,
      alg: "RS256",
      use: :sig,
      public_jwk:
        Map.take(jwk, ["kty", "kid", "alg", "use", "n", "e"])
        |> Map.put("kid", kid)
        |> Map.put("alg", "RS256")
        |> Map.put("use", "sig"),
      private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
      status: :active,
      published_at: DateTime.utc_now(),
      activated_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  # Decodes + JOSE-verifies an at+jwt access token against the active signing key,
  # returning {header_map, claims_map}. Asserts the signature is valid.
  defp verify_at_jwt(access_token) do
    {:ok, %{public_jwk: public_jwk}} = Repository.fetch_active_signing_key()
    jwk = JOSE.JWK.from_map(public_jwk)

    assert {true, %JOSE.JWT{fields: claims}, _jws} = JOSE.JWT.verify_strict(jwk, ["RS256"], access_token)

    header = decode_jwt_section(access_token, 0)
    {header, claims}
  end

  # True only when the token parses as a JWT whose header advertises typ "at+jwt".
  defp opaque_token_is_at_jwt?(token) do
    case decode_jwt_section(token, 0) do
      %{"typ" => "at+jwt"} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end

  defp basic_auth_form_encoded(client_id, client_secret) do
    encoded_client_id = URI.encode_www_form(client_id)
    encoded_client_secret = URI.encode_www_form(client_secret)
    "Basic " <> Base.encode64("#{encoded_client_id}:#{encoded_client_secret}")
  end

  defp client_secret_hash(secret) do
    salt = "static-salt"
    hash = :crypto.hash(:sha256, salt <> secret) |> Base.encode64()
    "sha256:#{salt}:#{hash}"
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  defp at_hash(access_token) do
    <<left::binary-size(16), _rest::binary>> = :crypto.hash(:sha256, access_token)
    Base.url_encode64(left, padding: false)
  end

  defp decode_jwt_section(jwt, index) do
    jwt
    |> String.split(".")
    |> Enum.at(index)
    |> Base.url_decode64!(padding: false)
    |> Jason.decode!()
  end

  defp recorded_event_names(agent) do
    Agent.get(agent, fn events -> Enum.map(events, fn {event, _metadata} -> event end) end)
  end

  defp recorded_events(agent) do
    agent
    |> Agent.get(&Enum.reverse(&1))
    |> Enum.map(fn {event, metadata} -> {event, Map.take(metadata, [:reason_code])} end)
  end

  defmodule PlainMethodTokenStore do
    def use_token(%Token{} = token), do: Process.put({__MODULE__, :token}, token)

    def fetch_authorization_code(_token_hash), do: {:ok, Process.get({__MODULE__, :token})}
  end
end
