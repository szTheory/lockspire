defmodule CleanRoomClientWeb.JourneyController do
  use Phoenix.Controller, formats: [:json]
  import Plug.Conn

  alias CleanRoomClient.{DPoP, OAuthHttp, Transactions}

  def status(conn, _params) do
    json(conn, get_session(conn, :journey_receipt) || %{complete: false})
  end

  def callback_attempts(conn, _params) do
    json(conn, %{token_exchange_attempts: get_session(conn, :token_exchange_attempts, 0)})
  end

  def csrf(conn, _params), do: json(conn, %{csrf_token: Plug.CSRFProtection.get_csrf_token()})

  def resource_challenge(conn, _params) do
    with {:ok, session} <- session(conn),
         {:ok, access_token} <- encrypted_value(session.encrypted_access_token),
         {:ok, proof} <- DPoP.resource_proof(session, :get, resource(), nil),
         {:ok, 401, headers, _body} <- OAuthHttp.dpop_get(resource(), access_token, proof),
         true <- challenge?(headers, "use_dpop_nonce"),
         nonce when is_binary(nonce) <- headers["dpop-nonce"],
         :ok <- Transactions.store_resource_nonce(session.handle, DPoP.encrypt(nonce)) do
      json(conn, %{status: 401, challenge: "use_dpop_nonce", dpop_nonce_present: true})
    else
      _ -> reject(conn)
    end
  end

  def resource_retry(conn, _params) do
    with {:ok, session} <- session(conn),
         {:ok, access_token} <- encrypted_value(session.encrypted_access_token),
         {:ok, nonce} <- encrypted_value(session.encrypted_resource_nonce),
         {:ok, proof} <- DPoP.resource_proof(session, :get, resource(), nonce),
         {:ok, 200, _headers, body} <- OAuthHttp.dpop_get(resource(), access_token, proof),
         {:ok, %{"access_token" => %{"confirmation" => %{"dpop_jkt" => jkt}}}} <-
           Jason.decode(body),
         true <- jkt == session.jkt,
         :ok <- Transactions.store_accepted_resource_proof(session.handle, DPoP.encrypt(proof)) do
      json(conn, %{status: 200, confirmation_jkt_matches: true})
    else
      _ -> reject(conn)
    end
  end

  def resource_replay(conn, _params) do
    with {:session, {:ok, session}} <- {:session, session(conn)},
         {:access_token, {:ok, access_token}} <-
           {:access_token, encrypted_value(session.encrypted_access_token)},
         {:proof, {:ok, proof}} <- {:proof, encrypted_value(session.encrypted_accepted_resource_proof)},
         {:resource_response, {:ok, status, headers, _body}} <-
           {:resource_response, OAuthHttp.dpop_get(resource(), access_token, proof)},
         {:replay_status, true} <- {:replay_status, status in [400, 401]},
         {:replay_challenge, true} <-
           {:replay_challenge, challenge?(headers, "invalid_token")} do
      json(conn, %{status: status, challenge: "invalid_token"})
    else
      {stage, _reason} when stage in [:session, :access_token, :proof, :resource_response] ->
        reject(conn, stage)

      {:replay_status, _reason} ->
        reject(conn, :replay_status)

      {:replay_challenge, _reason} ->
        reject(conn, :replay_challenge)
    end
  end

  defp session(conn) do
    case get_session(conn, :dpop_session_handle) do
      handle when is_binary(handle) -> Transactions.active_dpop_session(handle)
      _ -> {:error, :missing_session}
    end
  end

  defp encrypted_value(value) when is_binary(value), do: DPoP.decrypt(value)
  defp encrypted_value(_value), do: {:error, :missing_value}

  defp challenge?(headers, error) do
    String.contains?(Map.get(headers, "www-authenticate", ""), "error=\"#{error}\"")
  end

  defp reject(conn, stage \\ :operation),
    do:
      conn
      |> put_status(:bad_request)
      |> json(%{error: "dpop_operation_rejected", stage: Atom.to_string(stage)})

  defp resource do
    Application.fetch_env!(:clean_room_confidential_client, :provider_issuer)
    |> String.replace_suffix("/lockspire", "/api/billing/summary")
  end
end
