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
end
