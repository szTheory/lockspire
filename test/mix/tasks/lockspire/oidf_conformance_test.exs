defmodule Mix.Tasks.Lockspire.OidfConformanceTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task Mix.Tasks.Lockspire.OidfConformance
  @task_config_key :lockspire_oidf_conformance_task_config

  setup do
    prior_config = Application.get_env(:lockspire, @task_config_key)
    Application.put_env(:lockspire, @task_config_key, compose_available: true)

    on_exit(fn ->
      if is_nil(prior_config) do
        Application.delete_env(:lockspire, @task_config_key)
      else
        Application.put_env(:lockspire, @task_config_key, prior_config)
      end
    end)

    :ok
  end

  test "checks immutable inputs and prerequisite commands" do
    out = capture_io(fn -> @task.run(["--check"]) end)

    assert out =~ "Supplemental OIDF conformance check OK"
    assert out =~ "run_phase37_suite.sh"
    assert out =~ "run_fapi2_suite.sh"
  end

  test "default invocation and legacy --validate-env spelling run the same check" do
    out = capture_io(fn -> @task.run([]) end)
    legacy = capture_io(fn -> @task.run(["--validate-env"]) end)

    assert out =~ "Supplemental OIDF conformance check OK"
    assert legacy =~ "Supplemental OIDF conformance check OK"
  end

  test "raises when a required artifact is missing" do
    put_task_override(
      required_artifacts: ["scripts/conformance/nope.json"],
      compose_available: true
    )

    assert_raise Mix.Error, ~r/scripts\/conformance\/nope\.json/, fn ->
      @task.run(["--check"])
    end
  end

  test "raises when a required command is missing" do
    put_task_override(required_commands: ["definitely-missing-command"], compose_available: true)

    assert_raise Mix.Error, ~r/definitely-missing-command/, fn ->
      @task.run(["--check"])
    end
  end

  test "raises when Docker Compose is unavailable" do
    put_task_override(compose_available: false)

    assert_raise Mix.Error, ~r/Docker Compose plugin is unavailable/, fn ->
      @task.run(["--check"])
    end
  end

  test "raises on unknown switches" do
    assert_raise Mix.Error, ~r/Unknown options/, fn ->
      @task.run(["--no-such-flag"])
    end
  end

  test "--help prints usage and does not validate" do
    out = capture_io(fn -> @task.run(["--help"]) end)

    assert out =~ "mix lockspire.oidf_conformance"
    assert out =~ "--check"
    assert out =~ "immutable OIDF suite lock"
  end

  defp put_task_override(overrides) do
    Application.put_env(:lockspire, @task_config_key, overrides)
  end
end
