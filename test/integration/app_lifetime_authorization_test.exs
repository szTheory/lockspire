defmodule Lockspire.Integration.AppLifetimeAuthorizationTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.PushedAuthorizationRequest, as: Par
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord

  defmodule HostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context) do
      send(Process.get(:app_lifetime_test_owner), :host_account_resolved)
      {:ok, %{id: "app-lifetime-user"}}
    end

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context),
      do: {:ok, %Lockspire.Host.Claims{subject: to_string(account.id)}}

    @impl true
    def redirect_for_login(_conn_or_socket, context) do
      send(Process.get(:app_lifetime_test_owner), :host_login_redirected)

      %Lockspire.Host.InteractionResult{
        login_path: "/login",
        return_to: Map.get(context, :return_to),
        params: %{}
      }
    end
  end

  defmodule LockProbeJwksFetcher do
    def get_keys(_uri, opts) do
      owner = Keyword.fetch!(opts, :owner)
      client_id = Keyword.fetch!(opts, :client_id)
      key_set = Keyword.fetch!(opts, :key_set)

      probe =
        Task.async(fn ->
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

          result =
            try do
              Ecto.Adapters.SQL.query!(
                Lockspire.TestRepo,
                "SELECT id FROM lockspire_clients WHERE id = $1 FOR UPDATE NOWAIT",
                [client_id]
              )

              :lock_available
            rescue
              error -> {:lock_unavailable, error.__struct__}
            after
              Ecto.Adapters.SQL.Sandbox.checkin(Lockspire.TestRepo)
            end

          send(owner, {:client_lock_probe, result})
        end)

      Task.await(probe)
      {:ok, key_set}
    end

    def refresh_keys(uri, opts), do: get_keys(uri, opts)
  end

  defmodule InvalidLifetimeClientStore do
    def lifetime_contract, do: Repository.lifetime_contract()
    def lock_clients(ids), do: Repository.lock_clients(ids)

    def fetch_client_by_id(client_id) do
      case Repository.fetch_client_by_id(client_id) do
        {:ok, %Lockspire.Domain.Client{} = client} ->
          {:ok, %{client | lifetime_version: nil}}

        other ->
          other
      end
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://issuer.example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile"])
    Application.put_env(:lockspire, :account_resolver, HostResolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Process.put(:app_lifetime_test_owner, self())

    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 1,
        client_id: "app-lifetime-public-#{System.unique_integer([:positive])}",
        client_type: :public,
        name: "Lifetime test app",
        redirect_uris: ["https://client.example.test/callback"],
        allowed_scopes: ["openid", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "expired public app redirects only to its registered URI and never hands off to the host",
       %{
         client: client
       } do
    now = utc_second()
    expire_client!(client, now)

    conn =
      build_conn(:get, "/authorize", authorize_params(client, "safe-state"))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status in [302, 303]
    location = conn |> get_resp_header("location") |> List.first() |> URI.parse()
    params = URI.decode_query(location.query || "")
    assert location.host == "client.example.test"
    assert params["error"] == "access_denied"
    assert params["state"] == "safe-state"
    refute_received :host_account_resolved
    refute_received :host_login_redirected
    assert {:ok, []} = Repository.list_interactions()
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 0
  end

  test "an expired app with an unregistered redirect receives a local error", %{client: client} do
    now = utc_second()
    expire_client!(client, now)

    conn =
      build_conn(
        :get,
        "/authorize",
        authorize_params(client, "unsafe-state", "https://evil.test/")
      )
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    refute get_resp_header(conn, "location") |> Enum.any?()
    refute_received :host_account_resolved
    refute_received :host_login_redirected
    assert {:ok, []} = Repository.list_interactions()
  end

  test "expired private-key client is rejected at browser intake too", %{client: client} do
    {:ok, client} =
      Repository.update_client(client, %{token_endpoint_auth_method: :private_key_jwt})

    expire_client!(client, utc_second())

    assert {:redirect_error, %AuthorizationRequest.Error{} = error} =
             AuthorizationRequest.validate(authorize_params(client, "private-key-state"))

    assert error.error == "access_denied"
    assert error.state == "private-key-state"
    assert error.redirect_uri == "https://client.example.test/callback"
  end

  test "disabled apps are rejected before host work and invalid adapter state fails locally", %{
    client: client
  } do
    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "UPDATE lockspire_clients SET active = FALSE WHERE client_id = $1",
      [client.client_id]
    )

    assert {:redirect_error, %AuthorizationRequest.Error{error: "access_denied"}} =
             AuthorizationRequest.validate(authorize_params(client, "disabled-state"))

    assert {:browser_error,
            %AuthorizationRequest.Error{reason_code: :client_lifetime_state_invalid}} =
             AuthorizationRequest.validate(authorize_params(client, "bad-adapter-state"),
               client_store: InvalidLifetimeClientStore
             )

    refute_received :host_account_resolved
    refute_received :host_login_redirected
  end

  test "PAR creation rejects an app at deadline equality and leaves no request", %{client: client} do
    now = utc_second()
    expire_client!(client, now)

    assert {:error, %Par.Error{status: 401, reason_code: :client_app_expired}} =
             Par.push(%{
               params: authorize_params(client, "par-state"),
               opts: [now: now, request_uri_generator: fn -> "unused" end]
             })

    assert Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count) == 0
  end

  test "an accepted PAR is rejected at current app deadline equality on request_uri use", %{
    client: client
  } do
    now = utc_second()

    {:ok, %Par.Success{request_uri: request_uri}} =
      Par.push(%{
        params: authorize_params(client, "par-use-state"),
        opts: [now: now, request_uri_generator: fn -> "accepted" end]
      })

    deadline = now
    expire_client!(client, deadline)

    assert {:redirect_error, %AuthorizationRequest.Error{} = error} =
             AuthorizationRequest.validate(
               %{"client_id" => client.client_id, "request_uri" => request_uri},
               now: deadline
             )

    assert error.error == "access_denied"
    assert error.state == "par-use-state"
    assert {:ok, []} = Repository.list_interactions()
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 0
    assert {:ok, nil} = fetch_par(request_uri)

    assert {:browser_error, %AuthorizationRequest.Error{reason_code: :invalid_request_uri}} =
             AuthorizationRequest.validate(
               %{"client_id" => client.client_id, "request_uri" => request_uri},
               now: deadline
             )
  end

  test "approval at app deadline equality rolls back interaction, remembered consent, and code",
       %{
         client: client
       } do
    before_deadline = utc_second()
    deadline = DateTime.add(before_deadline, 60, :second)
    set_client_deadline!(client, deadline)

    assert {:ok, validated} =
             AuthorizationRequest.validate(authorize_params(client, "approve-state"))

    assert {:consent_required, interaction} =
             Lockspire.Protocol.AuthorizationFlow.start_authorization(
               validated,
               %{subject_id: "app-lifetime-user"},
               now: fn -> before_deadline end,
               interaction_id_generator: fn -> "app-lifetime-approval" end
             )

    expire_client!(client, before_deadline)

    assert {:denied, redirect_uri} =
             Lockspire.Protocol.AuthorizationFlow.approve_interaction(
               interaction.interaction_id,
               %{subject_id: "app-lifetime-user"},
               remember: true,
               now: fn -> before_deadline end
             )

    callback = URI.parse(redirect_uri)
    params = URI.decode_query(callback.query || "")
    assert params["error"] == "access_denied"
    assert params["state"] == "approve-state"
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 0
    assert {:ok, []} = Repository.list_consents()

    assert {:ok, [%Lockspire.Domain.Interaction{status: :pending_consent}]} =
             Repository.list_interactions()
  end

  test "resume and remembered-consent code paths recheck app state after ingress", %{
    client: client
  } do
    before_deadline = utc_second()
    deadline = DateTime.add(before_deadline, 60, :second)
    set_client_deadline!(client, deadline)

    assert {:ok, login_validated} =
             AuthorizationRequest.validate(authorize_params(client, "resume-state"),
               now: before_deadline
             )

    assert {:login_required, login_interaction} =
             Lockspire.Protocol.AuthorizationFlow.start_authorization(login_validated, nil,
               now: fn -> before_deadline end,
               interaction_id_generator: fn -> "app-lifetime-resume" end
             )

    expire_client!(client, before_deadline)

    assert {:consent_reused, resume_redirect} =
             Lockspire.Protocol.AuthorizationFlow.resume_interaction(
               login_interaction.interaction_id,
               %{subject_id: "app-lifetime-user"},
               now: fn -> before_deadline end
             )

    assert URI.decode_query(URI.parse(resume_redirect).query)["state"] == "resume-state"
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 0

    # A second, valid app with remembered consent reaches code persistence through
    # the silent-consent path; its decision clock expires only after both locks.
    {:ok, client} =
      Repository.register_client(%Client{
        lifetime_version: 1,
        client_id: "app-lifetime-remembered-#{System.unique_integer([:positive])}",
        client_type: :public,
        name: "Remembered lifetime app",
        redirect_uris: ["https://client.example.test/callback"],
        allowed_scopes: ["openid", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    remembered_before = utc_second()
    remembered_deadline = DateTime.add(remembered_before, 60, :second)
    set_client_deadline!(client, remembered_deadline)

    {:ok, _grant} =
      Repository.grant_consent(%Lockspire.Domain.ConsentGrant{
        account_id: "app-lifetime-user",
        client_id: client.client_id,
        scopes: ["openid", "profile"],
        granted_at: remembered_before,
        kind: :remembered
      })

    params = authorize_params(client, "remembered-state") |> Map.put("prompt", "none")
    assert {:ok, validated} = AuthorizationRequest.validate(params, now: remembered_before)
    {:ok, clock} = Agent.start_link(fn -> 0 end)

    decision_clock = fn ->
      Agent.get_and_update(clock, fn
        0 -> {remembered_before, 1}
        _ -> {remembered_deadline, 2}
      end)
    end

    assert {:consent_reused, remembered_redirect} =
             Lockspire.Protocol.AuthorizationFlow.start_authorization(
               validated,
               %{subject_id: "app-lifetime-user"},
               now: decision_clock,
               interaction_id_generator: fn -> "app-lifetime-remembered" end
             )

    assert URI.decode_query(URI.parse(remembered_redirect).query)["error"] == "access_denied"
    assert URI.decode_query(URI.parse(remembered_redirect).query)["state"] == "remembered-state"
    assert Lockspire.TestRepo.aggregate(TokenRecord, :count) == 0
  end

  test "remote JARM key resolution runs after the client lock is released", %{client: client} do
    _signing_key = publish_signing_key("app-lifetime-jarm-kid")
    encryption_key = JOSE.JWK.generate_key({:rsa, 2048})

    {:ok, client} =
      Repository.update_client(client, %{
        authorization_signed_response_alg: :RS256,
        authorization_encrypted_response_alg: :RSA_OAEP_256,
        authorization_encrypted_response_enc: :A256GCM,
        jwks_uri: "https://client.example.test/jwks.json"
      })

    params = authorize_params(client, "jarm-state") |> Map.put("response_mode", "query.jwt")
    assert {:ok, validated} = AuthorizationRequest.validate(params)

    assert {:consent_required, interaction} =
             Lockspire.Protocol.AuthorizationFlow.start_authorization(
               validated,
               %{subject_id: "app-lifetime-user"},
               interaction_id_generator: fn -> "app-lifetime-jarm" end
             )

    {_kty, jwk_map} = JOSE.JWK.to_public_map(encryption_key)
    jwk_map = jwk_map |> Map.put("kid", "app-lifetime-enc") |> Map.put("use", "enc")
    key_set = JOSE.JWK.from_map(%{"keys" => [jwk_map]})

    assert {:approved, redirect_uri} =
             Lockspire.Protocol.AuthorizationFlow.approve_interaction(
               interaction.interaction_id,
               %{subject_id: "app-lifetime-user"},
               key_store: Repository,
               jwks_fetcher: LockProbeJwksFetcher,
               jwks_fetcher_opts: [owner: self(), client_id: client.id, key_set: key_set]
             )

    assert_received {:client_lock_probe, :lock_available}
    assert URI.parse(redirect_uri).host == "client.example.test"
  end

  defp authorize_params(client, state, redirect_uri \\ "https://client.example.test/callback") do
    %{
      "client_id" => client.client_id,
      "response_type" => "code",
      "redirect_uri" => redirect_uri,
      "scope" => "openid profile",
      "state" => state,
      "nonce" => "lifetime-nonce",
      "code_challenge" =>
        Base.url_encode64(:crypto.hash(:sha256, "lifetime-verifier"), padding: false),
      "code_challenge_method" => "S256"
    }
  end

  defp expire_client!(client, now) do
    set_client_deadline!(client, now)
  end

  defp set_client_deadline!(client, deadline) do
    Ecto.Adapters.SQL.query!(
      Lockspire.TestRepo,
      "UPDATE lockspire_clients SET client_expires_at = $1 WHERE client_id = $2",
      [deadline, client.client_id]
    )

    :ok
  end

  defp fetch_par(request_uri) do
    request_uri_hash = Lockspire.Security.Policy.hash_token(request_uri)
    Repository.fetch_active_pushed_authorization_request(request_uri_hash)
  end

  defp utc_second, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%Lockspire.Domain.SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk: jwk |> Map.take(["kty", "kid", "alg", "use", "n", "e"]),
        private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    key
  end
end
