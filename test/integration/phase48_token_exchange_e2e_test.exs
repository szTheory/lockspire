defmodule Lockspire.Integration.Phase48TokenExchangeE2ETest do
  use ExUnit.Case, async: false

  @moduletag :integration
  @endpoint Lockspire.Web.Endpoint

  import Phoenix.ConnTest
  import Plug.Conn

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, Lockspire.Web.Endpoint,
      secret_key_base: String.duplicate("a", 64),
      server: false
    )

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    start_supervised!(Lockspire.Web.Endpoint)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "phase48-client",
        name: "Token Exchange Client",
        client_type: :public,
        token_endpoint_auth_method: :none,
        allowed_grant_types: ["urn:ietf:params:oauth:grant-type:token-exchange"],
        created_at: DateTime.utc_now()
      })

    %{client: client}
  end

  describe "TE-05: Mint new tokens as requested" do
    test "exchanged tokens are persisted and share lineage", %{client: client} do
      now = DateTime.utc_now()

      formatted_access_token = TokenFormatter.format_access_token([])

      access_token = %Token{
        token_hash: Lockspire.Security.Policy.hash_token(formatted_access_token.token),
        token_type: :access_token,
        family_id: "family_123",
        generation: 1,
        client_id: client.client_id,
        account_id: "user_456",
        sid: "session_789",
        scopes: ["read", "write"],
        expires_at: DateTime.add(now, 3600, :second)
      }

      {:ok, subject_token_record} = Repository.store_token(access_token)

      conn =
        build_conn()
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> post("/token", %{
          "grant_type" => "urn:ietf:params:oauth:grant-type:token-exchange",
          "subject_token" => formatted_access_token.token,
          "client_id" => client.client_id,
          "scope" => "read"
        })

      assert conn.status == 200

      body = Jason.decode!(conn.resp_body)

      assert body["access_token"]
      assert body["token_type"] == "Bearer"
      assert body["issued_token_type"] == "urn:ietf:params:oauth:token-type:access_token"
      assert body["scope"] == "read"

      new_token_hash = Lockspire.Security.Policy.hash_token(body["access_token"])

      {:ok, %Token{} = new_token} = Repository.fetch_lifecycle_token(new_token_hash)

      assert new_token.family_id == "family_123"
      assert new_token.parent_token_id == subject_token_record.id
      assert new_token.generation == 2
      assert new_token.account_id == "user_456"
      assert new_token.sid == "session_789"
      assert new_token.scopes == ["read"]
    end
  end
end
