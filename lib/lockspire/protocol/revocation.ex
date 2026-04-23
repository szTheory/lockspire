defmodule Lockspire.Protocol.Revocation do
  @moduledoc """
  Revokes client-bound opaque access and refresh tokens with RFC-safe success semantics.
  """

  alias Lockspire.Config
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Observability
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.TokenFormatter

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

  @type result :: :ok | {:error, Error.t()}

  @spec revoke(map()) :: result()
  def revoke(request) when is_map(request) do
    params = Map.get(request, :params, Map.get(request, "params", request))
    authorization = Map.get(request, :authorization, Map.get(request, "authorization"))

    with {:ok, token_hash} <- fetch_token_hash(params),
         {:ok, %Client{} = client} <- authenticate_client(params, authorization, request),
         {:ok, revoked_token} <- revoke_token(client, token_hash, request) do
      emit_success(client, revoked_token)
      :ok
    else
      {:error, %Error{} = error} ->
        emit_failure(error, params)
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

  defp revoke_token(%Client{} = client, token_hash, request) do
    revoked_at = now(request)

    case transact_with_optional_audit(token_store(request), fn ->
           case token_store(request).revoke_lifecycle_token(token_hash, client.client_id, revoked_at) do
             {:ok, %Token{} = token} ->
               {:ok, token, [revocation_audit_event(client, token)]}

             {:ok, nil} ->
               {:ok, nil, []}

             {:error, reason} ->
               {:error, reason}
           end
         end) do
      {:ok, token} -> {:ok, token}
      {:error, _reason} -> {:error, server_error("Unable to revoke token", :revocation_failed)}
    end
  end

  defp emit_success(%Client{} = client, revoked_token) do
    metadata = %{
      client_id: client.client_id,
      token_id: token_id(revoked_token),
      token_type: token_type(revoked_token),
      outcome: if(is_struct(revoked_token, Token), do: :revoked, else: :no_match)
    }

    Observability.emit(:token_revoked, %{}, metadata)
  end

  defp emit_failure(%Error{} = error, params) do
    Observability.emit(:revocation_failed, %{}, %{
      reason_code: error.reason_code,
      error: error.error,
      token_type_hint: Map.get(params, "token_type_hint")
    })
  end

  defp token_id(%Token{id: id}), do: id
  defp token_id(_other), do: nil

  defp token_type(%Token{token_type: token_type}), do: token_type
  defp token_type(_other), do: nil

  defp invalid_request(description, reason_code) do
    %Error{
      status: 400,
      error: "invalid_request",
      error_description: description,
      reason_code: reason_code
    }
  end

  defp server_error(description, reason_code) do
    %Error{
      status: 500,
      error: "server_error",
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

  defp transact_with_optional_audit(store, fun) when is_function(fun, 0) do
    store.transact(fn ->
      case fun.() do
        {:ok, result, audit_events} ->
          case append_audit_events(store, audit_events) do
            :ok -> result
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  defp append_audit_events(_store, []), do: :ok

  defp append_audit_events(store, [event | rest]) do
    case store.append_audit_event(event) do
      {:ok, _event} -> append_audit_events(store, rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp revocation_audit_event(%Client{} = client, %Token{} = token) do
    %{
      action: :token_revoked,
      outcome: :succeeded,
      reason_code: :token_revoked,
      actor: %{type: :client, id: client.client_id, display: client.client_id},
      resource: %{type: token.token_type, id: to_string(token.id || token.token_hash)},
      metadata: %{
        client_id: client.client_id,
        subject_id: token.account_id,
        family_id: token.family_id
      }
    }
  end
end
