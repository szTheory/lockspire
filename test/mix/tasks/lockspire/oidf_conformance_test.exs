defmodule Mix.Tasks.Lockspire.OidfConformanceTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task Mix.Tasks.Lockspire.OidfConformance
  @task_config_key :lockspire_oidf_conformance_task_config

  setup do
    prior_db = System.get_env("LOCKSPIRE_TEST_DB_HOST")
    prior_oidf = System.get_env("OIDF_CONFORMANCE_SERVER")
    prior_config = Application.get_env(:lockspire, @task_config_key)

    on_exit(fn ->
      restore_env("LOCKSPIRE_TEST_DB_HOST", prior_db)
      restore_env("OIDF_CONFORMANCE_SERVER", prior_oidf)

      if is_nil(prior_config) do
        Application.delete_env(:lockspire, @task_config_key)
      else
        Application.put_env(:lockspire, @task_config_key, prior_config)
      end
    end)

    :ok
  end

  test "exits 0 with success message when env, artifacts, and commands are all present" do
    put_required_envs()

    out = capture_io(fn -> @task.run(["--validate-env"]) end)

    assert out =~ "OIDF FAPI 2.0 preflight OK"
  end

  test "default invocation behaves the same as --validate-env" do
    put_required_envs()

    out = capture_io(fn -> @task.run([]) end)

    assert out =~ "OIDF FAPI 2.0 preflight OK"
  end

  test "raises when LOCKSPIRE_TEST_DB_HOST is missing" do
    System.delete_env("LOCKSPIRE_TEST_DB_HOST")
    System.put_env("OIDF_CONFORMANCE_SERVER", "https://localhost.emobix.co.uk:8443/")

    assert_raise Mix.Error, ~r/LOCKSPIRE_TEST_DB_HOST/, fn ->
      @task.run(["--validate-env"])
    end
  end

  test "raises when OIDF_CONFORMANCE_SERVER is missing" do
    System.put_env("LOCKSPIRE_TEST_DB_HOST", "localhost")
    System.delete_env("OIDF_CONFORMANCE_SERVER")

    assert_raise Mix.Error, ~r/OIDF_CONFORMANCE_SERVER/, fn ->
      @task.run(["--validate-env"])
    end
  end

  test "raises when a required artifact is missing" do
    put_required_envs()
    put_task_override(required_artifacts: ["scripts/conformance/nope.json"])

    assert_raise Mix.Error, ~r/scripts\/conformance\/nope\.json/, fn ->
      @task.run(["--validate-env"])
    end
  end

  test "raises when a required command is missing" do
    put_required_envs()
    put_task_override(required_commands: ["definitely-missing-command"])

    assert_raise Mix.Error, ~r/definitely-missing-command/, fn ->
      @task.run(["--validate-env"])
    end
  end

  test "raises on unknown switches" do
    assert_raise Mix.Error, ~r/Unknown options/, fn ->
      @task.run(["--no-such-flag"])
    end
  end

  test "--help prints usage and does not validate" do
    System.delete_env("LOCKSPIRE_TEST_DB_HOST")
    System.delete_env("OIDF_CONFORMANCE_SERVER")

    out = capture_io(fn -> @task.run(["--help"]) end)

    assert out =~ "mix lockspire.oidf_conformance"
    assert out =~ "--validate-env"
  end

  defp put_required_envs do
    System.put_env("LOCKSPIRE_TEST_DB_HOST", "localhost")
    System.put_env("OIDF_CONFORMANCE_SERVER", "https://localhost.emobix.co.uk:8443/")
  end

  defp put_task_override(overrides) do
    Application.put_env(:lockspire, @task_config_key, overrides)
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end
