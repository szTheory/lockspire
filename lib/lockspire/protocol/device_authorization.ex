defmodule Lockspire.Protocol.DeviceAuthorization do
  @moduledoc """
  Protocol pipeline for Device Authorization (RFC 8628).
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization, as: DeviceAuthorizationState
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.DeviceCode
  alias Lockspire.Storage.ClientLifetime
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
    clock = clock(request)

    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, %DeviceAuthorizationState{} = device_auth, now} <-
           persist_device_authorization(params, client, request, clock) do
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
    with {:ok, options} <- client_auth_options(request) do
      case ClientAuth.authenticate(params, authorization, options) do
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
  end

  defp persist_device_authorization(params, %Client{} = client, request, clock) do
    device_code = DeviceCode.generate_device_code()
    user_code = DeviceCode.generate_user_code()
    scopes = parse_scopes(params["scope"])

    case guarded_create_device_authorization(
           client,
           request,
           clock,
           device_code,
           user_code,
           scopes
         ) do
      {:ok, {%DeviceAuthorizationState{} = stored_auth, now}} ->
        Lockspire.Observability.emit(
          :device_authorization,
          :created,
          %{},
          %{client_id: client.client_id, verification_handle: stored_auth.verification_handle}
        )

        {:ok,
         %DeviceAuthorizationState{
           stored_auth
           | device_code: device_code,
             user_code: user_code
         }, now}

      {:error, :expired} ->
        {:error,
         oauth_error(401, "invalid_client", "Client application has expired", :client_app_expired)}

      {:error, :disabled} ->
        {:error,
         oauth_error(
           401,
           "invalid_client",
           "Client application is disabled",
           :client_app_disabled
         )}

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

  defp guarded_create_device_authorization(
         %Client{} = client,
         request,
         clock,
         device_code,
         user_code,
         scopes
       ) do
    opts = request_opts(request)
    client_store = Keyword.get(opts, :client_store, Repository)
    device_store = device_authorization_store(request)
    transaction_store = Keyword.get(opts, :transaction_store, Repository)
    authority = transaction_store.transaction_authority()

    with :ok <- require_participants(authority, client_store, device_store, transaction_store),
         {:ok, _lifetime} <- ClientLifetime.adapt(client_store, authority),
         {:ok, {stored_auth, decision_time}} <-
           transaction_store.transact(fn ->
             with {:ok, [current_client]} <- client_store.lock_clients([client.client_id]),
                  decision_time <- clock.(),
                  :ok <- eligible(current_client, decision_time, :device_authorization),
                  device_auth <-
                    DeviceAuthorizationState.issue(
                      %{
                        client_id: client.client_id,
                        device_code: device_code,
                        user_code: user_code,
                        scopes: scopes
                      },
                      now: decision_time
                    ),
                  {:ok, stored} <- device_store.put_device_authorization(device_auth) do
               {:ok, {stored, decision_time}}
             else
               {:ok, []} -> {:error, :client_not_found}
               {:error, reason} -> {:error, reason}
             end
           end) do
      {:ok, {stored_auth, decision_time}}
    else
      {:error, %ClientAuth.Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _error -> {:error, :client_lifetime_unavailable}
  end

  defp eligible(%Client{} = client, %DateTime{} = now, consumer) do
    case ClientLifetime.validate_client(client) do
      {:ok, client} -> Client.app_eligibility(client, now, consumer)
      {:error, reason} -> {:error, reason}
    end
  end

  defp require_participants(%{identity: identity, participants: participants}, client, device, tx)
       when not is_nil(identity) and is_map(participants) do
    if Map.get(participants, :client_store) == client and
         Map.get(participants, :device_authorization_store) == device and
         Map.get(participants, :transaction_store) == tx do
      :ok
    else
      {:error, :transaction_authority_mismatch}
    end
  end

  defp require_participants(_authority, _client, _device, _tx),
    do: {:error, :transaction_authority_unavailable}

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
    opts = request_opts(request)
    client_store = Keyword.get(opts, :client_store, Repository)
    device_store = device_authorization_store(request)
    transaction_store = Keyword.get(opts, :transaction_store, Repository)
    authority = transaction_store.transaction_authority()

    with :ok <- require_participants(authority, client_store, device_store, transaction_store),
         {:ok, lifetime} <- ClientLifetime.adapt(client_store, authority) do
      {:ok,
       [
         client_store: client_store,
         client_lifetime: lifetime,
         now: clock(request),
         supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt]
       ]}
    end
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

  defp clock(request) do
    request
    |> request_opts()
    |> Keyword.get(:now, &DateTime.utc_now/0)
    |> case do
      %DateTime{} = now -> fn -> now end
      now when is_function(now, 0) -> now
      _other -> fn -> nil end
    end
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
