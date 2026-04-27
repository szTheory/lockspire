defmodule Lockspire.Web.DiscoveryController do
  @moduledoc """
  Thin discovery delivery adapter.
  """

  use Phoenix.Controller, formats: [:json]

  alias Lockspire.Protocol.Discovery
  alias Lockspire.Web.DiscoveryJSON

  def show(conn, _params) do
    conn
    |> put_resp_header("cache-control", "public, max-age=300")
    |> put_status(:ok)
    |> json(DiscoveryJSON.openid_configuration(Discovery.openid_configuration()))
  end
end
