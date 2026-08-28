defmodule Lockspire.CiStaticContractTest do
  use ExUnit.Case, async: true

  @lint Path.expand("../../scripts/ci/lint_workflows.sh", __DIR__)
  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @release Path.expand("../../.github/workflows/release.yml", __DIR__)
  @dialyzer_script Path.expand("../../scripts/ci/run_dialyzer.sh", __DIR__)

  test "CI owns checksum-verified zero-warning workflow and shell linting" do
    script = File.read!(@lint)
    ci = File.read!(@ci)

    assert script =~ "ACTIONLINT_VERSION=\"1.7.12\""
    assert script =~ "SHELLCHECK_VERSION=\"0.11.0\""
    assert script =~ "sha256sum --check --status"
    assert script =~ "actionlint -no-color"
    assert script =~ "shellcheck --severity=warning"
    assert ci =~ "bash ./scripts/ci/lint_workflows.sh"
  end

  test "authoritative dependency lanes are check-locked and protect every lockfile" do
    ci = File.read!(@ci)
    release = File.read!(@release)

    assert ci =~ "mix deps.get --check-locked"
    assert release =~ "mix deps.get --check-locked"

    assert ci =~
             "git diff --exit-code -- mix.lock examples/adoption_demo/mix.lock compatibility/phoenix_1_8_live_view_1_1/mix.lock .github/actions/release-please/runtime/package-lock.json"

    assert ci =~
             "npm audit --omit=dev --audit-level=moderate --prefix .github/actions/release-please/runtime"

    assert ci =~ "npm ci --prefix .github/actions/release-please/runtime --ignore-scripts"
    assert ci =~ ~s|await import("./.github/actions/release-please/runtime/index.js")|
  end

  test "Dialyzer is a bounded cached CI gate with no warning suppression" do
    ci = File.read!(@ci)
    script = File.read!(@dialyzer_script)

    assert ci =~ "dialyzer:"
    assert ci =~ "name: Dialyzer"
    assert ci =~ "timeout-minutes: 20"
    assert ci =~ "priv/plts"
    assert ci =~ "Run zero-warning Dialyzer"
    assert ci =~ "bash ./scripts/ci/run_dialyzer.sh"
    assert script =~ "set -euo pipefail"
    assert script =~ "mix deps.get --check-locked"
    assert script =~ "mix compile --warnings-as-errors"
    assert script =~ "mix qa.dialyzer"
    refute script =~ "ignore_warnings"
    refute script =~ "continue-on-error"
  end
end
