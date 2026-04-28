defmodule Lockspire.Protocol.Userinfo do
  @moduledoc """
  Resolves OIDC userinfo from durable opaque bearer tokens and host claims.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Protocol.ProtectedResourceDPoP
  alias Lockspire.Protocol.TokenFormatter

  @scope_claims %{
    "profile" =>
      ~w(name family_name given_name middle_name nickname preferred_username profile picture website gender birthdate zoneinfo locale updated_at),
    "email" => ~w(email email_verified),
    "phone" => ~w(phone_number phone_number_verified),
    "address" => ~w(address)
  }

  defmodule Error do
    @moduledoc """
    Userinfo endpoint error payload.
    """

    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }

    defstruct [:status, :error, :error_description, :reason_code]
  end

  @type result :: {:ok, map()} | {:error, Error.t()}

  @spec fetch_claims(map()) :: result()
  def fetch_claims(request) when is_map(request) do
    with {:ok, authorization_scheme, raw_access_token} <- parse_authorization(request),
         {:ok, %Token{} = access_token} <- fetch_access_token(raw_access_token, request),
         :ok <- validate_access_mode(access_token, authorization_scheme, raw_access_token, request),
         {:ok, %Claims{} = claims} <- resolve_claims(access_token),
         userinfo_claims <- build_userinfo_claims(claims, access_token.scopes) do
      {:ok, userinfo_claims}
    else
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp parse_authorization(request) do
    case Map.get(request, :authorization, Map.get(request, "authorization")) do
      "Bearer " <> token when byte_size(token) > 0 ->
        {:ok, "Bearer", token}

      "DPoP " <> token when byte_size(token) > 0 ->
        {:ok, "DPoP", token}

      _other ->
        {:error,
         error(401, "invalid_token", "Bearer access token is required", :missing_bearer_token)}
    end
  end

  # DPoP enforcement is driven by durable Token.cnf["jkt"] state, not client policy lookups.
  defp validate_access_mode(%Token{cnf: %{"jkt" => _jkt}} = access_token, authorization_scheme, raw_access_token, request) do
    request =
      request
      |> Map.put(:authorization_scheme, authorization_scheme)
      |> Map.put(:access_token, raw_access_token)

    case ProtectedResourceDPoP.validate_userinfo_access(access_token, request) do
      {:ok, _proof} -> :ok
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp validate_access_mode(%Token{}, "Bearer", _raw_access_token, _request), do: :ok

  defp validate_access_mode(%Token{}, _authorization_scheme, _raw_access_token, _request) do
    {:error, error(401, "invalid_token", "Bearer access token is required", :missing_bearer_token)}
  end

  defp fetch_access_token(token, request) do
    token_hash = TokenFormatter.hash_token(token)

    case token_store(request).fetch_active_access_token(token_hash) do
      {:ok, %Token{} = access_token} ->
        {:ok, access_token}

      {:ok, nil} ->
        {:error, error(401, "invalid_token", "Access token is invalid", :invalid_access_token)}

      {:error, _reason} ->
        {:error,
         error(500, "server_error", "Unable to load access token", :access_token_lookup_failed)}
    end
  end

  defp resolve_claims(%Token{} = access_token) do
    resolver = Config.account_resolver!()

    context = %{
      client_id: access_token.client_id,
      scopes: access_token.scopes,
      interaction_id: access_token.interaction_id
    }

    with {:ok, account} <- resolver.resolve_account(access_token.account_id, context),
         {:ok, %Claims{} = claims} <- resolver.build_claims(account, context) do
      {:ok, claims}
    else
      {:error, _reason} ->
        {:error,
         error(500, "server_error", "Unable to resolve subject claims", :claims_resolution_failed)}
    end
  end

  defp build_userinfo_claims(%Claims{} = claims, scopes) do
    allowed_claims =
      scopes
      |> Enum.flat_map(&Map.get(@scope_claims, &1, []))
      |> MapSet.new()

    claims
    |> Claims.build_userinfo_claims()
    |> Enum.filter(fn {key, _value} -> key == "sub" or MapSet.member?(allowed_claims, key) end)
    |> Map.new()
  end

  defp error(status, error, description, reason_code) do
    %Error{
      status: status,
      error: error,
      error_description: description,
      reason_code: reason_code
    }
  end

  defp token_store(request),
    do:
      request
      |> Map.get(:opts, [])
      |> Keyword.get(:token_store, Config.repo!())
end
