defmodule Lockspire.Web.TokenControllerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  import Ecto.Query
  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.TokenRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, public_client} =
      Repository.register_client(%Client{
        client_id: "client-public",
        client_secret_hash: nil,
        client_type: :public,
        name: "Public App",
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

    now = DateTime.utc_now()

    {:ok, _code} =
      Repository.store_token(%Token{
        token_hash: TokenFormatter.hash_token("public-code"),
        token_type: :authorization_code,
        client_id: public_client.client_id,
        account_id: "subject-public",
        interaction_id: "interaction-public",
        redirect_uri: "https://client.example.com/callback",
        scopes: ["email", "profile"],
        code_challenge: code_challenge("public-verifier"),
        code_challenge_method: :S256,
        issued_at: now,
        expires_at: DateTime.add(now, 300, :second)
      })

    %{public_client: public_client}
  end

  test "POST /token returns an oauth token response for public clients", %{public_client: public_client} do
    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "authorization_code",
        "client_id" => public_client.client_id,
        "code" => "public-code",
        "redirect_uri" => "https://client.example.com/callback",
        "code_verifier" => "public-verifier"
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 200
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "pragma") == ["no-cache"]

    body = Jason.decode!(conn.resp_body)

    assert Map.keys(body) |> Enum.sort() == ["access_token", "expires_in", "scope", "token_type"]
    assert body["token_type"] == "Bearer"
    assert body["scope"] == "email profile"

    persisted_token =
      Lockspire.TestRepo.one!(
        from token in TokenRecord,
          where:
            token.token_type == :access_token and token.client_id == ^public_client.client_id
      )

    assert persisted_token.token_hash == TokenFormatter.hash_token(body["access_token"])
  end

  test "POST /token returns oauth-safe error json for unsupported grant types", %{
    public_client: public_client
  } do
    conn =
      build_conn(:post, "/token", %{
        "grant_type" => "refresh_token",
        "client_id" => public_client.client_id
      })
      |> put_req_header("accept", "application/json")
      |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

    assert conn.status == 400

    body = Jason.decode!(conn.resp_body)

    assert body == %{
             "error" => "unsupported_grant_type",
             "error_description" => "Only grant_type=authorization_code is supported"
           }
  end

  defp code_challenge(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end
end
