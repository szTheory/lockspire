defmodule Lockspire.Web.AuthorizeControllerTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  import Phoenix.ConnTest

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :known_scopes, ["profile", "email", "offline_access"])

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, client} =
      Repository.register_client(%Client{
        client_id: "client_123",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Acme Integrations",
        redirect_uris: ["https://client.example.com/callback"],
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

  test "redirect-safe validation failures redirect with oauth error params and preserved state" do
    conn =
      "client_123"
      |> valid_params()
      |> Map.put("prompt", "select_account")
      |> call_authorize()

    assert conn.status in [302, 303]
    assert location = List.first(Plug.Conn.get_resp_header(conn, "location"))
    assert location =~ "https://client.example.com/callback"
    assert location =~ "error=invalid_request"
    assert location =~ "state=state-123"
  end

  test "successful validation returns the typed handoff contract as json" do
    conn = call_authorize(valid_params("client_123"))

    assert conn.status == 200
    assert conn.resp_body =~ "\"status\":\"validated\""
    assert conn.resp_body =~ "\"client_id\":\"client_123\""
    assert conn.resp_body =~ "\"code_challenge_method\":\"S256\""
  end

  defp call_authorize(params) do
    conn = build_conn(:get, "/authorize", params)
    Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))
  end

  defp redirected?(conn) do
    Plug.Conn.get_resp_header(conn, "location") != []
  end

  defp valid_params(client_id) do
    %{
      "client_id" => client_id,
      "response_type" => "code",
      "redirect_uri" => "https://client.example.com/callback",
      "scope" => "profile email",
      "state" => "state-123",
      "prompt" => "login consent",
      "code_challenge" => String.duplicate("a", 43),
      "code_challenge_method" => "S256"
    }
  end
end
