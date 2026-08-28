defmodule CleanRoomClientWeb.OAuthController do
  use Phoenix.Controller, formats: [:html]
  alias CleanRoomClient.{DPoP, OIDCVerifier, OAuthHttp, Transactions}

  @profiles %{
    bearer: %{
      client_id: "clean-room-bearer",
      callback_uri: "/oauth/callback"
    },
    dpop: %{
      client_id: "clean-room-dpop",
      callback_uri: "/oauth/dpop/callback"
    }
  }

  def start(conn, _params), do: begin(conn, :bearer)
  def dpop_start(conn, _params), do: begin(conn, :dpop)

  def callback(conn, params), do: terminal(conn, params, :bearer)
  def dpop_callback(conn, params), do: terminal(conn, params, :dpop)

  def replace_nonce(conn, _params) do
    case get_session(conn, :oauth_transaction_id) do
      id when is_integer(id) ->
        case Transactions.replace_nonce(id) do
          :ok -> json(conn, %{nonce: "replaced"})
          _ -> conn |> put_status(:bad_request) |> json(%{error: "terminal"})
        end

      _ ->
        conn |> put_status(:bad_request) |> json(%{error: "missing_transaction"})
    end
  end

  defp begin(conn, mode) do
    profile = Map.fetch!(@profiles, mode)

    transaction =
      Transactions.start(
        Map.merge(profile, %{
          profile: mode,
          issuer: provider_issuer(),
          callback_uri: callback_uri(profile)
        })
      )

    transaction =
      if mode == :dpop do
        key = DPoP.new_key()

        Transactions.attach_dpop_key(
          transaction,
          DPoP.encrypt(Jason.encode!(key.private_jwk)),
          key.jkt
        )
      else
        transaction
      end

    conn
    |> put_session(:oauth_transaction_id, transaction.id)
    |> redirect(external: authorization_url(transaction))
  end

  defp terminal(conn, params, mode) do
    with id when is_integer(id) <- get_session(conn, :oauth_transaction_id),
         state when is_binary(state) <- params["state"],
         {:ok, transaction} <- Transactions.consume(id, state),
         code when is_binary(code) <- params["code"],
         true <- is_nil(params["error"]),
         conn =
           put_session(
             conn,
             :token_exchange_attempts,
             get_session(conn, :token_exchange_attempts, 0) + 1
           ),
         outcome <- complete_journey(transaction, code, mode) do
      case outcome do
        {:ok, receipt} ->
          conn
          |> maybe_put_dpop_session(receipt)
          |> put_session(:journey_receipt, receipt)
          |> text("callback complete")

        {:host_denied, receipt} ->
          conn
          |> put_session(:journey_receipt, receipt)
          |> put_status(:bad_request)
          |> text("oauth callback rejected")

        {:error, {:journey_failed, stage}} ->
          conn
          |> put_session(:journey_receipt, %{complete: false, failed_stage: stage})
          |> put_status(:bad_request)
          |> text("oauth callback rejected: #{stage}")

        _ ->
          conn |> put_status(:bad_request) |> text("oauth callback rejected")
      end
    else
      _ ->
        conn
        |> put_session(:journey_receipt, %{complete: false, failed_stage: :callback_params})
        |> put_status(:bad_request)
        |> text("oauth callback rejected: callback_params")
    end
  end

  defp complete_journey(transaction, code, :bearer) do
    with {:ok, 200, _headers, discovery_body} <-
           stage(:discovery, OAuthHttp.get_json(discovery_url(transaction.issuer))),
         {:ok, discovery} <- decode(discovery_body),
         {:ok, metadata} <-
           stage(:discovery, OIDCVerifier.validate_metadata(discovery, transaction.issuer)),
         {:ok, 200, _headers, jwks_body} <- stage(:jwks, OAuthHttp.get_json(metadata.jwks_uri)),
         {:ok, jwks} <- decode(jwks_body),
         {:ok, secret} <- File.read(bearer_secret_path()),
         {:ok, 200, _headers, token_body} <-
           stage(
             :token,
             OAuthHttp.token_exchange(
               discovery["token_endpoint"],
               transaction,
               %{
                 client_id: transaction.client_id,
                 client_secret: String.trim(secret),
                 mode: :bearer
               },
               %{code: code, resource: provider_origin() <> "/api/billing"}
             )
           ),
         {:ok, token} <- decode(token_body),
         id_token when is_binary(id_token) <- token["id_token"],
         access_token when is_binary(access_token) <- token["access_token"],
         {:ok, claims} <-
           stage(:oidc, OIDCVerifier.verify_id_token(id_token, jwks, transaction, metadata)),
         {:ok, 200, _headers, userinfo_body} <-
           stage(:userinfo, OAuthHttp.bearer_get(discovery["userinfo_endpoint"], access_token)),
         {:ok, userinfo} <- decode(userinfo_body),
         true <- OIDCVerifier.same_subject?(userinfo, claims),
         resource_result <-
           stage(
             :resource,
             OAuthHttp.bearer_get(provider_origin() <> "/api/billing/summary", access_token)
           ) do
      complete_resource(resource_result, claims)
    else
      _ -> {:error, {:journey_failed, Process.get(:clean_room_stage, :unknown)}}
    end
  end

  defp complete_journey(transaction, code, :dpop) do
    with {:ok, 200, _headers, discovery_body} <-
           stage(:discovery, OAuthHttp.get_json(discovery_url(transaction.issuer))),
         {:ok, discovery} <- decode(discovery_body),
         {:ok, metadata} <-
           stage(:discovery, OIDCVerifier.validate_metadata(discovery, transaction.issuer)),
         {:ok, 200, _headers, jwks_body} <- stage(:jwks, OAuthHttp.get_json(metadata.jwks_uri)),
         {:ok, jwks} <- decode(jwks_body),
         {:ok, secret} <- stage(:dpop_secret, File.read(dpop_secret_path())),
         {:ok, token, token_nonce_retry?} <-
           stage(
             :dpop_token,
             dpop_token_exchange(transaction, code, discovery, String.trim(secret))
           ),
         id_token when is_binary(id_token) <- token["id_token"],
         access_token when is_binary(access_token) <- token["access_token"],
         "DPoP" <- token["token_type"],
         {:ok, claims} <-
           stage(:oidc, OIDCVerifier.verify_id_token(id_token, jwks, transaction, metadata)),
         {:ok, userinfo, userinfo_nonce_retry?} <-
           stage(
             :dpop_userinfo,
             dpop_userinfo(transaction, discovery["userinfo_endpoint"], access_token)
           ),
         true <- OIDCVerifier.same_subject?(userinfo, claims),
         {:ok, session} <-
           stage(
             :dpop_session,
             Transactions.handoff_dpop_session(
               transaction,
               DPoP.encrypt(access_token),
               claims["sub"]
             )
           ) do
      {:ok,
       %{
         complete: true,
         profile: "dpop",
         stages: ["discovery", "authorization", "callback", "oidc", "userinfo"],
         subject: claims["sub"],
         dpop_session: session.handle,
         dpop_jkt: session.jkt,
         token_nonce_retry: token_nonce_retry?,
         userinfo_nonce_retry: userinfo_nonce_retry?
       }}
    else
      _ -> {:error, {:journey_failed, Process.get(:clean_room_stage) || :unknown}}
    end
  end

  defp complete_journey(_transaction, _code, _mode), do: {:error, :unsupported_profile}

  defp dpop_token_exchange(transaction, code, discovery, secret) do
    with {:ok, private_jwk} <- DPoP.decrypt(transaction.encrypted_dpop_key),
         token_endpoint when is_binary(token_endpoint) <- discovery["token_endpoint"],
         {:ok, proof} <- dpop_proof(private_jwk, :post, token_endpoint),
         response <-
           OAuthHttp.token_exchange(
             token_endpoint,
             transaction,
             %{client_id: transaction.client_id, client_secret: secret, mode: :dpop},
             %{code: code, resource: provider_origin() <> "/api/billing", proof: proof}
           ) do
      dpop_token_retry(transaction, code, token_endpoint, secret, private_jwk, response)
    end
  end

  defp dpop_token_retry(_transaction, _code, _endpoint, _secret, _key, {:ok, 200, _headers, body}) do
    with {:ok, token} <- decode(body), do: {:ok, token, false}
  end

  defp dpop_token_retry(
         transaction,
         code,
         endpoint,
         secret,
         private_jwk,
         {:ok, 400, headers, body}
       ) do
    with {:ok, %{"error" => "use_dpop_nonce"}} <- decode(body),
         nonce when is_binary(nonce) <- headers["dpop-nonce"],
         {:ok, proof} <- dpop_proof(private_jwk, :post, endpoint, nonce),
         {:ok, 200, _headers, retry_body} <-
           OAuthHttp.token_exchange(
             endpoint,
             transaction,
             %{client_id: transaction.client_id, client_secret: secret, mode: :dpop},
             %{code: code, resource: provider_origin() <> "/api/billing", proof: proof}
           ),
         {:ok, token} <- decode(retry_body) do
      {:ok, token, true}
    else
      _ -> {:error, :token_nonce_retry}
    end
  end

  defp dpop_token_retry(_transaction, _code, _endpoint, _secret, _key, _response),
    do: {:error, :token_exchange}

  defp dpop_userinfo(transaction, endpoint, token) do
    with {:ok, private_jwk} <- DPoP.decrypt(transaction.encrypted_dpop_key),
         {:ok, proof} <- dpop_proof(private_jwk, :get, endpoint, nil, token),
         response <- OAuthHttp.userinfo(endpoint, token, proof) do
      dpop_userinfo_retry(private_jwk, endpoint, token, response)
    end
  end

  defp dpop_userinfo_retry(_key, _endpoint, _token, {:ok, 200, _headers, body}) do
    with {:ok, userinfo} <- decode(body), do: {:ok, userinfo, false}
  end

  defp dpop_userinfo_retry(private_jwk, endpoint, token, {:ok, 401, headers, _body}) do
    with nonce when is_binary(nonce) <- headers["dpop-nonce"],
         {:ok, proof} <- dpop_proof(private_jwk, :get, endpoint, nonce, token),
         {:ok, 200, _headers, retry_body} <- OAuthHttp.userinfo(endpoint, token, proof),
         {:ok, userinfo} <- decode(retry_body) do
      {:ok, userinfo, true}
    else
      _ -> {:error, :userinfo_nonce_retry}
    end
  end

  defp dpop_userinfo_retry(_key, _endpoint, _token, _response), do: {:error, :userinfo}

  defp dpop_proof(private_jwk, method, endpoint, nonce \\ nil, token \\ nil) do
    options = %{}
    options = if is_binary(nonce), do: Map.put(options, :nonce, nonce), else: options

    options =
      if is_binary(token),
        do: Map.put(options, :ath, DPoP.access_token_hash(token)),
        else: options

    {:ok, DPoP.proof(Jason.decode!(private_jwk), method, endpoint, options)}
  rescue
    _ -> {:error, :proof}
  end

  defp complete_resource({:ok, 200, _headers, body}, claims) do
    with {:ok, %{"access_token" => semantic}} <- decode(body),
         true <- semantic_response?(semantic) do
      {:ok,
       %{
         complete: true,
         stages: ["discovery", "authorization", "callback", "oidc", "userinfo", "resource"],
         subject: claims["sub"],
         resource: semantic
       }}
    else
      _ -> {:error, {:journey_failed, :resource_contract}}
    end
  end

  defp complete_resource({:ok, 403, _headers, _body}, claims) do
    {:host_denied,
     %{
       complete: false,
       stages: ["discovery", "authorization", "callback", "oidc", "userinfo", "resource"],
       subject: claims["sub"],
       host_policy: "denied"
     }}
  end

  defp complete_resource(_, _claims), do: {:error, {:journey_failed, :resource_http}}

  defp authorization_url(transaction) do
    provider_issuer() <>
      "/authorize?" <>
      URI.encode_query(%{
        "response_type" => "code",
        "client_id" => transaction.client_id,
        "redirect_uri" => transaction.callback_uri,
        "scope" => "openid profile read:billing",
        "state" => transaction.state,
        "nonce" => transaction.nonce,
        "code_challenge" => transaction.challenge,
        "code_challenge_method" => "S256",
        "resource" => provider_origin() <> "/api/billing"
      })
  end

  defp provider_issuer,
    do:
      Application.get_env(
        :clean_room_confidential_client,
        :provider_issuer,
        "http://127.0.0.1:4100/lockspire"
      )

  defp provider_origin, do: String.replace_suffix(provider_issuer(), "/lockspire", "")
  defp discovery_url(issuer), do: issuer <> "/.well-known/openid-configuration"
  defp callback_uri(profile), do: client_origin() <> profile.callback_uri

  defp client_origin,
    do:
      Application.get_env(
        :clean_room_confidential_client,
        :client_origin,
        "http://127.0.0.1:4101"
      )

  defp bearer_secret_path, do: System.fetch_env!("CLEAN_ROOM_BEARER_SECRET_PATH")
  defp dpop_secret_path, do: System.fetch_env!("CLEAN_ROOM_DPOP_SECRET_PATH")
  defp decode(body), do: Jason.decode(body)

  defp semantic_response?(%{
         "subject" => subject,
         "scopes" => scopes,
         "audiences" => audiences,
         "expires_at" => expires_at,
         "confirmation" => confirmation
       }) do
    is_binary(subject) and is_list(scopes) and is_list(audiences) and
      (is_binary(expires_at) or is_nil(expires_at)) and
      (is_map(confirmation) or is_nil(confirmation))
  end

  defp semantic_response?(_), do: false

  defp stage(name, value) do
    Process.put(:clean_room_stage, name)
    value
  end

  defp maybe_put_dpop_session(conn, %{dpop_session: handle}) when is_binary(handle),
    do: put_session(conn, :dpop_session_handle, handle)

  defp maybe_put_dpop_session(conn, _receipt), do: conn
end
