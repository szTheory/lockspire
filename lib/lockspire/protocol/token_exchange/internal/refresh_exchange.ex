defmodule Lockspire.Protocol.TokenExchange.Internal.RefreshExchange do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.TokenExchange.Internal.GrantObservability
  alias Lockspire.Protocol.TokenExchange.Internal.GrantPersistence
  alias Lockspire.Protocol.TokenExchange.Internal.ClientAuthentication
  alias Lockspire.Protocol.TokenExchange.Internal.TokenIssuer
  alias Lockspire.Protocol.TokenExchange.Internal.TokenEndpointDPoP
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Protocol.TokenLifetime
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenResult.Success

  @spec exchange_refresh_token(Client.t(), map(), Dependencies.t()) ::
          {:ok, Success.t()} | {:error, Error.t()}
  def exchange_refresh_token(%Client{} = client, request, %Dependencies{} = dependencies)
      when is_map(request) do
    request = Dependencies.attach(request, dependencies)
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, refresh_token_hash} <- fetch_refresh_token_hash(params),
         {:ok, result} <- rotate_refresh_token(client, refresh_token_hash, request) do
      GrantObservability.emit_refresh_success(
        client,
        result.presented_refresh_token,
        result.refresh_token,
        dependencies
      )

      {:ok,
       %Success{
         access_token: result.raw_access_token,
         refresh_token: result.raw_refresh_token,
         id_token: nil,
         token_type: result.token_type,
         expires_in: result.expires_in,
         scope: Enum.join(result.access_token.scopes, " ")
       }}
    else
      {:error, %Error{} = error} ->
        GrantObservability.emit_refresh_failure(client, error, dependencies)
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
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, %Token{} = presented_refresh_token} <-
           fetch_presented_refresh_token(refresh_token_hash, request),
         {:ok, requested_resources} <-
           validate_requested_resources(params, presented_refresh_token),
         {:ok, context} <-
           TokenEndpointDPoP.resolve_refresh_context(
             client,
             presented_refresh_token,
             request,
             Dependencies.fetch!(request)
           ) do
      context =
        Map.put(
          context,
          :verified_client_identity,
          ClientAuthentication.verified_identity(client)
        )

      rotate_refresh_token_with_audit(
        client,
        refresh_token_hash,
        presented_refresh_token,
        requested_resources,
        context,
        request
      )
    end
  end

  defp rotate_refresh_token_with_audit(
         %Client{} = client,
         refresh_token_hash,
         %Token{} = presented_refresh_token,
         requested_resources,
         context,
         request
       ) do
    dependencies = Dependencies.fetch!(request)

    formatted_refresh_token =
      TokenFormatter.format_refresh_token(refresh_token_format_options(request))

    with {:ok, prepared_signing} <- TokenIssuer.prepare_refresh_access(client, dependencies) do
      case transact_with_audit_outcome(request, fn ->
             with {:ok, [%Client{} = current_client]} <-
                    dependencies.client_store.lock_clients([client.client_id]) do
               builder =
                 refresh_rotation_builder(
                   current_client,
                   client,
                   prepared_signing,
                   formatted_refresh_token,
                   requested_resources,
                   context,
                   dependencies
                 )

               handle_refresh_rotation(
                 token_store(request),
                 current_client,
                 refresh_token_hash,
                 formatted_refresh_token,
                 builder,
                 presented_refresh_token,
                 context
               )
             else
               {:error, reason} -> {:error, reason}
               _ -> {:error, client_authority_error(:credential_changed)}
             end
           end) do
        {:ok, result} -> {:ok, result}
        {:error, %Error{} = error} -> {:error, error}
        {:error, reason} -> {:error, refresh_rotation_error(reason)}
      end
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

  defp refresh_rotation_builder(
         %Client{} = locked_client,
         %Client{} = authenticated_client,
         prepared_signing,
         formatted_refresh_token,
         requested_resources,
         context,
         %Dependencies{} = dependencies
       ) do
    fn %Token{} = locked_refresh ->
      with {:ok, current_client} <-
             GrantPersistence.validate_current_client(
               locked_client,
               authenticated_client,
               context
             ),
           {:ok, now} <- refresh_authority_time(dependencies),
           :ok <-
             GrantPersistence.validate_current_authority(
               current_client,
               context,
               now,
               :guarded_refresh_rotation
             ),
           {:ok, access_expires_at} <-
             TokenLifetime.effective_expiry(
               now,
               TokenLifetime.access_token(),
               current_client.client_expires_at
             ),
           {:ok, refresh_expires_at} <-
             TokenLifetime.effective_expiry(
               now,
               TokenLifetime.refresh_token(),
               current_client.client_expires_at
             ) do
        access_token =
          build_rotated_access_token(
            current_client,
            now,
            access_expires_at,
            context,
            locked_refresh,
            requested_resources
          )

        with {:ok, raw_access_token, access_token_hash} <-
               TokenIssuer.issue_prepared_refresh_access(
                 access_token,
                 current_client,
                 prepared_signing
               ) do
          access_token = %Token{access_token | token_hash: access_token_hash}

          refresh_token =
            build_rotated_refresh_token(
              current_client,
              formatted_refresh_token,
              now,
              refresh_expires_at,
              context,
              locked_refresh
            )

          {:ok,
           %{
             rotated_at: to_utc_datetime_usec(now),
             refresh_token: refresh_token,
             access_token: access_token,
             raw_access_token: raw_access_token,
             raw_refresh_token: formatted_refresh_token.token,
             expires_in: TokenLifetime.expires_in(now, access_expires_at)
           }}
        end
      else
        {:error, %Error{} = error} -> {:error, error}
        {:error, reason} -> {:error, reason}
        _ -> {:error, client_authority_error(:credential_changed)}
      end
    end
  end

  defp refresh_authority_time(%Dependencies{} = dependencies) do
    case dependencies.now.() do
      %DateTime{} = now -> {:ok, now}
      _other -> {:error, server_error(:client_lifetime_clock_failed)}
    end
  rescue
    _error -> {:error, server_error(:client_lifetime_clock_failed)}
  end

  defp server_error(reason) do
    %Error{
      status: 500,
      error: "server_error",
      error_description: "Client lifetime state is unavailable",
      reason_code: reason
    }
  end

  defp client_authority_error(reason) do
    %Error{
      status: 401,
      error: "invalid_client",
      error_description: "Client is no longer authorized to rotate this grant",
      reason_code: reason
    }
  end

  defp validate_requested_resources(params, %Token{} = presented_refresh_token) do
    requested =
      params
      |> Map.get("resource")
      |> List.wrap()
      |> Enum.flat_map(fn
        r when is_binary(r) -> [r]
        _ -> []
      end)

    authorized = presented_refresh_token.audience

    cond do
      requested == [] ->
        {:ok, authorized}

      Enum.all?(requested, &(&1 in authorized)) ->
        {:ok, requested}

      true ->
        {:error,
         invalid_grant(
           "The requested resource is invalid or was not authorized",
           :invalid_resource
         )}
    end
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

  defp token_store(request), do: Dependencies.fetch!(request).token_store

  defp refresh_token_format_options(request) do
    dependencies = Dependencies.fetch!(request)

    generator = dependencies.refresh_token_generator || dependencies.token_generator

    case generator do
      nil -> []
      generator -> [token_generator: generator]
    end
  end

  defp transact_with_audit_outcome(request, fun) when is_map(request) and is_function(fun, 0) do
    case GrantPersistence.transact_with_audit(Dependencies.fetch!(request), fun) do
      {:error, reason} when is_atom(reason) ->
        {:error, oauth_error(500, "server_error", "Unable to rotate refresh token", reason)}

      result ->
        result
    end
  end

  defp build_rotated_access_token(
         %Client{} = client,
         rotated_at,
         expires_at,
         context,
         %Token{} = source_token,
         requested_resources
       ) do
    %Token{
      # token_hash is re-pointed to the signer's hash after minting.
      token_hash: nil,
      token_type: :access_token,
      client_id: client.client_id,
      # The rotated token's subject must come from the presented
      # refresh token, otherwise the minted JWT would carry `sub: nil`.
      account_id: source_token.account_id,
      consent_grant_id: source_token.consent_grant_id,
      sid: source_token.sid,
      scopes: source_token.scopes,
      audience: requested_resources,
      cnf: context.cnf,
      issued_at: to_utc_datetime_usec(rotated_at),
      expires_at: expires_at
    }
  end

  defp build_rotated_refresh_token(
         %Client{} = client,
         formatted_refresh_token,
         _rotated_at,
         expires_at,
         context,
         %Token{} = source_token
       ) do
    %Token{
      token_hash: formatted_refresh_token.token_hash,
      token_type: :refresh_token,
      client_id: client.client_id,
      account_id: nil,
      consent_grant_id: source_token.consent_grant_id,
      sid: source_token.sid,
      cnf: context.cnf,
      expires_at: expires_at
    }
  end

  defp handle_refresh_rotation(
         store,
         %Client{} = client,
         refresh_token_hash,
         formatted_refresh_token,
         builder,
         %Token{} = presented_refresh_token,
         context
       ) do
    expected_cnf = context.cnf

    case store.rotate_refresh_token(
           refresh_token_hash,
           client.client_id,
           nil,
           builder,
           nil,
           expected_cnf
         ) do
      {:ok,
       %{
         presented_refresh_token: %Token{} = presented,
         refresh_token: %Token{} = persisted_refresh_token,
         access_token: %Token{}
       } = success} ->
        {:ok,
         Map.merge(success, %{
           raw_refresh_token: formatted_refresh_token.token,
           token_type: context.token_type
         }), [refresh_rotation_audit_event(client, presented, persisted_refresh_token)]}

      {:error, :reuse_detected} ->
        {:durable_error,
         invalid_grant(
           "Refresh token reuse detected; the token family has been revoked",
           :refresh_token_reuse_detected
         ), reuse_audit_events(client, presented_refresh_token)}

      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error, refresh_rotation_error(reason)}
    end
  end

  defp refresh_rotation_error(:not_found),
    do: invalid_grant("Refresh token is invalid", :refresh_token_not_found)

  defp refresh_rotation_error(:client_mismatch),
    do: invalid_grant("Refresh token was not issued to this client", :client_mismatch)

  defp refresh_rotation_error(:dpop_binding_mismatch),
    do: invalid_grant("Refresh token is invalid", :refresh_dpop_binding_mismatch)

  defp refresh_rotation_error(:expired),
    do: invalid_grant("Refresh token has expired", :refresh_token_expired)

  defp refresh_rotation_error(:missing_family_id),
    do: oauth_error(500, "server_error", "Refresh token family is invalid", :missing_family_id)

  defp refresh_rotation_error(_reason),
    do:
      oauth_error(
        500,
        "server_error",
        "Unable to rotate refresh token",
        :refresh_rotation_failed
      )

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
        resource: %{
          type: :refresh_token,
          id: to_string(refresh_token.id || refresh_token.token_hash)
        },
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

  defp to_utc_datetime_usec(datetime),
    do: DateTime.from_unix!(DateTime.to_unix(datetime) * 1_000_000, :microsecond)
end
