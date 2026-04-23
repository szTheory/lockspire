defmodule Lockspire.Web.DiscoveryControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  setup do
    original_env =
      for key <- [:issuer, :mount_path, :known_scopes], into: %{} do
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
    assert body["scopes_supported"] == ["openid", "profile", "email"]
    assert body["response_types_supported"] == ["code"]
    assert body["response_modes_supported"] == ["query"]
    assert body["grant_types_supported"] == ["authorization_code", "refresh_token"]

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
    refute Map.has_key?(body, "pushed_authorization_request_endpoint")
    refute Map.has_key?(body, "request_object_signing_alg_values_supported")
  end
end
