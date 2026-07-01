defmodule Lockspire.Install.VerifyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Install.Verify

  defmodule Scope.AccountResolver do
    @behaviour Lockspire.Host.AccountResolver

    alias Lockspire.Host.Claims
    alias Lockspire.Host.InteractionResult

    def resolve_current_account(_conn_or_socket, _context), do: {:ok, %{id: "verify-user"}}
    def resolve_account(account_reference, _context), do: {:ok, %{id: account_reference}}

    def build_claims(account, _context) do
      {:ok, %Claims{subject: to_string(account.id), id_token: %{}, userinfo: %{}}}
    end

    def redirect_for_login(_conn_or_socket, _context),
      do: %InteractionResult{login_path: "/login", return_to: "/verify", params: %{}}
  end

  defmodule Scope.InteractionHandler do
    def consent_path(interaction_id), do: "/lockspire/consent/#{interaction_id}"
  end

  defmodule Web.Router do
    use Phoenix.Router

    scope "/", Lockspire.Install.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
    end

    scope "/lockspire/admin" do
      forward("/", Lockspire.Web.AdminRouter)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterMissingVerify do
    use Phoenix.Router

    scope "/lockspire/admin" do
      forward("/", Lockspire.Web.AdminRouter)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterMissingAdmin do
    use Phoenix.Router

    scope "/", Lockspire.Install.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterPublicBeforeAdmin do
    def __routes__ do
      [
        route(:get, "/verify", PlaceholderController),
        route(:post, "/verify", PlaceholderController),
        route(:post, "/verify/:handle/approve", PlaceholderController),
        route(:post, "/verify/:handle/deny", PlaceholderController),
        route(:*, "/lockspire", Lockspire.Web.Router),
        route(:*, "/lockspire/admin", Lockspire.Web.AdminRouter)
      ]
    end

    defp route(verb, path, plug), do: %{verb: verb, path: path, plug: plug}
  end

  defmodule PlaceholderController do
    use Phoenix.Controller, formats: []

    def show(conn, _params), do: conn
    def lookup(conn, _params), do: conn
    def approve(conn, _params), do: conn
    def deny(conn, _params), do: conn
  end

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

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Scope.AccountResolver)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :oban, repo: Lockspire.TestRepo, queues: false)

    :ok
  end

  test "returns a passing result set for a wired host router" do
    result =
      Verify.run(
        router: Web.Router,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    assert result.ok?
    assert Enum.all?(result.checks, &(&1.status == :ok))
    assert Enum.any?(result.checks, &(&1.id == :router))
    assert Enum.any?(result.checks, &(&1.id == :migrations))
  end

  test "returns a failing result set for missing verify routes" do
    result =
      Verify.run(
        router: RouterMissingVerify,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    refute result.ok?
    assert %{status: :error, details: details} = Enum.find(result.checks, &(&1.id == :router))
    assert details =~ "get /verify"
  end

  test "returns a failing result set for a missing guarded admin mount" do
    result =
      Verify.run(
        router: RouterMissingAdmin,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    refute result.ok?

    assert %{status: :error, details: details, fix: fix} =
             Enum.find(result.checks, &(&1.id == :router))

    assert details =~ "forward /lockspire/admin -> Lockspire.Web.AdminRouter"
    assert fix =~ "host-owned operator auth pipeline"
  end

  test "returns a failing result when public forward shadows the admin mount" do
    result =
      Verify.run(
        router: RouterPublicBeforeAdmin,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    refute result.ok?

    assert %{status: :error, details: details, fix: fix} =
             Enum.find(result.checks, &(&1.id == :router))

    assert details =~ "public forward /lockspire -> Lockspire.Web.Router appears before admin"
    assert fix =~ "Move the guarded `Lockspire.Web.AdminRouter` mount above"
  end
end
