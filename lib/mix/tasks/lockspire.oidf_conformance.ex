defmodule Mix.Tasks.Lockspire.OidfConformance do
  @moduledoc """
  Validate the OIDF FAPI 2.0 conformance preflight environment.

  This task does NOT execute the OIDF conformance Docker suite. The live suite
  run remains a documented manual maintainer step (see
  `docs/maintainer-conformance.md`). This task only verifies that the
  environment, dependencies, and pinned plan artifacts are present so a
  maintainer can proceed with the manual run.

  ## Usage

      mix lockspire.oidf_conformance --validate-env

  Required environment variables:
    * `LOCKSPIRE_TEST_DB_HOST`
    * `OIDF_CONFORMANCE_SERVER`

  Required commands on PATH: `bash`, `curl`
  Required artifacts: `scripts/conformance/fapi2-check.sh`, `scripts/conformance/fapi2-plan.json`
  """

  @shortdoc "Validates the OIDF FAPI 2.0 conformance preflight environment"

  use Mix.Task

  @requirements ["app.config"]

  @required_envs ~w(LOCKSPIRE_TEST_DB_HOST OIDF_CONFORMANCE_SERVER)
  @required_artifacts [
    "scripts/conformance/fapi2-check.sh",
    "scripts/conformance/fapi2-plan.json"
  ]
  @required_commands ~w(bash curl)
  @config_key :lockspire_oidf_conformance_task_config

  @switches [validate_env: :boolean, help: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      validate_env!()
    end
  end

  def help do
    """
    mix lockspire.oidf_conformance --validate-env

    Validates the OIDF FAPI 2.0 conformance preflight environment.
    Does NOT run the live Docker suite (manual maintainer step).

    Required env vars: #{Enum.join(required_envs(), ", ")}
    Required commands: #{Enum.join(required_commands(), ", ")}
    Required artifacts:
      #{Enum.join(required_artifacts(), "\n      ")}
    """
  end

  defp validate_env! do
    missing_envs = Enum.filter(required_envs(), &(System.get_env(&1) in [nil, ""]))
    missing_artifacts = Enum.reject(required_artifacts(), &File.exists?/1)
    missing_commands = Enum.reject(required_commands(), &System.find_executable/1)

    if missing_envs != [] or missing_artifacts != [] or missing_commands != [] do
      Mix.raise("""
      OIDF FAPI 2.0 conformance preflight failed.
        missing env vars: #{inspect(missing_envs)}
        missing artifacts: #{inspect(missing_artifacts)}
        missing commands: #{inspect(missing_commands)}

      See docs/maintainer-conformance.md for setup instructions.
      """)
    end

    Mix.shell().info(
      "OIDF FAPI 2.0 preflight OK: env, artifacts, and dependencies present. " <>
        "Proceed with the manual Docker suite run per docs/maintainer-conformance.md."
    )
  end

  defp required_envs do
    Keyword.get(overrides(), :required_envs, @required_envs)
  end

  defp required_artifacts do
    Keyword.get(overrides(), :required_artifacts, @required_artifacts)
  end

  defp required_commands do
    Keyword.get(overrides(), :required_commands, @required_commands)
  end

  defp overrides do
    Application.get_env(:lockspire, @config_key, [])
  end
end
