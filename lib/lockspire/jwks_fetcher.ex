defmodule Lockspire.JwksFetcher do
  @moduledoc """
  Fetches and caches JSON Web Key Sets (JWKS) dynamically using Req and Cachex.
  """

  @cache_name :lockspire_jwks_cache
  @default_ttl :timer.minutes(15)

  @doc """
  Retrieves a parsed `JOSE.JWK` (which contains the JWKSet) from the given URI.

  Hits the network only on cache miss. Strict timeouts are enforced.
  """
  @spec get_keys(String.t(), keyword()) :: {:ok, JOSE.JWK.t()} | {:error, term()}
  def get_keys(uri, opts \\ []) when is_binary(uri) and is_list(opts) do
    # Cachex.fetch/3 calls the fallback function only if the key is missing or expired,
    # ensuring only one network request per URI is made concurrently.
    case Cachex.fetch(@cache_name, uri, fn _uri -> fetch_from_network(uri, opts) end) do
      {:ok, keys} ->
        {:ok, keys}

      {:commit, keys} ->
        {:ok, keys}

      {:error, reason} ->
        {:error, reason}

      {:ignore, {:error, reason}} ->
        {:error, reason}

      other ->
        {:error, {:unexpected_cache_response, other}}
    end
  end

  defp fetch_from_network(uri, opts) do
    req_opts =
      Keyword.merge(
        [
          retry: false,
          receive_timeout: 5000
        ],
        opts
      )

    case Req.get(uri, req_opts) do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        try do
          jwk_set = JOSE.JWK.from_map(body)
          {:commit, jwk_set, ttl: @default_ttl}
        rescue
          e ->
            {:ignore, {:error, {:invalid_jwks_format, e}}}
        end

      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        try do
          jwk_set = body |> Jason.decode!() |> JOSE.JWK.from_map()
          {:commit, jwk_set, ttl: @default_ttl}
        rescue
          e ->
            {:ignore, {:error, {:invalid_jwks_format, e}}}
        end

      {:ok, %Req.Response{status: status}} ->
        {:ignore, {:error, {:http_error, status}}}

      {:error, exception} ->
        {:ignore, {:error, exception}}
    end
  end
end
