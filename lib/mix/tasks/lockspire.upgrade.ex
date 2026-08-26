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
    mix lockspire.upgrade [--web MyAppWeb] [--scope MyApp.Lockspire] [--path PATH] [--mount-path /lockspire] [--storage-prefix lockspire] [--oban-prefix lockspire] [--dry-run]

    Upgrades only manifest-tracked Lockspire-managed scaffolding.
    Host-owned seams stay untouched and drifted managed files are refused with manual guidance.
    Pass --storage-prefix public --oban-prefix public only for an intentional public-schema install.
    """
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp do_run(opts) do
    assigns = Install.build_assigns(opts)
    dry_run? = Keyword.get(opts, :dry_run, false)

    manifest =
      case Manifest.load(assigns.project_root) do
        {:ok, manifest} ->
          manifest

        {:error, :enoent} ->
          Mix.raise("Missing install manifest. Run `mix lockspire.install` first.")

        {:error, reason} ->
          Mix.raise("Could not load install manifest: #{inspect(reason)}")
      end

    rendered_templates = Install.rendered_templates(assigns)

    case OperationPlan.upgrade(assigns, rendered_templates, manifest) do
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

  defp apply_plan!(plan) do
    case OperationPlan.apply(plan) do
      {:ok, _plan} -> :ok
      {:error, errors} -> refuse!(errors)
    end
  end

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
