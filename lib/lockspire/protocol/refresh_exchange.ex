defmodule Lockspire.Protocol.RefreshExchange do
  @moduledoc """
  Rotates refresh tokens and revokes the full family on reuse.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.AccessTokenSigner
  alias Lockspire.Protocol.TokenEndpointDPoP
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
    params = Map.get(request, :params, Map.get(request, "params", request))

    with {:ok, %Token{} = presented_refresh_token} <-
           fetch_presented_refresh_token(refresh_token_hash, request),
         {:ok, requested_resources} <-
           validate_requested_resources(params, presented_refresh_token),
         {:ok, context} <-
           TokenEndpointDPoP.resolve_refresh_context(client, presented_refresh_token, request) do
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
    formatted_refresh_token =
      TokenFormatter.format_refresh_token(token_format_options(request, :refresh_token))

    rotated_at = now(request)

    # Build the rotated access token with the subject/scopes sourced from the
    # presented refresh token (Pitfall 5: the rotated token's own account_id is
    # nil) so the signer derives a non-nil `sub` and a correct `scope` claim.
    access_token =
      build_rotated_access_token(
        client,
        rotated_at,
        context,
        presented_refresh_token,
        requested_resources
      )

    # Mint the at+jwt (or opaque, per format resolution) via the shared signer and
    # re-point the persisted token_hash to the signer's hash (Pitfall 1).
    with {:ok, raw_access_token, access_token_hash} <-
           AccessTokenSigner.issue(access_token, client, request) do
      access_token = %Token{access_token | token_hash: access_token_hash}

      refresh_token =
        build_rotated_refresh_token(
          client,
          formatted_refresh_token,
          rotated_at,
          context,
          presented_refresh_token
        )

      case transact_with_audit_outcome(token_store(request), fn ->
             handle_refresh_rotation(
               token_store(request),
               client,
               refresh_token_hash,
               rotated_at,
               refresh_token,
               access_token,
               presented_refresh_token,
               context
             )
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
             raw_access_token: raw_access_token,
             raw_refresh_token: formatted_refresh_token.token,
             token_type: context.token_type
           }}

        {:error, %Error{} = error} ->
          {:error, error}
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

    Observability.emit(:token, :issued, %{}, metadata)
    Observability.emit(:refresh_token, :issued, %{}, metadata)
  end

  defp emit_failure(%Client{} = client, %Error{} = error) do
    metadata = %{
      client_id: client.client_id,
      reason_code: error.reason_code,
      error: error.error,
      grant_type: "refresh_token"
    }

    if error.reason_code == :refresh_token_reuse_detected do
      Observability.emit(:refresh_token, :reuse_detected, %{}, metadata)
    end

    Observability.emit(:token_exchange, :failed, %{}, metadata)
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
    case Keyword.get(
           Map.get(request, :opts, []),
           :"#{token_type}_generator",
           Keyword.get(Map.get(request, :opts, []), :token_generator)
         ) do
      nil -> []
      generator -> [token_generator: generator]
    end
  end

  @spec now(map()) :: DateTime.t()
  defp now(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
    |> then(& &1.())
  end

  defp transact_with_audit_outcome(store, fun) when is_function(fun, 0) do
    store.transact(fn ->
      fun.()
      |> maybe_append_audit_events(store)
    end)
    |> case do
      {:ok, {:durable_error, %Error{} = error}} ->
        {:error, error}

      {:ok, result} ->
        {:ok, result}

      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} when is_atom(reason) ->
        {:error, oauth_error(500, "server_error", "Unable to rotate refresh token", reason)}

      {:error, other} ->
        {:error, other}
    end
  end

  defp append_audit_events(_store, []), do: :ok

  defp append_audit_events(store, [event | rest]) do
    case store.append_audit_event(event) do
      {:ok, _event} -> append_audit_events(store, rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_rotated_access_token(
         %Client{} = client,
         rotated_at,
         context,
         %Token{} = source_token,
         requested_resources
       ) do
    %Token{
      # token_hash is re-pointed to the signer's hash after minting (Pitfall 1).
      token_hash: nil,
      token_type: :access_token,
      client_id: client.client_id,
      # Pitfall 5: the rotated token's subject must come from the presented
      # refresh token, otherwise the minted JWT would carry `sub: nil`.
      account_id: source_token.account_id,
      consent_grant_id: source_token.consent_grant_id,
      sid: source_token.sid,
      scopes: source_token.scopes,
      audience: requested_resources,
      cnf: context.cnf,
      issued_at: rotated_at,
      expires_at: DateTime.add(rotated_at, @access_token_ttl, :second)
    }
  end

  defp build_rotated_refresh_token(
         %Client{} = client,
         formatted_refresh_token,
         rotated_at,
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
      expires_at: DateTime.add(rotated_at, @refresh_token_ttl, :second)
    }
  end

  defp handle_refresh_rotation(
         store,
         %Client{} = client,
         refresh_token_hash,
         rotated_at,
         %Token{} = refresh_token,
         %Token{} = access_token,
         %Token{} = presented_refresh_token,
         context
       ) do
    expected_cnf = context.cnf

    case store.rotate_refresh_token(
           refresh_token_hash,
           client.client_id,
           rotated_at,
           refresh_token,
           access_token,
           expected_cnf
         ) do
      {:ok,
       %{
         presented_refresh_token: %Token{} = presented,
         refresh_token: %Token{} = persisted_refresh_token,
         access_token: %Token{}
       } = success} ->
        {:ok, success, [refresh_rotation_audit_event(client, presented, persisted_refresh_token)]}

      {:error, :reuse_detected} ->
        {:durable_error,
         invalid_grant(
           "Refresh token reuse detected; the token family has been revoked",
           :refresh_token_reuse_detected
         ), reuse_audit_events(client, presented_refresh_token)}

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

  defp maybe_append_audit_events({:error, reason}, _store), do: {:error, reason}

  defp maybe_append_audit_events({tag, error, audit_events}, store)
       when tag in [:ok, :durable_error] do
    case append_audit_events(store, audit_events) do
      :ok -> {tag, error}
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
end
