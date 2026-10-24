defmodule Lockspire.Web.AdminRoutesCompileTest do
  use ExUnit.Case, async: false

  alias Lockspire.Web.AdminRouteHost.LiveAuthorization
  alias Lockspire.Web.AdminRoutes

  defmodule SecondHook do
    def on_mount(_name, _params, _session, socket), do: {:cont, socket}
  end

  defmodule RootRouter do
    use Phoenix.Router
    require AdminRoutes

    pipeline(:host_auth, do: plug(:accepts, ["html"]))

    AdminRoutes.lockspire_admin_routes("/lockspire/admin",
      pipe_through: [:host_auth],
      on_mount: [LiveAuthorization, SecondHook]
    )
  end

  defmodule NestedRouter do
    use Phoenix.Router
    import AdminRoutes, only: [lockspire_admin_routes: 2]

    pipeline(:host_auth, do: plug(:accepts, ["html"]))

    scope "/lockspire" do
      lockspire_admin_routes("/admin",
        pipe_through: [:host_auth],
        on_mount: LiveAuthorization
      )
    end
  end

  defmodule AliasedRouter do
    use Phoenix.Router
    require AdminRoutes

    pipeline(:host_auth, do: plug(:accepts, ["html"]))

    scope "/lockspire", Lockspire.Web do
      AdminRoutes.lockspire_admin_routes("/admin",
        pipe_through: [:host_auth],
        on_mount: LiveAuthorization
      )
    end
  end

  defmodule TupleHookRouter do
    use Phoenix.Router
    require AdminRoutes

    pipeline(:host_auth, do: plug(:accepts, ["html"]))

    AdminRoutes.lockspire_admin_routes("/lockspire/admin",
      pipe_through: [:host_auth],
      on_mount: {Lockspire.Web.AdminRouteHost.LiveAuthorization, :host_auth}
    )
  end

  test "root and scoped declarations compile to the same ordered native routes" do
    root = normalized_routes(RootRouter)
    nested = normalized_routes(NestedRouter)
    assert root == nested
    assert length(root) == 29

    assert %{pipe_through: [:host_auth, :lockspire_admin_mount]} =
             Phoenix.Router.route_info(RootRouter, "GET", "/lockspire/admin", "www.example.com")

    assert [Lockspire.Web.AdminRouteHost.LiveAuthorization, SecondHook, Lockspire.Web.AdminMount] ==
             hook_modules(RootRouter, "/lockspire/admin")

    assert [Lockspire.Web.AdminRouteHost.LiveAuthorization, Lockspire.Web.AdminMount] ==
             hook_modules(NestedRouter, "/lockspire/admin")

    assert [Lockspire.Web.AdminRouteHost.LiveAuthorization, Lockspire.Web.AdminMount] ==
             hook_modules(TupleHookRouter, "/lockspire/admin")

    assert Lockspire.Web.Live.Admin.OverviewLive.Index ==
             Phoenix.Router.route_info(
               AliasedRouter,
               "GET",
               "/lockspire/admin",
               "www.example.com"
             )
             |> Map.fetch!(:phoenix_live_view)
             |> elem(0)

    assert :error ==
             Phoenix.Router.route_info(RootRouter, "GET", "/xlockspire/admin", "www.example.com")

    assert :error ==
             Phoenix.Router.route_info(
               RootRouter,
               "GET",
               "/lockspire/admin-extra",
               "www.example.com"
             )
  end

  test "the macro rejects malformed paths and required host wiring at compile time" do
    for {path, options} <- [
          {"relative/admin", "pipe_through: [:browser], on_mount: HostHook"},
          {"/lockspire/:tenant/admin", "pipe_through: [:browser], on_mount: HostHook"},
          {"/lockspire/admin", "pipe_through: [], on_mount: HostHook"},
          {"/lockspire/admin", "pipe_through: nil, on_mount: HostHook"},
          {"/lockspire/admin", "on_mount: HostHook"},
          {"/lockspire/admin", "pipe_through: [:browser], on_mount: []"},
          {"/lockspire/admin", "pipe_through: [:browser], on_mount: nil"},
          {"/lockspire/admin", "pipe_through: [:browser]"},
          {"/lockspire/admin", "pipe_through: [:browser], on_mount: HostHook, unknown: true"},
          {"/lockspire/admin",
           "pipe_through: [:browser], on_mount: HostHook, session: %{bad: :key}"},
          {"/lockspire/admin",
           "pipe_through: [:browser], on_mount: HostHook, session: {HostHook, :session}"},
          {"/lockspire/admin",
           "pipe_through: [:browser], on_mount: HostHook, session: {HostHook, :session, :args}"},
          {"/lockspire/admin", "pipe_through: [:browser], on_mount: HostHook, root_layout: :bad"},
          {"/lockspire/admin",
           "pipe_through: [:browser], on_mount: HostHook, layout: {HostHook, :main, :extra}"},
          {"/lockspire/admin", "pipe_through: [:browser], on_mount: HostHook, session: nil"},
          {"/lockspire/admin",
           "pipe_through: [:browser], pipe_through: [:other], on_mount: HostHook"},
          {"/lockspire/admin", "pipe_through: [:missing_pipeline], on_mount: HostHook"}
        ] do
      assert_compile_error(path, options)
    end
  end

  test "the macro preserves native string-keyed session and false layout options" do
    router =
      compile_router!("""
      Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
        pipe_through: [:browser], on_mount: HostHook,
        session: %{"host" => "value"}, root_layout: false, layout: false
      )
      """)

    route = Phoenix.Router.route_info(router, "GET", "/lockspire/admin", "www.example.com")
    {_view, _action, _opts, live_session} = route.phoenix_live_view
    assert live_session.name == :lockspire_admin
    assert live_session.extra.session == %{"host" => "value"}
    assert live_session.extra.root_layout == false
    assert live_session.extra.layout == false
  end

  test "native root layout and MFA options are passed through without compile-time invocation" do
    router =
      compile_router!("""
      Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
        pipe_through: [:browser], on_mount: HostHook,
        session: {HostHook, :session, ["tag"]}, root_layout: {HostHook, :root}, layout: {HostHook, :inner}
      )
      """)

    route = Phoenix.Router.route_info(router, "GET", "/lockspire/admin", "www.example.com")
    {_view, _action, _opts, live_session} = route.phoenix_live_view
    assert match?({module, :session, ["tag"]} when is_atom(module), live_session.extra.session)
    assert live_session.extra.root_layout == {Module.concat(router, HostHook), :root}
    assert live_session.extra.layout == {Module.concat(router, HostHook), :inner}
  end

  test "a repeated declaration fails on Phoenix's fixed named session" do
    module = unique_module("Duplicate")

    source = """
    defmodule #{inspect(module)} do
      use Phoenix.Router
      require Lockspire.Web.AdminRoutes
      pipeline :browser, do: plug(:accepts, ["html"])
      Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin", pipe_through: [:browser], on_mount: #{inspect(LiveAuthorization)})
      Lockspire.Web.AdminRoutes.lockspire_admin_routes("/other/admin", pipe_through: [:browser], on_mount: #{inspect(LiveAuthorization)})
    end
    """

    assert_raise RuntimeError, ~r/redefine live_session :lockspire_admin/, fn ->
      Code.compile_string(source)
    end
  end

  test "an existing native session with the fixed name cannot be replaced" do
    assert_compile_failure(fn ->
      compile_router!("""
      Phoenix.LiveView.Router.live_session :lockspire_admin do
        Phoenix.LiveView.Router.live("/existing", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
      end
      Lockspire.Web.AdminRoutes.lockspire_admin_routes("/lockspire/admin",
        pipe_through: [:browser], on_mount: HostHook
      )
      """)
    end)
  end

  defp normalized_routes(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.map(fn route ->
      {route.verb, route.path, route.plug_opts,
       case route.metadata[:phoenix_live_view] do
         {view, action, _opts, live_session} -> {view, action, live_session.name}
       end}
    end)
  end

  defp hook_modules(router, path) do
    route = Phoenix.Router.route_info(router, "GET", path, "www.example.com")
    {_view, _action, _opts, live_session} = route.phoenix_live_view

    Enum.map(live_session.extra.on_mount, fn hook ->
      {:module, module} = :erlang.fun_info(hook.function, :module)
      module
    end)
  end

  defp assert_compile_error(path, options) do
    assert_compile_failure(fn ->
      compile_router!(
        "Lockspire.Web.AdminRoutes.lockspire_admin_routes(#{inspect(path)}, #{options})"
      )
    end)
  end

  defp assert_compile_failure(fun) do
    error =
      try do
        fun.()
        flunk("expected macro compilation to fail")
      rescue
        error in [ArgumentError, CompileError, RuntimeError] -> error
      end

    assert Exception.message(error) != ""
  end

  defp compile_router!(body) do
    module = unique_module("Compile")

    source = """
    defmodule #{inspect(module)} do
      use Phoenix.Router
      require Phoenix.LiveView.Router
      require Lockspire.Web.AdminRoutes
      defmodule HostHook do
        def on_mount(_name, _params, _session, socket), do: {:cont, socket}
        def session(_conn), do: %{"host" => "value"}
      end
      pipeline :browser, do: plug(:accepts, ["html"])
      #{body}
    end
    """

    compiled = Code.compile_string(source)

    Enum.find_value(compiled, fn {compiled_module, _binary} ->
      if compiled_module == module, do: compiled_module
    end)
  end

  defp unique_module(prefix) do
    Module.concat(__MODULE__, "#{prefix}#{System.unique_integer([:positive])}")
  end
end
