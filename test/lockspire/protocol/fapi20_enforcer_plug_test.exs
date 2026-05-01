defmodule Lockspire.Protocol.FAPI20EnforcerPlugTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Phoenix.ConnTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.FAPI20EnforcerPlug
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @endpoint Lockspire.Web.Endpoint

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    # Reset server policy to :none (safe baseline)
    {:ok, policy} = Repository.get_server_policy()
    Repository.put_server_policy(%{policy | security_profile: :none})

    :ok
  end

  # ---------------------------------------------------------------------------
  # Group A — Passthrough when effective profile is :none
  # ---------------------------------------------------------------------------

  describe "Group A: passthrough when profile is :none (global)" do
    test "A1: GET /authorize without request_uri, profile :none -> passthrough" do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :none})

      conn =
        build_conn(:get, "/authorize", %{"client_id" => "unknown", "redirect_uri" => "https://client.example.com/cb"})
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "A2: POST /token without dpop header, profile :none -> passthrough" do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :none})

      conn =
        build_conn(:post, "/token", %{"client_id" => "unknown"})
        |> Map.put(:path_info, ["token"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "A3: GET /userinfo with Bearer auth, profile :none -> passthrough" do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :none})

      conn =
        build_conn(:get, "/userinfo")
        |> put_req_header("authorization", "Bearer some-token")
        |> Map.put(:path_info, ["userinfo"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end
  end

  # ---------------------------------------------------------------------------
  # Group B — /authorize enforcement when profile is :fapi_2_0_security
  # ---------------------------------------------------------------------------

  describe "Group B: /authorize enforcement with :fapi_2_0_security" do
    setup do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})
      :ok
    end

    test "B1: GET /authorize without request_uri with valid redirect_uri -> 302 redirect with error" do
      {:ok, client} = register_client("b1-client")

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id,
          "redirect_uri" => "https://client.example.com/callback",
          "response_type" => "code"
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 302
      location = get_resp_header(conn, "location") |> List.first()
      assert location =~ "error=invalid_request"
      assert location =~ "error_description=request_uri+from+the+PAR+endpoint+is+required"
    end

    test "B2: GET /authorize WITH non-empty request_uri -> passthrough" do
      {:ok, client} = register_client("b2-client")

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id,
          "request_uri" => "urn:ietf:params:oauth:request_uri:abc123"
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "B3: GET /authorize without request_uri and without parseable redirect_uri -> 400 JSON" do
      {:ok, client} = register_client("b3-client")

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_request"
    end

    test "B4: GET /authorize with unknown client_id -> uses global profile (still rejects when global is FAPI)" do
      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => "nonexistent-client",
          "redirect_uri" => "https://client.example.com/callback"
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 302
      location = get_resp_header(conn, "location") |> List.first()
      assert location =~ "error=invalid_request"
    end
  end

  # ---------------------------------------------------------------------------
  # Group C — /token enforcement when profile is :fapi_2_0_security
  # ---------------------------------------------------------------------------

  describe "Group C: /token enforcement with :fapi_2_0_security" do
    setup do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})
      :ok
    end

    test "C1: POST /token without dpop header -> 400 JSON invalid_dpop_proof" do
      {:ok, client} = register_client("c1-client")

      conn =
        build_conn(:post, "/token", %{"client_id" => client.client_id})
        |> Map.put(:path_info, ["token"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_dpop_proof"
      assert body["error_description"] == "A valid DPoP proof is required"
    end

    test "C2: POST /token with non-empty dpop header -> passthrough" do
      {:ok, client} = register_client("c2-client")

      conn =
        build_conn(:post, "/token", %{"client_id" => client.client_id})
        |> put_req_header("dpop", "some.jwt.token")
        |> Map.put(:path_info, ["token"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "C3: POST /token with empty dpop header -> rejected as invalid_dpop_proof" do
      {:ok, client} = register_client("c3-client")

      conn =
        build_conn(:post, "/token", %{"client_id" => client.client_id})
        |> put_req_header("dpop", "")
        |> Map.put(:path_info, ["token"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_dpop_proof"
    end
  end

  # ---------------------------------------------------------------------------
  # Group D — /userinfo enforcement when profile is :fapi_2_0_security
  # ---------------------------------------------------------------------------

  describe "Group D: /userinfo enforcement with :fapi_2_0_security" do
    setup do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})
      :ok
    end

    test "D1: GET /userinfo with Bearer auth and no dpop header -> 401 JSON invalid_token with WWW-Authenticate" do
      conn =
        build_conn(:get, "/userinfo")
        |> put_req_header("authorization", "Bearer some-access-token")
        |> Map.put(:path_info, ["userinfo"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 401
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_token"
      assert body["error_description"] == "DPoP-bound access token required"

      www_auth = get_resp_header(conn, "www-authenticate") |> List.first()
      assert www_auth =~ ~s(DPoP realm=)
      assert www_auth =~ ~s(error="invalid_token")
    end

    test "D2: GET /userinfo with DPoP auth and dpop header -> passthrough" do
      conn =
        build_conn(:get, "/userinfo")
        |> put_req_header("authorization", "DPoP some-access-token")
        |> put_req_header("dpop", "some.dpop.jwt")
        |> Map.put(:path_info, ["userinfo"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "D3: POST /userinfo (alternate verb) with no dpop header -> 401 JSON invalid_token" do
      conn =
        build_conn(:post, "/userinfo")
        |> put_req_header("authorization", "Bearer some-access-token")
        |> Map.put(:path_info, ["userinfo"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 401
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_token"
    end
  end

  # ---------------------------------------------------------------------------
  # Group E — Exemptions
  # ---------------------------------------------------------------------------

  describe "Group E: exemptions (routes outside Plug responsibility)" do
    setup do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})
      :ok
    end

    test "E1: POST /par with profile :fapi_2_0_security and no request_uri -> passthrough (PAR is exempt)" do
      conn =
        build_conn(:post, "/par", %{"client_id" => "any-client"})
        |> Map.put(:path_info, ["par"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "E2: GET /jwks with profile :fapi_2_0_security -> passthrough (out of scope)" do
      conn =
        build_conn(:get, "/jwks")
        |> Map.put(:path_info, ["jwks"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "E3: GET /.well-known/openid-configuration with profile :fapi_2_0_security -> passthrough" do
      conn =
        build_conn(:get, "/.well-known/openid-configuration")
        |> Map.put(:path_info, [".well-known", "openid-configuration"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end

    test "E4: GET /admin/clients with profile :fapi_2_0_security -> passthrough" do
      conn =
        build_conn(:get, "/admin/clients")
        |> Map.put(:path_info, ["admin", "clients"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end
  end

  # ---------------------------------------------------------------------------
  # Group F — Error handling (fail-closed on policy unavailability)
  # ---------------------------------------------------------------------------

  describe "Group F: fail-closed on policy unavailability" do
    test "F1: Repository.get_server_policy/0 error -> 503 JSON server_error halted" do
      # We pass opts with a mock policy_fn that simulates DB failure
      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => "any-client",
          "redirect_uri" => "https://client.example.com/callback"
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call(policy_fn: fn -> {:error, :unavailable} end)

      assert conn.halted
      assert conn.status == 503
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "server_error"
      assert body["error_description"] == "Security profile unavailable"
    end
  end

  # ---------------------------------------------------------------------------
  # Group G — Per-client override
  # ---------------------------------------------------------------------------

  describe "Group G: per-client security profile override" do
    test "G1: global :none but client has :fapi_2_0_security override; /authorize without request_uri -> rejected" do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :none})

      {:ok, fapi_client} =
        Repository.register_client(%Client{
          client_id: "fapi-only-g1",
          client_secret_hash: Policy.hash_client_secret("g1-secret"),
          client_type: :confidential,
          name: "FAPI Override Client G1",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["openid"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: false,
          subject_type: :public,
          created_at: DateTime.utc_now(),
          metadata: %{},
          security_profile: :fapi_2_0_security
        })

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => fapi_client.client_id,
          "redirect_uri" => "https://client.example.com/callback"
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      assert conn.halted
      assert conn.status == 302
      location = get_resp_header(conn, "location") |> List.first()
      assert location =~ "error=invalid_request"
    end

    test "G2: global :fapi_2_0_security but client has :none override; /authorize without request_uri -> passthrough (mixed-mode escape hatch)" do
      {:ok, policy} = Repository.get_server_policy()
      Repository.put_server_policy(%{policy | security_profile: :fapi_2_0_security})

      {:ok, exempted_client} =
        Repository.register_client(%Client{
          client_id: "none-override-g2",
          client_secret_hash: Policy.hash_client_secret("g2-secret"),
          client_type: :confidential,
          name: "None Override Client G2",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["openid"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: false,
          subject_type: :public,
          created_at: DateTime.utc_now(),
          metadata: %{},
          security_profile: :none
        })

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => exempted_client.client_id,
          "redirect_uri" => "https://client.example.com/callback"
        })
        |> Map.put(:path_info, ["authorize"])
        |> FAPI20EnforcerPlug.call([])

      refute conn.halted
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp register_client(client_id) do
    Repository.register_client(%Client{
      client_id: client_id,
      client_secret_hash: Policy.hash_client_secret("test-secret-#{client_id}"),
      client_type: :confidential,
      name: "Test Client #{client_id}",
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: false,
      subject_type: :public,
      created_at: DateTime.utc_now(),
      metadata: %{}
    })
  end
end
