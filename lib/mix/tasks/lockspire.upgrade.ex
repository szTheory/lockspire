defmodule Mix.Tasks.Lockspire.Upgrade do
  @moduledoc """
  Upgrade manifest-tracked Lockspire-managed scaffolding only when it is still unchanged.
  """

  @shortdoc "Upgrades Lockspire-managed generated scaffolding"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.Generators.Install
  alias Lockspire.Install.Manifest

  @switches [
    web: :string,
    scope: :string,
    path: :string,
    mount_path: :string,
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
    mix lockspire.upgrade [--web MyAppWeb] [--scope MyApp.Lockspire] [--path PATH] [--mount-path /lockspire] [--dry-run]

    Upgrades only manifest-tracked Lockspire-managed scaffolding.
    Host-owned seams stay untouched and drifted managed files are refused with manual guidance.
    """
  end

  defp do_run(opts) do
    assigns = Install.build_assigns(opts)
    dry_run? = Keyword.get(opts, :dry_run, false)

    manifest =
      case Manifest.load(assigns.project_root) do
        {:ok, manifest} -> manifest
        {:error, :enoent} -> Mix.raise("Missing install manifest. Run `mix lockspire.install` first.")
        {:error, reason} -> Mix.raise("Could not load install manifest: #{inspect(reason)}")
      end

    rendered_by_path =
      assigns
      |> Install.rendered_templates()
      |> Enum.filter(&(&1.template.ownership == :managed))
      |> Map.new(&{&1.relative_path, &1})

    {updates, drifts} =
      manifest["managed_files"]
      |> List.wrap()
      |> Enum.reduce({[], []}, fn entry, {updates, drifts} ->
        path = entry["path"]
        expected_checksum = entry["checksum"]
        rendered = Map.fetch!(rendered_by_path, path)

        case File.read(rendered.destination) do
          {:ok, contents} ->
            current_checksum = Manifest.checksum(contents)
            next_checksum = Manifest.checksum(rendered.rendered)

            cond do
              current_checksum != expected_checksum ->
                {updates, [{path, "checksum drift detected"} | drifts]}

              current_checksum == next_checksum ->
                {updates, drifts}

              true ->
                {[rendered | updates], drifts}
            end

          {:error, :enoent} ->
            {updates, [{path, "managed file is missing"} | drifts]}

          {:error, reason} ->
            {updates, [{path, inspect(reason)} | drifts]}
        end
      end)

    if drifts != [] do
      Enum.each(Enum.reverse(drifts), fn {path, reason} ->
        Mix.shell().info("REFUSE #{path} (#{reason})")
        Mix.shell().info("  fix: reconcile the managed file manually, then rerun `mix lockspire.upgrade`.")
      end)

      Mix.raise("Lockspire upgrade refused because managed scaffolding drifted.")
    end

    if updates == [] do
      Mix.shell().info("No managed scaffolding updates were needed.")
      :ok
    else
      Enum.each(Enum.reverse(updates), fn rendered ->
        Mix.shell().info("#{if(dry_run?, do: "DRY-RUN", else: "UPDATE")} #{rendered.relative_path}")

        unless dry_run? do
          File.write!(rendered.destination, rendered.rendered)
        end
      end)

      unless dry_run? do
        assigns
        |> Manifest.build(Map.values(rendered_by_path))
        |> then(&Manifest.write(assigns.project_root, &1))
      end

      :ok
    end
  end
end
