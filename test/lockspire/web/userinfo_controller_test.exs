defmodule Lockspire.Web.UserinfoControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  defmodule Resolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    @impl true
    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "subject-userinfo"}}

    @impl true
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    @impl true
    def build_claims(account, _context) do
      {:ok,
       %Claims{
         subject: account.id,
         id_token: %{"email" => "#{account.id}@example.test"},
         userinfo: %{
           "email" => "#{account.id}@example.test",
           "email_verified" => true,
           "name" => "Subject #{account.id}",
           "nickname" => nil
         }
       }}
    end

    @impl true
    def redirect_for_login(_conn_or_socket, _context) do
      %InteractionResult{login_path: "/sign-in", return_to: "/authorize", params: %{}}
    end
  end

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :account_resolver, Resolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client-userinfo",
        client_secret_hash: nil,
        client_type: :public,
        name: "Userinfo App",
        redirect_uris: ["https://client.example.com/callback"],
        allowed_scopes: ["email", "profile"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :none,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    raw_access_token = "userinfo-access-token"
    raw_dpop_access_token = "userinfo-dpop-access-token"
    now = DateTime.utc_now()

    {:ok, _token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw_access_token),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-userinfo",
        interaction_id: "interaction-userinfo",
        scopes: ["openid", "email", "profile"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    dpop_proof = dpop_proof_fixture(raw_dpop_access_token, now)

    {:ok, _dpop_token} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token(raw_dpop_access_token),
        token_type: :access_token,
        client_id: client.client_id,
        account_id: "subject-userinfo",
        interaction_id: "interaction-userinfo-dpop",
        scopes: ["openid", "email", "profile"],
        cnf: %{"jkt" => dpop_proof.jkt},
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      })

    %{
      access_token: raw_access_token,
      dpop_access_token: raw_dpop_access_token,
      dpop_proof: dpop_proof.jwt,
      dpop_jkt: dpop_proof.jkt,
      now: now
    }
  end

  test "GET /userinfo returns scope-bounded claims with sub and omits nil claims", %{
    access_token: access_token
  } do
    conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "Bearer " <> access_token)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)

    assert body["sub"] == "subject-userinfo"
    assert body["email"] == "subject-userinfo@example.test"
    assert body["name"] == "Subject subject-userinfo"
    refute Map.has_key?(body, "nickname")
  end

  test "GET /userinfo rejects missing bearer tokens" do
    conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401

    assert get_resp_header(conn, "www-authenticate") == [
             "Bearer realm=\"Lockspire Userinfo\", error=\"invalid_token\""
           ]

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_token",
             "error_description" => "Bearer access token is required"
           }
  end

  test "GET /userinfo accepts a DPoP-bound access token only with Authorization: DPoP and a valid proof",
       %{dpop_access_token: access_token, dpop_proof: proof} do
    conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> access_token)
      |> put_req_header("dpop", proof)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)

    assert body["sub"] == "subject-userinfo"
    assert body["email"] == "subject-userinfo@example.test"
    assert body["name"] == "Subject subject-userinfo"
  end

  test "GET /userinfo rejects a DPoP-bound token presented as bearer with a DPoP-aware challenge",
       %{dpop_access_token: access_token} do
    conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "Bearer " <> access_token)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 401
    [challenge] = get_resp_header(conn, "www-authenticate")
    assert challenge =~ "DPoP realm=\"Lockspire Userinfo\""
    assert challenge =~ "error=\"invalid_token\""
    assert challenge =~ "algs=\""

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_token",
             "error_description" => "DPoP-bound access token requires Authorization: DPoP"
           }
  end

  test "GET /userinfo returns invalid_token with a DPoP-aware challenge for replay wrong ath and wrong proof key",
       %{dpop_access_token: access_token, dpop_proof: proof, now: now} do
    replay_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> access_token)
      |> put_req_header("dpop", proof)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert replay_conn.status == 200

    replay_failure_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> access_token)
      |> put_req_header("dpop", proof)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert replay_failure_conn.status == 401
    assert_dpop_challenge(replay_failure_conn)

    wrong_ath_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> access_token)
      |> put_req_header("dpop", dpop_proof_fixture(access_token, now, %{"ath" => DPoP.access_token_ath("other-token")}).jwt)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert wrong_ath_conn.status == 401
    assert_dpop_challenge(wrong_ath_conn)

    wrong_key_conn =
      build_conn(:get, "/userinfo")
      |> put_req_header("authorization", "DPoP " <> access_token)
      |> put_req_header("dpop", dpop_proof_fixture(access_token, now, %{}, :other).jwt)
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert wrong_key_conn.status == 401
    assert_dpop_challenge(wrong_key_conn)
  end

  defp assert_dpop_challenge(conn) do
    [challenge] = get_resp_header(conn, "www-authenticate")
    assert challenge =~ "DPoP realm=\"Lockspire Userinfo\""
    assert challenge =~ "error=\"invalid_token\""
    assert challenge =~ "algs=\""
  end

  defp dpop_proof_fixture(access_token, now, claim_overrides \\ %{}, key_seed \\ :default) do
    keys =
      case key_seed do
        :other -> JarTestHelpers.generate_ec_keys()
        _default -> JarTestHelpers.generate_ec_keys()
      end

    claims =
      %{
        "htm" => "GET",
        "htu" => "https://example.test/lockspire/userinfo",
        "iat" => DateTime.to_unix(now),
        "jti" => Ecto.UUID.generate(),
        "ath" => DPoP.access_token_ath(access_token)
      }
      |> Map.merge(claim_overrides)

    jwt = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

    assert {:ok, validated} =
             DPoP.validate_proof(jwt,
               method: "GET",
               target_uri: "https://example.test/lockspire/userinfo",
               now: now,
               max_age: 300,
               clock_skew: 30
             )

    %{jwt: jwt, jkt: validated.jkt}
  end
end
