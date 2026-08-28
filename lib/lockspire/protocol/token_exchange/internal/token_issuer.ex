defmodule Lockspire.Protocol.TokenExchange.Internal.TokenIssuer do
  @moduledoc false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.TokenExchange.Internal.AccessTokenSigner
  alias Lockspire.Protocol.TokenExchange.Internal.Dependencies
  alias Lockspire.Protocol.IdToken
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Protocol.TokenLifetime
  alias Lockspire.Protocol.TokenResult.Error
  alias Lockspire.Protocol.TokenResult.Success

  @type token_for_issuance :: %Token{token_hash: String.t() | nil}

  @doc false
  @spec issue_access(token_for_issuance(), Client.t(), Dependencies.t()) ::
          {:ok, String.t(), String.t()} | {:error, Error.t()}
  def issue_access(%Token{} = token, %Client{} = client, %Dependencies{} = dependencies) do
    # This is intentionally a construction/signing boundary. It does not receive a
    # store, transaction, audit sink, or telemetry dependency, so issuance cannot
    # create a durable side effect.
    AccessTokenSigner.issue(token, client, %{}, dependencies)
  end

  @doc false
  @spec issue_exchange(token_for_issuance(), Client.t(), map(), Dependencies.t()) ::
          {:ok, String.t(), String.t()} | {:error, Error.t()}
  def issue_exchange(%Token{} = token, %Client{} = client, claims, %Dependencies{} = dependencies)
      when is_map(claims) do
    AccessTokenSigner.issue_exchange(token, client, claims, %{}, dependencies)
  end

  @doc false
  @spec issue_grant(Client.t(), Token.t(), DateTime.t(), map(), Dependencies.t()) ::
          {:ok,
           %{
             access_token: Token.t(),
             raw_access_token: String.t(),
             formatted_refresh_token: map() | nil
           }}
          | {:error, Error.t()}
  def issue_grant(
        %Client{} = client,
        %Token{} = grant,
        %DateTime{} = issued_at,
        issuance_context,
        %Dependencies{} = dependencies
      )
      when is_map(issuance_context) do
    formatted_refresh_token = maybe_format_refresh_token(client, grant, dependencies)
    family_id = if formatted_refresh_token, do: formatted_refresh_token.token_hash

    access_token = %Token{
      token_type: :access_token,
      family_id: family_id,
      generation: 0,
      client_id: client.client_id,
      account_id: grant.account_id,
      interaction_id: grant.interaction_id,
      consent_grant_id: grant.consent_grant_id,
      sid: grant.sid,
      scopes: grant.scopes,
      audience: grant.audience,
      cnf: issuance_context.cnf,
      issued_at: issued_at,
      expires_at: DateTime.add(issued_at, TokenLifetime.access_token(), :second)
    }

    with {:ok, raw_access_token, token_hash} <- issue_access(access_token, client, dependencies) do
      {:ok,
       %{
         access_token: %Token{access_token | token_hash: token_hash},
         raw_access_token: raw_access_token,
         formatted_refresh_token: formatted_refresh_token
       }}
    end
  end

  @doc false
  @spec build_success(
          Client.t(),
          Token.t(),
          Token.t(),
          String.t(),
          map(),
          DateTime.t(),
          String.t() | nil,
          Dependencies.t()
        ) :: Success.t() | {:error, Error.t()}
  def build_success(
        %Client{} = client,
        %Token{} = grant,
        %Token{} = persisted_access_token,
        raw_access_token,
        issuance_context,
        %DateTime{} = issued_at,
        raw_refresh_token,
        %Dependencies{} = dependencies
      ) do
    with {:ok, id_token} <-
           maybe_issue_id_token(
             client,
             grant,
             raw_access_token,
             issued_at,
             issuance_context,
             dependencies
           ) do
      %Success{
        access_token: raw_access_token,
        refresh_token: raw_refresh_token,
        id_token: id_token,
        token_type: issuance_context.token_type,
        expires_in: TokenLifetime.access_token(),
        scope: Enum.join(persisted_access_token.scopes, " ")
      }
    end
  end

  defp maybe_format_refresh_token(
         %Client{} = client,
         %Token{} = grant,
         %Dependencies{} = dependencies
       ) do
    if "refresh_token" in client.allowed_grant_types and "offline_access" in grant.scopes do
      TokenFormatter.format_refresh_token(refresh_token_format_options(dependencies))
    end
  end

  defp refresh_token_format_options(%Dependencies{} = dependencies) do
    generator = dependencies.refresh_token_generator || dependencies.token_generator

    if generator, do: [token_generator: generator], else: []
  end

  defp maybe_issue_id_token(
         client,
         grant,
         raw_access_token,
         issued_at,
         issuance_context,
         dependencies
       ) do
    if "openid" in grant.scopes do
      with {:ok, interaction} <- fetch_optional_interaction(grant, dependencies),
           {:ok, auth_time} <- resolve_interaction_auth_time(interaction),
           {:ok, %Claims{} = claims} <- resolve_claims(grant, client, dependencies),
           {:ok, signing_key} <- fetch_signing_key(dependencies),
           {:ok, token} <-
             IdToken.sign(%{
               client_id: client.client_id,
               issuer: dependencies.issuer,
               host_claims: claims,
               interaction_nonce: interaction_nonce(interaction),
               auth_time: auth_time,
               sid: grant.sid,
               access_token: raw_access_token,
               issued_at: issued_at,
               signing_key: signing_key,
               security_profile: issuance_context.security_profile.effective_profile
             }) do
        {:ok, token}
      else
        {:error, reason_code} ->
          {:error, oauth_error(500, "server_error", "Unable to issue id_token", reason_code)}
      end
    else
      {:ok, nil}
    end
  end

  defp fetch_optional_interaction(
         %Token{interaction_id: interaction_id},
         %Dependencies{} = dependencies
       )
       when is_binary(interaction_id) do
    case dependencies.interaction_store.fetch_interaction(interaction_id) do
      {:ok, %Interaction{} = interaction} -> {:ok, interaction}
      {:ok, nil} -> {:error, :interaction_not_found}
      {:error, _reason} -> {:error, :interaction_lookup_failed}
    end
  end

  defp fetch_optional_interaction(%Token{}, _dependencies), do: {:ok, nil}

  defp interaction_nonce(%Interaction{} = interaction), do: interaction.nonce
  defp interaction_nonce(nil), do: nil

  defp resolve_interaction_auth_time(%Interaction{
         max_age: max_age,
         auth_time_requested: requested,
         auth_time: auth_time
       }) do
    if is_integer(max_age) or requested do
      if match?(%DateTime{}, auth_time),
        do: {:ok, auth_time},
        else: {:error, :missing_interaction_auth_time}
    else
      {:ok, nil}
    end
  end

  defp resolve_interaction_auth_time(nil), do: {:ok, nil}

  defp resolve_claims(%Token{} = grant, %Client{} = client, %Dependencies{} = dependencies) do
    context = %{
      client_id: client.client_id,
      scopes: grant.scopes,
      interaction_id: grant.interaction_id
    }

    with {:ok, account} <-
           dependencies.account_resolver.resolve_account(grant.account_id, context),
         {:ok, %Claims{} = claims} <- dependencies.account_resolver.build_claims(account, context) do
      {:ok, claims}
    else
      {:error, _reason} -> {:error, :claims_resolution_failed}
    end
  end

  defp fetch_signing_key(%Dependencies{} = dependencies) do
    case dependencies.key_store.fetch_active_signing_key() do
      {:ok, %{alg: alg, private_jwk_encrypted: private_jwk} = key}
      when is_binary(private_jwk) and is_binary(alg) ->
        {:ok, key}

      {:ok, nil} ->
        {:error, :signing_key_not_found}

      {:ok, _key} ->
        {:error, :invalid_signing_key}

      {:error, _reason} ->
        {:error, :signing_key_lookup_failed}
    end
  end

  defp oauth_error(status, error, description, reason_code),
    do: %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
end
