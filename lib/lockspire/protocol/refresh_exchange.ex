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
    with {:ok, %Token{} = presented_refresh_token} <-
           fetch_presented_refresh_token(refresh_token_hash, request) do
      rotate_refresh_token_with_audit(client, refresh_token_hash, presented_refresh_token, request)
    end
  end

  defp rotate_refresh_token_with_audit(
         %Client{} = client,
         refresh_token_hash,
         %Token{} = presented_refresh_token,
         request
       ) do
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

    case transact_with_audit_outcome(token_store(request), fn ->
           case token_store(request).rotate_refresh_token(
                  refresh_token_hash,
                  client.client_id,
                  rotated_at,
                  refresh_token,
                  access_token
                ) do
             {:ok,
              %{
                presented_refresh_token: %Token{} = presented,
                refresh_token: %Token{} = persisted_refresh_token,
                access_token: %Token{}
              } = success} ->
               {:ok,
                success,
                [refresh_rotation_audit_event(client, presented, persisted_refresh_token)]}

             {:error, :reuse_detected} ->
               {:durable_error,
                invalid_grant(
                  "Refresh token reuse detected; the token family has been revoked",
                  :refresh_token_reuse_detected
                ),
                reuse_audit_events(client, presented_refresh_token)}

             {:error, :not_found} ->
               {:error, invalid_grant("Refresh token is invalid", :refresh_token_not_found)}

             {:error, :client_mismatch} ->
               {:error,
                invalid_grant("Refresh token was not issued to this client", :client_mismatch)}

             {:error, :expired} ->
               {:error, invalid_grant("Refresh token has expired", :refresh_token_expired)}

             {:error, :missing_family_id} ->
               {:error,
                oauth_error(
                  500,
                  "server_error",
                  "Refresh token family is invalid",
                  :missing_family_id
                )}

             {:error, _reason} ->
               {:error,
                oauth_error(
                  500,
                  "server_error",
                  "Unable to rotate refresh token",
                  :refresh_rotation_failed
                )}
           end
         end) do
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

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp fetch_presented_refresh_token(refresh_token_hash, request) do
    case token_store(request).fetch_refresh_token(refresh_token_hash) do
      {:ok, %Token{} = refresh_token} ->
        {:ok, refresh_token}

      {:ok, nil} ->
        {:error, invalid_grant("Refresh token is invalid", :refresh_token_not_found)}

      {:error, _reason} ->
        {:error,
         oauth_error(500, "server_error", "Unable to load refresh token", :refresh_lookup_failed)}
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

  defp transact_with_audit_outcome(store, fun) when is_function(fun, 0) do
    store.transact(fn ->
      case fun.() do
        {:ok, result, audit_events} ->
          case append_audit_events(store, audit_events) do
            :ok -> result
            {:error, reason} -> {:error, reason}
          end

        {:durable_error, error, audit_events} ->
          case append_audit_events(store, audit_events) do
            :ok -> {:durable_error, error}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end)
    |> case do
      {:ok, {:durable_error, %Error{} = error}} -> {:error, error}
      {:ok, result} -> {:ok, result}
      {:error, %Error{} = error} -> {:error, error}
      {:error, reason} when is_atom(reason) -> {:error, oauth_error(500, "server_error", "Unable to rotate refresh token", reason)}
      {:error, other} -> {:error, other}
    end
  end

  defp append_audit_events(_store, []), do: :ok

  defp append_audit_events(store, [event | rest]) do
    case store.append_audit_event(event) do
      {:ok, _event} -> append_audit_events(store, rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp refresh_rotation_audit_event(%Client{} = client, %Token{} = presented, %Token{} = rotated) do
    %{
      action: :refresh_token_rotated,
      outcome: :succeeded,
      reason_code: :refresh_token_rotated,
      actor: client_actor(client.client_id),
      resource: %{type: :refresh_token, id: to_string(rotated.id || rotated.token_hash)},
      metadata: %{
        client_id: client.client_id,
        subject_id: rotated.account_id,
        family_id: rotated.family_id,
        previous_refresh_token_id: presented.id
      }
    }
  end

  defp reuse_audit_events(%Client{} = client, %Token{} = refresh_token) do
    [
      %{
        action: :refresh_token_reuse_detected,
        outcome: :denied,
        reason_code: :refresh_token_reuse_detected,
        actor: client_actor(client.client_id),
        resource: %{type: :refresh_token, id: to_string(refresh_token.id || refresh_token.token_hash)},
        metadata: %{
          client_id: client.client_id,
          subject_id: refresh_token.account_id,
          family_id: refresh_token.family_id
        }
      },
      %{
        action: :token_family_revoked,
        outcome: :succeeded,
        reason_code: :refresh_token_reuse_detected,
        actor: client_actor(client.client_id),
        resource: %{type: :token_family, id: to_string(refresh_token.family_id)},
        metadata: %{
          client_id: client.client_id,
          subject_id: refresh_token.account_id,
          refresh_token_id: refresh_token.id
        }
      }
    ]
  end

  defp client_actor(client_id), do: %{type: :client, id: client_id, display: client_id}
end
