defmodule Lockspire.AccessToken do
  @moduledoc """
  Encapsulates the state of an access token throughout the validation plug pipeline.
  """

  defstruct [
    :token,
    :claims,
    :client_id,
    :authorization_scheme,
    :binding_type,
    :binding_requirements,
    :error,
    binding_verified: false
  ]

  @type t :: %__MODULE__{
          token: String.t() | nil,
          claims: map() | nil,
          client_id: String.t() | nil,
          authorization_scheme: String.t() | nil,
          binding_type: String.t() | nil,
          binding_requirements:
            %{
              optional(:dpop_jkt) => String.t(),
              optional(:mtls_x5t_s256) => String.t()
            }
            | nil,
          error: term(),
          binding_verified: boolean()
        }

  @doc """
  Returns the normalized subject claim for an access token.

  Blank, missing, and malformed subjects return `nil`. The original value remains
  available through `token.claims` for compatibility and extension use cases.
  """
  @spec subject(t() | term()) :: String.t() | nil
  def subject(%__MODULE__{} = token) do
    case claim(token, "sub") do
      value when is_binary(value) -> nonblank(value)
      _other -> nil
    end
  end

  def subject(_token), do: nil

  @doc """
  Returns normalized, first-seen-deduplicated access-token scopes.

  A scope claim is a whitespace-delimited binary. Missing or malformed claims
  return an empty list.
  """
  @spec scopes(t() | term()) :: [String.t()]
  def scopes(%__MODULE__{} = token) do
    case claim(token, "scope") do
      value when is_binary(value) ->
        value
        |> String.split(~r/\s+/, trim: true)
        |> Enum.uniq()

      _other ->
        []
    end
  end

  def scopes(_token), do: []

  @doc """
  Returns normalized, first-seen-deduplicated access-token audiences.

  A single nonblank audience or a nonempty list of nonblank audiences is
  accepted. Missing and malformed claims return an empty list.
  """
  @spec audiences(t() | term()) :: [String.t()]
  def audiences(%__MODULE__{} = token) do
    case normalize_audiences(token.claims) do
      {:ok, audiences} -> audiences
      {:error, _reason} -> []
    end
  end

  def audiences(_token), do: []

  @doc """
  Returns the access-token expiration as a UTC `DateTime`.

  Only integer JWT NumericDate values are accepted. Strings, floats, missing
  values, and values outside `DateTime`'s supported range return `nil`.
  """
  @spec expires_at(t() | term()) :: DateTime.t() | nil
  def expires_at(%__MODULE__{} = token) do
    case claim(token, "exp") do
      value when is_integer(value) ->
        case DateTime.from_unix(value, :second) do
          {:ok, datetime} -> datetime
          {:error, _reason} -> nil
        end

      _other ->
        nil
    end
  end

  def expires_at(_token), do: nil

  @doc """
  Returns allowlisted confirmation values for the token's sender binding.

  The returned map contains only nonblank `cnf.jkt` and `cnf["x5t#S256"]`
  values. Unknown or malformed confirmation members are not exposed.
  """
  @spec confirmation(t() | term()) ::
          %{optional(:dpop_jkt) => String.t(), optional(:mtls_x5t_s256) => String.t()} | nil
  def confirmation(%__MODULE__{} = token), do: normalize_confirmation(claim(token, "cnf"))
  def confirmation(_token), do: nil

  @doc false
  @spec normalize_audiences(map() | term()) ::
          {:ok, [String.t()]} | {:error, :missing_audience | :invalid_audience}
  def normalize_audiences(claims) when is_map(claims) do
    case Map.get(claims, "aud") do
      nil ->
        {:error, :missing_audience}

      audience when is_binary(audience) ->
        case nonblank(audience) do
          nil -> {:error, :invalid_audience}
          normalized -> {:ok, [normalized]}
        end

      audiences when is_list(audiences) ->
        case normalize_audience_list(audiences) do
          [] -> {:error, :invalid_audience}
          normalized -> {:ok, normalized}
        end

      _other ->
        {:error, :invalid_audience}
    end
  end

  def normalize_audiences(_claims), do: {:error, :invalid_audience}

  @doc false
  @spec normalize_confirmation(map() | term()) ::
          %{optional(:dpop_jkt) => String.t(), optional(:mtls_x5t_s256) => String.t()} | nil
  def normalize_confirmation(confirmation) when is_map(confirmation) do
    normalized =
      %{}
      |> put_confirmation(:dpop_jkt, Map.get(confirmation, "jkt"))
      |> put_confirmation(:mtls_x5t_s256, Map.get(confirmation, "x5t#S256"))

    if map_size(normalized) == 0, do: nil, else: normalized
  end

  def normalize_confirmation(_confirmation), do: nil

  defp claim(%__MODULE__{claims: claims}, key) when is_map(claims), do: Map.get(claims, key)
  defp claim(_token, _key), do: nil

  defp normalize_audience_list(audiences) do
    if Enum.all?(audiences, &is_binary/1) do
      audiences
      |> Enum.map(&nonblank/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
    else
      []
    end
  end

  defp put_confirmation(confirmation, _key, value) when not is_binary(value), do: confirmation

  defp put_confirmation(confirmation, key, value) do
    case nonblank(value) do
      nil -> confirmation
      normalized -> Map.put(confirmation, key, normalized)
    end
  end

  defp nonblank(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end
end
