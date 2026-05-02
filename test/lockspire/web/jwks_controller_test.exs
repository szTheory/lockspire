defmodule Lockspire.Web.JwksControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    now = DateTime.utc_now()

    assert {:ok, _key} =
             Repository.publish_key(%SigningKey{
               kid: "kid_active",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: %{
                 "kid" => "kid_active",
                 "kty" => "RSA",
                 "alg" => "RS256",
                 "use" => "sig",
                 "n" => "modulus-active",
                 "e" => "AQAB",
                 "d" => "private-should-not-leak"
               },
               private_jwk_encrypted: <<1, 2, 3>>,
               status: :active,
               published_at: now,
               activated_at: now
             })

    assert {:ok, _key} =
             Repository.publish_key(%SigningKey{
               kid: "kid_retiring",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: %{
                 "kid" => "kid_retiring",
                 "kty" => "RSA",
                 "alg" => "RS256",
                 "use" => "sig",
                 "n" => "modulus-retiring",
                 "e" => "AQAB"
               },
               private_jwk_encrypted: <<4, 5, 6>>,
               status: :retiring,
               published_at: now,
               activated_at: now,
               retiring_at: now
             })

    assert {:ok, _key} =
             Repository.publish_key(%SigningKey{
               kid: "kid_upcoming",
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk: %{"kid" => "kid_upcoming", "kty" => "RSA", "alg" => "RS256"},
               private_jwk_encrypted: <<7, 8, 9>>,
               status: :upcoming,
               published_at: now
             })

    assert {:ok, _key} =
             Repository.publish_key(%SigningKey{
               kid: "kid_enc",
               kty: :RSA,
               alg: "RS256",
               use: :enc,
               public_jwk: %{"kid" => "kid_enc", "kty" => "RSA", "alg" => "RS256", "use" => "enc"},
               private_jwk_encrypted: <<1, 2, 3>>,
               status: :active,
               published_at: now,
               activated_at: now
             })

    :ok
  end

  test "GET /jwks returns only publishable public keys" do
    conn =
      build_conn(:get, "/jwks")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["public, max-age=300"]

    body = Jason.decode!(conn.resp_body)
    assert %{"keys" => keys} = body
    assert Enum.map(keys, & &1["kid"]) == ["kid_active", "kid_retiring", "kid_upcoming", "kid_enc"]

    assert Enum.all?(keys, fn key ->
             key["alg"] == "RS256" and key["kty"] == "RSA" and key["use"] in ["sig", "enc"]
           end)

    refute Enum.any?(keys, &Map.has_key?(&1, "d"))
  end

  test "GET /jwks filters out RS256 keys when server profile is fapi_2_0_security" do
    Repository.update_server_policy(fn policy ->
      %{policy | security_profile: :fapi_2_0_security}
    end)

    conn =
      build_conn(:get, "/jwks")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert %{"keys" => keys} = body
    
    # All inserted keys are RS256, they should all be filtered out
    assert keys == []
  end
end
