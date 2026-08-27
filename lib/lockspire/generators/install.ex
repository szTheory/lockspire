defmodule Lockspire.Generators.Install do
  @moduledoc """
  Generates editable Lockspire host integration files inside a Phoenix app.
  """

  alias Lockspire.Generators.Templates
  alias Lockspire.Install.Assets
  alias Lockspire.Install.OperationPlan

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    assigns = build_assigns(opts)
    rendered_templates = rendered_templates(assigns)

    plan = build_plan!(assigns, rendered_templates)
    OperationPlan.report(plan, :apply)
    apply_plan!(plan)
    Mix.shell().info(instructions(assigns))

    :ok
  end

  @spec build_assigns(keyword()) :: map()
  def build_assigns(opts) do
    root_module =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()
      |> Macro.camelize()

    web_module = Keyword.get(opts, :web, "#{root_module}Web")
    scope_module = Keyword.get(opts, :scope, "#{root_module}.Lockspire")
    mount_path = Keyword.get(opts, :mount_path, "/lockspire")
    storage_prefix = Keyword.get(opts, :storage_prefix, "lockspire")
    oban_prefix = Keyword.get(opts, :oban_prefix, storage_prefix)

    %{
      project_root: Keyword.get(opts, :path, File.cwd!()),
      app_module: root_module,
      app_path: Macro.underscore(root_module),
      web_module: web_module,
      web_path: Macro.underscore(web_module),
      scope_module: scope_module,
      scope_path: Macro.underscore(scope_module),
      mount_path: mount_path,
      storage_prefix: Lockspire.Storage.Ecto.Prefix.normalize(storage_prefix),
      oban_prefix: Lockspire.Storage.Ecto.Prefix.normalize(oban_prefix),
      router_module: "#{web_module}.Router",
      resolver_module: "#{scope_module}.AccountResolver",
      interaction_handler_module: "#{scope_module}.InteractionHandler",
      consent_live_module: "#{web_module}.LockspireConsentLive",
      authorized_apps_controller_module: "#{web_module}.AuthorizedAppsController",
      authorized_apps_html_module: "#{web_module}.AuthorizedAppsHTML",
      verification_controller_module: "#{web_module}.LockspireVerificationController",
      verification_html_module: "#{web_module}.LockspireVerificationHTML",
      sigra_host: Keyword.get(opts, :sigra_host, false),
      with_fapi_smoke: Keyword.get(opts, :with_fapi_smoke, false)
    }
  end

  @spec rendered_templates(map()) :: [map()]
  def rendered_templates(assigns) do
    Enum.map(Templates.all(assigns), fn template ->
      destination = destination_path(template, assigns)

      %{
        template: template,
        destination: destination,
        relative_path: template.output.(assigns),
        rendered: render_template_content(template, assigns, destination)
      }
    end)
  end

  @spec destination_path(map(), map()) :: String.t()
  def destination_path(%{output: output_fun}, assigns) do
    assigns.project_root
    |> Path.join(output_fun.(assigns))
    |> Path.expand()
  end

  @spec render_template_content(map(), map(), String.t() | nil) :: String.t()
  def render_template_content(template, assigns, destination \\ nil) do
    destination = destination || destination_path(template, assigns)

    rendered_body =
      Assets.path("priv/templates/lockspire.install")
      |> Path.join(template.template)
      |> EEx.eval_file(assigns: assigns)

    ownership_header(template, destination) <> rendered_body
  end

  defp build_plan!(assigns, rendered_templates) do
    case OperationPlan.install(assigns, rendered_templates) do
      {:ok, plan} -> plan
      {:error, errors} -> refuse!("install", errors)
    end
  end

  defp apply_plan!(plan) do
    case OperationPlan.apply(plan) do
      {:ok, _plan} -> :ok
      {:error, errors} -> refuse!("install", errors)
    end
  end

  defp refuse!(operation, errors) do
    Enum.each(errors, fn error ->
      Mix.shell().info("REFUSE #{error.message}")

      Mix.shell().info(
        "  fix: reconcile the host file manually, then rerun `mix lockspire.#{operation}`."
      )
    end)

    Mix.raise(
      "Lockspire #{operation} refused because planned host changes are unsafe: " <>
        Enum.map_join(errors, "; ", & &1.message)
    )
  end

  defp instructions(assigns) do
    """

    Lockspire canonical onboarding next steps:
      1. Import `config/lockspire.exs` from your main config files.
      2. Import `#{assigns.web_module}.Router.Lockspire` in `lib/#{assigns.web_path}/router.ex`.
      3. Call `lockspire_routes()` where your host wants the authorized-apps surface.
      4. Implement `#{assigns.resolver_module}` with real account lookup and claims.
      5. Point your login flow back through `#{assigns.interaction_handler_module}`.
      6. Review `docs/device-flow-host-guide.md` before shipping the generated `/verify` seam. Wire host auth/session behavior, keep GET prefill-only, and add rate limiting for both GET and POST.
      7. Run `mix ecto.migrate`, create a client, and run `mix test test/#{assigns.app_path}/lockspire_smoke_e2e_test.exs` to verify discovery, JWKS, and an auth-code + PKCE flow.
      8. If you explicitly operate a FAPI 2.0 security profile, generate its isolated proof with `mix lockspire.install --with-fapi-smoke`, then run `mix test test/#{assigns.app_path}/lockspire_fapi_smoke_e2e.exs --include fapi`.
    """
  end

  defp ownership_header(%{ownership: :managed}, destination) do
    ownership_comment(
      destination,
      "Lockspire-managed scaffolding",
      [
        "Safe to update later only through `mix lockspire.upgrade` when the manifest says this file is unchanged.",
        "Keep this file unchanged if you want future managed upgrades to apply automatically."
      ]
    )
  end

  defp ownership_header(%{ownership: :host_owned}, destination) do
    ownership_comment(
      destination,
      "Host-owned Lockspire seam",
      [
        "Lockspire generates this file once, but your app owns the ongoing logic, UX, claims, and policy here.",
        "If you customize this file, keep those edits and reconcile future changes manually."
      ]
    )
  end

  defp ownership_comment(destination, title, lines) do
    if Path.extname(destination) == ".heex" do
      [
        "<%!-- #{title} --%>",
        Enum.map(lines, &"<%!-- #{&1} --%>"),
        ""
      ]
      |> List.flatten()
      |> Enum.join("\n")
      |> Kernel.<>("\n")
    else
      [
        "# #{title}",
        Enum.map(lines, &"# #{&1}"),
        ""
      ]
      |> List.flatten()
      |> Enum.join("\n")
      |> Kernel.<>("\n")
    end
  end
end
