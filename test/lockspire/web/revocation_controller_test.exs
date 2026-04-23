defmodule Lockspire.Web.RevocationControllerTest do
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

    secret = "revocation-controller-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-revocation-controller",
        client_secret_hash: client_secret_hash(secret),
        client_type: :confidential,
        name: "Revocation Controller Client",
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
        client_id: "client-revocation-controller-other",
        client_secret_hash: client_secret_hash("other-controller-secret"),
        client_type: :confidential,
        name: "Other Revocation Controller Client",
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
        token_hash: TokenFormatter.hash_token("controller-revoke-access"),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-controller-revoke",
        interaction_id: "interaction-controller-revoke",
        scopes: ["email"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    %{client: client, secret: secret, other_client: other_client}
  end

  test "POST /revoke returns success and revokes a token", %{client: client, secret: secret} do
    conn =
      build_conn(:post, "/revoke", %{"token" => "controller-revoke-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]
    assert Jason.decode!(conn.resp_body) == %{}

    assert {:ok, %Token{revoked_at: %DateTime{}}} =
             Repository.fetch_lifecycle_token(
               TokenFormatter.hash_token("controller-revoke-access")
             )
  end

  test "POST /revoke returns success for unknown tokens", %{client: client, secret: secret} do
    conn =
      build_conn(:post, "/revoke", %{"token" => "controller-revoke-unknown"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{}
  end

  test "POST /revoke returns success for client mismatch", %{other_client: client} do
    conn =
      build_conn(:post, "/revoke", %{"token" => "controller-revoke-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, "other-controller-secret"))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{}

    assert {:ok, %Token{revoked_at: nil}} =
             Repository.fetch_lifecycle_token(
               TokenFormatter.hash_token("controller-revoke-access")
             )
  end

  test "POST /revoke returns success for already revoked tokens", %{
    client: client,
    secret: secret
  } do
    first_conn =
      build_conn(:post, "/revoke", %{"token" => "controller-revoke-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert first_conn.status == 200

    second_conn =
      build_conn(:post, "/revoke", %{"token" => "controller-revoke-access"})
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert second_conn.status == 200
    assert Jason.decode!(second_conn.resp_body) == %{}
  end

  defp client_secret_hash(secret) do
    "sha256:static-salt:" <> Base.encode64(:crypto.hash(:sha256, "static-salt" <> secret))
  end

  defp basic_auth(client_id, client_secret) do
    "Basic " <> Base.encode64("#{client_id}:#{client_secret}")
  end
end
