defmodule Mix.Tasks.Lockspire.Keys.Reencrypt do
  @moduledoc """
  Re-encrypts stored signing keys under the current key-encryption key.

  Run `mix lockspire.keys.reencrypt --check` to see whether every stored key is ready.
  """

  use Mix.Task

  alias Lockspire.Admin.Keys

  @shortdoc "Re-encrypts stored signing keys under the current key-encryption key"
  @requirements ["app.config"]

  @actor %{type: :operator, id: "mix lockspire.keys.reencrypt"}

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args, strict: [dry_run: :boolean, check: :boolean, help: :boolean])

    mode = if Keyword.get(opts, :check, false), do: :check, else: :apply

    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    result =
      case Ecto.Migrator.with_repo(
             Lockspire.Config.repo!(),
             fn _repo -> work(mode) end,
             mode: :temporary
           ) do
        {:ok, result, _apps} -> result
        {:error, _reason} -> Mix.raise(repo_failure())
      end

    finish(result)
  end

  defp work(:apply), do: {:apply, Keys.reencrypt(actor: @actor)}
  defp work(:check), do: {:check, Keys.encryption_status()}

  defp finish({:apply, {:ok, report}}) do
    Mix.shell().info(
      "scanned=#{report.scanned} encrypted=#{report.encrypted} rewrapped=#{report.rewrapped} " <>
        "already_current=#{report.already_current} failed=#{length(report.failed)} " <>
        "no_private_key=#{report.no_private_key} conflicted=#{report.conflicted}"
    )

    if report.failed != [] or report.conflicted > 0 do
      Mix.raise("Some keys were not re-encrypted. All other keys were saved; rerunning is safe.")
    end
  end

  defp finish({:check, {:ok, status}}) do
    Mix.shell().info("ready=#{status.ready?}")

    unless status.ready? do
      Mix.raise("Not ready: #{length(status.pending)} signing keys still need re-encryption.")
    end
  end

  defp finish({_mode, {:error, _reason}}), do: Mix.raise(repo_failure())

  defp repo_failure, do: "could not start the repo; check database connectivity and config"
end
