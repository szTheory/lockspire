defmodule Lockspire.Install.VerifyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Install.Verify

  defmodule RemoteJwksFetcher do
    def get_keys(_uri, _opts), do: {:error, {:jwks_fetch_failed, :timeout}}
  end

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

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

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

  test "appends an opt-in remote jwks diagnostic without changing the default install checks" do
    original_fetcher = Application.get_env(:lockspire, :jwks_fetcher)

    on_exit(fn ->
      if is_nil(original_fetcher) do
        Application.delete_env(:lockspire, :jwks_fetcher)
      else
        Application.put_env(:lockspire, :jwks_fetcher, original_fetcher)
      end
    end)

    Application.put_env(:lockspire, :jwks_fetcher, RemoteJwksFetcher)

    {:ok, _client} =
      Lockspire.Storage.Ecto.Repository.register_client(%Lockspire.Domain.Client{
        client_id: "verify-remote-client",
        client_type: :confidential,
        token_endpoint_auth_method: :private_key_jwt,
        redirect_uris: ["https://app.example.test/cb"],
        allowed_scopes: ["openid"],
        allowed_grant_types: ["authorization_code"],
        allowed_response_types: ["code"],
        pkce_required: true,
        subject_type: :public,
        jwks_uri: "https://keys.example.test/verify-client.jwks.json",
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    result =
      Verify.run(
        router: Web.Router,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire",
        remote_jwks_client_id: "verify-remote-client"
      )

    assert %{status: :error, details: details} = Enum.find(result.checks, &(&1.id == :remote_jwks))
    assert details =~ "client_id=verify-remote-client"
    assert details =~ "category=transport"
    assert details =~ "timed out"
  end
end
