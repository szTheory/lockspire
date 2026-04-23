defmodule Mix.Tasks.Lockspire.Install do
  @shortdoc "Generates host-owned Lockspire integration files"

  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [web: :string, scope: :string, path: :string, help: :boolean, sigra_host: :boolean]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      Lockspire.Generators.Install.run(opts)
    end
  end

  def help do
    """
    mix lockspire.install [--web MyAppWeb] [--scope MyApp.Lockspire] [--sigra-host]

    Generates editable host-owned Lockspire integration files:
      * router mount snippet
      * Lockspire config scaffold
      * AccountResolver behaviour stub
      * interaction handoff module
      * consent LiveView shell

    When --sigra-host is passed, the AccountResolver stub includes Sigra-oriented
    moduledoc/comments (still host-owned; see Sigra companion recipe on hexdocs).
    """
  end
end
