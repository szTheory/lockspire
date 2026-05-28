defmodule Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
  def show(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.Protocol.DiscoveryTest.TokenOnlyController do
  use Phoenix.Controller, formats: [:json]

  def create(conn, _params), do: json(conn, %{})
end

defmodule Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoController, :create)
    get("/userinfo", Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoController, :show)
  end
end

defmodule Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter do
  use Phoenix.Router

  scope "/" do
    post("/token", Lockspire.Protocol.DiscoveryTest.TokenOnlyController, :create)
  end
end

defmodule Lockspire.Protocol.DiscoveryTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest, only: [build_conn: 3]
  import Plug.Conn

  alias Lockspire.Clients
  alias Lockspire.Protocol.Discovery
  alias Lockspire.Protocol.Discovery.AuthorizationResponseCapabilities
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Storage.Ecto.Repository

  @static_methods [
    "none",
    "client_secret_basic",
    "client_secret_post",
    "client_secret_jwt",
    "private_key_jwt",
    "tls_client_auth",
    "self_signed_tls_client_auth"
  ]
  @published_methods [
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
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    # We must start the repo if it's not already started.
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    original = Application.get_env(:lockspire, :issuer)
    original_router = Application.get_env(:lockspire, :discovery_router)
    original_rar_validators = Application.get_env(:lockspire, :rar_validators)
    original_rar_types_supported = Application.get_env(:lockspire, :rar_types_supported)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")

    on_exit(fn ->
      if is_nil(original) do
        Application.delete_env(:lockspire, :issuer)
      else
        Application.put_env(:lockspire, :issuer, original)
      end

      if is_nil(original_router) do
        Application.delete_env(:lockspire, :discovery_router)
      else
        Application.put_env(:lockspire, :discovery_router, original_router)
      end

      if is_nil(original_rar_validators) do
        Application.delete_env(:lockspire, :rar_validators)
      else
        Application.put_env(:lockspire, :rar_validators, original_rar_validators)
      end

      if is_nil(original_rar_types_supported) do
        Application.delete_env(:lockspire, :rar_types_supported)
      else
        Application.put_env(:lockspire, :rar_types_supported, original_rar_types_supported)
      end
    end)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    :ok
  end

  test "token_endpoint_auth_methods_supported/0 returns the static seam value (Phase 25 Plan 01)" do
    assert Discovery.token_endpoint_auth_methods_supported() == @static_methods
  end

  test "published_token_endpoint_auth_methods_supported/0 includes private_key_jwt once runtime verification is shared" do
    assert Discovery.published_token_endpoint_auth_methods_supported() == @published_methods
  end

  describe "openid_configuration/0 — endpoint auth metadata truth" do
    test "publishes shared token and revocation auth metadata including private_key_jwt" do
      config = Discovery.openid_configuration()

      assert config["token_endpoint_auth_methods_supported"] == @published_methods

      assert config["token_endpoint_auth_signing_alg_values_supported"] == [
               "HS256",
               "RS256",
               "ES256",
               "PS256",
               "EdDSA"
             ]

      assert config["revocation_endpoint_auth_methods_supported"] == @published_methods

      assert config["revocation_endpoint_auth_signing_alg_values_supported"] == [
               "HS256",
               "RS256",
               "ES256",
               "PS256",
               "EdDSA"
             ]

      refute Map.has_key?(config, "pushed_authorization_request_endpoint_auth_methods_supported")

      refute Map.has_key?(
               config,
               "pushed_authorization_request_endpoint_auth_signing_alg_values_supported"
             )
    end

    test "publishes introspection auth metadata from current shared confidential-client runtime behavior" do
      config = Discovery.openid_configuration()

      assert config["introspection_endpoint_auth_methods_supported"] == @introspection_methods

      assert config["introspection_endpoint_auth_signing_alg_values_supported"] == [
               "RS256",
               "ES256",
               "PS256",
               "EdDSA"
             ]
    end

    test "omits revocation and introspection auth metadata when those routes are not mounted" do
      Application.put_env(
        :lockspire,
        :discovery_router,
        Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter
      )

      config = Discovery.openid_configuration()

      assert config["token_endpoint_auth_methods_supported"] == @published_methods

      assert config["token_endpoint_auth_signing_alg_values_supported"] == [
               "HS256",
               "RS256",
               "ES256",
               "PS256",
               "EdDSA"
             ]

      refute Map.has_key?(config, "revocation_endpoint_auth_methods_supported")
      refute Map.has_key?(config, "revocation_endpoint_auth_signing_alg_values_supported")
      refute Map.has_key?(config, "introspection_endpoint_auth_methods_supported")
      refute Map.has_key?(config, "introspection_endpoint_auth_signing_alg_values_supported")
    end

    test "publishes endpoint signing algorithms from the shared effective allowlist when private_key_jwt is published" do
      put_server_security_profile!(:fapi_2_0_security)

      config = Discovery.openid_configuration()

      assert config["token_endpoint_auth_signing_alg_values_supported"] == ["ES256", "PS256"]
      assert config["revocation_endpoint_auth_signing_alg_values_supported"] == ["ES256", "PS256"]

      assert config["introspection_endpoint_auth_signing_alg_values_supported"] == [
               "ES256",
               "PS256"
             ]
    end

    test "suppresses client_secret_jwt and HS256 publication under FAPI posture" do
      put_server_security_profile!(:fapi_2_0_security)

      config = Discovery.openid_configuration()

      refute "client_secret_jwt" in config["token_endpoint_auth_methods_supported"]
      refute "client_secret_jwt" in config["revocation_endpoint_auth_methods_supported"]
      refute "HS256" in config["token_endpoint_auth_signing_alg_values_supported"]
      refute "HS256" in config["revocation_endpoint_auth_signing_alg_values_supported"]
      refute Map.has_key?(config, "pushed_authorization_request_endpoint_auth_methods_supported")
    end
  end

  describe "authorization-response capability truth" do
    test "publishes one mounted capability story for response modes, signing, and encryption metadata" do
      capabilities =
        AuthorizationResponseCapabilities.metadata(
          %{"authorization_endpoint" => "https://example.test/lockspire/authorize"},
          :none
        )

      assert capabilities["response_modes_supported"] == [
               "query",
               "fragment",
               "form_post",
               "jwt",
               "query.jwt",
               "fragment.jwt",
               "form_post.jwt"
             ]

      assert capabilities["authorization_signing_alg_values_supported"] == [
               "RS256",
               "ES256",
               "PS256",
               "EdDSA"
             ]

      assert capabilities["authorization_encryption_alg_values_supported"] == [
               "RSA-OAEP-256",
               "ECDH-ES"
             ]

      assert capabilities["authorization_encryption_enc_values_supported"] == [
               "A256GCM",
               "A128GCM"
             ]
    end

    test "restricts signing algorithms under the effective FAPI issuer posture while preserving the narrow encryption allow-list" do
      capabilities =
        AuthorizationResponseCapabilities.metadata(
          %{"authorization_endpoint" => "https://example.test/lockspire/authorize"},
          :fapi_2_0_security
        )

      assert capabilities["authorization_signing_alg_values_supported"] == ["ES256", "PS256"]

      assert capabilities["authorization_encryption_alg_values_supported"] == [
               "RSA-OAEP-256",
               "ECDH-ES"
             ]

      assert capabilities["authorization_encryption_enc_values_supported"] == [
               "A256GCM",
               "A128GCM"
             ]
    end

    test "publishes no JARM response metadata when the authorization surface is not mounted" do
      capabilities = AuthorizationResponseCapabilities.metadata(%{}, :none)

      assert capabilities["response_modes_supported"] == ["query", "fragment", "form_post"]
      refute Map.has_key?(capabilities, "authorization_signing_alg_values_supported")
      refute Map.has_key?(capabilities, "authorization_encryption_alg_values_supported")
      refute Map.has_key?(capabilities, "authorization_encryption_enc_values_supported")
    end

    test "openid_configuration derives signing and encryption metadata from the shared helper" do
      config = Discovery.openid_configuration()

      assert Map.take(
               config,
               [
                 "response_modes_supported",
                 "authorization_signing_alg_values_supported",
                 "authorization_encryption_alg_values_supported",
                 "authorization_encryption_enc_values_supported"
               ]
             ) ==
               AuthorizationResponseCapabilities.metadata(
                 %{"authorization_endpoint" => config["authorization_endpoint"]},
                 :none
               )
    end

    test "openid_configuration publishes the unmounted authorization-response contract from the shared helper" do
      Application.put_env(
        :lockspire,
        :discovery_router,
        Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter
      )

      config = Discovery.openid_configuration()

      assert Map.take(
               config,
               [
                 "response_modes_supported",
                 "authorization_signing_alg_values_supported",
                 "authorization_encryption_alg_values_supported",
                 "authorization_encryption_enc_values_supported"
               ]
             ) == AuthorizationResponseCapabilities.metadata(%{}, :none)
    end

    test "published JARM metadata does not depend on transient client registrations" do
      before_registration =
        Discovery.openid_configuration()
        |> Map.take([
          "response_modes_supported",
          "authorization_signing_alg_values_supported",
          "authorization_encryption_alg_values_supported",
          "authorization_encryption_enc_values_supported"
        ])

      {:ok, %{client: client}} =
        Clients.register_client(%{
          name: "encrypted jarm metadata truth fixture",
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

      after_registration =
        Discovery.openid_configuration()
        |> Map.take([
          "response_modes_supported",
          "authorization_signing_alg_values_supported",
          "authorization_encryption_alg_values_supported",
          "authorization_encryption_enc_values_supported"
        ])

      assert after_registration == before_registration
    end
  end

  test "openid_configuration/0 publishes the shipped device grant and device authorization endpoint truth" do
    config = Discovery.openid_configuration()

    assert config["grant_types_supported"] == [
             "authorization_code",
             "refresh_token",
             "urn:ietf:params:oauth:grant-type:device_code",
             "urn:openid:params:grant-type:ciba"
           ]

    assert config["device_authorization_endpoint"] ==
             "https://example.test/lockspire/device/code"

    assert config["backchannel_authentication_endpoint"] ==
             "https://example.test/lockspire/bc-authorize"

    assert config["backchannel_token_delivery_modes_supported"] == ["poll", "ping", "push"]
  end

  test "openid_configuration/0 publishes dpop metadata when /token and /userinfo are both mounted" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.Protocol.DiscoveryTest.TokenAndUserinfoRouter
    )

    config = Discovery.openid_configuration()

    assert config["dpop_signing_alg_values_supported"] == DPoP.signing_alg_values_supported()
  end

  test "openid_configuration/0 omits dpop metadata when the owned userinfo surface is not mounted" do
    Application.put_env(
      :lockspire,
      :discovery_router,
      Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter
    )

    config = Discovery.openid_configuration()

    # Acceptance gate: refute Map.has_key(config, "dpop_signing_alg_values_supported")
    refute Map.has_key?(config, "dpop_signing_alg_values_supported")
  end

  describe "openid_configuration/0 — resource indicators and rar discovery truth" do
    test "publishes resource indicators and sorted rar types when the authorization code surface is usable" do
      Application.put_env(:lockspire, :rar_validators, %{
        "payment_initiation" => Lockspire.Test.Rar.PassthroughValidator,
        "account_access" => Lockspire.Test.Rar.PassthroughValidator
      })

      Application.put_env(:lockspire, :rar_types_supported, [
        "account_access",
        "payment_initiation"
      ])

      config = Discovery.openid_configuration()

      assert config["resource_indicators_supported"] == true

      assert config["authorization_details_types_supported"] == [
               "account_access",
               "payment_initiation"
             ]
    end

    test "omits both keys when the mounted surface cannot complete the authorization code flow" do
      Application.put_env(:lockspire, :rar_validators, %{
        "payment_initiation" => Lockspire.Test.Rar.PassthroughValidator
      })

      Application.put_env(:lockspire, :rar_types_supported, ["payment_initiation"])

      Application.put_env(
        :lockspire,
        :discovery_router,
        Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter
      )

      config = Discovery.openid_configuration()

      refute Map.has_key?(config, "resource_indicators_supported")
      refute Map.has_key?(config, "authorization_details_types_supported")
    end

    test "omits authorization_details_types_supported instead of publishing an empty list" do
      Application.put_env(:lockspire, :rar_validators, %{})
      Application.put_env(:lockspire, :rar_types_supported, [])

      config = Discovery.openid_configuration()

      assert config["resource_indicators_supported"] == true
      refute Map.has_key?(config, "authorization_details_types_supported")
    end
  end

  describe "openid_configuration/0 — shipped session/logout fields" do
    test "includes end_session_endpoint pointing to /end_session" do
      config = Discovery.openid_configuration()

      assert config["end_session_endpoint"] == "https://example.test/lockspire/end_session"
    end

    test "backchannel_logout_supported is truthful for the shipped Phase 39 surface" do
      config = Discovery.openid_configuration()

      assert config["backchannel_logout_supported"] == true
    end

    test "frontchannel_logout_supported is truthful for the shipped Phase 39 surface" do
      config = Discovery.openid_configuration()

      assert config["frontchannel_logout_supported"] == true
    end
  end

  describe "openid_configuration/0 — Phase 39 logout propagation truth" do
    test "publishes all four shipped logout booleans together" do
      config = Discovery.openid_configuration()

      assert config["backchannel_logout_supported"] == true
      assert config["backchannel_logout_session_supported"] == true
      assert config["frontchannel_logout_supported"] == true
      assert config["frontchannel_logout_session_supported"] == true
    end
  end

  describe "openid_configuration/0 — id_token_signing_alg_values_supported truth" do
    test "publishes the legacy broad list when the server profile is :none" do
      Repository.update_server_policy(fn policy ->
        %{policy | security_profile: :none}
      end)

      config = Discovery.openid_configuration()

      assert config["id_token_signing_alg_values_supported"] == [
               "RS256",
               "ES256",
               "PS256",
               "EdDSA"
             ]
    end

    test "publishes the restricted list when the server profile is :fapi_2_0_security" do
      Repository.update_server_policy(fn policy ->
        %{policy | security_profile: :fapi_2_0_security}
      end)

      config = Discovery.openid_configuration()
      assert config["id_token_signing_alg_values_supported"] == ["ES256", "PS256"]
    end
  end

  describe "openid_configuration/0 — access_token_signing_alg_values_supported truth (DISCOVERY-01)" do
    test "publishes the fixed truthful triple as a static literal" do
      config = Discovery.openid_configuration()

      assert config["access_token_signing_alg_values_supported"] == ["RS256", "ES256", "PS256"]
    end

    test "publishes the same literal triple regardless of server security profile (not derived from SecurityProfile)" do
      Repository.update_server_policy(fn policy ->
        %{policy | security_profile: :none}
      end)

      none_config = Discovery.openid_configuration()

      Repository.update_server_policy(fn policy ->
        %{policy | security_profile: :fapi_2_0_security}
      end)

      fapi_config = Discovery.openid_configuration()

      assert none_config["access_token_signing_alg_values_supported"] == ["RS256", "ES256", "PS256"]
      assert fapi_config["access_token_signing_alg_values_supported"] == ["RS256", "ES256", "PS256"]
    end

    test "publishes the key unconditionally, even when the token_endpoint route is not mounted" do
      Application.put_env(
        :lockspire,
        :discovery_router,
        Lockspire.Protocol.DiscoveryTest.TokenOnlyRouter
      )

      mounted_config = Discovery.openid_configuration()

      assert mounted_config["access_token_signing_alg_values_supported"] == [
               "RS256",
               "ES256",
               "PS256"
             ]

      # Mirror the always-present id_token sibling: this key is static, not gated.
      assert Map.has_key?(mounted_config, "access_token_signing_alg_values_supported")
      assert Map.has_key?(mounted_config, "id_token_signing_alg_values_supported")
    end
  end

  describe "openid_configuration/0 — FAPI 2.0 discovery truth" do
    test "publishes authorization_response_iss_parameter_supported unconditionally" do
      metadata = Discovery.openid_configuration()

      assert metadata["authorization_response_iss_parameter_supported"] == true
    end

    test "does NOT publish mTLS or signed_metadata keys (D-09)" do
      metadata = Discovery.openid_configuration()

      refute Map.has_key?(metadata, "tls_client_certificate_bound_access_tokens")
      refute Map.has_key?(metadata, "signed_metadata")
    end

    test "publishes require_pushed_authorization_requests when global profile is :fapi_2_0_security" do
      put_server_security_profile!(:fapi_2_0_security)

      metadata = Discovery.openid_configuration()

      assert metadata["require_pushed_authorization_requests"] == true
    end

    test "publishes require_pushed_authorization_requests when global profile is :fapi_2_0_message_signing" do
      put_server_security_profile!(:fapi_2_0_message_signing)

      metadata = Discovery.openid_configuration()

      assert metadata["require_pushed_authorization_requests"] == true
    end

    test "omits require_pushed_authorization_requests key when global profile is :none" do
      put_server_security_profile!(:none)

      metadata = Discovery.openid_configuration()

      refute Map.has_key?(metadata, "require_pushed_authorization_requests")
    end

    test "per-client :fapi_2_0_security override does NOT flip discovery PAR key when global is :none" do
      put_server_security_profile!(:none)

      {:ok, %{client: client}} =
        Clients.register_client(%{
          name: "discovery per-client override fixture",
          client_type: :confidential,
          redirect_uris: ["https://override.example.com/cb"],
          allowed_scopes: ["profile"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic
        })

      {:ok, _updated} =
        Repository.update_client(client, %{
          security_profile: :fapi_2_0_security
        })

      metadata = Discovery.openid_configuration()

      refute Map.has_key?(metadata, "require_pushed_authorization_requests")
    end
  end

  describe "truthful discovery for registration_endpoint" do
    test "when registration_policy is :disabled, endpoint is hidden and router returns 404" do
      Repository.update_server_policy(fn policy -> %{policy | registration_policy: :disabled} end)

      config = Discovery.openid_configuration()
      refute Map.has_key?(config, "registration_endpoint")

      conn =
        build_conn(:post, "/register", %{})
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 404
    end

    test "when registration_policy is :initial_access_token, endpoint is shown and router handles it" do
      Repository.update_server_policy(fn policy ->
        %{policy | registration_policy: :initial_access_token}
      end)

      config = Discovery.openid_configuration()
      assert config["registration_endpoint"] == "https://example.test/lockspire/register"

      conn =
        build_conn(:post, "/register", %{})
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      # Should return 401 or 400, not 404
      assert conn.status in [400, 401]
    end

    test "when registration_policy is :open, endpoint is shown and router handles it" do
      Repository.update_server_policy(fn policy -> %{policy | registration_policy: :open} end)

      config = Discovery.openid_configuration()
      assert config["registration_endpoint"] == "https://example.test/lockspire/register"

      conn =
        build_conn(:post, "/register", %{})
        |> put_req_header("accept", "application/json")
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      # Should return 400 (bad request due to missing body), not 404
      assert conn.status == 400
    end
  end

  describe "openid_configuration/0 — mtls_endpoint_aliases" do
    test "publishes mtls_endpoint_aliases when mtls_issuer is configured" do
      Application.put_env(:lockspire, :mtls_issuer, "https://mtls.example.test/lockspire")
      on_exit(fn -> Application.delete_env(:lockspire, :mtls_issuer) end)

      config = Discovery.openid_configuration()

      aliases = config["mtls_endpoint_aliases"]
      assert aliases["token_endpoint"] == "https://mtls.example.test/lockspire/token"
      assert aliases["revocation_endpoint"] == "https://mtls.example.test/lockspire/revoke"
      assert aliases["introspection_endpoint"] == "https://mtls.example.test/lockspire/introspect"

      assert aliases["device_authorization_endpoint"] ==
               "https://mtls.example.test/lockspire/device/code"

      assert aliases["pushed_authorization_request_endpoint"] ==
               "https://mtls.example.test/lockspire/par"

      assert aliases["userinfo_endpoint"] == "https://mtls.example.test/lockspire/userinfo"

      assert aliases["backchannel_authentication_endpoint"] ==
               "https://mtls.example.test/lockspire/bc-authorize"
    end
  end

  defp put_server_security_profile!(profile) do
    {:ok, policy} = Repository.get_server_policy()
    Repository.put_server_policy(%{policy | security_profile: profile})
  end
end
