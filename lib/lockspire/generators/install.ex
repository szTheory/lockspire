defmodule Lockspire.Generators.Install do
  @moduledoc """
  Generates editable Lockspire host integration files inside a Phoenix app.
  """

  alias Lockspire.Generators.Templates

  @template_root Application.app_dir(:lockspire, "priv/templates/lockspire.install")

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    assigns = build_assigns(opts)

    Enum.each(Templates.all(), fn template ->
      render_template(template, assigns)
    end)

    :ok
  end

  defp render_template(%{template: template_name, output: output_fun}, assigns) do
    destination =
      assigns.project_root
      |> Path.join(output_fun.(assigns))
      |> Path.expand()

    rendered =
      @template_root
      |> Path.join(template_name)
      |> EEx.eval_file(assigns: assigns)

    ensure_file!(destination, rendered)
  end

  defp ensure_file!(destination, rendered) do
    File.mkdir_p!(Path.dirname(destination))

    case File.read(destination) do
      {:ok, ^rendered} ->
        Mix.shell().info("* unchanged #{Path.relative_to_cwd(destination)}")

      {:ok, _existing} ->
        Mix.raise("""
        Refusing to overwrite modified file: #{Path.relative_to_cwd(destination)}

        Keep the host-owned edits and reconcile this file manually before rerunning
        `mix lockspire.install`.
        """)

      {:error, :enoent} ->
        File.write!(destination, rendered)
        Mix.shell().info("* created #{Path.relative_to_cwd(destination)}")

      {:error, reason} ->
        Mix.raise("Could not read #{Path.relative_to_cwd(destination)}: #{inspect(reason)}")
    end
  end

  defp build_assigns(opts) do
    root_module =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()
      |> Macro.camelize()

    web_module = Keyword.get(opts, :web, "#{root_module}Web")
    scope_module = Keyword.get(opts, :scope, "#{root_module}.Lockspire")
    mount_path = Lockspire.mount_path()

    %{
      project_root: Keyword.get(opts, :path, File.cwd!()),
      app_module: root_module,
      app_path: Macro.underscore(root_module),
      web_module: web_module,
      web_path: Macro.underscore(web_module),
      scope_module: scope_module,
      scope_path: Macro.underscore(scope_module),
      mount_path: mount_path,
      router_module: "#{web_module}.Router",
      resolver_module: "#{scope_module}.AccountResolver",
      interaction_handler_module: "#{scope_module}.InteractionHandler",
      consent_live_module: "#{web_module}.LockspireConsentLive",
      authorized_apps_controller_module: "#{web_module}.AuthorizedAppsController",
      authorized_apps_html_module: "#{web_module}.AuthorizedAppsHTML",
      sigra_host: Keyword.get(opts, :sigra_host, false)
    }
  end
end
