defmodule Lockspire.Protocol.ClientAuth do
  @moduledoc """
  Shared token-endpoint client authentication for OAuth lifecycle surfaces.
  """

  alias Lockspire.Domain.Client

  @supported_auth_methods [:none, :client_secret_basic, :client_secret_post]

  defmodule Error do
    @moduledoc false

    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }

    defstruct [:status, :error, :error_description, :reason_code]
  end

  @type result :: {:ok, Client.t()} | {:error, Error.t()}

  @spec authenticate(map(), String.t() | nil, keyword()) :: result()
  def authenticate(params, authorization, opts) when is_map(params) and is_list(opts) do
    with {:ok, attempted_method, client_id, client_secret} <-
           parse_client_credentials(params, authorization),
         {:ok, %Client{} = client} <- fetch_client(client_id, opts),
         :ok <- validate_registered_auth_method(client, attempted_method),
         :ok <- validate_client_secret(client, attempted_method, client_secret) do
      {:ok, client}
    end
  end

  @spec supported_auth_methods() :: [atom()]
  def supported_auth_methods, do: @supported_auth_methods

  defp parse_client_credentials(params, authorization) do
    has_header? = present?(authorization)
    body_client_id = normalize_optional_string(params["client_id"])
    body_client_secret = normalize_optional_string(params["client_secret"])

    cond do
      has_header? and present?(body_client_secret) ->
        {:error,
         invalid_client("Token endpoint authentication methods must not be mixed", :mixed_auth)}

      has_header? ->
        parse_basic_authorization(authorization)

      present?(body_client_secret) and present?(body_client_id) ->
        {:ok, :client_secret_post, body_client_id, body_client_secret}

      present?(body_client_id) ->
        {:ok, :none, body_client_id, nil}

      true ->
        {:error, invalid_client("Missing client authentication", :missing_client_auth)}
    end
  end

  defp parse_basic_authorization("Basic " <> encoded_credentials) do
    with {:ok, decoded} <- Base.decode64(encoded_credentials),
         [raw_client_id, raw_client_secret] <- String.split(decoded, ":", parts: 2),
         client_id when client_id not in [nil, ""] <- URI.decode_www_form(raw_client_id),
         client_secret when client_secret not in [nil, ""] <-
           URI.decode_www_form(raw_client_secret) do
      {:ok, :client_secret_basic, client_id, client_secret}
    else
      _other ->
        {:error, invalid_client("Malformed HTTP Basic credentials", :invalid_basic_auth)}
    end
  end

  defp parse_basic_authorization(_authorization) do
    {:error,
     invalid_client("Unsupported token endpoint authentication method", :unsupported_auth)}
  end

  defp fetch_client(client_id, opts) do
    case client_store(opts).fetch_client_by_id(client_id) do
      {:ok, %Client{} = client} ->
        {:ok, client}

      {:ok, nil} ->
        {:error, invalid_client("Unknown client_id", :invalid_client)}

      {:error, _reason} ->
        {:error, oauth_error(500, "server_error", "Unable to load client", :client_lookup_failed)}
    end
  end

  defp validate_registered_auth_method(
         %Client{token_endpoint_auth_method: auth_method},
         attempted_method
       )
       when auth_method in @supported_auth_methods do
    if auth_method == attempted_method do
      :ok
    else
      {:error,
       invalid_client(
         "Client is not allowed to use this token endpoint authentication method",
         :unsupported_token_endpoint_auth_method
       )}
    end
  end

  defp validate_registered_auth_method(_client, _attempted_method) do
    {:error,
     invalid_client(
       "Unsupported token endpoint authentication method",
       :unsupported_token_endpoint_auth_method
     )}
  end

  defp validate_client_secret(%Client{token_endpoint_auth_method: :none}, :none, _client_secret),
    do: :ok

  defp validate_client_secret(%Client{} = client, method, client_secret)
       when method in [:client_secret_basic, :client_secret_post] do
    cond do
      not present?(client.client_secret_hash) ->
        {:error, invalid_client("Client secret is not configured", :missing_client_secret)}

      not verify_client_secret(client.client_secret_hash, client_secret) ->
        {:error, invalid_client("Client authentication failed", :invalid_client_secret)}

      true ->
        :ok
    end
  end

  defp verify_client_secret("sha256:" <> rest, client_secret) when is_binary(client_secret) do
    case String.split(rest, ":", parts: 2) do
      [salt, expected_hash] ->
        calculated_hash =
          :crypto.hash(:sha256, salt <> client_secret)
          |> Base.encode64()

        secure_compare(expected_hash, calculated_hash)

      _other ->
        false
    end
  end

  defp verify_client_secret(_client_secret_hash, _client_secret), do: false

  defp client_store(opts) do
    Keyword.fetch!(opts, :client_store)
  end

  defp secure_compare(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_compare(_left, _right), do: false

  defp normalize_optional_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp invalid_client(description, reason_code) do
    oauth_error(401, "invalid_client", description, reason_code)
  end

  defp oauth_error(status, error, description, reason_code) do
    %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
  end
end
