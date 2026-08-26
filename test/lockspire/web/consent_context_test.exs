defmodule Lockspire.Web.ConsentContextTestResolver do
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
  def redirect_for_login(_conn_or_socket, _context), do: %InteractionResult{login_path: "/login"}
end

defmodule Lockspire.Web.ConsentContextMismatchResolver do
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
  def redirect_for_login(_conn_or_socket, _context), do: %InteractionResult{login_path: "/login"}
end

defmodule Lockspire.Web.ConsentContextTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.ConsentContext

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Lockspire.Web.ConsentContextTestResolver)

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "context-client",
        client_secret_hash: "sha256:salt:hash",
        client_type: :confidential,
        name: "Context Client",
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

  test "returns only render-ready facts for a subject-bound interaction" do
    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(
          status: :pending_consent,
          account_id: "account-123",
          authorization_details: [%{"type" => "payment_initiation", "secret" => "never-render"}]
        )
      )

    assert {:ok, context} = ConsentContext.load(%{}, interaction.interaction_id)
    assert context.client_name == "Context Client"
    assert context.requested_scopes == ["profile", "email"]
    assert context.authorization_detail_types == ["payment_initiation"]
    assert context.finalize_path == "/lockspire/interactions/#{interaction.interaction_id}/complete"
    refute Map.has_key?(context, :interaction)
    refute Map.has_key?(context, :subject_id)
    refute inspect(context) =~ "never-render"
  end

  test "treats missing and expired interactions as safe terminal errors" do
    assert {:error, :not_found} = ConsentContext.load(%{}, "not-a-real-interaction")

    {:ok, expired} =
      Repository.put_interaction(
        interaction_fixture(
          status: :expired,
          account_id: "account-123",
          expires_at: DateTime.add(DateTime.utc_now(), -60, :second),
          expired_at: DateTime.utc_now()
        )
      )

    assert {:error, :expired} = ConsentContext.load(%{}, expired.interaction_id)
  end

  test "does not return decision context for another subject" do
    Application.put_env(:lockspire, :account_resolver, Lockspire.Web.ConsentContextMismatchResolver)

    {:ok, interaction} =
      Repository.put_interaction(interaction_fixture(status: :pending_consent, account_id: "account-123"))

    assert {:error, :subject_mismatch} = ConsentContext.load(%{}, interaction.interaction_id)
  end

  defp interaction_fixture(overrides) do
    now = DateTime.utc_now()

    defaults = %Interaction{
      interaction_id: "context-#{System.unique_integer([:positive])}",
      client_id: "context-client",
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
end
