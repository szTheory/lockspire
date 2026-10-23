defmodule Mix.Tasks.Lockspire.VerifyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

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

  defmodule HostAuthorizationPlug do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule HostLiveAuthorization do
    def on_mount(_name, _params, _session, socket), do: {:cont, socket}
  end

  defmodule Web.Router do
    use Phoenix.Router

    import Phoenix.LiveView.Router
    require Lockspire.Web.AdminRoutes

    pipeline :operator_access do
      plug(Mix.Tasks.Lockspire.VerifyTest.HostAuthorizationPlug)
    end

    scope "/", Mix.Tasks.Lockspire.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
      get("/authorized-apps", PlaceholderController, :index)
      delete("/authorized-apps/:id", PlaceholderController, :delete)
    end

    scope "/lockspire" do
      live("/consent/:interaction_id", Mix.Tasks.Lockspire.VerifyTest.ConsentLive, :show)
    end

    Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
      pipe_through: [:operator_access],
      on_mount: Mix.Tasks.Lockspire.VerifyTest.HostLiveAuthorization
    )

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

  defmodule Web.LegacyAdmin.Router do
    use Phoenix.Router

    import Phoenix.LiveView.Router

    scope "/", Mix.Tasks.Lockspire.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
      get("/authorized-apps", PlaceholderController, :index)
      delete("/authorized-apps/:id", PlaceholderController, :delete)
    end

    scope "/lockspire" do
      live("/consent/:interaction_id", Mix.Tasks.Lockspire.VerifyTest.ConsentLive, :show)
    end

    scope "/lockspire/admin" do
      forward("/", Lockspire.Web.AdminRouter)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
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
      Mix.Task.reenable("lockspire.verify")

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

  test "prints OK lines for a passing verify run" do
    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Verify.run([
          "--web",
          "Mix.Tasks.Lockspire.VerifyTest.Web",
          "--scope",
          "Mix.Tasks.Lockspire.VerifyTest.Scope",
          "--mount-path",
          "/lockspire"
        ])
      end)

    assert output =~ "OK Runtime config :repo is present"
    assert output =~ "OK Runtime config :logout_path is present"
    assert output =~ "OK Host router wiring is present"
    assert output =~ "Lockspire verification passed."
  end

  test "public diagnostic refuses the legacy admin forward" do
    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/Lockspire verification failed/, fn ->
          Mix.Tasks.Lockspire.Verify.run([
            "--web",
            "Mix.Tasks.Lockspire.VerifyTest.Web.LegacyAdmin",
            "--scope",
            "Mix.Tasks.Lockspire.VerifyTest.Scope",
            "--mount-path",
            "/lockspire"
          ])
        end
      end)

    assert output =~ "missing native admin route"
  end

  test "raises with actionable router guidance when verify routes are missing" do
    assert_raise Mix.Error, ~r/Lockspire verification failed/, fn ->
      capture_io(fn ->
        Mix.Tasks.Lockspire.Verify.run([
          "--web",
          "Mix.Tasks.Lockspire.VerifyTest.RouterMissingVerify",
          "--scope",
          "Mix.Tasks.Lockspire.VerifyTest.Scope",
          "--mount-path",
          "/lockspire"
        ])
      end)
    end
  end
end
