defmodule Lockspire.Protocol.ClientAuth do
  @moduledoc """
  Shared token-endpoint client authentication for OAuth lifecycle surfaces.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.ClientAuth.PrivateKeyJwt
  alias Lockspire.Security.Policy

  @supported_auth_methods [:none, :client_secret_basic, :client_secret_post, :private_key_jwt]

  defmodule Error do
    @moduledoc """
    Client authentication failure returned to OAuth protocol handlers.
    """

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
         :ok <- validate_client_secret(client, attempted_method, client_secret, opts) do
      {:ok, client}
    end
  end

  @spec supported_auth_methods() :: [atom()]
  def supported_auth_methods, do: @supported_auth_methods

  @spec supported_auth_method_names() :: [String.t()]
  def supported_auth_method_names do
    Enum.map(@supported_auth_methods, &Atom.to_string/1)
  end

  defp parse_client_credentials(params, authorization) do
    auth_state = %{
      has_header?: present?(authorization),
      body_client_id: normalize_optional_string(params["client_id"]),
      body_client_secret: normalize_optional_string(params["client_secret"]),
      client_assertion: normalize_optional_string(params["client_assertion"]),
      is_jwt_bearer?:
        params["client_assertion_type"] ==
          "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      authorization: authorization
    }

    evaluate_client_credentials(auth_state)
  end

  defp evaluate_client_credentials(%{has_header?: true, body_client_secret: s})
       when not is_nil(s), do: mixed_auth_error()

  defp evaluate_client_credentials(%{has_header?: true, client_assertion: a}) when not is_nil(a),
    do: mixed_auth_error()

  defp evaluate_client_credentials(%{body_client_secret: s, client_assertion: a})
       when not is_nil(s) and not is_nil(a), do: mixed_auth_error()

  defp evaluate_client_credentials(%{has_header?: true, authorization: auth}),
    do: parse_basic_authorization(auth)

  defp evaluate_client_credentials(%{is_jwt_bearer?: true, client_assertion: a})
       when not is_nil(a) do
    case peek_jwt_client_id(a) do
      {:ok, client_id} -> {:ok, :private_key_jwt, client_id, a}
      :error -> {:error, invalid_client("Malformed client_assertion", :invalid_client_assertion)}
    end
  end

  defp evaluate_client_credentials(%{body_client_id: id, body_client_secret: s})
       when not is_nil(id) and not is_nil(s) do
    {:ok, :client_secret_post, id, s}
  end

  defp evaluate_client_credentials(%{body_client_id: id}) when not is_nil(id) do
    {:ok, :none, id, nil}
  end

  defp evaluate_client_credentials(_state) do
    {:error, invalid_client("Missing client authentication", :missing_client_auth)}
  end

  defp mixed_auth_error do
    {:error,
     invalid_client("Token endpoint authentication methods must not be mixed", :mixed_auth)}
  end

  defp peek_jwt_client_id(assertion) do
    with [_, payload_b64, _] <- String.split(assertion, "."),
         {:ok, payload_json} <- Base.url_decode64(payload_b64, padding: false),
         {:ok, payload} <- Jason.decode(payload_json),
         client_id when is_binary(client_id) and client_id != "" <-
           payload["sub"] || payload["iss"] do
      {:ok, client_id}
    else
      _ -> :error
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
    case Policy.ensure_supported_token_endpoint_auth_method(auth_method) do
      :ok ->
        if auth_method == attempted_method do
          :ok
        else
          {:error,
           invalid_client(
             "Client is not allowed to use this token endpoint authentication method",
             :unsupported_token_endpoint_auth_method
           )}
        end

      {:error, :unsupported_token_endpoint_auth_method} ->
        {:error,
         invalid_client(
           "Unsupported token endpoint authentication method",
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

  defp validate_client_secret(
         %Client{token_endpoint_auth_method: :none},
         :none,
         _client_secret,
         _opts
       ),
       do: :ok

  defp validate_client_secret(%Client{} = client, :private_key_jwt, client_assertion, opts) do
    case PrivateKeyJwt.verify(client, client_assertion, opts) do
      :ok ->
        :ok

      {:error, reason_code} ->
        {:error, invalid_client("Client authentication failed", reason_code)}
    end
  end

  defp validate_client_secret(%Client{} = client, method, client_secret, _opts)
       when method in [:client_secret_basic, :client_secret_post] do
    cond do
      not present?(client.client_secret_hash) ->
        {:error, invalid_client("Client secret is not configured", :missing_client_secret)}

      not Policy.verify_client_secret(client.client_secret_hash, client_secret) ->
        {:error, invalid_client("Client authentication failed", :invalid_client_secret)}

      true ->
        :ok
    end
  end

  defp client_store(opts) do
    Keyword.fetch!(opts, :client_store)
  end

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
