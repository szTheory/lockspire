defmodule Lockspire.Protocol.AuthorizationRequestTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.AuthorizationRequest.Error
  alias Lockspire.Protocol.AuthorizationRequest.Validated
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "offline_access"])
    Application.put_env(:lockspire, :issuer, "https://server.example.com/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client_123",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Acme Integrations",
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

    {:ok, other_client} =
      Repository.register_client(%Client{
        client_id: "client_456",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Other Integrations",
        redirect_uris: ["https://other.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client, other_client: other_client}
  end

  test "accepts a valid authorization request and returns a typed validated contract", %{
    client: client
  } do
    handler_id = attach_events(self())
    client_id = client.client_id

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(valid_params(client.client_id))

    assert validated.client_id == client.client_id
    assert validated.redirect_uri == "https://client.example.com/callback"
    assert validated.scopes == ["profile", "email"]
    assert validated.prompt == ["login", "consent"]
    assert validated.nonce == nil
    assert validated.code_challenge_method == :S256

    assert_received {:telemetry_event, [:lockspire, :authorization_request, :accepted],
                     %{client_id: ^client_id, redirect_safe: true}}

    assert_received {:telemetry_event, [:lockspire, :audit, :authorization_request, :accepted],
                     %{client_id: ^client_id, redirect_safe: true}}

    :telemetry.detach(handler_id)
  end

  test "invalid client_id returns a browser error and never becomes redirect-safe" do
    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(valid_params("missing"))

    assert error.error == "invalid_client"
    assert error.reason_code == :invalid_client
    assert error.redirect_uri == nil
  end

  test "mismatched redirect_uri returns a browser error" do
    params =
      valid_params("client_123")
      |> Map.put("redirect_uri", "https://attacker.example.com/callback")

    assert {:browser_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :invalid_redirect_uri
    assert error.error_description == "redirect_uri must match a registered URI"
  end

  test "unknown scopes return redirect errors with preserved state" do
    handler_id = attach_events(self())

    params =
      valid_params("client_123")
      |> Map.put("scope", "profile admin")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.error == "invalid_scope"
    assert error.reason_code == :unknown_scope
    assert error.state == "state-123"

    assert_received {:telemetry_event, [:lockspire, :authorization_request, :rejected],
                     %{reason_code: :unknown_scope, redirect_safe: true}}

    assert_received {:telemetry_event, [:lockspire, :audit, :authorization_request, :rejected],
                     %{reason_code: :unknown_scope, redirect_safe: true}}

    :telemetry.detach(handler_id)
  end

  test "openid requests require a nonce and persist it when present", %{client: client} do
    missing_nonce_params =
      valid_params(client.client_id)
      |> Map.put("scope", "openid email profile")

    assert {:redirect_error, %Error{} = error} =
             AuthorizationRequest.validate(missing_nonce_params)

    assert error.reason_code == :missing_nonce

    assert {:ok, %Validated{} = validated} =
             client.client_id
             |> valid_params()
             |> Map.put("scope", "openid email profile")
             |> Map.put("nonce", "nonce-123")
             |> AuthorizationRequest.validate()

    assert validated.scopes == ["openid", "email", "profile"]
    assert validated.nonce == "nonce-123"
  end

  test "invalid prompt returns a redirect error" do
    params =
      valid_params("client_123")
      |> Map.put("prompt", "login login")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :duplicate_prompt
  end

  test "prompt=none is accepted only as a standalone value", %{client: client} do
    assert {:ok, %Validated{} = validated} =
             client.client_id
             |> valid_params()
             |> Map.put("prompt", "none")
             |> AuthorizationRequest.validate()

    assert validated.prompt == ["none"]
    assert validated.max_age == nil
    refute validated.auth_time_requested?
  end

  test "prompt=none rejects combinations with other prompt values" do
    for prompt <- ["none consent", "none login"] do
      assert {:redirect_error, %Error{} = error} =
               "client_123"
               |> valid_params()
               |> Map.put("prompt", prompt)
               |> AuthorizationRequest.validate()

      assert error.error == "invalid_request"
      assert error.reason_code == :prompt_none_conflict
    end
  end

  test "max_age accepts only digit-only strings and stores an integer", %{client: client} do
    assert {:ok, %Validated{} = validated} =
             client.client_id
             |> valid_params()
             |> Map.put("max_age", "600")
             |> AuthorizationRequest.validate()

    assert validated.max_age == 600

    for max_age <- ["", "-1", "12.5", "abc", " 10"] do
      assert {:redirect_error, %Error{} = error} =
               "client_123"
               |> valid_params()
               |> Map.put("max_age", max_age)
               |> AuthorizationRequest.validate()

      assert error.error == "invalid_request"
      assert error.reason_code == :invalid_max_age
    end
  end

  test "claims supports only id_token.auth_time.essential=true" do
    valid_claims = ~s({"id_token":{"auth_time":{"essential":true}}})

    assert {:ok, %Validated{} = validated} =
             "client_123"
             |> valid_params()
             |> Map.put("claims", valid_claims)
             |> AuthorizationRequest.validate()

    assert validated.auth_time_requested?

    invalid_claims_values = [
      "",
      "not-json",
      ~s({"userinfo":{"auth_time":{"essential":true}}}),
      ~s({"id_token":{"auth_time":{"essential":false}}}),
      ~s({"id_token":{"auth_time":{"value":true}}}),
      ~s({"id_token":{"email":{"essential":true}}}),
      ~s({"id_token":"bad"})
    ]

    for claims <- invalid_claims_values do
      assert {:redirect_error, %Error{} = error} =
               "client_123"
               |> valid_params()
               |> Map.put("claims", claims)
               |> AuthorizationRequest.validate()

      assert error.error == "invalid_request"
      assert error.reason_code == :invalid_claims_parameter
    end
  end

  test "openid requests without nonce still fail with stable reason code while valid nonce is preserved",
       %{client: client} do
    missing_nonce_params =
      valid_params(client.client_id)
      |> Map.put("scope", "openid email profile")
      |> Map.put("prompt", "none")
      |> Map.put("max_age", "60")

    assert {:redirect_error, %Error{} = error} =
             AuthorizationRequest.validate(missing_nonce_params)

    assert error.reason_code == :missing_nonce

    assert {:ok, %Validated{} = validated} =
             client.client_id
             |> valid_params()
             |> Map.put("scope", "openid email profile")
             |> Map.put("prompt", "none")
             |> Map.put("max_age", "60")
             |> Map.put("nonce", "nonce-preserved-123")
             |> AuthorizationRequest.validate()

    assert validated.scopes == ["openid", "email", "profile"]
    assert validated.prompt == ["none"]
    assert validated.max_age == 60
    assert validated.nonce == "nonce-preserved-123"
  end

  test "missing pkce returns a redirect error" do
    params =
      valid_params("client_123")
      |> Map.delete("code_challenge")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :missing_pkce
    assert error.error == "invalid_request"
  end

  test "unsupported response_type returns a stable redirect-safe reason code" do
    params =
      valid_params("client_123")
      |> Map.put("response_type", "token")

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.reason_code == :unsupported_response_type
    assert error.error == "unsupported_response_type"
  end

  test "required global par policy rejects direct authorize requests with a trusted redirect", %{
    client: client
  } do
    handler_id = attach_events(self())
    put_server_policy!(:required)
    client_id = client.client_id

    assert {:redirect_error, %Error{} = error} =
             AuthorizationRequest.validate(valid_params(client.client_id))

    assert error.error == "invalid_request"
    assert error.reason_code == :par_required_request_uri
    assert error.redirect_uri == "https://client.example.com/callback"
    assert error.state == "state-123"

    assert_received {:telemetry_event, [:lockspire, :authorization_request, :rejected],
                     %{
                       client_id: ^client_id,
                       reason_code: :par_required_request_uri,
                       redirect_safe: true
                     }}

    assert_received {:telemetry_event, [:lockspire, :audit, :authorization_request, :rejected],
                     %{
                       client_id: ^client_id,
                       reason_code: :par_required_request_uri,
                       redirect_safe: true
                     }}

    :telemetry.detach(handler_id)
  end

  test "required global par policy keeps missing redirect_uri on the browser-safe error surface",
       %{
         client: client
       } do
    handler_id = attach_events(self())
    put_server_policy!(:required)
    client_id = client.client_id

    params =
      valid_params(client.client_id)
      |> Map.delete("redirect_uri")

    assert {:browser_error, %Error{} = error} = AuthorizationRequest.validate(params)

    assert error.error == "invalid_request"
    assert error.reason_code == :par_required_request_uri
    assert error.redirect_uri == nil
    assert error.state == nil

    assert_received {:telemetry_event, [:lockspire, :authorization_request, :rejected],
                     %{
                       client_id: ^client_id,
                       reason_code: :par_required_request_uri,
                       redirect_safe: false
                     }}

    assert_received {:telemetry_event, [:lockspire, :audit, :authorization_request, :rejected],
                     %{
                       client_id: ^client_id,
                       reason_code: :par_required_request_uri,
                       redirect_safe: false
                     }}

    :telemetry.detach(handler_id)
  end

  test "required global par policy keeps mismatched redirect_uri on the browser-safe error surface",
       %{
         client: client
       } do
    put_server_policy!(:required)

    params =
      valid_params(client.client_id)
      |> Map.put("redirect_uri", "https://attacker.example.com/callback")

    assert {:browser_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.error == "invalid_request"
    assert error.reason_code == :par_required_request_uri
    assert error.redirect_uri == nil
  end

  test "client required par policy rejects direct authorize requests when the global policy is optional",
       %{client: client} do
    put_server_policy!(:optional)
    client = update_client_par_policy!(client, :required)

    assert {:redirect_error, %Error{} = error} =
             AuthorizationRequest.validate(valid_params(client.client_id))

    assert error.error == "invalid_request"
    assert error.reason_code == :par_required_request_uri
  end

  test "client optional par policy preserves direct authorize requests when the global policy is required",
       %{client: client} do
    put_server_policy!(:required)
    client = update_client_par_policy!(client, :optional)

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(valid_params(client.client_id))

    assert validated.client_id == client.client_id
    assert validated.redirect_uri == "https://client.example.com/callback"
  end

  test "required par policy still accepts a valid lockspire-issued request_uri", %{client: client} do
    put_server_policy!(:required)
    pushed_request = put_pushed_request!(client.client_id)

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => pushed_request.request_uri
             })

    assert validated.client_id == client.client_id
    assert validated.redirect_uri == "https://client.example.com/callback"
  end

  test "consumes a valid pushed authorization request exactly once for the bound client", %{
    client: client
  } do
    pushed_request = put_pushed_request!(client.client_id)

    assert {:ok, %PushedAuthorizationRequest{} = consumed} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               client.client_id
             )

    assert consumed.client_id == client.client_id
    assert consumed.redirect_uri == "https://client.example.com/callback"
    assert consumed.scopes == ["profile", "email"]
    assert consumed.prompt == ["login", "consent"]
    assert consumed.state == "state-123"

    assert {:ok, nil} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               client.client_id
             )
  end

  test "resolves a valid pushed authorization request into the canonical validated contract", %{
    client: client
  } do
    pushed_request = put_pushed_request!(client.client_id)

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => pushed_request.request_uri
             })

    assert validated.client_id == client.client_id
    assert validated.redirect_uri == "https://client.example.com/callback"
    assert validated.scopes == ["profile", "email"]
    assert validated.prompt == ["login", "consent"]
    assert validated.state == "state-123"
    assert validated.code_challenge == String.duplicate("a", 43)
  end

  test "expired pushed authorization request is treated like a missing reference", %{
    client: client
  } do
    pushed_request = put_pushed_request!(client.client_id, ttl: -1)

    assert {:ok, nil} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               client.client_id
             )
  end

  test "expired pushed authorization request is rejected as invalid input", %{client: client} do
    request_uri =
      put_pushed_request!(client.client_id, ttl: -1)
      |> Map.fetch!(:request_uri)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => request_uri
             })

    assert error.error == "invalid_request"
    assert error.reason_code == :invalid_request_uri
  end

  test "required par policy preserves invalid_request_uri semantics for expired request_uri values",
       %{
         client: client
       } do
    put_server_policy!(:required)

    request_uri =
      put_pushed_request!(client.client_id, ttl: -1)
      |> Map.fetch!(:request_uri)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => request_uri
             })

    assert error.error == "invalid_request"
    assert error.reason_code == :invalid_request_uri
  end

  test "required par policy preserves invalid_request_uri semantics for foreign request_uri values",
       %{client: client} do
    put_server_policy!(:required)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => "https://attacker.example.com/request/123"
             })

    assert error.error == "invalid_request"
    assert error.reason_code == :invalid_request_uri
  end

  test "replayed pushed authorization request stays burned after first successful consume", %{
    client: client
  } do
    pushed_request = put_pushed_request!(client.client_id)

    assert {:ok, %PushedAuthorizationRequest{}} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               client.client_id
             )

    assert {:ok, nil} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               client.client_id
             )
  end

  test "replayed pushed authorization request is rejected after first successful use", %{
    client: client
  } do
    pushed_request = put_pushed_request!(client.client_id)
    params = %{"client_id" => client.client_id, "request_uri" => pushed_request.request_uri}

    assert {:ok, %Validated{}} = AuthorizationRequest.validate(params)

    assert {:browser_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.error == "invalid_request"
    assert error.reason_code == :invalid_request_uri
  end

  test "wrong-client pushed authorization request attempt burns the reference", %{
    client: client,
    other_client: other_client
  } do
    pushed_request = put_pushed_request!(client.client_id)

    assert {:ok, nil} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               other_client.client_id
             )

    assert {:ok, nil} =
             Repository.consume_pushed_authorization_request(
               pushed_request.request_uri_hash,
               client.client_id
             )
  end

  test "wrong-client pushed authorization request is rejected and burns the reference", %{
    client: client,
    other_client: other_client
  } do
    pushed_request = put_pushed_request!(client.client_id)

    assert {:browser_error, %Error{} = wrong_client_error} =
             AuthorizationRequest.validate(%{
               "client_id" => other_client.client_id,
               "request_uri" => pushed_request.request_uri
             })

    assert wrong_client_error.error == "invalid_request"
    assert wrong_client_error.reason_code == :invalid_request_uri

    assert {:browser_error, %Error{} = replay_error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => pushed_request.request_uri
             })

    assert replay_error.error == "invalid_request"
    assert replay_error.reason_code == :invalid_request_uri
  end

  test "required par policy preserves invalid_request_uri semantics for wrong-client request_uri values",
       %{client: client, other_client: other_client} do
    put_server_policy!(:required)
    pushed_request = put_pushed_request!(client.client_id)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => other_client.client_id,
               "request_uri" => pushed_request.request_uri
             })

    assert error.error == "invalid_request"
    assert error.reason_code == :invalid_request_uri
  end

  test "rejects mixed request_uri and raw authorization parameters", %{client: client} do
    pushed_request = put_pushed_request!(client.client_id)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request_uri" => pushed_request.request_uri,
               "redirect_uri" => "https://client.example.com/callback"
             })

    assert error.error == "invalid_request"
    assert error.reason_code == :request_uri_conflict
  end

  test "accepts a signed request object and projects its claims into the authorization pipeline",
       %{
         client: client
       } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client_jar",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "JAR Integrations",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        jwks: pub_jwk_map,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    request_jwt =
      JarTestHelpers.sign_jar(
        private_jwk,
        %{
          "iss" => client.client_id,
          "aud" => Lockspire.Config.issuer!(),
          "exp" => DateTime.utc_now() |> DateTime.add(300, :second) |> DateTime.to_unix(),
          "redirect_uri" => "https://client.example.com/callback",
          "response_type" => "code",
          "scope" => "profile email",
          "state" => "state-123",
          "prompt" => "login consent",
          "code_challenge" => String.duplicate("a", 43),
          "code_challenge_method" => "S256"
        }
      )

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" => request_jwt
             })

    assert validated.client_id == client.client_id
    assert validated.redirect_uri == "https://client.example.com/callback"
    assert validated.scopes == ["profile", "email"]
    assert validated.prompt == ["login", "consent"]
    assert validated.state == "state-123"
    assert validated.code_challenge == String.duplicate("a", 43)
  end

  test "rejects raw params mixed into a request object as sealed-envelope conflicts", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    request_jwt =
      sign_jar_request!(private_jwk, client.client_id)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" => request_jwt,
               "redirect_uri" => "https://client.example.com/callback"
             })

    assert error.reason_code == :request_object_conflict
  end

  test "rejects request and request_uri collisions with the request-object reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    request_jwt =
      sign_jar_request!(private_jwk, client.client_id)

    pushed_request = put_pushed_request!(client.client_id)

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" => request_jwt,
               "request_uri" => pushed_request.request_uri
             })

    assert error.reason_code == :request_object_and_request_uri_conflict
  end

  test "maps malformed request objects to the invalid_request_object_jwt reason code", %{
    client: _client
  } do
    %{pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()
    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" => "not.a.jwt"
             })

    assert error.reason_code == :invalid_request_object_jwt
  end

  test "maps invalid request object typ headers to the invalid_request_object_typ reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" =>
                 JarTestHelpers.sign_jar(private_jwk, jar_claims(client.client_id),
                   extra_header: %{"typ" => "JWT-bearer"}
                 )
             })

    assert error.reason_code == :invalid_request_object_typ
  end

  test "maps invalid signatures to the invalid_request_object_signature reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()
    other_private_jwk = JOSE.JWK.generate_key({:rsa, 2048})

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" =>
                 JarTestHelpers.sign_jar(other_private_jwk, jar_claims(client.client_id))
             })

    assert error.reason_code == :invalid_request_object_signature
  end

  test "maps missing client jwks to the client_jwks_missing reason code", %{client: client} do
    %{private_jwk: private_jwk} = JarTestHelpers.generate_keys()

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" => JarTestHelpers.sign_jar(private_jwk, jar_claims(client.client_id))
             })

    assert error.reason_code == :client_jwks_missing
  end

  test "maps expired request objects to the invalid_request_object_expired reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" =>
                 JarTestHelpers.sign_jar(
                   private_jwk,
                   jar_claims(client.client_id,
                     exp: DateTime.utc_now() |> DateTime.add(-5, :second) |> DateTime.to_unix()
                   )
                 )
             })

    assert error.reason_code == :invalid_request_object_expired
  end

  test "maps issuer mismatches to the invalid_request_object_iss reason code", %{client: _client} do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" => JarTestHelpers.sign_jar(private_jwk, jar_claims("other-client"))
             })

    assert error.reason_code == :invalid_request_object_iss
  end

  test "maps audience mismatches to the invalid_request_object_aud reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" =>
                 JarTestHelpers.sign_jar(
                   private_jwk,
                   jar_claims(client.client_id, aud: "https://other.example.com")
                 )
             })

    assert error.reason_code == :invalid_request_object_aud
  end

  test "maps max-age violations to the invalid_request_object_max_age reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" =>
                 JarTestHelpers.sign_jar(
                   private_jwk,
                   jar_claims(client.client_id,
                     exp: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
                   )
                 )
             })

    assert error.reason_code == :invalid_request_object_max_age
  end

  test "maps invalid claim shapes to the invalid_request_object_claims reason code", %{
    client: _client
  } do
    %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map} = JarTestHelpers.generate_keys()

    {:ok, client} = register_jar_client!(pub_jwk_map, "client_jar")

    assert {:browser_error, %Error{} = error} =
             AuthorizationRequest.validate(%{
               "client_id" => client.client_id,
               "request" =>
                 JarTestHelpers.sign_jar(
                   private_jwk,
                   jar_claims(client.client_id,
                     nbf: DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
                   )
                 )
             })

    assert error.reason_code == :invalid_request_object_claims
  end

  test "accepts a valid authorization_details JSON array on direct requests", %{client: client} do
    detail = %{"type" => "payment_initiation", "actions" => ["initiate"]}
    encoded = Jason.encode!([detail])

    assert {:ok, %Validated{} = validated} =
             client.client_id
             |> valid_params()
             |> Map.put("authorization_details", encoded)
             |> AuthorizationRequest.validate()

    assert validated.authorization_details == [detail]
  end

  test "defaults authorization_details to [] when absent", %{client: client} do
    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate(valid_params(client.client_id))

    assert validated.authorization_details == []
  end

  test "rejects authorization_details longer than 2048 characters on direct requests", %{
    client: client
  } do
    over_limit_payload =
      [
        %{
          "type" => "payment_initiation",
          "padding" => String.duplicate("x", 2100)
        }
      ]
      |> Jason.encode!()

    assert byte_size(over_limit_payload) > 2048

    params =
      client.client_id
      |> valid_params()
      |> Map.put("authorization_details", over_limit_payload)

    assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
    assert error.error == "invalid_request"
    assert error.reason_code == :authorization_details_too_large
  end

  test "rejects authorization_details that is not a JSON array of objects", %{client: client} do
    for invalid <- [
          ~s({"type":"payment_initiation"}),
          ~s(["not-an-object"]),
          "not-json"
        ] do
      params =
        client.client_id
        |> valid_params()
        |> Map.put("authorization_details", invalid)

      assert {:redirect_error, %Error{} = error} = AuthorizationRequest.validate(params)
      assert error.error == "invalid_authorization_details"
      assert error.reason_code == :invalid_authorization_details
    end
  end

  test "accepts authorization_details from a pre-decoded list (Request Object projection)", %{
    client: client
  } do
    details = [
      %{"type" => "account_information", "locations" => ["https://api.example.com/accounts"]}
    ]

    params =
      client.client_id
      |> valid_params()
      |> Map.put("authorization_details", details)

    assert {:ok, %Validated{} = validated} = AuthorizationRequest.validate(params)
    assert validated.authorization_details == details
  end

  test "skips the 2048 character limit when invoked through the pushed pipeline", %{
    client: client
  } do
    over_limit_payload =
      [
        %{
          "type" => "payment_initiation",
          "padding" => String.duplicate("x", 2100)
        }
      ]
      |> Jason.encode!()

    params =
      client.client_id
      |> valid_params()
      |> Map.put("authorization_details", over_limit_payload)

    assert {:ok, %Validated{} = validated} =
             AuthorizationRequest.validate_pushed(params, client)

    assert [%{"type" => "payment_initiation"}] = validated.authorization_details
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

  defp register_jar_client!(pub_jwk_map, client_id) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: "sha256:salt:hash",
      client_type: :confidential,
      name: "JAR Integrations",
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["profile", "email"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      jwks: pub_jwk_map,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end

  defp sign_jar_request!(private_jwk, client_id, overrides \\ []) do
    claims = jar_claims(client_id) |> Map.merge(Map.new(overrides))
    JarTestHelpers.sign_jar(private_jwk, claims, extra_header: %{"typ" => "oauth-authz-req+jwt"})
  end

  defp jar_claims(client_id, overrides \\ []) do
    base = %{
      "iss" => client_id,
      "aud" => Lockspire.Config.issuer!(),
      "exp" => DateTime.utc_now() |> DateTime.add(300, :second) |> DateTime.to_unix(),
      "redirect_uri" => "https://client.example.com/callback",
      "response_type" => "code",
      "scope" => "profile email",
      "state" => "state-123",
      "prompt" => "login consent",
      "code_challenge" => String.duplicate("a", 43),
      "code_challenge_method" => "S256"
    }

    Map.merge(base, Map.new(overrides))
  end

  defp put_pushed_request!(client_id, opts \\ []) do
    attrs = %{
      client_id: client_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: ["profile", "email"],
      prompt: ["login", "consent"],
      state: "state-123",
      code_challenge: String.duplicate("a", 43),
      code_challenge_method: :S256
    }

    request = PushedAuthorizationRequest.issue(attrs, opts)

    assert {:ok, %PushedAuthorizationRequest{} = stored} =
             Repository.put_pushed_authorization_request(request)

    stored
  end

  defp put_server_policy!(mode) do
    assert {:ok, %ServerPolicy{} = _policy} =
             Repository.put_server_policy(%ServerPolicy{par_policy: mode})
  end

  defp update_client_par_policy!(client, mode) do
    assert {:ok, %Client{} = updated_client} =
             Repository.update_client(client, %{par_policy: mode})

    updated_client
  end

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "authorization-request-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :authorization_request, :accepted],
          [:lockspire, :audit, :authorization_request, :accepted],
          [:lockspire, :authorization_request, :rejected],
          [:lockspire, :audit, :authorization_request, :rejected]
        ],
        &__MODULE__.handle_event/4,
        pid
      )

    handler_id
  end
end
