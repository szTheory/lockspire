defmodule Lockspire.Integration.AppLifetimeOnlineConsumersTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn
  import Plug.Test

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Protocol.Userinfo
  alias Lockspire.AccessToken
  alias Lockspire.KeyCache
  alias Lockspire.Plug.VerifyToken
  alias Lockspire.Storage.Ecto.Repository

  defmodule LifetimeStore do
    def lifetime_contract do
      %{version: 1, transaction_authority: transaction_authority()}
    end

    def transaction_authority do
      %{identity: :online_consumer_test, participants: %{client_store: __MODULE__}}
    end

    def lock_clients(_client_ids), do: {:ok, []}

    def fetch_client_by_id(client_id) do
      Process.put(
        :online_consumer_client_reads,
        Process.get(:online_consumer_client_reads, []) ++ [client_id]
      )

      case Process.get(:online_consumer_clients, %{}) |> Map.get(client_id) do
        [%Client{} = client | rest] ->
          Process.put(
            :online_consumer_clients,
            Map.put(Process.get(:online_consumer_clients), client_id, rest)
          )

          {:ok, client}

        %Client{} = client ->
          {:ok, client}

        nil ->
          {:ok, nil}
      end
    end
  end

  defmodule TestResolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    @impl true
    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "online-subject"}}

    @impl true
    def resolve_account(id, _context) do
      Process.put(:online_consumer_host_calls, Process.get(:online_consumer_host_calls, 0) + 1)
      {:ok, %{id: id}}
    end

    @impl true
    def build_claims(account, _context) do
      Process.put(:online_consumer_host_calls, Process.get(:online_consumer_host_calls, 0) + 1)
      {:ok, %Claims{subject: account.id, userinfo: %{"email" => "#{account.id}@example.test"}}}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context),
      do: %InteractionResult{login_path: "/sign-in", return_to: "/authorize", params: %{}}
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    previous_resolver = Application.get_env(:lockspire, :account_resolver)
    Application.put_env(:lockspire, :account_resolver, TestResolver)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    on_exit(fn ->
      if previous_resolver,
        do: Application.put_env(:lockspire, :account_resolver, previous_resolver),
        else: Application.delete_env(:lockspire, :account_resolver)
    end)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Process.put(:online_consumer_clients, %{})
    Process.put(:online_consumer_client_reads, [])
    Process.put(:online_consumer_host_calls, 0)
    :ok
  end

  test "UserInfo checks the custom current app before host callbacks" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expired = public_client("userinfo-expired", DateTime.add(now, -1, :second))
    Process.put(:online_consumer_clients, %{expired.client_id => expired})
    store_token("userinfo-expired-token", expired.client_id, now)

    assert {:error, %Userinfo.Error{status: 401, error: "invalid_token"}} =
             Userinfo.fetch_claims(%{
               authorization: "Bearer userinfo-expired-token",
               opts: online_opts(now)
             })

    assert Process.get(:online_consumer_client_reads) == [expired.client_id]
    assert Process.get(:online_consumer_host_calls) == 0
  end

  test "UserInfo uses its declared custom store for an eligible app" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    client = public_client("userinfo-live", DateTime.add(now, 60, :second))
    Process.put(:online_consumer_clients, %{client.client_id => client})
    store_token("userinfo-live-token", client.client_id, now)

    assert {:ok, %{"sub" => "online-subject", "email" => "online-subject@example.test"}} =
             Userinfo.fetch_claims(%{
               authorization: "Bearer userinfo-live-token",
               opts: online_opts(now)
             })

    assert Process.get(:online_consumer_client_reads) == [client.client_id]
    assert Process.get(:online_consumer_host_calls) == 2
  end

  test "the HTTP UserInfo challenge maps an expired issuing app to invalid_token" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, client} =
      Repository.register_client(%Client{
        active: true,
        lifetime_version: 1,
        client_expires_at: DateTime.add(now, -1, :second),
        client_id: "userinfo-http-expired",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_scopes: ["email"],
        created_at: now,
        metadata: %{}
      })

    store_token("userinfo-http-expired-token", client.client_id, now)

    conn =
      build_conn(:get, "/userinfo")
      |> Plug.Conn.put_req_header("authorization", "Bearer userinfo-http-expired-token")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401

    assert Plug.Conn.get_resp_header(conn, "www-authenticate") == [
             "Bearer realm=\"Lockspire Userinfo\", error=\"invalid_token\""
           ]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_token",
             "error_description" => "Access token is invalid"
           }

    assert Process.get(:online_consumer_host_calls) == 0
  end

  test "introspection returns only active false when an owned token issuer is currently expired" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    caller = confidential_client("introspection-owner", :active, now)
    expired = %Client{caller | client_expires_at: DateTime.add(now, -1, :second)}
    Process.put(:online_consumer_clients, %{caller.client_id => [caller, expired]})
    store_token("introspection-owned-token", caller.client_id, now)

    assert {:ok, %{payload: %{active: false}}} =
             Introspection.introspect(%{
               params: %{"token" => "introspection-owned-token"},
               authorization: basic_auth(caller.client_id, "test-secret"),
               opts: online_opts(now) ++ [token_store: Repository]
             })

    assert Process.get(:online_consumer_client_reads) == [caller.client_id, caller.client_id]
  end

  test "revocation rejects an expired caller and preserves success for an eligible unknown token" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expired = confidential_client("revocation-expired", DateTime.add(now, -1, :second), now)
    Process.put(:online_consumer_clients, %{expired.client_id => expired})

    assert {:error, %{status: 401, error: "invalid_client"}} =
             Revocation.revoke(%{
               params: %{"token" => "revocation-unknown-token"},
               authorization: basic_auth(expired.client_id, "test-secret"),
               opts: online_opts(now) ++ [token_store: Repository]
             })

    public_expired = public_client("revocation-public-expired", DateTime.add(now, -1, :second))
    Process.put(:online_consumer_clients, %{public_expired.client_id => public_expired})

    assert {:error, %{status: 401, error: "invalid_client"}} =
             Revocation.revoke(%{
               params: %{
                 "token" => "revocation-unknown-token",
                 "client_id" => public_expired.client_id
               },
               opts: online_opts(now) ++ [token_store: Repository]
             })

    eligible = confidential_client("revocation-live", :active, now)
    Process.put(:online_consumer_clients, %{eligible.client_id => eligible})

    assert :ok =
             Revocation.revoke(%{
               params: %{"token" => "unknown-token"},
               authorization: basic_auth(eligible.client_id, "test-secret"),
               opts: online_opts(now) ++ [token_store: Repository]
             })
  end

  test "provider discovery remains independent of client app lifetime" do
    signing_key = JOSE.JWK.generate_key({:rsa, 2048})
    kid = "public-jwks-#{System.unique_integer([:positive])}"
    public_jwk = signing_key |> JOSE.JWK.to_public() |> JOSE.JWK.to_map() |> elem(1)

    {:ok, _key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk: public_jwk,
        status: :active,
        inserted_at: DateTime.utc_now()
      })

    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["jwks_uri"] == "https://example.test/lockspire/jwks"

    jwks_conn =
      build_conn(:get, "/jwks")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert jwks_conn.status == 200
    assert Enum.any?(Jason.decode!(jwks_conn.resp_body)["keys"], &(&1["kid"] == kid))
  end

  test "offline JWT verification does not learn that its issuing app later expired" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    client_id = "offline-expired-app"

    {:ok, _client} =
      Repository.register_client(%Client{
        active: true,
        lifetime_version: 1,
        client_expires_at: DateTime.add(now, -60, :second),
        client_id: client_id,
        client_type: :public,
        redirect_uris: ["https://offline.example.test/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: now,
        metadata: %{}
      })

    signing_key = JOSE.JWK.generate_key({:rsa, 2048})
    kid = "offline-lifetime-#{System.unique_integer([:positive])}"
    public_key = JOSE.JWK.to_public(signing_key)
    :ets.insert(:lockspire_keys, {kid, public_key})
    on_exit(fn -> :ets.delete(:lockspire_keys, kid) end)

    claims = %{
      "client_id" => client_id,
      "iss" => "https://example.test/lockspire",
      "sub" => "offline-subject",
      "iat" => DateTime.to_unix(now) - 60,
      "nbf" => DateTime.to_unix(now) - 60,
      "exp" => DateTime.to_unix(now) + 3_600
    }

    {_, token} =
      JOSE.JWT.sign(signing_key, %{"alg" => "RS256", "kid" => kid, "typ" => "at+jwt"}, claims)
      |> JOSE.JWS.compact()

    conn =
      conn(:get, "/")
      |> put_req_header("authorization", "Bearer " <> token)
      |> VerifyToken.call(VerifyToken.init([]))

    assert %AccessToken{client_id: ^client_id, error: nil} = conn.assigns.access_token

    assert {:ok, %Client{client_expires_at: expires_at}} =
             Repository.fetch_client_by_id(client_id)

    assert DateTime.compare(expires_at, now) == :lt
    assert {:ok, _jwk} = KeyCache.get_key(kid)
  end

  defp online_opts(now) do
    [
      client_store: LifetimeStore,
      transaction_store: LifetimeStore,
      now: fn -> now end,
      server_policy_store: Repository
    ]
  end

  defp public_client(id, expires_at) do
    %Client{
      active: true,
      lifetime_version: 1,
      client_expires_at: expires_at,
      client_id: id,
      client_type: :public,
      token_endpoint_auth_method: :none,
      allowed_scopes: ["email", "profile"],
      security_profile: :none
    }
  end

  defp confidential_client(id, expiry, now) do
    %Client{
      public_client(id, if(expiry == :active, do: DateTime.add(now, 60, :second), else: expiry))
      | client_type: :confidential,
        token_endpoint_auth_method: :client_secret_basic,
        client_secret_hash: Lockspire.Security.Policy.hash_client_secret("test-secret")
    }
  end

  defp store_token(value, client_id, now) do
    {:ok, _token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(value),
        token_type: :access_token,
        client_id: client_id,
        account_id: "online-subject",
        interaction_id: "online-consumer-test",
        scopes: ["email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3_600, :second)
      })
  end

  defp basic_auth(id, secret), do: "Basic " <> Base.encode64("#{id}:#{secret}")
end
