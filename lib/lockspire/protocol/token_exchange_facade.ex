defmodule Lockspire.Protocol.TokenExchange do
  @moduledoc """
  Stable public facade for OAuth/OIDC token endpoint exchanges.
  """

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Protocol.RefreshExchange
  alias Lockspire.Protocol.Rfc8693Exchange
  alias Lockspire.Protocol.TokenExchange.AuthorizationCodeGrant
  alias Lockspire.Protocol.TokenExchange.CibaGrant
  alias Lockspire.Protocol.TokenExchange.DeviceCodeGrant
  alias Lockspire.Protocol.TokenExchange.GrantSupport

  defmodule Success do
    @moduledoc "Successful token endpoint response payload."
    @type t :: %__MODULE__{
            access_token: String.t(),
            refresh_token: String.t() | nil,
            id_token: String.t() | nil,
            token_type: String.t(),
            issued_token_type: String.t() | nil,
            expires_in: pos_integer(),
            scope: String.t()
          }
    defstruct [
      :access_token,
      :refresh_token,
      :id_token,
      :token_type,
      :issued_token_type,
      :expires_in,
      :scope
    ]
  end

  defmodule Error do
    @moduledoc "Token endpoint error payload."
    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom(),
            dpop_nonce: String.t() | nil
          }
    defstruct [:status, :error, :error_description, :reason_code, :dpop_nonce]
  end

  @type result :: {:ok, Success.t()} | {:error, Error.t()}

  @spec exchange(map()) :: result()
  def exchange(request) when is_map(request) do
    params = params(request)

    case normalize_optional_string(params["grant_type"]) do
      "authorization_code" -> AuthorizationCodeGrant.exchange(request)
      "refresh_token" -> exchange_refresh_token(request)
      "urn:ietf:params:oauth:grant-type:device_code" -> DeviceCodeGrant.exchange(request)
      "urn:openid:params:grant-type:ciba" -> CibaGrant.exchange(request)
      "urn:ietf:params:oauth:grant-type:token-exchange" -> exchange_rfc8693(request)
      _other -> {:error, unsupported_grant_type_error()}
    end
  end

  @doc "Issues CIBA Push tokens through the stable worker contract."
  @spec issue_ciba_tokens(Client.t(), CibaAuthorization.t(), map(), map()) :: result()
  def issue_ciba_tokens(
        %Client{} = client,
        %CibaAuthorization{} = authorization,
        context,
        request
      ),
      do: CibaGrant.issue_tokens(client, authorization, context, request)

  @spec exchange_authorization_code(map()) :: result()
  def exchange_authorization_code(request) when is_map(request),
    do: AuthorizationCodeGrant.exchange(request)

  @doc false
  def validate_grant_resources_for_test(params, grant),
    do: GrantSupport.validate_grant_resources_for_test(params, grant)

  defp exchange_refresh_token(request) do
    params = params(request)
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, %Client{} = client} <-
           GrantSupport.authenticate_client(params, authorization, request),
         {:ok, %Success{} = success} <- RefreshExchange.exchange_refresh_token(client, request) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        GrantSupport.emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp exchange_rfc8693(request) do
    params = params(request)
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, %Client{} = client} <-
           GrantSupport.authenticate_client(params, authorization, request),
         {:ok, %Success{} = success} <- Rfc8693Exchange.exchange(client, request) do
      {:ok, success}
    else
      {:error, %Error{} = error} ->
        GrantSupport.emit_failure(error, params, request)
        {:error, error}
    end
  end

  defp params(request), do: Map.get(request, :params, Map.get(request, "params", request))

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp unsupported_grant_type_error do
    %Error{
      status: 400,
      error: "unsupported_grant_type",
      error_description:
        "Only grant_type=authorization_code, grant_type=refresh_token, grant_type=urn:ietf:params:oauth:grant-type:device_code, grant_type=urn:openid:params:grant-type:ciba, and grant_type=urn:ietf:params:oauth:grant-type:token-exchange are supported",
      reason_code: :unsupported_grant_type
    }
  end
end
