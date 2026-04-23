defmodule Lockspire.Web.UserinfoControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
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

    %{access_token: raw_access_token}
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
end
