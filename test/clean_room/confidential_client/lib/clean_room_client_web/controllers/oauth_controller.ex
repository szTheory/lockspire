defmodule CleanRoomClientWeb.OAuthController do
  use Phoenix.Controller, formats: [:html]
  alias CleanRoomClient.{DPoP, Transactions}

  @profiles %{
    bearer: %{
      client_id: "clean-room-bearer",
      callback_uri: "http://127.0.0.1:4200/oauth/callback"
    },
    dpop: %{
      client_id: "clean-room-dpop",
      callback_uri: "http://127.0.0.1:4200/oauth/dpop/callback"
    }
  }

  def start(conn, _params), do: begin(conn, :bearer)
  def dpop_start(conn, _params), do: begin(conn, :dpop)

  def callback(conn, params), do: terminal(conn, params, :bearer)
  def dpop_callback(conn, params), do: terminal(conn, params, :dpop)

  defp begin(conn, mode) do
    profile = Map.fetch!(@profiles, mode)

    transaction =
      Transactions.start(Map.merge(profile, %{profile: mode, issuer: provider_issuer()}))

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
         {:ok, _transaction} <- Transactions.consume(id, state),
         true <- is_binary(params["code"]) and is_nil(params["error"]) do
      text(conn, "callback consumed for #{mode}")
    else
      _ -> conn |> put_status(:bad_request) |> text("oauth callback rejected")
    end
  end

  defp authorization_url(transaction) do
    provider_issuer() <>
      "/authorize?" <>
      URI.encode_query(%{
        "response_type" => "code",
        "client_id" => transaction.client_id,
        "redirect_uri" => transaction.callback_uri,
        "scope" => "openid profile billing.read",
        "state" => transaction.state,
        "nonce" => transaction.nonce,
        "code_challenge" => transaction.challenge,
        "code_challenge_method" => "S256"
      })
  end

  defp provider_issuer,
    do:
      Application.get_env(
        :clean_room_confidential_client,
        :provider_issuer,
        "http://127.0.0.1:4100/lockspire"
      )
end
