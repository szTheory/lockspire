defmodule Lockspire.ConformanceProfileExecutionTest do
  use ExUnit.Case, async: false

  @runner Path.expand("../../scripts/conformance/run_phase37_suite.sh", __DIR__)

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "lockspire-conformance-command-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)

    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root}
  end

  test "successful profile waits for Compose and invokes the pinned plan runner", %{root: root} do
    fixture = fixture!(root, 0, 0)

    assert {output, 0} = run_profile(fixture)
    assert output == ""

    calls = fixture.calls |> File.read!() |> String.split("\n", trim: true)

    compose_index =
      Enum.find_index(calls, &String.contains?(&1, "up -d --wait --wait-timeout 120"))

    runner_index =
      Enum.find_index(calls, &String.starts_with?(&1, "runner --verbose --export-dir "))

    assert is_integer(compose_index) and is_integer(runner_index) and compose_index < runner_index
    assert Enum.any?(calls, &String.contains?(&1, "runner --list --verbose --export-dir "))
    assert Enum.any?(calls, &String.contains?(&1, "oidcc-test-plan[client_auth_type=none]"))
    assert Enum.any?(calls, &String.contains?(&1, ":oidcc-prompt-none-not-logged-in"))
    assert Enum.any?(calls, &String.contains?(&1, fixture.config))

    receipt = fixture.artifact |> Path.join("receipt.json") |> File.read!() |> Jason.decode!()
    assert receipt["result"]["status"] == "passed"
    assert receipt["result"]["classification"] == "success"
    refute File.exists?(fixture.raw_marker)
  end

  test "suite failure exits nonzero and retains only a suite_failure receipt", %{root: root} do
    fixture = fixture!(root, 0, 9)

    assert {output, 9} = run_profile(fixture)
    assert output =~ "OIDF suite reported a profile failure"
    assert File.read!(fixture.calls) =~ "runner --verbose --export-dir "

    receipt = fixture.artifact |> Path.join("receipt.json") |> File.read!() |> Jason.decode!()
    assert receipt["result"]["status"] == "failed"
    assert receipt["result"]["classification"] == "suite_failure"
    assert File.ls!(fixture.artifact) == ["receipt.json"]
    refute File.exists?(fixture.raw_marker)
  end

  test "runner preflight failure remains an infrastructure failure", %{root: root} do
    fixture = fixture!(root, 12, 9)

    assert {output, 70} = run_profile(fixture)
    assert output =~ "OIDF suite runner setup failed"

    receipt = fixture.artifact |> Path.join("receipt.json") |> File.read!() |> Jason.decode!()
    assert receipt["result"]["status"] == "failed"
    assert receipt["result"]["classification"] == "infrastructure_failure"
  end

  test "a JSON secret is materialized privately and never retained", %{root: root} do
    fixture = fixture!(root, 0, 0)
    secret = Jason.encode!(%{"description" => "never-retain-me", "server" => %{}})

    assert {output, 0} = run_profile(fixture, secret)

    calls = File.read!(fixture.calls)
    receipt = fixture.artifact |> Path.join("receipt.json") |> File.read!()
    refute calls =~ "never-retain-me"
    refute receipt =~ "never-retain-me"
    refute output =~ "never-retain-me"
    refute calls =~ fixture.config
  end

  test "a missing JSON secret fails with infrastructure evidence before preparation", %{
    root: root
  } do
    fixture = fixture!(root, 0, 0)

    assert {output, 65} = run_profile(fixture, "")
    assert output =~ "LOCKSPIRE_OIDF_PROVIDER_CONFIG must name a regular JSON file"
    refute File.exists?(fixture.calls)

    receipt = fixture.artifact |> Path.join("receipt.json") |> File.read!() |> Jason.decode!()
    assert receipt["result"]["status"] == "failed"
    assert receipt["result"]["classification"] == "infrastructure_failure"
    assert File.ls!(fixture.artifact) == ["receipt.json"]
  end

  defp fixture!(root, preflight_exit, runner_exit) do
    calls = Path.join(root, "calls.txt")
    artifact = Path.join(root, "evidence")
    config = Path.join(root, "provider.json")
    raw_marker = Path.join(root, "raw-output-leaked")
    prepare = executable!(root, "prepare", prepare_script())
    compose = executable!(root, "compose", compose_script(calls))

    suite_runner =
      python_executable!(
        root,
        "suite-runner.py",
        suite_runner_script(calls, preflight_exit, runner_exit)
      )

    File.write!(
      config,
      Jason.encode!(%{
        "description" => "test",
        "server" => %{
          "discoveryUrl" => "https://example.invalid/.well-known/openid-configuration"
        }
      })
    )

    %{
      prepare: prepare,
      compose: compose,
      suite_runner: suite_runner,
      calls: calls,
      artifact: artifact,
      config: config,
      raw_marker: raw_marker
    }
  end

  defp run_profile(fixture) do
    System.cmd("bash", [@runner],
      stderr_to_stdout: true,
      env: [
        {"LOCKSPIRE_PHASE37_ARTIFACT_DIR", fixture.artifact},
        {"LOCKSPIRE_OIDF_PROVIDER_CONFIG", fixture.config},
        {"LOCKSPIRE_OIDF_ALLOW_TEST_DOUBLES", "true"},
        {"LOCKSPIRE_OIDF_TEST_PREPARE", fixture.prepare},
        {"LOCKSPIRE_OIDF_TEST_COMPOSE", fixture.compose},
        {"LOCKSPIRE_OIDF_TEST_RUNNER", fixture.suite_runner}
      ]
    )
  end

  defp run_profile(fixture, config_json) do
    System.cmd("bash", [@runner],
      stderr_to_stdout: true,
      env: [
        {"LOCKSPIRE_PHASE37_ARTIFACT_DIR", fixture.artifact},
        {"LOCKSPIRE_OIDF_PROVIDER_CONFIG", ""},
        {"LOCKSPIRE_OIDF_PROVIDER_CONFIG_JSON", config_json},
        {"LOCKSPIRE_OIDF_ALLOW_TEST_DOUBLES", "true"},
        {"LOCKSPIRE_OIDF_TEST_PREPARE", fixture.prepare},
        {"LOCKSPIRE_OIDF_TEST_COMPOSE", fixture.compose},
        {"LOCKSPIRE_OIDF_TEST_RUNNER", fixture.suite_runner}
      ]
    )
  end

  defp executable!(root, name, body) do
    path = Path.join(root, name)
    File.write!(path, "#!/usr/bin/env bash\nset -euo pipefail\n" <> body)
    File.chmod!(path, 0o700)
    path
  end

  defp python_executable!(root, name, body) do
    path = Path.join(root, name)
    File.write!(path, "#!/usr/bin/env python3\n" <> body)
    File.chmod!(path, 0o700)
    path
  end

  defp prepare_script do
    """
    [[ "$1" == "--output-dir" ]]
    mkdir -p "$2/suite/scripts"
    : > "$2/docker-compose.locked.yml"
    """
  end

  defp compose_script(calls) do
    """
    printf '%s\\n' "$*" >> #{inspect(calls)}
    """
  end

  defp suite_runner_script(calls, preflight_exit, runner_exit) do
    """
    import os
    import pathlib
    import sys

    if "LOCKSPIRE_OIDF_PROVIDER_CONFIG_JSON" in os.environ:
        sys.exit(77)
    with pathlib.Path(#{inspect(calls)}).open("a", encoding="utf-8") as log:
        log.write("runner " + " ".join(sys.argv[1:]) + "\\n")
    print("raw suite output that must be deleted")
    if "--list" in sys.argv:
        sys.exit(#{preflight_exit})
    sys.exit(#{runner_exit})
    """
  end
end
