defmodule Lockspire.Generators.Install do
  @moduledoc """
  Generates editable Lockspire host integration files inside a Phoenix app.
  """

  alias Lockspire.Generators.Templates
  alias Lockspire.Install.Manifest

  @template_root Application.app_dir(:lockspire, "priv/templates/lockspire.install")

  @spec run(keyword()) :: :ok
  def run(opts \\ []) do
    assigns = build_assigns(opts)
    install_plan = plan(assigns)

    apply_plan!(assigns, install_plan)
    Mix.shell().info(instructions(assigns))

    :ok
  end

  @doc """
  Side-effect-free classification pass. Reads every rendered template's
  destination and the install manifest (if any), but never writes, creates a
  directory, or removes a file. Returns the full per-destination
  classification plus the subset that conflict, in template-inventory order.
  """
  @spec plan(map()) :: map()
  def plan(assigns) do
    rendered_templates = rendered_templates(assigns)
    manifest_checksums = load_manifest_checksums(assigns.project_root)
    expanded_root = Path.expand(assigns.project_root)

    {classified, conflicts} =
      Enum.reduce(rendered_templates, {[], []}, fn rendered, {classified, conflicts} ->
        case classify_destination(rendered, manifest_checksums, expanded_root) do
          {:conflict, reason} = outcome ->
            {[{rendered, outcome} | classified], [{rendered, reason} | conflicts]}

          outcome ->
            {[{rendered, outcome} | classified], conflicts}
        end
      end)

    %{
      rendered_templates: rendered_templates,
      classified: Enum.reverse(classified),
      conflicts: Enum.reverse(conflicts)
    }
  end

  @doc """
  Apply pass. Only reached when the plan produced zero conflicts -- if any
  conflict is present, prints the full refusal list and raises exactly once,
  having written nothing. Otherwise creates directories, writes files that
  need creating, and writes the manifest.
  """
  @spec apply_plan!(map(), map()) :: :ok
  def apply_plan!(assigns, %{classified: classified, conflicts: conflicts} = install_plan) do
    if conflicts != [] do
      print_refusals(conflicts)

      Mix.raise(
        "Lockspire install refused: #{length(conflicts)} destination(s) conflict. " <>
          "Fix each listed file, then rerun `mix lockspire.install`."
      )
    end

    Enum.each(classified, fn
      {rendered, :create} ->
        File.mkdir_p!(Path.dirname(rendered.destination))
        File.write!(rendered.destination, rendered.rendered)
        Mix.shell().info("* created #{Path.relative_to_cwd(rendered.destination)}")

      {rendered, :unchanged} ->
        Mix.shell().info("* unchanged #{Path.relative_to_cwd(rendered.destination)}")
    end)

    write_manifest!(assigns, install_plan.rendered_templates)

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
      sigra_host: Keyword.get(opts, :sigra_host, false)
    }
  end

  @spec rendered_templates(map()) :: [map()]
  def rendered_templates(assigns) do
    Enum.map(Templates.all(), fn template ->
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
      @template_root
      |> Path.join(template.template)
      |> EEx.eval_file(assigns: assigns)

    ownership_header(template, destination) <> rendered_body
  end

  defp write_manifest!(assigns, rendered_templates) do
    managed_templates =
      rendered_templates
      |> Enum.filter(&(&1.template.ownership == :managed))

    assigns
    |> Manifest.build(managed_templates)
    |> then(&Manifest.write(assigns.project_root, &1))
  end

  # Classifies one rendered destination against the current host state. This
  # is a read-only decision: :unchanged, :create, or {:conflict, reason}.
  # Never writes -- called only from plan/1.
  defp classify_destination(rendered, manifest_checksums, expanded_root) do
    if contained_in_root?(rendered.destination, expanded_root) do
      case File.read(rendered.destination) do
        {:ok, contents} when contents == rendered.rendered ->
          :unchanged

        {:ok, contents} ->
          {:conflict, conflict_reason(rendered, contents, manifest_checksums)}

        {:error, :enoent} ->
          :create

        {:error, reason} ->
          {:conflict, "could not read file: #{inspect(reason)}"}
      end
    else
      {:conflict, "destination escapes the project root: #{rendered.destination}"}
    end
  end

  defp contained_in_root?(destination, expanded_root) do
    destination == expanded_root or String.starts_with?(destination, expanded_root <> "/")
  end

  # Three-way comparison, copied from `lockspire.upgrade`'s drift check: the
  # manifest's recorded checksum distinguishes a host edit (current content
  # never matched what Lockspire generated) from a Lockspire template change
  # (current content still matches the recorded checksum, but the freshly
  # rendered content differs -- the template itself moved on). A destination
  # with no recorded checksum (unmanaged, or no manifest exists yet) falls
  # back to reporting a host edit, since there is nothing to compare against.
  defp conflict_reason(rendered, contents, manifest_checksums) do
    case Map.fetch(manifest_checksums, rendered.relative_path) do
      {:ok, expected_checksum} ->
        if Manifest.checksum(contents) == expected_checksum do
          "Lockspire template changed"
        else
          "host edit detected"
        end

      :error ->
        "host edit detected"
    end
  end

  defp load_manifest_checksums(project_root) do
    case Manifest.load(project_root) do
      {:ok, manifest} ->
        manifest
        |> Map.get("managed_files")
        |> List.wrap()
        |> Map.new(fn entry -> {entry["path"], entry["checksum"]} end)

      {:error, _reason} ->
        %{}
    end
  end

  defp print_refusals(conflicts) do
    Enum.each(conflicts, fn {rendered, reason} ->
      Mix.shell().info("REFUSE #{rendered.relative_path} (#{reason})")
      Mix.shell().info("  fix: #{refusal_fix_line(reason)}")
    end)
  end

  defp refusal_fix_line("Lockspire template changed") do
    "run `mix lockspire.upgrade` to update this Lockspire-managed file."
  end

  defp refusal_fix_line("destination escapes the project root" <> _rest) do
    "check the --path/--web/--scope values that produced this destination."
  end

  defp refusal_fix_line(_host_edit_or_read_error) do
    "reconcile this file manually, then rerun `mix lockspire.install`."
  end

  defp instructions(assigns) do
    migrations_path = Application.app_dir(:lockspire, "priv/repo/migrations")

    """

    Lockspire canonical onboarding next steps:
      1. Import `config/lockspire.exs` from your main config files.
      2. Import `#{assigns.web_module}.Router.Lockspire` in `lib/#{assigns.web_path}/router.ex`.
      3. Call `lockspire_routes()` where your host wants the authorized-apps surface.
      4. Implement `#{assigns.resolver_module}` with real account lookup and claims.
      5. Point your login flow back through `#{assigns.interaction_handler_module}`.
      6. Review `docs/device-flow-host-guide.md` before shipping the generated `/verify` seam. Wire host auth/session behavior, keep GET prefill-only, and add rate limiting for both GET and POST.
      7. Wire your app tree yourself -- Lockspire does not modify your `mix.exs` or `application.ex`. Add `included_applications: [:lockspire]` to your `application/0` in `mix.exs`, and add `:oban` and `:cachex` to `extra_applications` in that same `application/0` (required alongside `included_applications`, because `Application.ensure_all_started/1` never walks an included application's own dependency chain and would otherwise leave Oban's registry unstarted). Then add Lockspire's three supervision children to your `Application.start/2` child list, ordered after your own Repo: the Oban child built from `Lockspire.Oban.runtime_config!/0`, the Cachex child named `:lockspire_jwks_cache`, and `Lockspire.KeyCache`.
      8. Generate, publish, and activate a signing key, in that order: `Lockspire.Admin.generate_key/1`, then `Lockspire.Admin.publish_key/2`, then `Lockspire.Admin.activate_key/2`. These are three separate stages -- generation alone leaves JWKS empty, publication makes the key visible in JWKS but still unable to sign, and only activation makes a published key eligible to sign tokens.
      9. Run `mix ecto.migrate --migrations-path #{migrations_path}`, create a client, and verify discovery, JWKS, and an auth-code + PKCE flow. A bare migrate command runs none of Lockspire's migrations -- they live under the `:lockspire` dependency's own `priv/repo/migrations`.
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
