defmodule Lockspire.Protocol.TokenExchange.DeviceCodeTest do
  use Lockspire.TokenExchangeCase

  test "maps pending, slow_down, denied, expired, and unknown device polls into RFC 8628 token errors" do
    public_client =
      create_public_client("device-public-client", [
        "urn:ietf:params:oauth:grant-type:device_code"
      ])

    dpop_public_client =
      create_public_client("device-dpop-public-client", [
        "urn:ietf:params:oauth:grant-type:device_code"
      ])

    update_client_dpop_policy!(dpop_public_client.client_id, :dpop)

    confidential_secret = "device-confidential-secret"

    {:ok, confidential_client} =
      create_client(
        "device-confidential-client",
        :client_secret_basic,
        confidential_secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, pending} =
      create_device_authorization(public_client,
        device_code: "device-code-pending",
        user_code: "PEND-ING1"
      )

    assert {:error, pending_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "client_id" => public_client.client_id,
                 "device_code" => "device-code-pending"
               },
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> pending.next_poll_allowed_at end
               ]
             })

    assert pending_error.error == "authorization_pending"
    assert pending_error.reason_code == :device_authorization_pending

    {:ok, dpop_pending} =
      create_device_authorization(dpop_public_client,
        device_code: "device-code-dpop-pending",
        user_code: "DPND-ING1"
      )

    assert {:error, dpop_pending_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "client_id" => dpop_public_client.client_id,
                 "device_code" => "device-code-dpop-pending"
               },
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> dpop_pending.next_poll_allowed_at end
               ]
             })

    assert dpop_pending_error.error == "authorization_pending"
    assert dpop_pending_error.reason_code == :device_authorization_pending

    {:ok, too_early} =
      create_device_authorization(confidential_client,
        device_code: "device-code-too-early",
        user_code: "SLOW-DOWN"
      )

    assert {:error, slow_down_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-too-early"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> DateTime.add(too_early.next_poll_allowed_at, -1, :second) end
               ]
             })

    assert slow_down_error.error == "slow_down"
    assert slow_down_error.reason_code == :device_authorization_slow_down

    {:ok, denied} =
      create_device_authorization(confidential_client,
        device_code: "device-code-denied",
        user_code: "DENI-ED01",
        transition: %{status: :denied, denied_at: DateTime.utc_now()}
      )

    assert {:error, denied_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-denied"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository
               ]
             })

    assert denied_error.error == "access_denied"
    assert denied_error.reason_code == :device_authorization_denied

    {:ok, _expired} =
      create_device_authorization(confidential_client,
        device_code: "device-code-expired",
        user_code: "EXPI-RED1",
        transition: %{status: :expired, expired_at: DateTime.utc_now()}
      )

    assert {:error, expired_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-expired"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository
               ]
             })

    assert expired_error.error == "expired_token"
    assert expired_error.reason_code == :device_authorization_expired

    assert {:error, invalid_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "unknown-device-code"
               },
               authorization: basic_auth(confidential_client.client_id, confidential_secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository
               ]
             })

    assert invalid_error.error == "invalid_grant"
    assert invalid_error.reason_code == :device_authorization_not_found

    refute pending.verification_handle == denied.verification_handle
  end

  test "maps approved-but-expired device authorizations to expired_token" do
    secret = "device-approved-expired-secret"

    {:ok, client} =
      create_client(
        "device-approved-expired-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    issued_at = DateTime.add(DateTime.utc_now(), -310, :second)

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-approved-expired",
        user_code: "EXPR-APPR",
        now: issued_at,
        transition: %{
          status: :approved,
          approved_at: issued_at,
          subject_id: "subject-123"
        }
      )

    assert {:error, expired_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-approved-expired"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 device_authorization_store: Repository,
                 token_store: Repository,
                 now: fn -> DateTime.utc_now() end
               ]
             })

    assert expired_error.error == "expired_token"
    assert expired_error.reason_code == :device_authorization_expired
  end

  test "redeems an approved device authorization through the shared token success pipeline" do
    secret = "device-success-secret"

    {:ok, client} =
      create_client(
        "device-success-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"],
        %{access_token_format: :opaque}
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-approved",
        user_code: "APPR-OVED",
        scopes: ["email", "profile"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-approved"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    # :opaque opt-in: the signer mints the opaque token (the legacy
    # access_token_generator seam no longer drives access-token minting), so the
    # issued token is a non-empty binary that is not a JOSE at+jwt.
    assert is_binary(success.access_token)
    refute opaque_token_is_at_jwt?(success.access_token)
    assert success.token_type == "Bearer"
    assert success.scope == "email profile"
    assert success.refresh_token == nil
    assert success.id_token == nil

    assert {:ok, %DeviceAuthorization{status: :consumed}} =
             Repository.fetch_device_authorization_by_device_code_hash(
               TokenFormatter.hash_token("device-code-approved")
             )
  end

  test "redeems an approved DPoP device authorization with token_type DPoP and persisted cnf" do
    secret = "device-dpop-secret"

    {:ok, client} =
      create_client(
        "device-dpop-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
        %{
          allowed_scopes: ["email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-dpop-approved",
        user_code: "DP0P-000",
        scopes: ["email", "profile", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    %{jwt: proof_jwt, validated: validated_proof} = dpop_proof_fixture()

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-dpop-approved"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_jwt,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "device-dpop-access-token" end,
                 refresh_token_generator: fn -> "device-dpop-refresh-token" end
               ]
             })

    assert success.token_type == "DPoP"

    assert {:ok, %Token{} = persisted_refresh_token} =
             Repository.fetch_refresh_token(
               TokenFormatter.hash_token("device-dpop-refresh-token")
             )

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
    assert persisted_refresh_token.cnf["jkt"] == validated_proof.jkt
  end

  test "returns use_dpop_nonce for device-code exchange before succeeding with the supplied nonce" do
    secret = "device-nonce-secret"

    {:ok, client} =
      create_client(
        "device-dpop-nonce-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
        %{
          allowed_scopes: ["email", "profile", "offline_access"],
          dpop_policy: :dpop,
          access_token_format: :opaque
        }
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-dpop-nonce",
        user_code: "DPOP-NNC",
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
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-dpop-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_without_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
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
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-dpop-nonce"
               },
               authorization: basic_auth(client.client_id, secret),
               dpop: proof_with_nonce,
               method: "POST",
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 server_policy_store: Repository,
                 dpop_replay_store: Repository,
                 access_token_generator: fn -> "device-nonce-access-token" end,
                 refresh_token_generator: fn -> "device-nonce-refresh-token" end
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

  test "device flow with resource= mints an at+jwt whose aud == [resource] (AUD-01)" do
    secret = "device-resource-secret"
    publish_signing_key("kid-device-resource")

    {:ok, client} =
      create_client(
        "device-resource-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-resource",
        user_code: "RES-0001",
        scopes: ["email", "profile"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-resource",
                 "resource" => "https://api.device.example.com"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    {_header, claims} = verify_at_jwt(success.access_token)
    assert claims["aud"] == ["https://api.device.example.com"]
  end

  test "device flow without resource= mints an at+jwt whose aud == [client_id] (AUD-02)" do
    secret = "device-no-resource-secret"
    publish_signing_key("kid-device-no-resource")

    {:ok, client} =
      create_client(
        "device-no-resource-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-no-resource",
        user_code: "NORES001",
        scopes: ["email", "profile"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-no-resource"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    {_header, claims} = verify_at_jwt(success.access_token)
    assert claims["aud"] == [client.client_id]
  end

  test "preserves bearer token_type for approved bearer-mode device authorization" do
    secret = "device-bearer-secret"
    publish_signing_key("kid-device-bearer")

    {:ok, client} =
      create_client(
        "device-bearer-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _approved} =
      create_device_authorization(client,
        device_code: "device-code-bearer-approved",
        user_code: "BEAR-000",
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-bearer-approved"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 access_token_generator: fn -> "device-bearer-access-token" end
               ]
             })

    assert success.token_type == "Bearer"
  end

  test "device grants redeem once, collapse replay to invalid_grant, and append durable device audit rows" do
    secret = "device-replay-secret"
    publish_signing_key("kid-device-replay")

    {:ok, client} =
      create_client(
        "device-replay-client",
        :client_secret_basic,
        secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, authorization} =
      create_device_authorization(client,
        device_code: "device-code-replay",
        user_code: "REPL-AY01",
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    request = %{
      params: %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => "device-code-replay"
      },
      authorization: basic_auth(client.client_id, secret),
      opts: [
        client_store: Repository,
        token_store: Repository,
        interaction_store: Repository,
        key_store: Repository,
        device_authorization_store: Repository,
        access_token_generator: fn -> "device-replay-access-token" end
      ]
    }

    assert {:ok, _success} = TokenExchange.exchange(request)
    assert {:error, replay_error} = TokenExchange.exchange(request)
    assert replay_error.error == "invalid_grant"
    assert replay_error.reason_code == :device_authorization_consumed

    audits =
      Lockspire.TestRepo.all(AuditEventRecord)
      |> Enum.filter(&(&1.actor_id == client.client_id))

    assert Enum.any?(audits, fn audit ->
             audit.action == "device_authorization_redeemed" and
               audit.resource_type == "device_authorization" and
               audit.resource_id == Integer.to_string(authorization.id) and
               audit.reason_code == "device_authorization_redeemed"
           end)

    assert Enum.any?(audits, fn audit ->
             audit.action == "device_authorization_replay_detected" and
               audit.resource_type == "device_authorization" and
               audit.resource_id == Integer.to_string(authorization.id) and
               audit.reason_code == "device_authorization_consumed"
           end)
  end

  test "device grants preserve shared refresh and id_token policy while collapsing client mismatch to invalid_grant" do
    publish_signing_key("kid-device-openid")

    refresh_secret = "device-openid-secret"

    {:ok, refresh_client} =
      create_client(
        "device-openid-client",
        :client_secret_basic,
        refresh_secret,
        ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"]
      )

    {:ok, _approved_openid} =
      create_device_authorization(refresh_client,
        device_code: "device-code-openid",
        user_code: "OPEN-ID01",
        scopes: ["openid", "email", "offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, refresh_success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-openid"
               },
               authorization: basic_auth(refresh_client.client_id, refresh_secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository,
                 access_token_generator: fn -> "device-openid-access-token" end,
                 refresh_token_generator: fn -> "device-openid-refresh-token" end
               ]
             })

    assert refresh_success.refresh_token == "device-openid-refresh-token"
    assert is_binary(refresh_success.id_token)

    {:ok, no_refresh_client} =
      create_client(
        "device-no-refresh-client",
        :client_secret_basic,
        "device-no-refresh-secret",
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _approved_no_refresh} =
      create_device_authorization(no_refresh_client,
        device_code: "device-code-no-refresh",
        user_code: "NORE-FRSH",
        scopes: ["offline_access"],
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:ok, no_refresh_success} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-no-refresh"
               },
               authorization: basic_auth(no_refresh_client.client_id, "device-no-refresh-secret"),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    assert no_refresh_success.refresh_token == nil

    mismatch_secret = "device-mismatch-secret"

    {:ok, other_client} =
      create_client(
        "device-other-client",
        :client_secret_basic,
        mismatch_secret,
        ["urn:ietf:params:oauth:grant-type:device_code"]
      )

    {:ok, _mismatch_approved} =
      create_device_authorization(refresh_client,
        device_code: "device-code-mismatch",
        user_code: "MISM-ATCH",
        transition: %{
          status: :approved,
          approved_at: DateTime.utc_now(),
          subject_id: "subject-123"
        }
      )

    assert {:error, mismatch_error} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "device-code-mismatch"
               },
               authorization: basic_auth(other_client.client_id, mismatch_secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 interaction_store: Repository,
                 key_store: Repository,
                 device_authorization_store: Repository
               ]
             })

    assert mismatch_error.error == "invalid_grant"
    assert mismatch_error.reason_code == :device_authorization_client_mismatch
  end
end
