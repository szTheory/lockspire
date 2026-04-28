defmodule Lockspire.Web.DiscoveryControllerTest.TokenAndUserinfoController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
  def show(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.Web.DiscoveryControllerTest.TokenOnlyController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.Web.DiscoveryControllerTest.TokenAndUserinfoRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.Web.DiscoveryControllerTest.TokenAndUserinfoController, :create)
    get("/userinfo", Lockspire.Web.DiscoveryControllerTest.TokenAndUserinfoController, :show)
  end
end

defmodule Lockspire.Web.DiscoveryControllerTest.TokenOnlyRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.Web.DiscoveryControllerTest.TokenOnlyController, :create)
  end
end

defmodule Lockspire.Web.DiscoveryControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest, only: [build_conn: 2]
  import Plug.Conn

  alias Lockspire.Protocol.DPoP

  setup do
    original_env =
      for key <- [:issuer, :mount_path, :known_scopes, :discovery_router], into: %{} do
        {key, Application.get_env(:lockspire, key)}
      end

    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "profile"])

    on_exit(fn ->
      Enum.each(original_env, fn {key, value} ->
        if is_nil(value) do
          Application.delete_env(:lockspire, key)
        else
          Application.put_env(:lockspire, key, value)
        end
      end)
    end)

    :ok
  end

  test "GET /.well-known/openid-configuration publishes truthful mounted metadata" do
    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["public, max-age=300"]

    body = Jason.decode!(conn.resp_body)

    assert body["issuer"] == "https://example.test/lockspire"
    assert body["authorization_endpoint"] == "https://example.test/lockspire/authorize"
    assert body["token_endpoint"] == "https://example.test/lockspire/token"
    assert body["userinfo_endpoint"] == "https://example.test/lockspire/userinfo"
    assert body["jwks_uri"] == "https://example.test/lockspire/jwks"
    assert body["revocation_endpoint"] == "https://example.test/lockspire/revoke"
    assert body["introspection_endpoint"] == "https://example.test/lockspire/introspect"
    assert body["pushed_authorization_request_endpoint"] == "https://example.test/lockspire/par"
    assert body["scopes_supported"] == ["openid", "profile", "email"]
    assert body["response_types_supported"] == ["code"]
    assert body["response_modes_supported"] == ["query"]
    assert body["grant_types_supported"] == [
             "authorization_code",
             "refresh_token",
             "urn:ietf:params:oauth:grant-type:device_code"
           ]
    assert body["device_authorization_endpoint"] == "https://example.test/lockspire/device/code"

    assert body["token_endpoint_auth_methods_supported"] == [
             "none",
             "client_secret_basic",
             "client_secret_post"
           ]

    assert body["code_challenge_methods_supported"] == ["S256"]
    assert body["subject_types_supported"] == ["public"]
    assert body["id_token_signing_alg_values_supported"] == ["RS256"]

    refute Map.has_key?(body, "registration_endpoint")
    refute Map.has_key?(body, "end_session_endpoint")
    refute Map.has_key?(body, "request_parameter_supported")
    refute Map.has_key?(body, "request_uri_parameter_supported")
    refute Map.has_key?(body, "request_object_signing_alg_values_supported")
    refute Map.has_key?(body, "request_object_encryption_alg_values_supported")
    refute Map.has_key?(body, "request_object_encryption_enc_values_supported")
    refute Map.has_key?(body, "require_pushed_authorization_requests")
  end

  test "GET /.well-known/openid-configuration publishes dpop metadata only when /token and /userinfo are both mounted" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.Web.DiscoveryControllerTest.TokenAndUserinfoRouter
    )

    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    body = Jason.decode!(conn.resp_body)

    assert body["dpop_signing_alg_values_supported"] == DPoP.signing_alg_values_supported()

    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.Web.DiscoveryControllerTest.TokenOnlyRouter
    )

    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    body = Jason.decode!(conn.resp_body)

    refute Map.has_key?(body, "dpop_signing_alg_values_supported")
  end
end
