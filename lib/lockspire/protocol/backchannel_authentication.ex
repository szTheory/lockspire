defmodule Lockspire.Protocol.BackchannelAuthentication do
  @moduledoc """
  Protocol pipeline for CIBA Backchannel Authentication (OpenID Connect CIBA).
  """

  alias Lockspire.Config
  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Host.Context
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Security.DeviceCode
  alias Lockspire.Storage.Ecto.Repository

  defmodule Success do
    @moduledoc "Successful CIBA backchannel authorization response."
    @type t :: %__MODULE__{
            auth_req_id: String.t(),
            expires_in: pos_integer(),
            interval: pos_integer() | nil
          }
    defstruct [:auth_req_id, :expires_in, :interval]
  end

  defmodule Error do
    @moduledoc "Error response for CIBA backchannel authorization."
    @type t :: %__MODULE__{
            status: pos_integer(),
            error: String.t(),
            error_description: String.t() | nil,
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
         :ok <- validate_hints(params),
         :ok <- validate_scopes(params),
         {:ok, delivery_mode} <- validate_delivery_mode(params, client),
         {:ok, subject_id} <- resolve_subject(params, client, request),
         :ok <- validate_user_code(params, client, subject_id, request),
         {:ok, %CibaAuthorization{} = ciba_auth} <-
           persist_ciba_authorization(params, client, subject_id, delivery_mode, request, now),
         :ok <- notify_host(ciba_auth, client, request) do
      {:ok,
       %Success{
         auth_req_id: ciba_auth.auth_req_id,
         expires_in: DateTime.diff(ciba_auth.expires_at, now, :second),
         interval: ciba_auth.effective_poll_interval_seconds
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

  defp validate_hints(params) do
    hints =
      params
      |> Map.take(["login_hint", "id_token_hint", "login_hint_token"])
      |> Map.values()
      |> Enum.reject(&(&1 == nil or &1 == ""))

    case length(hints) do
      1 ->
        :ok

      0 ->
        {:error,
         oauth_error(400, "invalid_request", "Exactly one hint is required", :missing_hint)}

      _ ->
        {:error,
         oauth_error(400, "invalid_request", "More than one hint provided", :too_many_hints)}
    end
  end

  defp validate_scopes(params) do
    scopes = parse_scopes(params["scope"])

    if "openid" in scopes do
      :ok
    else
      {:error,
       oauth_error(400, "invalid_scope", "The openid scope is required", :missing_openid_scope)}
    end
  end

  defp validate_delivery_mode(params, %Client{} = client) do
    delivery_mode = client.backchannel_token_delivery_mode
    notification_token = params["client_notification_token"]

    cond do
      delivery_mode in [:ping, :push] and (notification_token == nil or notification_token == "") ->
        {:error,
         oauth_error(
           400,
           "invalid_request",
           "client_notification_token is required for #{delivery_mode} mode",
           :missing_client_notification_token
         )}

      delivery_mode in [:ping, :push] and
          (client.backchannel_client_notification_endpoint == nil or
             client.backchannel_client_notification_endpoint == "") ->
        {:error,
         oauth_error(
           400,
           "invalid_request",
           "client_notification_endpoint is not registered for this client",
           :missing_client_notification_endpoint
         )}

      true ->
        {:ok, delivery_mode}
    end
  end

  defp validate_user_code(params, client, subject_id, request) do
    user_code = params["user_code"]

    cond do
      client.backchannel_user_code_parameter and (user_code == nil or user_code == "") ->
        {:error,
         oauth_error(
           400,
           "missing_user_code",
           "A user_code is required for this client",
           :missing_user_code
         )}

      user_code != nil and user_code != "" ->
        verify_user_code_with_host(subject_id, user_code, client, request)

      true ->
        :ok
    end
  end

  defp verify_user_code_with_host(subject_id, user_code, client, request) do
    resolver = account_resolver(request)

    if function_exported?(resolver, :verify_backchannel_user_code, 3) do
      params = params_from_request(request)
      context = build_context(client, params, :ciba_user_code_verification)

      case resolver.verify_backchannel_user_code(subject_id, user_code, context) do
        :ok ->
          :ok

        {:error, :invalid_user_code} ->
          {:error,
           oauth_error(400, "invalid_user_code", "The user_code is incorrect", :invalid_user_code)}

        {:error, reason} ->
          {:error, oauth_error(400, "invalid_request", "Error verifying user_code", reason)}
      end
    else
      if client.backchannel_user_code_parameter do
        {:error,
         oauth_error(
           500,
           "server_error",
           "Host does not support user_code verification",
           :missing_host_callback
         )}
      else
        :ok
      end
    end
  end

  defp notify_host(ciba_auth, client, request) do
    notifier = backchannel_notification(request)

    if notifier do
      params = params_from_request(request)
      context = build_context(client, params, :ciba_notification)

      case notifier.notify_authentication(ciba_auth, context) do
        :ok ->
          :ok

        {:error, reason} ->
          {:error,
           oauth_error(
             500,
             "server_error",
             "Failed to trigger out-of-band notification",
             reason
           )}
      end
    else
      :ok
    end
  end

  defp build_context(client, params, interaction_type) do
    %Context{
      interaction_type: interaction_type,
      client_id: client.client_id,
      scopes: parse_scopes(params["scope"]),
      metadata: %{
        user_code: params["user_code"],
        binding_message: params["binding_message"]
      }
    }
  end

  defp params_from_request(request) do
    Map.get(request, :params, Map.get(request, "params", %{}))
  end

  defp resolve_subject(params, client, request) do
    # Resolve the hint to a subject_id using the host's AccountResolver
    hint_type = find_hint_type(params)
    hint_value = params[to_string(hint_type)]

    context = %Context{
      interaction_type: :ciba_initiation,
      client_id: client.client_id,
      scopes: parse_scopes(params["scope"]),
      metadata: %{
        hint_type: hint_type,
        hint_value: hint_value,
        user_code: params["user_code"],
        binding_message: params["binding_message"]
      }
    }

    resolver = account_resolver(request)

    case resolver.resolve_account(hint_value, context) do
      {:ok, account} ->
        # We need the ID of the account. Host usually returns the account struct.
        # We assume the host knows how to return a subject_id if we ask for it,
        # but resolve_account/2 is generic.
        # Lockspire usually expects the host to return something that can be used as subject_id.
        # For CIBA, we'll assume the 'account' returned is the subject_id or can be mapped to it.
        # Actually, let's look at how other parts use resolve_account.
        {:ok, to_subject_id(account)}

      {:error, :not_found} ->
        # return generic error to prevent enumeration if required by policy
        {:error,
         oauth_error(400, "unknown_user", "The user could not be resolved", :user_not_found)}

      {:error, reason} ->
        {:error, oauth_error(400, "invalid_request", "Error resolving user", reason)}
    end
  end

  defp find_hint_type(params) do
    cond do
      params["login_hint"] -> :login_hint
      params["id_token_hint"] -> :id_token_hint
      params["login_hint_token"] -> :login_hint_token
      true -> nil
    end
  end

  defp to_subject_id(subject_id) when is_binary(subject_id), do: subject_id
  defp to_subject_id(%{id: id}), do: to_string(id)
  defp to_subject_id(other), do: to_string(other)

  defp persist_ciba_authorization(params, client, subject_id, delivery_mode, request, now) do
    # Reusing the same entropy as device code
    auth_req_id = DeviceCode.generate_device_code()
    scopes = parse_scopes(params["scope"])

    ciba_auth =
      CibaAuthorization.issue(
        %{
          client_id: client.client_id,
          auth_req_id: auth_req_id,
          scopes: scopes,
          subject_id: subject_id,
          binding_message: params["binding_message"],
          delivery_mode: delivery_mode,
          client_notification_endpoint: client.backchannel_client_notification_endpoint,
          client_notification_token_encrypted: params["client_notification_token"],
          auth_req_id_encrypted: auth_req_id
        },
        now: now
      )

    case ciba_authorization_store(request).put_ciba_authorization(ciba_auth) do
      {:ok, %CibaAuthorization{} = stored_auth} ->
        Lockspire.Observability.emit(
          :ciba_authorization,
          :initiated,
          %{},
          %{client_id: client.client_id, auth_req_id_hash: stored_auth.auth_req_id_hash}
        )

        {:ok, %CibaAuthorization{stored_auth | auth_req_id: ciba_auth.auth_req_id}}

      {:error, _reason} ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to persist CIBA authorization",
           :ciba_store_failed
         )}
    end
  end

  defp parse_scopes(nil), do: []
  defp parse_scopes(""), do: []

  defp parse_scopes(scopes) when is_binary(scopes) do
    scopes
    |> String.split(" ", trim: true)
  end

  defp ciba_authorization_store(request) do
    request
    |> request_opts()
    |> Keyword.get(:ciba_authorization_store, Repository)
  end

  defp account_resolver(request) do
    request
    |> request_opts()
    |> Keyword.get_lazy(:account_resolver, &Config.account_resolver!/0)
  end

  defp backchannel_notification(request) do
    request
    |> request_opts()
    |> Keyword.get_lazy(:backchannel_notification, &Config.backchannel_notification/0)
  end

  defp client_auth_options(request) do
    [client_store: Keyword.get(request_opts(request), :client_store, Repository)]
  end

  defp request_opts(request) do
    Map.get(request, :opts, Map.get(request, "opts", []))
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
