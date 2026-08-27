defmodule Lockspire.Protocol.TokenExchange.CharacterizationTest do
  use Lockspire.TokenExchangeCase, async: false

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.TokenExchangeCharacterization

  @moduletag :integration

  defmodule AllowTokenExchange do
    def validate(_context), do: :ok
  end

  defmodule DenyTokenExchange do
    def validate(_context), do: {:error, :policy_denied}
  end

  test "authorization-code facade preserves token, audit, telemetry, and replay contracts", %{
    events: events
  } do
    journey = TokenExchangeCharacterization.authorization_code_journey("characterization-code")

    assert {:ok, %TokenExchange.Success{} = success} = TokenExchange.exchange(journey.request)
    assert success.token_type == "Bearer"
    assert success.access_token
    assert success.refresh_token

    TokenExchangeCharacterization.assert_authorization_code_success(journey, success, events)

    assert {:error, %TokenExchange.Error{} = replay} = TokenExchange.exchange(journey.request)
    assert replay.error == "invalid_grant"
    assert replay.reason_code == :authorization_code_replayed

    TokenExchangeCharacterization.assert_authorization_code_replay(journey, replay, events)
  end

  test "the remaining stable facade grants retain their observable contracts", %{events: events} do
    TokenExchangeCharacterization.assert_remaining_grant_contracts(events)
  end

  test "device and CIBA public facade grants retain success and pending classifications" do
    secret = "characterization-polling-secret"

    assert {:ok, client} =
             create_client(
               "characterization-polling-client",
               :client_secret_basic,
               secret,
               [
                 "urn:ietf:params:oauth:grant-type:device_code",
                 "urn:openid:params:grant-type:ciba"
               ],
               %{access_token_format: :opaque}
             )

    assert {:ok, _device} =
             create_device_authorization(client,
               device_code: "characterization-device-code",
               user_code: "CHAR-DEV1",
               transition: %{
                 status: :approved,
                 approved_at: DateTime.utc_now(),
                 subject_id: "subject-123"
               }
             )

    assert {:ok, %TokenExchange.Success{access_token: access_token}} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "characterization-device-code"
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

    assert {:ok, _token} =
             Repository.fetch_active_access_token(TokenFormatter.hash_token(access_token))

    assert {:ok, pending_device} =
             create_device_authorization(client,
               device_code: "characterization-device-pending",
               user_code: "CHAR-DEV2"
             )

    assert {:error, %TokenExchange.Error{reason_code: :device_authorization_pending}} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
                 "device_code" => "characterization-device-pending"
               },
               authorization: basic_auth(client.client_id, secret),
               opts: [
                 client_store: Repository,
                 token_store: Repository,
                 device_authorization_store: Repository,
                 now: fn -> pending_device.next_poll_allowed_at end
               ]
             })

    assert {:ok, _ciba} =
             create_ciba_authorization(client,
               auth_req_id: "characterization-ciba-code",
               scopes: ["email", "profile"],
               transition: %{
                 status: :approved,
                 approved_at: DateTime.utc_now(),
                 subject_id: "subject-123"
               }
             )

    assert {:ok, %TokenExchange.Success{access_token: ciba_access_token}} =
             TokenExchange.exchange(%{
               params: %{
                 "grant_type" => "urn:openid:params:grant-type:ciba",
                 "auth_req_id" => "characterization-ciba-code"
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

    assert {:ok, _token} =
             Repository.fetch_active_access_token(TokenFormatter.hash_token(ciba_access_token))
  end

  test "RFC 8693 facade retains allowed issuance and policy denial" do
    secret = "characterization-rfc-secret"

    assert {:ok, client} =
             create_client(
               "characterization-rfc-client",
               :client_secret_basic,
               secret,
               ["urn:ietf:params:oauth:grant-type:token-exchange"],
               %{access_token_format: :opaque}
             )

    now = DateTime.utc_now()

    assert {:ok, _subject_token} =
             Repository.store_token(%Token{
               token_hash: TokenFormatter.hash_token("characterization-rfc-subject"),
               token_type: :access_token,
               client_id: client.client_id,
               account_id: "subject-123",
               scopes: ["email"],
               issued_at: now,
               expires_at: DateTime.add(now, 300, :second)
             })

    request = %{
      params: %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
        "subject_token" => "characterization-rfc-subject",
        "scope" => "email"
      },
      authorization: basic_auth(client.client_id, secret),
      opts: [
        client_store: Repository,
        token_store: Repository,
        key_store: Repository,
        token_exchange_validator: AllowTokenExchange
      ]
    }

    assert {:ok, %TokenExchange.Success{access_token: exchanged_token}} =
             TokenExchange.exchange(request)

    assert {:ok, _persisted} =
             Repository.fetch_active_access_token(TokenFormatter.hash_token(exchanged_token))

    assert {:error, %TokenExchange.Error{error: "access_denied", reason_code: :access_denied}} =
             TokenExchange.exchange(
               put_in(request, [:opts, :token_exchange_validator], DenyTokenExchange)
             )
  end
end
