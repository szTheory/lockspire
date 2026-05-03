defmodule Lockspire.Protocol.Introspection do
  @moduledoc """
  Returns caller-authorized opaque token state while collapsing inactive outcomes to `active: false`.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.TokenFormatter

  defmodule Error do
    @moduledoc """
    Introspection endpoint error payload.
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

  @spec introspect(map()) :: result()
  def introspect(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, token_hash} <- fetch_token_hash(params),
         {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, response} <- introspection_response(client, token_hash, request) do
      emit_result(client, response)
      {:ok, response}
    else
      {:error, %Error{} = error} ->
        emit_failure(error)
        {:error, error}
    end
  end

  defp fetch_token_hash(%{"token" => token}) when is_binary(token) do
    token
    |> String.trim()
    |> case do
      "" -> {:error, invalid_request("token is required", :missing_token)}
      value -> {:ok, TokenFormatter.hash_token(value)}
    end
  end

  defp fetch_token_hash(_params),
    do: {:error, invalid_request("token is required", :missing_token)}

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

  defp introspection_response(%Client{} = client, token_hash, request) do
    with {:ok, true} <- validate_confidential_caller(client),
         {:ok, token} <- fetch_lifecycle_token(token_hash, request) do
      classify_token(client, token, now(request))
    else
      {:ok, false} -> inactive_response()
      {:error, :lookup_failed} -> raise_lookup_error()
    end
  end

  defp validate_confidential_caller(%Client{
         client_type: :confidential,
         token_endpoint_auth_method: method
       })
       when method in [:client_secret_basic, :client_secret_post] do
    {:ok, true}
  end

  defp validate_confidential_caller(_client), do: {:ok, false}

  defp fetch_lifecycle_token(token_hash, request) do
    case token_store(request).fetch_lifecycle_token(token_hash) do
      {:ok, token} -> {:ok, token}
      {:error, _reason} -> {:error, :lookup_failed}
    end
  end

  defp classify_token(%Client{} = client, %Token{} = token, now) do
    cond do
      token.client_id != client.client_id ->
        inactive_response()

      token.token_type not in [:access_token, :refresh_token] ->
        inactive_response()

      not is_nil(token.reuse_detected_at) ->
        inactive_response()

      not is_nil(token.revoked_at) ->
        inactive_response()

      DateTime.compare(token.expires_at, now) != :gt ->
        inactive_response()

      true ->
        {:ok, active_response(token)}
    end
  end

  defp classify_token(_client, nil, _now), do: inactive_response()

  defp active_response(%Token{} = token) do
    %{
      active: true,
      client_id: token.client_id,
      token_type: Atom.to_string(token.token_type),
      scope: Enum.join(token.scopes, " "),
      sub: token.account_id,
      aud: empty_to_nil(token.audience),
      exp: DateTime.to_unix(token.expires_at),
      iat: maybe_unix(token.issued_at)
    }
    |> maybe_put(:jti, token.jti)
    |> maybe_put(:cnf, token.cnf)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp inactive_response, do: {:ok, %{active: false}}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp empty_to_nil([]), do: nil
  defp empty_to_nil(value), do: value

  defp maybe_unix(nil), do: nil
  defp maybe_unix(%DateTime{} = datetime), do: DateTime.to_unix(datetime)

  defp raise_lookup_error do
    {:error,
     %Error{
       status: 500,
       error: "server_error",
       error_description: "Unable to load token",
       reason_code: :token_lookup_failed
     }}
  end

  defp emit_result(%Client{} = client, %{"active" => _} = _response) do
    # unreachable because controller-facing responses use atom keys, but keep clause for completeness
    Observability.emit(:token, :introspected, %{}, %{client_id: client.client_id, active: false})
  end

  defp emit_result(%Client{} = client, %{active: active} = response) do
    Observability.emit(:token, :introspected, %{}, %{
      client_id: client.client_id,
      active: active,
      token_type: Map.get(response, :token_type),
      subject_id: Map.get(response, :sub)
    })
  end

  defp emit_failure(%Error{} = error) do
    Observability.emit(:introspection, :failed, %{}, %{
      reason_code: error.reason_code,
      error: error.error
    })
  end

  defp invalid_request(description, reason_code) do
    %Error{
      status: 400,
      error: "invalid_request",
      error_description: description,
      reason_code: reason_code
    }
  end

  defp client_auth_options(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.put_new(:client_store, Config.repo!())
  end

  defp token_store(request),
    do:
      request
      |> Map.get(:opts, [])
      |> Keyword.get(:token_store, Config.repo!())

  defp now(request) do
    request
    |> Map.get(:opts, [])
    |> Keyword.get_lazy(:now, fn -> &DateTime.utc_now/0 end)
    |> then(& &1.())
  end
end
