defmodule Lockspire.Plug.RequireTokenTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  alias Lockspire.AccessToken
  alias Lockspire.Plug.RequireToken

  defp build_conn do
    conn(:get, "/")
  end

  describe "RequireToken plug" do
    test "allows request to proceed if valid AccessToken is assigned" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{error: nil, claims: %{"sub" => "123"}})
        |> RequireToken.call([])

      refute conn.halted
      assert conn.status == nil
    end

    test "halts with 401 and generic WWW-Authenticate if AccessToken is missing entirely" do
      conn =
        build_conn()
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401

      assert ["Bearer realm=\"Lockspire\""] = get_resp_header(conn, "www-authenticate")
      assert %{"error" => "invalid_token"} = Jason.decode!(conn.resp_body)
    end

    test "halts with 401 and generic WWW-Authenticate if error is :missing_token" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{error: :missing_token})
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401

      assert ["Bearer realm=\"Lockspire\""] = get_resp_header(conn, "www-authenticate")
      assert %{"error" => "invalid_token"} = Jason.decode!(conn.resp_body)
    end

    test "halts with 401 and detailed WWW-Authenticate if error is :invalid_token" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{error: :invalid_token})
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401

      assert [
               "Bearer realm=\"Lockspire\", error=\"invalid_token\", error_description=\"The access token is invalid or expired\""
             ] =
               get_resp_header(conn, "www-authenticate")

      assert %{
               "error" => "invalid_token",
               "error_description" => "The access token is invalid or expired"
             } = Jason.decode!(conn.resp_body)
    end

    test "halts with DPoP-aware challenge for typed sender-constraint failures" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{
          error: %{
            category: :sender_constraint,
            challenge: :dpop,
            reason_code: :missing_dpop_proof,
            error: "invalid_token",
            error_description: "A valid DPoP proof is required"
          }
        })
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401

      [challenge] = get_resp_header(conn, "www-authenticate")
      assert challenge =~ "DPoP realm=\"Lockspire\""
      assert challenge =~ "error=\"invalid_token\""
      assert challenge =~ "error_description=\"A valid DPoP proof is required\""
      assert challenge =~ "algs=\""

      assert %{
               "error" => "invalid_token",
               "error_description" => "A valid DPoP proof is required"
             } = Jason.decode!(conn.resp_body)
    end

    test "halts with DPoP nonce header when sender-constraint failure requests nonce retry" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{
          error: %{
            category: :sender_constraint,
            challenge: :dpop,
            reason_code: :missing_dpop_nonce,
            error: "use_dpop_nonce",
            error_description: "Resource server requires nonce in DPoP proof",
            dpop_nonce: "retry-nonce"
          }
        })
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401
      assert ["retry-nonce"] = get_resp_header(conn, "dpop-nonce")
      assert Enum.any?(get_resp_header(conn, "access-control-expose-headers"), &(&1 =~ "DPoP-Nonce"))
      [challenge] = get_resp_header(conn, "www-authenticate")
      assert challenge =~ "error=\"use_dpop_nonce\""
    end

    test "halts with bearer challenge for mtls sender-constraint failures" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{
          error: %{
            category: :sender_constraint,
            challenge: :bearer,
            reason_code: :invalid_client_certificate,
            error: "invalid_token",
            error_description: "Client certificate missing or thumbprint mismatch"
          }
        })
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401

      assert [
               "Bearer realm=\"Lockspire\", error=\"invalid_token\", error_description=\"Client certificate missing or thumbprint mismatch\""
             ] = get_resp_header(conn, "www-authenticate")

      assert %{
               "error" => "invalid_token",
               "error_description" => "Client certificate missing or thumbprint mismatch"
             } = Jason.decode!(conn.resp_body)
    end

    test "halts with 401 and structured invalid_token details for audience failures" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{
          error: %{
            category: :token_restriction,
            challenge: :bearer,
            reason_code: :invalid_audience,
            error: "invalid_token",
            error_description: "The access token audience is invalid for this route"
          }
        })
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 401

      assert [
               "Bearer realm=\"Lockspire\", error=\"invalid_token\", error_description=\"The access token audience is invalid for this route\""
             ] = get_resp_header(conn, "www-authenticate")

      assert %{
               "error" => "invalid_token",
               "error_description" => "The access token audience is invalid for this route"
             } = Jason.decode!(conn.resp_body)
    end

    test "halts with 403 and scope challenge for insufficient scope failures" do
      conn =
        build_conn()
        |> assign(:access_token, %AccessToken{
          error: %{
            category: :insufficient_scope,
            challenge: :bearer,
            reason_code: :insufficient_scope,
            error: "insufficient_scope",
            error_description: "The access token is missing a required scope",
            required_scopes: ["read:billing", "write:reports"]
          }
        })
        |> RequireToken.call([])

      assert conn.halted
      assert conn.status == 403

      assert [
               "Bearer realm=\"Lockspire\", error=\"insufficient_scope\", error_description=\"The access token is missing a required scope\", scope=\"read:billing write:reports\""
             ] = get_resp_header(conn, "www-authenticate")

      assert %{
               "error" => "insufficient_scope",
               "error_description" => "The access token is missing a required scope"
             } = Jason.decode!(conn.resp_body)
    end
  end
end
