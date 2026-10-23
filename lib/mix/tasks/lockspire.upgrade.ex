defmodule Mix.Tasks.Lockspire.Upgrade do
  @moduledoc """
  Upgrade manifest-tracked Lockspire-managed scaffolding only when it is still unchanged.
  """

  @shortdoc "Upgrades Lockspire-managed generated scaffolding"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.Generators.Install
  alias Lockspire.Install.Manifest
  alias Lockspire.Install.OperationPlan

  @switches [
    web: :string,
    scope: :string,
    path: :string,
    mount_path: :string,
    storage_prefix: :string,
    oban_prefix: :string,
    with_fapi_smoke: :boolean,
    dry_run: :boolean,
    help: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      do_run(opts)
    end
  end

  def help do
    """
    mix lockspire.upgrade [--web MyAppWeb] [--scope MyApp.Lockspire] [--path PATH] [--mount-path /lockspire] [--storage-prefix lockspire] [--oban-prefix lockspire] [--with-fapi-smoke] [--dry-run]

    Upgrades only manifest-tracked Lockspire-managed scaffolding.
    Host-owned seams stay untouched, except the absent default-deny operator authorization seam
    is created once. That new host-owned seam must be implemented with current host policy before
    admin access resumes. Dry-run is read-only; if recovery is needed, rerun without --dry-run.
    Drifted managed files are refused with manual guidance.
    Pass --storage-prefix public --oban-prefix public only for an intentional public-schema install.
    An existing install manifest retains its opted-in FAPI smoke by default; use
    --with-fapi-smoke to add it to a legacy install explicitly.
    """
  end

  # Upgrade ordering preserves managed-file refusal before any host-owned mutation can run.
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp do_run(opts) do
    base_assigns = Install.build_assigns(opts)
    dry_run? = Keyword.get(opts, :dry_run, false)

    manifest =
      case Manifest.load(base_assigns.project_root) do
        {:ok, manifest} ->
          manifest

        {:error, :enoent} ->
          Mix.raise("Missing install manifest. Run `mix lockspire.install` first.")

        {:error, reason} ->
          Mix.raise("Could not load install manifest: #{inspect(reason)}")
      end

    assigns =
      opts
      |> Keyword.put(:with_fapi_smoke, fapi_smoke?(opts, manifest))
      |> Install.build_assigns()
      |> preserve_manifest_inputs(opts, manifest)

    rendered_templates = Install.rendered_templates(assigns)

    case OperationPlan.upgrade(assigns, rendered_templates, manifest, dry_run: dry_run?) do
      {:ok, plan} ->
        OperationPlan.report(plan, if(dry_run?, do: :dry_run, else: :apply))

        if dry_run? do
          :ok
        else
          apply_plan!(plan)
        end

      {:error, errors} ->
        refuse!(errors)
    end
  end

  defp preserve_manifest_inputs(assigns, opts, manifest) do
    inputs = Map.get(manifest, "inputs", %{})

    [
      {:web, :web_module, "web_module"},
      {:scope, :scope_module, "scope_module"},
      {:mount_path, :mount_path, "mount_path"},
      {:storage_prefix, :storage_prefix, "storage_prefix"},
      {:oban_prefix, :oban_prefix, "oban_prefix"}
    ]
    |> Enum.reduce(assigns, fn {option, assign, input}, current ->
      if Keyword.has_key?(opts, option) do
        current
      else
        case Map.fetch(inputs, input) do
          {:ok, value} when is_binary(value) -> Map.put(current, assign, value)
          _ -> current
        end
      end
    end)
  end

  defp fapi_smoke?(opts, manifest) do
    Keyword.get(opts, :with_fapi_smoke, get_in(manifest, ["inputs", "with_fapi_smoke"]) == true)
  end

  defp apply_plan!(plan) do
    case OperationPlan.apply(plan) do
      {:ok, _plan} -> :ok
      {:error, errors} -> refuse!(errors)
    end
  end

  @spec refuse!([map()]) :: no_return()
  defp refuse!(errors) do
    Enum.each(errors, fn error ->
      Mix.shell().info("REFUSE #{error.message}")

      Mix.shell().info(
        "  fix: reconcile the managed file manually, then rerun `mix lockspire.upgrade`."
      )
    end)

    Mix.raise("Lockspire upgrade refused because managed scaffolding drifted.")
  end
end
