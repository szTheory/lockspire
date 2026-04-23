defmodule Lockspire.Web.JwksController do
  @moduledoc """
  Thin JWKS delivery adapter.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Jwks
  alias Lockspire.Web.JwksJSON

  def index(conn, _params) do
    case Jwks.public_jwk_set() do
      {:ok, jwk_set} ->
        conn
        |> put_resp_header("cache-control", "public, max-age=300")
        |> put_status(:ok)
        |> json(JwksJSON.jwk_set(jwk_set))

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "server_error", error_description: "Unable to load signing keys"})
    end
  end
end
