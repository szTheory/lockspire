defmodule Lockspire.Protocol.TokenExchange.CharacterizationTest do
  use Lockspire.TokenExchangeCase, async: false

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.TokenExchangeCharacterization

  @moduletag :integration

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
end
