defmodule Lockspire.Protocol.TokenExchange do
  @moduledoc """
  Redeems Phase 2 authorization codes into durable opaque bearer access tokens.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.TokenFormatter

  @access_token_ttl 3600
  @supported_auth_methods [:none, :client_secret_basic, :client_secret_post]

  defmodule Success do
    @moduledoc false

    @type t :: %__MODULE__{
            access_token: String.t(),
            token_type: String.t(),
            expires_in: pos_integer(),
            scope: String.t()
          }

    defstruct [:access_token, :token_type, :expires_in, :scope]
  end

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

  @type result :: {:ok, Success.t()} | {:error, Error.t()}

  @spec exchange_authorization_code(map()) :: result()
  def exchange_authorization_code(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with :ok <- validate_grant_type(params),
         {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %Token{} = authorization_code, code_hash} <- fetch_authorization_code(params, request),
         :ok <- validate_code_active(authorization_code, code_hash),
         :ok <- validate_code_binding(client, authorization_code, params),
         %Success{} = success <- redeem_code(client, authorization_code, code_hash, request) do
      emit_success(client, authorization_code)
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp validate_grant_type(%{"grant_type" => "authorization_code"}), do: :ok

  defp validate_grant_type(_params) do
    {:error,
     oauth_error(
       400,
       "unsupported_grant_type",
       "Only grant_type=authorization_code is supported",
       :unsupported_grant_type
     )}
  end

  defp authenticate_client(params, authorization, request) do
    with {:ok, attempted_method, client_id, client_secret} <-
           parse_client_credentials(params, authorization),
         {:ok, %Client{} = client} <- fetch_client(client_id, request),
         :ok <- validate_registered_auth_method(client, attempted_method),
         :ok <- validate_client_secret(client, attempted_method, client_secret) do
      {:ok, client}
    end
  end

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
         [client_id, client_secret] <- :binary.split(decoded, ":", [:global]),
         true <- present?(client_id),
         true <- present?(client_secret) do
      {:ok, :client_secret_basic, client_id, client_secret}
    else
      _other ->
        {:error, invalid_client("Malformed HTTP Basic credentials", :invalid_basic_auth)}
    end
  end

  defp parse_basic_authorization(_authorization) do
    {:error, invalid_client("Unsupported token endpoint authentication method", :unsupported_auth)}
  end

  defp fetch_client(client_id, request) do
    case client_store(request).fetch_client_by_id(client_id) do
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

  defp fetch_authorization_code(params, request) do
    with code when is_binary(code) and code != "" <- normalize_optional_string(params["code"]) do
      code_hash = TokenFormatter.hash_token(code)

      case token_store(request).fetch_authorization_code(code_hash) do
        {:ok, %Token{} = authorization_code} ->
          {:ok, authorization_code, code_hash}

        {:ok, nil} ->
          {:error, invalid_grant("Authorization code is invalid", :authorization_code_not_found)}

        {:error, _reason} ->
          {:error,
           oauth_error(
             500,
             "server_error",
             "Unable to load authorization code",
             :authorization_code_lookup_failed
           )}
      end
    else
      _other ->
        {:error, invalid_grant("Authorization code is required", :missing_authorization_code)}
    end
  end

  defp validate_code_active(%Token{} = authorization_code, _code_hash) do
    now = DateTime.utc_now()

    cond do
      not is_nil(authorization_code.redeemed_at) ->
        {:error, invalid_grant("Authorization code has already been used", :authorization_code_replayed)}

      not is_nil(authorization_code.revoked_at) ->
        {:error, invalid_grant("Authorization code is invalid", :authorization_code_revoked)}

      DateTime.compare(authorization_code.expires_at, now) != :gt ->
        {:error, invalid_grant("Authorization code has expired", :authorization_code_expired)}

      true ->
        :ok
    end
  end

  defp validate_code_binding(%Client{} = client, %Token{} = authorization_code, params) do
    with :ok <- validate_client_binding(client, authorization_code),
         :ok <- validate_redirect_uri_binding(authorization_code, params),
         :ok <- validate_pkce_binding(authorization_code, params) do
      :ok
    end
  end

  defp validate_client_binding(%Client{} = client, %Token{} = authorization_code) do
    if client.client_id == authorization_code.client_id do
      :ok
    else
      {:error, invalid_grant("Authorization code was not issued to this client", :client_mismatch)}
    end
  end

  defp validate_redirect_uri_binding(%Token{} = authorization_code, params) do
    redirect_uri = normalize_optional_string(params["redirect_uri"])

    if redirect_uri == authorization_code.redirect_uri do
      :ok
    else
      {:error,
       invalid_grant(
         "redirect_uri does not match the issued authorization code",
         :redirect_uri_mismatch
       )}
    end
  end

  defp validate_pkce_binding(%Token{} = authorization_code, params) do
    verifier = normalize_optional_string(params["code_verifier"])

    cond do
      not present?(verifier) ->
        {:error, invalid_grant("code_verifier is required", :missing_code_verifier)}

      authorization_code.code_challenge_method != :S256 ->
        {:error, invalid_grant("Unsupported PKCE challenge method", :unsupported_code_challenge_method)}

      not pkce_verifier_matches?(verifier, authorization_code.code_challenge) ->
        {:error, invalid_grant("code_verifier is invalid", :code_verifier_mismatch)}

      true ->
        :ok
    end
  end

  defp redeem_code(%Client{} = client, %Token{} = authorization_code, code_hash, request) do
    formatted_access_token =
      TokenFormatter.format_access_token(
        token_generator:
          Keyword.get(request_options(request), :token_generator, &default_token_generator/0)
      )

    issued_at = now(request)
    expires_at = DateTime.add(issued_at, @access_token_ttl, :second)

    access_token = %Token{
      token_hash: formatted_access_token.token_hash,
      token_type: :access_token,
      client_id: client.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      scopes: authorization_code.scopes,
      issued_at: issued_at,
      expires_at: expires_at
    }

    case token_store(request).redeem_authorization_code(code_hash, issued_at, access_token) do
      {:ok, %{access_token: %Token{}}} ->
        %Success{
          access_token: formatted_access_token.token,
          token_type: formatted_access_token.token_type,
          expires_in: @access_token_ttl,
          scope: Enum.join(authorization_code.scopes, " ")
        }

      {:error, :already_redeemed} ->
        {:error, invalid_grant("Authorization code has already been used", :authorization_code_replayed)}

      {:error, :not_found} ->
        {:error, invalid_grant("Authorization code is invalid", :authorization_code_not_found)}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to redeem authorization code",
           :token_redemption_failed
         )}
    end
  end

  defp emit_success(%Client{} = client, %Token{} = authorization_code) do
    metadata = %{
      client_id: client.client_id,
      interaction_id: authorization_code.interaction_id,
      subject_id: authorization_code.account_id,
      authorization_code_id: authorization_code.id,
      token_type: :access_token
    }

    Observability.emit(:authorization_code_redeemed, %{}, metadata)
    Observability.emit(:access_token_issued, %{}, metadata)
  end

  defp emit_failure(%Error{reason_code: :authorization_code_replayed} = error, params, request) do
    metadata = failure_metadata(error, params, request)
    Observability.emit(:authorization_code_replay_detected, %{}, metadata)
    Observability.emit(:token_exchange_failed, %{}, metadata)
  end

  defp emit_failure(%Error{} = error, params, request) do
    Observability.emit(:token_exchange_failed, %{}, failure_metadata(error, params, request))
  end

  defp failure_metadata(%Error{} = error, params, request) do
    request
    |> request_client_id()
    |> then(fn client_id ->
      %{
        client_id: client_id,
        reason_code: error.reason_code,
        error: error.error,
        grant_type: params["grant_type"]
      }
    end)
  end

  defp request_client_id(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    normalize_optional_string(params["client_id"])
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

  defp pkce_verifier_matches?(verifier, challenge) when is_binary(challenge) do
    calculated_challenge =
      :crypto.hash(:sha256, verifier)
      |> Base.url_encode64(padding: false)

    secure_compare(challenge, calculated_challenge)
  end

  defp pkce_verifier_matches?(_verifier, _challenge), do: false

  defp secure_compare(left, right)
       when is_binary(left) and is_binary(right) and byte_size(left) == byte_size(right) do
    Plug.Crypto.secure_compare(left, right)
  end

  defp secure_compare(_left, _right), do: false

  defp invalid_client(description, reason_code) do
    oauth_error(401, "invalid_client", description, reason_code)
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

  defp client_store(request),
    do: Keyword.get(request_options(request), :client_store, Config.repo!())

  defp token_store(request),
    do: Keyword.get(request_options(request), :token_store, Config.repo!())

  defp now(request),
    do:
      request
      |> request_options()
      |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
      |> then(& &1.())

  defp default_token_generator do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp request_options(request), do: Map.get(request, :opts, [])

  defp normalize_optional_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp present?(value), do: is_binary(value) and value != ""
end
