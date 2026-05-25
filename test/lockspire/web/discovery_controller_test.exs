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

  alias Lockspire.Clients
  alias Lockspire.Protocol.Discovery.AuthorizationResponseCapabilities
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Storage.Ecto.Repository

  @shared_methods [
    "none",
    "client_secret_basic",
    "client_secret_post",
    "client_secret_jwt",
    "private_key_jwt",
    "tls_client_auth",
    "self_signed_tls_client_auth"
  ]
  @introspection_methods ["client_secret_basic", "client_secret_post", "private_key_jwt"]

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

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

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

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

    assert body["response_modes_supported"] == [
             "query",
             "fragment",
             "form_post",
             "jwt",
             "query.jwt",
             "fragment.jwt",
             "form_post.jwt"
           ]

    assert body["grant_types_supported"] == [
             "authorization_code",
             "refresh_token",
             "urn:ietf:params:oauth:grant-type:device_code",
             "urn:openid:params:grant-type:ciba"
           ]

    assert body["device_authorization_endpoint"] == "https://example.test/lockspire/device/code"
    assert body["end_session_endpoint"] == "https://example.test/lockspire/end_session"
    assert body["backchannel_logout_supported"] == true
    assert body["backchannel_logout_session_supported"] == true
    assert body["frontchannel_logout_supported"] == true
    assert body["frontchannel_logout_session_supported"] == true

    assert body["token_endpoint_auth_methods_supported"] == @shared_methods

    assert body["token_endpoint_auth_signing_alg_values_supported"] == [
             "HS256",
             "RS256",
             "ES256",
             "PS256",
             "EdDSA"
           ]

    assert body["revocation_endpoint_auth_methods_supported"] == @shared_methods

    assert body["revocation_endpoint_auth_signing_alg_values_supported"] == [
             "HS256",
             "RS256",
             "ES256",
             "PS256",
             "EdDSA"
           ]

    refute Map.has_key?(body, "pushed_authorization_request_endpoint_auth_methods_supported")

    refute Map.has_key?(
             body,
             "pushed_authorization_request_endpoint_auth_signing_alg_values_supported"
           )

    assert body["introspection_endpoint_auth_methods_supported"] == @introspection_methods

    assert body["introspection_endpoint_auth_signing_alg_values_supported"] == [
             "RS256",
             "ES256",
             "PS256",
             "EdDSA"
           ]

    assert body["code_challenge_methods_supported"] == ["S256"]
    assert body["subject_types_supported"] == ["public"]
    assert body["id_token_signing_alg_values_supported"] == ["RS256", "ES256", "PS256", "EdDSA"]

    assert body["authorization_signing_alg_values_supported"] == [
             "RS256",
             "ES256",
             "PS256",
             "EdDSA"
           ]

    assert body["authorization_encryption_alg_values_supported"] == [
             "RSA-OAEP-256",
             "ECDH-ES"
           ]

    assert body["authorization_encryption_enc_values_supported"] == [
             "A256GCM",
             "A128GCM"
           ]

    assert Map.take(
             body,
             [
               "response_modes_supported",
               "authorization_signing_alg_values_supported",
               "authorization_encryption_alg_values_supported",
               "authorization_encryption_enc_values_supported"
             ]
           ) ==
             AuthorizationResponseCapabilities.metadata(
               %{"authorization_endpoint" => body["authorization_endpoint"]},
               :none
             )

    refute Map.has_key?(body, "registration_endpoint")
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

  test "GET /.well-known/openid-configuration omits revocation and introspection auth metadata when those routes are unmounted" do
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

    assert body["token_endpoint_auth_methods_supported"] == @shared_methods

    assert body["token_endpoint_auth_signing_alg_values_supported"] == [
             "HS256",
             "RS256",
             "ES256",
             "PS256",
             "EdDSA"
           ]

    refute Map.has_key?(body, "revocation_endpoint_auth_methods_supported")
    refute Map.has_key?(body, "revocation_endpoint_auth_signing_alg_values_supported")
    refute Map.has_key?(body, "introspection_endpoint_auth_methods_supported")
    refute Map.has_key?(body, "introspection_endpoint_auth_signing_alg_values_supported")
    refute Map.has_key?(body, "pushed_authorization_request_endpoint_auth_methods_supported")

    refute Map.has_key?(
             body,
             "pushed_authorization_request_endpoint_auth_signing_alg_values_supported"
           )
  end

  test "GET /.well-known/openid-configuration drops JARM signing and encryption metadata when the authorization surface is unmounted" do
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

    assert body["response_modes_supported"] == ["query", "fragment", "form_post"]
    refute Map.has_key?(body, "authorization_signing_alg_values_supported")
    refute Map.has_key?(body, "authorization_encryption_alg_values_supported")
    refute Map.has_key?(body, "authorization_encryption_enc_values_supported")

    assert Map.take(
             body,
             [
               "response_modes_supported",
               "authorization_signing_alg_values_supported",
               "authorization_encryption_alg_values_supported",
               "authorization_encryption_enc_values_supported"
             ]
           ) == AuthorizationResponseCapabilities.metadata(%{}, :none)
  end

  test "GET /.well-known/openid-configuration publishes the FAPI signing posture through the shared authorization-response capability contract" do
    {:ok, policy} = Repository.get_server_policy()
    Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})

    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    body = Jason.decode!(conn.resp_body)

    assert body["authorization_signing_alg_values_supported"] == ["ES256", "PS256"]

    assert Map.take(
             body,
             [
               "response_modes_supported",
               "authorization_signing_alg_values_supported",
               "authorization_encryption_alg_values_supported",
               "authorization_encryption_enc_values_supported"
             ]
           ) ==
             AuthorizationResponseCapabilities.metadata(
               %{"authorization_endpoint" => body["authorization_endpoint"]},
               :fapi_2_0_security
             )
  end

  test "GET /.well-known/openid-configuration does not change JARM metadata when transient clients are registered" do
    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    before_registration =
      Jason.decode!(conn.resp_body)
      |> Map.take([
        "response_modes_supported",
        "authorization_signing_alg_values_supported",
        "authorization_encryption_alg_values_supported",
        "authorization_encryption_enc_values_supported"
      ])

    {:ok, %{client: client}} =
      Clients.register_client(%{
        name: "http discovery metadata truth fixture",
        client_type: :confidential,
        redirect_uris: ["https://client.example.com/cb"],
        allowed_scopes: ["profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic
      })

    {:ok, _updated_client} =
      Repository.update_client(client, %{
        authorization_signed_response_alg: :RS256,
        authorization_encrypted_response_alg: :RSA_OAEP_256,
        authorization_encrypted_response_enc: :A256GCM
      })

    conn =
      build_conn(:get, "/.well-known/openid-configuration")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    after_registration =
      Jason.decode!(conn.resp_body)
      |> Map.take([
        "response_modes_supported",
        "authorization_signing_alg_values_supported",
        "authorization_encryption_alg_values_supported",
        "authorization_encryption_enc_values_supported"
      ])

    assert after_registration == before_registration
  end
end
