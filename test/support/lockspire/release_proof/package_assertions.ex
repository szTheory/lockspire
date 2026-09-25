defmodule Lockspire.TestSupport.ReleaseProof.PackageAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.ReleaseProof.Paths

  @baseline_phase_number "138"
  @next_phase_number "139"
  @action_phase_number "140"
  @closure_phase_number "141"
  @baseline_phase_label "Phase " <> @baseline_phase_number
  @next_phase_label "Phase " <> @next_phase_number
  @action_phase_label "Phase " <> @action_phase_number
  @closure_phase_label "Phase " <> @closure_phase_number
  @baseline_phase_commit_prefix "docs(phase-" <> @baseline_phase_number <> "): "
  @next_phase_slug "phase-" <> @next_phase_number
  @next_phase_commit_prefix "docs(" <> @next_phase_slug <> "): "

  def assert_hex_package_inputs! do
    files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)

    assert "lib/lockspire.ex" in files
    assert "lib/lockspire/storage/ecto/prefix.ex" in files
    assert "priv/templates/lockspire.install/router.ex" in files
    assert "docs/supported-surface.md" in files
    assert "SECURITY.md" in files

    refute Enum.any?(files, &String.contains?(&1, "*"))
    refute Enum.any?(files, &(&1 in ["lib", "priv", "docs"]))

    refute Enum.any?(
             files,
             &(&1 in ["lib/lockspire/test_repo.ex", "lib/mix/tasks/lockspire.test.setup.ex"])
           )

    package_paths(files)
    |> Enum.each(fn path ->
      refute String.ends_with?(path, ".bak")
      refute String.ends_with?(path, ".DS_Store")
      refute String.starts_with?(path, "_build/")
      refute String.starts_with?(path, "deps/")
      refute String.starts_with?(path, ".planning/")
      refute String.starts_with?(path, "priv/plts/")
    end)
  end

  def assert_repository_hygiene! do
    script = Paths.read!("scripts/maintainer/repo_hygiene_check.sh")
    ci = Paths.read!(".github/workflows/ci.yml")
    adoption_docs = Paths.read!("docs/adoption-demo.md")

    assert script =~ "ci_source_contract_checks"
    assert script =~ "repo_hygiene_check.sh [--ci] [--project NAME]"
    assert ci =~ "bash ./scripts/maintainer/repo_hygiene_check.sh --ci"
    assert ci =~ "python3 scripts/demo/adoption_smoke.py"
    assert adoption_docs =~ "repo-local adopter proof"
    assert adoption_docs =~ "not a production deployment guide"
    refute ci =~ "docker compose"
    refute ci =~ "docker-compose"
    refute script =~ "mix lockspire.demo.cleanup"
    refute File.exists?(Paths.path("lib/lockspire/repo_hygiene.ex"))
  end

  def assert_phase_139_exact_sha_hygiene! do
    script = Paths.read!("scripts/maintainer/repo_hygiene_check.sh")
    {output, status} = run_exact_sha_hygiene_fixture!()

    assert status == 0, output

    for helper <- [
          "validate_acceptance_sha",
          "collect_exact_workflow_run",
          "validate_required_ci_run",
          "validate_required_ci_jobs",
          "validate_no_publish_release_run",
          "require_warn_dispositions",
          "emit_acceptance_receipt"
        ] do
      assert script =~ "#{helper}()"
    end

    assert script =~ ~S(trap 'rm -f -- "$output_file"' EXIT)

    receipt = Jason.decode!(output)

    assert Map.keys(receipt) == [
             "baseline_sha",
             "hygiene",
             "local_gate",
             "release_no_publish",
             "required_ci",
             "schema",
             "supplemental_oidf",
             "warn_dispositions"
           ]

    assert receipt["schema"] == "lockspire-phase-" <> @next_phase_number <> "-acceptance-v1"
    assert receipt["baseline_sha"] == acceptance_sha()
    assert receipt["local_gate"] == %{"exunit_tests" => 1, "status" => "pass"}
    assert receipt["hygiene"]["block"] == 0
    assert receipt["required_ci"]["run_id"] == 1001
    assert receipt["release_no_publish"]["outcome"] == "no_publish"
    assert receipt["warn_dispositions"] == []

    assert receipt["supplemental_oidf"] == %{
             "classification" => "supplemental_non_certifying",
             "required_gate" => false
           }

    assert exact_receipt_keys_in_order?(output)

    assert Enum.all?(
             receipt["required_ci"]["jobs"],
             &(Map.keys(&1) == ["conclusion", "name", "status"])
           )

    assert Enum.all?(
             receipt["release_no_publish"]["jobs"],
             &(Map.keys(&1) == ["conclusion", "name", "status"])
           )
  end

  def assert_phase_139_exact_sha_hygiene_fail_closed! do
    cases = [
      {"invalid SHA syntax", "success", [accept_sha: String.upcase(acceptance_sha())]},
      {"unrelated HEAD", "head-mismatch", []},
      {"unequal local main", "main-mismatch", []},
      {"unequal remote main", "remote-mismatch", []},
      {"remote refresh failure", "fetch-failure", []},
      {"moving HEAD", "head-moves", []},
      {"moving main", "main-moves", []},
      {"failed checkout observation", "status-failure", []},
      {"nonzero mix ci", "mix-failure", []},
      {"interrupted mix ci", "mix-signal", []},
      {"zero ExUnit tests", "mix-zero-tests", []},
      {"malformed ExUnit proof", "mix-malformed", []},
      {"empty workflow candidates", "ci-runs-empty", []},
      {"ambiguous workflow candidates", "ci-runs-duplicate", []},
      {"malformed workflow JSON", "ci-runs-malformed", []},
      {"wrong workflow repository", "ci-wrong-repository", []},
      {"wrong workflow id", "ci-wrong-workflow-id", []},
      {"wrong workflow name", "ci-wrong-name", []},
      {"wrong workflow path", "ci-wrong-path", []},
      {"wrong workflow event", "ci-wrong-event", []},
      {"wrong workflow branch", "ci-wrong-branch", []},
      {"wrong workflow SHA", "ci-wrong-sha", []},
      {"failed workflow", "ci-failed", []},
      {"missing workflow URL", "ci-missing-url", []},
      {"cancelled workflow", "ci-cancelled", []},
      {"bounded polling timeout", "ci-queued-timeout", []},
      {"polling identity replacement", "ci-run-replaced", [wait_seconds: 2]},
      {"main advancement during polling", "main-advances-during-poll", [wait_seconds: 2]},
      {"incomplete job pagination", "ci-jobs-incomplete", []},
      {"successful publication job", "release-published", []},
      {"missing publication job", "release-job-missing", []},
      {"duplicated publication job", "release-job-duplicate", []},
      {"identity movement during Docker inspection", "docker-main-race", []},
      {"undispositioned warning", "docker-warn", []},
      {"unknown zero-warning disposition", "success", [dispositions: ["unknown=reviewed"]]},
      {"duplicate warning disposition", "docker-warn",
       dispositions: [
         "adoption demo stopped containers=reviewed",
         "adoption demo stopped containers=accepted"
       ]},
      {"control character disposition", "docker-warn",
       [dispositions: ["adoption demo stopped containers=bad\nvalue"]]},
      {"redacted API response", "ci-secret-response", []},
      {"redacted command output", "mix-secret-failure", []}
    ]

    Enum.each(cases, fn {label, scenario, options} ->
      {output, status} = run_exact_sha_hygiene_fixture!(scenario, options)

      assert status != 0, "#{label} unexpectedly passed: #{output}"
      assert output =~ "[BLOCK]", "#{label} did not emit a BLOCK category: #{output}"
      refute output =~ "fixture-credential-sentinel", "#{label} leaked fixture credentials"
      refute output =~ ~s({"workflow_runs"), "#{label} leaked a raw workflow response"
    end)

    {output, status} =
      run_exact_sha_hygiene_fixture!("docker-warn",
        dispositions: ["adoption demo stopped containers=reviewed"]
      )

    assert status == 0, output

    assert Jason.decode!(output)["warn_dispositions"] == [
             %{"label" => "adoption demo stopped containers", "disposition" => "reviewed"}
           ]
  end

  def assert_baseline_inventory_collector! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "collect_git_baseline"
    assert script =~ "record_source_receipt"
    assert script =~ "render_front_matter"
    assert script =~ "render_source_receipts"
    assert script =~ "git fetch --prune --tags \"$REMOTE\""
    assert script =~ "git status --porcelain=v2 --branch"
    assert script =~ "git rev-list --left-right --count main...\"$REMOTE/main\""
    assert script =~ "complete"
    assert script =~ "partial"
    assert script =~ "unavailable"
    assert script =~ "not_applicable"
    assert script =~ ~s(yaml_quoted_scalar "no — inventory proposal only")
    assert script =~ "[REDACTED]"
    assert script =~ "mktemp \"${OUTPUT}.tmp.XXXXXX\""
    assert script =~ "Another collector holds the target lock"
    refute script =~ "--prune-tags"
    refute script =~ "git branch -D"
    refute script =~ "git tag -d"
    refute script =~ "git worktree remove"
    refute script =~ "git checkout"
    refute script =~ "git reset"
    refute script =~ "eval "
    refute File.exists?(Paths.path("lib/mix/tasks/lockspire.baseline_inventory.ex"))
    refute File.exists?(Paths.path("lib/lockspire/baseline_inventory.ex"))

    assert {:ok, output} = run_baseline_fixture!()
    assert output =~ ~r/^scope: "git-baseline"$/m
    assert output =~ ~r/^status: "complete"$/m
    assert output =~ ~r/^evidence_base_sha: "/m

    assert output =~
             "Ahead of origin/main (local `main` only): `2`; behind origin/main (remote only): `3`"

    assert output =~ "git fetch --prune --tags origin"
    assert output =~ ~r/^executed: "no — inventory proposal only"$/m
  end

  def assert_baseline_inventory_git_domains! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "--scope git"
    assert script =~ "collect_git_refs"
    assert script =~ "collect_git_tags"
    assert script =~ "collect_git_worktrees"
    assert script =~ "stable_evidence_id"
    assert script =~ "git hash-object --stdin"
    assert script =~ "sort_evidence_rows"

    assert script =~
             "git for-each-ref --format='%(refname)%09%(objectname)' refs/heads refs/remotes"

    assert script =~ "git for-each-ref --format='%(refname)%09%(objectname)' refs/tags"
    assert script =~ "git worktree list --porcelain"
    assert script =~ "GIT-BR"
    assert script =~ "GIT-TAG"
    assert script =~ "GIT-WT"
    assert script =~ "No %s observed; query succeeded with 0 results."
    assert script =~ ~s(yaml_quoted_scalar "no — inventory proposal only")
    refute script =~ "git update-ref"
    refute script =~ "git worktree remove"
    refute script =~ "git branch -d"
    refute script =~ "git tag -d"

    assert {:ok, output} = run_baseline_fixture!("git")
    assert output =~ "## Git branches"
    assert output =~ "GIT-BR-000000000000"
    assert output =~ "refs/heads/main"
    assert output =~ "refs/remotes/origin/main"
    assert output =~ "## Git tags"
    assert output =~ "GIT-TAG-000000000000"
    assert output =~ "## Git worktrees"
    assert output =~ "GIT-WT-000000000000"
  end

  def assert_baseline_inventory_git_domain_receipts! do
    for domain <- ["branches", "tags", "worktrees"] do
      assert {:ok, empty} = run_baseline_fixture!("git", "empty-#{domain}")
      assert empty =~ ~r/^status: "complete"$/m
      assert empty =~ "No Git #{domain} observed; query succeeded with 0 results."
      assert empty =~ "Git #{domain} | complete"

      assert {:ok, malformed} = run_baseline_fixture!("git", "malformed-#{domain}")
      assert malformed =~ ~r/^status: "partial"$/m
      assert malformed =~ "Git #{domain} | partial"
      refute malformed =~ "No Git #{domain} observed; query succeeded with 0 results."

      assert {:ok, unavailable} = run_baseline_fixture!("git", "failed-#{domain}")
      assert unavailable =~ ~r/^status: "partial"$/m
      assert unavailable =~ "Git #{domain} | unavailable"
    end

    assert {:ok, unknown} = run_baseline_fixture!("git", "unknown-branches")
    assert unknown =~ "Git branches | partial"
    assert unknown =~ "unknown Git receipt condition"
    refute unknown =~ ~r/^status: "complete"$/m
  end

  def assert_baseline_inventory_stable_id_failures! do
    git_ref_scenarios = ["failed-branch-id", "empty-tag-id", "malformed-tag-id"]

    for scenario <- git_ref_scenarios do
      assert {:ok, output} = run_baseline_fixture!("git", scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ "Stable evidence ID generation failed"
    end

    assert {:ok, branch_failure} = run_baseline_fixture!("git", "failed-branch-id")
    assert branch_failure =~ "Git branches | partial"
    assert branch_failure =~ "refs/remotes/origin/main"
    refute branch_failure =~ "refs/heads/main` | observed SHA"
    refute branch_failure =~ "No Git branches observed; query succeeded with 0 results."

    for scenario <- ["empty-tag-id", "malformed-tag-id"] do
      assert {:ok, tag_failure} = run_baseline_fixture!("git", scenario)
      assert tag_failure =~ "Git tags | partial"
      refute tag_failure =~ "refs/tags/v1.5.0` | observed SHA"
      refute tag_failure =~ "No Git tags observed; query succeeded with 0 results."
    end

    assert {:ok, valid_empty} = run_baseline_fixture!("git", "empty-tags")
    assert valid_empty =~ "Git tags | complete"
    assert valid_empty =~ "No Git tags observed; query succeeded with 0 results."

    for scenario <- [
          "failed-worktree-id-rollover",
          "empty-worktree-id-blank-close",
          "malformed-worktree-id-final-flush"
        ] do
      assert {:ok, worktree_failure} = run_baseline_fixture!("git", scenario)
      assert worktree_failure =~ ~r/^status: "partial"$/m
      assert worktree_failure =~ "Git worktrees | partial"

      assert worktree_failure =~
               "Stable evidence ID generation failed for one or more observed worktrees"

      assert worktree_failure =~ "worktree-sibling"
      refute worktree_failure =~ "worktree-id-failed` | observed SHA"
      refute worktree_failure =~ "No Git worktrees observed; query succeeded with 0 results."
    end
  end

  def assert_baseline_inventory_github_pull_requests! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "--scope github"
    assert script =~ "collect_github_pull_requests"
    assert script =~ "github_auth_receipt"
    assert script =~ "combine_graphql_pages"
    assert script =~ "github_field_value"
    assert script =~ "summarize_pr_checks"
    assert script =~ "propose_pr_disposition"
    assert script =~ "gh api graphql --paginate"
    assert script =~ "COLLECTION(first: 100, states: OPEN, after: $endCursor)"
    assert script =~ "prefix=\"GH-PR\""
    assert script =~ "pageInfo"
    assert script =~ ~s(yaml_quoted_scalar "no — inventory proposal only")
    refute script =~ "gh pr list"
    refute script =~ "bodyText"
    refute script =~ "comments"

    assert {:ok, output} = run_github_fixture!()
    assert output =~ "GH-PR-1"
    assert output =~ "GH-PR-2"
    assert output =~ "GH-ISSUE-1"
    assert output =~ "duplicate nodes corroborated: `1`"
    assert output =~ "merge-ready"
    assert output =~ "[REDACTED]"
    refute output =~ "body-secret-sentinel"
    refute output =~ "token-secret-sentinel"
  end

  def assert_baseline_inventory_github_issues! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "collect_github_issues"
    assert script =~ "propose_issue_disposition"
    assert script =~ "GH-ISSUE"
    assert script =~ "No open issues observed; query succeeded with 0 results."

    assert {:ok, output} = run_github_fixture!("zero-issues")
    assert output =~ "No open issues observed; query succeeded with 0 results."
    refute output =~ "GH-ISSUE-"
    assert output =~ "GH-PR-1"
  end

  def assert_baseline_inventory_github_failure_receipts! do
    for {scenario, receipt} <- [
          {"null-nodes", "null_nodes"},
          {"malformed-json", "malformed_json"},
          {"malformed-page-info", "malformed_page_info"},
          {"premature-pagination", "premature_pagination"},
          {"auth-failed", "auth_failed"},
          {"api-failed", "api_failed"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ "GitHub open queues |"
      assert output =~ receipt
      refute output =~ "query succeeded with 0 results"
      refute output =~ "| merge-ready |"
    end

    assert {:ok, hostile} = run_github_fixture!("hostile")
    assert hostile =~ "[REDACTED]"
    refute hostile =~ "ToKeN"
    refute hostile =~ "GHp_"
    refute hostile =~ "GiThUb_PaT_"
    refute hostile =~ "\r"
    refute hostile =~ <<0x1F>>
    refute hostile =~ <<0x1B>>
    refute hostile =~ <<0x7F>>
    refute hostile =~ <<0xC2, 0x80>>
  end

  def assert_baseline_inventory_github_aggregate_fail_closed! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "validate_github_rows"
    assert script =~ "cleanup_github_temp"

    for {scenario, receipt} <- [
          {"issue-api-failed", "api_failed"},
          {"issue-premature-pagination", "premature_pagination"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ "GitHub open queues |"
      assert output =~ receipt
      assert output =~ "GH-PR-1"
      assert output =~ "| active | defer |"
      refute output =~ "| merge-ready |"
    end

    assert {:ok, complete} = run_github_fixture!("default")
    assert complete =~ ~r/^status: "complete"$/m
    assert complete =~ "GH-PR-1"
    assert complete =~ "GH-ISSUE-1"
    assert complete =~ "| merge-ready |"

    for {scenario, receipt, retained_row, rejected_row} <- [
          {"malformed-issue-row", "issues_row_validation_failed", "GH-PR-1", "GH-ISSUE-1"},
          {"malformed-pr-row", "pull_requests_row_validation_failed", "GH-ISSUE-1", "GH-PR-1"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ receipt
      assert output =~ retained_row
      assert output =~ "| active | defer |"
      refute output =~ rejected_row
      refute output =~ "| merge-ready |"
      refute output =~ "| close |"
      refute output =~ "| retain |"
    end

    assert {:ok, hostile_valid} = run_github_fixture!("hostile-valid-row")
    assert hostile_valid =~ ~r/^status: "complete"$/m
    assert hostile_valid =~ "GH-PR-1"
    assert length(Regex.scan(~r/\| GH-PR-1 \|/, hostile_valid)) == 1
    assert hostile_valid =~ "[REDACTED]"
    refute hostile_valid =~ "GHp_bad"
    refute hostile_valid =~ "GiThUb_PaT_bad"
  end

  def assert_baseline_inventory_github_check_completeness! do
    for {scenario, expected_check_state} <- [
          {"pending-check", "unknown"},
          {"legacy-failure", "failed"},
          {"action-required", "failed"},
          {"startup-failure", "failed"},
          {"unknown-conclusion", "unknown"},
          {"mixed-nonterminal", "unknown"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ "checks `#{expected_check_state}"
      refute output =~ "| merge-ready |"
    end

    assert {:ok, nested_complete} = run_github_fixture!("nested-many")
    assert nested_complete =~ ~r/^status: "complete"$/m
    assert nested_complete =~ "checks `passed (101 observed; complete)`"
    assert nested_complete =~ "| merge-ready |"

    for {scenario, receipt} <- [
          {"nested-count-mismatch", "nested_count_mismatch"},
          {"nested-malformed-page-info", "nested_malformed_page_info"},
          {"nested-api-failed", "nested_api_failed"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ receipt
      assert output =~ "GH-PR-1"
      assert output =~ "| active | defer |"
      refute output =~ "| merge-ready |"
    end
  end

  def assert_baseline_inventory_github_duplicate_consistency! do
    for scenario <- [
          "duplicate-head",
          "duplicate-check",
          "duplicate-review",
          "duplicate-updated"
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ "contradictory_duplicate_PR-1"
      assert output =~ "GH-ISSUE-1"
      assert output =~ "| active | defer |"
      refute output =~ "| merge-ready |"
    end

    for {scenario, receipt} <- [
          {"outer-premature-terminal", "premature_terminal_page"},
          {"outer-missing-cursor", "missing_page_cursor"},
          {"outer-repeated-cursor", "repeated_page_cursor"},
          {"outer-post-terminal", "post_terminal_page"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ receipt
      refute output =~ "| merge-ready |"
      refute output =~ "query succeeded with 0 results"
    end

    assert {:ok, corroborated} = run_github_fixture!("identical-duplicate-reversed")
    assert corroborated =~ ~r/^status: "complete"$/m
    assert corroborated =~ "duplicate nodes corroborated: `1`"
    assert length(Regex.scan(~r/\| GH-PR-1 \|/, corroborated)) == 1
    assert length(Regex.scan(~r/\| GH-PR-2 \|/, corroborated)) == 1
    assert :binary.match(corroborated, "| GH-PR-1 |") < :binary.match(corroborated, "| GH-PR-2 |")
    assert corroborated =~ "GH-ISSUE-1"
    refute corroborated =~ "No open issues observed; query succeeded with 0 results."
  end

  def assert_baseline_inventory_github_integrity_gaps! do
    for {scenario, receipt} <- [
          {"outer-errors-pending", "graphql_errors"},
          {"nested-errors-pending", "nested_graphql_errors"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ receipt
      refute output =~ "forbidden raw diagnostic"

      if scenario == "nested-errors-pending" do
        assert output =~ "GH-PR-1"
        assert output =~ "checks `unknown"
        assert output =~ "| active | defer |"
      else
        assert output =~ "pullRequests graphql_errors"
        refute output =~ "GH-PR-1"
      end

      refute output =~ "| merge-ready |"
    end

    assert {:ok, complete} = run_github_fixture!("default")
    assert complete =~ ~r/^status: "complete"$/m
    assert complete =~ "checks `passed (1 observed; complete)`"
    assert complete =~ "| merge-ready |"
    assert :binary.match(complete, "| GH-PR-1 |") < :binary.match(complete, "| GH-PR-2 |")

    for scenario <- [
          "issue-duplicate-title",
          "issue-duplicate-state",
          "issue-duplicate-updated"
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ "contradictory_duplicate_ISSUE-1"
      refute output =~ "| GH-ISSUE-1 |"
      assert output =~ "| GH-ISSUE-2 |"
      assert output =~ "| active | defer |"
      refute output =~ "No open issues observed; query succeeded with 0 results."
    end

    assert {:ok, corroborated} = run_github_fixture!("issue-exact-duplicate-reversed")
    assert corroborated =~ ~r/^status: "complete"$/m
    assert corroborated =~ "duplicate nodes corroborated: `2`"
    assert length(Regex.scan(~r/\| GH-ISSUE-1 \|/, corroborated)) == 1
    assert length(Regex.scan(~r/\| GH-ISSUE-2 \|/, corroborated)) == 1

    assert :binary.match(corroborated, "| GH-ISSUE-1 |") <
             :binary.match(corroborated, "| GH-ISSUE-2 |")

    assert corroborated =~ "| GH-PR-1 |"
    assert corroborated =~ "| GH-PR-2 |"

    assert {:ok, zero} = run_github_fixture!("zero-issues")
    assert zero =~ ~r/^status: "complete"$/m
    assert zero =~ "No open issues observed; query succeeded with 0 results."
  end

  def assert_baseline_inventory_current_verification_gaps! do
    assert {:ok, matching} = run_github_fixture!("default")
    assert matching =~ ~r/^status: "complete"$/m
    assert matching =~ "checks `passed (1 observed; complete)`"
    assert matching =~ "| merge-ready |"

    for {scenario, limitation} <- [
          {"nested-head-mismatch", "nested_head_mismatch"},
          {"nested-head-missing", "nested_missing_commit_oid"},
          {"nested-head-null", "nested_missing_commit_oid"},
          {"nested-head-multiple", "nested_ambiguous_latest_commit"},
          {"nested-head-malformed", "nested_malformed_commit_oid"},
          {"nested-head-page-changing", "nested_commit_oid_changed"}
        ] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ limitation
      assert output =~ "| GH-PR-1 |"
      assert output =~ "checks `unknown"
      assert output =~ "| active | defer |"
      refute output =~ "| merge-ready |"
      refute output =~ "forbidden raw diagnostic"
    end

    assert {:ok, late_marker} =
             run_baseline_fixture!("maintained", "maintained-archive-late-marker")

    late_id = stable_rec_id(".planning/debug/late-actionable.md")
    assert late_marker =~ ~r/^status: "complete"$/m
    assert length(Regex.scan(~r/\| #{Regex.escape(late_id)} \|/, late_marker)) == 1
    assert late_marker =~ "`.planning/debug/late-actionable.md`"
    assert late_marker =~ "| active | fix-now |"

    assert {:ok, benign_archive} =
             run_baseline_fixture!("maintained", "maintained-archive-benign")

    refute benign_archive =~ "`.planning/debug/benign.md`"
    assert benign_archive =~ "| debug | archive-summary |"

    assert {:ok, incidental_terms} =
             run_baseline_fixture!("maintained", "maintained-archive-incidental-terms")

    assert incidental_terms =~ ~r/^status: "complete"$/m
    refute incidental_terms =~ "`.planning/debug/incidental-terms.md`"
    assert incidental_terms =~ "| debug | archive-summary |"

    assert {:ok, unreadable_archive} =
             run_baseline_fixture!("maintained", "maintained-archive-unreadable")

    assert unreadable_archive =~ ~r/^status: "partial"$/m
    assert unreadable_archive =~ "| debug | unavailable | `.planning/debug/unreadable.md` |"
    refute unreadable_archive =~ "| debug | archive-summary |"
    refute unreadable_archive =~ "No Maintained follow-up families observed"

    for format <- ["sha1", "sha256"],
        domain <- ["branches", "tags", "worktrees"],
        length <- [40, 41, 63, 64] do
      scenario = "object-#{format}-#{domain}-#{length}"
      assert {:ok, output} = run_baseline_fixture!("git", scenario)
      valid = (format == "sha1" and length == 40) or (format == "sha256" and length == 64)

      if valid do
        assert output =~ "Git #{domain} | complete"
        assert output =~ "#{domain}-candidate"
      else
        assert output =~ ~r/^status: "partial"$/m
        assert output =~ "Git #{domain} | partial"
        refute output =~ "#{domain}-candidate` | observed SHA"
        refute output =~ "No Git #{domain} observed; query succeeded with 0 results."
      end

      assert output =~ "#{domain}-sibling"
    end
  end

  def assert_baseline_inventory_review_verification_gaps! do
    for scenario <- ["github-object-40", "github-object-64"] do
      assert {:ok, output} = run_github_fixture!(scenario)
      assert output =~ ~r/^status: "complete"$/m
      assert output =~ "| GH-PR-1 |"
      assert output =~ "| merge-ready |"
    end

    for length <- [41, 63] do
      assert {:ok, output} = run_github_fixture!("github-base-oid-#{length}")
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ "pullRequests=partial"
      assert output =~ "pull_requests_row_validation_failed"
      assert output =~ "| GH-ISSUE-1 |"
      assert output =~ "| active | defer |"
      refute output =~ "| merge-ready |"
    end

    assert {:ok, active_incidental} =
             run_baseline_fixture!("maintained", "maintained-active-incidental")

    review_id =
      stable_rec_id(".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md")

    verification_id =
      stable_rec_id(
        ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md"
      )

    assert active_incidental =~ ~r/^status: "complete"$/m
    assert active_incidental =~ "| active-records | complete |"
    assert active_incidental =~ "2 bounded tracked matches"

    for id <- [review_id, verification_id] do
      assert length(Regex.scan(~r/\| #{Regex.escape(id)} \|/, active_incidental)) == 1
      assert active_incidental =~ ~r/\| #{Regex.escape(id)} \|[^\n]*\| active \| fix-now \|/
    end

    assert {:ok, archive_matrix} =
             run_baseline_fixture!("maintained", "maintained-archive-action-matrix")

    for marker <- ["fix", "status", "outcome", "disposition", "heading"],
        phrase <- ["resolved", "historical", "scope"],
        order <- ["before", "after"] do
      path = ".planning/debug/matrix-#{marker}-#{phrase}-#{order}.md"
      id = stable_rec_id(path)

      assert length(Regex.scan(~r/\| #{Regex.escape(id)} \|/, archive_matrix)) == 1,
             "missing #{path}"

      assert archive_matrix =~ ~r/\| #{Regex.escape(id)} \|[^\n]*\| active \| fix-now \|/
    end

    conflict_path = ".planning/debug/matrix-conflict.md"
    conflict_id = stable_rec_id(conflict_path)
    assert archive_matrix =~ ~r/^status: "partial"$/m
    assert archive_matrix =~ "| debug | unclassified/ambiguous | `#{conflict_path}` |"
    refute archive_matrix =~ "| #{conflict_id} |"

    assert {:ok, incidental_fix_now} =
             run_baseline_fixture!("maintained", "maintained-archive-incidental-fix-now")

    terminal_archive_path =
      ".planning/milestones/v1.27-phases/99-signer-extraction-jwt-default-issuance/99-VERIFICATION.md"

    terminal_archive_id = stable_rec_id(terminal_archive_path)
    assert incidental_fix_now =~ ~r/^status: "complete"$/m
    assert incidental_fix_now =~ "| milestones | archive-summary |"
    assert incidental_fix_now =~ "1 retained records summarized"
    refute incidental_fix_now =~ "| #{terminal_archive_id} |"
    refute incidental_fix_now =~ "milestones:ambiguous"
  end

  def assert_baseline_inventory_credential_redaction! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "credential_like_value"
    assert script =~ "redacted_display_value"

    lowercase_run_opaque = "AbCdEfGhIjKlMnOpQrStUvWxYz012345abcdef"

    assert {:ok, lowercase_run_branch} =
             run_baseline_fixture!("git", "credential-redaction", [
               {"FAKE_CREDENTIAL", lowercase_run_opaque},
               {"FAKE_CREDENTIAL_REPO_ROOT", lowercase_run_opaque},
               {"LOCKSPIRE_INVENTORY_REMOTE", lowercase_run_opaque}
             ])

    lowercase_run_branch_id =
      stable_git_evidence_id(
        "GIT-BR",
        "local_branch",
        "refs/heads/#{lowercase_run_opaque}"
      )

    assert_no_raw_credential!(
      lowercase_run_branch,
      lowercase_run_opaque,
      "lowercase-run opaque Git branch"
    )

    assert lowercase_run_branch =~
             "| #{lowercase_run_branch_id} | local_branch | `[REDACTED]` |"

    assert lowercase_run_branch =~ ~s(repository: "[REDACTED]")
    assert lowercase_run_branch =~ "| origin metadata refresh | complete | `[REDACTED]` |"
    assert lowercase_run_branch =~ "no — inventory proposal only"

    safe_format_near_misses = [
      {"git-object", "G1" <> String.duplicate("a1", 19)},
      {"evidence-id", "REC-a1b2c3d4e5f6-AbCdEfGhIjKlMnOp1"},
      {"uuid", "G23e4567-e89b-12d3-a456-426614174000"},
      {"version", "lockspire-v1.38.0-#{lowercase_run_opaque}"},
      {"release-name", "LockspireReleaseCandidateSeptember2026x"},
      {"public-url", "http://example.test/#{lowercase_run_opaque}"}
    ]

    Enum.each(safe_format_near_misses, fn {label, value} ->
      assert {:ok, output} =
               run_github_fixture!("credential-redaction", [{"FAKE_CREDENTIAL", value}])

      assert_no_raw_credential!(output, value, "#{label} safe-format near miss")
      assert output =~ "[REDACTED]"
    end)

    credentials = [
      {"lowercase-run-opaque", lowercase_run_opaque},
      {"aws-access-key", "AKIAIOSFODNN7EXAMPLE"},
      {"slack-token",
       "xoxb-" <>
         "123456789012" <>
         "-" <>
         "123456789012" <>
         "-" <>
         "AbCdEfGhIjKlMnOpQrStUvWx"},
      {"jwt",
       "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"},
      {"pem-boundary", "-----BEGIN PRIVATE KEY-----"},
      {"bearer", "Bearer QWxwaGEyMDE4U2VjcmV0Q3JlZGVudGlhbA=="},
      {"github-token", "ghp_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789"},
      {"opaque", "AbCdEfGhIjKlMnOpQrStUvWxYz0123456789AB"}
    ]

    Enum.each(credentials, fn {label, credential} ->
      assert {:ok, github} =
               run_github_fixture!("credential-redaction", [{"FAKE_CREDENTIAL", credential}])

      assert {:ok, maintained} =
               run_baseline_fixture!("maintained", "credential-redaction", [
                 {"FAKE_CREDENTIAL", credential}
               ])

      assert_no_raw_credential!(github, credential, "#{label} GitHub fields")
      assert_no_raw_credential!(maintained, credential, "#{label} maintained fields")
      assert github =~ "[REDACTED]"
      assert maintained =~ "[REDACTED]"
    end)

    assert {:ok, limitation_output} =
             run_github_fixture!("credential-redaction-limitation", [
               {"FAKE_CREDENTIAL", lowercase_run_opaque}
             ])

    assert_no_raw_credential!(
      limitation_output,
      lowercase_run_opaque,
      "GitHub limitation and source receipt"
    )

    assert limitation_output =~ "Collection partial: [REDACTED]"
    assert limitation_output =~ "| GitHub open queues | partial |"

    {diagnostic, diagnostic_status} =
      System.cmd(
        "bash",
        [Paths.path("scripts/maintainer/baseline_inventory.sh"), "--#{lowercase_run_opaque}"],
        stderr_to_stdout: true
      )

    assert diagnostic_status != 0
    assert_no_raw_credential!(diagnostic, lowercase_run_opaque, "captured CLI diagnostic")
    assert diagnostic =~ "[REDACTED]"

    for {label, credential} <-
          Enum.filter(credentials, fn {label, _credential} ->
            label not in ["pem-boundary", "bearer"]
          end) do
      assert {:ok, git} =
               run_baseline_fixture!("git", "credential-redaction", [
                 {"FAKE_CREDENTIAL", credential}
               ])

      assert_no_raw_credential!(git, credential, "#{label} Git fields")
      assert git =~ "[REDACTED]"
    end

    first = "AKIAIOSFODNN7EXAMPLE"
    second = "AKIAZZZZZZZZZZZZZZZZ"

    assert {:ok, collapsed} =
             run_baseline_fixture!("git", "credential-redaction", [
               {"FAKE_CREDENTIAL", first},
               {"FAKE_CREDENTIAL_ALT", second}
             ])

    assert_no_raw_credential!(collapsed, first, "first collapsed Git identity")
    assert_no_raw_credential!(collapsed, second, "second collapsed Git identity")

    branch_ids =
      ~r/\| (GIT-BR-[0-9a-f]{12}) \|/
      |> Regex.scan(collapsed, capture: :all_but_first)
      |> List.flatten()
      |> Enum.uniq()

    assert length(branch_ids) >= 3
    assert length(Regex.scan(~r/`\[REDACTED\]`/, collapsed)) >= 6

    benign_values = [
      {"sha1", String.duplicate("a1", 20)},
      {"sha256", String.duplicate("b2", 32)},
      {"evidence-id", "REC-a1b2c3d4e5f6"},
      {"uuid", "123e4567-e89b-12d3-a456-426614174000"},
      {"version", "lockspire-v1.38.0-rc.2"},
      {"release-name", "LockspireReleaseCandidateSeptember2026"},
      {"public-url", "https://github.com/lockspire/lockspire/releases/tag/v1.38.0"},
      {"prose", "This maintained record remains useful to release operators"}
    ]

    Enum.each(benign_values, fn {label, value} ->
      assert {:ok, git} =
               run_baseline_fixture!("git", "credential-redaction", [
                 {"FAKE_CREDENTIAL", value}
               ])

      if :binary.match(git, value) == :nomatch do
        flunk("benign #{label} was hidden at the Git display boundary")
      end
    end)
  end

  def assert_baseline_inventory_maintained_records! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")

    assert script =~ "--scope maintained"
    assert script =~ "MAINTAINED_SOURCE_FAMILIES"
    assert script =~ "collect_maintained_records"
    assert script =~ "classify_record"
    assert script =~ "summarize_archive_container"
    assert script =~ "canonical_record_subject"
    assert script =~ "deduplicate_record_refs"
    assert script =~ "render_maintained_inventory"
    assert script =~ "collect_maintained_family_paths"
    assert script =~ "classify_active_record"
    assert script =~ "validate_phase_completion_state_contract"
    assert script =~ "validate_repeated_worktree_transition"
    assert script =~ ~S(at `'"${short}"'`.*Phase ) <> @next_phase_number
    assert script =~ ~S(ledger `'"${short}"'` \|$)
    refute script =~ ~S(\\`${short}\\`)
    assert script =~ "previous_status:[[:space:]]+passed"
    assert script =~ "all_fixed) printf 'resolved\\talready-resolved\\tdirect_current'"
    assert script =~ "issues_found) printf 'active\\tfix-now\\tdirect_current'"
    assert script =~ "gaps_found) printf 'active\\tfix-now\\tdirect_current'"
    assert script =~ "REC-"
    assert script =~ "not_applicable"
    assert script =~ "unclassified"
    assert script =~ ~s(yaml_quoted_scalar "no — inventory proposal only")
    refute script =~ "git clean"

    active_record_patterns =
      for suffix <- ~w(REVIEW AUDIT VERIFICATION UAT HANDOFF CHECKPOINT) do
        ":(glob).planning/phases/*/*-#{suffix}*.md"
      end

    {active_record_output, 0} =
      System.cmd("git", ["ls-files", "-z", "--" | active_record_patterns], stderr_to_stdout: true)

    active_record_paths = String.split(active_record_output, <<0>>, trim: true)

    assert ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md" in active_record_paths

    assert ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md" in active_record_paths

    assert {:ok, lifecycle_output} =
             run_baseline_fixture!("maintained", "maintained-active-lifecycle")

    assert lifecycle_output =~ ~r/^status: "complete"$/m

    assert lifecycle_output =~
             "| maintained_record | `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-review.md` | observed allowlisted source | active | fix-now |"

    assert lifecycle_output =~
             "| maintained_record | `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-verification.md` | observed allowlisted source | active | fix-now |"

    assert lifecycle_output =~
             "| maintained_record | `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-review-fix.md` | observed allowlisted source | resolved | already-resolved |"

    assert {:ok, review_fix_near_miss} =
             run_baseline_fixture!("maintained", "maintained-review-fix-near-miss")

    assert review_fix_near_miss =~ ~r/^status: "partial"$/m

    assert review_fix_near_miss =~
             "| active-records | unclassified/ambiguous | `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW-FIX.md` |"

    assert {:ok, output} = run_baseline_fixture!("maintained", "maintained")
    assert output =~ "## Maintained source-family receipts"
    assert output =~ "todos | complete-zero"
    assert output =~ "debug | archive-summary"
    assert output =~ "REC-"

    for disposition <- [
          "fix-now",
          "defer-with-trigger",
          "retain-historical",
          "already-resolved",
          "out-of-scope"
        ] do
      assert output =~ disposition
    end

    assert output =~ "supersedes:old-record"
    assert output =~ "active-records:.planning/debug/actionable.md"
    assert output =~ "unclassified/ambiguous"
    refute output =~ ".planning/phases/old/"
    refute output =~ "_build/generated"
  end

  def assert_baseline_inventory_active_uat! do
    complete_path = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md"
    partial_path = ".planning/phases/139-required-truth-reconciliation/139-UAT.md"

    assert {:ok, valid} = run_baseline_fixture!("maintained", "maintained-active-uat")
    assert valid =~ ~r/^status: "complete"$/m

    assert valid =~
             "| active-records | complete | `.planning/phases/*/*-{REVIEW,AUDIT,VERIFICATION,UAT,HANDOFF,CHECKPOINT}*.md` | 2 bounded tracked matches |"

    assert valid =~ "| Maintained follow-up families | complete |"

    for {path, lifecycle, disposition} <- [
          {complete_path, "resolved", "already-resolved"},
          {partial_path, "active", "defer-with-trigger"}
        ] do
      id = stable_rec_id_from_canonical(String.downcase(path))

      assert maintained_row_fields(valid, id) == [
               id,
               "maintained_record",
               "`#{String.downcase(path)}`",
               "observed allowlisted source",
               lifecycle,
               disposition,
               "`active-records:#{path}`",
               "Allowlisted maintained record; source preserved",
               "direct_current",
               "Revalidate current state, authority, and recovery path before action",
               "repository maintainer",
               "no"
             ]
    end

    near_miss_paths = [
      ".planning/phases/current/missing-status-UAT.md",
      ".planning/phases/current/duplicate-status-UAT.md",
      ".planning/phases/current/unknown-status-UAT.md",
      ".planning/phases/current/missing-current-test-UAT.md",
      ".planning/phases/current/missing-tests-UAT.md",
      ".planning/phases/current/fenced-headings-UAT.md",
      ".planning/phases/current/commented-headings-UAT.md",
      ".planning/phases/current/frontmatter-headings-UAT.md",
      ".planning/phases/current/indented-code-headings-UAT.md"
    ]

    assert {:ok, near_misses} =
             run_baseline_fixture!("maintained", "maintained-active-uat-near-misses")

    assert near_misses =~ ~r/^status: "partial"$/m
    assert near_misses =~ "| Maintained follow-up families | partial |"
    assert near_misses =~ "| active-records | unclassified/ambiguous |"

    Enum.each(near_miss_paths, fn path ->
      id = stable_rec_id_from_canonical(String.downcase(path))
      refute Enum.any?(maintained_rec_rows(near_misses), &String.starts_with?(&1, "| #{id} |"))

      assert near_misses =~
               "| active-records | unclassified/ambiguous | `#{path}` |"
    end)
  end

  def assert_baseline_inventory_maintained_fail_closed! do
    assert {:ok, marker_failure} =
             run_baseline_fixture!("maintained", "maintained-marker-failure")

    assert marker_failure =~ ~r/^status: "partial"$/m
    assert marker_failure =~ "| tracked-markers | unavailable |"
    assert marker_failure =~ "selector failed with exit 31"
    refute marker_failure =~ "| tracked-markers | complete-zero |"

    assert {:ok, family_failure} =
             run_baseline_fixture!("maintained", "maintained-family-failure")

    assert family_failure =~ ~r/^status: "partial"$/m
    assert family_failure =~ "| debug | unavailable |"
    assert family_failure =~ "selector failed with exit 32"
    assert family_failure =~ "| active-records | complete |"
    assert family_failure =~ "defer-with-trigger"
    refute family_failure =~ "| debug | complete-zero |"

    assert {:ok, ambiguous} = run_baseline_fixture!("maintained", "maintained")
    assert ambiguous =~ ~r/^status: "partial"$/m
    assert ambiguous =~ "| active-records | unclassified/ambiguous |"
    assert ambiguous =~ ".planning/phases/current/138-VERIFICATION.md"
    assert ambiguous =~ "recheck required before a maintained row can be proposed"
    refute ambiguous =~ "| Maintained follow-up families | complete |"

    assert {:ok, reversed} = run_baseline_fixture!("maintained", "maintained-reversed")

    assert maintained_rec_rows(ambiguous) == maintained_rec_rows(reversed)

    assert {:ok, current_planning} =
             run_baseline_fixture!("maintained", "maintained-current-planning")

    assert current_planning =~ ~r/^status: "complete"$/m

    for {family, path} <- [
          {"threads", ".planning/threads/next-roadmap-assessment.md"},
          {"roadmap", ".planning/ROADMAP.md"},
          {"state", ".planning/STATE.md"},
          {"project", ".planning/PROJECT.md"},
          {"release-train", ".planning/RELEASE-TRAIN.md"},
          {"development-train", ".planning/DEVELOPMENT-TRAIN.md"}
        ] do
      assert current_planning =~ "| #{family} | complete |"

      assert current_planning =~
               "| maintained_record | `#{String.downcase(path)}` | observed allowlisted source | active | defer-with-trigger | `#{family}:#{path}` |"

      refute current_planning =~ "| #{family} | unclassified/ambiguous |"
    end

    assert {:ok, planning_near_misses} =
             run_baseline_fixture!("maintained", "maintained-current-planning-near-misses")

    assert planning_near_misses =~ ~r/^status: "partial"$/m

    for {family, path} <- [
          {"threads", ".planning/threads/next-roadmap-assessment.md"},
          {"roadmap", ".planning/ROADMAP.md"},
          {"state", ".planning/STATE.md"},
          {"project", ".planning/PROJECT.md"},
          {"release-train", ".planning/RELEASE-TRAIN.md"},
          {"development-train", ".planning/DEVELOPMENT-TRAIN.md"}
        ] do
      assert planning_near_misses =~
               "| #{family} | unclassified/ambiguous | `#{path}` |"
    end

    refute planning_near_misses =~ "| Maintained follow-up families | complete |"

    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")
    assert script =~ "git ls-files -z"
    assert script =~ "git grep -z"
    refute script =~ ~s(files="$(git ls-files)

    {hostile, repeated, subjects, repository, fixture} = run_hostile_maintained_fixture!()

    try do
      assert hostile =~ ~r/^status: "complete"$/m
      assert normalize_collection_window(hostile) == normalize_collection_window(repeated)

      Enum.each(subjects, fn subject ->
        if String.valid?(subject) do
          canonical_subject = String.downcase(subject)
          input = "record:#{canonical_subject}"

          digest =
            :crypto.hash(:sha, "blob #{byte_size(input)}\0#{input}")
            |> Base.encode16(case: :lower)

          id = "REC-" <> String.slice(digest, 0, 12)
          assert length(Regex.scan(~r/\| #{Regex.escape(id)} \|/, hostile)) == 1
        end
      end)

      refute hostile =~ "\n## INJECTED"
      refute hostile =~ "\n| INJECTED |"
      refute hostile =~ "GHp_hostile"
      refute hostile =~ "token-secret"
      refute hostile =~ "\t"
      refute hostile =~ "\r"

      refute Enum.any?(String.to_charlist(hostile), fn codepoint ->
               codepoint in 0..8 or codepoint in 11..12 or codepoint in 14..31 or
                 codepoint in 127..159
             end)

      refute File.exists?(Path.join(repository, "LOCKSPIRE_HOSTILE_SIDE_EFFECT"))
      assert run_git!(repository, ["status", "--porcelain"]) == ""
      assert_collector_artifacts_clean!(Path.join(fixture, "inventory.md"))
      assert_collector_artifacts_clean!(Path.join(fixture, "inventory-repeated.md"))
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_maintained_encoding! do
    assert {:ok, marker_zero} =
             run_baseline_fixture!("maintained", "maintained-marker-zero")

    assert marker_zero =~ ~r/^status: "complete"$/m
    assert marker_zero =~ "| tracked-markers | complete-zero |"
    assert marker_zero =~ "selector succeeded with zero tracked markers"
    assert marker_zero =~ "| Maintained follow-up families | complete |"
    refute marker_zero =~ "| tracked_marker |"
    refute marker_zero =~ "selector failed"

    assert {:ok, marker_zero_with_family_failure} =
             run_baseline_fixture!("maintained", "maintained-marker-zero-family-failure")

    assert marker_zero_with_family_failure =~ ~r/^status: "partial"$/m
    assert marker_zero_with_family_failure =~ "| tracked-markers | complete-zero |"
    assert marker_zero_with_family_failure =~ "| debug | unavailable |"
    refute marker_zero_with_family_failure =~ "| Maintained follow-up families | complete |"

    for {scenario, exit_status} <- [
          {"maintained-marker-failure-2", "2"},
          {"maintained-marker-failure-42", "42"}
        ] do
      assert {:ok, unavailable} = run_baseline_fixture!("maintained", scenario)
      assert unavailable =~ ~r/^status: "partial"$/m
      assert unavailable =~ "| tracked-markers | unavailable |"
      assert unavailable =~ "selector failed with exit #{exit_status}"
      refute unavailable =~ "| Maintained follow-up families | complete |"
    end

    for scenario <- [
          "maintained-marker-exit-one-output",
          "maintained-marker-exit-zero-empty",
          "maintained-marker-malformed"
        ] do
      assert {:ok, malformed} = run_baseline_fixture!("maintained", scenario)
      assert malformed =~ ~r/^status: "partial"$/m
      assert malformed =~ "| tracked-markers | unavailable |"
      refute malformed =~ "| Maintained follow-up families | complete |"
    end

    {hostile, _repeated, _subjects, repository, fixture} = run_hostile_maintained_fixture!()

    try do
      assert String.valid?(hostile)
      assert hostile =~ "café"
      assert hostile =~ "euro-€.md"
      assert hostile =~ "invalid-%FF.md"
      refute hostile =~ <<0xFF>>

      frontmatter = read_frontmatter!(Path.join(fixture, "inventory.md"))

      canonical_repository =
        repository |> run_git!(["rev-parse", "--show-toplevel"]) |> String.trim_trailing("\n")

      assert frontmatter["repository"] == canonical_repository
      assert frontmatter["repository_identity"] == canonical_repository
      assert frontmatter["scope"] == "maintained"
      assert frontmatter["status"] == "complete"

      for field <- [
            "scope",
            "status",
            "collection_started_at",
            "collection_finished_at",
            "repository",
            "repository_identity",
            "declared_source_scopes",
            "local_head_sha",
            "evidence_base_sha",
            "local_main_sha",
            "origin_main_sha",
            "git_receipt_fingerprint",
            "github_receipt_fingerprint",
            "maintained_receipt_fingerprint",
            "executed"
          ] do
        assert hostile =~ ~r/^#{Regex.escape(field)}: "/m
      end

      hostile
      |> maintained_rec_rows()
      |> Enum.each(fn row ->
        assert length(String.split(row, " | ")) == 12, row
      end)

      tab_subject = ".planning/todos/tab\tname.md"
      tab_id = stable_rec_id(tab_subject)

      assert maintained_row_fields(hostile, tab_id) == [
               tab_id,
               "maintained_record",
               "`.planning/todos/tab%09name.md`",
               "observed allowlisted source",
               "active",
               "defer-with-trigger",
               "`todos:.planning/todos/tab%09name.md`",
               "Allowlisted maintained record; source preserved",
               "corroborated",
               "Revalidate current state, authority, and recovery path before action",
               "repository maintainer",
               "no"
             ]

      invalid_subject = ".planning/todos/invalid-" <> <<0xFF>> <> ".md"
      invalid_id = stable_rec_id_from_canonical(invalid_subject)
      invalid_fields = maintained_row_fields(hostile, invalid_id)
      assert Enum.at(invalid_fields, 2) == "`.planning/todos/invalid-%FF.md`"
      assert Enum.at(invalid_fields, 6) == "`todos:.planning/todos/invalid-%FF.md`"
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_maintained_integrity_gaps! do
    helper_source = Paths.read!("test/support/lockspire/release_proof/package_assertions.ex")

    for source <- [
          helper_source,
          Paths.read!("scripts/maintainer/baseline_inventory.sh"),
          Paths.read!("scripts/maintainer/finalize_phase_138_inventory.sh")
        ] do
      refute source =~ "/" <> "Users" <> "/"
    end

    {hostile, repeated, subjects, repository, fixture} = run_hostile_maintained_fixture!()

    try do
      assert normalize_collection_window(hostile) == normalize_collection_window(repeated)

      Enum.each(subjects, fn subject ->
        id =
          if String.valid?(subject),
            do: stable_rec_id(subject),
            else: stable_rec_id_from_canonical(subject)

        fields = maintained_row_fields(hostile, id)

        assert [
                 ^id,
                 "maintained_record",
                 _display_subject,
                 "observed allowlisted source",
                 "active",
                 "defer-with-trigger",
                 _evidence,
                 "Allowlisted maintained record; source preserved",
                 "corroborated",
                 "Revalidate current state, authority, and recovery path before action",
                 "repository maintainer",
                 "no"
               ] = fields
      end)

      refute hostile =~ "\n## INJECTED"
      refute hostile =~ "\n| INJECTED |"
      refute File.exists?(Path.join(repository, "LOCKSPIRE_HOSTILE_SIDE_EFFECT"))
    after
      File.rm_rf(fixture)
    end

    assert {:ok, duplicates} = run_baseline_fixture!("maintained", "maintained")
    duplicate_id = stable_rec_id(".planning/debug/actionable.md")

    assert maintained_row_fields(duplicates, duplicate_id) == [
             duplicate_id,
             "maintained_record",
             "`.planning/debug/actionable.md`",
             "observed allowlisted source",
             "active",
             "fix-now",
             "`active-records:.planning/debug/actionable.md; debug:.planning/debug/actionable.md`",
             "Allowlisted maintained record; source preserved; supersedes:old-record",
             "direct_current",
             "Revalidate current state, authority, and recovery path before action",
             "repository maintainer",
             "no"
           ]

    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")
    assert script =~ "invalid or contradictory structured record"
    assert script =~ ": > \"$MAINTAINED_AGGREGATED_OUTPUT\""

    assert {:ok, all_excluded} =
             run_baseline_fixture!("maintained", "maintained-archive-all-excluded")

    assert all_excluded =~ "| debug | complete-zero |"
    refute all_excluded =~ "debug archive container"
    refute all_excluded =~ ".planning/debug/cache/ignored.md"

    assert {:ok, mixed} = run_baseline_fixture!("maintained", "maintained-archive-mixed")

    assert {:ok, mixed_reversed} =
             run_baseline_fixture!("maintained", "maintained-archive-mixed-reversed")

    assert length(Regex.scan(~r/\| archive_summary \| .*1 retained records/, mixed)) == 2
    assert mixed =~ "1 retained records summarized"
    refute mixed =~ ".planning/debug/cache/ignored.md"
    assert maintained_rec_rows(mixed) == maintained_rec_rows(mixed_reversed)
  end

  def assert_baseline_inventory_output_lifecycle! do
    root = Paths.path(".")

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-output-lifecycle-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(fixture, "bin")
    output = Path.join(fixture, "inventory.md")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "git"), 0o755)
      File.chmod!(Path.join(bin, "gh"), 0o755)

      base_env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_REPO_ROOT", root},
        {"FAKE_OUTPUT", output}
      ]

      prior_target = "complete target before interrupted render\n"
      File.write!(output, prior_target)

      # The directory lock is the publication guard. Refusal leaves a fully written
      # pre-existing target byte-for-byte intact, and a clean retry can atomically
      # replace it once the owning process has released the lock.
      File.mkdir!(output <> ".lock")
      {refusal, refusal_status} = run_collector!("git", output, base_env)
      assert refusal_status != 0
      assert refusal =~ "Another collector holds the target lock"
      assert File.read!(output) == prior_target
      File.rmdir!(output <> ".lock")

      {retry_output, 0} = run_collector!("git", output, base_env)
      assert retry_output == ""
      assert File.read!(output) =~ "## Git branches"
      refute File.read!(output) =~ output <> ".tmp."
      assert_collector_artifacts_clean!(output)

      assert_different_targets_are_independent!(fixture, base_env)
      assert_ledger_parent_freshness_relation!(fixture)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_publication_transaction! do
    root = Paths.path(".")

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-publication-transaction-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(fixture, "bin")
    output = Path.join(fixture, "inventory.md")
    barrier_release = Path.join(fixture, "release-prelock")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.write!(Path.join(bin, "mkdir"), prelock_barrier_mkdir_script())

      for command <- ["git", "gh", "mkdir"] do
        File.chmod!(Path.join(bin, command), 0o755)
      end

      base_env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_REPO_ROOT", root},
        {"LOCKSPIRE_INVENTORY_LOCK_ATTEMPTS", "500"},
        {"FAKE_PRELOCK_RELEASE", barrier_release}
      ]

      writers =
        for writer <- ["a", "b"] do
          ready = Path.join(fixture, "#{writer}-prelock-ready")
          seen = Path.join(fixture, "#{writer}-prelock-seen")
          command_log = Path.join(fixture, "#{writer}-commands.log")

          owner =
            start_collector_port!(
              "git",
              output,
              base_env ++
                [
                  {"FAKE_PRELOCK_READY", ready},
                  {"FAKE_PRELOCK_SEEN", seen},
                  {"FAKE_COMMAND_LOG", command_log}
                ],
              false
            )

          {writer, owner, ready, command_log}
        end

      Enum.each(writers, fn {writer, _owner, ready, _log} ->
        await_path!(ready, "writer #{writer} did not reach the pre-lock barrier")
      end)

      refute File.exists?(output)
      File.write!(barrier_release, "release\n")

      results =
        Enum.map(writers, fn {writer, owner, _ready, log} ->
          {command_output, status} = await_port_exit!(owner)
          {writer, command_output, status, File.read!(log)}
        end)

      assert Enum.count(results, fn {_writer, _output, status, _log} -> status == 0 end) == 1
      assert Enum.count(results, fn {_writer, _output, status, _log} -> status != 0 end) == 1

      [{_winner, "", 0, winner_log}] =
        Enum.filter(results, fn {_writer, _output, status, _log} -> status == 0 end)

      [{_loser, loser_output, loser_status, loser_log}] =
        Enum.filter(results, fn {_writer, _output, status, _log} -> status != 0 end)

      assert loser_status != 0
      assert loser_output =~ "Refusing to replace existing output without --replace"
      assert winner_log =~ "fetch --prune --tags origin"
      refute loser_log =~ "fetch --prune --tags origin"
      refute loser_log =~ "for-each-ref"
      refute loser_log =~ "worktree list --porcelain"

      published = File.read!(output)
      published_digest = :crypto.hash(:sha256, published)
      assert published =~ "## Git branches"
      assert :crypto.hash(:sha256, File.read!(output)) == published_digest
      assert_collector_artifacts_clean!(output)

      for {scenario, diagnostic} <- [
            {"worktree-modified", "working tree changed"},
            {"worktree-deleted", "working tree changed"},
            {"worktree-untracked", "working tree changed"},
            {"status-capture-failed", "Working-tree evidence unavailable during capture"},
            {"status-recheck-failed",
             "Working-tree evidence unavailable during pre-publication recheck"}
          ] do
        assert_publication_worktree_failure_preserves_target!(
          fixture,
          bin,
          root,
          scenario,
          diagnostic
        )
      end

      assert_owned_worktree_paths_are_exactly_excluded!(fixture, bin, root)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_publication_integrity_gaps! do
    for scenario <- [
          "missing-head",
          "missing-main",
          "missing-remote-main",
          "failed-head-with-stdout",
          "malformed-head",
          "malformed-divergence",
          "failed-porcelain"
        ] do
      assert {:ok, output} = run_baseline_fixture!("git-baseline", scenario)
      assert output =~ ~r/^status: "partial"$/m
      assert output =~ "Completeness: `partial`"
      refute output =~ "failed-command-stdout"
      refute output =~ "Source receipt is complete"
    end

    assert {:ok, complete} = run_baseline_fixture!("git-baseline", "default")
    assert complete =~ ~r/^status: "complete"$/m
    assert complete =~ ~r/^local_head_sha: "0{63}1"$/m
    assert complete =~ ~r/^local_main_sha: "0{63}2"$/m
    assert complete =~ ~r/^origin_main_sha: "0{63}3"$/m

    assert complete =~
             "Ahead of origin/main (local `main` only): `2`; behind origin/main (remote only): `3`"

    assert_publication_rejects_non_regular_targets!()
    assert_baseline_inventory_publication_transaction!()
  end

  def assert_baseline_inventory_worktree_path_boundaries! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-worktree-paths-#{System.unique_integer([:positive])}"
      )

    repository = Path.join(fixture, "repository")
    origin = Path.join(fixture, "origin.git")
    output = Path.join(fixture, "inventory.md")

    hostile_paths = [
      Path.join(fixture, "linked\tworktree"),
      Path.join(fixture, "linked\nworktree")
    ]

    try do
      File.mkdir_p!(repository)
      run_git!(repository, ["init", "-q", "-b", "main"])
      run_git!(repository, ["config", "user.email", "paths@example.com"])
      run_git!(repository, ["config", "user.name", "Path Boundary Test"])
      write_repo_file!(repository, "tracked.txt", "path boundary\n")
      commit_all!(repository, "test: hostile worktree paths")

      File.mkdir_p!(origin)
      run_git!(origin, ["init", "-q", "--bare"])
      run_git!(repository, ["remote", "add", "origin", origin])
      run_git!(repository, ["push", "-qu", "origin", "main"])

      Enum.each(hostile_paths, fn path ->
        run_git!(repository, ["worktree", "add", "--detach", path, "HEAD"])
      end)

      hostile_paths =
        Enum.map(hostile_paths, fn path ->
          {physical_path, 0} = System.cmd("pwd", ["-P"], cd: path, stderr_to_stdout: true)
          String.trim_trailing(physical_path, "\n")
        end)

      {command_output, status} =
        System.cmd(
          "bash",
          [
            Paths.path("scripts/maintainer/baseline_inventory.sh"),
            "--scope",
            "git",
            "--output",
            output
          ],
          cd: repository,
          stderr_to_stdout: true
        )

      assert status == 0, command_output
      assert command_output == ""
      inventory = File.read!(output)
      assert inventory =~ ~r/^status: "complete"$/m
      assert inventory =~ "| Git worktrees | complete |"

      worktree_rows =
        inventory
        |> String.split("\n")
        |> Enum.filter(&String.starts_with?(&1, "| GIT-WT-"))

      assert length(worktree_rows) == 3

      Enum.each(hostile_paths, fn path ->
        input = "worktree:" <> path

        digest =
          :crypto.hash(:sha, "blob #{byte_size(input)}\0#{input}") |> Base.encode16(case: :lower)

        id = "GIT-WT-" <> String.slice(digest, 0, 12)

        encoded_path =
          path
          |> String.replace("%", "%25")
          |> String.replace("\t", "%09")
          |> String.replace("\n", "%0A")

        row = Enum.find(worktree_rows, &String.starts_with?(&1, "| #{id} |"))

        assert row, "expected exact stable worktree row for #{inspect(path)}"
        assert row =~ "`#{encoded_path}`"

        assert row
               |> String.trim_leading("| ")
               |> String.trim_trailing(" |")
               |> String.split(" | ")
               |> length() == 12
      end)

      assert {:ok, malformed} = run_baseline_fixture!("git", "malformed-worktrees")
      assert malformed =~ ~r/^status: "partial"$/m
      assert malformed =~ "Git worktrees | partial"
      refute malformed =~ "No Git worktrees observed; query succeeded with 0 results."
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_caller_paths_and_preflight! do
    assert_caller_relative_replacement!("name.md", "nested/name.md", "name.md")
    assert_caller_relative_replacement!("../name.md", "name.md", "../name.md")
    assert_missing_jq_preflight!("collection")
    assert_missing_jq_preflight!("relation")
  end

  defp assert_caller_relative_replacement!(argument, intended_relative, former_relative) do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-caller-path-#{System.unique_integer([:positive])}"
      )

    repository = Path.join(fixture, "repository")
    origin = Path.join(fixture, "origin.git")
    nested = Path.join(repository, "nested")
    intended = Path.expand(intended_relative, repository)
    former = Path.expand(former_relative, repository)

    try do
      File.mkdir_p!(nested)
      run_git!(repository, ["init", "-q", "-b", "main"])
      run_git!(repository, ["config", "user.email", "caller@example.com"])
      run_git!(repository, ["config", "user.name", "Caller Path Test"])
      write_repo_file!(repository, "tracked.txt", "caller path\n")
      File.mkdir_p!(Path.dirname(intended))
      File.mkdir_p!(Path.dirname(former))
      File.write!(intended, "intended sentinel\n")
      File.write!(former, "former sentinel\n")
      commit_all!(repository, "test: caller-relative output targets")

      File.mkdir_p!(origin)
      run_git!(origin, ["init", "-q", "--bare"])
      run_git!(repository, ["remote", "add", "origin", origin])
      run_git!(repository, ["push", "-qu", "origin", "main"])

      {command_output, status} =
        System.cmd(
          "bash",
          [
            Paths.path("scripts/maintainer/baseline_inventory.sh"),
            "--scope",
            "git-baseline",
            "--output",
            argument,
            "--replace"
          ],
          cd: nested,
          stderr_to_stdout: true
        )

      assert status == 0, command_output
      assert command_output == ""
      assert File.read!(intended) =~ "# Git baseline evidence receipt"
      assert File.read!(former) == "former sentinel\n"
    after
      File.rm_rf(fixture)
    end
  end

  defp assert_missing_jq_preflight!(mode) do
    fixture =
      Path.join(System.tmp_dir!(), "lockspire-no-jq-#{System.unique_integer([:positive])}")

    bin = Path.join(fixture, "bin")
    command_sentinel = Path.join(fixture, "command-ran")
    output = Path.join(fixture, "inventory.md")
    ledger = Path.join(fixture, "ledger.md")

    try do
      File.mkdir_p!(bin)

      for executable <- ["git", "python3"] do
        path = Path.join(bin, executable)

        File.write!(
          path,
          "#!/bin/sh\nprintf '%s\\n' '#{executable}' >> '#{command_sentinel}'\nexit 42\n"
        )

        File.chmod!(path, 0o755)
      end

      File.write!(output, "output sentinel\n")
      File.write!(ledger, "ledger sentinel\n")

      args =
        case mode do
          "collection" -> ["--scope", "git-baseline", "--output", output, "--replace"]
          "relation" -> ["--verify-snapshot-relation", ledger]
        end

      {command_output, status} =
        System.cmd(
          "/bin/bash",
          [Paths.path("scripts/maintainer/baseline_inventory.sh") | args],
          env: [{"PATH", bin}],
          stderr_to_stdout: true
        )

      assert status != 0
      assert command_output == "jq is required for structured evidence processing\n"
      refute File.exists?(command_sentinel)
      assert File.read!(output) == "output sentinel\n"
      assert File.read!(ledger) == "ledger sentinel\n"
      refute File.exists?(output <> ".lock")
    after
      File.rm_rf(fixture)
    end
  end

  defp assert_publication_rejects_non_regular_targets! do
    root = Paths.path(".")

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-publication-targets-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(fixture, "bin")
    neighbor = Path.join(fixture, "neighbor.txt")
    linked_file = Path.join(fixture, "linked-file.md")
    linked_dir = Path.join(fixture, "linked-dir")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.chmod!(Path.join(bin, "git"), 0o755)
      File.write!(neighbor, "neighbor bytes\n")
      File.write!(linked_file, "linked file bytes\n")
      File.mkdir!(linked_dir)

      base_env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_REPO_ROOT", root}
      ]

      directory = Path.join(fixture, "directory-target")
      File.mkdir!(directory)

      symlink_file = Path.join(fixture, "symlink-file.md")
      symlink_dir = Path.join(fixture, "symlink-dir.md")
      File.ln_s!(linked_file, symlink_file)
      File.ln_s!(linked_dir, symlink_dir)

      fifo = Path.join(fixture, "fifo-target")
      {_, 0} = System.cmd("mkfifo", [fifo], stderr_to_stdout: true)

      for {kind, output} <- [
            {:directory, directory},
            {:symlink_file, symlink_file},
            {:symlink_directory, symlink_dir},
            {:fifo, fifo}
          ] do
        before_neighbor = File.read!(neighbor)
        before_linked_file = File.read!(linked_file)
        before_directory = File.ls!(linked_dir)

        {command_output, status} = run_collector!("git", output, base_env)
        assert status != 0, "#{kind} unexpectedly accepted"
        assert command_output =~ "regular file target"
        assert File.read!(neighbor) == before_neighbor
        assert File.read!(linked_file) == before_linked_file
        assert File.ls!(linked_dir) == before_directory

        case kind do
          :directory -> assert File.ls!(directory) == []
          :symlink_file -> assert {:ok, %File.Stat{type: :symlink}} = File.lstat(symlink_file)
          :symlink_directory -> assert {:ok, %File.Stat{type: :symlink}} = File.lstat(symlink_dir)
          :fifo -> assert {:ok, %File.Stat{type: :other}} = File.lstat(fifo)
        end

        assert_collector_artifacts_clean!(output)
      end
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_live_writer_contention! do
    root = Paths.path(".")

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-live-writer-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(fixture, "bin")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "git"), 0o755)
      File.chmod!(Path.join(bin, "gh"), 0o755)

      base_env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_REPO_ROOT", root}
      ]

      for signal <- ["INT", "TERM", "HUP"] do
        output = Path.join(fixture, "signal-#{String.downcase(signal)}.md")
        ready = output <> ".ready"
        release = output <> ".release"
        prior = "complete target before #{signal}\n"
        File.write!(output, prior)

        owner_env =
          base_env ++
            [
              {"FAKE_GIT_SCENARIO", "hold-before-rename"},
              {"FAKE_HOLD_READY", ready},
              {"FAKE_HOLD_RELEASE", release}
            ]

        owner = start_collector_port!("git", output, owner_env)
        await_path!(ready, "collector did not reach pre-rename hold for #{signal}")

        sentinel = output <> ".refused-writer-ran"

        {refusal, refusal_status} =
          run_collector!("git", output, base_env ++ [{"FAKE_WRITER_SENTINEL", sentinel}])

        assert refusal_status != 0
        assert refusal =~ "Another collector holds the target lock"
        assert File.exists?(sentinel)
        refute File.read!(output) =~ "refused-writer-ran"
        assert File.read!(output) == prior

        signal_collector!(owner, signal)
        File.write!(release, "release\n")
        {owner_output, owner_status} = await_port_exit!(owner)
        assert owner_status != 0, "#{signal} exit #{owner_status}: #{owner_output}"
        assert File.read!(output) == prior

        assert_collector_artifacts_clean!(
          output,
          "#{signal} exit #{owner_status}: #{owner_output}"
        )

        {retry_output, 0} = run_collector!("git", output, base_env)
        assert retry_output == ""
        assert File.read!(output) =~ "## Git branches"
        assert_collector_artifacts_clean!(output)
      end

      assert_pagination_contention!(fixture, base_env)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_snapshot_currentness! do
    script = Paths.read!("scripts/maintainer/baseline_inventory.sh")
    assert script =~ "capture_snapshot_identity"
    assert script =~ "capture_source_receipt_fingerprints"
    assert script =~ "verify_snapshot_identity_unchanged"
    assert script =~ "evidence_base_sha: $(yaml_quoted_scalar \"$EVIDENCE_BASE_SHA\")"
    assert script =~ "git_receipt_fingerprint:"
    assert script =~ "github_receipt_fingerprint:"
    assert script =~ "maintained_receipt_fingerprint:"

    assert {:ok, stable_git} = run_baseline_fixture!("git", "default")
    assert stable_git =~ ~r/^evidence_base_sha: "/m
    assert stable_git =~ ~r/^git_receipt_fingerprint: "/m
    assert stable_git =~ ~r/^declared_source_scopes: "git"$/m
    refute stable_git =~ ".tmp.collector-owned"

    assert {:ok, stable_github} = run_github_fixture!("default")
    assert stable_github =~ ~r/^github_receipt_fingerprint: "/m
    refute stable_github =~ "body-secret-sentinel"

    assert {:ok, superseded} =
             run_baseline_fixture!("maintained", "maintained-superseded-gaps")

    assert superseded =~ "| active-records | superseded-lifecycle |"
    refute superseded =~ "unclassified/ambiguous"

    assert {:ok, missing_summary} =
             run_baseline_fixture!("maintained", "maintained-missing-gap-summary")

    assert missing_summary =~ "unclassified/ambiguous"
    refute missing_summary =~ "superseded-lifecycle"

    for {scope, scenario, diagnostic} <- [
          {"git", "drift-head", "HEAD changed"},
          {"git", "drift-main", "main changed"},
          {"git", "drift-remote-main", "remote main changed"},
          {"git", "drift-repository", "repository identity changed"},
          {"maintained", "drift-maintained", "maintained receipt changed"},
          {"github", "external-receipt-drift", "GitHub receipt changed"}
        ] do
      assert_snapshot_drift_preserves_target!(scope, scenario, diagnostic)
    end
  end

  def assert_baseline_inventory_post_snapshot_drift! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-post-snapshot-#{System.unique_integer([:positive])}"
      )

    repository = Path.join(fixture, "authorized")
    ledger = "baseline.md"

    try do
      {ledger_commit, _base} = build_snapshot_repository!(repository, ledger)
      phase_completion = append_authorized_lifecycle!(repository)

      before_refs = run_git!(repository, ["show-ref"])
      before_status = run_git!(repository, ["status", "--porcelain=v1"])
      {first, 0} = run_snapshot_relation!(repository, ledger)
      {second, 0} = run_snapshot_relation!(repository, ledger)
      assert first == second
      assert first =~ "snapshot_relation: authorized_bookkeeping"

      for lifecycle <- [
            "phase_summary",
            "clean_review",
            "passed_verification",
            "phase_completion",
            "transition_bookkeeping"
          ] do
        assert first =~ "class=#{lifecycle}"
      end

      assert run_git!(repository, ["show-ref"]) == before_refs
      assert run_git!(repository, ["status", "--porcelain=v1"]) == before_status

      run_git!(repository, ["checkout", "-q", "-B", "main", phase_completion])
      write_valid_transition!(repository)
      {working_tree, 0} = run_snapshot_relation!(repository, ledger)
      assert working_tree =~ "working_tree|transition_bookkeeping|authorized_bookkeeping"

      hostile_cases = [
        {"pending-summary",
         fn repo ->
           path = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-12-SUMMARY.md"
           write_repo_file!(repo, path, "---\nstatus: complete\n---\nTODO pending follow-up\n")
           commit_all!(repo, "docs(138-12): complete hostile plan")
         end},
        {"source-change",
         fn repo ->
           path = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-12-SUMMARY.md"
           write_repo_file!(repo, path, "---\nstatus: complete\n---\nSafe\n")
           write_repo_file!(repo, "lib/source.ex", "changed\n")
           commit_all!(repo, "docs(138-12): complete hostile plan")
         end},
        {"unknown-subject",
         fn repo ->
           write_repo_file!(repo, ".planning/STATE.md", "status: changed\n")
           commit_all!(repo, "docs: unknown bookkeeping")
         end},
        {"unknown-author",
         fn repo ->
           run_git!(repo, ["config", "user.name", "Unknown Author"])
           path = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-12-SUMMARY.md"
           write_repo_file!(repo, path, "---\nstatus: complete\n---\nSafe\n")
           commit_all!(repo, "docs(138-12): complete hostile plan")
         end},
        {"committer-mismatch",
         fn repo ->
           path = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-12-SUMMARY.md"
           write_repo_file!(repo, path, "---\nstatus: complete\n---\nSafe\n")
           run_git!(repo, ["add", "--all"])

           {_, 0} =
             System.cmd("git", ["commit", "-qm", "docs(138-12): complete hostile plan"],
               cd: repo,
               env: [
                 {"GIT_COMMITTER_NAME", "Different Committer"},
                 {"GIT_COMMITTER_EMAIL", "different@example.com"}
               ],
               stderr_to_stdout: true
             )
         end},
        {"todo-close",
         fn repo ->
           write_repo_file!(repo, ".planning/todos/completed/closed.md", "resolved todo\n")
           commit_all!(repo, @baseline_phase_commit_prefix <> "close 1 resolved todo(s)")
         end},
        {"changed-ledger",
         fn repo ->
           File.write!(Path.join(repo, ledger), "changed ledger\n")
           commit_all!(repo, "docs: mutate ledger")
         end}
      ]

      Enum.each(hostile_cases, fn {name, mutation} ->
        hostile = clone_at_commit!(fixture, repository, ledger_commit, name)
        mutation.(hostile)
        assert_relation_refreshes!(hostile, ledger)
      end)

      merge_repo = clone_at_commit!(fixture, repository, ledger_commit, "merge")
      run_git!(merge_repo, ["checkout", "-qb", "side"])
      write_repo_file!(merge_repo, ".planning/STATE.md", "side\n")
      commit_all!(merge_repo, "docs: unknown side")
      run_git!(merge_repo, ["checkout", "-q", "main"])
      write_repo_file!(merge_repo, ".planning/ROADMAP.md", "main\n")
      commit_all!(merge_repo, "docs: unknown main")
      run_git!(merge_repo, ["merge", "--no-ff", "-qm", "merge hostile history", "side"])
      assert_relation_refreshes!(merge_repo, ledger)

      external = Path.join(fixture, "external")
      {_, _} = build_snapshot_repository!(external, ledger, "expected-fingerprint")

      {external_output, external_status} =
        run_snapshot_relation!(external, ledger, [
          {"LOCKSPIRE_INVENTORY_TEST_GITHUB_FINGERPRINT", "drifted-fingerprint"}
        ])

      assert external_status != 0
      assert external_output =~ "refresh_required"
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_snapshot_relation_fail_closed! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-snapshot-relation-fail-closed-#{System.unique_integer([:positive])}"
      )

    repository = Path.join(fixture, "stable")
    ledger = "baseline.md"
    File.rm_rf!(fixture)

    try do
      {ledger_commit, base, linked} = build_git_snapshot_repository!(repository, ledger)

      before = relation_repository_state(repository, ledger)
      {first, 0} = run_snapshot_relation!(repository, ledger)
      {second, 0} = run_snapshot_relation!(repository, ledger)
      assert first == second
      assert first =~ "snapshot_relation: authorized_bookkeeping"
      assert relation_repository_state(repository, ledger) == before

      run_git!(repository, ["branch", "post-snapshot-branch", base])
      assert_relation_domain_refreshes!(repository, ledger, "branches")
      run_git!(repository, ["branch", "-D", "post-snapshot-branch"])

      run_git!(repository, ["branch", "-D", "snapshot-branch"])
      assert_relation_domain_refreshes!(repository, ledger, "branches")
      run_git!(repository, ["branch", "snapshot-branch", base])

      run_git!(repository, ["branch", "-f", "snapshot-branch", ledger_commit])
      assert_relation_domain_refreshes!(repository, ledger, "branches")
      run_git!(repository, ["branch", "-f", "snapshot-branch", base])

      run_git!(repository, ["tag", "post-snapshot-tag", base])
      assert_relation_domain_refreshes!(repository, ledger, "tags")
      run_git!(repository, ["tag", "-d", "post-snapshot-tag"])

      run_git!(repository, ["tag", "-d", "snapshot-tag"])
      assert_relation_domain_refreshes!(repository, ledger, "tags")
      run_git!(repository, ["tag", "snapshot-tag", base])

      run_git!(repository, ["tag", "-f", "snapshot-tag", ledger_commit])
      assert_relation_domain_refreshes!(repository, ledger, "tags")
      run_git!(repository, ["tag", "-f", "snapshot-tag", base])

      added_worktree = Path.join(fixture, "post-snapshot-worktree")
      run_git!(repository, ["worktree", "add", "--detach", added_worktree, base])
      assert_relation_domain_refreshes!(repository, ledger, "worktrees")
      run_git!(repository, ["worktree", "remove", "--force", added_worktree])

      run_git!(repository, ["worktree", "remove", "--force", linked])
      assert_relation_domain_refreshes!(repository, ledger, "worktrees")
      run_git!(repository, ["worktree", "add", "--detach", linked, base])

      moved_worktree = Path.join(fixture, "snapshot-worktree-moved")
      run_git!(repository, ["worktree", "move", linked, moved_worktree])
      assert_relation_domain_refreshes!(repository, ledger, "worktrees")
      run_git!(repository, ["worktree", "move", moved_worktree, linked])

      for {scenario, domain} <- [
            {"failed-branches", "branches"},
            {"malformed-branches", "branches"},
            {"failed-tags", "tags"},
            {"malformed-tags", "tags"},
            {"failed-worktrees", "worktrees"},
            {"malformed-worktrees", "worktrees"},
            {"failed-hash", "branches"},
            {"malformed-hash", "branches"},
            {"failed-status", "working_tree"},
            {"malformed-status", "working_tree"},
            {"malformed-status-header", "working_tree"}
          ] do
        {output, status} = run_snapshot_relation_with_git_failure!(repository, ledger, scenario)
        assert status != 0
        assert output =~ "#{domain}|unavailable|refresh_required"
        assert output =~ "snapshot_relation: refresh_required"
        refute output =~ "working_tree|clean|authorized_bookkeeping"
      end
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_lifecycle_transitions_fail_closed! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-lifecycle-transitions-fail-closed-#{System.unique_integer([:positive])}"
      )

    ledger = ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md"
    File.rm_rf!(fixture)

    try do
      source = Path.join(fixture, "source")
      {_ledger_commit, _base} = build_snapshot_repository!(source, ledger)
      append_authorized_lifecycle!(source)
      {authorized, 0} = run_snapshot_relation!(source, ledger)

      for class <-
            ~w(phase_summary clean_review passed_verification phase_completion transition_bookkeeping) do
        assert authorized =~ "class=#{class}"
      end

      reopened = Path.join(fixture, "reopened-completion-gap")
      build_snapshot_repository!(reopened, ledger)

      write_repo_file!(
        reopened,
        ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md",
        "---\nphase: #{@baseline_phase_number}-baseline-inventory-evidence-taxonomy\nstatus: gaps_found\n---\n# #{@baseline_phase_label}: Baseline Inventory Verification Report\n## Goal Achievement\nThe finalizer's completion boundary does not match the live GSD v1.13 phase.complete state transition.\nLive phase completion advances STATE to Phase #{@next_phase_number}/planning before the transition-owned worktree projection.\nUpdate completion and transition validation to the observed GSD v1.13 state machine, then re-run the live gate.\n"
      )

      commit_all!(reopened, "test: record live completion boundary gap")
      replace_snapshot_ledger!(reopened, ledger)
      write_valid_lifecycle_candidate!(reopened, "verification")
      commit_all!(reopened, @baseline_phase_commit_prefix <> "record passed verification")
      {reopened_output, 0} = run_snapshot_relation!(reopened, ledger)
      assert reopened_output =~ "class=passed_verification"

      reopened_authority = Path.join(fixture, "reopened-verification-authority-gap")
      build_snapshot_repository!(reopened_authority, ledger)

      write_repo_file!(
        reopened_authority,
        ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md",
        "---\nphase: #{@baseline_phase_number}-baseline-inventory-evidence-taxonomy\nstatus: gaps_found\n---\n# #{@baseline_phase_label}: Baseline Inventory Verification Report\n## Goal Achievement\nAggregate GitHub failure can retain a historical decoy without the complete original authority.\nThe finalizer's completion boundary does not match the live GSD v1.13 phase.complete state transition. — historical decoy only\nThe verification transition recognizes only the original four-gap predecessor, not the exact later completion-boundary gap report.\nThe freshly passed verification commit is fail-closed as unknown until the bounded predecessor contract is extended.\nAuthorize the exact completion-boundary gaps_found to passed transition and prove hostile variants remain rejected.\n"
      )

      commit_all!(reopened_authority, "test: record bounded verification authority gap")
      replace_snapshot_ledger!(reopened_authority, ledger)
      write_valid_lifecycle_candidate!(reopened_authority, "verification")

      commit_all!(
        reopened_authority,
        @baseline_phase_commit_prefix <> "record passed verification"
      )

      {authority_output, 0} = run_snapshot_relation!(reopened_authority, ledger)
      assert authority_output =~ "class=passed_verification"

      reopened_project = Path.join(fixture, "reopened-project-transition-gap")
      build_snapshot_repository!(reopened_project, ledger)

      write_repo_file!(
        reopened_project,
        ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md",
        "---\nphase: #{@baseline_phase_number}-baseline-inventory-evidence-taxonomy\nstatus: gaps_found\n---\n# #{@baseline_phase_label}: Baseline Inventory Verification Report\n## Goal Achievement\nThe post-transition validator requires a PROJECT current-focus line that the live v1.38 document does not contain.\nThe sealed receipt is valid, but its immutable completion parent cannot satisfy the modeled PROJECT precondition.\nBind PROJECT evolution to the live milestone heading, #{@baseline_phase_label} completion paragraph, Phase #{@next_phase_number} ownership sentence, and transition footer.\n"
      )

      commit_all!(reopened_project, "test: record live project transition gap")
      replace_snapshot_ledger!(reopened_project, ledger)
      write_valid_lifecycle_candidate!(reopened_project, "verification")

      commit_all!(
        reopened_project,
        @baseline_phase_commit_prefix <> "record passed verification"
      )

      {project_output, 0} = run_snapshot_relation!(reopened_project, ledger)
      assert project_output =~ "class=passed_verification"

      reopened_large_blob = Path.join(fixture, "reopened-large-project-gap")
      build_snapshot_repository!(reopened_large_blob, ledger)

      write_repo_file!(
        reopened_large_blob,
        ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md",
        "---\nphase: #{@baseline_phase_number}-baseline-inventory-evidence-taxonomy\nstatus: gaps_found\n---\n# #{@baseline_phase_label}: Baseline Inventory Verification Report\n## Goal Achievement\nThe post-transition receipt validator misclassifies an early PROJECT heading when grep -q closes a pipe under pipefail.\nThe sealed receipt and lifecycle semantics are valid, but blob_has_line returns the upstream git show SIGPIPE status.\nConsume complete blob output when matching lifecycle lines and prove large-document headings remain authorized.\n"
      )

      commit_all!(reopened_large_blob, "test: record large project blob gap")
      replace_snapshot_ledger!(reopened_large_blob, ledger)
      write_valid_lifecycle_candidate!(reopened_large_blob, "verification")

      commit_all!(
        reopened_large_blob,
        @baseline_phase_commit_prefix <> "record passed verification"
      )

      {large_blob_output, 0} = run_snapshot_relation!(reopened_large_blob, ledger)
      assert large_blob_output =~ "class=passed_verification"

      completion_delete = Path.join(fixture, "completion-delete")
      build_snapshot_repository!(completion_delete, ledger)
      File.rm!(Path.join(completion_delete, ".planning/STATE.md"))
      commit_all!(completion_delete, @baseline_phase_commit_prefix <> "complete phase execution")
      assert_relation_refreshes!(completion_delete, ledger)

      transition_replace = Path.join(fixture, "transition-replace")
      build_snapshot_repository!(transition_replace, ledger)
      write_repo_file!(transition_replace, ".planning/PROJECT.md", "Safe unrelated prose\n")
      write_repo_file!(transition_replace, ".planning/STATE.md", "Safe unrelated prose\n")

      commit_all!(
        transition_replace,
        @baseline_phase_commit_prefix <> "transition to phase " <> @next_phase_number
      )

      assert_relation_refreshes!(transition_replace, ledger)

      working_replace = Path.join(fixture, "working-replace")
      build_snapshot_repository!(working_replace, ledger)
      write_repo_file!(working_replace, ".planning/PROJECT.md", "Safe unrelated prose\n")
      write_repo_file!(working_replace, ".planning/STATE.md", "Safe unrelated prose\n")
      assert_relation_refreshes!(working_replace, ledger)

      for mode <- ~w(unstaged staged mixed) do
        working = Path.join(fixture, "working-#{mode}")
        build_snapshot_repository!(working, ledger)
        write_valid_lifecycle_candidate!(working, "summary")
        commit_all!(working, "docs(138-11): complete final ledger plan")
        write_valid_lifecycle_candidate!(working, "completion")
        commit_all!(working, @baseline_phase_commit_prefix <> "complete phase execution")
        write_valid_transition!(working)

        case mode do
          "staged" -> run_git!(working, ["add", ".planning/PROJECT.md", ".planning/STATE.md"])
          "mixed" -> run_git!(working, ["add", ".planning/PROJECT.md"])
          "unstaged" -> :ok
        end

        {output, 0} = run_snapshot_relation!(working, ledger)
        assert output =~ "working_tree|transition_bookkeeping|authorized_bookkeeping"
      end

      for class <- ~w(summary review verification completion transition),
          variant <-
            ~w(deletion empty rename type-change wrong-phase missing-heading arbitrary companion-arbitrary mixed-path) do
        repository = Path.join(fixture, "#{class}-#{variant}")
        build_snapshot_repository!(repository, ledger)
        write_valid_lifecycle_candidate!(repository, class)
        apply_lifecycle_near_miss!(repository, class, variant)
        commit_all!(repository, lifecycle_subject(class))
        {output, status} = run_snapshot_relation!(repository, ledger)
        assert status != 0, "#{class}-#{variant} was authorized:\n#{output}"
        assert output =~ "snapshot_relation: refresh_required"
      end

      companion_cases = [
        {"summary", "plan",
         ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-PLAN.md"},
        {"summary", "state", ".planning/STATE.md"},
        {"summary", "roadmap", ".planning/ROADMAP.md"},
        {"summary", "requirements", ".planning/REQUIREMENTS.md"},
        {"summary", "state-contract", ".planning/state.json"},
        {"completion", "roadmap", ".planning/ROADMAP.md"},
        {"completion", "requirements", ".planning/REQUIREMENTS.md"},
        {"completion", "verification",
         ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md"}
      ]

      Enum.each(companion_cases, fn {class, name, path} ->
        repository = Path.join(fixture, "#{class}-companion-#{name}")
        build_snapshot_repository!(repository, ledger)
        write_valid_lifecycle_candidate!(repository, class)
        write_repo_file!(repository, path, "Safe unrelated prose\n")
        commit_all!(repository, lifecycle_subject(class))
        {output, status} = run_snapshot_relation!(repository, ledger)
        assert status != 0, "#{class} #{name} companion was authorized:\n#{output}"
        assert output =~ "snapshot_relation: refresh_required"
      end)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_gsd_plan_closeout_transitions! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-gsd-plan-closeout-#{System.unique_integer([:positive])}"
      )

    ledger = ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md"
    File.rm_rf!(fixture)

    try do
      control = Path.join(fixture, "control")
      build_gsd_plan_closeout_repository!(control, ledger)
      write_valid_gsd_plan_closeout!(control)
      commit_all!(control, "docs(138-25): complete corrected immutable baseline plan")
      {output, 0} = run_snapshot_relation!(control, ledger)
      assert output =~ "class=gsd_plan_closeout"
      assert output =~ "snapshot_relation: authorized_bookkeeping"

      normalized_control = Path.join(fixture, "normalized-control")
      build_gsd_plan_closeout_repository!(normalized_control, ledger)
      write_valid_gsd_plan_closeout!(normalized_control)

      replace_closeout_summary!(
        normalized_control,
        "duration: 81min",
        "duration:   81min   "
      )

      replace_closeout_summary!(
        normalized_control,
        "    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md",
        "    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md\n" <>
          "    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-25-SUMMARY.md"
      )

      replace_gsd_closeout_state!(
        normalized_control,
        "| 81min | 2 tasks | 4 files |",
        "|   81min   | 2 tasks | 4 files |"
      )

      commit_all!(
        normalized_control,
        "docs(138-25): complete corrected immutable baseline plan"
      )

      {normalized_output, 0} = run_snapshot_relation!(normalized_control, ledger)
      assert normalized_output =~ "class=gsd_plan_closeout"
      assert normalized_output =~ "snapshot_relation: authorized_bookkeeping"

      variants = ~w(
        extra-path missing-state missing-state-json missing-roadmap wrong-phase wrong-plan
        failed-summary missing-self-check requirement-mismatch coverage-mismatch
        summary-body-requirements summary-body-coverage duplicate-requirements
        non-monotonic-progress unrelated-roadmap unrelated-state forged-lifecycle
        extra-checked-plan extra-phase-row extra-status-line extra-decision-line
        extra-performance-row replacement-decision duplicate-decisions
        summary-body-decisions replacement-performance-duration
        replacement-performance-tasks replacement-performance-files missing-duration
        duplicate-duration duplicate-actual-tasks duplicate-modified-files
      )

      Enum.each(variants, fn variant ->
        repository = Path.join(fixture, variant)
        build_gsd_plan_closeout_repository!(repository, ledger)
        write_valid_gsd_plan_closeout!(repository)
        apply_gsd_plan_closeout_near_miss!(repository, variant)
        commit_all!(repository, "docs(138-25): complete corrected immutable baseline plan")
        {near_output, status} = run_snapshot_relation!(repository, ledger)
        assert status != 0, "#{variant} was authorized:\n#{near_output}"
        assert near_output =~ "snapshot_relation: refresh_required"
      end)

      wrong_subject = Path.join(fixture, "wrong-subject")
      build_gsd_plan_closeout_repository!(wrong_subject, ledger)
      write_valid_gsd_plan_closeout!(wrong_subject)
      commit_all!(wrong_subject, "docs(138-24): complete corrected immutable baseline plan")
      assert_relation_refreshes!(wrong_subject, ledger)

      wrong_author = Path.join(fixture, "wrong-author")
      build_gsd_plan_closeout_repository!(wrong_author, ledger)
      write_valid_gsd_plan_closeout!(wrong_author)
      run_git!(wrong_author, ["add", "--all"])

      {_, 0} =
        System.cmd(
          "git",
          [
            "-c",
            "user.name=Different Author",
            "-c",
            "user.email=different@example.com",
            "commit",
            "-qm",
            "docs(138-25): complete corrected immutable baseline plan"
          ],
          cd: wrong_author,
          stderr_to_stdout: true,
          env: [
            {"GIT_AUTHOR_NAME", "Different Author"},
            {"GIT_AUTHOR_EMAIL", "different@example.com"}
          ]
        )

      assert_relation_refreshes!(wrong_author, ledger)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_138_preverify_relation! do
    fixture = unique_tmp_fixture("lockspire-preverify-relation")
    repository = Path.join(fixture, "repository")
    ledger = ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md"

    try do
      {_ledger_commit, _base} = build_snapshot_repository!(repository, ledger)
      review = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md"
      review_bytes = File.read!(Path.join(repository, review))
      review_sha256 = file_sha256(Path.join(repository, review))
      ledger_path = Path.join(repository, ledger)

      File.write!(
        ledger_path,
        File.read!(ledger_path)
        |> String.replace(
          "executed: \"no — inventory proposal only\"",
          "phase_review_status: \"consumed\"\nphase_review_sha256: \"#{review_sha256}\"\nexecuted: \"no — inventory proposal only\""
        )
      )

      run_git!(repository, ["add", ledger])

      run_git!(repository, [
        "commit",
        "--amend",
        "-qm",
        @baseline_phase_commit_prefix <> "publish pre-verification baseline inventory"
      ])

      before = relation_repository_state(repository, ledger)
      {output, 0} = run_preverify_relation!(repository, ledger)
      assert output =~ "relation_boundary|pre-verify|current"
      assert output =~ "review_receipt|consumed|#{review_sha256}"
      assert output =~ "snapshot_relation: authorized_bookkeeping"
      assert relation_repository_state(repository, ledger) == before

      File.write!(Path.join(repository, review), "forged review bytes\n")
      {drifted, drifted_status} = run_preverify_relation!(repository, ledger)
      assert drifted_status != 0
      assert drifted =~ "review_receipt|mismatch|refresh_required"
      assert drifted =~ "snapshot_relation: refresh_required"

      File.write!(Path.join(repository, review), review_bytes)
      write_valid_lifecycle_candidate!(repository, "summary")
      commit_all!(repository, "docs(138-11): complete final ledger plan")

      {stale, stale_status} = run_preverify_relation!(repository, ledger)
      assert stale_status != 0
      assert stale =~ "relation_boundary|pre-verify|refresh_required"
      assert stale =~ "snapshot_relation: refresh_required"
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_138_posttransition_relation! do
    fixture = unique_tmp_fixture("lockspire-posttransition-relation")
    repository = Path.join(fixture, "repository")
    ledger = ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md"
    gsd_tools = gsd_tools_path!()

    state_helper =
      Paths.path(
        "tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"
      )

    receipt_path = Path.join(repository, ".git/gsd-lifecycle/post-completion-finalizer.json")

    hooks = %{
      "activeHooks" => [
        %{
          "kind" => "step",
          "capId" => "lockspire-phase-finalizer",
          "ref" => %{"command" => "lockspire-finalize post-transition"},
          "onError" => "halt"
        }
      ]
    }

    try do
      build_snapshot_repository!(repository, ledger)
      append_pretransition_lifecycle!(repository, ledger)

      {begin_output, 0} =
        System.cmd("node", [state_helper, "begin", "138"],
          cd: repository,
          stderr_to_stdout: true
        )

      assert Jason.decode!(begin_output)["status"] == "preparing"
      write_valid_transition!(repository)

      hooks_path = Path.join(fixture, "hooks.json")
      File.write!(hooks_path, Jason.encode!(hooks))

      {seal_output, 0} =
        System.cmd("bash", ["-c", ~S(exec node "$STATE_HELPER" seal 138 < "$HOOKS_PATH")],
          cd: repository,
          env: [{"STATE_HELPER", state_helper}, {"HOOKS_PATH", hooks_path}],
          stderr_to_stdout: true
        )

      assert Jason.decode!(seal_output)["status"] == "pending"
      original_receipt = File.read!(receipt_path)
      before_head = Jason.decode!(original_receipt)["before"]["head"]
      local_writer = install_receipt_writer_fixture!(repository, gsd_tools)

      {output, 0} =
        run_posttransition_relation!(repository, ledger, [{"GSD_TOOLS", gsd_tools}])

      assert output =~ "relation_boundary|post-transition|receipt_authorized"
      assert output =~ "receipt_before_head|#{before_head}|authorized_bookkeeping"
      assert output =~ "snapshot_relation: authorized_bookkeeping"
      assert File.read!(receipt_path) == original_receipt

      File.write!(local_writer, File.read!(local_writer) <> "\nwriter drift\n")

      {writer_drift, writer_drift_status} =
        run_posttransition_relation!(repository, ledger, [{"GSD_TOOLS", gsd_tools}])

      assert writer_drift_status != 0
      assert writer_drift =~ "snapshot_relation: refresh_required"
      install_receipt_writer_fixture!(repository, gsd_tools)

      adversaries = [
        {"writer-descriptor",
         fn receipt ->
           put_in(receipt, ["writer", "workflow", "sha256"], String.duplicate("0", 64))
         end},
        {"transformation-digest",
         fn receipt ->
           put_in(receipt, ["transformation", "sha256"], String.duplicate("1", 64))
         end},
        {"allowed-path-order",
         fn receipt -> update_in(receipt, ["writer", "allowedPaths"], &Enum.reverse/1) end},
        {"allowed-path-removal",
         fn receipt -> update_in(receipt, ["writer", "allowedPaths"], &Enum.drop(&1, -1)) end},
        {"allowed-path-addition",
         fn receipt ->
           update_in(receipt, ["writer", "allowedPaths"], &(&1 ++ [".planning/EXTRA.md"]))
         end},
        {"hook-hash",
         fn receipt -> Map.put(receipt, "hooksSha256", String.duplicate("2", 64)) end},
        {"wrong-phase", fn receipt -> Map.put(receipt, "phase", "139") end},
        {"wrong-status", fn receipt -> Map.put(receipt, "status", "preparing") end}
      ]

      Enum.each(adversaries, fn {name, mutate} ->
        forged = original_receipt |> Jason.decode!() |> mutate.() |> Jason.encode!(pretty: true)
        File.write!(receipt_path, forged <> "\n")
        File.chmod!(receipt_path, 0o600)

        {rejected, status} =
          run_posttransition_relation!(repository, ledger, [{"GSD_TOOLS", gsd_tools}])

        assert status != 0, "#{name} receipt was authorized:\n#{rejected}"
        assert rejected =~ "snapshot_relation: refresh_required"
      end)

      File.write!(receipt_path, original_receipt)
      File.chmod!(receipt_path, 0o600)
      write_repo_file!(repository, "unexpected.txt", "unexpected post-seal dirt\n")

      {dirty_output, dirty_status} =
        run_posttransition_relation!(repository, ledger, [{"GSD_TOOLS", gsd_tools}])

      assert dirty_status != 0
      assert dirty_output =~ "snapshot_relation: refresh_required"
      File.rm!(Path.join(repository, "unexpected.txt"))

      credential = "AbCdEfGhIjKlMnOpQrStUvWxYz012345abcdef"
      hostile = original_receipt |> Jason.decode!() |> Map.put("status", credential)
      File.write!(receipt_path, Jason.encode!(hostile) <> "\n")
      File.chmod!(receipt_path, 0o600)

      {diagnostic, diagnostic_status} =
        run_posttransition_relation!(repository, ledger, [{"GSD_TOOLS", gsd_tools}])

      assert diagnostic_status != 0
      assert_no_raw_credential!(diagnostic, credential, "post-transition receipt diagnostic")
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_138_finalizer_contract! do
    fixture = unique_tmp_fixture("lockspire-phase-" <> @baseline_phase_number <> "-finalizer")
    repository = Path.join(fixture, "repository")

    ledger =
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"

    try do
      build_snapshot_repository!(repository, ledger)

      {premature, premature_status} = run_phase_138_finalizer!(repository, "pre-verify", [])
      assert premature_status != 0
      assert premature =~ "phase state is not executable"

      state = Path.join(repository, ".planning/STATE.md")

      File.write!(
        state,
        File.read!(state)
        |> String.replace("status: executing", "status: verifying")
        |> String.replace("Status: Ready to execute", "Status: Ready for phase verification")
      )

      commit_all!(repository, "docs: enter phase verification")
      remote = Path.join(fixture, "origin.git")
      {_, 0} = System.cmd("git", ["clone", "-q", "--bare", repository, remote])
      run_git!(repository, ["remote", "add", "origin", remote])

      bin = Path.join(fixture, "bin")
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "gh"), 0o755)

      env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_GH_SCENARIO", "zero-issues"}
      ]

      before = run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim()
      {first, 0} = run_phase_138_finalizer!(repository, "pre-verify", env)
      assert first =~ "relation_boundary|pre-verify|current"
      after_first = run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim()
      assert String.to_integer(after_first) == String.to_integer(before) + 1

      assert run_git!(repository, ["show", "-s", "--format=%s", "HEAD"]) |> String.trim() ==
               @baseline_phase_commit_prefix <> "publish pre-verification baseline inventory"

      assert run_git!(repository, ["diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"])
             |> String.trim() == ledger

      {second, 0} = run_phase_138_finalizer!(repository, "pre-verify", env)
      assert second =~ "snapshot_relation: authorized_bookkeeping"
      assert run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim() == after_first

      lock =
        Path.join(
          repository,
          ".git/phase-" <> @baseline_phase_number <> "-finalizer.lock"
        )

      File.mkdir!(lock)
      {locked, locked_status} = run_phase_138_finalizer!(repository, "pre-verify", env)
      assert locked_status != 0
      assert locked =~ "another pre-verify finalizer is active"
      File.rmdir!(lock)

      assert {_, status} = run_phase_138_finalizer!(repository, "post-transition", env)
      assert status != 0
      assert run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim() == after_first
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_139_inventory_relation! do
    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-inventory-relation")
    repository = Path.join(fixture, "repository")

    ledger =
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"

    try do
      {ledger_commit, evidence_base, remote} =
        build_phase_139_relation_repository!(fixture, repository, ledger)

      before = relation_repository_state(repository, ledger)
      {preverify, 0} = run_phase_139_preverify_relation!(repository, ledger)
      assert preverify =~ "relation_boundary|" <> @next_phase_slug <> "-preverify|current"
      assert preverify =~ "snapshot_relation: authorized_bookkeeping"
      assert relation_repository_state(repository, ledger) == before

      write_phase_139_verification!(repository)
      commit_all!(repository, @next_phase_commit_prefix <> "record passed verification")
      verification_commit = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
      write_phase_139_completion!(repository, verification_commit)
      commit_all!(repository, @next_phase_commit_prefix <> "complete phase execution")
      candidate = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

      gsd_tools = gsd_tools_path!()

      state_helper =
        Paths.path(
          "tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"
        )

      write_phase_139_transition!(repository)

      hooks = %{
        "activeHooks" => [
          %{
            "kind" => "gate",
            "capId" => "lockspire-phase-finalizer",
            "check" => %{
              "predicate" => %{
                "kind" => "command-exit-zero",
                "command" =>
                  ~S(test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139),
                "timeout" => 2400
              }
            },
            "blocking" => true,
            "onError" => "halt"
          }
        ]
      }

      hooks_path = Path.join(fixture, "hooks.json")
      File.write!(hooks_path, Jason.encode!(hooks))

      {_, 0} =
        System.cmd("bash", ["-c", ~S(exec node "$STATE_HELPER" prepare 139 < "$HOOKS_PATH")],
          cd: repository,
          env: [{"STATE_HELPER", state_helper}, {"HOOKS_PATH", hooks_path}],
          stderr_to_stdout: true
        )

      receipt_path = Path.join(repository, ".git/gsd-lifecycle/post-completion-finalizer.json")
      receipt = File.read!(receipt_path)
      install_receipt_writer_fixture!(repository, gsd_tools)
      run_git!(repository, ["update-ref", "refs/heads/main", candidate, evidence_base])
      run_git!(repository, ["push", "origin", "#{candidate}:refs/heads/main"])
      run_git!(repository, ["fetch", "origin", "main"])

      post_before = relation_repository_state(repository, ledger)
      {posttransition, 0} = run_phase_139_posttransition_relation!(repository, ledger)

      assert posttransition =~
               "relation_boundary|" <> @next_phase_slug <> "-posttransition|receipt_authorized"

      assert posttransition =~ "snapshot_relation: authorized_bookkeeping"
      assert relation_repository_state(repository, ledger) == post_before

      run_git!(repository, ["update-ref", "refs/heads/main", evidence_base, candidate])
      {one_sided, one_sided_status} = run_phase_139_posttransition_relation!(repository, ledger)
      assert one_sided_status != 0
      assert one_sided =~ "snapshot_relation: refresh_required"
      run_git!(repository, ["update-ref", "refs/heads/main", candidate, evidence_base])

      hostile_ref = "unexpected-" <> @next_phase_slug <> "-ref"
      run_git!(repository, ["branch", hostile_ref, ledger_commit])
      {extra_ref, extra_ref_status} = run_phase_139_posttransition_relation!(repository, ledger)
      assert extra_ref_status != 0
      assert extra_ref =~ "snapshot_relation: refresh_required"
      run_git!(repository, ["branch", "-D", hostile_ref])

      forged =
        receipt |> Jason.decode!() |> Map.put("phase", "138") |> Jason.encode!(pretty: true)

      File.write!(receipt_path, forged <> "\n")
      File.chmod!(receipt_path, 0o600)

      {wrong_receipt, wrong_receipt_status} =
        run_phase_139_posttransition_relation!(repository, ledger)

      assert wrong_receipt_status != 0
      assert wrong_receipt =~ "snapshot_relation: refresh_required"
      File.write!(receipt_path, receipt)
      File.chmod!(receipt_path, 0o600)

      assert run_git!(repository, ["ls-remote", remote, "refs/heads/main"])
             |> String.starts_with?(candidate)

      lifecycle_mutations = [
        {"completion-roadmap-forged-count",
         fn repository ->
           path = Path.join(repository, ".planning/ROADMAP.md")
           File.write!(path, File.read!(path) |> String.replace("9/9", "99/99"))
         end, fn _repository -> :ok end},
        {"completion-forged-state-count",
         fn repository ->
           path = Path.join(repository, ".planning/STATE.md")

           File.write!(
             path,
             File.read!(path) |> String.replace("completed_plans: 43", "completed_plans: 99")
           )
         end, fn _repository -> :ok end},
        {"completion-duplicate-valid-progress-row",
         fn repository ->
           path = Path.join(repository, ".planning/STATE.md")

           File.write!(
             path,
             File.read!(path)
             |> String.replace(
               "Progress: [█████░░░░░] 50%\n",
               "Progress: [█████░░░░░] 50%\nProgress: [█████░░░░░] 50%\n"
             )
           )
         end, fn _repository -> :ok end},
        {"completion-prefix-valid-incomplete-phase-row",
         fn repository ->
           path = Path.join(repository, ".planning/STATE.md")

           File.write!(
             path,
             File.read!(path)
             |> String.replace(
               "Phase: #{@action_phase_number}\n",
               "Phase: #{@action_phase_number} forged\n"
             )
           )
         end, fn _repository -> :ok end},
        {"completion-extra-prefixed-phase-row",
         fn repository ->
           path = Path.join(repository, ".planning/STATE.md")
           File.write!(path, File.read!(path) <> "Phase: #{@action_phase_number} forged\n")
         end, fn _repository -> :ok end},
        {"completion-extra-noncanonical-progress-row",
         fn repository ->
           path = Path.join(repository, ".planning/STATE.md")
           File.write!(path, File.read!(path) <> "Progress: 0%\n")
         end, fn _repository -> :ok end},
        {"completion-without-roadmap",
         fn repository ->
           write_repo_file!(
             repository,
             ".planning/ROADMAP.md",
             run_git!(repository, ["show", "HEAD:.planning/ROADMAP.md"])
           )
         end, fn _repository -> :ok end},
        {"completion-duplicate-requirement",
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/REQUIREMENTS.md"),
             "| CI-06 | #{@next_phase_label} | Complete |\n",
             [:append]
           )
         end, fn _repository -> :ok end},
        {"completion-partial-requirements",
         fn repository ->
           path = Path.join(repository, ".planning/REQUIREMENTS.md")

           File.write!(
             path,
             File.read!(path)
             |> String.replace("- [x] **TRUTH-05**: #{@next_phase_label} requirement.\n", "")
             |> String.replace("| TRUTH-05 | #{@next_phase_label} | Complete |\n", "")
           )
         end, fn _repository -> :ok end},
        {"completion-roadmap",
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/ROADMAP.md"),
             "Unrelated future roadmap rewrite.\n",
             [:append]
           )
         end, fn _repository -> :ok end},
        {"completion-requirements",
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/REQUIREMENTS.md"),
             "- [x] **UNRELATED-01**: Unauthorized requirement.\n",
             [:append]
           )
         end, fn _repository -> :ok end},
        {"completion-state",
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/STATE.md"),
             "Unrelated state mutation.\n",
             [:append]
           )
         end, fn _repository -> :ok end},
        {"completion-state-contract",
         fn repository ->
           write_repo_file!(
             repository,
             ".planning/state.json",
             Jason.encode!(%{"contract" => "rewritten"}) <> "\n"
           )
         end, fn _repository -> :ok end},
        {"transition-project", fn _repository -> :ok end,
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/PROJECT.md"),
             "Unrelated project mutation.\n",
             [:append]
           )
         end},
        {"transition-project-valid-shaped", fn _repository -> :ok end,
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/PROJECT.md"),
             "| Forged #{@next_phase_label} decision | plausible rationale | accepted |\n",
             [:append]
           )
         end},
        {"transition-state", fn _repository -> :ok end,
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/STATE.md"),
             "Unrelated transition state mutation.\n",
             [:append]
           )
         end},
        {"transition-state-valid-shaped", fn _repository -> :ok end,
         fn repository ->
           File.write!(
             Path.join(repository, ".planning/STATE.md"),
             "- [#{@next_phase_label}]: Forged but valid-shaped transition decision.\n",
             [:append]
           )
         end}
      ]

      Enum.each(lifecycle_mutations, fn {label, completion_mutate, transition_mutate} ->
        mutation_fixture = Path.join(fixture, label)

        context =
          build_sealed_phase_139_acceptance_fixture!(
            mutation_fixture,
            completion_mutate,
            transition_mutate
          )

        run_git!(context.repository, [
          "update-ref",
          "refs/heads/main",
          context.candidate,
          context.evidence_base
        ])

        run_git!(context.repository, ["push", "origin", "#{context.candidate}:refs/heads/main"])
        run_git!(context.repository, ["fetch", "origin", "main"])

        {rejected, rejected_status} =
          run_phase_139_posttransition_relation!(context.repository, context.receipt.ledger)

        assert rejected_status != 0, "#{label} was authorized:\n#{rejected}"
        assert rejected =~ "refresh_required"
      end)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_139_preverify_refresh! do
    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-preverify-refresh")
    repository = Path.join(fixture, "repository")

    ledger =
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"

    try do
      build_phase_139_finalizer_repository!(repository, ledger)
      remote = Path.join(fixture, "origin.git")
      {_, 0} = System.cmd("git", ["clone", "-q", "--bare", repository, remote])
      run_git!(repository, ["remote", "add", "origin", remote])

      bin = Path.join(fixture, "bin")
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "gh"), 0o755)

      env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_GH_SCENARIO", "zero-issues"}
      ]

      review =
        Path.join(
          repository,
          ".planning/phases/139-required-truth-reconciliation/139-REVIEW.md"
        )

      original_review = File.read!(review)
      File.write!(review, String.replace(original_review, "status: clean", "status: skipped"))
      before_review = run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim()
      {skipped, skipped_status} = run_phase_139_finalizer!(repository, "pre-verify", env)
      assert skipped_status != 0
      assert skipped =~ "code review is incomplete"

      assert run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim() ==
               before_review

      refute File.exists?(Path.join(repository, ledger))
      File.write!(review, original_review)

      state = Path.join(repository, ".planning/STATE.md")
      original_state = File.read!(state)
      File.write!(state, String.replace(original_state, "status: verifying", "status: executing"))
      {wrong_state, wrong_state_status} = run_phase_139_finalizer!(repository, "pre-verify", env)
      assert wrong_state_status != 0
      assert wrong_state =~ "phase state is not executable"
      File.write!(state, original_state)

      write_repo_file!(repository, "unexpected.txt", "dirty\n")
      {dirty, dirty_status} = run_phase_139_finalizer!(repository, "pre-verify", env)
      assert dirty_status != 0
      assert dirty =~ "working tree contains unrelated changes"
      File.rm!(Path.join(repository, "unexpected.txt"))

      before = run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim()
      {first, 0} = run_phase_139_finalizer!(repository, "pre-verify", env)
      assert first =~ "relation_boundary|" <> @next_phase_slug <> "-preverify|current"
      after_first = run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim()
      assert String.to_integer(after_first) == String.to_integer(before) + 1

      assert run_git!(repository, ["show", "-s", "--format=%s", "HEAD"]) |> String.trim() ==
               @next_phase_commit_prefix <> "refresh baseline inventory before verification"

      assert run_git!(repository, ["diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"])
             |> String.trim() == ledger

      assert File.read!(Path.join(repository, ledger)) =~
               "executed: \"no — inventory proposal only\""

      scratch_patterns = [".selector.*", ".included.*", ".record.*", ".rows.*", ".aggregated.*"]

      assert Enum.all?(scratch_patterns, fn pattern ->
               Path.wildcard(Path.join(repository, pattern), match_dot: true) == []
             end)

      {second, 0} = run_phase_139_finalizer!(repository, "pre-verify", env)
      assert second =~ "snapshot_relation: authorized_bookkeeping"
      assert run_git!(repository, ["rev-list", "--count", "HEAD"]) |> String.trim() == after_first

      assert Enum.all?(scratch_patterns, fn pattern ->
               Path.wildcard(Path.join(repository, pattern), match_dot: true) == []
             end)

      lock = Path.join(repository, ".git/" <> @next_phase_slug <> "-finalizer.lock")
      File.mkdir!(lock)
      {locked, locked_status} = run_phase_139_finalizer!(repository, "pre-verify", env)
      assert locked_status != 0
      assert locked =~ "another pre-verify finalizer is active"
      File.rmdir!(lock)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_139_final_acceptance! do
    script = Paths.read!("scripts/maintainer/finalize_phase_139_acceptance.sh")

    for helper <- [
          "resolve_sealed_candidate",
          "fast_forward_main",
          "verify_sealed_state_unchanged"
        ] do
      assert script =~ "#{helper}()"
    end

    assert script =~ "update-ref refs/heads/main \"$candidate\" \"$old_main\""
    assert script =~ "push origin \"$candidate:refs/heads/main\""
    assert script =~ "fetch --no-tags origin refs/heads/main:refs/remotes/origin/main"
    assert script =~ "--verify-" <> @next_phase_slug <> "-posttransition-relation"
    assert script =~ "trap cleanup EXIT"
    assert script =~ "trap 'on_signal 143' TERM"
    refute script =~ "--force"
    refute script =~ "push -f"
    refute script =~ "reset --hard"
    refute script =~ "checkout"
    refute script =~ " rebase"
    refute script =~ " commit --amend"
    refute script =~ "mix hex.publish"

    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-final-acceptance")

    try do
      %{repository: repository, remote: remote, candidate: candidate, receipt: receipt} =
        build_sealed_phase_139_acceptance_fixture!(fixture)

      before = relation_repository_state(repository, receipt.ledger)
      {output, 0} = run_phase_139_acceptance!(repository)

      assert output =~
               "relation_boundary|" <> @next_phase_slug <> "-posttransition|receipt_authorized"

      assert run_git!(repository, ["rev-parse", "refs/heads/main"]) |> String.trim() == candidate

      assert run_git!(repository, ["rev-parse", "refs/remotes/origin/main"]) |> String.trim() ==
               candidate

      assert run_git!(repository, ["ls-remote", remote, "refs/heads/main"])
             |> String.starts_with?(candidate)

      refute File.exists?(receipt.path)

      assert Map.drop(relation_repository_state(repository, receipt.ledger), [:refs]) ==
               Map.drop(before, [:refs])

      {retry_output, 0} = run_phase_139_acceptance!(repository)
      assert retry_output =~ "acceptance: already complete at #{candidate}"
      refute File.exists?(receipt.path)
    after
      File.rm_rf(fixture)
    end

    assert_phase_139_acceptance_failure!("wrong-receipt", fn context ->
      forged =
        context.receipt.bytes
        |> Jason.decode!()
        |> put_in(["after", "head"], String.duplicate("f", 40))
        |> Jason.encode!(pretty: true)

      File.write!(context.receipt.path, forged <> "\n")
      File.chmod!(context.receipt.path, 0o600)
    end)

    receipt_field_adversaries = [
      {"forged-writer",
       fn receipt ->
         put_in(receipt, ["writer", "workflow", "sha256"], String.duplicate("0", 64))
       end},
      {"forged-hook",
       fn receipt ->
         put_in(receipt, ["hooks", Access.at(0), "blocking"], false)
       end},
      {"forged-hook-digest",
       fn receipt ->
         Map.put(receipt, "hooksSha256", String.duplicate("1", 64))
       end},
      {"forged-transformation",
       fn receipt ->
         put_in(receipt, ["transformation", "sha256"], String.duplicate("2", 64))
       end},
      {"forged-before",
       fn receipt ->
         put_in(receipt, ["before", "project", "sha256"], String.duplicate("3", 64))
       end},
      {"forged-after",
       fn receipt ->
         put_in(receipt, ["after", "state", "sha256"], String.duplicate("4", 64))
       end},
      {"forged-lifecycle-point",
       fn receipt ->
         Map.put(receipt, "point", "verify:post")
       end}
    ]

    Enum.each(receipt_field_adversaries, fn {label, mutate} ->
      assert_phase_139_acceptance_failure!(label, fn context ->
        forged =
          context.receipt.bytes
          |> Jason.decode!()
          |> mutate.()
          |> Jason.encode!(pretty: true)

        File.write!(context.receipt.path, forged <> "\n")
        File.chmod!(context.receipt.path, 0o600)
      end)
    end)

    assert_phase_139_acceptance_failure!("dirty-transition", fn context ->
      write_repo_file!(context.repository, "unexpected.txt", "unsealed change\n")
    end)

    assert_phase_139_acceptance_failure!("missing-main", fn context ->
      run_git!(context.repository, ["update-ref", "-d", "refs/heads/main"])
    end)

    assert_phase_139_acceptance_failure!("non-fast-forward", fn context ->
      competing =
        run_git!(context.repository, [
          "commit-tree",
          context.evidence_base <> "^{tree}",
          "-p",
          context.evidence_base,
          "-m",
          "test: advance remote outside candidate"
        ])
        |> String.trim()

      run_git!(context.repository, ["push", "origin", "#{competing}:refs/heads/main"])
    end)

    assert_phase_139_acceptance_failure!("remote-rejection", fn context ->
      hook = Path.join(context.remote, "hooks/pre-receive")
      File.write!(hook, "#!/usr/bin/env bash\nexit 1\n")
      File.chmod!(hook, 0o755)
    end)

    assert_phase_139_acceptance_failure!("held-lock", fn context ->
      File.mkdir!(
        Path.join(context.repository, ".git/lockspire-" <> @next_phase_slug <> "-acceptance.lock")
      )
    end)

    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-linked-acceptance")

    try do
      context = build_sealed_phase_139_acceptance_fixture!(fixture)
      linked = Path.join(fixture, "linked")

      run_git!(context.repository, [
        "worktree",
        "add",
        "-q",
        "-b",
        "acceptance-linked",
        linked,
        context.candidate
      ])

      {output, status} = run_phase_139_acceptance!(linked)
      assert status != 0
      assert output =~ "linked worktrees cannot perform final acceptance"
      assert File.exists?(context.receipt.path)
    after
      File.rm_rf(fixture)
    end

    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-signal-acceptance")

    try do
      context = build_sealed_phase_139_acceptance_fixture!(fixture)
      barrier = Path.join(fixture, "acceptance-barrier")

      env =
        install_phase_139_acceptance_api_fixture!(fixture, context.candidate) ++
          [{"FAKE_ACCEPTANCE_BARRIER", barrier}]

      task = Task.async(fn -> run_phase_139_live_acceptance!(context.repository, env) end)
      wait_for_fixture_path!(barrier <> ".pid")

      {overlap, overlap_status} = run_phase_139_live_acceptance!(context.repository, env)
      assert overlap_status != 0
      assert overlap =~ "another final acceptance is active"

      pid = File.read!(barrier <> ".pid") |> String.trim()
      {_, 0} = System.cmd("kill", ["-TERM", pid])
      {_, signal_status} = Task.await(task, 5_000)
      assert signal_status == 143

      refute File.exists?(
               Path.join(
                 context.repository,
                 ".git/lockspire-" <> @next_phase_slug <> "-acceptance-v1.json"
               )
             )

      refute File.exists?(
               Path.join(
                 context.repository,
                 ".git/lockspire-" <> @next_phase_slug <> "-acceptance.lock"
               )
             )
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_139_acceptance_receipt! do
    script = Paths.read!("scripts/maintainer/finalize_phase_139_acceptance.sh")

    for helper <- [
          "wait_for_exact_acceptance",
          "verify_historical_release_chain",
          "write_live_receipt",
          "acceptance_receipt_matches_exact"
        ] do
      assert script =~ "#{helper}()"
    end

    assert script =~ "lockspire-" <> @next_phase_slug <> "-acceptance-v1.json"
    assert script =~ "--wait-seconds 1800 --format json"
    assert script =~ "supplemental_non_certifying"
    assert script =~ "src_dir_fd=directory_fd"
    assert script =~ "os.fsync(directory_fd)"
    assert script =~ "os.O_RDONLY | os.O_NOFOLLOW"
    refute script =~ "mix hex.publish"
    refute script =~ "gh workflow run"
    refute script =~ "curl -X"

    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-acceptance-receipt")

    try do
      context = build_sealed_phase_139_acceptance_fixture!(fixture)
      env = install_phase_139_acceptance_api_fixture!(fixture, context.candidate)
      before = relation_repository_state(context.repository, context.receipt.ledger)
      {output, 0} = run_phase_139_live_acceptance!(context.repository, env)
      assert output =~ "snapshot_relation: authorized_bookkeeping"

      receipt_path =
        Path.join(
          context.repository,
          ".git/lockspire-" <> @next_phase_slug <> "-acceptance-v1.json"
        )

      receipt_bytes = File.read!(receipt_path)
      receipt = Jason.decode!(receipt_bytes)

      assert Map.keys(receipt) == [
               "baseline_sha",
               "captured_at",
               "historical_release",
               "hygiene",
               "inventory_relation",
               "local_gate",
               "release_no_publish",
               "repository",
               "required_ci",
               "schema",
               "supplemental_oidf",
               "warn_dispositions"
             ]

      assert receipt["baseline_sha"] == context.candidate
      assert receipt["inventory_relation"] == %{"status" => "verified"}
      assert receipt["repository"] == "lockspire/fixture"
      assert receipt["historical_release"]["status"] == "verified"
      assert receipt["historical_release"]["version"] == "1.5.0"
      assert receipt["supplemental_oidf"]["required_gate"] == false
      assert File.stat!(receipt_path).mode |> Bitwise.band(0o777) == 0o600

      assert Map.drop(relation_repository_state(context.repository, context.receipt.ledger), [
               :refs
             ]) ==
               Map.drop(before, [:refs])

      {_, 0} = run_phase_139_live_acceptance!(context.repository, env)
      assert File.read!(receipt_path) == receipt_bytes

      retry_mutations = [
        {"different positive local test count",
         &put_in(&1, ["local_gate", "exunit_tests"], 1_944)},
        {"different positive required CI run ID", &put_in(&1, ["required_ci", "run_id"], 9_101)},
        {"different valid required CI URL",
         &put_in(&1, ["required_ci", "url"], "https://example.test/other-ci")},
        {"different valid WARN disposition",
         fn value ->
           value
           |> put_in(["hygiene", "warn"], 1)
           |> Map.put("warn_dispositions", [
             %{"label" => "package drift", "disposition" => "accepted"}
           ])
         end},
        {"nonpositive local test count", &put_in(&1, ["local_gate", "exunit_tests"], 0)},
        {"missing hygiene count",
         &update_in(&1, ["hygiene"], fn value -> Map.delete(value, "pass") end)},
        {"wrong required CI event", &put_in(&1, ["required_ci", "event"], "workflow_dispatch")},
        {"wrong required CI conclusion", &put_in(&1, ["required_ci", "conclusion"], "failure")},
        {"wrong required CI job graph", &put_in(&1, ["required_ci", "jobs"], [])},
        {"wrong release event",
         &put_in(&1, ["release_no_publish", "event"], "workflow_dispatch")},
        {"wrong release conclusion",
         &put_in(&1, ["release_no_publish", "conclusion"], "failure")},
        {"wrong release job graph", &put_in(&1, ["release_no_publish", "jobs"], [])},
        {"malformed captured timestamp", &Map.put(&1, "captured_at", "not-a-timestamp")},
        {"incomplete WARN dispositions",
         fn value ->
           value
           |> put_in(["hygiene", "warn"], 1)
           |> Map.put("warn_dispositions", [])
         end}
      ]

      Enum.each(retry_mutations, fn {label, mutate} ->
        malformed = receipt |> mutate.() |> Jason.encode!() |> Kernel.<>("\n")
        File.write!(receipt_path, malformed)
        File.chmod!(receipt_path, 0o600)
        {rejected, rejected_status} = run_phase_139_live_acceptance!(context.repository, env)
        assert rejected_status != 0, "#{label} unexpectedly passed: #{rejected}"
        assert File.read!(receipt_path) == malformed
      end)

      File.write!(receipt_path, receipt_bytes)
      File.chmod!(receipt_path, 0o644)
      {public, public_status} = run_phase_139_live_acceptance!(context.repository, env)
      assert public_status != 0, "public receipt unexpectedly passed: #{public}"
      assert File.read!(receipt_path) == receipt_bytes

      oversized = String.duplicate(" ", 1_048_577)
      File.write!(receipt_path, oversized)
      File.chmod!(receipt_path, 0o600)
      {large, large_status} = run_phase_139_live_acceptance!(context.repository, env)
      assert large_status != 0, "oversized receipt unexpectedly passed: #{large}"
      assert File.stat!(receipt_path).size == 1_048_577
    after
      File.rm_rf(fixture)
    end

    for scenario <- ["wrong-hygiene-sha", "historical-mismatch", "repository-race"] do
      fixture =
        unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-acceptance-" <> scenario)

      try do
        context = build_sealed_phase_139_acceptance_fixture!(fixture)
        env = install_phase_139_acceptance_api_fixture!(fixture, context.candidate, scenario)
        {output, status} = run_phase_139_live_acceptance!(context.repository, env)
        assert status != 0, "#{scenario} unexpectedly passed: #{output}"
        refute output =~ "fixture-credential-sentinel"

        refute File.exists?(
                 Path.join(
                   context.repository,
                   ".git/lockspire-" <> @next_phase_slug <> "-acceptance-v1.json"
                 )
               )

        assert File.exists?(context.receipt.path)
      after
        File.rm_rf(fixture)
      end
    end

    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-unsafe-acceptance-target")

    try do
      context = build_sealed_phase_139_acceptance_fixture!(fixture)
      env = install_phase_139_acceptance_api_fixture!(fixture, context.candidate)

      target =
        Path.join(
          context.repository,
          ".git/lockspire-" <> @next_phase_slug <> "-acceptance-v1.json"
        )

      sentinel = Path.join(fixture, "sentinel")
      File.write!(sentinel, "preserve\n")
      File.ln_s!(sentinel, target)
      {_, status} = run_phase_139_live_acceptance!(context.repository, env)
      assert status != 0
      assert File.read!(sentinel) == "preserve\n"
      assert File.exists?(context.receipt.path)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_phase_138_finalizer_recovery_contract! do
    fixture =
      unique_tmp_fixture("lockspire-phase-" <> @baseline_phase_number <> "-finalizer-recovery")

    repository = Path.join(fixture, "repository")

    ledger =
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"

    gsd_tools = gsd_tools_path!()

    state_helper =
      Paths.path(
        "tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"
      )

    receipt_path = Path.join(repository, ".git/gsd-lifecycle/post-completion-finalizer.json")

    hooks = %{
      "activeHooks" => [
        %{
          "kind" => "step",
          "capId" => "lockspire-phase-finalizer",
          "ref" => %{"command" => "lockspire-finalize post-transition"},
          "onError" => "halt"
        }
      ]
    }

    try do
      build_snapshot_repository!(repository, ledger)
      append_pretransition_lifecycle!(repository, ledger)
      {_, 0} = System.cmd("node", [state_helper, "begin", "138"], cd: repository)
      write_valid_transition!(repository)
      hooks_path = Path.join(fixture, "hooks.json")
      File.write!(hooks_path, Jason.encode!(hooks))

      {_, 0} =
        System.cmd("bash", ["-c", ~S(exec node "$STATE_HELPER" seal 138 < "$HOOKS_PATH")],
          cd: repository,
          env: [{"STATE_HELPER", state_helper}, {"HOOKS_PATH", hooks_path}]
        )

      receipt = File.read!(receipt_path)
      install_receipt_writer_fixture!(repository, gsd_tools)

      {preflight, preflight_status} =
        run_posttransition_relation!(repository, ledger, [{"GSD_TOOLS", gsd_tools}])

      assert preflight_status == 0, preflight

      forged =
        receipt
        |> Jason.decode!()
        |> put_in(["transformation", "sha256"], String.duplicate("0", 64))
        |> Jason.encode!(pretty: true)

      File.write!(receipt_path, forged <> "\n")
      File.chmod!(receipt_path, 0o600)
      head = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

      {failed, failed_status} =
        run_phase_138_finalizer!(repository, "post-transition", [{"GSD_TOOLS", gsd_tools}])

      assert failed_status != 0
      assert failed =~ "snapshot_relation: refresh_required"
      assert File.read!(receipt_path) == forged <> "\n"
      assert run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim() == head

      File.write!(receipt_path, receipt)
      File.chmod!(receipt_path, 0o600)

      {success, 0} =
        run_phase_138_finalizer!(repository, "post-transition", [{"GSD_TOOLS", gsd_tools}])

      assert success =~ "relation_boundary|post-transition|receipt_authorized"
      assert File.read!(receipt_path) == receipt
      assert run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim() == head
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_external_source_authority! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-external-source-authority-#{System.unique_integer([:positive])}"
      )

    ledger = "baseline.md"
    github_fingerprint = String.duplicate("a", 40)
    maintained_fingerprint = String.duplicate("b", 40)
    File.rm_rf!(fixture)

    try do
      github = Path.join(fixture, "github-unavailable")
      {_, _} = build_snapshot_repository!(github, ledger, github_fingerprint)

      {github_output, github_status} =
        run_snapshot_relation!(github, ledger, [
          {"LOCKSPIRE_INVENTORY_TEST_GITHUB_FINGERPRINT", github_fingerprint}
        ])

      assert github_status != 0, github_output
      assert github_output =~ "snapshot_relation: refresh_required"

      maintained = Path.join(fixture, "maintained-drifted")

      {_, _} =
        build_snapshot_repository!(
          maintained,
          ledger,
          "not_applicable",
          maintained_fingerprint
        )

      {maintained_output, maintained_status} =
        run_snapshot_relation!(maintained, ledger, [
          {"LOCKSPIRE_INVENTORY_TEST_MAINTAINED_FINGERPRINT", maintained_fingerprint}
        ])

      assert maintained_status != 0, maintained_output
      assert maintained_output =~ "snapshot_relation: refresh_required"

      Enum.each(~w(github maintained), fn scope ->
        live = Path.join(fixture, "live-#{scope}")
        {live_ledger, live_env} = build_live_source_snapshot_repository!(live, ledger, scope)
        {live_output, 0} = run_snapshot_relation!(live, live_ledger, live_env)
        assert live_output =~ "snapshot_relation: authorized_bookkeeping"
      end)

      lifecycle = Path.join(fixture, "maintained-lifecycle")
      build_snapshot_repository!(lifecycle, ledger)
      lifecycle_remote = lifecycle <> "-origin.git"
      {_, 0} = System.cmd("git", ["clone", "-q", "--bare", lifecycle, lifecycle_remote])
      run_git!(lifecycle, ["remote", "add", "origin", lifecycle_remote])
      lifecycle_output = Path.join(fixture, "maintained-lifecycle-ledger.md")

      {"", 0} =
        System.cmd(
          "bash",
          [
            Paths.path("scripts/maintainer/baseline_inventory.sh"),
            "--scope",
            "maintained",
            "--output",
            lifecycle_output
          ],
          cd: lifecycle,
          stderr_to_stdout: true
        )

      write_repo_file!(lifecycle, ledger, File.read!(lifecycle_output))
      commit_all!(lifecycle, "docs: publish immutable maintained lifecycle ledger")
      append_authorized_lifecycle!(lifecycle)
      {lifecycle_relation, 0} = run_snapshot_relation!(lifecycle, ledger)
      assert lifecycle_relation =~ "class=passed_verification"
      assert lifecycle_relation =~ "snapshot_relation: authorized_bookkeeping"

      script = File.read!(Paths.path("scripts/maintainer/baseline_inventory.sh"))
      refute script =~ "LOCKSPIRE_INVENTORY_TEST_GITHUB_FINGERPRINT"
      refute script =~ "LOCKSPIRE_INVENTORY_TEST_MAINTAINED_FINGERPRINT"
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_snapshot_commit_resolution! do
    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-snapshot-resolution-#{System.unique_integer([:positive])}"
      )

    ledger = ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md"

    try do
      replacement_repo = Path.join(fixture, "replacement")
      {old_ledger_commit, _base} = build_snapshot_repository!(replacement_repo, ledger)
      replacement_commit = replace_snapshot_ledger!(replacement_repo, ledger)

      {replacement_output, 0} = run_snapshot_relation!(replacement_repo, ledger)
      assert replacement_output =~ "ledger_commit|#{replacement_commit}|"
      refute replacement_output =~ "ledger_commit|#{old_ledger_commit}|"
      assert replacement_output =~ "snapshot_relation: authorized_bookkeeping"

      missing_repo = Path.join(fixture, "missing")
      initialize_snapshot_repository!(missing_repo)
      assert_relation_refreshes!(missing_repo, ledger)

      mixed_repo = Path.join(fixture, "mixed")
      mixed_base = initialize_snapshot_repository!(mixed_repo)
      write_snapshot_ledger!(mixed_repo, ledger, mixed_base, "mixed publication")
      write_repo_file!(mixed_repo, "unexpected.txt", "mixed with ledger publication\n")
      commit_all!(mixed_repo, "docs: publish mixed baseline ledger")
      assert_relation_refreshes!(mixed_repo, ledger)

      renamed_repo = Path.join(fixture, "renamed")
      renamed_base = initialize_snapshot_repository!(renamed_repo)
      legacy_ledger = ".planning/phases/138-baseline-inventory-evidence-taxonomy/legacy.md"
      write_snapshot_ledger!(renamed_repo, legacy_ledger, renamed_base, "legacy publication")
      commit_all!(renamed_repo, "docs: publish legacy baseline ledger")
      run_git!(renamed_repo, ["mv", legacy_ledger, ledger])
      commit_all!(renamed_repo, "docs: rename baseline ledger")
      assert_relation_refreshes!(renamed_repo, ledger)

      ambiguous_repo = Path.join(fixture, "ambiguous")
      ambiguous_base = initialize_snapshot_repository!(ambiguous_repo)
      run_git!(ambiguous_repo, ["checkout", "-qb", "candidate-a"])
      write_snapshot_ledger!(ambiguous_repo, ledger, ambiguous_base, "ambiguous publication")
      commit_all!(ambiguous_repo, "docs: publish candidate a")
      run_git!(ambiguous_repo, ["checkout", "-qb", "candidate-b", ambiguous_base])
      write_snapshot_ledger!(ambiguous_repo, ledger, ambiguous_base, "ambiguous publication")
      commit_all!(ambiguous_repo, "docs: publish candidate b")
      run_git!(ambiguous_repo, ["checkout", "-q", "candidate-a"])

      run_git!(ambiguous_repo, [
        "merge",
        "--no-ff",
        "-qm",
        "merge ambiguous ledgers",
        "candidate-b"
      ])

      run_git!(ambiguous_repo, ["branch", "-M", "main"])

      {ambiguous_output, ambiguous_status} =
        run_snapshot_relation!(ambiguous_repo, ledger)

      assert ambiguous_status != 0
      assert ambiguous_output =~ "reason: ledger commit ambiguous"
      assert ambiguous_output =~ "snapshot_relation: refresh_required"
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_relation_integrity_gaps! do
    assert_baseline_inventory_snapshot_relation_fail_closed!()
    assert_baseline_inventory_lifecycle_transitions_fail_closed!()

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-relation-integrity-gaps-#{System.unique_integer([:positive])}"
      )

    ledger = "baseline.md"
    File.rm_rf!(fixture)

    try do
      control = Path.join(fixture, "control")
      {_ledger_commit, _base, _linked} = build_git_snapshot_repository!(control, ledger)
      {control_output, 0} = run_snapshot_relation!(control, ledger)
      assert control_output =~ "snapshot_relation: authorized_bookkeeping"

      required_fields = ~w(
        phase scope status collection_started_at collection_finished_at repository
        repository_identity declared_source_scopes local_head_sha evidence_base_sha
        local_main_sha origin_main_sha git_receipt_fingerprint github_receipt_fingerprint
        maintained_receipt_fingerprint executed
      )

      missing_field_variants =
        Enum.map(required_fields, fn field ->
          {"missing-#{field}", &String.replace(&1, ~r/^#{field}:.*\n/m, "")}
        end)

      variants =
        missing_field_variants ++
          [
            {"duplicate-phase", &String.replace(&1, "phase: 138\n", "phase: 138\nphase: 138\n")},
            {"unterminated",
             &String.replace(&1, ~r/^---\n\n# Git baseline/m, "\n# Git baseline")},
            {"partial", &String.replace(&1, ~r/^status: \"complete\"$/m, ~s(status: "partial"))},
            {"wrong-repository",
             &String.replace(&1, ~r/^repository:.*$/m, ~s(repository: "/tmp/forged"))},
            {"invalid-sha",
             &String.replace(&1, ~r/^local_head_sha:.*$/m, ~s(local_head_sha: "bad"))},
            {"invalid-digest",
             &String.replace(
               &1,
               ~r/^git_receipt_fingerprint:.*$/m,
               ~s(git_receipt_fingerprint: "bad")
             )},
            {"implicit-na",
             &String.replace(
               &1,
               ~r/^git_receipt_fingerprint:.*$/m,
               ~s(git_receipt_fingerprint: "not_applicable")
             )},
            {"missing-maintained",
             fn body ->
               body
               |> String.replace(~r/^scope:.*$/m, ~s(scope: ""))
               |> String.replace(
                 ~r/^declared_source_scopes:.*$/m,
                 ~s(declared_source_scopes: "git-baseline,git,github,maintained")
               )
               |> String.replace(
                 ~r/^github_receipt_fingerprint:.*$/m,
                 ~s(github_receipt_fingerprint: "#{String.duplicate("a", 40)}")
               )
             end}
          ]

      Enum.each(variants, fn {name, mutate} ->
        repository = Path.join(fixture, name)
        initialize_snapshot_repository!(repository)
        base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
        body = File.read!(Path.join(control, ledger))
        body = String.replace(body, ~r/^evidence_base_sha:.*$/m, "evidence_base_sha: \"#{base}\"")
        body = String.replace(body, ~r/^local_head_sha:.*$/m, "local_head_sha: \"#{base}\"")
        body = String.replace(body, ~r/^local_main_sha:.*$/m, "local_main_sha: \"#{base}\"")

        body =
          String.replace(body, ~r/^repository:.*$/m, ~s(repository: "#{repository}"),
            global: false
          )

        body =
          String.replace(
            body,
            ~r/^repository_identity:.*$/m,
            ~s(repository_identity: "#{repository}")
          )

        body = mutate.(body)
        write_repo_file!(repository, ledger, body)
        commit_all!(repository, "docs: publish forged baseline ledger")
        assert_relation_refreshes!(repository, ledger)
      end)
    after
      File.rm_rf(fixture)
    end
  end

  def assert_baseline_inventory_currentness_instructions! do
    assert {:ok, output} = run_complete_inventory_fixture!()

    assert output =~ ~r/^status: "complete"$/m
    assert output =~ "| Git branches | complete |"
    assert output =~ "| Git tags | complete |"
    assert output =~ "| Git worktrees | complete |"
    assert output =~ "| GitHub open queues | complete |"
    assert output =~ "| Maintained follow-up families | complete |"
    assert output =~ "## Post-snapshot currentness relation"

    assert output =~
             "This ledger is an immutable snapshot bounded as of `"

    assert output =~
             "it does not claim to represent a later HEAD or pre-authorize later lifecycle writes."

    assert output =~
             "bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation"

    assert output =~ "authorized_bookkeeping"
    assert output =~ "refresh_required"
    assert output =~ "start of Phases " <> @next_phase_number <> " and " <> @action_phase_number
    assert output =~ "immediately before any " <> @action_phase_label <> " mutation"
    assert output =~ @closure_phase_label <> " exact-SHA closure"
    assert output =~ "read-only"
    assert output =~ "proposal-only"
  end

  defp build_snapshot_repository!(
         repository,
         ledger,
         github_fingerprint \\ "not_applicable",
         maintained_fingerprint \\ "not_applicable"
       ) do
    initialize_snapshot_repository!(repository)

    write_repo_file!(
      repository,
      ".planning/PROJECT.md",
      "# Lockspire\n## Current Milestone: v1.38 Repository Baseline & Reconciliation\n**Current focus:** " <>
        @baseline_phase_label <>
        " — Baseline Inventory & Evidence Taxonomy\n" <>
        String.duplicate(
          "Historical project context remains outside lifecycle authority.\n",
          8_192
        )
    )

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: 138\nstatus: executing\n---\n# Project State\n## Current Position\nPhase: 138\nStatus: Ready to execute\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\nPhase 138 in progress\n"
    )

    write_repo_file!(repository, ".planning/REQUIREMENTS.md", "# Requirements\nBASE-01 pending\n")

    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-SUMMARY.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nplan: \"11\"\nstatus: draft\n---\n# Draft Summary\n"
    )

    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nstatus: issues_found\n---\n# " <>
        @baseline_phase_label <> ": Code Review Report\n## Findings\nOpen findings.\n"
    )

    verification = ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md"

    write_repo_file!(
      repository,
      verification,
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nstatus: gaps_found\n---\n# " <>
        @baseline_phase_label <>
        ": Baseline Inventory Verification Report\n## Goal Achievement\nAggregate GitHub failure can retain\nCapture immutable baseline refs before all collection\nID-generation failure silently drops\nUse NUL-delimited Git output\n"
    )

    for plan <- ~w(07 08 09 10) do
      write_repo_file!(
        repository,
        ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-#{plan}-SUMMARY.md",
        "---\nstatus: complete\n---\nCompleted gap plan.\n"
      )
    end

    commit_all!(repository, "feat: evidence base")
    base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    write_snapshot_ledger!(
      repository,
      ledger,
      base,
      "immutable ledger",
      github_fingerprint,
      maintained_fingerprint
    )

    commit_all!(repository, "docs: publish immutable baseline ledger")
    {run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim(), base}
  end

  defp build_phase_139_relation_repository!(fixture, repository, ledger) do
    initialize_snapshot_repository!(repository)

    write_repo_file!(
      repository,
      ".planning/PROJECT.md",
      "# Lockspire\n## Current Milestone: v1.38 Repository Baseline & Reconciliation\n## Current State\n#{@baseline_phase_label} completed the v1.38 evidence foundation. #{@next_phase_label} now owns required truth reconciliation.\n---\n*Last updated: 2026-09-11 after #{@baseline_phase_label}*\n"
    )

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: #{@next_phase_number}\ncurrent_phase_name: Required Truth Reconciliation\nstatus: verifying\nstopped_at: Completed #{@next_phase_number}-09-PLAN.md\nlast_updated: \"2026-09-12T00:40:28.686Z\"\nlast_activity_desc: #{@next_phase_label} execution started\nstate_head: prior\nprogress:\n  total_phases: 4\n  completed_phases: 1\n  total_plans: 43\n  completed_plans: 43\n  percent: 25\n---\n# Project State\n## Project Reference\nSee: .planning/PROJECT.md\n**Current focus:** #{@next_phase_label} — Required Truth Reconciliation\n## Current Position\nPhase: #{@next_phase_number}\nPlan: 9 of 9\nStatus: Phase complete — ready for verification\nLast activity: 2026-09-11 — #{@next_phase_label} execution started\nProgress: [███░░░░░░░] 25%\n## Session Continuity\nLast session: 2026-09-12T00:40:28.652Z\nStopped at: Completed #{@next_phase_number}-09-PLAN.md\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\n- [ ] **#{@next_phase_label}: Required Truth Reconciliation** - Reconcile required truth.\n\n| Phase | Plans Complete | Status | Completed |\n|-------|----------------|--------|-----------|\n| #{@next_phase_number}. Required Truth Reconciliation | 9/9 | In Progress|  |\n"
    )

    write_repo_file!(
      repository,
      ".planning/REQUIREMENTS.md",
      phase_139_requirements_fixture("Pending")
    )

    historical =
      "source 5d10ce2219c2e687cf9573c8b280abfb118a47d8 ci 33141161205 release 33141484467 " <>
        "version 1.5.0 checksum 30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de " <>
        "tag lockspire-v1.5.0\n"

    write_repo_file!(
      repository,
      ".planning/RELEASE-TRAIN.md",
      "# Lockspire Release Train\n" <> historical
    )

    write_repo_file!(repository, ".planning/MILESTONES.md", "# Milestones\n" <> historical)

    write_repo_file!(
      repository,
      ".planning/phases/139-required-truth-reconciliation/139-REVIEW.md",
      "---\nphase: #{@next_phase_number}-required-truth-reconciliation\nstatus: clean\n---\n# #{@next_phase_label}: Code Review Report\n## Summary\nNo findings.\n"
    )

    commit_all!(repository, @next_phase_commit_prefix <> "record clean code review")
    evidence_base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    remote = Path.join(fixture, "origin.git")
    {_, 0} = System.cmd("git", ["clone", "-q", "--bare", repository, remote])
    run_git!(repository, ["remote", "add", "origin", remote])
    run_git!(repository, ["fetch", "-q", "origin", "main"])
    run_git!(repository, ["switch", "-q", "-c", @next_phase_slug])
    candidate = Path.join(fixture, @next_phase_slug <> "-ledger.md")

    {output, 0} =
      System.cmd(
        "bash",
        [
          Paths.path("scripts/maintainer/baseline_inventory.sh"),
          "--scope",
          "git",
          "--output",
          candidate
        ],
        cd: repository,
        env: [{"LOCKSPIRE_INVENTORY_REVIEW_PHASE", "139"}],
        stderr_to_stdout: true
      )

    assert output == ""
    write_repo_file!(repository, ledger, File.read!(candidate))

    commit_all!(
      repository,
      @next_phase_commit_prefix <> "refresh baseline inventory before verification"
    )

    ledger_commit = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    {ledger_commit, evidence_base, remote}
  end

  defp build_sealed_phase_139_acceptance_fixture!(
         fixture,
         completion_mutate \\ fn _repository -> :ok end,
         transition_mutate \\ fn _repository -> :ok end
       ) do
    repository = Path.join(fixture, "repository")

    ledger =
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"

    {_ledger_commit, evidence_base, remote} =
      build_phase_139_relation_repository!(fixture, repository, ledger)

    write_phase_139_verification!(repository)
    commit_all!(repository, @next_phase_commit_prefix <> "record passed verification")
    verification_commit = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    write_phase_139_completion!(repository, verification_commit)
    completion_mutate.(repository)
    commit_all!(repository, @next_phase_commit_prefix <> "complete phase execution")
    candidate = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    gsd_tools = gsd_tools_path!()

    state_helper =
      Paths.path(
        "tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"
      )

    write_phase_139_transition!(repository)
    transition_mutate.(repository)

    hooks = %{
      "activeHooks" => [
        %{
          "kind" => "gate",
          "capId" => "lockspire-phase-finalizer",
          "check" => %{
            "predicate" => %{
              "kind" => "command-exit-zero",
              "command" =>
                ~S(test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139),
              "timeout" => 2400
            }
          },
          "blocking" => true,
          "onError" => "halt"
        }
      ]
    }

    hooks_path = Path.join(fixture, "hooks.json")
    File.write!(hooks_path, Jason.encode!(hooks))

    {_, 0} =
      System.cmd("bash", ["-c", ~S(exec node "$STATE_HELPER" prepare "$PHASE" < "$HOOKS_PATH")],
        cd: repository,
        env: [
          {"STATE_HELPER", state_helper},
          {"PHASE", @next_phase_number},
          {"HOOKS_PATH", hooks_path}
        ],
        stderr_to_stdout: true
      )

    receipt_path = Path.join(repository, ".git/gsd-lifecycle/post-completion-finalizer.json")
    receipt = File.read!(receipt_path)
    install_receipt_writer_fixture!(repository, gsd_tools)

    %{
      repository: repository,
      remote: remote,
      evidence_base: evidence_base,
      candidate: candidate,
      receipt: %{path: receipt_path, bytes: receipt, ledger: ledger}
    }
  end

  defp run_phase_139_acceptance!(repository, env \\ []) do
    candidate = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    fixture_env =
      install_phase_139_acceptance_api_fixture!(Path.dirname(repository), candidate)

    System.cmd(
      "bash",
      [
        phase_139_acceptance_driver_path(repository),
        "post-transition",
        "--phase",
        @next_phase_number
      ],
      cd: repository,
      env: fixture_env ++ env,
      stderr_to_stdout: true
    )
  end

  defp run_phase_139_live_acceptance!(repository, env) do
    System.cmd(
      "bash",
      [
        phase_139_acceptance_driver_path(repository),
        "post-transition",
        "--phase",
        @next_phase_number
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp phase_139_acceptance_driver_path(repository) do
    Path.join([
      Path.dirname(repository),
      "acceptance-driver",
      "finalize_phase_139_acceptance.sh"
    ])
  end

  defp wait_for_fixture_path!(path, attempts \\ 400)

  defp wait_for_fixture_path!(path, attempts) when attempts > 0 do
    if File.exists?(path) do
      :ok
    else
      Process.sleep(50)
      wait_for_fixture_path!(path, attempts - 1)
    end
  end

  defp wait_for_fixture_path!(path, 0), do: flunk("timed out waiting for fixture path #{path}")

  defp install_phase_139_acceptance_api_fixture!(fixture, candidate, scenario \\ "success") do
    bin = Path.join(fixture, "acceptance-bin")
    driver = Path.join(fixture, "acceptance-driver")
    File.mkdir_p!(bin)
    File.mkdir_p!(driver)
    finalizer = Path.join(driver, "finalize_phase_139_acceptance.sh")
    inventory = Path.join(driver, "baseline_inventory.sh")
    hygiene = Path.join(driver, "repo_hygiene_check.sh")
    gh = Path.join(bin, "gh")
    curl = Path.join(bin, "curl")

    File.cp!(Paths.path("scripts/maintainer/finalize_phase_139_acceptance.sh"), finalizer)
    File.cp!(Paths.path("scripts/maintainer/baseline_inventory.sh"), inventory)

    File.write!(
      hygiene,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      if [[ -n "${FAKE_ACCEPTANCE_BARRIER:-}" ]]; then
        printf '%s\n' "$PPID" > "${FAKE_ACCEPTANCE_BARRIER}.pid"
        sleep 1
      fi
      candidate="$2"
      receipt_sha="$candidate"
      [[ "${FAKE_ACCEPTANCE_SCENARIO:-success}" != "wrong-hygiene-sha" ]] || receipt_sha="ffffffffffffffffffffffffffffffffffffffff"
      jq -cn --arg sha "$receipt_sha" --arg phase "#{@next_phase_number}" '{
        schema:("lockspire-phase-" + $phase + "-acceptance-v1"),baseline_sha:$sha,
        local_gate:{status:"pass",exunit_tests:1943},
        hygiene:{status:"pass",pass:12,warn:0,block:0},
        required_ci:{status:"pass",run_id:9001,event:"push",conclusion:"success",url:"https://example.test/ci",jobs:[
          {name:"Dialyzer",status:"completed",conclusion:"success"},
          {name:"Release Hygiene Drift",status:"completed",conclusion:"success"},
          {name:"Fast Checks",status:"completed",conclusion:"success"},
          {name:"Minimum Supported Elixir/OTP",status:"completed",conclusion:"success"},
          {name:"Integration Checks",status:"completed",conclusion:"success"},
          {name:"Complete Coverage Evidence",status:"completed",conclusion:"success"},
          {name:"Adoption Demo Smoke",status:"completed",conclusion:"success"}
        ]},
        release_no_publish:{status:"pass",outcome:"no_publish",run_id:9002,event:"push",conclusion:"success",url:"https://example.test/release",jobs:[
          {name:"Maintain Release Please PR",status:"completed",conclusion:"success"},
          {name:"Validate exact main head and CI evidence",status:"completed",conclusion:"skipped"},
          {name:"Prove exact package before publication",status:"completed",conclusion:"skipped"},
          {name:"Publish verified release to Hex",status:"completed",conclusion:"skipped"},
          {name:"Verify public install truth",status:"completed",conclusion:"skipped"}
        ]},
        warn_dispositions:[],
        supplemental_oidf:{classification:"supplemental_non_certifying",required_gate:false}
      }'
      if [[ "${FAKE_ACCEPTANCE_SCENARIO:-success}" == "repository-race" ]]; then
        tree="$(git rev-parse "$candidate^{tree}")"
        competing="$(printf 'race after exact acceptance\n' | git commit-tree "$tree" -p "$candidate")"
        git --git-dir="$FAKE_ACCEPTANCE_REMOTE" update-ref refs/heads/main "$competing" "$candidate"
      fi
      """
    )

    File.write!(
      gh,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      source_sha="5d10ce2219c2e687cf9573c8b280abfb118a47d8"
      case "$1 $2" in
        "repo view") printf 'lockspire/fixture\n' ;;
        "api repos/lockspire/fixture/actions/runs/33141161205")
          jq -cn --arg sha "$source_sha" '{id:33141161205,head_sha:$sha,event:"push",status:"completed",conclusion:"success"}' ;;
        "api repos/lockspire/fixture/actions/runs/33141484467")
          [[ "${FAKE_ACCEPTANCE_SCENARIO:-success}" != "historical-mismatch" ]] || source_sha="ffffffffffffffffffffffffffffffffffffffff"
          jq -cn --arg sha "$source_sha" '{id:33141484467,head_sha:$sha,event:"workflow_dispatch",status:"completed",conclusion:"success"}' ;;
        "api repos/lockspire/fixture/releases/tags/lockspire-v1.5.0")
          jq -cn --arg sha "$source_sha" '{tag_name:"lockspire-v1.5.0",target_commitish:$sha}' ;;
        *) exit 17 ;;
      esac
      """
    )

    File.write!(
      curl,
      """
      #!/usr/bin/env bash
      set -euo pipefail
      jq -cn '{version:"1.5.0",checksum:"30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de"}'
      """
    )

    for path <- [finalizer, inventory, hygiene, gh, curl], do: File.chmod!(path, 0o755)

    [
      {"PATH", bin <> ":" <> System.get_env("PATH", "")},
      {"FAKE_ACCEPTANCE_SCENARIO", scenario},
      {"FAKE_ACCEPTANCE_REMOTE", Path.join(fixture, "origin.git")},
      {"FAKE_ACCEPTANCE_CANDIDATE", candidate}
    ]
  end

  defp assert_phase_139_acceptance_failure!(label, mutate) do
    fixture = unique_tmp_fixture("lockspire-" <> @next_phase_slug <> "-acceptance-" <> label)

    try do
      context = build_sealed_phase_139_acceptance_fixture!(fixture)
      mutate.(context)
      expected_receipt = File.read!(context.receipt.path)
      before_refs = relation_repository_state(context.repository, context.receipt.ledger).refs

      before_advertised =
        run_git!(context.repository, ["ls-remote", context.remote, "refs/heads/main"])

      {output, status} = run_phase_139_acceptance!(context.repository)
      assert status != 0, "#{label} unexpectedly passed: #{output}"
      assert File.read!(context.receipt.path) == expected_receipt
      refute output =~ "fixture-credential-sentinel"

      if String.starts_with?(label, "forged-") do
        assert relation_repository_state(context.repository, context.receipt.ledger).refs ==
                 before_refs

        assert run_git!(context.repository, ["ls-remote", context.remote, "refs/heads/main"]) ==
                 before_advertised
      end

      if label != "held-lock" do
        refute File.exists?(
                 Path.join(
                   context.repository,
                   ".git/lockspire-" <> @next_phase_slug <> "-acceptance.lock"
                 )
               )
      end
    after
      File.rm_rf(fixture)
    end
  end

  defp build_phase_139_finalizer_repository!(repository, ledger) do
    initialize_snapshot_repository!(repository)

    write_repo_file!(
      repository,
      ".planning/PROJECT.md",
      "# Lockspire\n## Current Milestone: v1.38 Repository Baseline & Reconciliation\n"
    )

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: 139\ncurrent_phase_name: Required Truth Reconciliation\nstatus: verifying\n---\n# Project State\n## Current Position\nPhase: 139\nStatus: Phase complete — ready for verification\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\nRepository lifecycle record.\n"
    )

    write_repo_file!(
      repository,
      ".planning/REQUIREMENTS.md",
      "# Requirements\nHYGIENE-05 pending\n"
    )

    for plan <- ~w(01 02 03 04 05 06 07) do
      write_repo_file!(
        repository,
        ".planning/phases/139-required-truth-reconciliation/139-#{plan}-SUMMARY.md",
        "---\nphase: #{@next_phase_number}-required-truth-reconciliation\nplan: \"#{plan}\"\nstatus: complete\n---\n# #{@next_phase_label} Plan #{plan} Summary\n## Self-Check: PASSED\n"
      )
    end

    write_repo_file!(
      repository,
      ".planning/phases/139-required-truth-reconciliation/139-REVIEW.md",
      "---\nphase: #{@next_phase_number}-required-truth-reconciliation\nstatus: clean\n---\n# #{@next_phase_label}: Code Review Report\n## Summary\nNo findings.\n"
    )

    File.mkdir_p!(Path.dirname(Path.join(repository, ledger)))
    commit_all!(repository, @next_phase_commit_prefix <> "enter verification")
  end

  defp write_phase_139_verification!(repository) do
    write_repo_file!(
      repository,
      ".planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md",
      "---\nphase: #{@next_phase_number}-required-truth-reconciliation\nstatus: passed\ngaps: []\nbehavior_unverified: 0\nhuman_needed: false\n---\n# #{@next_phase_label}: Required Truth Reconciliation Verification Report\n## Goal Achievement\nPassed.\n"
    )
  end

  defp write_phase_139_completion!(repository, parent) do
    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: #{@action_phase_number}\ncurrent_phase_name: Bounded Operational Loose-End Triage\nstatus: planning\nstopped_at: #{@next_phase_label} complete, ready to plan #{@action_phase_label}\nlast_updated: \"2026-09-12T01:00:00.000Z\"\nlast_activity_desc: #{@next_phase_label} complete, transitioned to #{@action_phase_label}\nstate_head: #{parent}\nprogress:\n  total_phases: 4\n  completed_phases: 2\n  total_plans: 43\n  completed_plans: 43\n  percent: 50\n---\n# Project State\n## Project Reference\nSee: .planning/PROJECT.md\n**Current focus:** #{@next_phase_label} — Required Truth Reconciliation\n## Current Position\nPhase: #{@action_phase_number}\nPlan: Not started\nStatus: Ready to plan\nLast activity: 2026-09-12 — #{@next_phase_label} complete, transitioned to #{@action_phase_label}\nProgress: [█████░░░░░] 50%\n## Session Continuity\nLast session: 2026-09-12T00:40:28.652Z\nStopped at: #{@next_phase_label} complete, ready to plan #{@action_phase_label}\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\n- [x] **#{@next_phase_label}: Required Truth Reconciliation** - Reconcile required truth. (completed 2026-09-12)\n\n| Phase | Plans Complete | Status | Completed |\n|-------|----------------|--------|-----------|\n| #{@next_phase_number}. Required Truth Reconciliation | 9/9 | Complete    | 2026-09-12 |\n"
    )

    write_repo_file!(
      repository,
      ".planning/REQUIREMENTS.md",
      phase_139_requirements_fixture("Complete")
    )
  end

  defp write_phase_139_transition!(repository) do
    write_repo_file!(
      repository,
      ".planning/PROJECT.md",
      "# Lockspire\n## Current Milestone: v1.38 Repository Baseline & Reconciliation\n## Current State\n#{@next_phase_label} completed exact truth reconciliation. #{@action_phase_label} owns bounded operational triage.\n---\n*Last updated: 2026-09-11 after #{@next_phase_label}*\n"
    )

    state = Path.join(repository, ".planning/STATE.md")

    File.write!(
      state,
      File.read!(state)
      |> String.replace(
        "See: .planning/PROJECT.md",
        "See: .planning/PROJECT.md (updated 2026-09-12)"
      )
      |> String.replace(
        "**Current focus:** #{@next_phase_label} — Required Truth Reconciliation",
        "**Current focus:** #{@action_phase_label} — Bounded Operational Loose-End Triage"
      )
      |> String.replace(
        "Last session: 2026-09-12T00:40:28.652Z",
        "Last session: 2026-09-12T01:00:01Z"
      )
    )
  end

  defp phase_139_requirements_fixture(status) do
    phase_139_ids = ~w(CI-08 QUAL-05 HYGIENE-05 HYGIENE-06 TRUTH-03 TRUTH-04 TRUTH-05)
    phase_140_ids = ~w(CI-06 CI-07)
    checked = if status == "Complete", do: "x", else: " "

    "# Requirements\n" <>
      Enum.map_join(phase_140_ids, "", &"- [ ] **#{&1}**: Phase 140 requirement.\n") <>
      Enum.map_join(phase_139_ids, "", &"- [#{checked}] **#{&1}**: Phase 139 requirement.\n") <>
      "\n| Requirement | Phase | Status |\n|-------------|-------|--------|\n" <>
      Enum.map_join(phase_140_ids, "", &"| #{&1} | Phase 140 | Pending |\n") <>
      Enum.map_join(phase_139_ids, "", &"| #{&1} | Phase 139 | #{status} |\n")
  end

  defp build_live_source_snapshot_repository!(repository, ledger, scope) do
    fixture = Path.dirname(repository)
    bin = Path.join(fixture, "live-#{scope}-bin")
    output = Path.join(fixture, "live-#{scope}-ledger.md")
    remote = repository <> "-origin.git"

    initialize_snapshot_repository!(repository)

    if scope == "maintained" do
      write_repo_file!(
        repository,
        "lib/lockspire/example.ex",
        "# TODO reconcile maintained evidence\n"
      )

      commit_all!(repository, "test: add maintained evidence")
    end

    {_, 0} = System.cmd("git", ["clone", "-q", "--bare", repository, remote])
    run_git!(repository, ["remote", "add", "origin", remote])

    env =
      if scope == "github" do
        File.mkdir_p!(bin)
        File.write!(Path.join(bin, "gh"), fake_gh_script())
        File.chmod!(Path.join(bin, "gh"), 0o755)

        [
          {"PATH", bin <> ":" <> System.get_env("PATH", "")},
          {"FAKE_GH_SCENARIO", "default"}
        ]
      else
        []
      end

    {command_output, 0} =
      System.cmd(
        "bash",
        [
          Paths.path("scripts/maintainer/baseline_inventory.sh"),
          "--scope",
          scope,
          "--output",
          output
        ],
        cd: repository,
        env: env,
        stderr_to_stdout: true
      )

    assert command_output == ""
    write_repo_file!(repository, ledger, File.read!(output))
    commit_all!(repository, "docs: publish immutable live-source ledger")
    {ledger, env}
  end

  defp build_gsd_plan_closeout_repository!(repository, ledger) do
    initialize_snapshot_repository!(repository)

    write_repo_file!(repository, ".planning/PROJECT.md", "# Lockspire\n")

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: 138\nstatus: executing\nstopped_at: Completed 138-24-PLAN.md\nstate_head: prior\nprogress:\n  total_plans: 25\n  completed_plans: 24\n---\n# Project State\n## Current Position\nPhase: 138\nPlan: 25 of 25\nStatus: Ready to execute\n## Accumulated Context\n### Decisions\n## Session Continuity\nStopped at: Completed 138-24-PLAN.md\n## Performance Metrics\n| Plan | Duration | Tasks | Files |\n|------|----------|-------|-------|\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\n**Plans**: 24/25 plans executed\n- [ ] 138-25-PLAN.md — Recollect ledger.\n## Progress\n| Phase | Plans Complete | Status | Completed |\n|-------|----------------|--------|-----------|\n| 138. Baseline Inventory & Evidence Taxonomy | 24/25 | In Progress|  |\n"
    )

    write_repo_file!(
      repository,
      ".planning/state.json",
      Jason.encode!(%{
        "contract" => "1.0.0",
        "phases" => [
          %{"number" => "138", "name" => @baseline_phase_label, "status" => "in_progress"}
        ],
        "next" => %{
          "command" => "/gsd:progress --next",
          "label" => "Advance to the next step",
          "reason" => @baseline_phase_label <> " of 4 · executing"
        },
        "updated_at" => "2026-09-10T01:23:19.166Z"
      }) <> "\n"
    )

    commit_all!(repository, "feat: closeout evidence base")
    base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    write_snapshot_ledger!(repository, ledger, base, "immutable ledger")
    commit_all!(repository, "docs: publish immutable baseline ledger")
  end

  defp write_valid_gsd_plan_closeout!(repository) do
    parent = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-25-SUMMARY.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nplan: \"25\"\nstatus: complete\nactuals:\n  tasks: 2\nkey-files:\n  modified:\n    - scripts/maintainer/baseline_inventory.sh\n    - test/lockspire/release/repository_hygiene_contract_test.exs\n    - test/support/lockspire/release_proof/package_assertions.ex\n    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md\nkey-decisions:\n  - \"Plan 138-25 closeout recorded.\"\nrequirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]\ncoverage:\n  - id: D1\n    requirement: BASE-01\n  - id: D2\n    requirement: BASE-02\n  - id: D3\n    requirement: TRIAGE-01\n  - id: D4\n    requirement: TRIAGE-02\n  - id: D5\n    requirement: LOOSE-01\nduration: 81min\n---\n# #{@baseline_phase_label} Plan 25: Corrected Immutable Baseline Inventory Summary\n## Accomplishments\nComplete.\n## Task Commits\nCommitted.\n## Files Created/Modified\nRecorded.\n## Decisions Made\nRecorded.\n## Deviations from Plan\nNone.\n## Issues Encountered\nNone.\n## Next Phase Readiness\nReady.\n## Self-Check: PASSED\n"
    )

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: 138\nstatus: verifying\nstopped_at: Completed 138-25-PLAN.md\nstate_head: #{parent}\nprogress:\n  total_plans: 25\n  completed_plans: 25\n---\n# Project State\n## Current Position\nPhase: 138\nPlan: 25 of 25\nStatus: Phase complete — ready for verification\n## Accumulated Context\n### Decisions\n- [#{@baseline_phase_label}]: Plan 138-25 closeout recorded.\n## Session Continuity\nStopped at: Completed 138-25-PLAN.md\n## Performance Metrics\n| Plan | Duration | Tasks | Files |\n|------|----------|-------|-------|\n| #{@baseline_phase_label} P25 | 81min | 2 tasks | 4 files |\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\n**Plans**: 25/25 plans executed\n- [x] 138-25-PLAN.md — Recollect ledger.\n## Progress\n| Phase | Plans Complete | Status | Completed |\n|-------|----------------|--------|-----------|\n| 138. Baseline Inventory & Evidence Taxonomy | 25/25 | In Progress|  |\n"
    )

    state =
      repository
      |> Path.join(".planning/state.json")
      |> File.read!()
      |> Jason.decode!()
      |> Map.put("next", %{
        "command" => "/gsd:progress --next",
        "label" => "Advance to the next step (verify)",
        "reason" => @baseline_phase_label <> " of 4 · ready to verify"
      })
      |> Map.put("updated_at", "2026-09-10T03:07:01.746Z")

    write_repo_file!(repository, ".planning/state.json", Jason.encode!(state) <> "\n")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "extra-path"),
    do: write_repo_file!(repository, "unrelated.txt", "not bookkeeping\n")

  defp apply_gsd_plan_closeout_near_miss!(repository, "missing-state"),
    do: File.rm!(Path.join(repository, ".planning/STATE.md"))

  defp apply_gsd_plan_closeout_near_miss!(repository, "missing-state-json"),
    do: File.rm!(Path.join(repository, ".planning/state.json"))

  defp apply_gsd_plan_closeout_near_miss!(repository, "missing-roadmap"),
    do: File.rm!(Path.join(repository, ".planning/ROADMAP.md"))

  defp apply_gsd_plan_closeout_near_miss!(repository, "wrong-phase"),
    do: replace_closeout_summary!(repository, "phase: 138-baseline", "phase: 137-baseline")

  defp apply_gsd_plan_closeout_near_miss!(repository, "wrong-plan"),
    do: replace_closeout_summary!(repository, "plan: \"25\"", "plan: \"24\"")

  defp apply_gsd_plan_closeout_near_miss!(repository, "failed-summary"),
    do: replace_closeout_summary!(repository, "status: complete", "status: failed")

  defp apply_gsd_plan_closeout_near_miss!(repository, "missing-self-check"),
    do: replace_closeout_summary!(repository, "## Self-Check: PASSED", "## Self-Check: FAILED")

  defp apply_gsd_plan_closeout_near_miss!(repository, "requirement-mismatch"),
    do: replace_closeout_summary!(repository, "TRIAGE-02, LOOSE-01", "TRIAGE-02")

  defp apply_gsd_plan_closeout_near_miss!(repository, "coverage-mismatch"),
    do: replace_closeout_summary!(repository, "requirement: LOOSE-01", "requirement: BASE-01")

  defp apply_gsd_plan_closeout_near_miss!(repository, "summary-body-requirements") do
    path = closeout_summary_path(repository)

    File.write!(
      path,
      File.read!(path)
      |> String.replace("requirements-completed:", "reported-requirements:", global: false)
      |> Kernel.<>(
        "\nrequirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]\n"
      )
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "summary-body-coverage") do
    path = closeout_summary_path(repository)
    requirements = ~w(BASE-01 BASE-02 TRIAGE-01 TRIAGE-02 LOOSE-01)

    body_coverage =
      "\ncoverage:\n" <>
        Enum.map_join(requirements, "", &"  - requirement: #{&1}\n")

    File.write!(
      path,
      File.read!(path)
      |> String.replace("coverage:", "reported-coverage:", global: false)
      |> Kernel.<>(body_coverage)
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "summary-body-decisions") do
    path = closeout_summary_path(repository)

    File.write!(
      path,
      File.read!(path)
      |> String.replace("key-decisions:", "reported-key-decisions:", global: false)
      |> Kernel.<>("\nkey-decisions:\n  - \"Plan 138-25 closeout recorded.\"\n")
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "duplicate-decisions") do
    replace_closeout_summary!(
      repository,
      "  - \"Plan 138-25 closeout recorded.\"",
      "  - \"Plan 138-25 closeout recorded.\"\n  - \"Plan 138-25 closeout recorded.\""
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "duplicate-requirements") do
    path = closeout_summary_path(repository)

    File.write!(
      path,
      File.read!(path)
      |> String.replace(
        "requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]",
        "requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]\n" <>
          "requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]",
        global: false
      )
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "non-monotonic-progress") do
    path = Path.join(repository, ".planning/ROADMAP.md")
    File.write!(path, File.read!(path) |> String.replace("25/25", "23/25"))
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "unrelated-roadmap") do
    path = Path.join(repository, ".planning/ROADMAP.md")
    File.write!(path, File.read!(path) <> "Unrelated roadmap policy changed.\n")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "unrelated-state") do
    path = Path.join(repository, ".planning/STATE.md")
    File.write!(path, File.read!(path) <> "Unrelated state mutation.\n")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "forged-lifecycle") do
    path = Path.join(repository, ".planning/STATE.md")

    File.write!(
      path,
      File.read!(path) |> String.replace("completed_plans: 25", "completed_plans: 26")
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "extra-checked-plan") do
    path = Path.join(repository, ".planning/ROADMAP.md")
    File.write!(path, File.read!(path) <> "- [x] 138-24-PLAN.md — Forged sibling closeout.\n")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "extra-phase-row") do
    path = Path.join(repository, ".planning/ROADMAP.md")

    File.write!(
      path,
      File.read!(path) <>
        "| 138. Baseline Inventory & Evidence Taxonomy | 25/25 | In Progress| forged |\n"
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "extra-status-line") do
    path = Path.join(repository, ".planning/STATE.md")
    File.write!(path, File.read!(path) <> "Status: Forged sibling state\n")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "extra-decision-line") do
    path = Path.join(repository, ".planning/STATE.md")

    File.write!(
      path,
      File.read!(path) <> "- [#{@baseline_phase_label}]: Forged unrelated decision.\n"
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "extra-performance-row") do
    path = Path.join(repository, ".planning/STATE.md")

    File.write!(
      path,
      File.read!(path) <> "| #{@baseline_phase_label} P24 | 1min | 1 tasks | 1 files |\n"
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "replacement-decision") do
    path = Path.join(repository, ".planning/STATE.md")

    File.write!(
      path,
      File.read!(path)
      |> String.replace(
        "Plan 138-25 closeout recorded.",
        "Plan 138-25 policy override forged.",
        global: false
      )
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "replacement-performance-duration") do
    replace_gsd_closeout_state!(
      repository,
      "| 81min | 2 tasks | 4 files |",
      "| 82min | 2 tasks | 4 files |"
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "replacement-performance-tasks") do
    replace_gsd_closeout_state!(
      repository,
      "| 81min | 2 tasks | 4 files |",
      "| 81min | 3 tasks | 4 files |"
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "replacement-performance-files") do
    replace_gsd_closeout_state!(
      repository,
      "| 81min | 2 tasks | 4 files |",
      "| 81min | 2 tasks | 5 files |"
    )
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "missing-duration") do
    replace_closeout_summary!(repository, "duration: 81min", "reported-duration: 81min")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "duplicate-duration") do
    replace_closeout_summary!(repository, "duration: 81min", "duration: 81min\nduration: 81min")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "duplicate-actual-tasks") do
    replace_closeout_summary!(repository, "  tasks: 2", "  tasks: 2\n  tasks: 2")
  end

  defp apply_gsd_plan_closeout_near_miss!(repository, "duplicate-modified-files") do
    replace_closeout_summary!(
      repository,
      "    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md",
      "    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline.md\n" <>
        "  modified:\n    - forged.md"
    )
  end

  defp replace_gsd_closeout_state!(repository, old, new) do
    path = Path.join(repository, ".planning/STATE.md")
    File.write!(path, File.read!(path) |> String.replace(old, new, global: false))
  end

  defp closeout_summary_path(repository) do
    Path.join(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-25-SUMMARY.md"
    )
  end

  defp replace_closeout_summary!(repository, old, new) do
    path = closeout_summary_path(repository)

    File.write!(path, File.read!(path) |> String.replace(old, new))
  end

  defp build_git_snapshot_repository!(repository, ledger) do
    base = initialize_snapshot_repository!(repository)
    remote = repository <> "-origin.git"

    {_, 0} =
      System.cmd("git", ["clone", "-q", "--bare", repository, remote], stderr_to_stdout: true)

    run_git!(repository, ["remote", "add", "origin", remote])
    linked = repository <> "-snapshot-worktree"
    run_git!(repository, ["branch", "snapshot-branch", base])
    run_git!(repository, ["tag", "snapshot-tag", base])
    run_git!(repository, ["worktree", "add", "--detach", linked, base])

    {output, 0} =
      System.cmd(
        "bash",
        [
          Paths.path("scripts/maintainer/baseline_inventory.sh"),
          "--scope",
          "git",
          "--output",
          ledger
        ],
        cd: repository,
        stderr_to_stdout: true
      )

    assert output == ""

    commit_all!(repository, "docs: publish immutable Git baseline ledger")
    {run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim(), base, linked}
  end

  defp relation_repository_state(repository, ledger) do
    %{
      refs: run_git!(repository, ["show-ref"]),
      worktrees: run_git!(repository, ["worktree", "list", "--porcelain"]),
      index: run_git!(repository, ["write-tree"]),
      status: run_git!(repository, ["status", "--porcelain=v2", "--branch"]),
      ledger: File.read!(Path.join(repository, ledger))
    }
  end

  defp assert_relation_domain_refreshes!(repository, ledger, domain) do
    {output, status} = run_snapshot_relation!(repository, ledger)
    assert status != 0
    assert output =~ "git_topology|#{domain}|mismatch|refresh_required"
    assert output =~ "snapshot_relation: refresh_required"
  end

  defp run_snapshot_relation_with_git_failure!(repository, ledger, scenario) do
    bin = Path.join(repository, ".test-bin")
    File.mkdir_p!(bin)
    git = System.find_executable("git") || raise "git executable unavailable"
    shim = Path.join(bin, "git")

    File.write!(
      shim,
      """
      #!/usr/bin/env bash
      set -eu
      scenario="${LOCKSPIRE_RELATION_GIT_FAILURE:-}"
      case "$scenario:$*" in
        failed-branches:"for-each-ref --format=%(refname)%09%(objectname) refs/heads refs/remotes") exit 42 ;;
        malformed-branches:"for-each-ref --format=%(refname)%09%(objectname) refs/heads refs/remotes") printf 'refs/heads/main\\tbad-object-id\\n'; exit 0 ;;
        failed-tags:"for-each-ref --format=%(refname)%09%(objectname) refs/tags") exit 42 ;;
        malformed-tags:"for-each-ref --format=%(refname)%09%(objectname) refs/tags") printf 'refs/tags/snapshot-tag\\tbad-object-id\\n'; exit 0 ;;
        failed-worktrees:"worktree list --porcelain -z") exit 42 ;;
        malformed-worktrees:"worktree list --porcelain -z") printf 'worktree malformed\\0HEAD bad-object-id\\0\\0'; exit 0 ;;
        failed-hash:"hash-object --stdin") exit 42 ;;
        malformed-hash:"hash-object --stdin") cat >/dev/null; printf 'bad-object-id\\n'; exit 0 ;;
        failed-status:"status --porcelain=v2 --branch") exit 42 ;;
        malformed-status:"status --porcelain=v2 --branch") printf 'malformed status row\\n'; exit 0 ;;
        malformed-status-header:"status --porcelain=v2 --branch") printf '# branch.oid bad-object-id\\n# branch.head main\\n'; exit 0 ;;
      esac
      exec #{git} "$@"
      """
    )

    File.chmod!(shim, 0o755)

    run_snapshot_relation!(repository, ledger, [
      {"LOCKSPIRE_RELATION_GIT_FAILURE", scenario},
      {"PATH", bin <> ":" <> System.get_env("PATH", "")}
    ])
  end

  defp initialize_snapshot_repository!(repository) do
    File.mkdir_p!(repository)
    run_git!(repository, ["init", "-q", "-b", "main"])
    run_git!(repository, ["config", "core.hooksPath", "/dev/null"])
    run_git!(repository, ["config", "user.email", "snapshot@example.com"])
    run_git!(repository, ["config", "user.name", "Snapshot Author"])
    write_repo_file!(repository, "base.txt", "evidence base\n")
    commit_all!(repository, "feat: evidence base")
    run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
  end

  defp write_snapshot_ledger!(
         repository,
         ledger,
         evidence_base,
         body,
         github_fingerprint \\ "not_applicable",
         maintained_fingerprint \\ "not_applicable"
       ) do
    repository_identity =
      repository |> run_git!(["rev-parse", "--show-toplevel"]) |> String.trim()

    scope =
      cond do
        github_fingerprint != "not_applicable" -> "github"
        maintained_fingerprint != "not_applicable" -> "maintained"
        true -> "git-baseline"
      end

    write_repo_file!(
      repository,
      ledger,
      """
      ---
      phase: 138
      scope: "#{scope}"
      status: "complete"
      collection_started_at: "2026-08-28T00:00:00Z"
      collection_finished_at: "2026-08-28T00:00:01Z"
      repository: #{Jason.encode!(repository_identity)}
      repository_identity: #{Jason.encode!(repository_identity)}
      declared_source_scopes: "#{scope}"
      local_head_sha: "#{evidence_base}"
      evidence_base_sha: "#{evidence_base}"
      local_main_sha: "#{evidence_base}"
      origin_main_sha: "unavailable"
      git_receipt_fingerprint: "not_applicable"
      github_receipt_fingerprint: "#{github_fingerprint}"
      maintained_receipt_fingerprint: "#{maintained_fingerprint}"
      executed: "no — inventory proposal only"
      ---
      #{body}
      """
    )
  end

  defp replace_snapshot_ledger!(repository, ledger) do
    evidence_base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    write_snapshot_ledger!(repository, ledger, evidence_base, "replacement immutable ledger")
    commit_all!(repository, "docs: publish replacement immutable baseline ledger")
    run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
  end

  defp append_authorized_lifecycle!(repository) do
    write_valid_lifecycle_candidate!(repository, "summary")

    commit_all!(repository, "docs(138-11): complete final ledger plan")

    write_valid_lifecycle_candidate!(repository, "review")

    commit_all!(repository, @baseline_phase_commit_prefix <> "record clean code review")

    write_valid_lifecycle_candidate!(repository, "verification")

    commit_all!(repository, @baseline_phase_commit_prefix <> "record passed verification")

    write_valid_lifecycle_candidate!(repository, "completion")

    commit_all!(repository, @baseline_phase_commit_prefix <> "complete phase execution")
    phase_completion = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    write_valid_transition!(repository)

    commit_all!(
      repository,
      @baseline_phase_commit_prefix <> "transition to phase " <> @next_phase_number
    )

    phase_completion
  end

  defp append_pretransition_lifecycle!(repository, ledger) do
    write_valid_lifecycle_candidate!(repository, "summary")
    commit_all!(repository, "docs(138-11): complete final ledger plan")

    write_valid_lifecycle_candidate!(repository, "review")
    commit_all!(repository, @baseline_phase_commit_prefix <> "record clean code review")

    evidence_base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    review_sha256 =
      file_sha256(
        Path.join(
          repository,
          ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md"
        )
      )

    write_snapshot_ledger!(repository, ledger, evidence_base, "pre-verification immutable ledger")

    ledger_path = Path.join(repository, ledger)

    File.write!(
      ledger_path,
      File.read!(ledger_path)
      |> String.replace(
        "executed: \"no — inventory proposal only\"",
        "phase_review_status: \"consumed\"\nphase_review_sha256: \"#{review_sha256}\"\nexecuted: \"no — inventory proposal only\""
      )
    )

    commit_all!(
      repository,
      @baseline_phase_commit_prefix <> "publish pre-verification baseline inventory"
    )

    write_valid_lifecycle_candidate!(repository, "verification")
    commit_all!(repository, @baseline_phase_commit_prefix <> "record passed verification")

    write_valid_lifecycle_candidate!(repository, "preserved-completion")
    commit_all!(repository, @baseline_phase_commit_prefix <> "complete phase execution")
  end

  defp write_valid_transition!(repository) do
    write_repo_file!(
      repository,
      ".planning/PROJECT.md",
      "# Lockspire\n## Current Milestone: v1.38 Repository Baseline & Reconciliation\n## Current State\n#{@baseline_phase_label} completed the v1.38 evidence foundation. Phase #{@next_phase_number} now owns required truth reconciliation.\n---\n*Last updated: 2026-09-11 after #{@baseline_phase_label}*\n"
    )

    state = Path.join(repository, ".planning/STATE.md")

    File.write!(
      state,
      File.read!(state) <>
        "\n## Project Reference\n\n**Current focus:** Phase " <>
        @next_phase_number <> " — Required Truth Reconciliation\n"
    )
  end

  defp write_valid_lifecycle_candidate!(repository, "summary") do
    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-PLAN.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nplan: \"11\"\ntype: execute\n---\n<objective>\nClose the ledger.\n</objective>\n<tasks>\n<task type=\"auto\">Complete proof.</task>\n</tasks>\n"
    )

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: 138\nstatus: verifying\nstopped_at: Completed 138-11-PLAN.md\n---\n# Project State\n## Current Position\nPhase: 138\nPlan: 11 complete\nStatus: Phase complete — ready for verification\n"
    )

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\nPhase 138 in progress; Plan 11 complete\n"
    )

    write_repo_file!(
      repository,
      ".planning/REQUIREMENTS.md",
      "# Requirements\nBASE-01 pending; Plan 11 evidence recorded\n"
    )

    write_repo_file!(
      repository,
      ".planning/state.json",
      Jason.encode!(%{
        "contract" => "1.0.0",
        "phases" => [
          %{"number" => "138", "name" => @baseline_phase_label, "status" => "in_progress"}
        ]
      }) <> "\n"
    )

    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-SUMMARY.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nplan: \"11\"\nstatus: complete\nrequirements-completed: [BASE-01]\n---\n# " <>
        @baseline_phase_label <>
        " Plan 11: Final Ledger Summary\n## Accomplishments\nComplete ledger proof.\n## Task Commits\nOne atomic task.\n## Files Created/Modified\nSummary only.\n## Decisions Made\nNone.\n## Deviations from Plan\nNone.\n## Issues Encountered\nNone.\n## Next Phase Readiness\nReady.\n## Self-Check: PASSED\n"
    )
  end

  defp write_valid_lifecycle_candidate!(repository, "review") do
    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nstatus: clean\n---\n# " <>
        @baseline_phase_label <> ": Code Review Report\n## Summary\nNo findings.\n"
    )
  end

  defp write_valid_lifecycle_candidate!(repository, "verification") do
    write_repo_file!(
      repository,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md",
      "---\nphase: 138-baseline-inventory-evidence-taxonomy\nstatus: passed\ngaps: []\nbehavior_unverified: 0\nhuman_needed: false\n---\n# " <>
        @baseline_phase_label <>
        ": Baseline Inventory Verification Report\n## Goal Achievement\nPassed.\n"
    )
  end

  defp write_valid_lifecycle_candidate!(repository, "completion") do
    parent = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()

    write_repo_file!(
      repository,
      ".planning/ROADMAP.md",
      "# Lockspire Roadmap\n## Phases\n" <> @baseline_phase_label <> " complete\n"
    )

    write_repo_file!(
      repository,
      ".planning/STATE.md",
      "---\ncurrent_phase: #{@next_phase_number}\ncurrent_phase_name: Required Truth Reconciliation\nstatus: planning\nstopped_at: #{@baseline_phase_label} complete, ready to plan Phase #{@next_phase_number}\nstate_head: #{parent}\n---\n# Project State\n## Current Position\nPhase: #{@next_phase_number} — Required Truth Reconciliation\nPlan: Not started\nStatus: Ready to plan\n"
    )

    write_repo_file!(
      repository,
      ".planning/REQUIREMENTS.md",
      "# Requirements\nBASE-01 complete\n"
    )

    write_repo_file!(
      repository,
      ".planning/state.json",
      Jason.encode!(%{
        "contract" => "1.0.0",
        "phases" => [
          %{"number" => @baseline_phase_number, "status" => "complete"},
          %{"number" => @next_phase_number, "status" => "in_progress"}
        ],
        "next" => %{
          "label" => "Plan phase " <> @next_phase_number,
          "reason" => @next_phase_label <> " needs a plan"
        }
      }) <> "\n"
    )
  end

  defp write_valid_lifecycle_candidate!(repository, "preserved-completion") do
    write_valid_lifecycle_candidate!(repository, "completion")
    state = Path.join(repository, ".planning/STATE.md")

    File.write!(
      state,
      File.read!(state)
      |> String.replace(
        "stopped_at: #{@baseline_phase_label} complete, ready to plan Phase #{@next_phase_number}",
        "stopped_at: Completed 138-11-PLAN.md"
      )
    )
  end

  defp write_valid_lifecycle_candidate!(repository, "transition"),
    do: write_valid_transition!(repository)

  defp lifecycle_subject("summary"), do: "docs(138-11): complete final ledger plan"

  defp lifecycle_subject("review"),
    do: @baseline_phase_commit_prefix <> "record clean code review"

  defp lifecycle_subject("verification"),
    do: @baseline_phase_commit_prefix <> "record passed verification"

  defp lifecycle_subject("completion"),
    do: @baseline_phase_commit_prefix <> "complete phase execution"

  defp lifecycle_subject("transition"),
    do: @baseline_phase_commit_prefix <> "transition to phase " <> @next_phase_number

  defp lifecycle_primary_path("summary"),
    do: ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-SUMMARY.md"

  defp lifecycle_primary_path("review"),
    do: ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md"

  defp lifecycle_primary_path("verification"),
    do: ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md"

  defp lifecycle_primary_path("completion"), do: ".planning/STATE.md"
  defp lifecycle_primary_path("transition"), do: ".planning/STATE.md"

  defp apply_lifecycle_near_miss!(repository, class, "deletion") do
    File.rm!(Path.join(repository, lifecycle_primary_path(class)))
  end

  defp apply_lifecycle_near_miss!(repository, class, "empty") do
    File.write!(Path.join(repository, lifecycle_primary_path(class)), "")
  end

  defp apply_lifecycle_near_miss!(repository, class, "rename") do
    path = lifecycle_primary_path(class)
    run_git!(repository, ["mv", path, path <> ".renamed"])
  end

  defp apply_lifecycle_near_miss!(repository, class, "type-change") do
    path = Path.join(repository, lifecycle_primary_path(class))
    File.rm!(path)
    File.ln_s!("../ROADMAP.md", path)
  end

  defp apply_lifecycle_near_miss!(repository, class, "wrong-phase") do
    path = Path.join(repository, lifecycle_primary_path(class))
    content = File.read!(path)

    content =
      if class in ~w(completion transition) do
        String.replace(content, ~r/current_phase: (138|139)/, "current_phase: 137")
      else
        String.replace(content, "phase: 138-baseline", "phase: 137-baseline")
      end

    File.write!(path, content)
  end

  defp apply_lifecycle_near_miss!(repository, class, "missing-heading") do
    path = Path.join(repository, lifecycle_primary_path(class))
    File.write!(path, File.read!(path) |> String.replace(~r/^# .+$/m, ""))
  end

  defp apply_lifecycle_near_miss!(repository, class, "arbitrary") do
    File.write!(Path.join(repository, lifecycle_primary_path(class)), "Safe unrelated prose\n")
  end

  defp apply_lifecycle_near_miss!(repository, "summary", "companion-arbitrary") do
    write_repo_file!(repository, ".planning/STATE.md", "Safe unrelated prose\n")
  end

  defp apply_lifecycle_near_miss!(repository, "completion", "companion-arbitrary") do
    write_repo_file!(repository, ".planning/ROADMAP.md", "Safe unrelated prose\n")
  end

  defp apply_lifecycle_near_miss!(repository, "transition", "companion-arbitrary") do
    write_repo_file!(repository, ".planning/PROJECT.md", "Safe unrelated prose\n")
  end

  defp apply_lifecycle_near_miss!(repository, class, "companion-arbitrary") do
    apply_lifecycle_near_miss!(repository, class, "arbitrary")
  end

  defp apply_lifecycle_near_miss!(repository, _class, "mixed-path") do
    write_repo_file!(repository, "lib/unrelated.ex", "defmodule Unrelated do\nend\n")
  end

  defp clone_at_commit!(fixture, source, commit, name) do
    destination = Path.join(fixture, name)
    {_, 0} = System.cmd("git", ["clone", "-q", source, destination], stderr_to_stdout: true)
    run_git!(destination, ["checkout", "-q", "-B", "main", commit])
    run_git!(destination, ["config", "core.hooksPath", "/dev/null"])
    run_git!(destination, ["config", "user.email", "snapshot@example.com"])
    run_git!(destination, ["config", "user.name", "Snapshot Author"])
    destination
  end

  defp write_repo_file!(repository, relative, content) do
    path = Path.join(repository, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end

  defp commit_all!(repository, subject) do
    run_git!(repository, ["add", "--all"])
    run_git!(repository, ["commit", "-qm", subject])
  end

  defp run_snapshot_relation!(repository, ledger, env \\ []) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--verify-snapshot-relation",
        ledger
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_preverify_relation!(repository, ledger, env \\ []) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--verify-preverify-relation",
        ledger
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_posttransition_relation!(repository, ledger, env) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--verify-post-transition-relation",
        ledger
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_phase_139_preverify_relation!(repository, ledger, env \\ []) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--verify-" <> @next_phase_slug <> "-preverify-relation",
        ledger
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_phase_139_posttransition_relation!(repository, ledger, env \\ []) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--verify-" <> @next_phase_slug <> "-posttransition-relation",
        ledger
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_phase_138_finalizer!(repository, mode, env) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/finalize_phase_138_inventory.sh"),
        mode,
        "--phase",
        "138"
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_phase_139_finalizer!(repository, mode, env) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/finalize_phase_138_inventory.sh"),
        mode,
        "--phase",
        "139"
      ],
      cd: repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp file_sha256(path) do
    path
    |> File.read!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp gsd_tools_path! do
    home = System.user_home!()

    [
      System.get_env("GSD_TOOLS"),
      Paths.path("gsd-core/bin/gsd-tools.cjs"),
      Paths.path(".codex/gsd-core/bin/gsd-tools.cjs"),
      Paths.path(".claude/gsd-core/bin/gsd-tools.cjs"),
      Paths.path(
        "tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs"
      ),
      Path.join([home, ".codex", "gsd-core", "bin", "gsd-tools.cjs"]),
      Path.join([home, ".claude", "gsd-core", "bin", "gsd-tools.cjs"]),
      Path.join([home, ".hermes", "gsd-core", "bin", "gsd-tools.cjs"]),
      Path.join([home, ".cursor", "gsd-core", "bin", "gsd-tools.cjs"]),
      Path.join([home, ".gemini", "gsd-core", "bin", "gsd-tools.cjs"]),
      Path.join([home, ".copilot", "gsd-core", "bin", "gsd-tools.cjs"]),
      Path.join([home, ".agents", "gsd-core", "bin", "gsd-tools.cjs"])
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.find(&File.regular?/1)
    |> case do
      nil -> raise "GSD runtime tools unavailable"
      path -> Path.expand(path)
    end
  end

  defp install_receipt_writer_fixture!(repository, gsd_tools) do
    source_core = gsd_tools |> Path.dirname() |> Path.dirname()

    File.write!(
      Path.join([repository, ".git", "info", "exclude"]),
      "\n/gsd-core/\n/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs\n",
      [:append]
    )

    sources = [
      {Path.join(source_core, "bin/gsd-tools.cjs"), "bin/gsd-tools.cjs"},
      {Paths.path(
         "tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"
       ), "tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"},
      {Path.join(source_core, "workflows/execute-phase.md"), "workflows/execute-phase.md"},
      {Path.join(source_core, "workflows/plan-phase.md"), "workflows/plan-phase.md"},
      {Path.join(source_core, "workflows/transition.md"), "workflows/transition.md"},
      {Path.join(Path.dirname(source_core), "gsd-host-contract.json"),
       "fixtures/gsd-host-contract.json"}
    ]

    for {source, relative} <- sources do
      target =
        if String.starts_with?(relative, "tools/") do
          Path.join(repository, relative)
        else
          Path.join([repository, "gsd-core", relative])
        end

      File.mkdir_p!(Path.dirname(target))
      File.cp!(source, target)
    end

    Path.join([repository, "gsd-core", "workflows", "transition.md"])
  end

  defp assert_relation_refreshes!(repository, ledger) do
    {output, status} = run_snapshot_relation!(repository, ledger)
    assert status != 0
    assert output =~ "snapshot_relation: refresh_required"
  end

  defp assert_snapshot_drift_preserves_target!(scope, scenario, diagnostic) do
    root = Paths.path(".")

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-snapshot-drift-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(fixture, "bin")
    state = Path.join(fixture, "state")
    output = Path.join(fixture, "inventory.md")
    prior = "complete target before #{scenario}\n"

    try do
      File.mkdir_p!(bin)
      File.mkdir_p!(state)
      File.write!(output, prior)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "git"), 0o755)
      File.chmod!(Path.join(bin, "gh"), 0o755)

      env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_REPO_ROOT", root},
        {"FAKE_STATE_DIR", state},
        {"FAKE_GIT_SCENARIO", scenario},
        {"FAKE_GH_SCENARIO", scenario}
      ]

      {command_output, status} = run_collector!(scope, output, env)
      assert status != 0
      assert command_output =~ diagnostic
      assert File.read!(output) == prior
      assert_collector_artifacts_clean!(output)

      File.rm_rf!(state)
      File.mkdir_p!(state)

      stable_env =
        Enum.map(env, fn
          {"FAKE_GIT_SCENARIO", _} -> {"FAKE_GIT_SCENARIO", "default"}
          {"FAKE_GH_SCENARIO", _} -> {"FAKE_GH_SCENARIO", "default"}
          pair -> pair
        end)

      {retry_output, 0} = run_collector!(scope, output, stable_env)
      assert retry_output == ""
      refute File.read!(output) == prior
      assert_collector_artifacts_clean!(output)
    after
      File.rm_rf(fixture)
    end
  end

  defp assert_publication_worktree_failure_preserves_target!(
         fixture,
         bin,
         root,
         scenario,
         diagnostic
       ) do
    state = Path.join(fixture, "#{scenario}-state")
    output = Path.join(fixture, "#{scenario}.md")
    prior = "complete target before #{scenario}\n"
    File.mkdir_p!(state)
    File.write!(output, prior)

    env = [
      {"PATH", bin <> ":" <> System.get_env("PATH", "")},
      {"FAKE_REPO_ROOT", root},
      {"FAKE_OUTPUT", output},
      {"FAKE_STATE_DIR", state},
      {"FAKE_GIT_SCENARIO", scenario}
    ]

    {command_output, status} = run_collector!("git", output, env)
    assert status != 0
    assert command_output =~ diagnostic
    assert File.read!(output) == prior
    assert_collector_artifacts_clean!(output)

    File.rm_rf!(state)
    File.mkdir_p!(state)

    stable_env =
      Enum.map(env, fn
        {"FAKE_GIT_SCENARIO", _} -> {"FAKE_GIT_SCENARIO", "owned-only"}
        pair -> pair
      end)

    {retry_output, 0} = run_collector!("git", output, stable_env)
    assert retry_output == ""
    refute File.read!(output) == prior
    assert_collector_artifacts_clean!(output)
  end

  defp assert_owned_worktree_paths_are_exactly_excluded!(fixture, bin, root) do
    output = Path.join(fixture, "owned-worktree-paths.md")
    state = Path.join(fixture, "owned-worktree-state")
    File.mkdir_p!(state)

    env = [
      {"PATH", bin <> ":" <> System.get_env("PATH", "")},
      {"FAKE_REPO_ROOT", root},
      {"FAKE_OUTPUT", output},
      {"FAKE_STATE_DIR", state},
      {"FAKE_GIT_SCENARIO", "owned-only"}
    ]

    {command_output, 0} = run_collector!("git", output, env)
    assert command_output == ""
    assert File.read!(output) =~ ~r/^status: "complete"$/m
    assert_collector_artifacts_clean!(output)

    prior = File.read!(output)
    File.rm_rf!(state)
    File.mkdir_p!(state)

    {near_output, near_status} =
      run_collector!(
        "git",
        output,
        Enum.map(env, fn
          {"FAKE_GIT_SCENARIO", _} -> {"FAKE_GIT_SCENARIO", "owned-near-name"}
          pair -> pair
        end)
      )

    assert near_status != 0
    assert near_output =~ "working tree changed"
    assert File.read!(output) == prior
    assert_collector_artifacts_clean!(output)
  end

  defp assert_pagination_contention!(fixture, base_env) do
    output = Path.join(fixture, "pagination.md")
    ready = output <> ".ready"
    release = output <> ".release"
    prior = "complete target before pagination\n"
    File.write!(output, prior)

    owner_env =
      base_env ++
        [
          {"FAKE_GH_SCENARIO", "hold-pagination"},
          {"FAKE_HOLD_READY", ready},
          {"FAKE_HOLD_RELEASE", release}
        ]

    owner = start_collector_port!("github", output, owner_env)
    await_path!(ready, "collector did not reach GitHub pagination hold")

    for scope <- ["github", "git"] do
      sentinel = output <> ".refused-#{scope}-writer-ran"

      {refusal, refusal_status} =
        run_collector!(scope, output, base_env ++ [{"FAKE_WRITER_SENTINEL", sentinel}])

      assert refusal_status != 0
      assert refusal =~ "Another collector holds the target lock"
      assert File.exists?(sentinel)
      refute File.read!(output) =~ "refused-writer-ran"
      assert File.read!(output) == prior
    end

    independent = Path.join(fixture, "pagination-independent.md")
    {independent_output, 0} = run_collector!("git", independent, base_env)
    assert independent_output == ""
    assert File.read!(independent) =~ "## Git branches"

    File.write!(release, "release\n")
    {owner_output, 0} = await_port_exit!(owner)
    assert owner_output == ""
    assert File.read!(output) =~ "GH-PR-1"
    refute File.read!(output) =~ "refused-writer-ran"
    assert_collector_artifacts_clean!(output)
    assert_collector_artifacts_clean!(independent)
  end

  defp start_collector_port!(scope, output, env, replace? \\ true) do
    bash = System.find_executable("bash") || raise "bash is required"
    python = System.find_executable("python3") || raise "python3 is required"
    pid_file = output <> ".collector-pid"

    collector_args =
      [
        bash,
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--scope",
        scope,
        "--output",
        output
      ] ++ if(replace?, do: ["--replace"], else: [])

    port =
      Port.open(
        {:spawn_executable, String.to_charlist(python)},
        [
          :binary,
          :exit_status,
          :stderr_to_stdout,
          args:
            Enum.map(
              [
                "-c",
                "import os,sys; pid=os.fork(); " <>
                  "(os.setsid(), open(os.environ['FAKE_COLLECTOR_PID_FILE'],'w').write(str(os.getpid())), os.execv(sys.argv[1], sys.argv[1:])) if pid == 0 else None; " <>
                  "_,status=os.waitpid(pid,0); " <>
                  "os.unlink(os.environ['FAKE_COLLECTOR_PID_FILE']); " <>
                  "sys.exit(os.waitstatus_to_exitcode(status))"
              ] ++
                collector_args,
              &String.to_charlist/1
            ),
          env:
            Enum.map(env ++ [{"FAKE_COLLECTOR_PID_FILE", pid_file}], fn {key, value} ->
              {String.to_charlist(key), String.to_charlist(value)}
            end)
        ]
      )

    await_path!(pid_file, "collector process-group PID was not published")
    %{port: port, pid_file: pid_file}
  end

  defp await_path!(path, diagnostic) do
    deadline = System.monotonic_time(:millisecond) + 15_000
    do_await_path!(path, diagnostic, deadline)
  end

  defp do_await_path!(path, diagnostic, deadline) do
    cond do
      File.exists?(path) ->
        :ok

      System.monotonic_time(:millisecond) >= deadline ->
        flunk("#{diagnostic}: #{path}")

      true ->
        receive do
        after
          10 -> do_await_path!(path, diagnostic, deadline)
        end
    end
  end

  defp signal_collector!(%{pid_file: pid_file}, signal) do
    os_pid = pid_file |> File.read!() |> String.trim()

    {_, 0} =
      System.cmd("kill", ["-#{signal}", os_pid], stderr_to_stdout: true)
  end

  defp await_port_exit!(%{port: port} = owner, output \\ "") do
    receive do
      {^port, {:data, data}} -> await_port_exit!(owner, output <> data)
      {^port, {:exit_status, status}} -> {output, status}
    after
      5_000 -> flunk("collector process did not exit; output: #{output}")
    end
  end

  defp assert_different_targets_are_independent!(fixture, base_env) do
    first = Path.join(fixture, "first.md")
    second = Path.join(fixture, "second.md")
    {first_output, 0} = run_collector!("git", first, base_env)
    {second_output, 0} = run_collector!("git", second, base_env)
    assert first_output == ""
    assert second_output == ""
    assert File.read!(first) =~ "## Git branches"
    assert File.read!(second) =~ "## Git branches"
    assert_collector_artifacts_clean!(first)
    assert_collector_artifacts_clean!(second)
  end

  defp assert_ledger_parent_freshness_relation!(fixture) do
    repository = Path.join(fixture, "freshness-repository")
    ledger = "baseline-inventory-2026-08-28.md"
    File.mkdir_p!(repository)
    run_git!(repository, ["init", "-q"])
    run_git!(repository, ["config", "user.email", "test@example.com"])
    run_git!(repository, ["config", "user.name", "Lockspire Test"])
    File.write!(Path.join(repository, "collector.txt"), "collector corrections\n")
    run_git!(repository, ["add", "collector.txt"])
    run_git!(repository, ["commit", "-qm", "collector corrections"])
    evidence_base = run_git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    File.write!(Path.join(repository, ledger), "evidence_base_sha: #{evidence_base}\n")
    run_git!(repository, ["add", ledger])
    run_git!(repository, ["commit", "-qm", "refresh canonical ledger"])

    assert run_git!(repository, ["rev-parse", "HEAD^"]) |> String.trim() == evidence_base

    assert run_git!(repository, ["diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD"])
           |> String.trim() == ledger

    assert File.read!(Path.join(repository, ledger)) =~ evidence_base
  end

  defp run_collector!(scope, output, env) do
    System.cmd(
      "bash",
      [
        Paths.path("scripts/maintainer/baseline_inventory.sh"),
        "--scope",
        scope,
        "--output",
        output,
        "--replace"
      ],
      env: env,
      stderr_to_stdout: true
    )
  end

  defp assert_collector_artifacts_clean!(output, diagnostic \\ nil) do
    refute File.exists?(output <> ".lock"),
           diagnostic || "collector lock remained: #{output}.lock"

    (output <> ".*")
    |> Path.wildcard()
    |> Enum.each(fn path ->
      refute String.contains?(Path.basename(path), [".tmp.", ".git.", ".github", ".maintained"]),
             "collector artifact remained: #{path}"
    end)
  end

  defp assert_no_raw_credential!(output, credential, location) do
    if :binary.match(output, credential) != :nomatch do
      flunk("raw credential leaked through #{location}")
    end
  end

  defp run_git!(cwd, args) do
    {output, 0} = System.cmd("git", args, cd: cwd, stderr_to_stdout: true)
    output
  end

  defp normalize_collection_window(output) do
    output
    |> String.replace(~r/collection_(started|finished)_at: .+/, "collection_\\1_at: WINDOW")
    |> String.replace(~r/Collection window: `[^`]+` to `[^`]+`/, "Collection window: WINDOW")
    |> String.replace(
      ~r/Snapshot boundary: bounded as of `[^`]+`/,
      "Snapshot boundary: bounded as of WINDOW"
    )
  end

  defp maintained_rec_rows(output) do
    output
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "| REC-"))
  end

  defp stable_rec_id(subject) do
    subject
    |> String.downcase()
    |> stable_rec_id_from_canonical()
  end

  defp stable_git_evidence_id(prefix, kind, subject) do
    input = "#{kind}:#{subject}"

    digest =
      :crypto.hash(:sha, "blob #{byte_size(input)}\0#{input}")
      |> Base.encode16(case: :lower)

    "#{prefix}-#{String.slice(digest, 0, 12)}"
  end

  defp stable_rec_id_from_canonical(canonical_subject) do
    input = "record:" <> canonical_subject

    digest =
      :crypto.hash(:sha, "blob #{byte_size(input)}\0#{input}")
      |> Base.encode16(case: :lower)

    "REC-" <> String.slice(digest, 0, 12)
  end

  defp read_frontmatter!(path) do
    ["---" | lines] = path |> File.read!() |> String.split("\n")
    {frontmatter_lines, ["---" | _body]} = Enum.split_while(lines, &(&1 != "---"))

    Enum.reduce(frontmatter_lines, %{}, fn line, parsed ->
      [key, encoded_value] = String.split(line, ": ", parts: 2)
      refute Map.has_key?(parsed, key), "duplicate frontmatter key: #{key}"
      Map.put(parsed, key, Jason.decode!(encoded_value))
    end)
  end

  defp maintained_row_fields(output, id) do
    row =
      output
      |> maintained_rec_rows()
      |> Enum.find(&String.starts_with?(&1, "| #{id} |"))

    assert row, "expected maintained row for #{id}"

    row
    |> String.trim_leading("| ")
    |> String.trim_trailing(" |")
    |> String.split(" | ")
  end

  defp run_hostile_maintained_fixture! do
    fixture = unique_tmp_fixture("lockspire-hostile-maintained")

    repository = Path.join(fixture, " repository: #€ \"quoted\" [flow] \t ")
    origin = Path.join(fixture, "origin.git")
    output = Path.join(fixture, "inventory.md")
    repeated_output = Path.join(fixture, "inventory-repeated.md")

    subjects = [
      ".planning/todos/space name.md",
      ".planning/todos/colon:name.md",
      ".planning/todos/tab\tname.md",
      ".planning/todos/newline\n## INJECTED.md",
      ".planning/todos/row\n| INJECTED |.md",
      ".planning/todos/-leading.md",
      ".planning/todos/pipe|name.md",
      ".planning/todos/tick`name.md",
      ".planning/todos/[brackets](paren).md",
      ".planning/todos/percent%name.md",
      ".planning/todos/shell$(touch LOCKSPIRE_HOSTILE_SIDE_EFFECT).md",
      ".planning/todos/GHp_hostile-token-secret.md",
      ".planning/todos/café.md",
      ".planning/todos/euro-€.md",
      ".planning/todos/invalid-" <> <<0xFF>> <> ".md"
    ]

    File.mkdir_p!(repository)
    run_git!(repository, ["init", "-q", "-b", "main"])
    run_git!(repository, ["config", "user.email", "test@example.com"])
    run_git!(repository, ["config", "user.name", "Lockspire Test"])

    subjects
    |> Enum.filter(&String.valid?/1)
    |> Enum.each(fn subject ->
      path = Path.join(repository, subject)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "follow-up trigger\n")
    end)

    marker = Path.join(repository, "lib/maintained_marker.ex")
    File.mkdir_p!(Path.dirname(marker))
    File.write!(marker, "# TODO follow-up trigger\n")

    run_git!(repository, ["add", "--all"])
    add_invalid_index_path!(repository)
    run_git!(repository, ["commit", "-qm", "hostile maintained paths"])
    mark_invalid_index_path_skip_worktree!(repository)
    File.mkdir_p!(origin)
    run_git!(origin, ["init", "-q", "--bare"])
    run_git!(repository, ["remote", "add", "origin", origin])
    run_git!(repository, ["push", "-qu", "origin", "main"])

    {collector_output, 0} =
      System.cmd(
        "bash",
        [
          Paths.path("scripts/maintainer/baseline_inventory.sh"),
          "--scope",
          "maintained",
          "--output",
          output
        ],
        cd: repository,
        stderr_to_stdout: true
      )

    assert collector_output == ""

    {repeated_collector_output, 0} =
      System.cmd(
        "bash",
        [
          Paths.path("scripts/maintainer/baseline_inventory.sh"),
          "--scope",
          "maintained",
          "--output",
          repeated_output
        ],
        cd: repository,
        stderr_to_stdout: true
      )

    assert repeated_collector_output == ""
    {File.read!(output), File.read!(repeated_output), subjects, repository, fixture}
  end

  defp add_invalid_index_path!(repository) do
    blob_source = Path.join(Path.dirname(repository), "invalid-path-blob")
    File.write!(blob_source, "follow-up trigger\n")

    {blob, 0} =
      System.cmd("git", ["hash-object", "-w", blob_source],
        cd: repository,
        stderr_to_stdout: true
      )

    File.rm!(blob_source)

    script =
      ~S(invalid_path=$'.planning/todos/invalid-\xff.md'; git update-index --add --cacheinfo "100644,$INVALID_BLOB,$invalid_path")

    {output, status} =
      System.cmd("bash", ["-c", script],
        cd: repository,
        env: [{"INVALID_BLOB", String.trim(blob)}],
        stderr_to_stdout: true
      )

    assert status == 0, output
  end

  defp mark_invalid_index_path_skip_worktree!(repository) do
    script =
      ~S(invalid_path=$'.planning/todos/invalid-\xff.md'; git update-index --skip-worktree -- "$invalid_path")

    {output, status} =
      System.cmd("bash", ["-c", script], cd: repository, stderr_to_stdout: true)

    assert status == 0, output
  end

  defp run_baseline_fixture!(scope \\ "git-baseline", scenario \\ "default", extra_env \\ []) do
    root = Paths.path(".")
    fixture = unique_tmp_fixture("lockspire-baseline")

    {credential_root, extra_env} =
      case List.keytake(extra_env, "FAKE_CREDENTIAL_REPO_ROOT", 0) do
        {{_name, component}, remaining} -> {Path.join(fixture, component), remaining}
        nil -> {root, extra_env}
      end

    bin = Path.join(fixture, "bin")
    output_path = Path.join(fixture, "inventory.md")

    try do
      File.mkdir_p!(bin)
      File.mkdir_p!(credential_root)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.chmod!(Path.join(bin, "git"), 0o755)

      env =
        [
          {"PATH", bin <> ":" <> System.get_env("PATH", "")},
          {"FAKE_REPO_ROOT", credential_root},
          {"FAKE_GIT_SCENARIO", scenario}
        ] ++ extra_env

      {command_output, status} =
        System.cmd(
          "bash",
          [
            Paths.path("scripts/maintainer/baseline_inventory.sh"),
            "--scope",
            scope,
            "--output",
            output_path
          ],
          env: env,
          stderr_to_stdout: true
        )

      assert status == 0, command_output

      {:ok, File.read!(output_path)}
    after
      File.rm_rf(fixture)
    end
  end

  defp run_github_fixture!(scenario \\ "default", extra_env \\ []) do
    root = Paths.path(".")
    fixture = unique_tmp_fixture("lockspire-github")

    bin = Path.join(fixture, "bin")
    output_path = Path.join(fixture, "inventory.md")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "git"), 0o755)
      File.chmod!(Path.join(bin, "gh"), 0o755)

      env =
        [
          {"PATH", bin <> ":" <> System.get_env("PATH", "")},
          {"FAKE_REPO_ROOT", root},
          {"FAKE_GH_SCENARIO", scenario}
        ] ++ extra_env

      {command_output, status} =
        System.cmd(
          "bash",
          [
            Paths.path("scripts/maintainer/baseline_inventory.sh"),
            "--scope",
            "github",
            "--output",
            output_path
          ],
          env: env,
          stderr_to_stdout: true
        )

      assert status == 0, "GitHub fixture #{scenario} failed: #{command_output}"
      assert command_output == ""
      {:ok, File.read!(output_path)}
    after
      File.rm_rf(fixture)
    end
  end

  defp run_complete_inventory_fixture! do
    root = Paths.path(".")
    fixture = unique_tmp_fixture("lockspire-complete")

    bin = Path.join(fixture, "bin")
    output_path = Path.join(fixture, "inventory.md")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), fake_git_script())
      File.write!(Path.join(bin, "gh"), fake_gh_script())
      File.chmod!(Path.join(bin, "git"), 0o755)
      File.chmod!(Path.join(bin, "gh"), 0o755)

      env = [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"FAKE_REPO_ROOT", root},
        {"FAKE_GIT_SCENARIO", "maintained-current-planning"}
      ]

      {command_output, status} =
        System.cmd(
          "bash",
          [
            Paths.path("scripts/maintainer/baseline_inventory.sh"),
            "--output",
            output_path
          ],
          env: env,
          stderr_to_stdout: true
        )

      assert status == 0, command_output
      assert command_output == ""
      {:ok, File.read!(output_path)}
    after
      File.rm_rf(fixture)
    end
  end

  defp unique_tmp_fixture(prefix) do
    suffix = "#{System.os_time(:nanosecond)}-#{System.unique_integer([:positive])}"
    Path.join(System.tmp_dir!(), "#{prefix}-#{suffix}")
  end

  defp run_exact_sha_hygiene_fixture!(scenario \\ "success", options \\ []) do
    fixture = unique_tmp_fixture("lockspire-exact-sha-hygiene")
    bin = Path.join(fixture, "bin")
    state = Path.join(fixture, "state")
    jq = System.find_executable("jq") || flunk("jq is required for the exact-SHA fixture")

    try do
      File.mkdir_p!(bin)
      File.mkdir_p!(state)
      File.write!(Path.join(bin, "git"), exact_hygiene_git_script())
      File.write!(Path.join(bin, "gh"), exact_hygiene_gh_script())
      File.write!(Path.join(bin, "mix"), exact_hygiene_mix_script())
      File.write!(Path.join(bin, "docker"), exact_hygiene_docker_script())
      File.write!(Path.join(bin, "jq"), "#!/usr/bin/env bash\nexec #{jq} \"$@\"\n")

      for command <- ["git", "gh", "mix", "docker", "jq"] do
        File.chmod!(Path.join(bin, command), 0o755)
      end

      args =
        [
          Paths.path("scripts/maintainer/repo_hygiene_check.sh"),
          "--accept-sha",
          Keyword.get(options, :accept_sha, acceptance_sha()),
          "--wait-seconds",
          Integer.to_string(Keyword.get(options, :wait_seconds, 0)),
          "--format",
          "json"
        ] ++
          Enum.flat_map(Keyword.get(options, :dispositions, []), fn disposition ->
            ["--warn-disposition", disposition]
          end)

      result =
        System.cmd(
          "bash",
          args,
          cd: Paths.path("."),
          env: [
            {"PATH", bin <> ":" <> System.get_env("PATH", "")},
            {"FAKE_REPO_ROOT", Paths.path(".")},
            {"FAKE_HYGIENE_SHA", acceptance_sha()},
            {"FAKE_HYGIENE_STATE", state},
            {"TMPDIR", state},
            {"FAKE_HYGIENE_SCENARIO", scenario},
            {"LOCKSPIRE_HYGIENE_REPOSITORY", "szTheory/lockspire"}
          ],
          stderr_to_stdout: true
        )

      refute Enum.any?(File.ls!(state), &String.starts_with?(&1, "lockspire-mix-ci."))
      result
    after
      File.rm_rf(fixture)
    end
  end

  defp acceptance_sha, do: String.duplicate("a", 40)

  defp exact_receipt_keys_in_order?(output) do
    keys = [
      "schema",
      "baseline_sha",
      "local_gate",
      "hygiene",
      "required_ci",
      "release_no_publish",
      "warn_dispositions",
      "supplemental_oidf"
    ]

    offsets = Enum.map(keys, &(:binary.match(output, ~s("#{&1}":)) |> elem(0)))
    offsets == Enum.sort(offsets)
  end

  defp exact_hygiene_git_script do
    ~S"""
    #!/usr/bin/env bash
    set -eu
    scenario="${FAKE_HYGIENE_SCENARIO:-success}"
    other_sha="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    bump() {
      file="$FAKE_HYGIENE_STATE/$1"
      count=0
      [ ! -f "$file" ] || count="$(cat "$file")"
      count=$((count + 1))
      printf '%s' "$count" > "$file"
      printf '%s' "$count"
    }
    case "$*" in
      "rev-parse --show-toplevel") printf '%s\n' "$FAKE_REPO_ROOT" ;;
      "rev-parse HEAD")
        count="$(bump head)"
        if [ "$scenario" = "head-mismatch" ] || { [ "$scenario" = "head-moves" ] && [ "$count" -ge 3 ]; }; then
          printf '%s\n' "$other_sha"
        else
          printf '%s\n' "$FAKE_HYGIENE_SHA"
        fi ;;
      "rev-parse main")
        count="$(bump main)"
        if [ "$scenario" = "main-mismatch" ] || { [ "$scenario" = "main-moves" ] && [ "$count" -ge 2 ]; } || { [ "$scenario" = "main-advances-during-poll" ] && [ "$count" -ge 3 ]; } || { [ "$scenario" = "docker-main-race" ] && [ -f "$FAKE_HYGIENE_STATE/docker-inspected" ]; }; then
          printf '%s\n' "$other_sha"
        else
          printf '%s\n' "$FAKE_HYGIENE_SHA"
        fi ;;
      "rev-parse origin/main")
        [ "$scenario" = "remote-mismatch" ] && printf '%s\n' "$other_sha" || printf '%s\n' "$FAKE_HYGIENE_SHA" ;;
      "status --porcelain") [ "$scenario" = "status-failure" ] && exit 93 || : ;;
      "fetch origin --prune"|"fetch origin --prune --tags"|"fetch --prune origin"|"fetch --prune --tags origin")
        [ "$scenario" = "fetch-failure" ] && exit 94 || exit 0 ;;
      *) printf 'unexpected fake git command\n' >&2; exit 90 ;;
    esac
    """
  end

  defp exact_hygiene_mix_script do
    ~S"""
    #!/usr/bin/env bash
    set -eu
    [ "$*" = "ci" ] || exit 91
    case "${FAKE_HYGIENE_SCENARIO:-success}" in
      mix-failure) printf 'partial success\n'; exit 95 ;;
      mix-signal) kill -TERM "$$" ;;
      mix-secret-failure) printf 'fixture-credential-sentinel\n'; exit 95 ;;
      mix-zero-tests) printf '0 tests, 0 failures\n' ;;
      mix-malformed) printf 'tests allegedly passed\n' ;;
      *) printf '1 test, 0 failures\n' ;;
    esac
    """
  end

  defp exact_hygiene_docker_script do
    ~S"""
    #!/usr/bin/env bash
    set -eu
    scenario="${FAKE_HYGIENE_SCENARIO:-success}"
    case "$*" in
      "version") exit 0 ;;
      "container ls --filter label=com.docker.compose.project=lockspire-adoption-demo --format {{.Names}}") : ;;
      "container ls --all --filter label=com.docker.compose.project=lockspire-adoption-demo --filter status=exited --format {{.Names}}")
        [ "$scenario" = "docker-warn" ] && printf 'stopped-demo\n' || : ;;
      "volume list --filter name=^lockspire-adoption-demo_(db_data|deps_volume|build_volume)$ --format {{.Name}}")
        [ "$scenario" != "docker-main-race" ] || : > "$FAKE_HYGIENE_STATE/docker-inspected" ;;
      *) printf 'unexpected fake docker command\n' >&2; exit 96 ;;
    esac
    """
  end

  defp exact_hygiene_gh_script do
    ~S"""
    #!/usr/bin/env bash
    set -eu
    sha="$FAKE_HYGIENE_SHA"
    scenario="${FAKE_HYGIENE_SCENARIO:-success}"
    bump() {
      file="$FAKE_HYGIENE_STATE/$1"
      count=0
      [ ! -f "$file" ] || count="$(cat "$file")"
      count=$((count + 1))
      printf '%s' "$count" > "$file"
      printf '%s' "$count"
    }
    ci_run() {
      id="${1:-1001}"; status="${2:-completed}"; conclusion="${3:-success}"
      repository="${4:-szTheory/lockspire}"; workflow_id="${5:-101}"; head_sha="${6:-$sha}"
      printf '{"id":%s,"run_number":10,"name":"CI","path":".github/workflows/ci.yml","workflow_id":%s,"event":"push","head_branch":"main","status":"%s","conclusion":"%s","head_sha":"%s","html_url":"https://example.test/actions/runs/%s","repository":{"full_name":"%s"}}' "$id" "$workflow_id" "$status" "$conclusion" "$head_sha" "$id" "$repository"
    }
    case "$*" in
      "auth status") exit 0 ;;
      "api repos/szTheory/lockspire/actions/workflows/ci.yml")
        printf '%s\n' '{"id":101,"name":"CI","path":".github/workflows/ci.yml"}' ;;
      "api repos/szTheory/lockspire/actions/workflows/release.yml")
        printf '%s\n' '{"id":202,"name":"Release","path":".github/workflows/release.yml"}' ;;
      "api repos/szTheory/lockspire/actions/workflows/ci.yml/runs?branch=main&event=push&head_sha="*)
        case "$scenario" in
          ci-runs-empty) printf '%s\n' '{"workflow_runs":[]}' ;;
          ci-runs-duplicate) printf '{"workflow_runs":['; ci_run; printf ','; ci_run 1002; printf ']}\n' ;;
          ci-runs-malformed) printf '%s\n' '{not-json' ;;
          ci-secret-response) printf '%s\n' '{"credential":"fixture-credential-sentinel"}' ;;
          ci-wrong-repository) printf '{"workflow_runs":['; ci_run 1001 completed success other/repository; printf ']}\n' ;;
          ci-wrong-workflow-id) printf '{"workflow_runs":['; ci_run 1001 completed success szTheory/lockspire 999; printf ']}\n' ;;
          ci-wrong-name) printf '{"workflow_runs":['; ci_run | sed 's/"name":"CI"/"name":"Other"/'; printf ']}\n' ;;
          ci-wrong-path) printf '{"workflow_runs":['; ci_run | sed 's#\.github/workflows/ci.yml#.github/workflows/other.yml#'; printf ']}\n' ;;
          ci-wrong-event) printf '{"workflow_runs":['; ci_run | sed 's/"event":"push"/"event":"workflow_dispatch"/'; printf ']}\n' ;;
          ci-wrong-branch) printf '{"workflow_runs":['; ci_run | sed 's/"head_branch":"main"/"head_branch":"other"/'; printf ']}\n' ;;
          ci-wrong-sha) printf '{"workflow_runs":['; ci_run 1001 completed success szTheory/lockspire 101 bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb; printf ']}\n' ;;
          ci-failed) printf '{"workflow_runs":['; ci_run 1001 completed failure; printf ']}\n' ;;
          ci-missing-url) printf '{"workflow_runs":['; ci_run | sed 's/,"html_url":"[^"]*"//'; printf ']}\n' ;;
          ci-cancelled) printf '{"workflow_runs":['; ci_run 1001 completed cancelled; printf ']}\n' ;;
          ci-queued-timeout) printf '{"workflow_runs":['; ci_run 1001 queued null; printf ']}\n' ;;
          ci-run-replaced)
            count="$(bump ci_run)"; printf '{"workflow_runs":['
            [ "$count" -eq 1 ] && ci_run 1001 queued null || ci_run 1002 completed success
            printf ']}\n' ;;
          main-advances-during-poll)
            count="$(bump ci_run)"; printf '{"workflow_runs":['
            [ "$count" -eq 1 ] && ci_run 1001 queued null || ci_run 1001 completed success
            printf ']}\n' ;;
          *) printf '{"workflow_runs":['; ci_run; printf ']}\n' ;;
        esac ;;
      "api repos/szTheory/lockspire/actions/workflows/release.yml/runs?branch=main&event=push&head_sha="*)
        printf '{"workflow_runs":[{"id":2001,"run_number":20,"name":"Release","path":".github/workflows/release.yml","workflow_id":202,"event":"push","head_branch":"main","status":"completed","conclusion":"success","head_sha":"%s","html_url":"https://example.test/actions/runs/2001","repository":{"full_name":"szTheory/lockspire"}}]}\n' "$sha" ;;
      "api repos/szTheory/lockspire/actions/runs/1001/jobs?per_page=100&page=1")
        total=7; [ "$scenario" = "ci-jobs-incomplete" ] && total=8
        printf '{"total_count":%s,"jobs":%s}\n' "$total" '[{"name":"Dialyzer","status":"completed","conclusion":"success"},{"name":"Release Hygiene Drift","status":"completed","conclusion":"success"},{"name":"Fast Checks","status":"completed","conclusion":"success"},{"name":"Minimum Supported Elixir/OTP","status":"completed","conclusion":"success"},{"name":"Integration Checks","status":"completed","conclusion":"success"},{"name":"Complete Coverage Evidence","status":"completed","conclusion":"success"},{"name":"Adoption Demo Smoke","status":"completed","conclusion":"success"}]' ;;
      "api repos/szTheory/lockspire/actions/runs/1001/jobs?per_page=100&page=2")
        printf '%s\n' '{"total_count":8,"jobs":[]}' ;;
      "api repos/szTheory/lockspire/actions/runs/2001/jobs?per_page=100&page=1")
        case "$scenario" in
          release-published) publication=success; total=5; tail='' ;;
          release-job-missing) publication=skipped; total=4; tail='' ;;
          release-job-duplicate) publication=skipped; total=6; tail=',{"name":"Publish verified release to Hex","status":"completed","conclusion":"skipped"}' ;;
          *) publication=skipped; total=5; tail='' ;;
        esac
        jobs='[{"name":"Maintain Release Please PR","status":"completed","conclusion":"success"},{"name":"Validate exact main head and CI evidence","status":"completed","conclusion":"skipped"},{"name":"Prove exact package before publication","status":"completed","conclusion":"skipped"},{"name":"Publish verified release to Hex","status":"completed","conclusion":"'"$publication"'"},{"name":"Verify public install truth","status":"completed","conclusion":"skipped"}'
        [ "$scenario" = "release-job-missing" ] && jobs='[{"name":"Maintain Release Please PR","status":"completed","conclusion":"success"},{"name":"Validate exact main head and CI evidence","status":"completed","conclusion":"skipped"},{"name":"Prove exact package before publication","status":"completed","conclusion":"skipped"},{"name":"Publish verified release to Hex","status":"completed","conclusion":"skipped"}'
        printf '{"total_count":%s,"jobs":%s%s]}\n' "$total" "$jobs" "$tail" ;;
      *) printf 'unexpected fake gh command\n' >&2; exit 92 ;;
    esac
    """
  end

  defp fake_git_script do
    """
    #!/usr/bin/env bash
    set -eu
    scenario="${FAKE_GIT_SCENARIO:-default}"
    object_format=sha256
    [[ "$scenario" == object-sha1-* ]] && object_format=sha1
    object_width=64
    [[ "$object_format" == sha1 ]] && object_width=40
    object_oid() { printf "%0${object_width}d\\n" "$1"; }
    candidate_oid() {
      length="${scenario##*-}"
      printf "%0${length}d\\n" "$1"
    }
    [[ -z "${FAKE_COMMAND_LOG:-}" ]] || printf '%s\\n' "$*" >> "$FAKE_COMMAND_LOG"
    [[ -z "${FAKE_WRITER_SENTINEL:-}" ]] || : > "$FAKE_WRITER_SENTINEL"
    bump() {
      [[ -n "${FAKE_STATE_DIR:-}" ]] || { printf '1'; return; }
      file="$FAKE_STATE_DIR/$1"
      count=0
      [[ ! -f "$file" ]] || count="$(cat "$file")"
      count=$((count + 1))
      printf '%s' "$count" > "$file"
      printf '%s' "$count"
    }
    case "$*" in
      "rev-parse --show-toplevel")
        count="$(bump repository)"
        [[ "$scenario" == drift-repository && "$count" -gt 2 ]] && printf '%s\\n' "$FAKE_REPO_ROOT-drifted" || printf '%s\\n' "$FAKE_REPO_ROOT" ;;
      "rev-parse HEAD")
        count="$(bump head)"
        case "$scenario" in
          missing-head) exit 128 ;;
          failed-head-with-stdout) printf 'failed-command-stdout\\n'; exit 128 ;;
          malformed-head) printf 'short-sha\\n' ;;
          object-sha1-*|object-sha256-*) object_oid 1 ;;
          *) [[ "$scenario" == drift-head && "$count" -gt 1 ]] && printf '%064d\\n' 9 || printf '%064d\\n' 1 ;;
        esac ;;
      "rev-parse main")
        count="$(bump main)"
        [[ "$scenario" == missing-main ]] && exit 128
        if [[ "$scenario" == object-sha1-* || "$scenario" == object-sha256-* ]]; then object_oid 2
        else [[ "$scenario" == drift-main && "$count" -gt 1 ]] && printf '%064d\\n' 9 || printf '%064d\\n' 2; fi ;;
      "rev-parse origin/main"|"rev-parse ${FAKE_CREDENTIAL:-__no_credential__}/main")
        count="$(bump remote_main)"
        [[ "$scenario" == missing-remote-main ]] && exit 128
        if [[ "$scenario" == object-sha1-* || "$scenario" == object-sha256-* ]]; then object_oid 3
        else [[ "$scenario" == drift-remote-main && "$count" -gt 1 ]] && printf '%064d\\n' 9 || printf '%064d\\n' 3; fi ;;
      "rev-parse --show-object-format") printf '%s\\n' "$object_format" ;;
      "fetch --prune --tags origin"|"fetch --prune --tags ${FAKE_CREDENTIAL:-__no_credential__}") exit 0 ;;
      "status --porcelain=v2 --branch")
        count="$(bump status)"
        case "$scenario:$count" in
          failed-porcelain:*) printf 'malformed status row\\n' ;;
          status-capture-failed:1) exit 42 ;;
          status-recheck-failed:2) exit 43 ;;
        esac
        if [[ "$scenario" == object-sha1-* || "$scenario" == object-sha256-* ]]; then
          printf '# branch.oid '; object_oid 1; printf '# branch.head main\\n# branch.ab +2 -3\\n'
        else
          printf '# branch.oid %064d\\n# branch.head main\\n# branch.ab +2 -3\\n' 1
        fi
        if [[ "$count" -gt 1 ]]; then
          case "$scenario" in
            worktree-modified) printf '1 .M N... %064d %064d %064d %064d %064d tracked.txt\\n' 1 1 1 1 1 ;;
            worktree-deleted) printf '1 .D N... %064d %064d %064d %064d %064d tracked.txt\\n' 1 1 1 1 1 ;;
            worktree-untracked) printf '? newly-untracked.txt\\n' ;;
            owned-near-name) printf '? %s.tmp.near-name\\n' "$FAKE_OUTPUT" ;;
          esac
          if [[ -n "${FAKE_OUTPUT:-}" ]]; then
            for owned in "${FAKE_OUTPUT}.tmp."* "${FAKE_OUTPUT}.git."* \
              "${FAKE_OUTPUT}.github-render."* "${FAKE_OUTPUT}.maintained."* \
              "${FAKE_OUTPUT}.recheck-"*; do
              [[ -e "$owned" ]] && printf '? %s\\n' "$owned"
            done
            :
          fi
        fi ;;
      "rev-list --left-right --count main...origin/main"|"rev-list --left-right --count main...${FAKE_CREDENTIAL:-__no_credential__}/main")
        [[ "$scenario" == malformed-divergence ]] && printf '2 ahead 3 behind\\n' || printf '2 3\\n' ;;
      "for-each-ref --format=%(refname)%09%(objectname) refs/heads refs/remotes")
        if [[ "$scenario" == hold-before-rename ]]; then
          : > "$FAKE_HOLD_READY"
          while [[ ! -e "$FAKE_HOLD_RELEASE" ]]; do sleep 0.01; done
        fi
        case "$scenario" in
          credential-redaction)
            printf 'refs/heads/%s\\t%064d\\n' "$FAKE_CREDENTIAL" 2
            [[ -z "${FAKE_CREDENTIAL_ALT:-}" ]] || printf 'refs/heads/%s\\t%064d\\n' "$FAKE_CREDENTIAL_ALT" 4
            printf 'refs/remotes/origin/main\\t%064d\\n' 3 ;;
          object-sha1-branches-*|object-sha256-branches-*)
            printf 'refs/heads/branches-candidate\\t'; candidate_oid 4
            printf 'refs/remotes/origin/branches-sibling\\t'; object_oid 5 ;;
          empty-branches) : ;;
          malformed-branches) printf 'refs/heads/main\\tbad-sha\\n' ;;
          unknown-branches) printf 'refs/unknown/main\\t%064d\\n' 2 ;;
          failed-branches) exit 18 ;;
          *) printf 'refs/heads/main\\t%064d\\nrefs/remotes/origin/main\\t%064d\\n' 2 3 ;;
        esac ;;
      "for-each-ref --format=%(refname)%09%(objectname) refs/tags")
        case "$scenario" in
          credential-redaction)
            printf 'refs/tags/%s\\t%064d\\n' "$FAKE_CREDENTIAL" 3
            [[ -z "${FAKE_CREDENTIAL_ALT:-}" ]] || printf 'refs/tags/%s\\t%064d\\n' "$FAKE_CREDENTIAL_ALT" 4 ;;
          object-sha1-tags-*|object-sha256-tags-*)
            printf 'refs/tags/tags-candidate\\t'; candidate_oid 4
            printf 'refs/tags/tags-sibling\\t'; object_oid 5 ;;
          empty-tags) : ;;
          malformed-tags) printf 'refs/tags/v1.5.0\\tbad-sha\\n' ;;
          failed-tags) exit 18 ;;
          *) printf 'refs/tags/v1.5.0\\t%064d\\n' 3 ;;
        esac ;;
      "worktree list --porcelain -z")
        case "$scenario" in
          credential-redaction)
            printf 'worktree %s/%s\\0HEAD %064d\\0\\0' "$FAKE_REPO_ROOT" "$FAKE_CREDENTIAL" 2
            [[ -z "${FAKE_CREDENTIAL_ALT:-}" ]] || printf 'worktree %s/%s\\0HEAD %064d\\0\\0' "$FAKE_REPO_ROOT" "$FAKE_CREDENTIAL_ALT" 4 ;;
          object-sha1-worktrees-*|object-sha256-worktrees-*)
            printf 'worktree %s/worktrees-candidate\\0HEAD ' "$FAKE_REPO_ROOT"; candidate_oid 4 | tr '\\n' '\\0'
            printf '\\0'
            printf 'worktree %s/worktrees-sibling\\0HEAD ' "$FAKE_REPO_ROOT"; object_oid 5 | tr '\\n' '\\0'
            printf '\\0' ;;
          empty-worktrees) : ;;
          malformed-worktrees) printf 'worktree %s\\0HEAD bad-sha\\0\\0' "$FAKE_REPO_ROOT" ;;
          failed-worktrees) exit 18 ;;
          failed-worktree-id-rollover)
            printf 'worktree %s/worktree-sibling\\0HEAD %064d\\0\\0worktree %s/worktree-id-failed\\0HEAD %064d\\0worktree %s/worktree-tail\\0HEAD %064d\\0\\0' "$FAKE_REPO_ROOT" 2 "$FAKE_REPO_ROOT" 3 "$FAKE_REPO_ROOT" 4 ;;
          empty-worktree-id-blank-close)
            printf 'worktree %s/worktree-sibling\\0HEAD %064d\\0\\0worktree %s/worktree-id-failed\\0HEAD %064d\\0\\0' "$FAKE_REPO_ROOT" 2 "$FAKE_REPO_ROOT" 3 ;;
          malformed-worktree-id-final-flush)
            printf 'worktree %s/worktree-sibling\\0HEAD %064d\\0\\0worktree %s/worktree-id-failed\\0HEAD %064d' "$FAKE_REPO_ROOT" 2 "$FAKE_REPO_ROOT" 3 ;;
          *) printf 'worktree %s\\0HEAD %064d\\0branch refs/heads/main\\0\\0' "$FAKE_REPO_ROOT" 2 ;;
        esac ;;
      "hash-object --stdin")
        value="$(cat)"
        if [[ "$scenario" == object-sha1-* || "$scenario" == object-sha256-* ]]; then
          object_oid 8
          exit 0
        fi
        case "$value" in
          *refs/heads/main)
            [[ "$scenario" == failed-branch-id ]] && exit 19
            printf '%064d\\n' 11 ;;
          *refs/remotes/origin/main) printf '%064d\\n' 12 ;;
          *refs/tags/v1.5.0)
            case "$scenario" in
              empty-tag-id) : ;;
              malformed-tag-id) printf 'not-a-git-object-id\\n' ;;
              *) printf '%064d\\n' 13 ;;
            esac ;;
          *worktree-id-failed)
            case "$scenario" in
              failed-worktree-id-rollover) exit 20 ;;
              empty-worktree-id-blank-close) : ;;
              malformed-worktree-id-final-flush) printf 'short-object-id\\n' ;;
              *) printf '%064d\\n' 14 ;;
            esac ;;
          *worktree*) printf '%064d\\n' 14 ;;
          *) printf '%s' "$value" | command -p git hash-object --stdin ;;
        esac ;;
      "ls-files -z -- "*)
        if [[ "$scenario" == credential-redaction ]]; then
          [[ "$*" == *".planning/todos"* ]] && printf '.planning/todos/%s.md\\0' "$FAKE_CREDENTIAL" || :
          exit 0
        fi
        if [[ "$scenario" == maintained-family-failure || "$scenario" == maintained-marker-zero-family-failure ]] && [[ "$*" == *".planning/debug"* ]]; then
          exit 32
        fi
        if [[ "$scenario" == maintained || "$scenario" == maintained-family-failure || "$scenario" == maintained-reversed || "$scenario" == drift-maintained || "$scenario" == maintained-superseded-gaps || "$scenario" == maintained-missing-gap-summary || "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses || "$scenario" == maintained-active-lifecycle || "$scenario" == maintained-active-incidental || "$scenario" == maintained-active-uat || "$scenario" == maintained-active-uat-near-misses || "$scenario" == maintained-review-fix-near-miss || "$scenario" == maintained-archive-action-matrix || "$scenario" == maintained-archive-incidental-fix-now || "$scenario" == maintained-archive-all-excluded || "$scenario" == maintained-archive-mixed || "$scenario" == maintained-archive-mixed-reversed || "$scenario" == maintained-archive-late-marker || "$scenario" == maintained-archive-benign || "$scenario" == maintained-archive-incidental-terms || "$scenario" == maintained-archive-unreadable ]]; then
          case "$*" in
            *".planning/todos"*)
              count="$(bump maintained_todos)"
              [[ "$scenario" == drift-maintained && "$count" -gt 1 ]] && printf '.planning/todos/drift.md\\0' || : ;;
            *".planning/debug"*)
              case "$scenario" in
                maintained-archive-action-matrix)
                  for marker in fix status outcome disposition heading; do
                    for phrase in resolved historical scope; do
                      for order in before after; do
                        printf '.planning/debug/matrix-%s-%s-%s.md\\0' "$marker" "$phrase" "$order"
                      done
                    done
                  done
                  printf '.planning/debug/matrix-conflict.md\\0' ;;
                maintained-archive-all-excluded) printf '.planning/debug/cache/ignored.md\\0' ;;
                maintained-archive-mixed) printf '.planning/debug/cache/ignored.md\\0.planning/debug/actionable.md\\0' ;;
                maintained-archive-mixed-reversed) printf '.planning/debug/actionable.md\\0.planning/debug/cache/ignored.md\\0' ;;
                maintained-archive-late-marker) printf '.planning/debug/late-actionable.md\\0' ;;
                maintained-archive-benign) printf '.planning/debug/benign.md\\0' ;;
                maintained-archive-incidental-terms) printf '.planning/debug/incidental-terms.md\\0' ;;
                maintained-archive-unreadable) printf '.planning/debug/unreadable.md\\0' ;;
                *) printf '.planning/debug/complete.md\\0.planning/debug/actionable.md\\0' ;;
              esac ;;
            *".planning/quick"*) printf '.planning/quick/complete.md\\0' ;;
            *".planning/threads"*)
              [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf '.planning/threads/next-roadmap-assessment.md\\0' || : ;;
            *".planning/phases"*)
              if [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses || "$scenario" == maintained-archive-late-marker || "$scenario" == maintained-archive-benign || "$scenario" == maintained-archive-incidental-terms || "$scenario" == maintained-archive-incidental-fix-now || "$scenario" == maintained-archive-unreadable ]]; then
                :
              elif [[ "$scenario" == maintained-active-lifecycle || "$scenario" == maintained-active-incidental ]]; then
                printf '.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md\\0.planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md\\0'
                [[ "$scenario" == maintained-active-lifecycle ]] && printf '.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW-FIX.md\\0' || :
              elif [[ "$scenario" == maintained-active-uat ]]; then
                printf '.planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md\\0.planning/phases/139-required-truth-reconciliation/139-UAT.md\\0'
              elif [[ "$scenario" == maintained-active-uat-near-misses ]]; then
                printf '.planning/phases/current/missing-status-UAT.md\\0.planning/phases/current/duplicate-status-UAT.md\\0.planning/phases/current/unknown-status-UAT.md\\0.planning/phases/current/missing-current-test-UAT.md\\0.planning/phases/current/missing-tests-UAT.md\\0.planning/phases/current/fenced-headings-UAT.md\\0.planning/phases/current/commented-headings-UAT.md\\0.planning/phases/current/frontmatter-headings-UAT.md\\0.planning/phases/current/indented-code-headings-UAT.md\\0'
              elif [[ "$scenario" == maintained-review-fix-near-miss ]]; then
                printf '.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW-FIX.md\\0'
              elif [[ "$scenario" == maintained-superseded-gaps || "$scenario" == maintained-missing-gap-summary ]]; then
                printf '.planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md\\0'
              elif [[ "$scenario" == maintained-reversed ]]; then
                printf '.planning/phases/current/scope-VERIFICATION.md\\0.planning/phases/current/resolved-VERIFICATION.md\\0.planning/phases/current/historical-VERIFICATION.md\\0.planning/phases/current/defer-VERIFICATION.md\\0.planning/phases/current/138-VERIFICATION.md\\0.planning/debug/actionable.md\\0'
              else
                printf '.planning/debug/actionable.md\\0.planning/phases/current/138-VERIFICATION.md\\0.planning/phases/current/defer-VERIFICATION.md\\0.planning/phases/current/historical-VERIFICATION.md\\0.planning/phases/current/resolved-VERIFICATION.md\\0.planning/phases/current/scope-VERIFICATION.md\\0'
              fi ;;
            *".planning/milestones"*)
              [[ "$scenario" == maintained-archive-incidental-fix-now ]] && printf '.planning/milestones/v1.27-phases/99-signer-extraction-jwt-default-issuance/99-VERIFICATION.md\\0' || : ;;
            *".planning/ROADMAP.md"*)
              [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf '.planning/ROADMAP.md\\0' || : ;;
            *".planning/STATE.md"*)
              [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf '.planning/STATE.md\\0' || : ;;
            *".planning/PROJECT.md"*)
              [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf '.planning/PROJECT.md\\0' || : ;;
            *".planning/RELEASE-TRAIN.md"*)
              [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf '.planning/RELEASE-TRAIN.md\\0' || : ;;
            *".planning/DEVELOPMENT-TRAIN.md"*)
              [[ "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf '.planning/DEVELOPMENT-TRAIN.md\\0' || : ;;
            *"_build"*) printf '_build/generated/finding.md\\0' ;;
          esac
        fi ;;
      "show HEAD:.planning/debug/complete.md") printf 'completed terminal proof\\n' ;;
      "show HEAD:.planning/todos/"*)
        if [[ "$scenario" == credential-redaction ]]; then
          printf 'follow-up trigger supersedes:%s\\n' "$FAKE_CREDENTIAL"
        else
          printf 'follow-up trigger\\n'
        fi ;;
      "show HEAD:.planning/debug/actionable.md") printf 'fix-now supersedes:old-record\\n' ;;
      "show HEAD:.planning/debug/late-actionable.md") printf '%0410d\\nfix-now\\n' 0 ;;
      "show HEAD:.planning/debug/benign.md") printf 'completed terminal proof\\n' ;;
      "show HEAD:.planning/debug/incidental-terms.md") printf '%s\\n' '---' 'status: issues_found' '---' 'Historical review proof has no contradictory claims and rejects ambiguous input.' ;;
      "show HEAD:.planning/debug/unreadable.md") exit 23 ;;
      "show HEAD:.planning/debug/matrix-conflict.md")
        printf '%s\\n' 'status: actionable' 'disposition: already-resolved' ;;
      "show HEAD:.planning/debug/matrix-"*)
        path="${2#HEAD:.planning/debug/matrix-}"
        stem="${path%.md}"
        marker="${stem%%-*}"
        rest="${stem#*-}"
        phrase="${rest%%-*}"
        order="${rest##*-}"
        case "$marker" in
          fix) marker_text='fix-now' ;;
          status) marker_text='status: actionable' ;;
          outcome) marker_text='outcome: blocked' ;;
          disposition) marker_text='disposition: unresolved' ;;
          heading) marker_text='## Actionable' ;;
        esac
        case "$phrase" in
          resolved) phrase_text='terminal proof is unavailable for this archived investigation' ;;
          historical) phrase_text='retain historical context while current action remains open' ;;
          scope) phrase_text='out of scope alternatives are documented separately' ;;
        esac
        if [[ "$order" == before ]]; then printf '%s\\n%s\\n' "$marker_text" "$phrase_text"
        else printf '%s\\n%s\\n' "$phrase_text" "$marker_text"; fi ;;
      "show HEAD:.planning/milestones/v1.27-phases/99-signer-extraction-jwt-default-issuance/99-VERIFICATION.md")
        printf '%s\\n' '---' 'status: passed' '---' '# Archived Verification Report' '## Goal Achievement' 'Choosing fix-now vs. accept-and-track is a risk decision, not an automated determination.' ;;
      "show HEAD:.planning/quick/complete.md") printf 'completed terminal proof\\n' ;;
      "show HEAD:.planning/phases/current/138-VERIFICATION.md") printf 'unmatched candidate\\n' ;;
      "show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md")
        if [[ "$scenario" == maintained-active-lifecycle || "$scenario" == maintained-active-incidental ]]; then
          printf '%s\\n' '---' 'status: gaps_found' '---' '# Baseline Inventory Verification Report' '## Goal Achievement'
          [[ "$scenario" == maintained-active-incidental ]] && printf '%s\\n' 'Current gaps lack terminal proof and remain actionable.' || printf '%s\\n' 'Current verification gaps.'
        else
          printf 'status: gaps_found\\nAggregate GitHub failure can retain\\nCapture immutable baseline refs before all collection\\nID-generation failure silently drops\\nUse NUL-delimited Git output\\n'
        fi ;;
      "show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md")
        printf '%s\\n' '---' 'status: issues_found' '---' '# Baseline Inventory Code Review Report' '## Summary'
        [[ "$scenario" == maintained-active-incidental ]] && printf '%s\\n' 'Current issues lack terminal proof and remain actionable.' || printf '%s\\n' 'Current review findings.' ;;
      "show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW-FIX.md")
        if [[ "$scenario" == maintained-review-fix-near-miss ]]; then
          printf '%s\\n' '---' 'status: all_fixed' '---' '# Baseline Inventory Code Review Fix Draft' '## Fixed Issues'
        else
          printf '%s\\n' '---' 'status: all_fixed' '---' '# Baseline Inventory Code Review Fix Report' '## Fixed Issues'
        fi ;;
      "show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md")
        printf '%s\\n' '---' 'status: complete' '---' '## Current Test' 'The current test run finished.' '## Tests' 'All maintained UAT tests passed.' 'Actionable prose says fix-now and issues_found, but does not override lifecycle status.' ;;
      "show HEAD:.planning/phases/139-required-truth-reconciliation/139-UAT.md")
        phase_heading='Phase '
        printf '%s\\n' '---' 'status: partial' '---' "# ${phase_heading}139 UAT" '## Current Test' 'The current test run is pending.' '## Tests' 'Finish the current test before rechecking.' 'The recheck trigger is pending test completion; fix-now is only body prose.' ;;
      "show HEAD:.planning/phases/current/missing-status-UAT.md")
        printf '%s\\n' '---' 'owner: test' '---' '## Current Test' '## Tests' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/duplicate-status-UAT.md")
        printf '%s\\n' '---' 'status: complete' 'status: partial' '---' '## Current Test' '## Tests' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/unknown-status-UAT.md")
        printf '%s\\n' '---' 'status: upcoming' '---' '## Current Test' '## Tests' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/missing-current-test-UAT.md")
        printf '%s\\n' '---' 'status: complete' '---' '## Tests' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/missing-tests-UAT.md")
        printf '%s\\n' '---' 'status: partial' '---' '## Current Test' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/fenced-headings-UAT.md")
        printf '%s\\n' '---' 'status: complete' '---' '```markdown' '## Current Test' '## Tests' '```' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/commented-headings-UAT.md")
        printf '%s\\n' '---' 'status: complete' '---' '<!--' '## Current Test' '## Tests' '-->' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/frontmatter-headings-UAT.md")
        printf '%s\\n' '---' 'status: complete' '## Current Test' '## Tests' '---' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/current/indented-code-headings-UAT.md")
        printf '%s\\n' '---' 'status: complete' '---' '    ## Current Test' '    ## Tests' 'fix-now issues_found actionable prose' ;;
      "show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-07-SUMMARY.md"|"show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-08-SUMMARY.md"|"show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-09-SUMMARY.md")
        printf -- '---\\nstatus: complete\\n---\\n' ;;
      "show HEAD:.planning/phases/138-baseline-inventory-evidence-taxonomy/138-10-SUMMARY.md")
        [[ "$scenario" == maintained-missing-gap-summary ]] && exit 1
        printf -- '---\\nstatus: complete\\n---\\n' ;;
      "show HEAD:.planning/phases/current/defer-VERIFICATION.md") printf 'follow-up trigger\\n' ;;
      "show HEAD:.planning/phases/current/historical-VERIFICATION.md") printf 'retain historical\\n' ;;
      "show HEAD:.planning/phases/current/resolved-VERIFICATION.md") printf 'already resolved\\n' ;;
      "show HEAD:.planning/phases/current/scope-VERIFICATION.md") printf 'out of scope\\n' ;;
      "show HEAD:.planning/phases/old/complete.md") printf 'completed terminal proof\\n' ;;
      "show HEAD:.planning/threads/next-roadmap-assessment.md")
        if [[ "$scenario" == maintained-current-planning-near-misses ]]; then
          printf '# Lockspire Roadmap\\n## Phases\\n'
        else
          printf '# Next Roadmap Assessment\\n**Status:** Active cross-session context  \\n**Purpose:** Preserve current roadmap judgment.\\n'
        fi ;;
      "show HEAD:.planning/ROADMAP.md")
        [[ "$scenario" == maintained-current-planning-near-misses ]] && printf '# Lockspire Roadmap Draft\\n## Phases\\n' || printf '# Lockspire Roadmap\\n## Phases\\n' ;;
      "show HEAD:.planning/STATE.md")
        [[ "$scenario" == maintained-current-planning-near-misses ]] && printf '# Project State Draft\\n## Current Position\\n' || printf '# Project State\\n## Current Position\\n' ;;
      "show HEAD:.planning/PROJECT.md")
        [[ "$scenario" == maintained-current-planning-near-misses ]] && printf '# Lockspire\\n## Previous Milestone: v1.37\\n' || printf '# Lockspire\\n## Current Milestone: v1.38 Repository Baseline & Reconciliation\\n' ;;
      "show HEAD:.planning/RELEASE-TRAIN.md")
        [[ "$scenario" == maintained-current-planning-near-misses ]] && printf '# Lockspire Development Train\\n## Current Baseline\\n' || printf '# Lockspire Release Train\\n## Current Baseline\\n' ;;
      "show HEAD:.planning/DEVELOPMENT-TRAIN.md")
        [[ "$scenario" == maintained-current-planning-near-misses ]] && printf '# Lockspire Release Train\\n## Default Posture\\n' || printf '# Lockspire Development Train\\n## Default Posture\\n' ;;
      "grep -z -nE TODO|FIXME -- lib test scripts docs")
        case "$scenario" in
          maintained-marker-failure) exit 31 ;;
          maintained-marker-failure-2) exit 2 ;;
          maintained-marker-failure-42) exit 42 ;;
          maintained-marker-zero|maintained-marker-zero-family-failure|maintained-archive-action-matrix|maintained-archive-all-excluded|maintained-archive-mixed|maintained-archive-mixed-reversed|maintained-archive-late-marker|maintained-archive-benign|maintained-archive-incidental-terms|maintained-archive-unreadable) exit 1 ;;
          maintained-marker-exit-one-output)
            printf 'lib/lockspire/example.ex\\x001\\x00TODO follow-up\\n'
            exit 1 ;;
          maintained-marker-exit-zero-empty) exit 0 ;;
          maintained-marker-malformed)
            printf 'lib/lockspire/example.ex\\x00'
            exit 0 ;;
        esac
        [[ "$scenario" == maintained || "$scenario" == maintained-family-failure || "$scenario" == maintained-reversed || "$scenario" == maintained-current-planning || "$scenario" == maintained-current-planning-near-misses ]] && printf 'lib/lockspire/example.ex\\x001\\x00TODO follow-up\\n' ;;
      "--version") printf 'git version fixture\\n' ;;
      *) exit 17 ;;
    esac
    """
  end

  defp prelock_barrier_mkdir_script do
    """
    #!/usr/bin/env bash
    set -eu
    target="${!#}"
    if [[ "$target" == *.lock && -n "${FAKE_PRELOCK_READY:-}" && ! -e "$FAKE_PRELOCK_SEEN" ]]; then
      : > "$FAKE_PRELOCK_SEEN"
      : > "$FAKE_PRELOCK_READY"
      while [[ ! -e "$FAKE_PRELOCK_RELEASE" ]]; do sleep 0.01; done
    fi
    command -p mkdir "$@"
    """
  end

  defp fake_gh_script do
    """
    #!/usr/bin/env bash
    set -eu
    scenario="${FAKE_GH_SCENARIO:-default}"
    [[ -z "${FAKE_WRITER_SENTINEL:-}" ]] || : > "$FAKE_WRITER_SENTINEL"
    bump() {
      [[ -n "${FAKE_STATE_DIR:-}" ]] || { printf '1'; return; }
      file="$FAKE_STATE_DIR/$1"
      count=0
      [[ ! -f "$file" ]] || count="$(cat "$file")"
      count=$((count + 1))
      printf '%s' "$count" > "$file"
      printf '%s' "$count"
    }
    case "$1 $2" in
      "auth status") [[ "$scenario" == auth-failed ]] && exit 1 || exit 0 ;;
      "repo view") printf 'lockspire/fixture\\n' ;;
      "api graphql")
        if [[ "$scenario" == hold-pagination && "$*" == *pullRequests* ]]; then
          : > "$FAKE_HOLD_READY"
          while [[ ! -e "$FAKE_HOLD_RELEASE" ]]; do sleep 0.01; done
        fi
        [[ "$scenario" == api-failed ]] && exit 19
        if [[ "$*" == *pullRequestId=* ]]; then
          [[ "$scenario" == nested-api-failed ]] && exit 19
          nested_oid="1111111111111111111111111111111111111111"
          [[ "$scenario" == github-object-64 ]] && nested_oid="1111111111111111111111111111111111111111111111111111111111111111"
          [[ "$scenario" == identical-duplicate-reversed && "$*" == *pullRequestId=PR-2* ]] && nested_oid="4444444444444444444444444444444444444444"
          if [[ "$scenario" == nested-many ]]; then
            jq -nc '{data:{node:{commits:{nodes:[{commit:{oid:"1111111111111111111111111111111111111111",statusCheckRollup:{contexts:{totalCount:101,nodes:[range(0;100)|{__typename:"CheckRun",name:("ci-" + tostring),status:"COMPLETED",conclusion:"SUCCESS"}],pageInfo:{hasNextPage:true,endCursor:"check-cursor-1"}}}}}]}}}}'
            jq -nc '{data:{node:{commits:{nodes:[{commit:{oid:"1111111111111111111111111111111111111111",statusCheckRollup:{contexts:{totalCount:101,nodes:[{__typename:"CheckRun",name:"ci-100",status:"COMPLETED",conclusion:"SUCCESS"}],pageInfo:{hasNextPage:false,endCursor:null}}}}}]}}}}'
            exit 0
          fi
          if [[ "$scenario" == nested-head-page-changing ]]; then
            jq -nc '{data:{node:{commits:{nodes:[{commit:{oid:"1111111111111111111111111111111111111111",statusCheckRollup:{contexts:{totalCount:1,nodes:[],pageInfo:{hasNextPage:true,endCursor:"check-cursor-1"}}}}}]}}}}'
            jq -nc '{data:{node:{commits:{nodes:[{commit:{oid:"3333333333333333333333333333333333333333",statusCheckRollup:{contexts:{totalCount:1,nodes:[{__typename:"CheckRun",name:"ci",status:"COMPLETED",conclusion:"SUCCESS"}],pageInfo:{hasNextPage:false,endCursor:null}}}}}]}}}}'
            exit 0
          fi
          jq -nc --arg scenario "$scenario" --arg nested_oid "$nested_oid" '
            def checkrun($name; $status; $conclusion):
              {__typename:"CheckRun",name:$name,status:$status,conclusion:$conclusion};
            def statuscontext($name; $state):
              {__typename:"StatusContext",context:$name,state:$state};
            (if $scenario == "pending-check" or $scenario == "outer-errors-pending" or $scenario == "nested-errors-pending" then [checkrun("ci";"COMPLETED";"SUCCESS"),checkrun("deploy";"IN_PROGRESS";null)]
             elif $scenario == "legacy-failure" then [checkrun("ci";"COMPLETED";"SUCCESS"),statuscontext("legacy";"FAILURE")]
             elif $scenario == "action-required" then [checkrun("ci";"COMPLETED";"ACTION_REQUIRED")]
             elif $scenario == "startup-failure" then [checkrun("ci";"COMPLETED";"STARTUP_FAILURE")]
             elif $scenario == "unknown-conclusion" then [checkrun("ci";"COMPLETED";"FUTURE_STATE")]
             elif $scenario == "mixed-nonterminal" then [checkrun("ci";"COMPLETED";"SUCCESS"),statuscontext("legacy";"PENDING")]
             else [checkrun("ci";"COMPLETED";"SUCCESS")] end) as $nodes |
            (if $scenario == "nested-head-multiple" then
               [{commit:{oid:"1111111111111111111111111111111111111111",statusCheckRollup:{contexts:{totalCount:0,nodes:[],pageInfo:{hasNextPage:false,endCursor:null}}}}},
                {commit:{oid:"3333333333333333333333333333333333333333",statusCheckRollup:{contexts:{totalCount:0,nodes:[],pageInfo:{hasNextPage:false,endCursor:null}}}}}]
             else [{commit:((if $scenario == "nested-head-missing" then {}
                             elif $scenario == "nested-head-null" then {oid:null}
                             elif $scenario == "nested-head-malformed" then {oid:"forbidden raw diagnostic"}
                             elif $scenario == "nested-head-mismatch" then {oid:"3333333333333333333333333333333333333333"}
                             else {oid:$nested_oid} end) + {statusCheckRollup:{contexts:{
              totalCount:(if $scenario == "nested-count-mismatch" then (($nodes|length)+1) else ($nodes|length) end),
              nodes:$nodes,
              pageInfo:(if $scenario == "nested-malformed-page-info" then {hasNextPage:"false"} else {hasNextPage:false,endCursor:null} end)
            }}})}] end) as $commits |
            {data:{node:{commits:{nodes:$commits}}}} + (if $scenario == "nested-errors-pending" then {errors:[{message:"forbidden raw diagnostic"}]} else {} end)'
          exit 0
        fi
        if [[ "$scenario" == credential-redaction-limitation ]]; then
          if [[ "$*" == *pullRequests* ]]; then
            jq -nc --arg credential "$FAKE_CREDENTIAL" '{data:{repository:{pullRequests:{nodes:[
              {id:$credential,number:1,title:"first",url:"https://example.test/pr/1",updatedAt:"2026-08-28T00:00:00Z",state:"OPEN",isDraft:false,mergeStateStatus:"CLEAN",reviewDecision:"APPROVED",headRefName:"feature",headRefOid:"1111111111111111111111111111111111111111",baseRefName:"main",baseRefOid:"2222222222222222222222222222222222222222",commits:{nodes:[{commit:{statusCheckRollup:{state:"SUCCESS"}}}]}},
              {id:$credential,number:1,title:"second",url:"https://example.test/pr/1",updatedAt:"2026-08-28T00:00:00Z",state:"OPEN",isDraft:false,mergeStateStatus:"CLEAN",reviewDecision:"APPROVED",headRefName:"feature",headRefOid:"1111111111111111111111111111111111111111",baseRefName:"main",baseRefOid:"2222222222222222222222222222222222222222",commits:{nodes:[{commit:{statusCheckRollup:{state:"SUCCESS"}}}]}}
            ],pageInfo:{hasNextPage:false,endCursor:null}}}}}'
          else
            jq -nc '{data:{repository:{issues:{nodes:[],pageInfo:{hasNextPage:false,endCursor:null}}}}}'
          fi
          exit 0
        fi
        if [[ "$scenario" == credential-redaction ]]; then
          if [[ "$*" == *pullRequests* ]]; then
            jq -nc --arg credential "$FAKE_CREDENTIAL" '{data:{repository:{pullRequests:{nodes:[{
              id:"PR-CREDENTIAL",number:1,title:$credential,url:("https://example.test/pr/" + $credential),updatedAt:"2026-08-28T00:00:00Z",state:"OPEN",
              isDraft:false,mergeStateStatus:"CLEAN",reviewDecision:"APPROVED",headRefName:$credential,headRefOid:"1111111111111111111111111111111111111111",
              baseRefName:"main",baseRefOid:"2222222222222222222222222222222222222222",commits:{nodes:[{commit:{statusCheckRollup:{state:"SUCCESS"}}}]}
            }],pageInfo:{hasNextPage:false,endCursor:null}}}}}'
          else
            jq -nc --arg credential "$FAKE_CREDENTIAL" '{data:{repository:{issues:{nodes:[{
              id:"ISSUE-CREDENTIAL",number:1,title:$credential,url:("https://example.test/issue/" + $credential),updatedAt:"2026-08-28T00:00:00Z",state:"OPEN",stateReason:null
            }],pageInfo:{hasNextPage:false,endCursor:null}}}}}'
          fi
          exit 0
        fi
        if [[ "$*" == *pullRequests* ]] && [[ "$scenario" == github-object-40 || "$scenario" == github-object-64 || "$scenario" == github-base-oid-41 || "$scenario" == github-base-oid-63 ]]; then
          width=40
          [[ "$scenario" == github-object-64 ]] && width=64
          [[ "$scenario" == github-base-oid-41 ]] && width=41
          [[ "$scenario" == github-base-oid-63 ]] && width=63
          head_width=40
          [[ "$scenario" == github-object-64 ]] && head_width=64
          head_oid="$(printf "%${head_width}s" "" | tr ' ' 1)"
          base_oid="$(printf "%${width}s" "" | tr ' ' 2)"
          jq -nc --arg head "$head_oid" --arg base "$base_oid" '{data:{repository:{pullRequests:{nodes:[{
            id:"PR-1",number:1,title:"OID boundary",url:"https://example.test/pr/1",updatedAt:"2026-08-28T00:00:00Z",state:"OPEN",
            isDraft:false,mergeStateStatus:"CLEAN",reviewDecision:"APPROVED",headRefName:"feature",headRefOid:$head,
            baseRefName:"main",baseRefOid:$base,commits:{nodes:[{commit:{statusCheckRollup:{state:"SUCCESS"}}}]}
          }],pageInfo:{hasNextPage:false,endCursor:null}}}}}'
          exit 0
        fi
        if [[ "$*" == *pullRequests* ]] && [[ "$scenario" == pending-check || "$scenario" == outer-errors-pending || "$scenario" == nested-errors-pending || "$scenario" == legacy-failure || "$scenario" == action-required || "$scenario" == startup-failure || "$scenario" == unknown-conclusion || "$scenario" == mixed-nonterminal || "$scenario" == nested-many || "$scenario" == nested-count-mismatch || "$scenario" == nested-malformed-page-info || "$scenario" == nested-api-failed ]]; then
          jq -nc --arg scenario "$scenario" '
            def checkrun($name; $status; $conclusion):
              {__typename:"CheckRun",name:$name,status:$status,conclusion:$conclusion};
            def statuscontext($name; $state):
              {__typename:"StatusContext",context:$name,state:$state};
            (if $scenario == "pending-check" or $scenario == "outer-errors-pending" or $scenario == "nested-errors-pending" then [checkrun("ci";"COMPLETED";"SUCCESS"),checkrun("deploy";"IN_PROGRESS";null)]
             elif $scenario == "legacy-failure" then [checkrun("ci";"COMPLETED";"SUCCESS"),statuscontext("legacy";"FAILURE")]
             elif $scenario == "action-required" then [checkrun("ci";"COMPLETED";"ACTION_REQUIRED")]
             elif $scenario == "startup-failure" then [checkrun("ci";"COMPLETED";"STARTUP_FAILURE")]
             elif $scenario == "unknown-conclusion" then [checkrun("ci";"COMPLETED";"FUTURE_STATE")]
             elif $scenario == "mixed-nonterminal" then [checkrun("ci";"COMPLETED";"SUCCESS"),statuscontext("legacy";"PENDING")]
             elif $scenario == "nested-many" then [range(0;100)|checkrun(("ci-" + tostring);"COMPLETED";"SUCCESS")]
             else [checkrun("ci";"COMPLETED";"SUCCESS")] end) as $contexts |
            ({data:{repository:{pullRequests:{nodes:[{
              id:"PR-1",number:1,title:"complete checks",url:"https://example.test/pr/1",updatedAt:"2026-08-28T00:00:00Z",state:"OPEN",
              isDraft:false,mergeStateStatus:"CLEAN",reviewDecision:"APPROVED",headRefName:"feature",headRefOid:"1111111111111111111111111111111111111111",
              baseRefName:"main",baseRefOid:"2222222222222222222222222222222222222222",
              commits:{nodes:[{commit:{statusCheckRollup:{contexts:{nodes:$contexts}}}}]}
            }],pageInfo:{hasNextPage:false,endCursor:null}}}}} + (if $scenario == "outer-errors-pending" then {errors:[{message:"forbidden raw diagnostic"}]} else {} end))'
          exit 0
        fi
        if [[ "$*" == *pullRequests* ]] && [[ "$scenario" == duplicate-head || "$scenario" == duplicate-check || "$scenario" == duplicate-review || "$scenario" == duplicate-updated || "$scenario" == identical-duplicate-reversed ]]; then
          jq -nc --arg scenario "$scenario" '
            def pr($id;$number;$updated;$review;$head;$rollup):
              {id:$id,number:$number,title:("PR " + ($number|tostring)),url:("https://example.test/pr/" + ($number|tostring)),updatedAt:$updated,state:"OPEN",
               isDraft:false,mergeStateStatus:"CLEAN",reviewDecision:$review,headRefName:"feature",headRefOid:$head,
               baseRefName:"main",baseRefOid:"2222222222222222222222222222222222222222",
               commits:{nodes:[{commit:{statusCheckRollup:{state:$rollup}}}]}};
            pr("PR-1";1;"2026-08-28T00:00:00Z";"APPROVED";"1111111111111111111111111111111111111111";"SUCCESS") as $base |
            (if $scenario == "duplicate-head" then ($base | .headRefOid="3333333333333333333333333333333333333333")
             elif $scenario == "duplicate-check" then ($base | .commits.nodes[0].commit.statusCheckRollup.state="FAILURE")
             elif $scenario == "duplicate-review" then ($base | .reviewDecision="CHANGES_REQUESTED")
             elif $scenario == "duplicate-updated" then ($base | .updatedAt="2026-08-28T01:00:00Z")
             else $base end) as $copy |
            if $scenario == "identical-duplicate-reversed" then
              {data:{repository:{pullRequests:{nodes:[pr("PR-2";2;"2026-08-28T00:00:00Z";"APPROVED";"4444444444444444444444444444444444444444";"SUCCESS"),$base],pageInfo:{hasNextPage:true,endCursor:"cursor-1"}}}}},
              {data:{repository:{pullRequests:{nodes:[$base],pageInfo:{hasNextPage:false,endCursor:null}}}}}
            else
              {data:{repository:{pullRequests:{nodes:[$base],pageInfo:{hasNextPage:true,endCursor:"cursor-1"}}}}},
              {data:{repository:{pullRequests:{nodes:[$copy],pageInfo:{hasNextPage:false,endCursor:null}}}}}
            end'
          exit 0
        fi
        if [[ "$*" == *pullRequests* ]] && [[ "$scenario" == outer-premature-terminal || "$scenario" == outer-missing-cursor || "$scenario" == outer-repeated-cursor || "$scenario" == outer-post-terminal ]]; then
          case "$scenario" in
            outer-premature-terminal)
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}' ;;
            outer-missing-cursor)
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":null}}}}}'
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}' ;;
            outer-repeated-cursor)
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"cursor-1"}}}}}'
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"cursor-1"}}}}}'
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}' ;;
            outer-post-terminal)
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":"cursor-terminal"}}}}}'
              printf '%s\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}' ;;
          esac
          exit 0
        fi
        if [[ "$scenario" == external-receipt-drift && "$*" == *pullRequests* ]]; then
          count="$(bump github_pr)"
          if [[ "$count" -gt 1 ]]; then
            printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
            exit 0
          fi
        fi
        if [[ "$scenario" == issue-api-failed && "$*" != *pullRequests* ]]; then exit 19; fi
        if [[ "$scenario" == malformed-json ]]; then printf '{not json\\n'; exit 0; fi
        if [[ "$scenario" == null-nodes ]]; then printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[null],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'; exit 0; fi
        if [[ "$scenario" == malformed-page-info ]]; then printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":"false"}}}}}'; exit 0; fi
        if [[ "$scenario" == premature-pagination ]]; then printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"next"}}}}}'; exit 0; fi
        if [[ "$scenario" == issue-premature-pagination && "$*" != *pullRequests* ]]; then
          printf '%s\\n' '{"data":{"repository":{"issues":{"nodes":[],"pageInfo":{"hasNextPage":true,"endCursor":"next"}}}}}'
          exit 0
        fi
        if [[ "$scenario" == hostile || "$scenario" == hostile-valid-row ]]; then
          if [[ "$*" == *pullRequests* ]]; then
            printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[{"id":"PR-1","number":1,"title":"ToKeN\\rGHp_bad\\u001fGiThUb_PaT_bad\\u001b","url":"https://example.test/pr/1","updatedAt":"2026-08-28T00:00:00Z","state":"OPEN","isDraft":false,"mergeStateStatus":"CLEAN","reviewDecision":"APPROVED","headRefName":"feature","headRefOid":"1111111111111111111111111111111111111111","baseRefName":"main","baseRefOid":"2222222222222222222222222222222222222222","commits":{"nodes":[]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
          else
            printf '%s\\n' '{"data":{"repository":{"issues":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
          fi
          exit 0
        fi
        if [[ "$scenario" == malformed-pr-row && "$*" == *pullRequests* ]]; then
          printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[{"id":"PR-1","number":1,"title":"malformed PR","url":"https://example.test/pr/1","updatedAt":"2026-08-28T00:00:00Z","state":"OPEN","isDraft":false,"mergeStateStatus":"CLEAN","reviewDecision":"APPROVED","headRefName":"feature","baseRefName":"main","baseRefOid":"2222222222222222222222222222222222222222","commits":{"nodes":[{"commit":{"statusCheckRollup":{"contexts":{"nodes":[{"conclusion":"SUCCESS"}]}}}}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
          exit 0
        fi
        if [[ "$scenario" == malformed-issue-row && "$*" != *pullRequests* ]]; then
          printf '%s\\n' '{"data":{"repository":{"issues":{"nodes":[{"id":"ISSUE-1","number":1,"title":"malformed issue","url":"https://example.test/issue/1","updatedAt":"2026-08-28T00:00:00Z","stateReason":null}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
          exit 0
        fi
        if [[ "$*" == *pullRequests* ]]; then
          printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[{"id":"PR-2","number":2,"title":"same | title","url":"https://example.test/pr/2","updatedAt":"2026-08-28T00:00:00Z","state":"OPEN","isDraft":false,"mergeStateStatus":"CLEAN","reviewDecision":"APPROVED","headRefName":"feature","headRefOid":"1111111111111111111111111111111111111111","baseRefName":"main","baseRefOid":"2222222222222222222222222222222222222222","commits":{"nodes":[{"commit":{"statusCheckRollup":{"contexts":{"nodes":[{"conclusion":"SUCCESS"}]}}}}]}}],"pageInfo":{"hasNextPage":true,"endCursor":"cursor-1"}}}}}'
          printf '%s\\n' '{"data":{"repository":{"pullRequests":{"nodes":[{"id":"PR-1","number":1,"title":"token-secret-sentinel | body-secret-sentinel","url":"https://example.test/pr/1","updatedAt":"2026-08-28T00:00:00Z","state":"OPEN","isDraft":false,"mergeStateStatus":"CLEAN","reviewDecision":"APPROVED","headRefName":"feature","headRefOid":"1111111111111111111111111111111111111111","baseRefName":"main","baseRefOid":"2222222222222222222222222222222222222222","commits":{"nodes":[{"commit":{"statusCheckRollup":{"contexts":{"nodes":[{"conclusion":"SUCCESS"}]}}}}]}},{"id":"PR-2","number":2,"title":"same | title","url":"https://example.test/pr/2","updatedAt":"2026-08-28T00:00:00Z","state":"OPEN","isDraft":false,"mergeStateStatus":"CLEAN","reviewDecision":"APPROVED","headRefName":"feature","headRefOid":"1111111111111111111111111111111111111111","baseRefName":"main","baseRefOid":"2222222222222222222222222222222222222222","commits":{"nodes":[{"commit":{"statusCheckRollup":{"contexts":{"nodes":[{"conclusion":"SUCCESS"}]}}}}]}}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
        elif [[ "$scenario" == issue-duplicate-title || "$scenario" == issue-duplicate-state || "$scenario" == issue-duplicate-updated || "$scenario" == issue-exact-duplicate-reversed ]]; then
          jq -nc --arg scenario "$scenario" '
            def issue($id;$number;$title;$updated;$state):
              {id:$id,number:$number,title:$title,url:("https://example.test/issue/" + ($number|tostring)),updatedAt:$updated,state:$state,stateReason:null};
            issue("ISSUE-1";1;"Issue 1";"2026-08-28T00:00:00Z";"OPEN") as $base |
            issue("ISSUE-2";2;"Issue 2";"2026-08-28T00:00:00Z";"OPEN") as $sibling |
            (if $scenario == "issue-duplicate-title" then ($base | .title="Changed issue title")
             elif $scenario == "issue-duplicate-state" then ($base | .state="CLOSED")
             elif $scenario == "issue-duplicate-updated" then ($base | .updatedAt="2026-08-28T01:00:00Z")
             else $base end) as $copy |
            if $scenario == "issue-exact-duplicate-reversed" then
              {data:{repository:{issues:{nodes:[$sibling,$base],pageInfo:{hasNextPage:true,endCursor:"cursor-1"}}}}},
              {data:{repository:{issues:{nodes:[$base,$sibling],pageInfo:{hasNextPage:false,endCursor:null}}}}}
            else
              {data:{repository:{issues:{nodes:[$base,$sibling],pageInfo:{hasNextPage:true,endCursor:"cursor-1"}}}}},
              {data:{repository:{issues:{nodes:[$copy,$sibling],pageInfo:{hasNextPage:false,endCursor:null}}}}}
            end'
        elif [[ "$scenario" == "zero-issues" ]]; then
          printf '%s\\n' '{"data":{"repository":{"issues":{"nodes":[],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
        else
          printf '%s\\n' '{"data":{"repository":{"issues":{"nodes":[{"id":"ISSUE-1","number":1,"title":"same | title","url":"https://example.test/issue/1","updatedAt":"2026-08-28T00:00:00Z","state":"OPEN","stateReason":null}],"pageInfo":{"hasNextPage":false,"endCursor":null}}}}}'
        fi ;;
      *) exit 17 ;;
    esac
    """
  end

  defp package_paths(files) do
    files
    |> Enum.flat_map(fn relative_path ->
      path = Paths.path(relative_path)

      cond do
        File.dir?(path) -> Path.wildcard(Path.join(path, "**/*"), match_dot: true)
        File.exists?(path) -> [path]
        true -> []
      end
    end)
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(&Path.relative_to(&1, Paths.path(".")))
  end
end
