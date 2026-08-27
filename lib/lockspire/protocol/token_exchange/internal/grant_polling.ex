defmodule Lockspire.Protocol.TokenExchange.Internal.GrantPolling do
  @moduledoc false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Security.Policy

  def fetch_device(params, %Client{} = client, %Dependencies{} = dependencies) do
    poll(
      params,
      client,
      dependencies,
      "device_code",
      :device_authorization_store,
      :device_authorization,
      DeviceAuthorization,
      "device authorization"
    )
  end

  def fetch_ciba(params, %Client{} = client, %Dependencies{} = dependencies) do
    poll(
      params,
      client,
      dependencies,
      "auth_req_id",
      :ciba_authorization_store,
      :ciba_authorization,
      CibaAuthorization,
      "CIBA authorization"
    )
  end

  defp poll(
         params,
         client,
         dependencies,
         param,
         store_field,
         authorization_key,
         authorization_module,
         label
       ) do
    with {:ok, value} <- presented_code(params, param),
         {:ok, outcome} <- record_poll(value, client, dependencies, store_field, label) do
      map_outcome(outcome, client, authorization_key, authorization_module, label)
    end
  end

  defp presented_code(params, "device_code") do
    present(params["device_code"], "device_code is required", :missing_device_code)
  end

  defp presented_code(params, "auth_req_id") do
    present(params["auth_req_id"], "auth_req_id is required", :missing_auth_req_id)
  end

  defp present(value, description, reason_code) when is_binary(value) do
    case String.trim(value) do
      "" -> {:error, invalid_grant(description, reason_code)}
      normalized -> {:ok, normalized}
    end
  end

  defp present(_value, description, reason_code),
    do: {:error, invalid_grant(description, reason_code)}

  defp record_poll(value, client, dependencies, :device_authorization_store, _label) do
    case dependencies.device_authorization_store.record_device_poll(
           Policy.hash_token(value),
           client.client_id,
           dependencies.now.()
         ) do
      {:ok, %{} = outcome} ->
        {:ok, outcome}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to evaluate device authorization polling state",
           :device_authorization_lookup_failed
         )}
    end
  end

  defp record_poll(value, client, dependencies, :ciba_authorization_store, _label) do
    case dependencies.ciba_authorization_store.record_ciba_poll(
           Policy.hash_token(value),
           client.client_id,
           dependencies.now.()
         ) do
      {:ok, %{} = outcome} ->
        {:ok, outcome}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to evaluate CIBA polling state",
           :ciba_authorization_lookup_failed
         )}
    end
  end

  defp map_outcome(%{result: :approved_ready} = outcome, _client, key, module, _label) do
    case Map.fetch(outcome, key) do
      {:ok, authorization} when is_struct(authorization, module) -> {:ok, authorization}
      :error -> {:error, invalid_grant("The authorization is invalid", :authorization_not_found)}
    end
  end

  defp map_outcome(%{result: result} = outcome, %Client{} = client, key, module, label)
       when result in [:pending, :slow_down, :denied, :expired, :client_mismatch, :consumed] do
    case Map.fetch(outcome, key) do
      {:ok, authorization} when is_struct(authorization, module) ->
        {:error, result_error(result, label), authorization, client}

      :error ->
        {:error, result_error(result, label)}
    end
  end

  defp map_outcome(%{result: :client_mismatch}, _client, _key, _module, label),
    do:
      {:error,
       invalid_grant("The #{label} is invalid for this client", reason(label, :client_mismatch))}

  defp map_outcome(%{result: :invalid_grant}, _client, _key, _module, label),
    do: {:error, invalid_grant("The #{label} is invalid", reason(label, :not_found))}

  defp result_error(:pending, label),
    do:
      oauth_error(
        400,
        "authorization_pending",
        "The #{label} is still pending approval",
        reason(label, :pending)
      )

  defp result_error(:slow_down, label),
    do:
      oauth_error(
        400,
        "slow_down",
        "The client is polling too quickly",
        reason(label, :slow_down)
      )

  defp result_error(:denied, label),
    do: oauth_error(400, "access_denied", "The #{label} was denied", reason(label, :denied))

  defp result_error(:expired, label),
    do: oauth_error(400, "expired_token", "The #{label} has expired", reason(label, :expired))

  defp result_error(:client_mismatch, label),
    do: invalid_grant("The #{label} is invalid for this client", reason(label, :client_mismatch))

  defp result_error(:consumed, label),
    do: invalid_grant("The #{label} has already been redeemed", reason(label, :consumed))

  defp reason("device authorization", suffix),
    do: String.to_atom("device_authorization_#{suffix}")

  defp reason("CIBA authorization", suffix), do: String.to_atom("ciba_authorization_#{suffix}")

  defp invalid_grant(description, reason_code),
    do: oauth_error(400, "invalid_grant", description, reason_code)

  defp oauth_error(status, error, description, reason_code),
    do: %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
end
