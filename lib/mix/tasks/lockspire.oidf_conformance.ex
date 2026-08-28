defmodule Mix.Tasks.Lockspire.OidfConformance do
  @moduledoc """
  Checks prerequisites and immutable inputs for supplemental OIDF conformance runs.

  This task does not execute the external suite. Use the checked-in profile
  runners after the check succeeds:

      mix lockspire.oidf_conformance --check
      bash scripts/conformance/run_phase37_suite.sh
      bash scripts/conformance/run_fapi2_suite.sh

  The external lane is supplemental maintainer evidence. It is neither formal
  certification nor a release gate.
  """

  @shortdoc "Checks immutable OIDF conformance inputs and local prerequisites"

  use Mix.Task

  @requirements ["app.config"]
  @required_commands ~w(docker python3 curl jq)
  @required_artifacts [
    "scripts/conformance/oidf-suite-lock.json",
    "scripts/conformance/oidf_inputs.py",
    "scripts/conformance/prepare_oidf_suite.sh",
    "scripts/conformance/run_oidf_profile.sh",
    "scripts/conformance/run_phase37_suite.sh",
    "scripts/conformance/run_fapi2_suite.sh",
    "scripts/conformance/phase37-plan.json",
    "scripts/conformance/fapi2-plan.json",
    "scripts/conformance/build_redacted_evidence.py"
  ]
  @config_key :lockspire_oidf_conformance_task_config
  @switches [check: :boolean, validate_env: :boolean, help: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    if Keyword.get(opts, :help, false), do: Mix.shell().info(help()), else: check!()
  end

  def help do
    """
    mix lockspire.oidf_conformance --check

    Validates the checked-in immutable OIDF suite lock, required scripts/plans,
    and local Docker Compose, Python, curl, and jq prerequisites. The legacy
    --validate-env spelling remains an alias for --check.

    Run profiles after this check:
      bash scripts/conformance/run_phase37_suite.sh
      bash scripts/conformance/run_fapi2_suite.sh
    """
  end

  defp check! do
    missing_artifacts = Enum.reject(required_artifacts(), &File.regular?/1)
    missing_commands = Enum.reject(required_commands(), &System.find_executable/1)
    compose_ok? = missing_commands == [] and compose_available?()

    errors =
      []
      |> add_error(missing_artifacts != [], "missing inputs: #{inspect(missing_artifacts)}")
      |> add_error(missing_commands != [], "missing commands: #{inspect(missing_commands)}")
      |> add_error(
        missing_commands == [] and not compose_ok?,
        "Docker Compose plugin is unavailable"
      )
      |> validate_lock(missing_artifacts)

    if errors != [] do
      Mix.raise("""
      Supplemental OIDF conformance check failed.
        #{Enum.join(Enum.reverse(errors), "\n  ")}

      See docs/maintainer-conformance.md for setup and failure classification.
      """)
    end

    Mix.shell().info("""
    Supplemental OIDF conformance check OK: immutable lock, plans, redaction,
    Docker Compose, Python, curl, and jq are available.
    Run:
      bash scripts/conformance/run_phase37_suite.sh
      bash scripts/conformance/run_fapi2_suite.sh
    """)
  end

  defp validate_lock(errors, missing_artifacts) do
    lock_inputs = [
      "scripts/conformance/oidf-suite-lock.json",
      "scripts/conformance/oidf_inputs.py"
    ]

    if Enum.any?(lock_inputs, &(&1 in missing_artifacts)) do
      errors
    else
      case System.cmd(
             "python3",
             [
               "scripts/conformance/oidf_inputs.py",
               "--lock",
               "scripts/conformance/oidf-suite-lock.json",
               "--validate-only"
             ],
             stderr_to_stdout: true
           ) do
        {_output, 0} -> errors
        {_output, _status} -> ["immutable OIDF suite lock is invalid" | errors]
      end
    end
  end

  defp add_error(errors, true, message), do: [message | errors]
  defp add_error(errors, false, _message), do: errors

  defp compose_available? do
    case Keyword.fetch(overrides(), :compose_available) do
      {:ok, available?} ->
        available?

      :error ->
        match?({_output, 0}, System.cmd("docker", ["compose", "version"], stderr_to_stdout: true))
    end
  end

  defp required_artifacts,
    do: Keyword.get(overrides(), :required_artifacts, @required_artifacts)

  defp required_commands,
    do: Keyword.get(overrides(), :required_commands, @required_commands)

  defp overrides, do: Application.get_env(:lockspire, @config_key, [])
end
