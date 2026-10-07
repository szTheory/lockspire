defmodule Lockspire.ReleaseMainFreezeTest do
  use ExUnit.Case, async: true

  @script Path.expand("../../scripts/publish/release_main_freeze.sh", __DIR__)
  @sha "5e18d118091a47966bb29300de1fd453bb0880aa"
  @freeze_id 42
  @freeze_name "Lockspire protected release main freeze"
  @repo "szTheory/lockspire"

  test "preflight accepts only the active no-bypass main freeze and an exact current SHA" do
    {output, status} = run_preflight()

    assert status == 0
    assert output =~ "frozen main matches the exact authorized release SHA"
  end

  test "preflight rejects a freeze with a bypass actor" do
    {output, status} =
      run_preflight(%{bypass_actors: [%{actor_id: 1, actor_type: "User", bypass_mode: "always"}]})

    assert status != 0
    assert output =~ "no-bypass main update lock"
  end

  test "preflight rejects main movement after recovery authorization" do
    moved_sha = "a" <> String.duplicate("0", 39)
    {output, status} = run_preflight(%{main_sha: moved_sha})

    assert status != 0
    assert output =~ "current main differs from the workflow authorization"
  end

  defp run_preflight(overrides \\ %{}) do
    tmp =
      Path.join(
        System.tmp_dir!(),
        "lockspire-release-freeze-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(tmp, "bin")
    File.mkdir_p!(bin)

    gh = Path.join(bin, "gh")
    git = Path.join(bin, "git")
    File.write!(gh, fake_gh())
    File.write!(git, fake_git())
    File.chmod!(gh, 0o755)
    File.chmod!(git, 0o755)

    freeze =
      %{
        "id" => @freeze_id,
        "name" => @freeze_name,
        "source_type" => "Repository",
        "source" => @repo,
        "target" => "branch",
        "enforcement" => Map.get(overrides, :enforcement, "active"),
        "bypass_actors" => Map.get(overrides, :bypass_actors, []),
        "conditions" => %{"ref_name" => %{"include" => ["refs/heads/main"], "exclude" => []}},
        "rules" => [
          %{
            "type" => "update",
            "parameters" => %{"update_allows_fetch_and_merge" => false}
          }
        ]
      }

    effective_rules = [
      %{
        "type" => "update",
        "ruleset_id" => @freeze_id,
        "ruleset_source_type" => "Repository",
        "ruleset_source" => @repo
      }
    ]

    main_sha = Map.get(overrides, :main_sha, @sha)

    env = [
      {"PATH", bin <> ":" <> System.get_env("PATH")},
      {"GH_REPO", @repo},
      {"GH_TOKEN", "test-token"},
      {"RULESET_JSON", Jason.encode!(freeze)},
      {"EFFECTIVE_RULES_JSON", Jason.encode!(effective_rules)},
      {"MAIN_SHA", main_sha},
      {"AUTHORIZED_SHA_FROM_API", @sha}
    ]

    on_exit(fn -> File.rm_rf!(tmp) end)

    System.cmd(
      "bash",
      [@script, "preflight", Integer.to_string(@freeze_id), @sha, @sha, @sha],
      env: env,
      stderr_to_stdout: true
    )
  end

  defp fake_gh do
    """
    #!/usr/bin/env bash
    set -euo pipefail
    endpoint="${2:-}"

    case "$endpoint" in
      "repos/szTheory/lockspire/rulesets/42?includes_parents=false")
        printf '%s\\n' "$RULESET_JSON"
        ;;
      "repos/szTheory/lockspire/rules/branches/main")
        printf '%s\\n' "$EFFECTIVE_RULES_JSON"
        ;;
      "repos/szTheory/lockspire/git/ref/heads/main")
        printf '%s\\n' "$MAIN_SHA"
        ;;
      "repos/szTheory/lockspire/actions/variables/LOCKSPIRE_PHASE143_AUTHORIZED_SHA")
        printf '%s\\n' "$AUTHORIZED_SHA_FROM_API"
        ;;
      *)
        printf 'unexpected gh api endpoint: %s\\n' "$endpoint" >&2
        exit 2
        ;;
    esac
    """
  end

  defp fake_git do
    """
    #!/usr/bin/env bash
    set -euo pipefail

    case "${1:-}" in
      fetch)
        exit 0
        ;;
      rev-parse)
        printf '%s\\n' "$MAIN_SHA"
        ;;
      *)
        printf 'unexpected git command: %s\\n' "$*" >&2
        exit 2
        ;;
    esac
    """
  end
end
