defmodule Lockspire.Protocol.TokenExchange do
  @moduledoc """
  Redeems Phase 2 authorization codes into durable opaque bearer access tokens.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Observability
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.IdToken
  alias Lockspire.Protocol.TokenFormatter

  @access_token_ttl 3600

  defmodule Success do
    @moduledoc false

    @type t :: %__MODULE__{
            access_token: String.t(),
            id_token: String.t() | nil,
            token_type: String.t(),
            expires_in: pos_integer(),
            scope: String.t()
          }

    defstruct [:access_token, :id_token, :token_type, :expires_in, :scope]
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
         {:ok, %Token{} = authorization_code, code_hash} <-
           fetch_authorization_code(params, request),
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
    case ClientAuth.authenticate(params, authorization, client_auth_options(request)) do
      {:ok, %Client{} = client} ->
        {:ok, client}

      {:error, %ClientAuth.Error{} = error} ->
        {:error,
         %Error{
           status: error.status,
           error: error.error,
           error_description: error.error_description,
           reason_code: error.reason_code
         }}
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
        {:error,
         invalid_grant("Authorization code has already been used", :authorization_code_replayed)}

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
      {:error,
       invalid_grant("Authorization code was not issued to this client", :client_mismatch)}
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
        {:error,
         invalid_grant("Unsupported PKCE challenge method", :unsupported_code_challenge_method)}

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
      {:ok, %{access_token: %Token{} = persisted_access_token}} ->
        build_success_response(
          client,
          authorization_code,
          persisted_access_token,
          formatted_access_token.token,
          formatted_access_token.token_type,
          issued_at,
          request
        )

      {:error, :already_redeemed} ->
        {:error,
         invalid_grant("Authorization code has already been used", :authorization_code_replayed)}

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

  defp build_success_response(
         %Client{} = client,
         %Token{} = authorization_code,
         %Token{} = persisted_access_token,
         raw_access_token,
         token_type,
         issued_at,
         request
       ) do
    with {:ok, id_token} <-
           maybe_issue_id_token(client, authorization_code, raw_access_token, issued_at, request) do
      %Success{
        access_token: raw_access_token,
        id_token: id_token,
        token_type: token_type,
        expires_in: @access_token_ttl,
        scope: Enum.join(persisted_access_token.scopes, " ")
      }
    end
  end

  defp maybe_issue_id_token(
         %Client{} = client,
         %Token{} = authorization_code,
         raw_access_token,
         issued_at,
         request
       ) do
    if "openid" in authorization_code.scopes do
      with {:ok, %Interaction{} = interaction} <- fetch_interaction(authorization_code, request),
           {:ok, %Claims{} = claims} <- resolve_claims(authorization_code, client, request),
           {:ok, signing_key} <- fetch_signing_key(request),
           {:ok, token} <-
             IdToken.sign(%{
               client_id: client.client_id,
               issuer: Config.issuer!(),
               host_claims: claims,
               interaction_nonce: interaction.nonce,
               access_token: raw_access_token,
               issued_at: issued_at,
               signing_key: signing_key
             }) do
        {:ok, token}
      else
        {:error, %Error{} = error} ->
          {:error, error}

        {:error, reason_code} ->
          {:error, oauth_error(500, "server_error", "Unable to issue id_token", reason_code)}
      end
    else
      {:ok, nil}
    end
  end

  defp fetch_interaction(%Token{interaction_id: interaction_id}, request)
       when is_binary(interaction_id) do
    case interaction_store(request).fetch_interaction(interaction_id) do
      {:ok, %Interaction{} = interaction} ->
        {:ok, interaction}

      {:ok, nil} ->
        {:error, :interaction_not_found}

      {:error, _reason} ->
        {:error, :interaction_lookup_failed}
    end
  end

  defp fetch_interaction(_authorization_code, _request), do: {:error, :interaction_not_found}

  defp resolve_claims(%Token{} = authorization_code, %Client{} = client, _request) do
    resolver = Config.account_resolver!()

    context = %{
      client_id: client.client_id,
      scopes: authorization_code.scopes,
      interaction_id: authorization_code.interaction_id
    }

    with {:ok, account} <- resolver.resolve_account(authorization_code.account_id, context),
         {:ok, %Claims{} = claims} <- resolver.build_claims(account, context) do
      {:ok, claims}
    else
      {:error, _reason} -> {:error, :claims_resolution_failed}
    end
  end

  defp fetch_signing_key(request) do
    case key_store(request).fetch_active_signing_key() do
      {:ok, %{alg: "RS256", private_jwk_encrypted: private_jwk} = key}
      when is_binary(private_jwk) ->
        {:ok, key}

      {:ok, nil} ->
        {:error, :signing_key_not_found}

      {:ok, _key} ->
        {:error, :invalid_signing_key}

      {:error, _reason} ->
        {:error, :signing_key_lookup_failed}
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

  defp client_auth_options(request), do: [client_store: client_store(request)]

  defp token_store(request),
    do: Keyword.get(request_options(request), :token_store, Config.repo!())

  defp interaction_store(request),
    do: Keyword.get(request_options(request), :interaction_store, Config.repo!())

  defp key_store(request),
    do: Keyword.get(request_options(request), :key_store, Config.repo!())

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
