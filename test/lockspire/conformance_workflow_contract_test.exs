defmodule Lockspire.ConformanceWorkflowContractTest do
  use ExUnit.Case, async: true

  @workflow Path.expand("../../.github/workflows/oidf-conformance.yml", __DIR__)
  @guide Path.expand("../../docs/maintainer-conformance.md", __DIR__)
  @requirements Path.expand("../../scripts/conformance/runner-requirements.lock", __DIR__)
  @installer Path.expand("../../scripts/conformance/install_runner_dependencies.sh", __DIR__)
  @ephemeral_runner Path.expand(
                      "../../scripts/conformance/run_ephemeral_oidf_profile.sh",
                      __DIR__
                    )
  @ephemeral_seed Path.expand(
                    "../../examples/adoption_demo/priv/repo/conformance_seeds.exs",
                    __DIR__
                  )
  @demo_seed Path.expand("../../examples/adoption_demo/priv/repo/seeds.exs", __DIR__)

  test "default-branch schedule and dispatch run both immutable supplemental profiles" do
    workflow = File.read!(@workflow)

    assert workflow =~ "name: Supplemental OIDF Conformance"
    assert workflow =~ "schedule:"
    assert workflow =~ ~r/cron: "\d+ \d+ \* \* \d+"/
    assert workflow =~ "workflow_dispatch:"
    assert workflow =~ "permissions:\n  contents: read"
    assert workflow =~ "concurrency:"
    assert workflow =~ "cancel-in-progress: true"
    assert workflow =~ "mix lockspire.oidf_conformance --check"
    assert workflow =~ "bash scripts/conformance/run_ephemeral_oidf_profile.sh phase37"
    assert workflow =~ "bash scripts/conformance/run_ephemeral_oidf_profile.sh fapi2"
    assert workflow =~ ~s(PYTHON_VERSION: "3.13.15")
    assert workflow =~ ~s(PIP_VERSION: "26.2.1")

    assert length(
             Regex.scan(
               ~r/actions\/setup-python@e797f83bcb11b83ae66e0230d6156d7c80228e7c/,
               workflow
             )
           ) == 3

    assert length(Regex.scan(~r/install_runner_dependencies\.sh/, workflow)) == 3
  end

  test "scheduled jobs retain only bounded redacted receipts" do
    workflow = File.read!(@workflow)

    assert workflow =~ ".artifacts/conformance/phase37/receipt.json"
    assert workflow =~ ".artifacts/conformance/fapi2/receipt.json"
    assert length(Regex.scan(~r/if-no-files-found: error/, workflow)) == 3
    assert workflow =~ "retention-days: 30"
    assert workflow =~ "retention-days: 14"

    refute workflow =~ "path: .artifacts/conformance/phase37\n"
    refute workflow =~ "path: .artifacts/conformance/fapi2\n"
    refute workflow =~ "*.log"
    refute workflow =~ "docker-compose.locked.yml"
    refute workflow =~ ~r/path: .*provider/i
  end

  test "scheduled profiles mint throwaway provider material while hosted checks stay isolated" do
    workflow = File.read!(@workflow)
    phase37 = job!(workflow, "repo-native-phase37", "repo-native-fapi2")
    fapi2 = job!(workflow, "repo-native-fapi2", "hosted-maintainer-lane")
    hosted = final_job!(workflow, "hosted-maintainer-lane")
    guide = File.read!(@guide)

    assert hosted =~ "github.event_name == 'workflow_dispatch' && inputs.run_hosted_lane"
    assert phase37 =~ "run_ephemeral_oidf_profile.sh phase37"
    assert fapi2 =~ "run_ephemeral_oidf_profile.sh fapi2"
    assert hosted =~ "secrets.LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON"
    refute phase37 =~ "secrets."
    refute fapi2 =~ "secrets."
    refute hosted =~ "FAPI2_PROVIDER_CONFIG"

    assert length(Regex.scan(~r/LOCKSPIRE_OIDF_PROVIDER_CONFIG_JSON:/, workflow)) == 1
    assert length(Regex.scan(~r/\$\{\{ secrets\./, workflow)) == 1

    assert guide =~ "not OpenID certification"
    assert guide =~ "not a release gate"
    assert guide =~ "integration_only"
    assert guide =~ "infrastructure_failure"
    assert guide =~ "suite_failure"
    assert guide =~ "throwaway"
    assert guide =~ "host.docker.internal"
    assert guide =~ "LOCKSPIRE_OIDF_HOSTED_PROVIDER_CONFIG_JSON"
    assert String.downcase(guide) =~ "hosted maintainer lane"
  end

  test "ephemeral runner keeps provider configuration and host logs private" do
    runner = File.read!(@ephemeral_runner)
    seed = File.read!(@ephemeral_seed)
    demo_seed = File.read!(@demo_seed)

    assert runner =~ "umask 077"
    assert runner =~ "mktemp -d"
    assert runner =~ "conformance_seeds.exs"
    assert runner =~ "LOCKSPIRE_OIDF_PROVIDER_CONFIG"
    assert runner =~ "LOCKSPIRE_DEMO_BIND_IP=0.0.0.0"
    assert runner =~ "LOCKSPIRE_DEMO_BASE_URL=http://host.docker.internal:4100"
    assert runner =~ "ephemeral conformance output must not already exist"
    assert runner =~ "exec env MIX_ENV=dev mix phx.server"
    assert runner =~ "rm -rf \"$work_dir\""
    refute runner =~ "cat \"$host_log\""

    assert seed =~ "LOCKSPIRE_OIDF_PROFILE"
    assert seed =~ "JOSE.JWK.generate_key"
    assert seed =~ "registration_policy: :open"
    assert seed =~ "security_profile: :fapi_2_0_security"
    assert seed =~ "token_endpoint_auth_method: :private_key_jwt"
    assert seed =~ "https://nginx:8443/test/a/lockspire-fapi2/callback"

    assert length(
             Regex.scan(
               ~r/repo\.insert!?\(prefix: Lockspire\.Config\.storage_prefix\(\)\)/,
               demo_seed
             )
           ) == 4
  end

  test "OIDF Python dependencies are exact, hash-locked, and installed without resolution" do
    requirements = File.read!(@requirements)
    installer = File.read!(@installer)

    assert length(Regex.scan(~r/^\w[\w-]*==[^ ]+ \\/m, requirements)) == 7
    assert length(Regex.scan(~r/--hash=sha256:[0-9a-f]{64}/, requirements)) == 7
    refute requirements =~ ">="
    refute requirements =~ "~="

    assert installer =~ "--require-hashes"
    assert installer =~ "--only-binary=:all:"
    assert installer =~ "--no-deps"
    assert installer =~ "--no-input"
    assert installer =~ "actual != expected"
  end

  defp job!(workflow, name, next_name) do
    [_, job] =
      Regex.run(
        ~r/^  #{Regex.escape(name)}:\n(.*?)^  #{Regex.escape(next_name)}:/ms,
        workflow
      )

    job
  end

  defp final_job!(workflow, name) do
    [_, job] = Regex.run(~r/^  #{Regex.escape(name)}:\n(.*)\z/ms, workflow)
    job
  end
end
