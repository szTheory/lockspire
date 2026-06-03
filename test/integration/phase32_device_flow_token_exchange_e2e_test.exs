defmodule Lockspire.Integration.Phase32DeviceFlowTokenExchangeE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

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

    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.TestAccountResolver
    )

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, {:shared, self()})

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Lockspire.SeedingHelpers.seed_signing_key()

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

    # Bypass poll interval
    bypass_poll_interval(device_code_body["device_code"])

    # Approve the request via the internal verification handle (the "host side")
    verification_handle = lookup_verification_handle(device_code_body["device_code"])

    approve_conn =
      build_conn()
      |> post("/verify/#{verification_handle}/approve", %{})

    assert approve_conn.status == 302

    # Redeem the code — Request 1: 200 OK
    first_token_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "client_id" => client.client_id,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => device_code_body["device_code"]
      })

    assert first_token_conn.status == 200
    first_token_body = Jason.decode!(first_token_conn.resp_body)
    assert first_token_body["access_token"]
    assert first_token_body["token_type"] == "Bearer"

    # Replay redemption — Request 2: 400 invalid_grant (collapses replay)
    replay_token_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "client_id" => client.client_id,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => device_code_body["device_code"]
      })

    assert replay_token_conn.status == 400
    replay_token_body = Jason.decode!(replay_token_conn.resp_body)
    assert replay_token_body["error"] == "invalid_grant"
  end

  test "host-denied device authorization returns authorization_pending (or slow_down) then access_denied", %{
    client: client
  } do
    device_code_conn =
      build_conn()
      |> post("/lockspire/device/code", %{
        "client_id" => client.client_id,
        "scope" => "profile email"
      })

    device_code_body = Jason.decode!(device_code_conn.resp_body)

    # Bypass poll interval
    bypass_poll_interval(device_code_body["device_code"])

    # Initial poll: pending or slow_down (both prove it's still alive)
    pending_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "client_id" => client.client_id,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => device_code_body["device_code"]
      })

    assert pending_conn.status == 400
    assert Jason.decode!(pending_conn.resp_body)["error"] in ["authorization_pending", "slow_down"]

    # Deny the request
    verification_handle = lookup_verification_handle(device_code_body["device_code"])

    deny_conn =
      build_conn()
      |> post("/verify/#{verification_handle}/deny", %{})

    assert deny_conn.status == 302

    # Final poll: access_denied
    denied_token_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "client_id" => client.client_id,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => device_code_body["device_code"]
      })

    assert denied_token_conn.status == 400
    assert Jason.decode!(denied_token_conn.resp_body)["error"] == "access_denied"
  end

  test "DPoP-bound device authorization enforces binding through to introspection", %{client: client} do
    dpop_keys = JarTestHelpers.generate_ec_keys()

    # Enable DPoP on client
    {:ok, client} = Repository.update_client(client, %{dpop_policy: :dpop})

    # Step 1: Start device flow
    device_code_conn =
      build_conn()
      |> post("/lockspire/device/code", %{
        "client_id" => client.client_id,
        "scope" => "profile email"
      })

    device_code_body = Jason.decode!(device_code_conn.resp_body)

    # Bypass poll interval
    bypass_poll_interval(device_code_body["device_code"])

    # Step 2: Approve
    verification_handle = lookup_verification_handle(device_code_body["device_code"])
    build_conn() |> post("/verify/#{verification_handle}/approve", %{})

    # Small wait for shared DB state to propagate
    Process.sleep(50)

    # Step 3: Redeem WITH DPoP (nonce dance)
    # Request 1: No proof -> 401 use_dpop_nonce
    challenge_conn =
      build_conn()
      |> post("/lockspire/token", %{
        "client_id" => client.client_id,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => device_code_body["device_code"]
      })

    assert challenge_conn.status == 401
    assert [nonce_challenge] = get_resp_header(challenge_conn, "www-authenticate")
    assert nonce_challenge =~ "error=\"use_dpop_nonce\""
    assert [retry_nonce] = get_resp_header(challenge_conn, "dpop-nonce")

    # Request 2: Valid proof + nonce -> 200
    token_url = GeneratedHostAppWeb.Endpoint.url() <> "/lockspire/token"
    proof = generate_dpop_proof(dpop_keys.private_jwk, "POST", token_url, retry_nonce)

    first_token_conn =
      build_conn()
      |> put_req_header("dpop", proof)
      |> post("/lockspire/token", %{
        "client_id" => client.client_id,
        "grant_type" => "urn:ietf:params:oauth:grant-type:device_code",
        "device_code" => device_code_body["device_code"]
      })

    assert first_token_conn.status == 200
    first_token_body = Jason.decode!(first_token_conn.resp_body)
    assert first_token_body["access_token"]
    assert first_token_body["token_type"] == "DPoP"

    # Step 4: Verify binding via introspection
    introspection_conn =
      build_conn()
      |> post("/lockspire/introspect", %{"token" => first_token_body["access_token"]})

    assert introspection_conn.status == 200
    introspection_body = Jason.decode!(introspection_conn.resp_body)
    assert introspection_body["active"] == true
    assert introspection_body["token_type"] == "access_token"
    assert introspection_body["cnf"]["jkt"]
  end

  defp bypass_poll_interval(device_code) do
    hash = Lockspire.Security.Policy.hash_token(device_code)
    import Ecto.Query
    Lockspire.Storage.Ecto.DeviceAuthorizationRecord
    |> where(device_code_hash: ^hash)
    |> Lockspire.TestRepo.update_all(set: [
         effective_poll_interval_seconds: 0,
         next_poll_allowed_at: ~U[2000-01-01 00:00:00Z]
       ])
  end

  defp lookup_verification_handle(device_code) do
    hash = Lockspire.Security.Policy.hash_token(device_code)
    import Ecto.Query
    Lockspire.Storage.Ecto.DeviceAuthorizationRecord
    |> where(device_code_hash: ^hash)
    |> Lockspire.TestRepo.one()
    |> Map.get(:verification_handle)
  end

  defp generate_dpop_proof(key, method, url, nonce) do
    claims =
      %{
        "htm" => method,
        "htu" => url,
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate()
      }
      |> then(fn map ->
        if nonce, do: Map.put(map, "nonce", nonce), else: map
      end)

    {_modules, public_map} = JOSE.JWK.to_public_map(key)

    {_, token} =
      JOSE.JWT.sign(
        key,
        %{"alg" => "ES256", "typ" => "dpop+jwt", "jwk" => public_map},
        claims
      )
      |> JOSE.JWS.compact()

    token
  end
end
