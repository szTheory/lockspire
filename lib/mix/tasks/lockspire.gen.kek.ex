defmodule Mix.Tasks.Lockspire.Gen.Kek do
  @moduledoc """
  Prints a new key-encryption key and the `config/runtime.exs` block that reads it.

  The key encrypts Lockspire signing keys at rest. This task writes no files, needs no
  database and does not load your app config, so it works before the key exists. The key is
  printed once; store it in your secret manager as `LOCKSPIRE_KEY_ENCRYPTION_KEY`.

  ## Options

    * `--id ID` - the key id used in the config block (default: the current month in UTC, as
      `YYYY-MM`).
    * `--raw` - print only the key, on one line. The key id is not part of that output, so
      `--id` has no effect with `--raw` (an invalid id is still rejected).
    * `--help` - show usage.
  """

  use Mix.Task

  alias Lockspire.Generators.KekSnippet
  alias Lockspire.Security.KeyEncryption.KeySet

  @shortdoc "Prints a new key-encryption key and the config/runtime.exs block that reads it"

  @switches [id: :string, raw: :boolean, help: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate!(opts, argv, invalid)

    cond do
      Keyword.get(opts, :help, false) -> Mix.shell().info(help())
      Keyword.get(opts, :raw, false) -> Mix.shell().info(KekSnippet.generate_key())
      true -> print_default(opts[:id] || KekSnippet.default_id())
    end
  end

  def help do
    """
    mix lockspire.gen.kek [--id ID] [--raw]

    Prints a new key-encryption key, which encrypts Lockspire signing keys at rest, and the
    config/runtime.exs block that reads it from the LOCKSPIRE_KEY_ENCRYPTION_KEY variable.

    Options:
      --id ID   Key id used in the config block. Default: the current month in UTC, as
                YYYY-MM. Use 1-32 characters from A-Z, a-z, 0-9, dot, underscore or dash.
      --raw     Print only the key, on one line, for piping into a secret manager. --id has no
                effect with --raw.
      --help    Show this text.

    This task writes no files and needs no database. The key is shown only once, so store it
    in your secret manager before you close the terminal.

    The config entry may also be written as {"<id>", {:system, "LOCKSPIRE_KEY_ENCRYPTION_KEY"}}
    to read the variable at boot.
    """
  end

  defp validate!(opts, argv, invalid) do
    cond do
      invalid != [] ->
        Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")

      argv != [] ->
        Mix.raise(
          "Unexpected argument: #{Enum.join(argv, " ")}. " <>
            "Options start with dashes, for example --#{List.first(argv)}."
        )

      Keyword.has_key?(opts, :id) and not KeySet.valid_id?(opts[:id]) ->
        Mix.raise("--id must be 1-32 characters from A-Z, a-z, 0-9, dot, underscore or dash")

      true ->
        :ok
    end
  end

  defp print_default(id) do
    value = KekSnippet.generate_key()

    Mix.shell().info(
      "Generated a new key-encryption key. Store it in your secret manager; it is shown only once:"
    )

    Mix.shell().info("")
    Mix.shell().info("#{KekSnippet.env_var()}=#{value}")
    Mix.shell().info("")

    Mix.shell().info(
      "Add this block to config/runtime.exs. Production refuses to boot when the variable is missing:"
    )

    Mix.shell().info(String.trim_trailing(KekSnippet.prod_block(id, 2)))

    Mix.shell().info(
      "For dev and test, keep the throwaway key that mix lockspire.install printed for " <>
        "config/dev.exs and config/test.exs; never put this key there."
    )
  end
end
