defmodule Lockspire.Integration.InstallTemplateCompileTest do
  use ExUnit.Case, async: false

  import Plug.Test

  alias Lockspire.Generators.Install
  alias Lockspire.Generators.Templates

  # `build_assigns/1` only reads Lockspire's own `Mix.Project.config()[:app]` --
  # it needs no host, no `in_project`, and writes nothing to disk. Point
  # `project_root` at a non-existent path as a belt-and-braces guard against any
  # accidental write.
  @assigns Install.build_assigns(
             web: "InstallTemplateCompileWeb",
             scope: "InstallTemplateCompile.Lockspire",
             path: "/nonexistent/install-template-compile-test"
           )

  test "the rendered router helper injects a real, correctly ordered, deny-closed route table" do
    rendered_router_module = router_helper_source()

    stub_router_source = """
    defmodule InstallTemplateCompileWeb.Router do
      use Phoenix.Router
      import Phoenix.LiveView.Router
      import InstallTemplateCompileWeb.Router.Lockspire

      pipeline :browser do
        plug(:accepts, ["html"])
      end

      lockspire_routes()
    end
    """

    # Prove the stub host router defines no operator pipeline of its own -- the
    # only pipeline it declares is the standard :browser pipeline every stock
    # `mix phx.new` host already has.
    refute stub_router_source =~ "pipeline :lockspire_require_operator"

    compile!(InstallTemplateCompileWeb.Router.Lockspire, rendered_router_module)
    compile!(InstallTemplateCompileWeb.Router, stub_router_source)

    routes = Phoenix.Router.routes(InstallTemplateCompileWeb.Router)

    admin_index =
      Enum.find_index(routes, fn route ->
        route.verb == :* and route.plug == Lockspire.Web.AdminRouter
      end)

    public_index =
      Enum.find_index(routes, fn route ->
        route.verb == :* and route.plug == Lockspire.Web.Router
      end)

    assert is_integer(admin_index), "expected a forward to Lockspire.Web.AdminRouter"
    assert is_integer(public_index), "expected a forward to Lockspire.Web.Router"

    assert admin_index < public_index,
           "admin forward must be reachable before the public forward can shadow it"

    consent_route =
      Enum.find(routes, fn route ->
        route.path == "/lockspire/consent/:interaction_id"
      end)

    assert %{plug: Phoenix.LiveView.Plug} = consent_route

    assert Enum.any?(routes, fn route ->
             route.verb == :get and route.path == "/verify" and
               route.plug_opts == :show
           end)

    assert Enum.any?(routes, fn route ->
             route.verb == :post and route.path == "/verify" and
               route.plug_opts == :lookup
           end)

    assert Enum.any?(routes, fn route ->
             route.verb == :post and route.path == "/verify/:handle/approve" and
               route.plug_opts == :approve
           end)

    assert Enum.any?(routes, fn route ->
             route.verb == :post and route.path == "/verify/:handle/deny" and
               route.plug_opts == :deny
           end)

    assert Enum.any?(routes, fn route ->
             route.verb == :get and route.path == "/authorized-apps"
           end)

    assert Enum.any?(routes, fn route ->
             route.verb == :delete and route.path == "/authorized-apps/:id"
           end)

    conn =
      :get
      |> conn("/lockspire/admin")
      |> InstallTemplateCompileWeb.Router.call(InstallTemplateCompileWeb.Router.init([]))

    assert conn.halted
    assert conn.status == 403
  end

  test "the rendered router helper's body is paste-safe" do
    rendered_router_module = router_helper_source()

    refute rendered_router_module =~ "unquote("
  end

  test "every generated .heex template compiles under the LiveView tag engine" do
    heex_templates =
      @assigns
      |> Install.rendered_templates()
      |> Enum.filter(&(Path.extname(&1.destination) == ".heex"))

    # A fence that silently iterates over zero templates would pass forever.
    assert heex_templates != [],
           "expected at least one generated .heex template destination to fence"

    # `render_template_content/3` (install.ex:84-94) prepends an ownership
    # header comment before the source template's own content, so a reported
    # parse-error line number is offset from the source template's line
    # number by the header's length. Report the rendered path in any failure
    # message below rather than attempting to subtract the offset.
    for rendered <- heex_templates do
      Phoenix.LiveView.TagEngine.compile(rendered.rendered,
        caller: __ENV__,
        tag_handler: Phoenix.LiveView.HTMLEngine,
        file: rendered.relative_path,
        line: 1
      )
    end
  end

  defp router_helper_source do
    router_template = Enum.find(Templates.all(), &(&1.template == "router.ex"))

    destination =
      Path.join(
        System.tmp_dir!(),
        "install-template-compile-test/lib/install_template_compile_web/router/lockspire.ex"
      )

    Install.render_template_content(router_template, @assigns, destination)
  end

  defp compile!(module, source) do
    :code.purge(module)
    :code.delete(module)

    compiled = Code.compile_string(source, "#{module}.ex")

    assert Enum.any?(compiled, fn {compiled_module, _binary} -> compiled_module == module end),
           "expected #{inspect(module)} among the modules compiled from #{inspect(source)}"
  end
end
