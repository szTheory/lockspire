defmodule Lockspire.Integration.Phase54ResourceIndicatorsE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy
  alias Lockspire.Host.Claims
  alias Lockspire.Storage.Ecto.Repository

  defmodule ResourceHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "resource-user"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: to_string(account.id)
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context), do: raise "not implemented"
  end

  setup_all do
    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test")
    Application.put_env(:lockspire, :mount_path, "")
    Application.put_env(:lockspire, :known_scopes, ["openid", "offline_access"])
    Application.put_env(:lockspire, :account_resolver, ResourceHostResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, key_view} = Lockspire.Admin.Keys.generate_key()
    key_id = key_view.key.id
    {:ok, _} = Lockspire.Admin.Keys.publish_key(key_id)
    {:ok, _} = Lockspire.Admin.Keys.activate_key(key_id)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "resource-client",
        client_type: :confidential,
        client_secret_hash: Policy.hash_client_secret("secret"),
        name: "Resource Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_post,
        created_at: DateTime.utc_now()
      })

    %{client: client}
  end

  describe "RES-01: Resource Parameter Validation" do
    test "rejects resource with fragment", %{client: client} do
      code_verifier = String.duplicate("a", 43)
      code_challenge = :crypto.hash(:sha256, code_verifier) |> Base.url_encode64(padding: false)

      conn =
        build_conn()
        |> get("/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "resource" => "https://api.example.com/v1#fragment",
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce"
        })

      assert conn.status == 302
      location = get_resp_header(conn, "location") |> List.first()
      assert location =~ "error=invalid_target"
      assert location =~ "fragment"
    end
  end

  describe "RES-02: Targeted Audience Claims" do
    test "minted access tokens contain only requested resources", %{client: client} do
      code_verifier = String.duplicate("a", 43)
      code_challenge = :crypto.hash(:sha256, code_verifier) |> Base.url_encode64(padding: false)

      # 1. PAR with multiple resources
      par_conn =
        build_conn()
        |> post("/par", %{
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "response_type" => "code",
          "scope" => "openid",
          "redirect_uri" => List.first(client.redirect_uris),
          "resource" => ["https://api.one", "https://api.two"],
          "code_challenge" => code_challenge,
          "code_challenge_method" => "S256",
          "nonce" => "nonce"
        })

      assert par_conn.status == 201
      request_uri = Jason.decode!(par_conn.resp_body)["request_uri"]

      # 2. Authorize
      auth_conn =
        build_conn()
        |> get("/authorize", %{
          "client_id" => client.client_id,
          "request_uri" => request_uri
        })

      # Should redirect to consent
      assert auth_conn.status == 302
      location = get_resp_header(auth_conn, "location") |> List.first()
      assert location =~ "/consent/"

      interaction_id = location |> String.split("/") |> List.last()

      # 3. Approve interaction
      approve_conn =
        build_conn()
        |> post("/interactions/#{interaction_id}/complete", %{"decision" => "approve"})

      assert approve_conn.status == 302
      callback_location = get_resp_header(approve_conn, "location") |> List.first()
      query = URI.parse(callback_location).query |> URI.decode_query()
      code = query["code"]

      # 4. Exchange code for token with ONE resource
      token_conn =
        build_conn()
        |> post("/token", %{
          "grant_type" => "authorization_code",
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "code" => code,
          "redirect_uri" => List.first(client.redirect_uris),
          "code_verifier" => code_verifier,
          "resource" => "https://api.one"
        })

      assert token_conn.status == 200
      token_body = Jason.decode!(token_conn.resp_body)
      access_token = token_body["access_token"]

      # 5. Introspect to verify aud
      intro_conn =
        build_conn()
        |> post("/introspect", %{
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "token" => access_token
        })

      assert intro_conn.status == 200
      intro_body = Jason.decode!(intro_conn.resp_body)
      assert intro_body["active"] == true
      assert intro_body["aud"] == ["https://api.one"]
    end
  end

  describe "RES-03: Token Exchange Downscoping" do
    test "refresh token exchange intersects requested resources", %{client: client} do
      # Setup: issued refresh token with [R1, R2]
      now = DateTime.utc_now()
      rt_raw = "refresh_token_123"
      rt_hash = Policy.hash_token(rt_raw)

      refresh_token = %Token{
        token_hash: rt_hash,
        family_id: rt_hash,
        token_type: :refresh_token,
        client_id: client.client_id,
        account_id: "resource-user",
        scopes: ["openid", "offline_access"],
        audience: ["https://api.one", "https://api.two"],
        expires_at: DateTime.add(now, 3600, :second)
      }

      {:ok, _} = Repository.store_token(refresh_token)

      # 1. Refresh for R2
      token_conn =
        build_conn()
        |> post("/token", %{
          "grant_type" => "refresh_token",
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "refresh_token" => rt_raw,
          "resource" => "https://api.two"
        })

      assert token_conn.status == 200
      token_body = Jason.decode!(token_conn.resp_body)
      access_token = token_body["access_token"]

      # 2. Introspect
      intro_conn =
        build_conn()
        |> post("/introspect", %{
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "token" => access_token
        })

      assert intro_conn.status == 200
      intro_body = Jason.decode!(intro_conn.resp_body)
      assert intro_body["aud"] == ["https://api.two"]

      # 3. Request invalid resource (not in RT)
      fail_conn =
        build_conn()
        |> post("/token", %{
          "grant_type" => "refresh_token",
          "client_id" => client.client_id,
          "client_secret" => "secret",
          "refresh_token" => token_body["refresh_token"],
          "resource" => "https://api.three"
        })

      assert fail_conn.status == 400
      assert Jason.decode!(fail_conn.resp_body)["error"] == "invalid_grant"
    end
  end
end
