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
         outcome <- complete_journey(transaction, code, mode) do
      case outcome do
        {:ok, receipt} ->
          conn |> put_session(:journey_receipt, receipt) |> text("callback complete")

        {:host_denied, receipt} ->
          conn
          |> put_session(:journey_receipt, receipt)
          |> put_status(:bad_request)
          |> text("oauth callback rejected")

        {:error, {:journey_failed, stage}} ->
          conn
          |> put_session(:journey_receipt, %{complete: false, failed_stage: stage})
          |> put_status(:bad_request)
          |> text("oauth callback rejected")

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

  defp complete_journey(_transaction, _code, _mode), do: {:error, :unsupported_profile}

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
    label = if match?({:error, _}, value), do: "#{name}:#{elem(value, 1)}", else: name
    Process.put(:clean_room_stage, label)
    value
  end
end
