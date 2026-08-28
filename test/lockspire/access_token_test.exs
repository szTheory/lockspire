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

  describe "semantic readers" do
    test "normalizes subject and scopes while preserving exact audience identifiers" do
      claims = %{
        "sub" => "  user-123  ",
        "scope" => " read:invoices  write:invoices read:invoices ",
        "aud" => [" billing-api ", "ledger-api", "billing-api"]
      }

      token = %AccessToken{claims: claims}

      assert AccessToken.subject(token) == "user-123"
      assert AccessToken.scopes(token) == ["read:invoices", "write:invoices"]
      assert AccessToken.audiences(token) == [" billing-api ", "ledger-api", "billing-api"]
      assert token.claims == claims
    end

    test "semantic readers are total for missing, blank, and malformed claim shapes" do
      for claims <- [
            nil,
            %{},
            %{"sub" => "   ", "scope" => ["read"], "aud" => nil},
            %{"sub" => 42, "scope" => 42, "aud" => "   "},
            %{"sub" => %{}, "scope" => %{}, "aud" => []},
            %{"sub" => [], "scope" => nil, "aud" => ["billing-api", 42]}
          ] do
        token = %AccessToken{claims: claims}

        assert AccessToken.subject(token) == nil
        assert AccessToken.scopes(token) == []
        assert AccessToken.audiences(token) == []
      end
    end

    test "rejects a mixed audience list containing a blank identifier" do
      token = %AccessToken{claims: %{"aud" => ["billing-api", "   "]}}

      assert AccessToken.audiences(token) == []
      assert {:error, :invalid_audience} = AccessToken.normalize_audiences(token.claims)
    end

    test "normalizes integer NumericDate expiration and allowlisted confirmation values" do
      token = %AccessToken{
        claims: %{
          "exp" => 1_700_000_000,
          "cnf" => %{
            "jkt" => " proof-thumbprint ",
            "x5t#S256" => " certificate-thumbprint ",
            "unrelated" => "must-not-leak"
          }
        }
      }

      assert AccessToken.expires_at(token) == ~U[2023-11-14 22:13:20Z]

      assert AccessToken.confirmation(token) == %{
               dpop_jkt: "proof-thumbprint",
               mtls_x5t_s256: "certificate-thumbprint"
             }
    end

    test "expiration and confirmation readers are total and never disclose malformed or unknown values" do
      for claims <- [
            %{"exp" => "1700000000", "cnf" => nil},
            %{"exp" => 1.7e9, "cnf" => %{}},
            %{"exp" => 999_999_999_999_999_999_999, "cnf" => %{"unrelated" => "value"}},
            %{"cnf" => %{"jkt" => "  ", "x5t#S256" => 42}},
            %{"cnf" => ["not-a-map"]}
          ] do
        token = %AccessToken{claims: claims}

        assert AccessToken.expires_at(token) == nil
        assert AccessToken.confirmation(token) == nil
      end
    end
  end
end
