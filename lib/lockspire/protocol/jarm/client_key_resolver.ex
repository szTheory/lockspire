defmodule Lockspire.Protocol.Jarm.ClientKeyResolver do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Diagnostics.RemoteJwks
  alias Lockspire.Domain.Client
  alias Lockspire.Observability

  @type encryption_params :: %{
          required(:alg) => String.t(),
          required(:enc) => String.t(),
          optional(:kid) => String.t()
        }

  @supported_algs ["RSA-OAEP-256", "ECDH-ES"]
  @supported_encs ["A256GCM", "A128GCM"]

  @spec resolve(Client.t(), encryption_params(), keyword()) ::
          {:ok, JOSE.JWK.t(), :inline_jwks | :jwks_uri}
          | {:error, :client_jwks_missing}
          | {:error, :jarm_encryption_key_fetch_failed}
          | {:error, :jarm_encryption_key_unavailable}
          | {:error, :unsupported_jarm_encryption_alg}
          | {:error, :unsupported_jarm_encryption_enc}
  def resolve(%Client{} = client, %{alg: alg, enc: enc} = params, opts)
      when is_binary(alg) and is_binary(enc) and is_list(opts) do
    with :ok <- validate_alg(alg),
         :ok <- validate_enc(enc) do
      do_resolve(client, params, opts)
    end
  end

  defp do_resolve(%Client{jwks: jwks} = _client, params, _opts) when is_map(jwks) do
    case select_key(jwks, params) do
      {:ok, jwk} -> {:ok, jwk, :inline_jwks}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_resolve(%Client{jwks_uri: jwks_uri} = client, params, opts) when is_binary(jwks_uri) do
    fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())
    opts = Keyword.put_new(opts, :client, client)

    with {:ok, jwk_set} <- fetcher.get_keys(jwks_uri, jwks_fetcher_opts(opts)),
         {_modules, jwks} <- JOSE.JWK.to_map(jwk_set) do
      case select_key(jwks, params) do
        {:ok, jwk} ->
          clear_remote_jwks_diagnostic(client_from_opts_or_nil(opts), opts)
          {:ok, jwk, :jwks_uri}

        {:error, :jarm_encryption_key_unavailable} ->
          refresh_remote_key(fetcher, jwks_uri, params, opts)
      end
    else
      {:error, {:jwks_fetch_failed, _reason} = fetch_error} ->
        emit_remote_failure(
          :jarm_encryption_key_fetch_failed,
          RemoteJwks.classify_fetch_error(:jarm, fetch_error),
          client,
          opts
        )

        {:error, :jarm_encryption_key_fetch_failed}
    end
  end

  defp do_resolve(%Client{}, _params, _opts), do: {:error, :client_jwks_missing}

  defp refresh_remote_key(fetcher, jwks_uri, params, opts) do
    remote_opts = [
      cached_entry_present?: true,
      forced_refresh_attempted?: true
    ]

    case fetcher.refresh_keys(jwks_uri, jwks_fetcher_opts(opts)) do
      {:ok, jwk_set} ->
        {_modules, jwks} = JOSE.JWK.to_map(jwk_set)

        case select_key(jwks, params) do
          {:ok, jwk} ->
            clear_remote_jwks_diagnostic(client_from_opts_or_nil(opts), opts)
            {:ok, jwk, :jwks_uri}

          {:error, :jarm_encryption_key_unavailable} ->
            emit_remote_failure(
              :jarm_encryption_key_unavailable,
              RemoteJwks.key_unavailable(
                :jarm,
                Keyword.put(
                  remote_opts,
                  :requested_kid_present_in_cached_set?,
                  requested_kid_present?(jwks, params)
                )
              ),
              client_from_opts_or_nil(opts),
              opts
            )

            {:error, :jarm_encryption_key_unavailable}
        end

      {:error, {:jwks_fetch_failed, _reason} = fetch_error} ->
        emit_remote_failure(
          :jarm_encryption_key_fetch_failed,
          RemoteJwks.classify_fetch_error(:jarm, fetch_error, remote_opts),
          client_from_opts_or_nil(opts),
          opts
        )

        {:error, :jarm_encryption_key_fetch_failed}
    end
  end

  defp select_key(jwks, %{alg: alg} = params) do
    jwks
    |> jwk_entries()
    |> Enum.filter(fn jwk -> compatible_key_shape?(jwk, alg) and allowed_use?(jwk) end)
    |> maybe_filter_requested_kid(params)
    |> sort_candidates(params)
    |> case do
      [candidate | _rest] -> {:ok, JOSE.JWK.from_map(candidate)}
      [] -> {:error, :jarm_encryption_key_unavailable}
    end
  end

  defp jwk_entries(%{"keys" => keys}) when is_list(keys), do: Enum.filter(keys, &is_map/1)
  defp jwk_entries(%{} = jwk), do: [jwk]
  defp jwk_entries(_other), do: []

  defp compatible_key_shape?(%{"kty" => "RSA"}, "RSA-OAEP-256"), do: true
  defp compatible_key_shape?(%{"kty" => "EC"}, "ECDH-ES"), do: true
  defp compatible_key_shape?(_jwk, _alg), do: false

  defp allowed_use?(%{"use" => "enc"}), do: true
  defp allowed_use?(%{"use" => nil}), do: true
  defp allowed_use?(jwk) when is_map(jwk), do: not Map.has_key?(jwk, "use")

  defp sort_candidates(candidates, %{kid: requested_kid}) when is_binary(requested_kid) do
    Enum.sort_by(candidates, fn jwk ->
      {
        use_rank(jwk),
        kid_rank(jwk)
      }
    end)
  end

  defp sort_candidates(candidates, _params) do
    Enum.sort_by(candidates, fn jwk ->
      {use_rank(jwk), kid_rank(jwk)}
    end)
  end

  defp use_rank(%{"use" => "enc"}), do: 0

  defp use_rank(jwk) when is_map(jwk) do
    if Map.has_key?(jwk, "use"), do: 2, else: 1
  end

  defp use_rank(_jwk), do: 2

  defp kid_rank(%{"kid" => kid}) when is_binary(kid) and kid != "", do: 0
  defp kid_rank(_jwk), do: 1

  defp maybe_filter_requested_kid(candidates, %{kid: requested_kid})
       when is_binary(requested_kid) and requested_kid != "" do
    Enum.filter(candidates, &(Map.get(&1, "kid") == requested_kid))
  end

  defp maybe_filter_requested_kid(candidates, _params), do: candidates

  defp validate_alg(alg) when alg in @supported_algs, do: :ok
  defp validate_alg(_alg), do: {:error, :unsupported_jarm_encryption_alg}

  defp validate_enc(enc) when enc in @supported_encs, do: :ok
  defp validate_enc(_enc), do: {:error, :unsupported_jarm_encryption_enc}

  defp requested_kid_present?(jwks, %{kid: requested_kid})
       when is_binary(requested_kid) and requested_kid != "" do
    Enum.any?(jwk_entries(jwks), &(Map.get(&1, "kid") == requested_kid))
  end

  defp requested_kid_present?(_jwks, _params), do: nil

  defp emit_remote_failure(reason_code, remote_jwks_incident) do
    metadata =
      %{reason_code: reason_code, protocol_surface: :jarm, jwks_source: :jwks_uri}
      |> Map.merge(Observability.remote_jwks_metadata(remote_jwks_incident))

    Observability.emit(:jarm, :failed, %{}, metadata)
  end

  defp emit_remote_failure(reason_code, remote_jwks_incident, %Client{} = client, opts) do
    emit_remote_failure(reason_code, remote_jwks_incident)
    persist_remote_jwks_diagnostic(client, remote_jwks_incident, opts)
  end

  defp client_from_opts_or_nil(opts), do: Keyword.get(opts, :client)

  defp persist_remote_jwks_diagnostic(%Client{} = client, %RemoteJwks{} = incident, opts) do
    with store when not is_nil(store) <- Keyword.get(opts, :client_store, Config.repo!()),
         true <- function_exported?(store, :update_client, 2) do
      metadata =
        client.metadata
        |> ensure_metadata()
        |> Map.put("remote_jwks_diagnostic", RemoteJwks.snapshot(incident))

      _ = store.update_client(client, %{metadata: metadata})
      :ok
    else
      _other -> :ok
    end
  end

  defp persist_remote_jwks_diagnostic(_client, _incident, _opts), do: :ok

  defp clear_remote_jwks_diagnostic(%Client{} = client, opts) do
    with store when not is_nil(store) <- Keyword.get(opts, :client_store, Config.repo!()),
         true <- function_exported?(store, :update_client, 2),
         metadata when is_map(metadata) <- client.metadata,
         true <- Map.has_key?(metadata, "remote_jwks_diagnostic") do
      _ = store.update_client(client, %{metadata: Map.delete(metadata, "remote_jwks_diagnostic")})
      :ok
    else
      _other -> :ok
    end
  end

  defp clear_remote_jwks_diagnostic(_client, _opts), do: :ok

  defp ensure_metadata(metadata) when is_map(metadata), do: metadata
  defp ensure_metadata(_metadata), do: %{}

  defp jwks_fetcher_opts(opts) do
    Config.jwks_fetcher_opts()
    |> Keyword.merge(Keyword.get(opts, :jwks_fetcher_opts, []))
  end
end
