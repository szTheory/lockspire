defmodule Mix.Tasks.Lockspire.Install do
  @moduledoc """
  Generate host-owned Lockspire integration files for a Phoenix application.
  """

  @shortdoc "Generates host-owned Lockspire integration files"

  use Mix.Task

  @requirements ["app.config"]

  alias Lockspire.Generators.Install

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [
          web: :string,
          scope: :string,
          path: :string,
          help: :boolean,
          sigra_host: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      Install.run(opts)
    end
  end

  def help do
    """
    mix lockspire.install [--web MyAppWeb] [--scope MyApp.Lockspire] [--path PATH] [--sigra-host]

    Canonical Phoenix-first onboarding:
      1. Add the :lockspire dependency
      2. Run mix lockspire.install
      3. Review the host-owned files and wire them into your router/config
      4. Run migrations, register a client, and complete an auth-code + PKCE flow

    Generates editable host-owned Lockspire integration files:
      * config/lockspire.exs
      * lib/<web>/router/lockspire.ex
      * lib/<scope>/account_resolver.ex
      * lib/<scope>/interaction_handler.ex
      * lib/<web>/live/lockspire_consent_live.ex
      * lib/<web>/controllers/authorized_apps_controller.ex
      * lib/<web>/controllers/authorized_apps_html.ex
      * lib/<web>/controllers/authorized_apps_html/index.html.heex

    When --sigra-host is passed, the AccountResolver stub includes Sigra-oriented
    moduledoc/comments (still host-owned; see Sigra companion recipe on hexdocs).
    """
  end
end
