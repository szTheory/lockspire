defmodule Lockspire.Protocol.DeviceAuthorization do
  @moduledoc """
  Protocol pipeline for Device Authorization (RFC 8628).
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization, as: DeviceAuthorizationState
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.DeviceCode
  alias Lockspire.Storage.Ecto.Repository

  defmodule Success do
    @moduledoc "Successful device authorization response."
    @type t :: %__MODULE__{
            device_code: String.t(),
            user_code: String.t(),
            verification_uri: String.t(),
            verification_uri_complete: String.t() | nil,
            expires_in: pos_integer(),
            interval: pos_integer() | nil
          }
    defstruct [
      :device_code,
      :user_code,
      :verification_uri,
      :verification_uri_complete,
      :expires_in,
      :interval
    ]
  end

  defmodule Error do
    @moduledoc "Error response for device authorization."
    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t(),
            reason_code: atom()
          }
    defstruct [:status, :error, :error_description, :reason_code]
  end

  @type result :: {:ok, Success.t()} | {:error, Error.t()}

  @spec authorize(map()) :: result()
  def authorize(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", %{}))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))
    now = now(request)

    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %DeviceAuthorizationState{} = device_auth} <-
           persist_device_authorization(params, client, request, now) do
      verification_uri = verification_uri(request)

      {:ok,
       %Success{
         device_code: device_auth.device_code,
         user_code: device_auth.user_code,
         verification_uri: verification_uri,
         verification_uri_complete:
           verification_uri_complete(verification_uri, device_auth.user_code),
         expires_in: DateTime.diff(device_auth.expires_at, now, :second),
         interval: device_auth.effective_poll_interval_seconds
       }}
    else
      {:error, %Error{} = error} ->
        {:error, error}
    end
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

  defp persist_device_authorization(params, %Client{} = client, request, now) do
    device_code = DeviceCode.generate_device_code()
    user_code = DeviceCode.generate_user_code()
    scopes = parse_scopes(params["scope"])

    device_auth =
      DeviceAuthorizationState.issue(
        %{
          client_id: client.client_id,
          device_code: device_code,
          user_code: user_code,
          scopes: scopes
        },
        now: now
      )

    case device_authorization_store(request).put_device_authorization(device_auth) do
      {:ok, %DeviceAuthorizationState{} = stored_auth} ->
        Lockspire.Observability.emit(
          :device_authorization,
          :created,
          %{},
          %{client_id: client.client_id, verification_handle: stored_auth.verification_handle}
        )

        {:ok,
         %DeviceAuthorizationState{
           stored_auth
           | device_code: device_auth.device_code,
             user_code: device_auth.user_code
         }}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to persist device authorization",
           :device_store_failed
         )}
    end
  end

  defp parse_scopes(nil), do: []
  defp parse_scopes(""), do: []

  defp parse_scopes(scopes) when is_binary(scopes) do
    scopes
    |> String.split(" ", trim: true)
  end

  defp device_authorization_store(request) do
    request
    |> request_opts()
    |> Keyword.get(:device_authorization_store, Repository)
  end

  defp client_auth_options(request) do
    [
      client_store: Keyword.get(request_opts(request), :client_store, Repository),
      supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt]
    ]
  end

  defp request_opts(request) do
    Map.get(request, :opts, Map.get(request, "opts", []))
  end

  defp verification_uri(request) do
    request
    |> request_opts()
    |> Keyword.get(:verification_uri, "https://example.com/device")
  end

  defp verification_uri_complete(verification_uri, user_code)
       when is_binary(verification_uri) and is_binary(user_code) do
    uri = URI.parse(verification_uri)

    query =
      case uri.query do
        nil -> %{}
        query -> URI.decode_query(query)
      end
      |> Map.put("user_code", user_code)

    uri
    |> Map.put(:query, URI.encode_query(query))
    |> URI.to_string()
  end

  defp now(request) do
    request
    |> request_opts()
    |> Keyword.get_lazy(:now, &DateTime.utc_now/0)
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
