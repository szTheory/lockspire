defmodule Lockspire.Protocol.PushedAuthorizationRequest do
  @moduledoc """
  Accepts pushed authorization requests and returns opaque PAR references.
  """

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.PushedAuthorizationRequest, as: PushedAuthorizationRequestState
  alias Lockspire.Protocol.AuthorizationRequest
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.RequestObject
  alias Lockspire.Storage.ClientLifetime
  alias Lockspire.Storage.Ecto.Repository

  defmodule Success do
    @moduledoc """
    Successful PAR response payload.
    """

    @type t :: %__MODULE__{
            request_uri: String.t(),
            expires_in: pos_integer()
          }

    defstruct [:request_uri, :expires_in]
  end

  defmodule Error do
    @moduledoc """
    PAR error payload safe for JSON responses.
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

  @spec push(map()) :: result()
  def push(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))
    now = now(request)

    with {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, post_jar_params} <- maybe_consume_request_object(params, client),
         {:ok, %AuthorizationRequest.Validated{} = validated} <-
           validate_request(post_jar_params, client, request),
         {:ok, %PushedAuthorizationRequestState{} = pushed_request} <-
           persist_pushed_request(validated, request, now) do
      {:ok,
       %Success{
         request_uri: pushed_request.request_uri,
         expires_in: DateTime.diff(pushed_request.expires_at, now, :second)
       }}
    else
      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp validate_request(params, %Client{} = client, request) do
    case AuthorizationRequest.validate_pushed(params, client,
           client_store: client_store(request),
           now: now(request)
         ) do
      {:ok, %AuthorizationRequest.Validated{} = validated} ->
        {:ok, validated}

      {:error, %AuthorizationRequest.Error{} = error} ->
        {:error, oauth_error(400, error.error, error.error_description, error.reason_code)}
    end
  end

  defp maybe_consume_request_object(%{"request" => req} = params, %Client{} = client)
       when is_binary(req) and req != "" do
    case RequestObject.consume(params, client, []) do
      {:ok, projected_params} ->
        {:ok, projected_params}

      {:browser_error, %AuthorizationRequest.Error{} = issue} ->
        {:error, wrap_jar_error(issue)}
    end
  end

  defp maybe_consume_request_object(params, %Client{}), do: {:ok, params}

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

  defp persist_pushed_request(%AuthorizationRequest.Validated{} = validated, request, now) do
    with :ok <- ensure_current_app_eligible(validated.client_id, request, now) do
      pushed_request =
        PushedAuthorizationRequestState.issue(
          %{
            client_id: validated.client_id,
            redirect_uri: validated.redirect_uri,
            scopes: validated.scopes,
            resources_requested: validated.resources,
            authorization_details: validated.authorization_details,
            prompt: validated.prompt,
            nonce: validated.nonce,
            state: validated.state,
            code_challenge: validated.code_challenge,
            code_challenge_method: validated.code_challenge_method,
            response_mode: validated.response_mode
          },
          now: now,
          request_uri_generator: request_uri_generator(request)
        )

      case pushed_authorization_request_store(request).put_pushed_authorization_request(
             pushed_request
           ) do
        {:ok, %PushedAuthorizationRequestState{} = stored_request} ->
          {:ok, stored_request}

        {:error, _reason} ->
          {:error,
           oauth_error(500, "server_error", "Unable to persist request", :par_store_failed)}
      end
    end
  end

  defp pushed_authorization_request_store(request) do
    request
    |> request_opts()
    |> Keyword.get(:pushed_authorization_request_store, Repository)
  end

  defp client_auth_options(request) do
    [client_store: client_store(request), now: now(request)]
  end

  defp client_store(request), do: Keyword.get(request_opts(request), :client_store, Repository)

  defp ensure_current_app_eligible(client_id, request, now) do
    store = client_store(request)

    with {:ok, declaration} <- {:ok, store.lifetime_contract()},
         {:ok, _support} <-
           ClientLifetime.adapt(store, Map.get(declaration, :transaction_authority)),
         {:ok, %Client{} = client} <- store.fetch_client_by_id(client_id),
         {:ok, client} <- ClientLifetime.validate_client(client) do
      case Client.app_eligibility(client, now, :par_creation) do
        :ok ->
          :ok

        {:error, :expired} ->
          {:error,
           oauth_error(
             401,
             "invalid_client",
             "Client application has expired",
             :client_app_expired
           )}

        {:error, :disabled} ->
          {:error,
           oauth_error(
             401,
             "invalid_client",
             "Client application is disabled",
             :client_app_disabled
           )}

        {:error, :invalid_lifetime_state} ->
          {:error,
           oauth_error(
             500,
             "server_error",
             "Unable to validate client lifetime state",
             :client_lifetime_state_invalid
           )}
      end
    else
      _other ->
        {:error,
         oauth_error(
           500,
           "server_error",
           "Unable to validate client lifetime state",
           :client_lifetime_unavailable
         )}
    end
  rescue
    _error ->
      {:error,
       oauth_error(
         500,
         "server_error",
         "Unable to validate client lifetime state",
         :client_lifetime_unavailable
       )}
  end

  defp request_uri_generator(request) do
    request
    |> request_opts()
    |> Keyword.get_lazy(:request_uri_generator, fn ->
      fn ->
        32
        |> :crypto.strong_rand_bytes()
        |> Base.url_encode64(padding: false)
      end
    end)
  end

  defp request_opts(request) do
    Map.get(request, :opts, Map.get(request, "opts", []))
  end

  defp now(request) do
    case Keyword.get(request_opts(request), :now) do
      %DateTime{} = now -> DateTime.truncate(now, :second)
      now_fun when is_function(now_fun, 0) -> now_fun.() |> DateTime.truncate(:second)
      nil -> DateTime.utc_now() |> DateTime.truncate(:second)
      _other -> nil
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

  defp wrap_jar_error(%AuthorizationRequest.Error{} = issue) do
    oauth_error(400, issue.error, issue.error_description, issue.reason_code)
  end
end
