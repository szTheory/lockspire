defmodule Lockspire.Protocol.TokenExchange.CibaAndResourceTest do
  use Lockspire.TokenExchangeCase

  test "returns use_dpop_nonce for ciba exchange before succeeding with the supplied nonce" do
    secret = "ciba-nonce-secret"

    {:ok, client} =
      create_client(
        "client-ciba-nonce",
        :client_secret_basic,
        secret,
        ["urn:openid:params:grant-type:ciba", "refresh_token"],
        %{
          allowed_scopes: ["openid", "email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    {:ok, _authorization} =
      create_ciba_authorization(client,
        auth_req_id: "ciba-auth-req-nonce",
        scopes: ["email", "profile", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    %{jwt: proof_without_nonce} = dpop_proof_fixture(nonce: nil)

    assert {:error, error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "ciba-auth-req-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_without_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 ciba_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository
               ]
             })

    assert error.error == "use_dpop_nonce"
    assert error.reason_code == :missing_dpop_nonce
    assert is_binary(error.dpop_nonce)

    %{jwt: proof_with_nonce, validated: validated_proof} = dpop_proof_fixture(error.dpop_nonce)

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "ciba-auth-req-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_with_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 ciba_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "ciba-nonce-access-token" end,
                 refresh_token_generator: fn -> "ciba-nonce-refresh-token" end
               ]
             })

    assert success.token_type == "DPoP"

    persisted_access_token =
      Lockspire.TestRepo.one!(
        from(token in TokenRecord,
          where:
            token.token_type == :access_token and
              token.client_id == ^client.client_id and
              token.token_hash == ^TokenFormatter.hash_token(success.access_token)
        )
      )

    assert persisted_access_token.cnf["jkt"] == validated_proof.jkt
  end

  test "CIBA flow with resource= mints an at+jwt whose aud == [resource] (AUD-01)" do
    secret = "ciba-resource-secret"
    publish_signing_key("kid-ciba-resource")

    {:ok, client} =
      create_client(
        "client-ciba-resource",
        :client_secret_basic,
        secret,
        ["urn:openid:params:grant-type:ciba"],
        %{allowed_scopes: ["openid", "email", "profile"]}
      )

    {:ok, _authorization} =
      create_ciba_authorization(client,
        auth_req_id: "ciba-auth-req-resource",
        scopes: ["openid", "email", "profile"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "ciba-auth-req-resource",
                 "resource" => "https://api.ciba.example.com"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 ciba_authorization_store: Repository
               ]
             })

    {_header, claims} = verify_at_jwt(success.access_token)
    assert claims["aud"] == ["https://api.ciba.example.com"]
  end

  test "CIBA flow without resource= mints an at+jwt whose aud == [client_id] (AUD-02)" do
    secret = "ciba-no-resource-secret"
    publish_signing_key("kid-ciba-no-resource")

    {:ok, client} =
      create_client(
        "client-ciba-no-resource",
        :client_secret_basic,
        secret,
        ["urn:openid:params:grant-type:ciba"],
        %{allowed_scopes: ["openid", "email", "profile"]}
      )

    {:ok, _authorization} =
      create_ciba_authorization(client,
        auth_req_id: "ciba-auth-req-no-resource",
        scopes: ["openid", "email", "profile"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "ciba-auth-req-no-resource"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 ciba_authorization_store: Repository
               ]
             })

    {_header, claims} = verify_at_jwt(success.access_token)
    assert claims["aud"] == [client.client_id]
  end

  test "device/CIBA validate_grant_resources rejects an out-of-set resource with invalid_target when the grant carries a recorded audience" do
    # Exercises the device/CIBA invalid_target branch directly. Device/CIBA grants
    # carry no recorded audience through the public flow today, so the rejection
    # branch is exercised here against a grant token seeded with a recorded
    # audience — proving validate_grant_resources/2 rejects unauthorized resources
    # (T-99-11) rather than silently falling through to [client_id].
    grant_with_audience = %Token{audience: ["https://api.allowed.example.com"]}

    assert {:error, error} =
             TokenExchange.validate_grant_resources_for_test(
               %{"resource" => "https://api.evil.example.com"},
               grant_with_audience
             )

    assert error.status == 400
    assert error.error == "invalid_target"
    assert error.reason_code == :invalid_resource

    # And it accepts an in-set resource.
    assert {:ok, ["https://api.allowed.example.com"]} =
             TokenExchange.validate_grant_resources_for_test(
               %{"resource" => "https://api.allowed.example.com"},
               grant_with_audience
             )

    # And it accepts ANY binary resource when the grant carries no recorded audience.
    assert {:ok, ["https://anything.example.com"]} =
             TokenExchange.validate_grant_resources_for_test(
               %{"resource" => "https://anything.example.com"},
               %Token{audience: []}
             )
  end
end
