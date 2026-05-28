defmodule Lockspire.AccessTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.AccessToken

  describe "struct" do
    test "defaults all fields to nil (binding_verified defaults to false, not nil)" do
      token = %AccessToken{}

      assert token.token == nil
      assert token.claims == nil
      assert token.client_id == nil
      assert token.authorization_scheme == nil
      assert token.binding_type == nil
      assert token.binding_requirements == nil
      assert token.error == nil
      assert token.binding_verified == false
    end

    test "allows setting fields" do
      token = %AccessToken{
        token: "foo",
        claims: %{"sub" => "user1"},
        client_id: "client1",
        authorization_scheme: "DPoP",
        binding_type: "dpop+mtls",
        binding_requirements: %{dpop_jkt: "jkt1", mtls_x5t_s256: "thumb1"},
        error: :invalid_token
      }

      assert token.token == "foo"
      assert token.claims == %{"sub" => "user1"}
      assert token.client_id == "client1"
      assert token.authorization_scheme == "DPoP"
      assert token.binding_type == "dpop+mtls"
      assert token.binding_requirements == %{dpop_jkt: "jkt1", mtls_x5t_s256: "thumb1"}
      assert token.error == :invalid_token
    end
  end
end
