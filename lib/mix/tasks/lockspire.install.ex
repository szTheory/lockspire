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
    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [
          web: :string,
          scope: :string,
          path: :string,
          mount_path: :string,
          storage_prefix: :string,
          oban_prefix: :string,
          help: :boolean,
          sigra_host: :boolean,
          with_fapi_smoke: :boolean
        ]
      )

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if argv != [] do
      Mix.raise("Unknown arguments: #{Enum.join(argv, ", ")}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      Install.run(opts)
    end
  end

  def help do
    """
    mix lockspire.install [--web MyAppWeb] [--scope MyApp.Lockspire] [--path PATH] [--mount-path /lockspire] [--storage-prefix lockspire] [--oban-prefix lockspire] [--sigra-host] [--with-fapi-smoke]

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
      * test/<app>/lockspire_smoke_e2e_test.exs

    When --sigra-host is passed, the AccountResolver stub includes Sigra-oriented
    moduledoc/comments (still host-owned; see Sigra companion recipe on hexdocs).

    Options:
      --mount-path PATH   Embedded Lockspire mount path to generate into router/config
                          (default: /lockspire)
      --storage-prefix PREFIX
                          Postgres schema/prefix for Lockspire-owned tables.
                          New installs default to lockspire. Use public only when
                          you explicitly want Lockspire tables in the default schema.
      --oban-prefix PREFIX
                          Postgres schema/prefix for Lockspire's Oban tables.
                          Defaults to --storage-prefix.
      --with-fapi-smoke  Also generate the isolated FAPI 2.0 proof. This is not
                          emitted by default and must be run explicitly with:
                          mix test test/<app>/lockspire_fapi_smoke_e2e.exs --include fapi
    """
  end
end
