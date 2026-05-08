defmodule Lockspire.JwksFetcher do
  @moduledoc """
  Fetches and caches JSON Web Key Sets (JWKS) dynamically using Req and Cachex.
  """

  alias Lockspire.JwksFetcher.TargetSafety

  @cache_name :lockspire_jwks_cache
  @default_ttl :timer.minutes(15)
  @default_connect_timeout 1_000
  @default_receive_timeout 1_000
  @default_max_body_bytes 262_144
  @body_too_large_marker :"$lockspire_jwks_body_too_large"
  @fetch_error :jwks_fetch_failed
  @type result ::
          {:ok, JOSE.JWK.t()}
          | {:error, {:jwks_fetch_failed, atom() | {atom(), atom() | integer()}}}

  @doc """
  Retrieves a parsed `JOSE.JWK` (which contains the JWKSet) from the given URI.

  Hits the network only on cache miss. Strict timeouts are enforced.
  """
  @spec get_keys(String.t(), keyword()) :: result()
  def get_keys(uri, opts \\ []) when is_binary(uri) and is_list(opts) do
    with {:ok, _parsed_uri} <- validate_fetch_target(uri, opts) do
      # Cachex.fetch/3 calls the fallback function only if the key is missing or expired,
      # ensuring only one network request per URI is made concurrently.
      case Cachex.fetch(@cache_name, uri, fn _uri -> fetch_from_network(uri, opts) end) do
        {:ok, keys} ->
          {:ok, keys}

        {:commit, keys} ->
          {:ok, keys}

        {:error, _reason} ->
          {:error, fetch_error(:cache_error)}

        {:ignore, {:error, reason}} ->
          {:error, reason}

        _other ->
          {:error, fetch_error(:cache_error)}
      end
    end
  end

  @doc """
  Returns the JWKS cache TTL in milliseconds for successful fetches.
  """
  @spec cache_ttl() :: pos_integer()
  def cache_ttl, do: @default_ttl

  @doc """
  Forces a bounded cache refresh for the given JWKS URI.

  This bypasses the cached entry, updates the cache only on a successful refetch,
  and preserves the last-known-good cached entry when the refresh fails.
  """
  @spec refresh_keys(String.t(), keyword()) :: result()
  def refresh_keys(uri, opts \\ []) when is_binary(uri) and is_list(opts) do
    with {:ok, _parsed_uri} <- validate_fetch_target(uri, opts),
         {:ok, jwk_set} <- fetch_uncached(uri, opts),
         {:ok, true} <- Cachex.put(@cache_name, uri, jwk_set, expire: cache_ttl()) do
      {:ok, jwk_set}
    else
      {:error, {:jwks_fetch_failed, _reason}} = error ->
        error

      {:ok, false} ->
        {:error, fetch_error(:cache_error)}

      {:error, _reason} ->
        {:error, fetch_error(:cache_error)}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp fetch_from_network(uri, opts) do
    req_opts = strict_req_opts(opts)

    case Req.get(uri, req_opts) do
      {:ok, %Req.Response{status: 200, body: @body_too_large_marker}} ->
        {:ignore, {:error, fetch_error(:payload_too_large)}}

      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        parse_jwks(body)

      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        parse_jwks(body)

      {:ok, %Req.Response{status: 200}} ->
        {:ignore, {:error, fetch_error(:invalid_format)}}

      {:ok, %Req.Response{status: status}} when status in 300..399 ->
        {:ignore, {:error, fetch_error(:redirect_disallowed)}}

      {:ok, %Req.Response{status: status}} ->
        {:ignore, {:error, fetch_error({:http_status, status})}}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:ignore, {:error, fetch_error(:timeout)}}

      {:error, %Req.TransportError{}} ->
        {:ignore, {:error, fetch_error(:transport_error)}}

      {:error, %Req.HTTPError{}} ->
        {:ignore, {:error, fetch_error(:transport_error)}}

      {:error, _exception} ->
        {:ignore, {:error, fetch_error(:transport_error)}}
    end
  end

  defp parse_jwks(body) do
    with {:ok, body_map} <- decode_body(body),
         {:ok, jwk_set} <- build_jwk_set(body_map) do
      {:commit, jwk_set, expire: cache_ttl()}
    else
      {:error, :invalid_format} ->
        {:ignore, {:error, fetch_error(:invalid_format)}}
    end
  end

  defp fetch_uncached(uri, opts) do
    case fetch_from_network(uri, opts) do
      {:commit, jwk_set, expire: _ttl} -> {:ok, jwk_set}
      {:ignore, {:error, reason}} -> {:error, reason}
      _other -> {:error, fetch_error(:cache_error)}
    end
  end

  defp decode_body(body) when is_map(body), do: {:ok, body}

  defp decode_body(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      _ -> {:error, :invalid_format}
    end
  end

  defp build_jwk_set(body_map) do
    # credo:disable-for-next-line
    try do
      {:ok, JOSE.JWK.from_map(body_map)}
    rescue
      _ -> {:error, :invalid_format}
    end
  end

  defp validate_https_uri(uri) do
    case URI.parse(uri) do
      %URI{scheme: "https", host: host} = parsed_uri when is_binary(host) and host != "" ->
        {:ok, parsed_uri}

      %URI{scheme: "https"} ->
        {:error, fetch_error(:invalid_uri)}

      _ ->
        {:error, fetch_error(:https_required)}
    end
  end

  defp validate_fetch_target(uri, opts) do
    with {:ok, parsed_uri} <- validate_https_uri(uri),
         :ok <- ensure_safe_target(parsed_uri, opts) do
      {:ok, parsed_uri}
    end
  end

  defp ensure_safe_target(%URI{host: host}, opts) do
    case TargetSafety.ensure_safe_host(host, Keyword.take(opts, [:resolver])) do
      :ok -> :ok
      {:error, {:unsafe_target, reason}} -> {:error, fetch_error({:unsafe_target, reason})}
      {:error, :resolution_failed} -> {:error, fetch_error(:resolution_failed)}
    end
  end

  defp strict_req_opts(opts) do
    opts
    |> Keyword.put(:redirect, false)
    |> Keyword.put(:retry, false)
    |> Keyword.put(:compressed, false)
    |> Keyword.put(:raw, true)
    |> Keyword.put(:into, capped_body_into(@default_max_body_bytes))
    |> Keyword.put(:receive_timeout, @default_receive_timeout)
    |> Keyword.put(:connect_options, timeout: @default_connect_timeout)
  end

  defp capped_body_into(max_body_bytes) do
    fn {:data, chunk}, {req, resp} ->
      body = if is_binary(resp.body), do: resp.body, else: ""
      total_size = byte_size(body) + byte_size(chunk)

      if total_size > max_body_bytes do
        {:halt, {req, %{resp | body: @body_too_large_marker}}}
      else
        {:cont, {req, %{resp | body: body <> chunk}}}
      end
    end
  end

  defp fetch_error(reason), do: {@fetch_error, reason}
end
