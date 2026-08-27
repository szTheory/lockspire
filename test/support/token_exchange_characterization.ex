defmodule Lockspire.TokenExchangeCharacterization do
  @moduledoc false

  import Ecto.Query
  import ExUnit.Assertions

  alias Lockspire.Protocol.TokenExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord
  alias Lockspire.TokenExchangeCase

  def authorization_code_journey(name) do
    secret = "#{name}-secret"
    client_id = "#{name}-client"
    code = "#{name}-raw-code"
    verifier = "#{name}-verifier"

    assert {:ok, _key} = TokenExchangeCase.publish_signing_key("#{name}-kid")

    assert {:ok, client} =
             TokenExchangeCase.create_client(
               client_id,
               :client_secret_basic,
               secret,
               ["authorization_code", "refresh_token"]
             )

    assert {:ok, authorization_code} =
             TokenExchangeCase.create_authorization_code(client,
               raw_code: code,
               code_verifier: verifier,
               scopes: ["email", "offline_access"]
             )

    %{
      client: client,
      authorization_code: authorization_code,
      code: code,
      secret: secret,
      request: %{
        params: %{
          "grant_type" => "authorization_code",
          "code" => code,
          "redirect_uri" => "https://client.example.com/callback",
          "code_verifier" => verifier
        },
        authorization: TokenExchangeCase.basic_auth(client_id, secret),
        method: "POST",
        opts: [
          client_store: Repository,
          token_store: Repository,
          interaction_store: Repository,
          key_store: Repository,
          server_policy_store: Repository,
          now: fn -> DateTime.utc_now() end,
          access_token_generator: fn -> "#{name}-access-token" end,
          refresh_token_generator: fn -> "#{name}-refresh-token" end
        ]
      }
    }
  end

  def assert_authorization_code_success(journey, %TokenExchange.Success{} = success, events) do
    assert is_binary(success.access_token)
    assert success.access_token != ""
    assert success.refresh_token == "#{String.replace_suffix(journey.code, "-raw-code", "")}-refresh-token"

    assert %TokenRecord{} =
             Lockspire.TestRepo.one!(
               from(token in TokenRecord,
                 where:
                   token.token_type == :access_token and
                     token.client_id == ^journey.client.client_id and
                     token.token_hash == ^TokenFormatter.hash_token(success.access_token)
               )
             )

    assert {:ok, refresh_token} =
             Repository.fetch_refresh_token(TokenFormatter.hash_token(success.refresh_token))

    assert refresh_token.client_id == journey.client.client_id

    assert_audit(journey, "authorization_code_redeemed", "authorization_code_redeemed")
    assert_event(events, [:lockspire, :authorization_code, :redeemed], :authorization_code_redeemed)
    refute_observability_leaks(events, [journey.secret, success.access_token, success.refresh_token])
  end

  def assert_authorization_code_replay(journey, %TokenExchange.Error{} = replay, events) do
    assert_audit(journey, "authorization_code_replay_detected", "authorization_code_replayed")
    assert_event(
      events,
      [:lockspire, :authorization_code, :replay_detected],
      :authorization_code_replayed
    )

    refute_observability_leaks(events, [journey.secret])
  end

  def assert_remaining_grant_contracts(_events) do
    journey = authorization_code_journey("characterization-refresh")
    assert {:ok, initial} = TokenExchange.exchange(journey.request)

    refresh_request = %{
      params: %{"grant_type" => "refresh_token", "refresh_token" => initial.refresh_token},
      authorization: journey.request.authorization,
      method: "POST",
      opts:
        Keyword.put(
          journey.request.opts,
          :refresh_token_generator,
          fn -> "characterization-refresh-rotated-token" end
        )
    }

    assert {:ok, _rotated} = TokenExchange.exchange(refresh_request)
  end

  defp assert_audit(journey, action, reason_code) do
    assert %AuditEventRecord{
             action: ^action,
             reason_code: ^reason_code,
             actor_type: "client",
             actor_id: client_id,
             resource_type: "authorization_code",
             resource_id: resource_id
           } =
             Lockspire.TestRepo.one!(
               from(audit in AuditEventRecord,
                 where: audit.action == ^action and audit.actor_id == ^journey.client.client_id
               )
             )

    assert client_id == journey.client.client_id
    assert resource_id == Integer.to_string(journey.authorization_code.id)
  end

  defp assert_event(events, name, reason_code) do
    assert Enum.any?(Agent.get(events, & &1), fn {event, metadata} ->
             event == name and metadata[:reason_code] == reason_code
           end)
  end

  defp refute_observability_leaks(events, secrets) do
    observation = inspect(Agent.get(events, & &1))
    Enum.each(secrets, &refute(String.contains?(observation, &1)))
  end
end
