defmodule Lockspire.Web.ConsentLiveAuthResolver do
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

defmodule Lockspire.Web.ConsentLiveMismatchedResolver do
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

defmodule Lockspire.Web.ConsentLiveTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Interaction
  alias Lockspire.Web.ConsentLive
  alias Lockspire.Storage.Ecto.Repository
  import Phoenix.LiveViewTest

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :account_resolver, Lockspire.Web.ConsentLiveAuthResolver)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Lockspire.Web.ConsentLiveAuthResolver)

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

  test "renders client and requested scope context for consent review" do
    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(
          status: :pending_consent,
          account_id: "account-123",
          authorization_details: authorization_details_fixture()
        )
      )

    assert {:ok, socket} =
             ConsentLive.mount(
               %{"interaction_id" => interaction.interaction_id},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    html = rendered_to_string(ConsentLive.render(socket.assigns))

    assert html =~ "Acme Integrations"
    assert html =~ "profile"
    assert html =~ "email"
    assert html =~ "authorization_details"
    assert html =~ "payment_initiation"
    assert html =~ "account_access"
    assert html =~ "/lockspire/interactions/#{interaction.interaction_id}/complete"
    assert html =~ "Approve access"
    assert html =~ "Deny access"

    assert socket.assigns.authorization_details == authorization_details_fixture()
    assert socket.assigns.authorization_detail_types == ["payment_initiation", "account_access"]
  end

  test "pending login interactions resume into consent review for authenticated accounts" do
    {:ok, interaction} = Repository.put_interaction(interaction_fixture(status: :pending_login))

    assert {:ok, socket} =
             ConsentLive.mount(
               %{"interaction_id" => interaction.interaction_id},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    html = rendered_to_string(ConsentLive.render(socket.assigns))

    assert html =~ "Authorize Access"
    assert html =~ "Acme Integrations"
  end

  test "expired interactions render a first-party error surface" do
    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(
          status: :expired,
          account_id: "account-123",
          expires_at: DateTime.add(DateTime.utc_now(), -60, :second),
          expired_at: DateTime.utc_now()
        )
      )

    assert {:ok, socket} =
             ConsentLive.mount(
               %{"interaction_id" => interaction.interaction_id},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    html = rendered_to_string(ConsentLive.render(socket.assigns))

    assert html =~ "Authorization request rejected"
    assert html =~ "expired"
  end

  test "mismatched interactions render a first-party error surface" do
    Application.put_env(
      :lockspire,
      :account_resolver,
      Lockspire.Web.ConsentLiveMismatchedResolver
    )

    {:ok, interaction} =
      Repository.put_interaction(
        interaction_fixture(status: :pending_consent, account_id: "account-123")
      )

    assert {:ok, socket} =
             ConsentLive.mount(
               %{"interaction_id" => interaction.interaction_id},
               %{},
               %Phoenix.LiveView.Socket{}
             )

    html = rendered_to_string(ConsentLive.render(socket.assigns))

    assert html =~ "Authorization request rejected"
    assert html =~ "does not belong to this account"
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

  defp authorization_details_fixture do
    [
      %{
        "type" => "payment_initiation",
        "locations" => ["https://resource.example.com/payments"],
        "actions" => ["create"],
        "instructedAmount" => %{"currency" => "USD", "amount" => "12.34"}
      },
      %{
        "type" => "account_access",
        "locations" => ["https://resource.example.com/accounts"],
        "actions" => ["read"],
        "datatypes" => ["balances", "transactions"]
      }
    ]
  end
end
