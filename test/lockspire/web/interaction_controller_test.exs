defmodule Lockspire.Web.InteractionControllerAuthResolver do
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

defmodule Lockspire.Web.InteractionControllerMismatchedResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "account-999"}}

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

defmodule Lockspire.Web.InteractionControllerTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.Repository
  import Phoenix.ConnTest

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.InteractionControllerAuthResolver
    )

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.InteractionControllerAuthResolver
    )

    {:ok, _client} =
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

    :ok
  end

  test "show resumes pending login interactions into the consent surface" do
    {:ok, interaction} = Repository.put_interaction(interaction_fixture(status: :pending_login))

    conn = build_conn(:get, "/interactions/#{interaction.interaction_id}")
    conn = Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))

    assert conn.status in [302, 303]
    assert redirect_location(conn) == "/lockspire/consent/#{interaction.interaction_id}"
  end

  test "approval finalization redirects back to the client with code and state" do
    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(status: :pending_consent, account_id: "account-123")
      )

    conn =
      build_conn(:post, "/interactions/#{interaction.interaction_id}/complete", %{
        "decision" => "approve",
        "remember" => "true"
      })

    conn = Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "https://client.example.com/callback"
    assert location =~ "code="
    assert location =~ "state=state-123"
  end

  test "denial finalization redirects back to the client with access_denied and state" do
    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(status: :pending_consent, account_id: "account-123")
      )

    conn =
      build_conn(:post, "/interactions/#{interaction.interaction_id}/complete", %{
        "decision" => "deny"
      })

    conn = Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))

    assert conn.status in [302, 303]
    assert location = redirect_location(conn)
    assert location =~ "https://client.example.com/callback"
    assert location =~ "error=access_denied"
    assert location =~ "state=state-123"
  end

  test "expired interactions render a first-party error" do
    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(
          status: :expired,
          account_id: "account-123",
          expires_at: DateTime.add(DateTime.utc_now(), -60, :second),
          expired_at: DateTime.utc_now()
        )
      )

    conn =
      build_conn(:post, "/interactions/#{interaction.interaction_id}/complete", %{
        "decision" => "approve"
      })

    conn = Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "Authorization request rejected"
    assert conn.resp_body =~ "expired"
  end

  test "mismatched interactions render a first-party error instead of redirecting" do
    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.InteractionControllerMismatchedResolver
    )

    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(status: :pending_consent, account_id: "account-123")
      )

    conn =
      build_conn(:post, "/interactions/#{interaction.interaction_id}/complete", %{
        "decision" => "approve"
      })

    conn = Lockspire.Web.Router.call(conn, Lockspire.Web.Router.init([]))

    assert conn.status == 400
    refute redirected?(conn)
    assert conn.resp_body =~ "Authorization request rejected"
    assert conn.resp_body =~ "does not belong to this account"
  end

  defp interaction_fixture(overrides) do
    now = DateTime.utc_now()

    defaults = %Interaction{
      interaction_id: "interaction-#{System.unique_integer([:positive])}",
      client_id: "client_123",
      account_id: nil,
      scopes_requested: ["profile", "email"],
      prompt: [],
      redirect_uri: "https://client.example.com/callback",
      return_to: "/lockspire/consent/placeholder",
      state: "state-123",
      code_challenge: String.duplicate("a", 43),
      code_challenge_method: :S256,
      status: :pending_login,
      login_required_at: now,
      expires_at: DateTime.add(now, 300, :second)
    }

    struct!(defaults, Enum.into(overrides, %{}))
  end

  defp redirected?(conn), do: Plug.Conn.get_resp_header(conn, "location") != []
  defp redirect_location(conn), do: List.first(Plug.Conn.get_resp_header(conn, "location"))
end
