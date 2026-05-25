defmodule Lockspire.Plug.RequireToken do
  @moduledoc """
  A strict enforcement plug that ensures a valid `Lockspire.AccessToken`
  is present in `conn.assigns[:access_token]`. If not, it halts the connection
  and responds with a 401 Unauthorized and the appropriate RFC 6750 headers.
  """

  @behaviour Plug

  import Plug.Conn

  alias Lockspire.AccessToken
  alias Lockspire.Web.ProtectedResourceChallenge

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    case conn.assigns[:access_token] do
      %AccessToken{error: nil, claims: claims} when not is_nil(claims) ->
        conn

      %AccessToken{error: :missing_token} ->
        handle_missing_token(conn)

      %AccessToken{error: error} when is_map(error) ->
        handle_structured_error(conn, error)

      %AccessToken{error: _reason} ->
        handle_invalid_token(conn, default_invalid_error())

      _ ->
        handle_missing_token(conn)
    end
  end

  defp handle_missing_token(conn) do
    body = Jason.encode!(%{error: "invalid_token"})

    conn
    |> put_resp_header("www-authenticate", "Bearer realm=\"Lockspire\"")
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
    |> halt()
  end

  defp handle_invalid_token(conn, error) do
    conn =
      case error do
        %{challenge: :dpop} ->
          ProtectedResourceChallenge.put_dpop_challenge(conn, error, realm: "Lockspire")

        _other ->
          put_resp_header(conn, "www-authenticate", www_authenticate(error))
      end

    conn
    |> send_json(401, oauth_body(error))
    |> halt()
  end

  defp handle_insufficient_scope(conn, error) do
    conn
    |> put_resp_header("www-authenticate", www_authenticate(error))
    |> send_json(403, oauth_body(error))
    |> halt()
  end

  defp handle_structured_error(conn, %{category: :sender_constraint} = error),
    do: handle_invalid_token(conn, normalize_sender_error(error))

  defp handle_structured_error(conn, %{category: :insufficient_scope} = error),
    do: handle_insufficient_scope(conn, normalize_insufficient_scope_error(error))

  defp handle_structured_error(conn, error),
    do: handle_invalid_token(conn, normalize_invalid_error(error))

  defp normalize_sender_error(error) do
    %{
      challenge: Map.get(error, :challenge, :bearer),
      error: Map.get(error, :error, "invalid_token"),
      error_description:
        Map.get(error, :error_description, "The access token is invalid or expired"),
      dpop_nonce: Map.get(error, :dpop_nonce)
    }
  end

  defp default_invalid_error do
    %{
      challenge: :bearer,
      error: "invalid_token",
      error_description: "The access token is invalid or expired"
    }
  end

  defp normalize_invalid_error(error) do
    %{
      challenge: Map.get(error, :challenge, :bearer),
      error: Map.get(error, :error, "invalid_token"),
      error_description:
        Map.get(error, :error_description, "The access token is invalid or expired")
    }
  end

  defp normalize_insufficient_scope_error(error) do
    required_scopes =
      error
      |> Map.get(:required_scopes, [])
      |> Enum.filter(&is_binary/1)

    %{
      challenge: :bearer,
      error: Map.get(error, :error, "insufficient_scope"),
      error_description:
        Map.get(error, :error_description, "The access token is missing a required scope"),
      scope: Enum.join(required_scopes, " ")
    }
  end

  defp www_authenticate(%{
         error: "insufficient_scope",
         error_description: description,
         scope: scope
       })
       when is_binary(scope) and scope != "" do
    ~s(Bearer realm="Lockspire", error="insufficient_scope", error_description="#{description}", scope="#{scope}")
  end

  defp www_authenticate(%{error: error, error_description: description}) do
    ~s(Bearer realm="Lockspire", error="#{error}", error_description="#{description}")
  end

  defp oauth_body(error) do
    %{
      error: error.error,
      error_description: error.error_description
    }
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
