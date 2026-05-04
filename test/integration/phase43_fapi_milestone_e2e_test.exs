defmodule Lockspire.Integration.Phase43FapiMilestoneE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult
  alias Lockspire.Protocol.Discovery
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.Repository

  @issuer "https://example.test/lockspire"
  @authorize_redirect_mismatch_literal "redirect_uri must match a registered URI"
  @token_redirect_mismatch_literal "redirect_uri does not match the issued authorization code"
  @end_session_unregistered_literal "post_logout_redirect_uri not registered"

  defmodule GeneratedHostResolver do
    @behaviour Lockspire.Host.AccountResolver

    @impl true
    def resolve_current_account(_conn_or_socket, _context),
      do: {:ok, %{id: "phase41-fapi-user"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: to_string(account.id),
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{
           "email" => "#{account.id}@example.test",
           "email_verified" => true,
           "name" => "Phase 41 FAPI User"
         }
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, context) do
      %InteractionResult{
        login_path: "/login",
        return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
        params: %{
          "interaction_id" =>
            Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
        }
      }
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, @issuer)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :known_scopes, ["openid", "email", "profile"])
    Application.put_env(:lockspire, :account_resolver, GeneratedHostResolver)

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    secret = "phase43-client-secret"

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase43-fapi-client",
        client_secret_hash: Policy.hash_client_secret(secret),
        client_type: :confidential,
        name: "Phase 43 FAPI Client",
        redirect_uris: ["https://client.example.com/callback"],
        post_logout_redirect_uris: ["https://client.example.com/post-logout"],
        allowed_scopes: ["email", "profile", "openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    %{client: client, secret: secret}
  end

  describe "FAPI-05: zero-tolerance exact-match redirect URIs (D-01, D-03, D-11a)" do
    test "/authorize rejects trailing-slash redirect_uri (browser-error, exact literal)", %{
      client: client
    } do
      put_security_profile!(:none)

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "redirect_uri" => "https://client.example.com/callback/",
          "scope" => "openid",
          "code_challenge" => code_challenge("v1"),
          "code_challenge_method" => "S256"
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 400
      assert conn.resp_body =~ @authorize_redirect_mismatch_literal
    end

    test "/authorize rejects redirect_uri with extra query param (browser-error, exact literal)",
         %{client: client} do
      put_security_profile!(:none)

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "redirect_uri" => "https://client.example.com/callback?extra=1",
          "scope" => "openid",
          "code_challenge" => code_challenge("v2"),
          "code_challenge_method" => "S256"
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 400
      assert conn.resp_body =~ @authorize_redirect_mismatch_literal
    end

    test "/par rejects trailing-slash redirect_uri (JSON error, pinned OAuth code + literal description)",
         %{client: client, secret: secret} do
      put_security_profile!(:none)

      conn =
        build_conn(:post, "/par", %{
          "client_id" => client.client_id,
          "response_type" => "code",
          "redirect_uri" => "https://client.example.com/callback/",
          "scope" => "openid",
          "code_challenge" => code_challenge("v3"),
          "code_challenge_method" => "S256"
        })
        |> put_req_header("authorization", basic_auth(client.client_id, secret))
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_request"
      assert body["error_description"] =~ @authorize_redirect_mismatch_literal
    end

    test "/token rejects trailing-slash redirect_uri during code exchange (pinned literal)", %{
      client: client,
      secret: secret
    } do
      put_security_profile!(:none)
      code_verifier = "phase43-token-verifier"
      raw_code = "phase43-token-code"

      {:ok, _code} =
        create_completed_authorization_code(client, raw_code, code_verifier,
          account_id: "phase43-fapi-user",
          scopes: ["openid"]
        )

      conn =
        build_conn(:post, "/token", %{
          "grant_type" => "authorization_code",
          "code" => raw_code,
          "redirect_uri" => "https://client.example.com/callback/",
          "code_verifier" => code_verifier
        })
        |> put_req_header("authorization", basic_auth(client.client_id, secret))
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_grant"
      assert body["error_description"] =~ @token_redirect_mismatch_literal
    end

    test "/end_session rejects trailing-slash post_logout_redirect_uri (after String.trim, pinned literal)",
         %{client: client} do
      put_security_profile!(:none)

      conn =
        build_conn(:get, "/end_session", %{
          "client_id" => client.client_id,
          "post_logout_redirect_uri" => "https://client.example.com/post-logout/"
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      evidence = conn |> get_resp_header("location") |> List.first() || conn.resp_body || ""
      assert evidence =~ @end_session_unregistered_literal
    end

    test "/end_session rejects post_logout_redirect_uri with extra query param (pinned literal)",
         %{client: client} do
      put_security_profile!(:none)

      conn =
        build_conn(:get, "/end_session", %{
          "client_id" => client.client_id,
          "post_logout_redirect_uri" => "https://client.example.com/post-logout?leak=1"
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      evidence = conn |> get_resp_header("location") |> List.first() || conn.resp_body || ""
      assert evidence =~ @end_session_unregistered_literal
    end

    test "/end_session POSITIVE: surrounding whitespace IS tolerated for post_logout_redirect_uri (D-03)",
         %{client: client} do
      put_security_profile!(:none)

      conn =
        build_conn(:get, "/end_session", %{
          "client_id" => client.client_id,
          "post_logout_redirect_uri" => "  https://client.example.com/post-logout  "
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      evidence = conn |> get_resp_header("location") |> List.first() || conn.resp_body || ""
      refute evidence =~ @end_session_unregistered_literal
    end
  end

  describe "FAPI-06: iss on every authorization-response redirect (D-04, D-05, D-11b)" do
    test "successful authorization redirects append iss", %{client: client, secret: secret} do
      success_location = drive_par_authorize_callback!(client, secret, "approve")
      query = success_location |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      assert query["iss"] == @issuer
      assert query["state"] == "phase43-state"
      assert is_binary(query["code"])
    end

    test "denial authorization redirects append iss", %{client: client, secret: secret} do
      deny_location = drive_par_authorize_callback!(client, secret, "deny")
      query = deny_location |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()
      assert query["error"] == "access_denied"
      assert query["iss"] == @issuer
      assert query["state"] == "phase43-state"
    end

    test "validation/protocol error redirects append iss", %{client: client} do
      put_security_profile!(:none)

      conn =
        build_conn(:get, "/authorize", %{
          "client_id" => client.client_id,
          "response_type" => "id_token",
          "redirect_uri" => "https://client.example.com/callback",
          "scope" => "openid",
          "state" => "phase43-error-state",
          "code_challenge" => code_challenge("phase43-error-verifier"),
          "code_challenge_method" => "S256"
        })
        |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

      assert conn.status in [302, 303]

      query =
        conn
        |> get_resp_header("location")
        |> List.first()
        |> URI.parse()
        |> Map.fetch!(:query)
        |> URI.decode_query()

      assert query["error"] == "unsupported_response_type"
      assert query["iss"] == @issuer
      assert query["state"] == "phase43-error-state"
    end
  end

  describe "FAPI-06: discovery published correctly under both modes (D-07, D-08, D-11c)" do
    test "discovery under :none publishes iss support and omits PAR-required key" do
      put_security_profile!(:none)
      metadata = Discovery.openid_configuration()

      assert metadata["authorization_response_iss_parameter_supported"] == true
      refute Map.has_key?(metadata, "require_pushed_authorization_requests")
    end

    test "discovery under :fapi_2_0_security publishes iss support and PAR-required key" do
      put_security_profile!(:fapi_2_0_security)
      metadata = Discovery.openid_configuration()

      assert metadata["authorization_response_iss_parameter_supported"] == true
      assert metadata["require_pushed_authorization_requests"] == true
    end

    test "per-client :fapi_2_0_security override does not add PAR-required to discovery", %{
      client: client
    } do
      put_security_profile!(:none)

      assert {:ok, _client} =
               Repository.update_client(client, %{security_profile: :fapi_2_0_security})

      metadata = Discovery.openid_configuration()
      refute Map.has_key?(metadata, "require_pushed_authorization_requests")
    end

    test "discovery does not publish mTLS, JARM, or signed_metadata keys" do
      put_security_profile!(:fapi_2_0_security)
      metadata = Discovery.openid_configuration()

      refute Map.has_key?(metadata, "tls_client_certificate_bound_access_tokens")
      refute Map.has_key?(metadata, "authorization_signing_alg_values_supported")
      refute Map.has_key?(metadata, "signed_metadata")
    end
  end

  defp put_security_profile!(profile) do
    {:ok, policy} = Repository.get_server_policy()
    Repository.put_server_policy(%{policy | security_profile: profile})
  end

  defp basic_auth(id, secret) do
    "Basic " <> Base.encode64("#{id}:#{secret}")
  end

  defp code_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end

  defp create_completed_authorization_code(client, raw_code, verifier, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    interaction_id = "interaction-#{raw_code}"

    assert {:ok, _interaction} =
             Repository.put_interaction(%Interaction{
               interaction_id: interaction_id,
               client_id: client.client_id,
               account_id: Keyword.get(opts, :account_id, "phase41-fapi-user"),
               scopes_requested: Keyword.get(opts, :scopes, ["openid"]),
               nonce: Keyword.get(opts, :nonce),
               auth_time: Keyword.get(opts, :auth_time),
               max_age: Keyword.get(opts, :max_age),
               auth_time_requested: Keyword.get(opts, :auth_time_requested, false),
               redirect_uri: "https://client.example.com/callback",
               return_to: "/authorize",
               state: "phase41-state",
               code_challenge: code_challenge(verifier),
               code_challenge_method: :S256,
               status: :completed,
               completed_at: now,
               expires_at: DateTime.add(now, 300, :second)
             })

    Repository.store_token(%Token{
      token_hash: TokenFormatter.hash_token(raw_code),
      token_type: :authorization_code,
      client_id: client.client_id,
      account_id: Keyword.get(opts, :account_id, "phase41-fapi-user"),
      interaction_id: interaction_id,
      redirect_uri: "https://client.example.com/callback",
      scopes: Keyword.get(opts, :scopes, ["openid"]),
      code_challenge: code_challenge(verifier),
      code_challenge_method: :S256,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second)
    })
  end

  defp drive_par_authorize_callback!(client, secret, decision) do
    put_security_profile!(:none)

    par_conn =
      build_conn(:post, "/par", %{
        "client_id" => client.client_id,
        "response_type" => "code",
        "redirect_uri" => "https://client.example.com/callback",
        "scope" => "openid",
        "nonce" => "phase43-nonce",
        "state" => "phase43-state",
        "code_challenge" => code_challenge("phase43-success-verifier"),
        "code_challenge_method" => "S256"
      })
      |> put_req_header("authorization", basic_auth(client.client_id, secret))
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert par_conn.status == 201
    request_uri = Jason.decode!(par_conn.resp_body)["request_uri"]

    authorize_conn =
      build_conn(:get, "/authorize", %{
        "client_id" => client.client_id,
        "request_uri" => request_uri
      })
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert authorize_conn.status in [302, 303]

    interaction_id =
      authorize_conn
      |> get_resp_header("location")
      |> List.first()
      |> URI.parse()
      |> Map.fetch!(:path)
      |> Path.basename()

    complete_conn =
      build_conn(:post, "/interactions/#{interaction_id}/complete", %{"decision" => decision})
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert complete_conn.status in [302, 303]
    complete_conn |> get_resp_header("location") |> List.first()
  end
end
