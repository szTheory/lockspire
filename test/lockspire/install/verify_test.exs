defmodule Lockspire.Install.VerifyTest.RouterGenerator do
  defmacro define_native_host_router(name, mount_path) do
    name = Macro.expand(name, __CALLER__)
    mount_path = Macro.expand(mount_path, __CALLER__)

    admin_path =
      if mount_path in ["", "/"],
        do: "/admin",
        else: String.trim_trailing(mount_path, "/") <> "/admin"

    consent_path =
      if mount_path in ["", "/"],
        do: "/consent/:interaction_id",
        else: String.trim_trailing(mount_path, "/") <> "/consent/:interaction_id"

    public_path = if mount_path in ["", "/"], do: "/", else: String.trim_trailing(mount_path, "/")

    quote do
      defmodule unquote(name) do
        use Phoenix.Router
        import Phoenix.LiveView.Router
        require Lockspire.Web.AdminRoutes

        pipeline :selected_host_authorization do
          plug(Lockspire.Install.VerifyTest.HostAuthorizationPlug)
        end

        scope "/", Lockspire.Install.VerifyTest do
          get("/verify", PlaceholderController, :show)
          post("/verify", PlaceholderController, :lookup)
          post("/verify/:handle/approve", PlaceholderController, :approve)
          post("/verify/:handle/deny", PlaceholderController, :deny)
          get("/authorized-apps", PlaceholderController, :index)
          delete("/authorized-apps/:id", PlaceholderController, :delete)
        end

        Lockspire.Web.AdminRoutes.lockspire_admin_routes(unquote(admin_path),
          pipe_through: [:selected_host_authorization],
          on_mount: Lockspire.Install.VerifyTest.HostLiveAuthorization
        )

        scope "/" do
          live(unquote(consent_path), Lockspire.Install.VerifyTest.ConsentLive, :show)
          forward(unquote(public_path), Lockspire.Web.Router)
        end
      end
    end
  end
end

