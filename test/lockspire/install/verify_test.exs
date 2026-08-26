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

  defmodule OperatorGuard do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule Web.Router do
    use Phoenix.Router

    import Phoenix.LiveView.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    pipeline :require_operator do
      plug(Lockspire.Install.VerifyTest.OperatorGuard)
    end

    scope "/", Lockspire.Install.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
      get("/authorized-apps", PlaceholderController, :index)
      delete("/authorized-apps/:id", PlaceholderController, :delete)
    end

    scope "/lockspire" do
      live("/consent/:interaction_id", Lockspire.Install.VerifyTest.ConsentLive, :show)
    end

    scope "/lockspire/admin" do
      pipe_through([:browser, :require_operator])
      forward("/", Lockspire.Web.AdminRouter)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterMissingVerify do
    use Phoenix.Router

    import Phoenix.LiveView.Router

    scope "/" do
      get("/authorized-apps", Lockspire.Install.VerifyTest.PlaceholderController, :index)
      delete("/authorized-apps/:id", Lockspire.Install.VerifyTest.PlaceholderController, :delete)
    end

    scope "/lockspire" do
      live("/consent/:interaction_id", Lockspire.Install.VerifyTest.ConsentLive, :show)
    end

    scope "/lockspire/admin" do
      forward("/", Lockspire.Web.AdminRouter)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterMissingAdmin do
    use Phoenix.Router

    import Phoenix.LiveView.Router

    scope "/", Lockspire.Install.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
      get("/authorized-apps", PlaceholderController, :index)
      delete("/authorized-apps/:id", PlaceholderController, :delete)
    end

    scope "/lockspire" do
      live("/consent/:interaction_id", Lockspire.Install.VerifyTest.ConsentLive, :show)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterUnguardedAdmin do
    use Phoenix.Router

    import Phoenix.LiveView.Router

    scope "/", Lockspire.Install.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
      get("/authorized-apps", PlaceholderController, :index)
      delete("/authorized-apps/:id", PlaceholderController, :delete)
    end

    scope "/lockspire" do
      live("/consent/:interaction_id", Lockspire.Install.VerifyTest.ConsentLive, :show)
    end

    # A host can forward the admin router without its operator pipeline. The
    # verifier must reject this even though the path and target are correct.
    scope "/lockspire/admin" do
      forward("/", Lockspire.Web.AdminRouter)
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

    defp route(:*, "/lockspire/admin" = path, Lockspire.Web.AdminRouter),
      do: %{
        verb: :*,
        path: path,
        plug: Lockspire.Web.AdminRouter,
        metadata: %{lockspire_operator_guard: true}
      }

    defp route(verb, path, plug), do: %{verb: verb, path: path, plug: plug}
  end

  defmodule PlaceholderController do
    use Phoenix.Controller, formats: []

    def show(conn, _params), do: conn
    def lookup(conn, _params), do: conn
    def approve(conn, _params), do: conn
    def deny(conn, _params), do: conn
    def index(conn, _params), do: conn
    def delete(conn, _params), do: conn
  end

  defmodule ConsentLive do
    use Phoenix.LiveView

    def render(assigns), do: ~H"<main>Consent</main>"
  end

  setup do
    original_env =
      for key <- [:repo, :account_resolver, :issuer, :mount_path, :logout_path, :oban],
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

    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :account_resolver, Scope.AccountResolver)
    Application.put_env(:lockspire, :issuer, "https://example.test/lockspire")
    Application.put_env(:lockspire, :mount_path, "/lockspire")
    Application.put_env(:lockspire, :logout_path, "/logout")
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

  test "reports every missing config seam independently without suppressing module checks" do
    Application.delete_env(:lockspire, :repo)
    Application.delete_env(:lockspire, :account_resolver)
    Application.delete_env(:lockspire, :issuer)
    Application.delete_env(:lockspire, :mount_path)
    Application.delete_env(:lockspire, :logout_path)
    Application.put_env(:lockspire, :oban, repo: :not_a_repo, queues: :invalid)

    result =
      Verify.run(
        router: Web.Router,
        resolver_module: MissingResolver,
        interaction_handler_module: MissingInteractionHandler,
        repo: Lockspire.TestRepo,
        project_root: File.cwd!()
      )

    assert Enum.map(result.checks, & &1.id) |> Enum.sort() ==
             [
               :account_resolver,
               :issuer,
               :logout_path,
               :migrations,
               :mount_path,
               :oban,
               :repo,
               :resolver_module,
               :router,
               :interaction_handler_module
             ]
             |> Enum.sort()

    for id <- [:repo, :account_resolver, :issuer, :mount_path, :logout_path, :oban] do
      assert %{status: :error, fix: fix} = Enum.find(result.checks, &(&1.id == id))
      assert fix =~ "config/lockspire.exs"
    end

    assert %{status: :error, details: resolver_details} =
             Enum.find(result.checks, &(&1.id == :resolver_module))

    assert resolver_details =~ "MissingResolver"

    assert %{status: :error, details: handler_details} =
             Enum.find(result.checks, &(&1.id == :interaction_handler_module))

    assert handler_details =~ "MissingInteractionHandler"
  end

  test "reports missing generated authorized-app and consent routes together" do
    result =
      Verify.run(
        router: RouterMissingVerify,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    assert %{status: :error, details: details, fix: fix} =
             Enum.find(result.checks, &(&1.id == :router))

    assert details =~ "get /verify"
    assert fix =~ "lockspire_routes"
  end

  test "reports missing copied host migrations before database migration status" do
    project_root =
      Path.join(System.tmp_dir!(), "lockspire-verify-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(project_root) end)

    result =
      Verify.run(
        router: Web.Router,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire",
        project_root: project_root
      )

    assert %{status: :error, details: details, fix: fix} =
             Enum.find(result.checks, &(&1.id == :migrations))

    assert details =~ "priv/repo/migrations"
    assert fix =~ "mix lockspire.install"
    assert fix =~ "mix ecto.migrate"
  end

  test "returns a failing result set for a missing generated admin mount" do
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
    assert fix =~ "host request tests"
  end

  test "reports admin mount shape without claiming to verify host operator policy" do
    result =
      Verify.run(
        router: RouterUnguardedAdmin,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    assert result.ok?
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

    assert details =~ "generated admin forward appears after the public Lockspire forward"
    assert fix =~ "host request tests"
  end
end
