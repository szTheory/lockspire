defmodule Lockspire.Protocol.RefreshExchange do
  @moduledoc """
  Rotates refresh tokens and revokes the full family on reuse.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenExchange.Error
  alias Lockspire.Protocol.TokenExchange.Success
  alias Lockspire.Protocol.TokenFormatter

  @access_token_ttl 3600
  @refresh_token_ttl 2_592_000

  @spec exchange_refresh_token(Client.t(), map()) :: {:ok, Success.t()} | {:error, Error.t()}
  def exchange_refresh_token(%Client{} = client, request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, refresh_token_hash} <- fetch_refresh_token_hash(params),
         {:ok, result} <- rotate_refresh_token(client, refresh_token_hash, request) do
      emit_success(client, result.presented_refresh_token, result.refresh_token)

      {:ok,
       %Success{
         access_token: result.raw_access_token,
         refresh_token: result.raw_refresh_token,
         id_token: nil,
         token_type: result.token_type,
         expires_in: @access_token_ttl,
         scope: Enum.join(result.access_token.scopes, " ")
       }}
    else
      {:error, %Error{} = error} ->
        emit_failure(client, error)
        {:error, error}
    end
  end

  defp fetch_refresh_token_hash(%{"refresh_token" => refresh_token})
       when is_binary(refresh_token) do
    refresh_token
    |> String.trim()
    |> case do
      "" ->
        {:error, invalid_grant("refresh_token is required", :missing_refresh_token)}

      token ->
        {:ok, TokenFormatter.hash_token(token)}
    end
  end

  defp fetch_refresh_token_hash(_params) do
    {:error, invalid_grant("refresh_token is required", :missing_refresh_token)}
  end

  defp rotate_refresh_token(%Client{} = client, refresh_token_hash, request) do
    formatted_access_token =
      TokenFormatter.format_access_token(token_format_options(request, :access_token))

    formatted_refresh_token =
      TokenFormatter.format_refresh_token(token_format_options(request, :refresh_token))

    rotated_at = now(request)

    access_token = %Token{
      token_hash: formatted_access_token.token_hash,
      token_type: :access_token,
      client_id: client.client_id,
      account_id: nil,
      expires_at: DateTime.add(rotated_at, @access_token_ttl, :second)
    }

    refresh_token = %Token{
      token_hash: formatted_refresh_token.token_hash,
      token_type: :refresh_token,
      client_id: client.client_id,
      account_id: nil,
      expires_at: DateTime.add(rotated_at, @refresh_token_ttl, :second)
    }

    case token_store(request).rotate_refresh_token(
           refresh_token_hash,
           client.client_id,
           rotated_at,
           refresh_token,
           access_token
         ) do
      {:ok,
       %{
         presented_refresh_token: %Token{} = presented_refresh_token,
         refresh_token: %Token{} = persisted_refresh_token,
         access_token: %Token{} = persisted_access_token
       }} ->
        {:ok,
         %{
           presented_refresh_token: presented_refresh_token,
           refresh_token: persisted_refresh_token,
           access_token: persisted_access_token,
           raw_access_token: formatted_access_token.token,
           raw_refresh_token: formatted_refresh_token.token,
           token_type: formatted_access_token.token_type
         }}

      {:error, :not_found} ->
        {:error, invalid_grant("Refresh token is invalid", :refresh_token_not_found)}

      {:error, :client_mismatch} ->
        {:error, invalid_grant("Refresh token was not issued to this client", :client_mismatch)}

      {:error, :expired} ->
        {:error, invalid_grant("Refresh token has expired", :refresh_token_expired)}

      {:error, :reuse_detected} ->
        {:error,
         invalid_grant(
           "Refresh token reuse detected; the token family has been revoked",
           :refresh_token_reuse_detected
         )}

      {:error, :missing_family_id} ->
        {:error,
         oauth_error(500, "server_error", "Refresh token family is invalid", :missing_family_id)}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to rotate refresh token",
           :refresh_rotation_failed
         )}
    end
  end

  defp emit_success(
         %Client{} = client,
         %Token{} = presented_refresh_token,
         %Token{} = refresh_token
       ) do
    metadata = %{
      client_id: client.client_id,
      subject_id: refresh_token.account_id,
      family_id: refresh_token.family_id,
      refresh_token_id: refresh_token.id,
      previous_refresh_token_id: presented_refresh_token.id
    }

    Observability.emit(:access_token_issued, %{}, metadata)
    Observability.emit(:refresh_token_issued, %{}, metadata)
  end

  defp emit_failure(%Client{} = client, %Error{} = error) do
    metadata = %{
      client_id: client.client_id,
      reason_code: error.reason_code,
      error: error.error,
      grant_type: "refresh_token"
    }

    if error.reason_code == :refresh_token_reuse_detected do
      Observability.emit(:refresh_token_reuse_detected, %{}, metadata)
    end

    Observability.emit(:token_exchange_failed, %{}, metadata)
  end

  defp invalid_grant(description, reason_code) do
    oauth_error(400, "invalid_grant", description, reason_code)
  end

  defp oauth_error(status, error, description, reason_code) do
    %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
  end

  defp token_store(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.fetch!(:token_store)
  end

  defp token_format_options(request, token_type) do
    generator =
      request
      |> Map.get(:opts, [])
      |> case do
        opts ->
          case Keyword.get(opts, :"#{token_type}_generator", Keyword.get(opts, :token_generator)) do
            nil -> []
            generator -> [token_generator: generator]
          end
      end

    generator
  end

  defp now(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
    |> then(& &1.())
  end
end