defmodule Lockspire.Install.VerifyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Install.Verify
  alias Lockspire.KeyEncryptionHelpers

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

  defmodule HostAuthorizationPlug do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule HostLiveAuthorization do
    def on_mount(_name, _params, _session, socket), do: {:cont, socket}
  end

  require Lockspire.Install.VerifyTest.RouterGenerator

  Lockspire.Install.VerifyTest.RouterGenerator.define_native_host_router(
    RootMountNativeRouter,
    ""
  )

  Lockspire.Install.VerifyTest.RouterGenerator.define_native_host_router(
    NestedMountNativeRouter,
    "/teams/ops/identity"
  )

  defmodule NativeAdminRouter do
    use Phoenix.Router

    import Phoenix.LiveView.Router
    require Lockspire.Web.AdminRoutes

    pipeline :operator_access do
      plug(Lockspire.Install.VerifyTest.HostAuthorizationPlug)
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

    Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
      pipe_through: [:operator_access],
      on_mount: Lockspire.Install.VerifyTest.HostLiveAuthorization
    )

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end
  end

  defmodule ShadowedAdminRouter do
    use Phoenix.Router

    import Phoenix.LiveView.Router
    require Lockspire.Web.AdminRoutes

    pipeline :operator_access do
      plug(Lockspire.Install.VerifyTest.HostAuthorizationPlug)
    end

    scope "/", Lockspire.Install.VerifyTest do
      get("/verify", PlaceholderController, :show)
      post("/verify", PlaceholderController, :lookup)
      post("/verify/:handle/approve", PlaceholderController, :approve)
      post("/verify/:handle/deny", PlaceholderController, :deny)
      get("/authorized-apps", PlaceholderController, :index)
      delete("/authorized-apps/:id", PlaceholderController, :delete)
    end

    scope "/" do
      forward("/lockspire", Lockspire.Web.Router)
    end

    Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
      pipe_through: [:operator_access],
      on_mount: Lockspire.Install.VerifyTest.HostLiveAuthorization
    )

    scope "/lockspire" do
      live("/consent/:interaction_id", Lockspire.Install.VerifyTest.ConsentLive, :show)
    end
  end

  defmodule RouteMetadataVariantRouter do
    def __routes__ do
      routes = NativeAdminRouter.__routes__()

      case Application.get_env(:lockspire, :verify_route_variant) do
        :missing ->
          Enum.reject(routes, &(&1.path == "/lockspire/admin/clients/new"))

        :duplicate ->
          routes ++ [route_at(routes, "/lockspire/admin/clients/new")]

        :wrong_action ->
          update_route(routes, "/lockspire/admin/clients/new", &change_view(&1, :action))

        :wrong_view ->
          update_route(routes, "/lockspire/admin/clients/new", &change_view(&1, :view))

        :wrong_target ->
          update_route(
            routes,
            "/lockspire/admin/clients/new",
            &Map.put(&1, :plug, Phoenix.Controller)
          )

        :wrong_session ->
          update_route(
            routes,
            "/lockspire/admin/clients/new",
            &change_session(&1, :wrong_session)
          )

        :missing_hook ->
          update_route(routes, "/lockspire/admin/clients/new", &change_hooks(&1, :missing))

        :guard_first ->
          update_route(routes, "/lockspire/admin/clients/new", &change_hooks(&1, :guard_first))

        :wrong_guard_router ->
          update_route(routes, "/lockspire/admin/clients/new", &change_hooks(&1, :wrong_router))

        :malformed ->
          update_route(
            routes,
            "/lockspire/admin/clients/new",
            &Map.update!(&1, :metadata, fn metadata ->
              Map.put(metadata, :phoenix_live_view, "PRIVATE_METADATA_SENTINEL")
            end)
          )

        :extra_admin_view ->
          routes ++
            [
              Map.put(
                route_at(routes, "/lockspire/admin/clients"),
                :path,
                "/lockspire/admin/clients-extra"
              )
            ]

        _other ->
          routes
      end
    end

    def __match_route__(method, path, host) do
      result = NativeAdminRouter.__match_route__(method, path, host)

      if Application.get_env(:lockspire, :verify_route_variant) == :missing_pipeline do
        case result do
          {metadata, prepare, pipeline, dispatch} ->
            {Map.put(metadata, :pipe_through, [:lockspire_admin_mount]), prepare, pipeline,
             dispatch}

          other ->
            other
        end
      else
        result
      end
    end

    defp route_at(routes, path), do: Enum.find(routes, &(&1.path == path))

    defp update_route(routes, path, update) do
      Enum.map(routes, fn route -> if route.path == path, do: update.(route), else: route end)
    end

    defp change_view(route, :action) do
      Map.update!(route, :metadata, fn metadata ->
        Map.update!(metadata, :phoenix_live_view, fn {view, _action, options, session} ->
          {view, :index, options, session}
        end)
      end)
    end

    defp change_view(route, :view) do
      Map.update!(route, :metadata, fn metadata ->
        Map.update!(metadata, :phoenix_live_view, fn {_view, action, options, session} ->
          {Lockspire.Web.Live.Admin.OverviewLive.Index, action, options, session}
        end)
      end)
    end

    defp change_session(route, name) do
      update_session(route, fn session -> Map.put(session, :name, name) end)
    end

    defp change_hooks(route, mode) do
      update_session(route, fn session ->
        hooks = get_in(session, [:extra, :on_mount])
        guard = List.last(hooks)
        host = hd(hooks)

        changed =
          case mode do
            :missing ->
              [guard]

            :guard_first ->
              [guard, host]

            :wrong_router ->
              List.replace_at(
                hooks,
                -1,
                Map.update!(guard, :id, fn {module, _arg} ->
                  {module, {:mount_path, __MODULE__}}
                end)
              )
          end

        update_in(session, [:extra, :on_mount], fn _hooks -> changed end)
      end)
    end

    defp update_session(route, update) do
      Map.update!(route, :metadata, fn metadata ->
        Map.update!(metadata, :phoenix_live_view, fn {view, action, options, session} ->
          {view, action, options, update.(session)}
        end)
      end)
    end
  end

  defmodule MalformedRoutesRouter do
    def __routes__, do: :malformed
  end

  defmodule ExceptionRoutesRouter do
    def __routes__, do: raise("ROUTER_EXCEPTION_SENTINEL")
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

  defmodule FailingRepo do
    def config, do: []
    def __adapter__, do: Ecto.Adapters.Postgres
    def start_link(_opts), do: raise(DBConnection.ConnectionError, "connection refused")
  end

  defmodule ConsentLive do
    use Phoenix.LiveView

    def render(assigns), do: ~H"<main>Consent</main>"
  end

  setup do
    original_env =
      for key <- [
            :repo,
            :account_resolver,
            :issuer,
            :mount_path,
            :logout_path,
            :oban,
            :key_encryption
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
        router: NativeAdminRouter,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire",
        key_storage_status: fn -> {:ok, ready_status()} end
      )

    assert result.ok?
    assert Enum.all?(result.checks, &(&1.status == :ok))
    assert Enum.any?(result.checks, &(&1.id == :router))
    assert Enum.any?(result.checks, &(&1.id == :migrations))
  end

  test "accepts complete compiled native admin routes" do
    result =
      Verify.run(
        router: NativeAdminRouter,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire",
        key_storage_status: fn -> {:ok, ready_status()} end
      )

    assert %{status: :ok, summary: "Host router wiring is present"} =
             Enum.find(result.checks, &(&1.id == :router))
  end

  test "verifier reads the shared hidden route inventory" do
    inventory = Lockspire.Web.AdminRoutes.__route_inventory__()
    assert length(inventory) == 29
    assert {"/clients/new", Lockspire.Web.Live.Admin.ClientsLive.Index, :new} in inventory
  end

  test "accepts default, root, and nested host mounts" do
    for {router, mount_path} <- [
          {NativeAdminRouter, "/lockspire"},
          {RootMountNativeRouter, "/"},
          {NestedMountNativeRouter, "/teams/ops/identity"}
        ] do
      assert %{status: :ok} = verify_router_check(router, mount_path)
    end
  end

  test "rejects exact compiled inventory, session, pipeline, and hook defects" do
    on_exit(fn -> Application.delete_env(:lockspire, :verify_route_variant) end)

    for {variant, expected} <- [
          {:missing, "missing native admin route GET /lockspire/admin/clients/new"},
          {:duplicate, "duplicate native admin route GET /lockspire/admin/clients/new"},
          {:wrong_action,
           "wrong native admin target or action at GET /lockspire/admin/clients/new"},
          {:wrong_view,
           "wrong native admin target or action at GET /lockspire/admin/clients/new"},
          {:wrong_target,
           "wrong native admin target or action at GET /lockspire/admin/clients/new"},
          {:wrong_session,
           "wrong native admin LiveView session at GET /lockspire/admin/clients/new"},
          {:missing_pipeline,
           "missing host authorization pipeline before :lockspire_admin_mount"},
          {:missing_hook, "missing host LiveView authorization hook"},
          {:guard_first, "guard is missing, misordered, or has the wrong router argument"},
          {:wrong_guard_router, "guard is missing, misordered, or has the wrong router argument"},
          {:malformed, "malformed native admin metadata at GET /lockspire/admin/clients/new"},
          {:extra_admin_view, "unexpected route in the canonical admin namespace"}
        ] do
      Application.put_env(:lockspire, :verify_route_variant, variant)
      check = verify_router_check(RouteMetadataVariantRouter, "/lockspire")
      assert check.status == :error, "variant #{variant} was unexpectedly accepted"
      assert check.details =~ expected, "variant #{variant} lacked its structural diagnosis"
    end
  end

  test "a compiled public forward that wins first-match dispatch is rejected" do
    assert Phoenix.Router.route_info(
             ShadowedAdminRouter,
             "GET",
             "/lockspire/admin/overview",
             "localhost"
           ).plug == Lockspire.Web.Router

    check = verify_router_check(ShadowedAdminRouter, "/lockspire")
    assert check.status == :error
    assert check.details =~ "first-match dispatch does not select the canonical admin route"
    assert check.details =~ "canonical admin route appears after the public Lockspire forward"
  end

  test "malformed and exception route metadata produce bounded errors" do
    for router <- [MalformedRoutesRouter, ExceptionRoutesRouter] do
      check = verify_router_check(router, "/lockspire")
      assert check.status == :error
      assert check.summary =~ "router metadata"
      refute inspect(check) =~ "ROUTER_EXCEPTION_SENTINEL"
      refute inspect(check) =~ "PRIVATE_METADATA_SENTINEL"
    end
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
        router: NativeAdminRouter,
        resolver_module: MissingResolver,
        interaction_handler_module: MissingInteractionHandler,
        repo: Lockspire.TestRepo,
        project_root: File.cwd!()
      )

    assert Enum.map(result.checks, & &1.id) |> Enum.sort() ==
             [
               :account_resolver,
               :issuer,
               :key_encryption,
               :logout_path,
               :migrations,
               :mount_path,
               :oban,
               :repo,
               :resolver_module,
               :router,
               :interaction_handler_module,
               :key_storage
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

  describe ":key_encryption check" do
    @sentinel "SENTINEL-KEK-MATERIAL"

    defp verify_opts do
      [
        router: NativeAdminRouter,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      ]
    end

    defp kek_check(result), do: Enum.find(result.checks, &(&1.id == :key_encryption))

    test "is ok with ids, current and mode details for the valid test KEK" do
      result = Verify.run(verify_opts())
      assert %{status: :ok, details: details} = kek_check(result)
      assert details =~ "current=test-1"
      assert details =~ "ids=test-1,test-2"
      assert details =~ "legacy_plaintext=allow"
      assert result.ok?
    end

    test "errors when the KEK is absent" do
      KeyEncryptionHelpers.put_key_encryption(nil)
      result = Verify.run(verify_opts())

      refute result.ok?
      assert %{status: :error, details: details, fix: fix} = kek_check(result)
      assert details =~ ":key_encryption"
      assert fix =~ "config/runtime.exs"
      assert fix =~ "mix lockspire.gen.kek"
      refute fix =~ "openssl"
    end

    test "errors on invalid config without leaking the sentinel" do
      Application.put_env(:lockspire, :key_encryption,
        keys: [{"bad", @sentinel}],
        current: "bad"
      )

      result = Verify.run(verify_opts())
      refute result.ok?
      check = kek_check(result)
      assert check.status == :error
      assert check.details =~ ":key_encryption"
      refute inspect(check) =~ @sentinel
    end
  end

  describe ":key_encryption check with {:system, var}" do
    @unset_var "LOCKSPIRE_TEST_KEK_VERIFY_UNSET"
    @set_var "LOCKSPIRE_TEST_KEK_VERIFY_SET"

    setup do
      prior = for v <- [@unset_var, @set_var], do: {v, System.get_env(v)}
      System.delete_env(@unset_var)

      # Registers env and cache restoration for the original block.
      KeyEncryptionHelpers.put_key_encryption(Application.get_env(:lockspire, :key_encryption))

      on_exit(fn ->
        for {v, value} <- prior do
          if value, do: System.put_env(v, value), else: System.delete_env(v)
        end
      end)

      :ok
    end

    defp verify_kek_opts do
      [
        router: NativeAdminRouter,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      ]
    end

    test "errors with the variable name when a {:system, var} key is unset" do
      secret = Base.encode64(:crypto.hash(:sha256, "verify-secret"))
      System.put_env(@set_var, secret)

      Application.put_env(:lockspire, :key_encryption,
        keys: [{"a", {:system, @set_var}}, {"b", {:system, @unset_var}}],
        current: "a"
      )

      result = Verify.run(verify_kek_opts())
      refute result.ok?

      check = Enum.find(result.checks, &(&1.id == :key_encryption))
      assert check.status == :error
      assert check.details =~ @unset_var
      assert check.details =~ "missing_env"
      refute inspect(check) =~ secret
    end
  end

  describe ":key_storage check" do
    defp storage_check(status_result, extra \\ []) do
      opts =
        [
          router: NativeAdminRouter,
          resolver_module: Scope.AccountResolver,
          interaction_handler_module: Scope.InteractionHandler,
          repo: Lockspire.TestRepo,
          mount_path: "/lockspire",
          key_storage_status: fn -> status_result end
        ] ++ extra

      Enum.find(Verify.run(opts).checks, &(&1.id == :key_storage))
    end

    test "is ok for a ready status" do
      assert %{status: :ok, details: details} = storage_check({:ok, ready_status()})
      assert details =~ "total=0"
      refute details =~ "stranded_retired"
    end

    test "is ok with counts for legacy rows under :allow" do
      status = %{ready_status() | legacy: 2, total: 2, ready?: false}

      assert %{status: :ok, details: details} = storage_check({:ok, status})
      assert details =~ "legacy=2"
      assert details =~ "legacy_plaintext=allow"
    end

    test "is an error when an unknown key id holds rows" do
      status = %{ready_status() | unknown_kek: %{"gone-1" => 2}, total: 2, ready?: false}

      assert %{status: :error, details: details, fix: fix} = storage_check({:ok, status})
      assert details =~ "gone-1"
      assert fix =~ "mix lockspire.keys.reencrypt"
    end

    test "is an error when a row cannot be decrypted" do
      status = %{ready_status() | undecryptable: 1, total: 1, ready?: false}
      assert %{status: :error} = storage_check({:ok, status})
    end

    test "is an error for legacy rows under :reject" do
      status = %{ready_status() | legacy: 1, total: 1, legacy_plaintext: :reject, ready?: false}
      assert %{status: :error} = storage_check({:ok, status})
    end

    test "stranded retired rows are listed and never make it an error" do
      status = %{ready_status() | stranded_retired: %{count: 2, kids: ["k-a", "k-b"]}}

      assert %{status: :ok, details: details} = storage_check({:ok, status})
      assert details =~ "stranded_retired=2"
      assert details =~ "k-a"
      assert details =~ "k-b"
    end

    test "is a skipped ok when the status cannot be read" do
      assert %{status: :ok, details: details} = storage_check({:error, :storage_unavailable})
      assert details =~ "skipped:"
    end

    test "is a skipped ok when the status function raises" do
      opts = [key_storage_status: fn -> raise "boom" end]

      check =
        Enum.find(
          Verify.run(
            [
              router: NativeAdminRouter,
              resolver_module: Scope.AccountResolver,
              interaction_handler_module: Scope.InteractionHandler,
              repo: Lockspire.TestRepo,
              mount_path: "/lockspire"
            ] ++ opts
          ).checks,
          &(&1.id == :key_storage)
        )

      assert %{status: :ok, details: "skipped:" <> _} = check
      refute inspect(check) =~ "boom"
    end

    test "a repo whose startup raises a connection error does not crash verification" do
      result =
        Verify.run(
          router: NativeAdminRouter,
          resolver_module: Scope.AccountResolver,
          interaction_handler_module: Scope.InteractionHandler,
          repo: Lockspire.Install.VerifyTest.FailingRepo,
          mount_path: "/lockspire"
        )

      assert %{status: :error, details: details} =
               Enum.find(result.checks, &(&1.id == :migrations))

      assert details =~ "could not inspect database migration state"

      assert %{status: :ok, details: "skipped:" <> _} =
               Enum.find(result.checks, &(&1.id == :key_storage))
    end
  end

  defp ready_status do
    {:ok, status} =
      {:ok, Lockspire.Admin.Keys.EncryptionStatus.build(KeyEncryptionHelpers.config_keyset(), [])}

    status
  end

  defp verify_router_check(router, mount_path) do
    result =
      Verify.run(
        router: router,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: mount_path,
        key_storage_status: fn -> {:ok, ready_status()} end
      )

    Enum.find(result.checks, &(&1.id == :router))
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
    assert fix =~ "lockspire_admin_routes/2"
  end

  test "reports missing copied host migrations before database migration status" do
    project_root =
      Path.join(System.tmp_dir!(), "lockspire-verify-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(project_root) end)

    result =
      Verify.run(
        router: NativeAdminRouter,
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

  test "migration verification never creates a shadow schema migrations table" do
    source = File.read!(Path.expand("../../../lib/lockspire/install/verify.ex", __DIR__))

    assert source =~ "skip_table_creation: true"
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

    assert details =~ "missing native admin route GET /lockspire/admin/"
    assert fix =~ "host request and LiveView tests"
  end

  test "does not treat the legacy admin forward as complete native wiring" do
    result =
      Verify.run(
        router: RouterUnguardedAdmin,
        resolver_module: Scope.AccountResolver,
        interaction_handler_module: Scope.InteractionHandler,
        repo: Lockspire.TestRepo,
        mount_path: "/lockspire"
      )

    refute result.ok?
    assert %{status: :error, details: details} = Enum.find(result.checks, &(&1.id == :router))
    assert details =~ "missing native admin route GET /lockspire/admin/"
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

    assert details =~ "missing native admin route GET /lockspire/admin/"
    assert fix =~ "host request and LiveView tests"
  end
end
