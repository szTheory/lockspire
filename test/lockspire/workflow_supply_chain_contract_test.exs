defmodule Lockspire.WorkflowSupplyChainContractTest do
  use ExUnit.Case, async: true

  @release_please_composite Path.expand(
                              "../../.github/actions/release-please/action.yml",
                              __DIR__
                            )

  test "all workflow jobs are bounded and postgres references are immutable" do
    for path <- workflow_paths() do
      workflow = File.read!(path)
      assert workflow =~ "timeout-minutes:", "#{path} is missing a job timeout"

      for [image] <-
            Regex.scan(~r/image:\s+(postgres:[^\s#]+)/, workflow, capture: :all_but_first) do
        assert image =~ "@sha256:", "#{path} has mutable PostgreSQL service image #{image}"
      end
    end
  end

  test "dependency review fails when GitHub cannot provide the dependency graph" do
    workflow = File.read!(Path.expand("../../.github/workflows/dependency-review.yml", __DIR__))

    assert workflow =~ "refusing to skip dependency review"
    assert workflow =~ "exit 1"
    refute workflow =~ "skipping dependency review"
  end

  test "release hygiene runs the portable phase-finalizer lifecycle exactly once in protected order" do
    workflow = File.read!(Path.expand("../../.github/workflows/ci.yml", __DIR__))
    assert length(Regex.scan(~r/^permissions:\s*\n  contents: read\s*$/m, workflow)) == 1

    [[job]] =
      Regex.scan(~r/^  release-hygiene:\n(.*?)(?=^  [a-z0-9-]+:|\z)/ms, workflow,
        capture: :all_but_first
      )

    assert workflow =~
             "  release-hygiene:\n    name: Release Hygiene Drift\n    runs-on: ubuntu-latest\n    timeout-minutes: 30"

    step_names =
      Regex.scan(~r/^      - name: (.+)$/m, job, capture: :all_but_first)
      |> List.flatten()

    assert step_names == [
             "Check out repository",
             "Verify repo-owned release hygiene contract",
             "Lint workflows and maintained shell scripts",
             "Verify phase finalizer command router",
             "Verify portable phase-finalizer lifecycle",
             "Verify and audit Release Please runtime dependencies",
             "Verify dependency setup did not rewrite locks"
           ]

    router_command =
      "node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs"

    lifecycle_command =
      "LOCKSPIRE_SKIP_BEAM_INTEGRATION=1 LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs"

    router_step = step_source(job, "Verify phase finalizer command router")
    lifecycle_step = step_source(job, "Verify portable phase-finalizer lifecycle")

    assert length(:binary.matches(router_step, router_command)) == 1
    assert length(:binary.matches(lifecycle_step, lifecycle_command)) == 1

    router_position = :binary.match(job, router_command) |> elem(0)
    lifecycle_position = :binary.match(job, lifecycle_command) |> elem(0)

    release_audit_position =
      :binary.match(job, "Verify and audit Release Please runtime dependencies") |> elem(0)

    assert router_position < lifecycle_position
    assert lifecycle_position < release_audit_position
  end

  test "immutable action references include the repository-controlled composite exactly once" do
    paths = immutable_reference_paths()

    assert paths == Enum.sort(paths)
    assert File.regular?(@release_please_composite)
    assert Enum.count(paths, &(&1 == @release_please_composite)) == 1

    for path <- paths,
        reference <- action_references(File.read!(path)) do
      assert immutable_action_reference?(reference),
             "#{path} has mutable external action #{reference}"
    end

    assert immutable_action_reference?("./.github/actions/release-please")

    assert immutable_action_reference?(
             "actions/setup-node@2028fbc5c25fe9cf00d9f06a71cc4710d4507903"
           )

    for mutable <- [
          "actions/setup-node@v6",
          "actions/setup-node@main",
          "actions/setup-node@2028fbc5",
          "actions/setup-node@${{ inputs.ref }}",
          "actions/setup-node"
        ] do
      refute immutable_action_reference?(mutable),
             "mutable action reference unexpectedly passed: #{mutable}"
    end
  end

  defp immutable_reference_paths do
    Enum.sort(workflow_paths() ++ [@release_please_composite])
  end

  defp workflow_paths do
    Path.wildcard(Path.expand("../../.github/workflows/*.yml", __DIR__))
    |> Enum.sort()
  end

  defp action_references(source) do
    Regex.scan(~r/uses:\s+([^\s#]+)/, source, capture: :all_but_first)
    |> List.flatten()
  end

  defp step_source(job, name) do
    [[source]] =
      Regex.scan(
        Regex.compile!(
          "^      - name: #{Regex.escape(name)}\\n(.*?)(?=^      - name:|\\z)",
          "ms"
        ),
        job,
        capture: :all_but_first
      )

    source
  end

  defp immutable_action_reference?(reference) do
    String.starts_with?(reference, "./") or
      Regex.match?(~r/^[^@\s]+@[0-9a-f]{40}$/, reference)
  end
end
