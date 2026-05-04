defmodule Lockspire.Integration.Phase37ProtocolStrictnessE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint GeneratedHostAppWeb.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn, only: [get_resp_header: 2, put_req_header: 3]

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.SigningKeyRecord

  defmodule GeneratedHostAuthTimeResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(%Plug.Conn{} = conn, context) do
      case GeneratedHostApp.Lockspire.TestAccountResolver.resolve_current_account(conn, context) do
        {:ok, account} ->
          {:ok, maybe_put_auth_time(account, conn)}

        other ->
          other
      end
    end

    def resolve_current_account(conn_or_socket, context),
      do:
        GeneratedHostApp.Lockspire.TestAccountResolver.resolve_current_account(
          conn_or_socket,
          context
        )

    @impl true
    def resolve_account(account_reference, context),
      do:
        GeneratedHostApp.Lockspire.TestAccountResolver.resolve_account(account_reference, context)

    @impl true
    def build_claims(account, context),
      do: GeneratedHostApp.Lockspire.TestAccountResolver.build_claims(account, context)

    @impl true
    def redirect_for_login(conn_or_socket, context),
      do:
        GeneratedHostApp.Lockspire.TestAccountResolver.redirect_for_login(conn_or_socket, context)

    defp maybe_put_auth_time(account, conn) do
      case Plug.Conn.get_session(conn, "current_auth_time_unix") do
        unix when is_integer(unix) ->
          Map.put(account, :auth_time, DateTime.from_unix!(unix))

        _other ->
          account
      end
    end
  end

  setup_all do
    Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostAuthTimeResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(GeneratedHostAppWeb.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Lockspire.TestRepo.delete_all(SigningKeyRecord)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase37-strictness-client",
        client_secret_hash: nil,
        client_type: :public,
        name: "Phase 37 Strictness Client",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["openid", "email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client}
  end

  test "exact redirect_uri mismatches stay on the browser-safe surface", %{client: client} do
    conn =
      build_conn()
      |> get("/lockspire/authorize", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback/",
        "scope" => "openid email profile",
        "state" => "phase37-browser-error",
        "nonce" => "phase37-browser-error-nonce",
        "code_challenge" => code_challenge("phase37-browser-error-verifier"),
        "code_challenge_method" => "S256"
      })

    assert conn.status == 400
    assert conn.resp_body =~ "Authorization request rejected"
    assert conn.resp_body =~ "redirect_uri must match a registered URI"
    assert get_resp_header(conn, "location") == []
  end

  test "prompt=none with no visible host session returns login_required without host login redirection",
       %{client: client} do
    conn =
      build_conn()
      |> get(
        "/lockspire/authorize",
        Map.put(base_authorize_params(client.client_id), "prompt", "none")
      )

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirected_to()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert "#{uri.scheme}://#{uri.host}#{uri.path}" == "https://client.example.com/callback"
    assert params["error"] == "login_required"
    assert params["state"] == "phase37-state"
    refute redirected_to(conn) =~ "/login"
  end

  test "prompt=none plus stale auth_time under max_age returns login_required", %{client: client} do
    stale_auth_time = DateTime.utc_now() |> DateTime.add(-600, :second) |> DateTime.to_unix()

    conn =
      build_conn()
      |> init_test_session(%{
        "current_account_id" => "generated-host-user",
        "current_auth_time_unix" => stale_auth_time
      })
      |> get(
        "/lockspire/authorize",
        base_authorize_params(client.client_id)
        |> Map.put("prompt", "none")
        |> Map.put("max_age", "60")
      )

    assert conn.status in [302, 303]

    uri =
      conn
      |> redirected_to()
      |> URI.parse()

    params = URI.decode_query(uri.query || "")

    assert "#{uri.scheme}://#{uri.host}#{uri.path}" == "https://client.example.com/callback"
    assert params["error"] == "login_required"
    assert params["state"] == "phase37-state"
  end

  test "fresh auth emits integer auth_time in the ID token when max_age or explicit auth_time demand is present",
       %{client: client} do
    signing_key = publish_signing_key("phase37-strictness-kid")
    fresh_auth_time = DateTime.utc_now() |> DateTime.add(-30, :second) |> DateTime.to_unix()

    signed_in_conn =
      build_conn()
      |> init_test_session(%{
        "current_account_id" => "generated-host-user",
        "current_auth_time_unix" => fresh_auth_time
      })

    cases = [
      {"max_age", %{"max_age" => "60"}},
      {"claims",
       %{"claims" => Jason.encode!(%{"id_token" => %{"auth_time" => %{"essential" => true}}})}}
    ]

    Enum.each(cases, fn {label, extra_params} ->
      token_response =
        run_authorization_code_flow(
          signed_in_conn,
          client,
          "phase37-#{label}",
          Map.merge(base_authorize_params(client.client_id), extra_params)
        )

      assert {true, %JOSE.JWT{fields: id_token_claims}, _jws} =
               JOSE.JWT.verify_strict(signing_key, ["RS256"], token_response["id_token"])

      assert id_token_claims["sub"] == "generated-host-user"
      assert id_token_claims["nonce"] == "phase37-#{label}-nonce"
      assert is_integer(id_token_claims["auth_time"])
      assert id_token_claims["auth_time"] == fresh_auth_time
    end)
  end

  test "supported surface docs name only the repo-proven phase 37 strictness slice" do
    supported_surface = File.read!(Path.expand("../../docs/supported-surface.md", __DIR__))

    assert supported_surface =~ "prompt=none"
    assert supported_surface =~ "max_age"
    assert supported_surface =~ "auth_time"
    assert supported_surface =~ "test/integration/phase37_protocol_strictness_e2e_test.exs"
    assert supported_surface =~ "broad certification or conformance coverage"
  end

  defp run_authorization_code_flow(conn, client, flow_key, params) do
    code_verifier = "#{flow_key}-verifier"

    authorize_conn =
      conn
      |> get(
        "/lockspire/authorize",
        params
        |> Map.put("nonce", "#{flow_key}-nonce")
        |> Map.put("state", "#{flow_key}-state")
        |> Map.put("prompt", "consent")
        |> Map.put("code_challenge", code_challenge(code_verifier))
      )

    assert authorize_conn.status in [302, 303]

    consent_uri =
      authorize_conn
      |> redirected_to()
      |> URI.parse()

    assert consent_uri.path =~ "/lockspire/consent/"

    interaction_id =
      consent_uri.path
      |> String.split("/")
      |> List.last()

    consent_complete_conn =
      authorize_conn
      |> recycle()
      |> post("/lockspire/interactions/#{interaction_id}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })

    assert consent_complete_conn.status in [302, 303]

    callback_uri =
      consent_complete_conn
      |> redirected_to()
      |> URI.parse()

    callback_params = URI.decode_query(callback_uri.query || "")

    assert callback_uri.host == "client.example.com"
    assert callback_params["state"] == "#{flow_key}-state"
    assert code = callback_params["code"]

    token_conn =
      build_conn()
      |> put_req_header("accept", "application/json")
      |> post("/lockspire/token", %{
        "grant_type" => "authorization_code",
        "client_id" => client.client_id,
        "code" => code,
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => code_verifier
      })

    assert token_conn.status == 200
    Jason.decode!(token_conn.resp_body)
  end

  defp base_authorize_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "openid email profile",
      "state" => "phase37-state",
      "nonce" => "phase37-nonce",
      "code_challenge" => code_challenge("phase37-verifier"),
      "code_challenge_method" => "S256"
    }
  end

  defp publish_signing_key(kid) do
    key = JOSE.JWK.generate_key({:rsa, 2048})
    {_fields, jwk} = JOSE.JWK.to_map(key)

    {:ok, _published_key} =
      Repository.publish_key(%SigningKey{
        kid: kid,
        kty: :RSA,
        alg: "RS256",
        use: :sig,
        public_jwk:
          jwk
          |> Map.take(["kty", "kid", "alg", "use", "n", "e"])
          |> Map.put("kid", kid)
          |> Map.put("alg", "RS256")
          |> Map.put("use", "sig"),
        private_jwk_encrypted: Jason.encode!(Map.put(jwk, "kid", kid)),
        status: :active,
        published_at: DateTime.utc_now(),
        activated_at: DateTime.utc_now(),
        metadata: %{}
      })

    key
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end
end
