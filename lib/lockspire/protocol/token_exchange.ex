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
  alias Lockspire.Protocol.RefreshExchange
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy

  @access_token_ttl 3600
  @refresh_token_ttl 2_592_000

  defmodule Success do
    @moduledoc """
    Successful token endpoint response payload.
    """

    @type t :: %__MODULE__{
            access_token: String.t(),
            refresh_token: String.t() | nil,
            id_token: String.t() | nil,
            token_type: String.t(),
            expires_in: pos_integer(),
            scope: String.t()
          }

    defstruct [:access_token, :refresh_token, :id_token, :token_type, :expires_in, :scope]
  end

  defmodule Error do
    @moduledoc """
    Token endpoint error payload.
    """

    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }

    defstruct [:status, :error, :error_description, :reason_code]
  end

  @type result :: {:ok, Success.t()} | {:error, Error.t()}

  @spec exchange(map()) :: result()
  def exchange(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))

    case normalize_optional_string(params["grant_type"]) do
      "authorization_code" ->
        exchange_authorization_code(request)

      "refresh_token" ->
        exchange_refresh_token(request)

      _other ->
        {:error,
         oauth_error(
           400,
           "unsupported_grant_type",
           "Only grant_type=authorization_code and grant_type=refresh_token are supported",
           :unsupported_grant_type
         )}
    end
  end

  @spec exchange_authorization_code(map()) :: result()
  def exchange_authorization_code(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with :ok <- validate_grant_type(params),
         {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %Token{} = authorization_code, code_hash} <-
           fetch_authorization_code(params, request) do
      handle_code_exchange(client, authorization_code, code_hash, params, request)
    else
      {:error, %Error{} = error} ->
        emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp handle_code_exchange(
         %Client{} = client,
         %Token{} = authorization_code,
         code_hash,
         params,
         request
       ) do
    with :ok <- validate_code_active(authorization_code, code_hash),
         :ok <- validate_code_binding(client, authorization_code, params),
         %Success{} = success <- redeem_code(client, authorization_code, code_hash, request) do
      emit_success(client, authorization_code, success)
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        maybe_append_failure_audit(error, client, authorization_code, request)
        emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp exchange_refresh_token(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %Success{} = success} <- RefreshExchange.exchange_refresh_token(client, request) do
      {:ok, success}
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
    case normalize_optional_string(params["code"]) do
      code when is_binary(code) ->
        code_hash = Policy.hash_token(code)
        load_authorization_code(request, code_hash)

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
         :ok <- validate_redirect_uri_binding(authorization_code, params) do
      validate_pkce_binding(authorization_code, params)
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
    issued_at = now(request)
    formatted_refresh_token = maybe_format_refresh_token(client, authorization_code, request)

    {access_token, raw_access_token} =
      build_access_token(client, authorization_code, issued_at, formatted_refresh_token, request)

    case persist_authorization_code_grant(
           code_hash,
           issued_at,
           access_token,
           authorization_code,
           formatted_refresh_token,
           request
         ) do
      {:ok, %{access_token: %Token{} = persisted_access_token} = persisted_grant} ->
        build_success_response(
          client,
          authorization_code,
          persisted_access_token,
          raw_access_token,
          formatted_token_type(),
          issued_at,
          Map.get(persisted_grant, :refresh_token_raw),
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
         raw_refresh_token,
         request
       ) do
    with {:ok, id_token} <-
           maybe_issue_id_token(client, authorization_code, raw_access_token, issued_at, request) do
      %Success{
        access_token: raw_access_token,
        refresh_token: raw_refresh_token,
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
      reason_code: :authorization_code_redeemed,
      token_type: :access_token
    }

    Observability.emit(:authorization_code_redeemed, %{}, metadata)
    Observability.emit(:access_token_issued, %{}, metadata)
  end

  defp emit_success(%Client{} = client, %Token{} = authorization_code, %Success{
         refresh_token: refresh_token
       })
       when is_binary(refresh_token) do
    emit_success(client, authorization_code)

    Observability.emit(:refresh_token_issued, %{}, %{
      client_id: client.client_id,
      interaction_id: authorization_code.interaction_id,
      subject_id: authorization_code.account_id
    })
  end

  defp emit_success(%Client{} = client, %Token{} = authorization_code, %Success{} = _success) do
    emit_success(client, authorization_code)
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

  defp maybe_format_refresh_token(%Client{} = client, %Token{} = authorization_code, request) do
    if issue_refresh_token?(client, authorization_code) do
      TokenFormatter.format_refresh_token(token_format_options(request, :refresh_token))
    else
      nil
    end
  end

  defp issue_refresh_token?(%Client{} = client, %Token{} = authorization_code) do
    "refresh_token" in client.allowed_grant_types and
      refresh_scope_policy_allows?(authorization_code.scopes)
  end

  defp refresh_scope_policy_allows?(scopes) when is_list(scopes) do
    if "offline_access" in scopes do
      true
    else
      true
    end
  end

  defp build_access_token(
         %Client{} = client,
         %Token{} = authorization_code,
         issued_at,
         formatted_refresh_token,
         request
       ) do
    family_id = if formatted_refresh_token, do: formatted_refresh_token.token_hash

    formatted_access_token =
      TokenFormatter.format_access_token(token_format_options(request, :access_token))

    access_token = %Token{
      token_hash: formatted_access_token.token_hash,
      token_type: :access_token,
      family_id: family_id,
      generation: 0,
      client_id: client.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      scopes: authorization_code.scopes,
      audience: authorization_code.audience,
      issued_at: issued_at,
      expires_at: DateTime.add(issued_at, @access_token_ttl, :second)
    }

    {access_token, formatted_access_token.token}
  end

  defp persist_authorization_code_grant(
         code_hash,
         issued_at,
         %Token{} = access_token,
         %Token{} = authorization_code,
         nil,
         request
       ) do
    audit_event =
      redemption_audit_event(client_actor(authorization_code.client_id), authorization_code)

    case transact_with_audit_event(token_store(request), audit_event, fn ->
           token_store(request).redeem_authorization_code(code_hash, issued_at, access_token)
         end) do
      {:ok, %{access_token: %Token{} = persisted_access_token}} ->
        {:ok, %{access_token: persisted_access_token}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp persist_authorization_code_grant(
         code_hash,
         issued_at,
         %Token{} = access_token,
         %Token{} = authorization_code,
         formatted_refresh_token,
         request
       ) do
    refresh_token = %Token{
      token_hash: formatted_refresh_token.token_hash,
      token_type: :refresh_token,
      family_id: formatted_refresh_token.token_hash,
      generation: 0,
      client_id: authorization_code.client_id,
      account_id: authorization_code.account_id,
      interaction_id: authorization_code.interaction_id,
      scopes: authorization_code.scopes,
      audience: authorization_code.audience,
      issued_at: issued_at,
      expires_at: DateTime.add(issued_at, @refresh_token_ttl, :second)
    }

    audit_event =
      redemption_audit_event(client_actor(authorization_code.client_id), authorization_code)

    transact_with_audit_event(token_store(request), audit_event, fn ->
      with {:ok, %{access_token: %Token{} = persisted_access_token}} <-
             token_store(request).redeem_authorization_code(code_hash, issued_at, access_token),
           {:ok, %Token{} = persisted_refresh_token} <-
             token_store(request).store_token(refresh_token) do
        %{
          access_token: persisted_access_token,
          refresh_token: persisted_refresh_token,
          refresh_token_raw: formatted_refresh_token.token
        }
      else
        {:error, reason} -> {:error, reason}
      end
    end)
    |> case do
      {:ok, %{} = result} -> {:ok, result}
      {:error, _reason} = error -> error
      %{} = result -> {:ok, result}
    end
  end

  defp transact_with_audit_event(store, audit_event, fun) when is_function(fun, 0) do
    if function_exported?(store, :transact_with_audit, 2) do
      store.transact_with_audit(audit_event, fun)
    else
      transact_token_operation(store, audit_event, fun)
    end
  end

  defp append_audit_event(store, audit_event) do
    if function_exported?(store, :append_audit_event, 1) do
      store.append_audit_event(audit_event)
    else
      {:error, :audit_append_unsupported}
    end
  end

  defp maybe_append_failure_audit(
         %Error{reason_code: :authorization_code_replayed},
         %Client{} = client,
         %Token{} = authorization_code,
         request
       ) do
    replay_audit_event(client_actor(client.client_id), authorization_code)
    |> then(&append_audit_event(token_store(request), &1))

    :ok
  end

  defp maybe_append_failure_audit(_error, _client, _authorization_code, _request), do: :ok

  defp load_authorization_code(request, code_hash) do
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
  end

  defp transact_token_operation(store, audit_event, fun) do
    if function_exported?(store, :transact, 1) do
      store.transact(fn -> run_audited_token_operation(store, audit_event, fun) end)
    else
      run_audited_token_operation(store, audit_event, fun)
    end
  end

  defp run_audited_token_operation(store, audit_event, fun) do
    fun.()
    |> maybe_append_audit_event(store, audit_event)
  end

  defp maybe_append_audit_event({:error, reason}, _store, _audit_event), do: {:error, reason}

  defp maybe_append_audit_event(result, store, audit_event) do
    case append_audit_event(store, audit_event) do
      {:ok, _event} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp redemption_audit_event(actor, %Token{} = authorization_code) do
    audit_event(
      :authorization_code_redeemed,
      :succeeded,
      :authorization_code_redeemed,
      actor,
      authorization_code
    )
  end

  defp replay_audit_event(actor, %Token{} = authorization_code) do
    audit_event(
      :authorization_code_replay_detected,
      :denied,
      :authorization_code_replayed,
      actor,
      authorization_code
    )
  end

  defp audit_event(action, outcome, reason_code, actor, %Token{} = authorization_code) do
    %{
      action: action,
      outcome: outcome,
      reason_code: reason_code,
      actor: actor,
      resource: %{
        type: :authorization_code,
        id: to_string(authorization_code.id || authorization_code.interaction_id)
      },
      metadata: %{
        client_id: authorization_code.client_id,
        interaction_id: authorization_code.interaction_id,
        subject_id: authorization_code.account_id
      }
    }
  end

  defp client_actor(client_id) when is_binary(client_id) do
    %{type: :client, id: client_id, display: client_id}
  end

  defp token_format_options(request, token_type) do
    opts = request_options(request)

    case Keyword.get(opts, :"#{token_type}_generator", Keyword.get(opts, :token_generator)) do
      nil -> []
      generator -> [token_generator: generator]
    end
  end

  defp formatted_token_type, do: "Bearer"

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
