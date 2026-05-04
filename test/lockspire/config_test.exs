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

  @impl true
  def redirect_for_logout(_conn_or_socket, context) do
    %InteractionResult{
      login_path: "/sign-out",
      return_to: Map.get(context, :return_to),
      params: %{"account_id" => Map.get(context, :account_id)}
    }
  end
end

defmodule Lockspire.ConfigTest do
  use ExUnit.Case, async: false

  setup do
    original_env =
      for key <- [
            :repo,
            :account_resolver,
            :issuer,
            :mount_path,
            :logout_path,
            :oban,
            :signing_alg
          ],
          into: %{} do
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
    Application.put_env(:lockspire, :issuer, "https://example.test/oauth")
    Application.put_env(:lockspire, :mount_path, "/oauth")
    Application.put_env(:lockspire, :logout_path, "/sign-out")
    Application.put_env(:lockspire, :oban, repo: Lockspire.TestRepo, queues: false)

    assert Lockspire.Config.repo!() == Lockspire.TestRepo
    assert Lockspire.Config.account_resolver!() == Lockspire.TestAccountResolver
    assert Lockspire.Config.issuer!() == "https://example.test/oauth"
    assert Lockspire.Config.mount_path() == "/oauth"
    assert Lockspire.Config.logout_path() == "/sign-out"
    assert Lockspire.Config.oban_config() == [repo: Lockspire.TestRepo, queues: false]

    assert Lockspire.config() == %{
             repo: Lockspire.TestRepo,
             account_resolver: Lockspire.TestAccountResolver,
             issuer: "https://example.test/oauth",
             mount_path: "/oauth",
             logout_path: "/sign-out",
             oban: [repo: Lockspire.TestRepo, queues: false]
           }

    assert Lockspire.issuer() == "https://example.test/oauth"
    assert Lockspire.mount_path() == "/oauth"
    assert Lockspire.logout_path() == "/sign-out"
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

  test "logout_path/0 raises a clear error when logout_path config is missing" do
    Application.delete_env(:lockspire, :logout_path)

    assert_raise ArgumentError, ~r/missing required config :logout_path for :lockspire/, fn ->
      Lockspire.Config.logout_path()
    end
  end

  test "issuer!/0 validates absolute issuer urls that match mount_path" do
    Application.put_env(:lockspire, :mount_path, "/oauth")

    invalid_issuers = [
      "oauth",
      "https://example.test/oauth?foo=bar",
      "https://example.test/oauth#fragment",
      "https://example.test/other"
    ]

    for issuer <- invalid_issuers do
      Application.put_env(:lockspire, :issuer, issuer)

      assert_raise ArgumentError, fn ->
        Lockspire.Config.issuer!()
      end
    end

    Application.put_env(:lockspire, :issuer, "https://example.test/oauth")

    assert Lockspire.Config.issuer!() == "https://example.test/oauth"
  end

  test "issuer!/0 rejects unsupported signing posture when configured" do
    Application.put_env(:lockspire, :issuer, "https://example.test/oauth")
    Application.put_env(:lockspire, :mount_path, "/oauth")
    Application.put_env(:lockspire, :signing_alg, "none")

    assert_raise ArgumentError,
                 "invalid :signing_alg for :lockspire. Expected RS256 and never alg=none.",
                 fn ->
                   Lockspire.Config.issuer!()
                 end
  after
    Application.delete_env(:lockspire, :signing_alg)
  end

  test "jar_max_age_seconds/0 returns 600 by default and honors configured override" do
    original = Application.get_env(:lockspire, :jar_max_age_seconds)

    on_exit(fn ->
      if is_nil(original) do
        Application.delete_env(:lockspire, :jar_max_age_seconds)
      else
        Application.put_env(:lockspire, :jar_max_age_seconds, original)
      end
    end)

    # Default (no app env)
    Application.delete_env(:lockspire, :jar_max_age_seconds)
    assert Lockspire.Config.jar_max_age_seconds() == 600

    # Override
    Application.put_env(:lockspire, :jar_max_age_seconds, 300)
    assert Lockspire.Config.jar_max_age_seconds() == 300
  end

  test "test resolver satisfies the host seam behaviour without macros" do
    assert {:ok, %{id: "account-123"}} =
             Lockspire.TestAccountResolver.resolve_current_account(%{}, %Lockspire.Host.Context{
               return_to: "/authorize"
             })

    assert {:ok, %{id: "account-456"}} =
             Lockspire.TestAccountResolver.resolve_account(
               "account-456",
               %Lockspire.Host.Context{}
             )

    assert {:ok, %Lockspire.Host.Claims{subject: "account-456"}} =
             Lockspire.TestAccountResolver.build_claims(
               %{id: "account-456"},
               %Lockspire.Host.Context{}
             )

    assert %Lockspire.Host.InteractionResult{
             login_path: "/sign-in",
             return_to: "/authorize"
           } =
             Lockspire.TestAccountResolver.redirect_for_login(%{}, %Lockspire.Host.Context{
               return_to: "/authorize"
             })

    assert %Lockspire.Host.InteractionResult{
             login_path: "/sign-out",
             return_to: "/logout/complete"
           } =
             Lockspire.TestAccountResolver.redirect_for_logout(%{}, %Lockspire.Host.Context{
               return_to: "/logout/complete"
             })
  end
end
