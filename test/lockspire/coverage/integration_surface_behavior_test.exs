defmodule Lockspire.Coverage.IntegrationSurfaceBehaviorTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  test "the revocation endpoint fails closed when a confidential client omits credentials" do
    conn =
      build_conn(:post, "/revoke", %{"token" => "coverage-untrusted-token"})
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401
    assert %{"error" => "invalid_client"} = Jason.decode!(conn.resp_body)
    assert get_resp_header(conn, "www-authenticate") != []
  end
end
