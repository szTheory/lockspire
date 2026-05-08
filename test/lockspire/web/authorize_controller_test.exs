defmodule Lockspire.Web.AuthorizeControllerLoginResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context) do
    {:redirect, redirect_for_login(nil, %{})}
  end

  @impl true
  def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

  @impl true
  def build_claims(account, _context) do
    {:ok, %Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, _context) do
    %InteractionResult{login_path: "/sign-in", params: %{"source" => "authorize"}}
  end
end

defmodule Lockspire.Web.AuthorizeControllerAuthenticatedResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "account-123"}}

  @impl true
  def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

  @impl true
  def build_claims(account, _context) do
    {:ok, %Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, _context) do
    %InteractionResult{login_path: "/sign-in"}
  end
end

defmodule Lockspire.Web.AuthorizeControllerTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.JarTestHelpers
  alias Lockspire.Storage.Ecto.Repository
  import Phoenix.ConnTest

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "offline_access"])

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://issuer.test/lockspire")

    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.AuthorizeControllerLoginResolver
    )

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client_123",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Acme Integrations",
        redirect_uris: [
          "https://client.example.com/callback",
          "https://client.example.com/callback?foo=bar&state=old-state"
        ],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "invalid client_id renders a first-party error response" do
    conn = call_authorize(valid_params("missing"))

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "Authorization request rejected"
    assert conn.resp_body =~ "Unknown client_id"
  end

  test "mismatched redirect_uri renders a first-party error response" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("redirect_uri", "https://attacker.example.com/callback")
      |> call_authorize()

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "redirect_uri must match a registered URI"
  end

  describe "JAR-by-value (RFC 9101) at /authorize — browser boundary" do
    setup do
      %{pub_jwk_map: pub_jwk_map, private_jwk: private_jwk} = JarTestHelpers.generate_keys()

      {:ok, client} =
        Repository.register_client(%Client{
          client_id: "client_jar",
          client_secret_hash: "sha256:salt:hash",
          client_type: :confidential,
          name: "JAR Integrations",
          redirect_uris: ["https://client.example.com/callback"],
          allowed_scopes: ["profile", "email"],
          allowed_grant_types: ["authorization_code"],
          allowed_response_types: ["code"],
          token_endpoint_auth_method: :client_secret_basic,
          pkce_required: true,
          subject_type: :public,
          jwks: pub_jwk_map,
          created_at: DateTime.utc_now(),
          metadata: %{}
        })

      %{client: client, private_jwk: private_jwk}
    end

    test "renders the first-party browser error page when JAR signature is invalid", %{
      client: client
    } do
      %{private_jwk: wrong_jwk} = JarTestHelpers.generate_keys()

      bad_jwt =
        JarTestHelpers.sign_jar(
          wrong_jwk,
          jar_claims_for_controller(client.client_id, hd(client.redirect_uris))
        )

      conn = call_authorize(%{"client_id" => client.client_id, "request" => bad_jwt})

      assert conn.status == 400
      refute redirected?(conn)
      assert conn.resp_body =~ "Authorization request rejected"
      assert conn.resp_body =~ "Request object signature is invalid"
    end

    test "redirects to the host login surface when JAR is valid (redirect-safe handoff)", %{
      client: client,
      private_jwk: private_jwk
    } do
      jwt =
        JarTestHelpers.sign_jar(
          private_jwk,
          jar_claims_for_controller(client.client_id, hd(client.redirect_uris))
        )

      conn = call_authorize(%{"client_id" => client.client_id, "request" => jwt})

      assert conn.status in [302, 303]
      assert redirected?(conn)

      location = redirect_location(conn)
      assert location =~ "/sign-in?"
      assert location =~ "source=authorize"
      assert location =~ "interaction_id="
      assert location =~ "return_to=%2Flockspire%2Fconsent%2F"
    end
  end

  test "redirect-safe validation failures redirect with oauth error params and preserved state" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("prompt", "select_account")
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "https://client.example.com/callback"
    assert location =~ "error=invalid_request"
    assert location =~ "state=state-123"
  end

  test "invalid prompt=none combinations redirect to the trusted callback with preserved state" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("prompt", "none consent")
      |> call_authorize()

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert "#{uri.scheme}://#{uri.host}#{uri.path}" == "https://client.example.com/callback"
    assert params["error"] == "invalid_request"
    assert params["state"] == "state-123"
    assert params["iss"] == "https://issuer.test/lockspire"
  end

  test "invalid max_age stays redirect-safe and returns oauth invalid_request" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("max_age", "12.5")
      |> call_authorize()

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert "#{uri.scheme}://#{uri.host}#{uri.path}" == "https://client.example.com/callback"
    assert params["error"] == "invalid_request"
    assert params["state"] == "state-123"
  end

  test "missing nonce on openid requests remains redirect-safe with preserved state" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("scope", "openid email profile")
      |> Map.delete("nonce")
      |> call_authorize()

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert "#{uri.scheme}://#{uri.host}#{uri.path}" == "https://client.example.com/callback"
    assert params["error"] == "invalid_request"
    assert params["state"] == "state-123"
  end

  test "redirect-safe validation failures merge existing redirect query params canonically" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("redirect_uri", "https://client.example.com/callback?foo=bar&state=old-state")
      |> Map.put("prompt", "select_account")
      |> call_authorize()

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    assert uri.scheme == "https"
    assert uri.host == "client.example.com"
    assert uri.path == "/callback"

    params = URI.decode_query(uri.query || "")

    assert params["foo"] == "bar"
    assert params["state"] == "state-123"
    assert params["error"] == "invalid_request"
    refute uri.query =~ "state=old-state"
  end

  test "required-PAR direct requests redirect to the trusted exact callback with oauth error params",
       %{client: client} do
    put_server_policy!(:required)

    conn =
      client.client_id
      |> valid_params()
      |> Map.delete("prompt")
      |> call_authorize()

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    assert uri.scheme == "https"
    assert uri.host == "client.example.com"
    assert uri.path == "/callback"

    params = URI.decode_query(uri.query || "")

    assert params["error"] == "invalid_request"
    assert params["error_description"] == "request_uri from the PAR endpoint is required"
    assert params["state"] == "state-123"
  end

  test "required-PAR direct requests without redirect safety render the first-party error page",
       %{client: client} do
    put_server_policy!(:required)

    conn =
      client.client_id
      |> valid_params()
      |> Map.put("redirect_uri", "https://attacker.example.com/callback")
      |> call_authorize()

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "Authorization request rejected"
    assert conn.resp_body =~ "request_uri from the PAR endpoint is required"
  end

  test "optional-PAR direct requests keep the existing browser login handoff", %{client: client} do
    put_server_policy!(:required)
    update_client_par_policy!(client, :optional)

    conn =
      client.client_id
      |> valid_params()
      |> Map.delete("prompt")
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "/sign-in?"
    assert location =~ "source=authorize"
    assert location =~ "interaction_id="
    assert location =~ "return_to=%2Flockspire%2Fconsent%2F"
  end

  test "valid unauthenticated requests redirect to the host login handoff" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.delete("prompt")
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "/sign-in?"
    assert location =~ "source=authorize"
    assert location =~ "interaction_id="
    assert location =~ "return_to=%2Flockspire%2Fconsent%2F"
  end

  test "prompt=none with no subject redirects to the client with login_required and never calls redirect_for_login" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("prompt", "none")
      |> call_authorize()

    assert conn.status in [302, 303]
    refute redirect_location(conn) =~ "/sign-in"

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert params["error"] == "login_required"
    assert params["state"] == "state-123"
  end

  test "authenticated requests without reusable consent redirect to the consent surface" do
    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.AuthorizeControllerAuthenticatedResolver
    )

    conn =
      "client_123"
      |> valid_params()
      |> Map.delete("prompt")
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "/lockspire/consent/"
  end

  test "prompt=none with missing reusable consent redirects to the client with consent_required" do
    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.AuthorizeControllerAuthenticatedResolver
    )

    conn =
      "client_123"
      |> valid_params()
      |> Map.put("prompt", "none")
      |> call_authorize()

    assert conn.status in [302, 303]
    refute redirect_location(conn) =~ "/lockspire/consent/"

    uri =
      conn
      |> redirect_location()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert params["error"] == "consent_required"
    assert params["state"] == "state-123"
  end

  test "authenticated requests with reusable consent redirect back to the client" do
    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.AuthorizeControllerAuthenticatedResolver
    )

    assert {:ok, _grant} =
             Repository.grant_consent(%ConsentGrant{
               account_id: "account-123",
               client_id: "client_123",
               scopes: ["profile", "email"],
               granted_at: DateTime.utc_now(),
               status: :active,
               kind: :remembered
             })

    conn =
      "client_123"
      |> valid_params()
      |> Map.delete("prompt")
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "https://client.example.com/callback"
    assert location =~ "code="
    assert location =~ "state=state-123"
  end

  test "encrypted JARM failures render a first-party browser error instead of downgrading the redirect" do
    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.AuthorizeControllerAuthenticatedResolver
    )

    publish_signing_key("jarm-browser-kid")

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client_jarm_browser_fail_closed",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Encrypted JARM Browser Failure",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        authorization_signed_response_alg: :RS256,
        authorization_encrypted_response_alg: :RSA_OAEP_256,
        authorization_encrypted_response_enc: :A256GCM,
        jwks: %{
          "keys" => [
            %{
              "kty" => "EC",
              "kid" => "wrong-shape",
              "use" => "enc",
              "crv" => "P-256",
              "x" => "f83OJ3D2xF4qQnR1E8V7B6U4Y8W0vQ6V0g3cO7j4Q2M",
              "y" => "x_FEzRu9hR8L6Rxurx8WcN6iYG3PaY5E9OQj1YxDCE8"
            }
          ]
        },
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    assert {:ok, _grant} =
             Repository.grant_consent(%ConsentGrant{
               account_id: "account-123",
               client_id: client.client_id,
               scopes: ["profile", "email"],
               granted_at: DateTime.utc_now(),
               status: :active,
               kind: :remembered
             })

    conn =
      client.client_id
      |> valid_params()
      |> Map.put("prompt", "none")
      |> Map.put("response_mode", "query.jwt")
      |> call_authorize()

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "Authorization request rejected"
    assert conn.resp_body =~ "Unable to continue the authorization flow"
    refute conn.resp_body =~ "code="
  end

  test "par-backed authorize requests reuse the normal browser login handoff", %{client: client} do
    pushed_request = issue_pushed_request(client)

    conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "/sign-in?"
    assert location =~ "source=authorize"
    assert location =~ "interaction_id="
    assert location =~ "return_to=%2Flockspire%2Fconsent%2F"
  end

  test "required-PAR request_uris still reuse the normal browser login handoff", %{client: client} do
    put_server_policy!(:required)
    pushed_request = issue_pushed_request(client)

    conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "/sign-in?"
    assert location =~ "source=authorize"
    assert location =~ "interaction_id="
    assert location =~ "return_to=%2Flockspire%2Fconsent%2F"
  end

  test "expired par request_uris fail safely at the browser surface", %{client: client} do
    pushed_request =
      issue_pushed_request(client, now: DateTime.add(DateTime.utc_now(), -600, :second))

    conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "request_uri is invalid, expired, or already used"
  end

  test "foreign par request_uris fail safely at the browser surface", %{client: client} do
    conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => "https://attacker.example.com/request/123"
      }
      |> call_authorize()

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "request_uri is invalid, expired, or already used"
  end

  test "consumed par request_uris cannot reopen the authorization flow", %{client: client} do
    pushed_request = issue_pushed_request(client)

    first_conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert first_conn.status in [302, 303]

    replay_conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert replay_conn.status == 400
    refute redirected?(replay_conn)
    assert replay_conn.resp_body =~ "request_uri is invalid, expired, or already used"
  end

  test "wrong-client par attempts are rejected and burn the request_uri", %{client: client} do
    pushed_request = issue_pushed_request(client)

    {:ok, other_client} =
      Repository.register_client(%Client{
        client_id: "client_456",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Other Integrations",
        redirect_uris: ["https://other.example.com/callback"],
        allowed_scopes: ["profile", "email"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    wrong_client_conn =
      %{
        "client_id" => other_client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert wrong_client_conn.status == 400
    refute redirected?(wrong_client_conn)
    assert wrong_client_conn.resp_body =~ "request_uri is invalid, expired, or already used"

    burned_conn =
      %{
        "client_id" => client.client_id,
        "request_uri" => pushed_request.request_uri
      }
      |> call_authorize()

    assert burned_conn.status == 400
    refute redirected?(burned_conn)
    assert burned_conn.resp_body =~ "request_uri is invalid, expired, or already used"
  end

  defp call_authorize(params) do
    conn = build_conn(:get, "/authorize", params)
    Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))
  end

  defp redirected?(conn), do: Plug.Conn.get_resp_header(conn, "location") != []

  defp redirect_location(conn), do: List.first(Plug.Conn.get_resp_header(conn, "location"))

  defp valid_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "profile email",
      "state" => "state-123",
      "prompt" => "consent",
      "code_challenge" => String.duplicate("a", 43),
      "code_challenge_method" => "S256"
    }
  end

  defp jar_claims_for_controller(client_id, redirect_uri) do
    now_unix = DateTime.utc_now() |> DateTime.to_unix()

    %{
      "iss" => client_id,
      "aud" => Lockspire.Config.issuer!(),
      "exp" => now_unix + 300,
      "redirect_uri" => redirect_uri,
      "response_type" => "code",
      "scope" => "profile email",
      "prompt" => "consent",
      "state" => "state-123",
      "code_challenge" => String.duplicate("a", 43),
      "code_challenge_method" => "S256"
    }
  end

  defp issue_pushed_request(client, opts \\ []) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)

    pushed_request =
      PushedAuthorizationRequest.issue(
        %{
          client_id: client.client_id,
          redirect_uri: "https://client.example.com/callback",
          scopes: ["profile", "email"],
          prompt: ["consent"],
          state: "state-123",
          code_challenge: String.duplicate("a", 43),
          code_challenge_method: :S256
        },
        now: now
      )

    {:ok, stored_request} = Repository.put_pushed_authorization_request(pushed_request)
    stored_request
  end

  defp put_server_policy!(mode) do
    assert {:ok, %ServerPolicy{} = _policy} =
             Repository.put_server_policy(%ServerPolicy{par_policy: mode})
  end

  defp publish_signing_key(kid) do
    keys = JarTestHelpers.generate_keys()
    public_jwk = JOSE.JWK.to_public_map(keys.private_jwk) |> elem(1)
    private_jwk = JOSE.JWK.to_map(keys.private_jwk) |> elem(1)

    assert {:ok, _stored_key} =
             Repository.publish_key(%Lockspire.Domain.SigningKey{
               kid: kid,
               kty: :RSA,
               alg: "RS256",
               use: :sig,
               public_jwk:
                 public_jwk
                 |> Map.put("kid", kid)
                 |> Map.put("alg", "RS256")
                 |> Map.put("use", "sig"),
               private_jwk_encrypted: Jason.encode!(Map.put(private_jwk, "kid", kid)),
               status: :active,
               published_at: DateTime.utc_now(),
               activated_at: DateTime.utc_now(),
               metadata: %{}
             })
  end

  defp update_client_par_policy!(client, mode) do
    assert {:ok, %Client{} = updated_client} =
             Repository.update_client(client, %{par_policy: mode})

    updated_client
  end
end
