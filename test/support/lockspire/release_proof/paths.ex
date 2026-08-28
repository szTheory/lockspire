defmodule Lockspire.TestSupport.ReleaseProof.Paths do
  @moduledoc false

  @repo_root Path.expand("../../../..", __DIR__)

  def read!(relative_path), do: relative_path |> path() |> File.read!()
  def path(relative_path), do: Path.join(@repo_root, relative_path)

  def mix_version do
    read!("mix.exs")
    |> then(&Regex.run(~r/version:\s+"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end

  def manifest_version do
    read!(".release-please-manifest.json")
    |> then(&Regex.run(~r/"\."\s*:\s*"([0-9]+\.[0-9]+\.[0-9]+)"/, &1, capture: :all_but_first))
    |> List.first()
  end

  def newest_changelog_version do
    read!("CHANGELOG.md")
    |> then(&Regex.scan(~r/^## \[([0-9]+\.[0-9]+\.[0-9]+)\]/m, &1, capture: :all_but_first))
    |> List.first()
    |> List.first()
  end

  def workflow_job(workflow, name, next_name) do
    read!(workflow)
    |> then(
      &Regex.run(
        ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
        &1,
        capture: :all_but_first
      )
    )
    |> List.first()
  end

  def final_workflow_job(workflow, name) do
    read!(workflow)
    |> then(&Regex.run(~r/^  #{Regex.escape(name)}:\n(.*)\z/ms, &1, capture: :all_but_first))
    |> List.first()
  end
end
