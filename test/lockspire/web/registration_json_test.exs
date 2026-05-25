defmodule Lockspire.Web.RegistrationJSONTest do
  use ExUnit.Case, async: true
  alias Lockspire.Web.RegistrationJSON
  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Domain.Client

  @now DateTime.utc_now() |> DateTime.truncate(:second)
  @client %Client{
    client_id: "test-client-123",
    inserted_at: @now,
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
