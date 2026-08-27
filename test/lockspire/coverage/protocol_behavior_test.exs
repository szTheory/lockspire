defmodule Lockspire.Coverage.ProtocolBehaviorTest do
  use Lockspire.TokenExchangeCase

  test "a missing PKCE verifier is rejected without consuming the authorization code" do
    secret = "coverage-protocol-secret"
    {:ok, client} = create_client("coverage-protocol-client", :client_secret_basic, secret)
    assert {:ok, _key} = publish_signing_key("coverage-protocol-signing-key")

    assert {:ok, _code} =
             create_authorization_code(client,
               raw_code: "coverage-protocol-code",
               code_verifier: "coverage-protocol-verifier"
             )

    assert {:error, error} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "coverage-protocol-code",
                 "redirect_uri" => "https://client.example.com/callback"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert error.error == "invalid_grant"
    assert error.reason_code == :missing_code_verifier

    assert {:ok, success} =
             exchange(
               %{
                 "grant_type" => "authorization_code",
                 "code" => "coverage-protocol-code",
                 "redirect_uri" => "https://client.example.com/callback",
                 "code_verifier" => "coverage-protocol-verifier"
               },
               authorization: basic_auth(client.client_id, secret)
             )

    assert success.token_type == "Bearer"
  end
end
