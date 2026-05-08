defmodule Mix.Tasks.Lockspire.Verify do
  @moduledoc """
  Verify the canonical Lockspire host install wiring after generation and host edits.
  """

  @shortdoc "Verifies Lockspire host wiring, config, seams, and migrations"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.Install.Verify

  @switches [
    web: :string,
    scope: :string,
    mount_path: :string,
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
      opts
      |> build_verify_opts()
      |> Verify.run()
      |> print_result()
    end
  end

  def help do
    """
    mix lockspire.verify [--web MyAppWeb] [--scope MyApp.Lockspire] [--mount-path /lockspire]

    Canonical post-install verification:
      1. Confirm required :lockspire runtime config is present and valid
      2. Confirm the host seam modules compile
      3. Confirm the host router mounts Lockspire and exposes /verify routes
      4. Confirm Lockspire and Oban migrations are applied
    """
  end

  defp build_verify_opts(opts) do
    root_module =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()
      |> Macro.camelize()

    web_module = Keyword.get(opts, :web, "#{root_module}Web")
    scope_module = Keyword.get(opts, :scope, "#{root_module}.Lockspire")

    [
      router: Module.concat([web_module, "Router"]),
      resolver_module: Module.concat([scope_module, "AccountResolver"]),
      interaction_handler_module: Module.concat([scope_module, "InteractionHandler"]),
      mount_path: Keyword.get(opts, :mount_path, Lockspire.Config.mount_path())
    ]
  end

  defp print_result(%{ok?: ok?, checks: checks}) do
    Enum.each(checks, fn check ->
      Mix.shell().info("#{label(check.status)} #{check.summary}")
      Mix.shell().info("  #{check.details}")

      if check.status == :error do
        Mix.shell().info("  fix: #{check.fix}")
      end
    end)

    if ok? do
      Mix.shell().info("Lockspire verification passed.")
    else
      Mix.raise("Lockspire verification failed.")
    end
  end

  defp label(:ok), do: "OK"
  defp label(:error), do: "ERROR"
end
