defmodule Lockspire.Web.IntrospectionController do
  @moduledoc """
  Thin `/introspect` delivery adapter over protocol-owned opaque token classification.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Config
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.Introspection.Error
  alias Lockspire.Protocol.Introspection.Success
  alias Lockspire.Protocol.IntrospectionJwt
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.IntrospectionJSON

  @jwt_media_type "application/token-introspection+jwt"

  def create(conn, params) do
    authorization = List.first(get_req_header(conn, "authorization"))

    wants_jwt? = accepts_introspection_jwt?(conn)

    case Introspection.introspect(%{
           params: params,
           authorization: authorization,
           opts:
             [client_store: Repository, token_store: Repository, consent_store: Repository]
             |> Keyword.put(:mtls_cert, conn.private[:lockspire_mtls_cert])
         }) do
      {:ok, %Success{} = success} ->
        if success.strict_jwt_required? and not wants_jwt? do
          conn
          |> put_cache_headers()
          |> maybe_put_vary_accept(true)
          |> put_status(:bad_request)
          |> json(IntrospectionJSON.error_response(strict_jwt_required_error()))
        else
          conn
          |> put_cache_headers()
          |> maybe_put_vary_accept(wants_jwt? or success.strict_jwt_required?)
          |> render_success(success, wants_jwt?)
        end

      {:error, %Error{} = error} ->
        conn
        |> put_cache_headers()
        |> maybe_put_www_authenticate(error)
        |> put_status(error.status)
        |> json(IntrospectionJSON.error_response(error))
    end
  end

  defp put_cache_headers(conn) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("pragma", "no-cache")
  end

  defp maybe_put_www_authenticate(conn, %Error{error: "invalid_client"}) do
    put_resp_header(conn, "www-authenticate", ~s(Basic realm="Lockspire Token Endpoint"))
  end

  defp maybe_put_www_authenticate(conn, _error), do: conn

  defp render_success(conn, %Success{} = success, true) do
    case IntrospectionJwt.sign(%{
           success: success,
           issuer: Config.issuer!(),
           issued_at: DateTime.utc_now(),
           key_store: Repository
         }) do
      {:ok, jwt} ->
        conn
        |> put_resp_header("content-type", @jwt_media_type)
        |> send_resp(:ok, jwt)

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(IntrospectionJSON.error_response(server_error()))
    end
  end

  defp render_success(conn, success, false) do
    conn
    |> put_status(:ok)
    |> json(IntrospectionJSON.response(success))
  end

  defp accepts_introspection_jwt?(conn) do
    conn
    |> get_req_header("accept")
    |> Enum.flat_map(&Plug.Conn.Utils.list/1)
    |> Enum.reduce_while(:absent, fn entry, _acc ->
      case parse_accept_entry(entry) do
        {:ok, {@jwt_media_type, q}} when q > 0.0 -> {:halt, true}
        {:ok, {@jwt_media_type, _q}} -> {:cont, false}
        {:ok, _other} -> {:cont, :absent}
        :error -> {:halt, false}
      end
    end)
    |> Kernel.==(true)
  end

  defp parse_accept_entry(entry) when is_binary(entry) do
    with [media_type | params] <- String.split(entry, ";"),
         normalized_media_type when normalized_media_type != "" <-
           media_type |> String.trim() |> String.downcase(),
         {:ok, q} <- parse_q_value(params) do
      {:ok, {normalized_media_type, q}}
    else
      _other -> :error
    end
  end

  defp parse_q_value(params) do
    Enum.reduce_while(params, {:ok, 1.0}, fn param, _acc ->
      case String.split(param, "=", parts: 2) do
        [key, value] ->
          normalized_key = key |> String.trim() |> String.downcase()
          normalized_value = String.trim(value)

          if normalized_key == "q" do
            case Float.parse(normalized_value) do
              {q, ""} when q >= 0.0 and q <= 1.0 -> {:halt, {:ok, q}}
              _other -> {:halt, :error}
            end
          else
            {:cont, {:ok, 1.0}}
          end

        _other ->
          {:halt, :error}
      end
    end)
  end

  defp maybe_put_vary_accept(conn, true), do: put_resp_header(conn, "vary", "Accept")
  defp maybe_put_vary_accept(conn, false), do: conn

  defp server_error do
    %Error{
      status: 500,
      error: "server_error",
      error_description: "Unable to sign introspection response",
      reason_code: :introspection_signing_failed
    }
  end

  defp strict_jwt_required_error do
    %Error{
      status: 400,
      error: "invalid_request",
      error_description: "Accept must include application/token-introspection+jwt",
      reason_code: :strict_jwt_accept_required
    }
  end
end
