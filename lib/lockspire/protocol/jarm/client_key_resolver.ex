defmodule Lockspire.Protocol.Jarm.ClientKeyResolver do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Domain.Client

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

  defp do_resolve(%Client{jwks_uri: jwks_uri} = _client, params, opts) when is_binary(jwks_uri) do
    fetcher = Keyword.get(opts, :jwks_fetcher, Config.jwks_fetcher())

    with {:ok, jwk_set} <- fetcher.get_keys(jwks_uri, jwks_fetcher_opts(opts)),
         {_modules, jwks} <- JOSE.JWK.to_map(jwk_set) do
      case select_key(jwks, params) do
        {:ok, jwk} ->
          {:ok, jwk, :jwks_uri}

        {:error, :jarm_encryption_key_unavailable} ->
          refresh_remote_key(fetcher, jwks_uri, params, opts)
      end
    else
      {:error, _reason} -> {:error, :jarm_encryption_key_fetch_failed}
    end
  end

  defp do_resolve(%Client{}, _params, _opts), do: {:error, :client_jwks_missing}

  defp refresh_remote_key(fetcher, jwks_uri, params, opts) do
    with {:ok, jwk_set} <- fetcher.refresh_keys(jwks_uri, jwks_fetcher_opts(opts)),
         {_modules, jwks} <- JOSE.JWK.to_map(jwk_set),
         {:ok, jwk} <- select_key(jwks, params) do
      {:ok, jwk, :jwks_uri}
    else
      {:error, :jarm_encryption_key_unavailable} ->
        {:error, :jarm_encryption_key_unavailable}

      {:error, _reason} ->
        {:error, :jarm_encryption_key_fetch_failed}
    end
  end

  defp select_key(jwks, %{alg: alg} = params) do
    jwks
    |> jwk_entries()
    |> Enum.filter(&compatible_key_shape?(&1, alg))
    |> Enum.filter(&allowed_use?(&1))
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

  defp jwks_fetcher_opts(opts) do
    Config.jwks_fetcher_opts()
    |> Keyword.merge(Keyword.get(opts, :jwks_fetcher_opts, []))
  end
end
