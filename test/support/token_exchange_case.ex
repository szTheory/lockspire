defmodule Lockspire.TokenExchangeCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Lockspire.TestSupport.TelemetryCapture

  import Ecto.Query
  import ExUnit.Assertions

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
  alias Lockspire.Storage.Ecto.Repository

  using do
    quote do
      use Lockspire.DataCase, async: false

      import Ecto.Query
      import Lockspire.TokenExchangeCase

      alias Lockspire.Domain.DeviceAuthorization
      alias Lockspire.Domain.Token
      alias Lockspire.Protocol.TokenExchange
      alias Lockspire.Protocol.TokenFormatter
      alias Lockspire.Storage.Ecto.AuditEventRecord
      alias Lockspire.Storage.Ecto.Repository
      alias Lockspire.Storage.Ecto.TokenRecord
      alias Lockspire.TokenExchangeCase.PlainMethodTokenStore
    end
  end

  setup_all do
    unless Process.whereis(Lockspire.TestRepo) do
      start_supervised!(Lockspire.TestRepo)
    end

    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Lockspire.TokenExchangeCase.Resolver)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    events = start_supervised!({Agent, fn -> [] end})

    TelemetryCapture.attach_many_to_agent(
      [
        [:lockspire, :authorization_code, :redeemed],
        [:lockspire, :token, :issued],
        [:lockspire, :authorization_code, :replay_detected],
        [:lockspire, :token_exchange, :failed]
      ],
      events
    )

    %{events: events}
  end

  def exchange(params, opts \\ []) do
    exchange_with_store(params, Repository, opts)
  end

  def exchange_with_store(params, token_store, opts) do
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

  def create_client(
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

  def create_public_client(client_id, allowed_grant_types) do
    {:ok, client} =
      create_client(client_id, :none, "unused-public-secret", allowed_grant_types, %{
        client_type: :public,
        allowed_response_types: [],
        pkce_required: false,
        redirect_uris: [],
        name: "Public Client #{client_id}"
      })

    client
  end

  def create_authorization_code(client, opts) do
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

  def dpop_proof_fixture(overrides \\ []) do
    keys = JarTestHelpers.generate_ec_keys()
    now = DateTime.utc_now()
    target_uri = "https://example.test/lockspire/token"
    overrides = if is_list(overrides), do: overrides, else: [nonce: overrides]

    nonce = Keyword.get_lazy(overrides, :nonce, fn -> DPoPNonce.issue(:authorization_server) end)

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

  def create_device_authorization(client, opts) do
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

  def create_ciba_authorization(client, opts) do
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

  def update_client_dpop_policy!(client_id, policy) do
    from(client in Lockspire.Storage.Ecto.ClientRecord, where: client.client_id == ^client_id)
    |> Lockspire.TestRepo.update_all(set: [dpop_policy: policy])

    :ok
  end

  def publish_signing_key(kid) do
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

  def verify_at_jwt(access_token) do
    {:ok, %{public_jwk: public_jwk}} = Repository.fetch_active_signing_key()
    jwk = JOSE.JWK.from_map(public_jwk)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(jwk, ["RS256"], access_token)

    header = decode_jwt_section(access_token, 0)
    {header, claims}
  end

  def opaque_token_is_at_jwt?(token) do
    case decode_jwt_section(token, 0) do
      %{"typ" => "at+jwt"} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  def basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end

  def basic_auth_form_encoded(client_id, client_secret) do
    encoded_client_id = URI.encode_www_form(client_id)
    encoded_client_secret = URI.encode_www_form(client_secret)
    "Basic " <> Base.encode64("#{encoded_client_id}:#{encoded_client_secret}")
  end

  def client_secret_hash(secret) do
    salt = "static-salt"
    hash = :crypto.hash(:sha256, salt <> secret) |> Base.encode64()
    "sha256:#{salt}:#{hash}"
  end

  def code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  def at_hash(access_token) do
    <<left::binary-size(16), _rest::binary>> = :crypto.hash(:sha256, access_token)
    Base.url_encode64(left, padding: false)
  end

  def decode_jwt_section(jwt, index) do
    jwt
    |> String.split(".")
    |> Enum.at(index)
    |> Base.url_decode64!(padding: false)
    |> Jason.decode!()
  end

  def recorded_event_names(agent) do
    Agent.get(agent, fn events -> Enum.map(events, fn {event, _metadata} -> event end) end)
  end

  def recorded_events(agent) do
    agent
    |> Agent.get(&Enum.reverse(&1))
    |> Enum.map(fn {event, metadata} -> {event, Map.take(metadata, [:reason_code])} end)
  end

  defmodule Resolver do
    @moduledoc false

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
         userinfo: %{
           "email" => "#{account.id}@example.test",
           "name" => "Subject #{account.id}"
         }
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context) do
      %InteractionResult{login_path: "/sign-in", return_to: "/authorize", params: %{}}
    end
  end

  defmodule PlainMethodTokenStore do
    @moduledoc false

    def use_token(%Token{} = token), do: Process.put({__MODULE__, :token}, token)

    def fetch_authorization_code(_token_hash), do: {:ok, Process.get({__MODULE__, :token})}
  end
end
