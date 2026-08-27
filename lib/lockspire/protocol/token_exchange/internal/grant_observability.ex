defmodule Lockspire.Protocol.TokenExchange.Internal.GrantObservability do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error

  @doc false
  def authorization_code_redemption_audit_event(%Client{} = client, %Token{} = authorization_code) do
    authorization_code_audit_event(
      :authorization_code_redeemed,
      :succeeded,
      :authorization_code_redeemed,
      client,
      authorization_code
    )
  end

  @doc false
  def record_authorization_code_failure(
        %Error{reason_code: :authorization_code_replayed},
        %Client{} = client,
        %Token{} = authorization_code,
        %Dependencies{} = dependencies
      ) do
    _ =
      dependencies.audit_store.append_audit_event(
        authorization_code_audit_event(
          :authorization_code_replay_detected,
          :denied,
          :authorization_code_replayed,
          client,
          authorization_code
        )
      )

    :ok
  end

  def record_authorization_code_failure(_error, _client, _authorization_code, _dependencies),
    do: :ok

  @doc false
  def emit_authorization_code_success(
        %Client{} = client,
        %Token{} = authorization_code,
        success,
        %Dependencies{} = dependencies
      ) do
    metadata = authorization_code_metadata(client, authorization_code)
    dependencies.observability_emitter.emit(:authorization_code, :redeemed, %{}, metadata)
    dependencies.observability_emitter.emit(:token, :issued, %{}, metadata)

    if is_binary(Map.get(success, :refresh_token)) do
      dependencies.observability_emitter.emit(:refresh_token, :issued, %{}, %{
        client_id: client.client_id,
        interaction_id: authorization_code.interaction_id,
        subject_id: authorization_code.account_id
      })
    end

    :ok
  end

  @doc false
  def emit_authorization_code_failure(
        %Error{} = error,
        params,
        request,
        %Dependencies{} = dependencies
      ) do
    metadata = failure_metadata(error, params, request)

    if error.reason_code == :authorization_code_replayed do
      dependencies.observability_emitter.emit(
        :authorization_code,
        :replay_detected,
        %{},
        metadata
      )
    end

    dependencies.observability_emitter.emit(:token_exchange, :failed, %{}, metadata)
    :ok
  end

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

  @doc false
  def poll_redemption_audit_event(%Client{} = client, authorization)
      when is_struct(authorization, DeviceAuthorization) or
             is_struct(authorization, CibaAuthorization) do
    poll_audit_event(
      :redeemed,
      :succeeded,
      redemption_reason(authorization),
      client,
      authorization
    )
  end

  @doc false
  def poll_failure_audit_event(%Error{} = error, %Client{} = client, authorization)
      when is_struct(authorization, DeviceAuthorization) or
             is_struct(authorization, CibaAuthorization) do
    poll_audit_event(:replay_detected, :denied, error.reason_code, client, authorization)
  end

  @doc false
  def emit_poll_success(
        %Client{} = client,
        authorization,
        success,
        %Dependencies{} = dependencies
      )
      when is_struct(authorization, DeviceAuthorization) or
             is_struct(authorization, CibaAuthorization) do
    metadata = poll_metadata(client, authorization, redemption_reason(authorization))
    dependencies.observability_emitter.emit(:token, :issued, %{}, metadata)

    if is_binary(Map.get(success, :refresh_token)) do
      dependencies.observability_emitter.emit(:refresh_token, :issued, %{}, %{
        client_id: client.client_id,
        subject_id: authorization.subject_id
      })
    end

    :ok
  end

  @doc false
  def emit_poll_failure(%Error{} = error, params, request, %Dependencies{} = dependencies) do
    metadata = failure_metadata(error, params, request)
    dependencies.observability_emitter.emit(:token_exchange, :failed, %{}, metadata)
    :ok
  end

  defp authorization_code_metadata(%Client{} = client, %Token{} = authorization_code) do
    %{
      client_id: client.client_id,
      interaction_id: authorization_code.interaction_id,
      subject_id: authorization_code.account_id,
      authorization_code_id: authorization_code.id,
      reason_code: :authorization_code_redeemed,
      token_type: :access_token
    }
  end

  defp authorization_code_audit_event(
         action,
         outcome,
         reason_code,
         %Client{} = client,
         %Token{} = code
       ) do
    %{
      action: action,
      outcome: outcome,
      reason_code: reason_code,
      actor: %{type: :client, id: client.client_id, display: client.client_id},
      resource: %{type: :authorization_code, id: to_string(code.id || code.interaction_id)},
      metadata: %{
        client_id: code.client_id,
        interaction_id: code.interaction_id,
        subject_id: code.account_id
      }
    }
  end

  defp failure_metadata(%Error{} = error, params, request) do
    request_client_id(request)
    |> then(fn client_id ->
      %{
        client_id: client_id,
        reason_code: error.reason_code,
        error: error.error,
        grant_type: params["grant_type"]
      }
    end)
  end

  defp request_client_id(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

    case params["client_id"] do
      value when is_binary(value) -> String.trim(value) |> blank_to_nil()
      _other -> nil
    end
  end

  defp redemption_reason(%DeviceAuthorization{}), do: :device_authorization_redeemed
  defp redemption_reason(%CibaAuthorization{}), do: :ciba_authorization_redeemed

  defp poll_audit_event(action, outcome, reason_code, %Client{} = client, authorization) do
    %{
      action: poll_action(authorization, action),
      outcome: outcome,
      reason_code: reason_code,
      actor: %{type: :client, id: client.client_id, display: client.client_id},
      resource: poll_resource(authorization),
      metadata: poll_audit_metadata(authorization)
    }
  end

  defp poll_action(%DeviceAuthorization{}, :redeemed), do: :device_authorization_redeemed

  defp poll_action(%DeviceAuthorization{}, :replay_detected),
    do: :device_authorization_replay_detected

  defp poll_action(%CibaAuthorization{}, :redeemed), do: :ciba_authorization_redeemed

  defp poll_action(%CibaAuthorization{}, :replay_detected),
    do: :ciba_authorization_replay_detected

  defp poll_resource(%DeviceAuthorization{} = authorization),
    do: %{
      type: :device_authorization,
      id: to_string(authorization.id || authorization.verification_handle)
    }

  defp poll_resource(%CibaAuthorization{} = authorization),
    do: %{
      type: :ciba_authorization,
      id: to_string(authorization.id || authorization.auth_req_id_hash)
    }

  defp poll_audit_metadata(%DeviceAuthorization{} = authorization),
    do: %{
      client_id: authorization.client_id,
      subject_id: authorization.subject_id,
      verification_handle: authorization.verification_handle
    }

  defp poll_audit_metadata(%CibaAuthorization{} = authorization),
    do: %{
      client_id: authorization.client_id,
      subject_id: authorization.subject_id,
      auth_req_id_hash: authorization.auth_req_id_hash
    }

  defp poll_metadata(%Client{} = client, %DeviceAuthorization{} = authorization, reason_code),
    do: %{
      client_id: client.client_id,
      subject_id: authorization.subject_id,
      device_authorization_id: authorization.id,
      reason_code: reason_code,
      token_type: :access_token
    }

  defp poll_metadata(%Client{} = client, %CibaAuthorization{} = authorization, reason_code),
    do: %{
      client_id: client.client_id,
      subject_id: authorization.subject_id,
      ciba_authorization_id: authorization.id,
      reason_code: reason_code,
      token_type: :access_token
    }

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
