defmodule Lockspire.CiStaticContractTest do
  use ExUnit.Case, async: true

  @lint Path.expand("../../scripts/ci/lint_workflows.sh", __DIR__)
  @ci Path.expand("../../.github/workflows/ci.yml", __DIR__)
  @release Path.expand("../../.github/workflows/release.yml", __DIR__)

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
             "git diff --exit-code -- mix.lock examples/adoption_demo/mix.lock test/fixtures/phoenix_1_8_live_view_1_1/mix.lock .github/actions/release-please/runtime/package-lock.json"
  end
end
