defmodule Lockspire.Protocol.RequestObject.Retrieval do
  @moduledoc false

  @allowed_outer_keys ~w(client_id request)

  @type reason ::
          :request_object_and_request_uri_conflict | :request_object_conflict | :missing_request

  @spec fetch(map()) :: {:ok, String.t()} | {:error, reason()}
  def fetch(params) when is_map(params) do
    with :ok <- reject_request_uri_collision(params),
         :ok <- reject_outer_param_conflicts(params) do
      fetch_inline_request(params)
    end
  end

  defp reject_request_uri_collision(%{"request_uri" => request_uri}) do
    if present?(request_uri), do: {:error, :request_object_and_request_uri_conflict}, else: :ok
  end

  defp reject_request_uri_collision(_params), do: :ok

  defp reject_outer_param_conflicts(params) do
    has_conflict? =
      Enum.any?(params, fn {key, value} -> key not in @allowed_outer_keys and present?(value) end)

    if has_conflict?, do: {:error, :request_object_conflict}, else: :ok
  end

  defp fetch_inline_request(%{"request" => request}) when is_binary(request) and request != "",
    do: {:ok, request}

  defp fetch_inline_request(_params), do: {:error, :missing_request}

  defp present?(value) when value in [nil, ""], do: false
  defp present?(_value), do: true
end
