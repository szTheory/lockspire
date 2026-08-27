defmodule Lockspire.Protocol.TokenExchange.Internal.GrantObservability do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error

  @doc false
  def emit_refresh_success(
        %Client{} = client,
        %Token{} = presented_refresh_token,
        %Token{} = refresh_token,
        %Dependencies{} = dependencies
      ) do
    metadata = %{
      client_id: client.client_id,
      subject_id: refresh_token.account_id,
      family_id: refresh_token.family_id,
      refresh_token_id: refresh_token.id,
      previous_refresh_token_id: presented_refresh_token.id
    }

    dependencies.telemetry.emit(:token, :issued, %{}, metadata)
    dependencies.telemetry.emit(:refresh_token, :issued, %{}, metadata)
  end

  @doc false
  def emit_refresh_failure(%Client{} = client, %Error{} = error, %Dependencies{} = dependencies) do
    metadata = %{
      client_id: client.client_id,
      reason_code: error.reason_code,
      error: error.error,
      grant_type: "refresh_token"
    }

    if error.reason_code == :refresh_token_reuse_detected do
      dependencies.telemetry.emit(:refresh_token, :reuse_detected, %{}, metadata)
    end

    dependencies.telemetry.emit(:token_exchange, :failed, %{}, metadata)
  end
end
