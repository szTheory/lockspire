defmodule Lockspire.Web.RegistrationJSONTest do
  use ExUnit.Case, async: true
  alias Lockspire.Web.RegistrationJSON
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Domain.Client

  @now DateTime.utc_now() |> DateTime.truncate(:second)
  @client %Client{
    client_id: "test-client-123",
    name: "Test App",
    redirect_uris: ["https://example.com/callback"],
    allowed_scopes: ["openid", "profile"],
    allowed_grant_types: ["authorization_code", "refresh_token"],
    allowed_response_types: ["code"],
    inserted_at: @now,
    lifetime_version: 0,
    client_secret_expires_at: nil,
    dpop_policy: :dpop,
    backchannel_logout_uri: "https://rp.example.test/backchannel-logout",
    backchannel_logout_session_required: true,
    frontchannel_logout_uri: "https://example.com/frontchannel-logout",
    frontchannel_logout_session_required: false,
    metadata: %{"client_name" => "Test App", "client_uri" => "https://example.com"}
  }

  test "success_response/1 formats UNIX epochs and includes secrets" do
    success = %Registration.Success{
      client: @client,
      client_secret_plaintext: "secret-123",
      registration_access_token_plaintext: "rat-123"
    }

    result = RegistrationJSON.success_response(success)
    assert result.client_id == "test-client-123"
    assert result.client_secret == "secret-123"
    assert result.registration_access_token == "rat-123"
    assert result.client_id_issued_at == DateTime.to_unix(@now)
    assert result.client_secret_expires_at == 0
    assert result["client_name"] == "Test App"
    assert result["client_uri"] == "https://example.com"
    assert result.redirect_uris == ["https://example.com/callback"]
    assert result.scope == "openid profile"
    assert result.grant_types == ["authorization_code", "refresh_token"]
    assert result.response_types == ["code"]
    refute Map.has_key?(result, :id_token_signed_response_alg)
    refute Map.has_key?(result, :authorization_signed_response_alg)
    refute Map.has_key?(result, :authorization_encrypted_response_alg)
    refute Map.has_key?(result, :authorization_encrypted_response_enc)
    assert result.dpop_bound_access_tokens == true
    assert result.backchannel_logout_uri == "https://rp.example.test/backchannel-logout"
    assert result.backchannel_logout_session_required == true
    assert result.frontchannel_logout_uri == "https://example.com/frontchannel-logout"
    assert result.frontchannel_logout_session_required == false
    assert String.ends_with?(result.registration_client_uri, "/register/test-client-123")
  end

  test "read_response/1 formats UNIX epochs but omits secrets" do
    result = RegistrationJSON.read_response(@client)

    assert result.client_id == "test-client-123"
    refute Map.has_key?(result, :client_secret)
    refute Map.has_key?(result, :registration_access_token)
    assert result.client_id_issued_at == DateTime.to_unix(@now)
    assert result.client_secret_expires_at == 0
    assert result.dpop_bound_access_tokens == true
    assert result.backchannel_logout_uri == "https://rp.example.test/backchannel-logout"
    assert result.backchannel_logout_session_required == true
    assert result.frontchannel_logout_uri == "https://example.com/frontchannel-logout"
    assert result.frontchannel_logout_session_required == false
  end

  test "success_response/1 omits a client secret when none was issued" do
    result =
      RegistrationJSON.success_response(%Registration.Success{
        client: @client,
        client_secret_plaintext: nil,
        registration_access_token_plaintext: "rat-123"
      })

    refute Map.has_key?(result, :client_secret)
    assert result.registration_access_token == "rat-123"
  end

  test "update_response/1 includes RAT but omits client_secret" do
    update_success = %RegistrationManagement.UpdateSuccess{
      client: @client,
      registration_access_token_plaintext: "rat-456"
    }

    result = RegistrationJSON.update_response(update_success)

    assert result.client_id == "test-client-123"
    refute Map.has_key?(result, :client_secret)
    assert result.registration_access_token == "rat-456"
    assert result.client_id_issued_at == DateTime.to_unix(@now)
    assert result.dpop_bound_access_tokens == true
    assert result.backchannel_logout_uri == "https://rp.example.test/backchannel-logout"
    assert result.frontchannel_logout_session_required == false
  end

  test "responses expose dpop_bound_access_tokens as false for bearer clients" do
    bearer_client = %Client{@client | dpop_policy: :bearer}

    assert RegistrationJSON.read_response(bearer_client).dpop_bound_access_tokens == false
  end

  test "responses omit logout metadata when the client has none stored" do
    result =
      RegistrationJSON.read_response(%Client{
        @client
        | backchannel_logout_uri: nil,
          backchannel_logout_session_required: false,
          frontchannel_logout_uri: nil,
          frontchannel_logout_session_required: false
      })

    refute Map.has_key?(result, :backchannel_logout_uri)
    refute Map.has_key?(result, :backchannel_logout_session_required)
    refute Map.has_key?(result, :frontchannel_logout_uri)
    refute Map.has_key?(result, :frontchannel_logout_session_required)
  end

  test "serializer ignores advisory metadata and uses only the effective secret deadline" do
    client = %Client{
      @client
      | token_endpoint_auth_method: :client_secret_basic,
        lifetime_version: 1,
        client_secret_expires_at: DateTime.from_unix!(110),
        client_secret_hash: "dormant-hash",
        client_secret_jwt_verifier_encrypted: "dormant-verifier",
        metadata: Map.put(@client.metadata, "client_secret_expires_at", 999)
    }

    read = RegistrationJSON.read_response(client)

    assert read.client_secret_expires_at == 110
    refute Map.has_key?(read, "client_secret_expires_at")
    refute Map.has_key?(read, :client_secret)
  end

  test "non-secret methods omit secret expiry even with dormant material and v0 dates are advisory" do
    for method <- [:none, :private_key_jwt, :tls_client_auth, :self_signed_tls_client_auth] do
      client = %Client{
        @client
        | token_endpoint_auth_method: method,
          lifetime_version: 1,
          client_secret_expires_at: DateTime.from_unix!(110),
          client_secret_hash: "dormant-hash",
          client_secret_jwt_verifier_encrypted: "dormant-verifier"
      }

      refute Map.has_key?(RegistrationJSON.read_response(client), :client_secret_expires_at)
    end

    legacy = %Client{
      @client
      | token_endpoint_auth_method: :client_secret_basic,
        lifetime_version: 0,
        client_secret_expires_at: DateTime.from_unix!(50)
    }

    assert RegistrationJSON.success_response(%Registration.Success{
             client: legacy,
             client_secret_plaintext: "secret",
             registration_access_token_plaintext: "rat"
           }).client_secret_expires_at == 0

    assert RegistrationJSON.read_response(legacy).client_secret_expires_at == 0

    assert RegistrationJSON.update_response(%RegistrationManagement.UpdateSuccess{
             client: legacy,
             registration_access_token_plaintext: "rat"
           }).client_secret_expires_at == 0
  end

  test "operator secret registration does not inherit the DCR secret policy" do
    assert {:ok, nil} =
             Client.secret_deadline(
               %Client{token_endpoint_auth_method: :client_secret_basic, provenance: :operator},
               DateTime.from_unix!(100),
               10
             )
  end

  test "error_response/1 maps code to error string" do
    error = %Registration.Error{
      code: :invalid_client_metadata,
      field: :redirect_uris,
      reason: :invalid_uri
    }

    result = RegistrationJSON.error_response(error)

    assert result.error == "invalid_client_metadata"
    assert result.error_description == "invalid_uri for redirect_uris"
  end
end
