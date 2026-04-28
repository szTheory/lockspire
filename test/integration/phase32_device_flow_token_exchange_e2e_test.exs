defmodule Lockspire.Integration.Phase32DeviceFlowTokenExchangeE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn, only: [put_req_header: 3]

  alias Lockspire.Domain.Client
  alias Lockspire.JarTestHelpers
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "profile", "email"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostApp.Lockspire.TestAccountResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase32-device-client",
        name: "Bedroom TV",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
        allowed_scopes: ["profile", "email"],
        created_at: DateTime.utc_now()
      })

    %{client: client}
  end

  test "host-approved device authorization redeems once through /token and then collapses replay to invalid_grant",
       %{client: client} do
    device_code_conn =
      build_conn()
      |> post("/lockspire/device/code", %{
        "client_id" => client.client_id,
        "scope" => "profile email"
      })

    assert device_code_conn.status == 200

    device_code_body = Jason.decode!(device_code_conn.resp_body)
    assert device_code_body["verification_uri"] == "https://example.test/verify"
    assert device_code_body["interval"] == 5

    signed_in_conn =
      build_conn()
      |> init_test_session(%{"current_account_id" => "generated-host-user"})

    review_conn = prepare_form(signed_in_conn, "/verify", %{"user_code" => device_code_body["user_code"]})

    assert review_conn.status == 200
    assert review_conn.resp_body =~ "Approve device"

    handle = fetch_handle(review_conn.resp_body)

    approve_conn = submit_from(review_conn, "/verify/#{handle}/approve", %{})

    assert approve_conn.status in [302, 303]
    assert redirected_to(approve_conn) == "/verify"

    first_token_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "client_id" => client.client_id,
        "device_code" => device_code_body["device_code"]
      })

    assert first_token_conn.status == 200

    first_token_body = Jason.decode!(first_token_conn.resp_body)

    assert Map.keys(first_token_body) |> Enum.sort() == [
             "access_token",
             "expires_in",
             "scope",
             "token_type"
           ]

    assert first_token_body["token_type"] == "Bearer"
    assert first_token_body["scope"] == "profile email"

    replay_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "client_id" => client.client_id,
        "device_code" => device_code_body["device_code"]
      })

    assert replay_conn.status == 400

    replay_body = Jason.decode!(replay_conn.resp_body)
    assert replay_body["error"] == "invalid_grant"
  end

  test "host-approved DPoP device authorization binds only on /token and collapses replay to invalid_grant" do
    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase32-device-dpop-client",
        name: "CLI Device",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
        allowed_scopes: ["profile", "email", "offline_access"],
        dpop_policy: :dpop,
        created_at: DateTime.utc_now()
      })

    device_code_conn =
      build_conn()
      |> post("/lockspire/device/code", %{
        "client_id" => client.client_id,
        "scope" => "profile email offline_access"
      })

    assert device_code_conn.status == 200

    device_code_body = Jason.decode!(device_code_conn.resp_body)

    signed_in_conn =
      build_conn()
      |> init_test_session(%{"current_account_id" => "generated-host-user"})

    review_conn = prepare_form(signed_in_conn, "/verify", %{"user_code" => device_code_body["user_code"]})
    assert review_conn.status == 200

    handle = fetch_handle(review_conn.resp_body)

    approve_conn = submit_from(review_conn, "/verify/#{handle}/approve", %{})

    assert approve_conn.status in [302, 303]
    assert redirected_to(approve_conn) == "/verify"

    proof = dpop_proof_fixture()

    first_token_conn =
      build_conn()
      |> put_req_header("dpop", proof)
      |> post("/lockspire/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "client_id" => client.client_id,
        "device_code" => device_code_body["device_code"]
      })

    assert first_token_conn.status == 200

    first_token_body = Jason.decode!(first_token_conn.resp_body)
    assert first_token_body["token_type"] == "DPoP"

    replay_conn =
      build_conn()
      |> put_req_header("dpop", dpop_proof_fixture())
      |> post("/lockspire/token", %{
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "client_id" => client.client_id,
        "device_code" => device_code_body["device_code"]
      })

    assert replay_conn.status == 400

    replay_body = Jason.decode!(replay_conn.resp_body)
    assert replay_body["error"] == "invalid_grant"
  end

  defp prepare_form(conn, path, params) do
    token_conn =
      conn
      |> get("/verify")

    submit_from(token_conn, path, params)
  end

  defp submit_from(conn, path, params) do
    csrf_token = extract_csrf_token(conn.resp_body)

    conn
    |> recycle()
    |> post(path, Map.put(params, "_csrf_token", csrf_token))
  end

  defp extract_csrf_token(body) do
    ~r/name="_csrf_token" value="([^"]+)"/
    |> Regex.run(body, capture: :all_but_first)
    |> case do
      [token] -> token
      _ -> raise "expected CSRF token in response body"
    end
  end

  defp fetch_handle(body) do
    ~r{/verify/([^"/]+)/approve}
    |> Regex.run(body, capture: :all_but_first)
    |> case do
      [handle] -> handle
      _ -> raise "expected verification handle in review page"
    end
  end

  defp dpop_proof_fixture do
    keys = JarTestHelpers.generate_ec_keys()
    now = DateTime.utc_now()

    JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
      "htm" => "POST",
      "htu" => "https://example.test/lockspire/token",
      "iat" => DateTime.to_unix(now),
      "jti" => Ecto.UUID.generate()
    })
  end
end
