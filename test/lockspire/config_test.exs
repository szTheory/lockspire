defmodule Lockspire.TestAccountResolver do
  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(_conn_or_socket, _context) do
    {:ok, %{id: "account-123"}}
  end

  @impl true
  def resolve_account(account_reference, _context) do
    {:ok, %{id: account_reference}}
  end

  @impl true
  def build_claims(account, _context) do
    {:ok,
     %Claims{
       subject: account.id,
       id_token: %{"sub" => account.id},
       userinfo: %{"sub" => account.id}
     }}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/sign-in",
      return_to: Map.get(context, :return_to),
      params: %{"interaction_id" => "interaction-123"}
    }
  end
end

defmodule Lockspire.ConfigTest do
  use ExUnit.Case, async: false

  setup do
    original_env =
      for key <- [:repo, :account_resolver, :issuer, :mount_path, :oban], into: %{} do
        {key, Application.get_env(:lockspire, key)}
      end

    on_exit(fn ->
      Enum.each(original_env, fn {key, value} ->
        if is_nil(value) do
          Application.delete_env(:lockspire, key)
        else
          Application.put_env(:lockspire, key, value)
        end
      end)
    end)

    :ok
  end

  test "reads configured runtime values through the public api" do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Lockspire.TestAccountResolver)
    Application.put_env(:lockspire, :issuer, "https://example.test")
    Application.put_env(:lockspire, :mount_path, "/oauth")
    Application.put_env(:lockspire, :oban, repo: Lockspire.TestRepo, queues: false)

    assert Lockspire.Config.repo!() == Lockspire.TestRepo
    assert Lockspire.Config.account_resolver!() == Lockspire.TestAccountResolver
    assert Lockspire.Config.issuer!() == "https://example.test"
    assert Lockspire.Config.mount_path() == "/oauth"
    assert Lockspire.Config.oban_config() == [repo: Lockspire.TestRepo, queues: false]

    assert Lockspire.config() == %{
             repo: Lockspire.TestRepo,
             account_resolver: Lockspire.TestAccountResolver,
             issuer: "https://example.test",
             mount_path: "/oauth",
             oban: [repo: Lockspire.TestRepo, queues: false]
           }

    assert Lockspire.issuer() == "https://example.test"
    assert Lockspire.mount_path() == "/oauth"
    assert Lockspire.account_resolver!() == Lockspire.TestAccountResolver
  end

  test "repo!/0 raises a clear error when repo config is missing" do
    Application.delete_env(:lockspire, :repo)

    assert_raise ArgumentError, ~r/missing required config :repo for :lockspire/, fn ->
      Lockspire.Config.repo!()
    end
  end

  test "account_resolver!/0 raises a clear error when account_resolver config is missing" do
    Application.delete_env(:lockspire, :account_resolver)

    assert_raise ArgumentError,
                 ~r/missing required config :account_resolver for :lockspire/,
                 fn ->
                   Lockspire.Config.account_resolver!()
                 end
  end

  test "test resolver satisfies the host seam behaviour without macros" do
    assert {:ok, %{id: "account-123"}} =
             Lockspire.TestAccountResolver.resolve_current_account(%{}, %{return_to: "/authorize"})

    assert {:ok, %{id: "account-456"}} =
             Lockspire.TestAccountResolver.resolve_account("account-456", %{})

    assert {:ok, %Lockspire.Host.Claims{subject: "account-456"}} =
             Lockspire.TestAccountResolver.build_claims(%{id: "account-456"}, %{})

    assert %Lockspire.Host.InteractionResult{
             login_path: "/sign-in",
             return_to: "/authorize"
           } =
             Lockspire.TestAccountResolver.redirect_for_login(%{}, %{return_to: "/authorize"})
  end
end
