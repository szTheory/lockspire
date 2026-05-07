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

  defmodule Web.Router do
    use Phoenix.Router

    scope "/", Mix.Tasks.Lockspire.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule RouterMissingVerify do
    use Phoenix.Router

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
  end

  setup do
    original_env =
      for key <- [:repo, :account_resolver, :issuer, :mount_path, :oban], into: %{} do
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
    Application.put_env(:lockspire, :oban, repo: Lockspire.TestRepo, queues: false)

    :ok
  end

  test "prints OK lines for a passing verify run" do
    output =
      capture_io(fn ->
        Mix.Tasks.Lockspire.Verify.run(
          [
            "--web",
            "Mix.Tasks.Lockspire.VerifyTest.Web",
            "--scope",
            "Mix.Tasks.Lockspire.VerifyTest.Scope",
            "--mount-path",
            "/lockspire"
          ]
        )
      end)

    assert output =~ "OK Runtime config is present"
    assert output =~ "OK Host router wiring is present"
    assert output =~ "Lockspire verification passed."
  end

  test "raises with actionable router guidance when verify routes are missing" do
    assert_raise Mix.Error, ~r/Lockspire verification failed/, fn ->
      capture_io(fn ->
        Mix.Tasks.Lockspire.Verify.run(
          [
            "--web",
            "Mix.Tasks.Lockspire.VerifyTest.RouterMissingVerify",
            "--scope",
            "Mix.Tasks.Lockspire.VerifyTest.Scope",
            "--mount-path",
            "/lockspire"
          ]
        )
      end)
    end
  end
end
