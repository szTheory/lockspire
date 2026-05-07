defmodule Lockspire.Web.CibaAuthorizationJSONTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.BackchannelAuthentication.Error
  alias Lockspire.Web.CibaAuthorizationJSON

  test "does not expose internal reason_code values in public error JSON" do
    response =
      CibaAuthorizationJSON.error_response(%Error{
        status: 401,
        error: "invalid_client",
        error_description: "Client authentication failed",
        reason_code: :client_assertion_signature_invalid
      })

    assert response == %{
             error: "invalid_client",
             error_description: "Client authentication failed"
           }
  end
end
