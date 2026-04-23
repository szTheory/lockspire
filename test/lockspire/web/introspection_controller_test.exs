defmodule Lockspire.Web.IntrospectionControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    secret = "introspection-controller-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-controller",
        client_secret_hash: client_secret_hash(secret),
        client_type: :confidential,
        name: "Introspection Controller Client",
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

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-controller-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public Introspection Controller Client",
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

    {:ok, other_client} =
      Repository.register_client(%Client{
        client_id: "client-introspection-controller-other",
        client_secret_hash: client_secret_hash("other-introspection-controller-secret"),
        client_type: :confidential,
        name: "Other Introspection Controller Client",
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

    {:ok, _access_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-access"),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-controller-introspection",
        interaction_id: "interaction-controller-introspection",
        scopes: ["email"],
        audience: ["api.example.com"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    {:ok, _expired_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("controller-introspect-expired"),
        token_type: :refresh_token,
        family_id: "controller-introspect-family",
        generation: 0,
        client_id: client.client_id,
        account_id: "subject-controller-introspection",
        interaction_id: "interaction-controller-introspection-expired",
        scopes: ["email", "offline_access"],
        issued_at: DateTime.add(now, -7200, :second),
        expires_at: DateTime.add(now, -3600, :second)
      })

    %{client: client, secret: secret, public_client: public_client, other_client: other_client}
  end

  test "POST /introspect returns active token metadata for authorized callers", %{
    client: client,
    secret: secret
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert body["active"] == true
    assert body["client_id"] == client.client_id
    assert body["token_type"] == "access_token"
    assert body["sub"] == "subject-controller-introspection"
  end

  test "POST /introspect collapses unauthorized public callers to active false", %{
    public_client: client
  } do
    conn =
      build_conn(:post, "/introspect", %{
        "token" => "controller-introspect-access",
        "client_id" => client.client_id
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"active" => false}
  end

  test "POST /introspect collapses client mismatch to active false", %{other_client: client} do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-access"})
      |> put_req_header(
        "authorization",
        basic_auth(client.client_id, "other-introspection-controller-secret")
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"active" => false}
  end

  test "POST /introspect collapses expired tokens to active false", %{
    client: client,
    secret: secret
  } do
    conn =
      build_conn(:post, "/introspect", %{"token" => "controller-introspect-expired"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"active" => false}
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end
end
