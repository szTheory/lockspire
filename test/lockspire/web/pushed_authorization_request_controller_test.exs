defmodule Lockspire.Web.PushedAuthorizationRequestControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query
  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "openid"])

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "par-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "PAR Public Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{public_client: public_client}
  end

  test "POST /par returns 201 with request_uri and expires_in for valid requests", %{
    public_client: public_client
  } do
    conn =
      build_conn(:post, "/par", valid_params(public_client.client_id))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 201
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert Map.keys(body) |> Enum.sort() == ["expires_in", "request_uri"]
    assert body["expires_in"] == 300
    assert body["request_uri"] =~ "urn:ietf:params:oauth:request_uri:"

    persisted =
      Lockspire.TestRepo.one!(
        from(request in PushedAuthorizationRequestRecord,
          where: request.client_id == ^public_client.client_id
        )
      )

    assert persisted.request_uri_hash == Policy.hash_token(body["request_uri"])
  end

  test "POST /par returns invalid_client with WWW-Authenticate on basic auth failures" do
    secret = "controller-par-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "par-confidential",
        client_secret_hash: Policy.hash_client_secret(secret),
        client_type: :confidential,
        name: "PAR Confidential Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    conn =
      build_conn(:post, "/par", Map.delete(valid_params(client.client_id), "client_id"))
      |> put_req_header("authorization", basic_auth(client.client_id, "wrong-secret"))
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    assert get_resp_header(conn, "www-authenticate") == [
             "Basic realm=\"Lockspire Pushed Authorization Request Endpoint\""
           ]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_client",
             "error_description" => "Client authentication failed"
           }
  end

  test "POST /par returns oauth error json for invalid request_uri submissions", %{
    public_client: public_client
  } do
    before_count = count_pushed_requests()

    conn =
      build_conn(
        :post,
        "/par",
        valid_params(public_client.client_id)
        |> Map.put("request_uri", "urn:ietf:params:oauth:request_uri:attacker")
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_request",
             "error_description" => "request_uri is not supported"
           }

    assert count_pushed_requests() == before_count
  end

  test "POST /par returns oauth error json for missing pkce submissions", %{
    public_client: public_client
  } do
    before_count = count_pushed_requests()

    conn =
      build_conn(
        :post,
        "/par",
        Map.delete(valid_params(public_client.client_id), "code_challenge")
      )
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_request",
             "error_description" => "PKCE S256 is required"
           }

    assert count_pushed_requests() == before_count
  end

  defp valid_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "profile email",
      "state" => "state-123",
      "prompt" => "login consent",
      "code_challenge" => String.duplicate("a", 43),
      "code_challenge_method" => "S256"
    }
  end

  defp count_pushed_requests do
    Lockspire.TestRepo.aggregate(PushedAuthorizationRequestRecord, :count, :id)
  end

  defp basic_auth(client_id, secret) do
    "Basic " <> Base.encode64("#{URI.encode_www_form(client_id)}:#{URI.encode_www_form(secret)}")
  end
end
