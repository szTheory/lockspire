defmodule Lockspire.Web.RegistrationController do
  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Registration
  alias Lockspire.Protocol.RegistrationManagement
  alias Lockspire.Protocol.RegistrationAccessToken
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.RegistrationJSON

  plug(:ensure_dcr_enabled when action in [:create])

  def create(conn, params) do
    source = %{
      ip: to_string(:inet.ntoa(conn.remote_ip)),
      user_agent: List.first(get_req_header(conn, "user-agent"))
    }

    iat = extract_bearer_token(conn)
    {:ok, server_policy} = Repository.get_server_policy()

    case Registration.register(%{
           metadata: params,
           server_policy: server_policy,
           source: source,
           iat: iat,
           secret_key_base: conn.secret_key_base
         }) do
      {:ok, success} ->
        conn
        |> put_status(:created)
        |> json(RegistrationJSON.success_response(success))

      {:error, error} ->
        handle_error(conn, error)
    end
  end

  def show(conn, %{"client_id" => client_id}) do
    case lookup_client_by_rat(conn) do
      {:ok, client} ->
        case RegistrationManagement.read(client_id, client) do
          {:ok, client} ->
            json(conn, RegistrationJSON.read_response(client))

          {:error, error} ->
            handle_error(conn, error)
        end

      {:error, reason} ->
        handle_lookup_error(conn, reason)
    end
  end

  def update(conn, %{"client_id" => client_id} = params) do
    case lookup_client_by_rat(conn) do
      {:ok, client} ->
        case Repository.get_server_policy() do
          {:ok, server_policy} ->
            metadata = Map.delete(params, "client_id")

            request_map = %{
              metadata: metadata,
              server_policy: server_policy,
              client: client
            }

            case RegistrationManagement.update(client_id, request_map) do
              {:ok, success} ->
                json(conn, RegistrationJSON.update_response(success))

              {:error, error} ->
                handle_error(conn, error)
            end

          {:error, _reason} ->
            handle_error(conn, :server_error)
        end

      {:error, reason} ->
        handle_lookup_error(conn, reason)
    end
  end

  def delete(conn, %{"client_id" => client_id}) do
    case lookup_client_by_rat(conn) do
      {:ok, client} ->
        case RegistrationManagement.delete(client_id, client) do
          :ok ->
            send_resp(conn, 204, "")

          {:error, error} ->
            handle_error(conn, error)
        end

      {:error, reason} ->
        handle_lookup_error(conn, reason)
    end
  end

  defp ensure_dcr_enabled(conn, _opts) do
    {:ok, server_policy} = Repository.get_server_policy()

    if server_policy.registration_policy == :disabled do
      conn
      |> send_resp(404, "")
      |> halt()
    else
      conn
    end
  end

  defp extract_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token | _] -> String.trim(token)
      _ -> nil
    end
  end

  defp lookup_client_by_rat(conn) do
    case extract_bearer_token(conn) do
      nil ->
        {:error, :missing_credential}

      token when is_binary(token) ->
        case Repository.get_client_by_registration_access_token_hash(
               RegistrationAccessToken.hash(token)
             ) do
          {:ok, %Lockspire.Domain.Client{} = client} ->
            {:ok, client}

          {:ok, nil} ->
            {:error, :invalid_token}

          {:error, _reason} ->
            {:error, :server_error}

          _unsupported ->
            {:error, :server_error}
        end
    end
  end

  defp handle_lookup_error(conn, :missing_credential), do: handle_error(conn, :missing_credential)
  defp handle_lookup_error(conn, :invalid_token), do: handle_error(conn, :invalid_token)
  defp handle_lookup_error(conn, _reason), do: handle_error(conn, :server_error)

  defp handle_error(conn, :missing_credential) do
    conn
    |> put_status(401)
    |> put_resp_header(
      "www-authenticate",
      "Bearer realm=\"Lockspire Dynamic Client Registration\""
    )
    |> send_resp(401, "")
  end

  defp handle_error(conn, %Registration.Error{code: :invalid_token}) do
    conn
    |> put_status(401)
    |> put_resp_header(
      "www-authenticate",
      "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
    )
    |> send_resp(401, "")
  end

  defp handle_error(conn, :invalid_token) do
    conn
    |> put_status(401)
    |> put_resp_header(
      "www-authenticate",
      "Bearer realm=\"Lockspire Dynamic Client Registration\", error=\"invalid_token\""
    )
    |> send_resp(401, "")
  end

  defp handle_error(conn, %Registration.Error{code: :server_error}),
    do: server_error_response(conn)

  defp handle_error(conn, %Registration.Error{code: :persistence_error}),
    do: server_error_response(conn)

  defp handle_error(conn, :server_error), do: server_error_response(conn)

  defp handle_error(conn, %Registration.Error{code: :invalid_client_metadata} = e) do
    conn
    |> put_status(400)
    |> json(RegistrationJSON.error_response(e))
  end

  defp handle_error(conn, %Registration.Error{code: code} = e) do
    status =
      case code do
        :invalid_redirect_uri -> 400
        :invalid_client -> 401
        :unauthorized_client -> 401
        :access_denied -> 403
        :registration_expired -> 403
        :server_error -> 500
        :persistence_error -> 500
        _ -> 400
      end

    conn
    |> put_status(status)
    |> json(RegistrationJSON.error_response(e))
  end

  defp handle_error(conn, _reason), do: server_error_response(conn)

  defp server_error_response(conn) do
    conn
    |> put_status(500)
    |> json(%{error: "server_error"})
  end
end
