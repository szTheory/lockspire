defmodule Lockspire.Release.RepositoryHygieneContractTest do
  # These contract tests launch long-lived shell/Git fixtures and deliberately
  # exercise process cancellation. Keep them isolated from the rest of the
  # suite so shared OS resources cannot distort the exact topology receipts.
  use ExUnit.Case, async: false

  alias Lockspire.TestSupport.ReleaseProof.PackageAssertions
  alias Lockspire.TestSupport.QualityBaseline

  test "package inputs are explicit and exclude repository-local artifacts" do
    PackageAssertions.assert_hex_package_inputs!()
  end

  test "repository hygiene stays deterministic and outside the public product surface" do
    PackageAssertions.assert_repository_hygiene!()
  end

  @tag :phase139_gate_repair
  test "repository-owned workflow and shell lint accepts the inventory collector" do
    repo_root = Path.expand("../../..", __DIR__)

    {output, status} =
      System.cmd("bash", ["scripts/ci/lint_workflows.sh"],
        cd: repo_root,
        stderr_to_stdout: true
      )

    assert status == 0, output
  end

  @tag :phase139_gate_repair
  test "active release proof composes phase labels from semantic attributes" do
    assert QualityBaseline.active_phase_numbered_proof_locations() == []
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA repository hygiene joins synchronized local and workflow truth" do
    PackageAssertions.assert_phase_139_exact_sha_hygiene!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA hygiene matches only exact active-project Docker volume names" do
    PackageAssertions.assert_phase_139_docker_volume_name_matching!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  test "local hygiene warns when Docker state cannot be observed" do
    PackageAssertions.assert_phase_139_local_docker_list_failures!()
  end

  @tag :phase139_gap_closure
  @tag :phase139_exact_sha_hygiene
  @tag timeout: 180_000
  test "exact-SHA repository hygiene fails every ambiguous or stale path closed" do
    PackageAssertions.assert_phase_139_exact_sha_hygiene_fail_closed!()
  end

  test "baseline inventory collector renders a safe Git receipt" do
    PackageAssertions.assert_baseline_inventory_collector!()
  end

  test "baseline inventory collector renders deterministic Git domain rows" do
    PackageAssertions.assert_baseline_inventory_git_domains!()
  end

  test "baseline inventory collector fails closed for malformed or unavailable Git domains" do
    PackageAssertions.assert_baseline_inventory_git_domain_receipts!()
  end

  test "baseline inventory collector fails closed when stable IDs cannot be generated" do
    PackageAssertions.assert_baseline_inventory_stable_id_failures!()
  end

  test "baseline inventory collector renders safe GitHub pull-request evidence" do
    PackageAssertions.assert_baseline_inventory_github_pull_requests!()
  end

  test "baseline inventory collector distinguishes complete zero open issues" do
    PackageAssertions.assert_baseline_inventory_github_issues!()
  end

  test "baseline inventory collector keeps GitHub failure receipts distinct and sanitizes fields" do
    PackageAssertions.assert_baseline_inventory_github_failure_receipts!()
  end

  test "baseline inventory collector fails closed across GitHub namespaces" do
    PackageAssertions.assert_baseline_inventory_github_aggregate_fail_closed!()
  end

  test "baseline inventory collector requires complete GitHub check evidence" do
    PackageAssertions.assert_baseline_inventory_github_check_completeness!()
  end

  test "baseline inventory collector rejects contradictory duplicates and impossible page chains" do
    PackageAssertions.assert_baseline_inventory_github_duplicate_consistency!()
  end

  @tag :phase138_github_gap
  test "baseline inventory collector closes GitHub integrity gaps" do
    PackageAssertions.assert_baseline_inventory_github_integrity_gaps!()
  end

  @tag :phase138_current_gap
  @tag timeout: 180_000
  test "baseline inventory collector closes current evidence-integrity gaps" do
    PackageAssertions.assert_baseline_inventory_current_verification_gaps!()
  end

  @tag :phase138_review_gap
  @tag timeout: 180_000
  test "baseline inventory collector closes reviewed fail-open evidence gaps" do
    PackageAssertions.assert_baseline_inventory_review_verification_gaps!()
  end

  @tag :phase138_redaction_gap
  @tag timeout: 180_000
  test "baseline inventory collector redacts credentials at every display boundary" do
    PackageAssertions.assert_baseline_inventory_credential_redaction!()
  end

  test "baseline inventory collector accounts for maintained follow-up sources" do
    PackageAssertions.assert_baseline_inventory_maintained_records!()
  end

  @tag timeout: 180_000
  test "baseline inventory collector fails closed for maintained selectors and hostile paths" do
    PackageAssertions.assert_baseline_inventory_maintained_fail_closed!()
  end

  @tag :phase140_handoff_classification
  @tag timeout: 180_000
  test "Phase 140 handoff classification requires committed structure and emits one stable proposal" do
    repo_root = Path.expand("../../..", __DIR__)

    fixture =
      Path.join(
        System.tmp_dir!(),
        "lockspire-phase140-handoff-#{System.unique_integer([:positive])}"
      )

    repository = Path.join(fixture, "repository")
    origin = Path.join(fixture, "origin.git")

    handoff_dir =
      Path.join(repository, ".planning/phases/140-bounded-operational-loose-end-triage")

    valid_handoff = """
    ---
    phase: 140-bounded-operational-loose-end-triage
    status: in_progress
    ---
    # Phase 140 execution handoff

    **Updated:** 2026-09-30
    **Next command:** `$gsd-execute-phase 140 --gaps-only`
    **Position:** Plan 140-05 complete; Plans 140-06 through 140-09 remain.

    ## Current position

    Continue only the remaining bounded gap-closure plans.

    ## Next step

    Preserve exact-target and proposal-only boundaries.

    ## Do not

    Do not push or mutate remote state.
    """

    lookalikes = %{
      "140-missing-status-HANDOFF.md" =>
        String.replace(valid_handoff, "status: in_progress\n", ""),
      "140-wrong-shape-HANDOFF.md" =>
        String.replace(valid_handoff, "## Current position", "## Notes"),
      "140-wrong-status-HANDOFF.md" =>
        String.replace(valid_handoff, "status: in_progress", "status: complete")
    }

    git = fn args, cwd ->
      System.cmd("git", args,
        cd: cwd,
        env: [
          {"GIT_AUTHOR_NAME", "Lockspire Test"},
          {"GIT_AUTHOR_EMAIL", "lockspire-test@example.invalid"},
          {"GIT_COMMITTER_NAME", "Lockspire Test"},
          {"GIT_COMMITTER_EMAIL", "lockspire-test@example.invalid"}
        ],
        stderr_to_stdout: true
      )
    end

    try do
      File.mkdir_p!(handoff_dir)
      File.write!(Path.join(handoff_dir, "140-HANDOFF.md"), valid_handoff)

      Enum.each(lookalikes, fn {name, contents} ->
        File.write!(Path.join(handoff_dir, name), contents)
      end)

      {_, 0} = git.("init --initial-branch=main" |> String.split(), repository)
      {_, 0} = git.("init --bare origin.git" |> String.split(), fixture)
      {_, 0} = git.("add .planning" |> String.split(), repository)
      {_, 0} = git.("commit -m fixture" |> String.split(), repository)
      {_, 0} = git.("remote add origin #{origin}" |> String.split(), repository)
      {_, 0} = git.("push -u origin main" |> String.split(), repository)

      output_path = Path.join(fixture, "inventory.md")
      collector = Path.join(repo_root, "scripts/maintainer/baseline_inventory.sh")

      {first_output, first_status} =
        System.cmd("bash", [collector, "--scope", "maintained", "--output", output_path],
          cd: repository,
          stderr_to_stdout: true
        )

      assert first_status == 0, first_output
      first_inventory = File.read!(output_path)
      assert first_inventory =~ "Maintained follow-up families | partial"
      assert first_inventory =~ "active-records | unclassified/ambiguous"

      valid_path =
        ".planning/phases/140-bounded-operational-loose-end-triage/140-HANDOFF.md"

      canonical_valid_path = String.downcase(valid_path)

      id_rows =
        Regex.scan(
          ~r/^\| (REC-[0-9a-f]{12}) \| maintained_record \| `#{Regex.escape(canonical_valid_path)}` \|/m,
          first_inventory,
          capture: :all_but_first
        )

      assert length(id_rows) == 1, first_inventory
      [first_id] = id_rows

      {second_output, second_status} =
        System.cmd(
          "bash",
          [collector, "--scope", "maintained", "--output", output_path, "--replace"],
          cd: repository,
          stderr_to_stdout: true
        )

      assert second_status == 0, second_output
      second_inventory = File.read!(output_path)

      assert second_inventory =~
               "| #{hd(first_id)} | maintained_record | `#{canonical_valid_path}` | observed allowlisted source | active | defer-with-trigger |"

      second_id_rows =
        Regex.scan(
          ~r/^\| (REC-[0-9a-f]{12}) \| maintained_record \| `#{Regex.escape(canonical_valid_path)}` \|/m,
          second_inventory,
          capture: :all_but_first
        )

      assert second_id_rows == id_rows

      assert String.contains?(
               second_inventory,
               "| active-records | unclassified/ambiguous | `#{valid_path |> String.replace("140-HANDOFF", "140-missing-status-HANDOFF")}` |"
             )

      assert String.contains?(
               second_inventory,
               "| active-records | unclassified/ambiguous | `#{valid_path |> String.replace("140-HANDOFF", "140-wrong-shape-HANDOFF")}` |"
             )

      assert String.contains?(
               second_inventory,
               "| active-records | unclassified/ambiguous | `#{valid_path |> String.replace("140-HANDOFF", "140-wrong-status-HANDOFF")}` |"
             )
    after
      File.rm_rf(fixture)
    end
  end

  test "baseline inventory collector preserves maintained semantics and valid canonical encoding" do
    PackageAssertions.assert_baseline_inventory_maintained_encoding!()
  end

  @tag :phase138_maintained_gap
  @tag timeout: 180_000
  test "baseline inventory collector closes maintained evidence integrity gaps" do
    PackageAssertions.assert_baseline_inventory_maintained_integrity_gaps!()
  end

  @tag :phase138_maintained_uat
  @tag timeout: 180_000
  test "baseline inventory collector classifies active UAT lifecycle records structurally" do
    PackageAssertions.assert_baseline_inventory_active_uat!()
  end

  test "baseline inventory collector preserves the target under contention and interruption" do
    PackageAssertions.assert_baseline_inventory_output_lifecycle!()
  end

  test "baseline inventory collector publishes under one lock-stable working-tree snapshot" do
    PackageAssertions.assert_baseline_inventory_publication_transaction!()
  end

  @tag :phase138_publication_gap
  test "baseline inventory collector closes publication integrity gaps" do
    PackageAssertions.assert_baseline_inventory_publication_integrity_gaps!()
  end

  @tag :phase138_path_gap
  @tag timeout: 180_000
  test "baseline inventory collector preserves hostile worktree path boundaries" do
    PackageAssertions.assert_baseline_inventory_worktree_path_boundaries!()
    PackageAssertions.assert_baseline_inventory_caller_paths_and_preflight!()
  end

  test "snapshot fixture preserves committed modes for protected planning files" do
    PackageAssertions.assert_snapshot_planning_file_modes!()
  end

  test "baseline inventory collector proves live interruption and pagination contention" do
    PackageAssertions.assert_baseline_inventory_live_writer_contention!()
  end

  test "baseline inventory collector publishes only a source-stable snapshot" do
    PackageAssertions.assert_baseline_inventory_snapshot_currentness!()
  end

  test "baseline snapshot relation fails closed on semantically relevant post-snapshot drift" do
    PackageAssertions.assert_baseline_inventory_post_snapshot_drift!()
  end

  @tag timeout: 600_000
  test "baseline snapshot relation fails closed on topology and destructive bookkeeping drift" do
    PackageAssertions.assert_baseline_inventory_snapshot_relation_fail_closed!()
    PackageAssertions.assert_baseline_inventory_lifecycle_transitions_fail_closed!()
  end

  test "baseline snapshot relation resolves only the current immutable ledger publication" do
    PackageAssertions.assert_baseline_inventory_snapshot_commit_resolution!()
  end

  @tag :phase138_relation_gap
  @tag timeout: 300_000
  test "baseline snapshot relation closes relation integrity gaps" do
    PackageAssertions.assert_baseline_inventory_relation_integrity_gaps!()
  end

  @tag :phase138_preverify_relation_gap
  @tag timeout: 300_000
  test "baseline snapshot relation proves pre-verifier publication currentness" do
    PackageAssertions.assert_phase_138_preverify_relation!()
  end

  @tag :phase138_posttransition_relation_gap
  @tag timeout: 300_000
  test "baseline snapshot relation binds post-transition authority to the host receipt" do
    PackageAssertions.assert_phase_138_posttransition_relation!()
  end

  @tag :phase139_inventory_relation
  @tag timeout: 600_000
  test "relation accepts canonical completion and rejects hostile bookkeeping without moving refs" do
    PackageAssertions.assert_phase_139_inventory_relation!()
  end

  @tag :phase139_inventory_relation
  @tag timeout: 300_000
  test "phase 139 release-please main advance accepts only the authenticated refresh and recorded lag" do
    PackageAssertions.assert_phase_139_release_please_main_advance!()
  end

  @tag :phase139_inventory_relation
  @tag :phase139_merged_lineage
  @tag timeout: 300_000
  test "phase 139 accepts the sealed candidate while local main lags and the merged release branch is deleted" do
    PackageAssertions.assert_phase_139_merged_release_lineage!()
  end

  @tag :phase139_preverify_refresh
  @tag timeout: 600_000
  test "current pre-verifier refresh publishes one immutable ledger" do
    PackageAssertions.assert_phase_139_preverify_refresh!()
  end

  @tag :phase140_recovery_relation
  @tag timeout: 180_000
  test "Phase 140 recovery validates dependency and inventory fixture timeout follow-ups" do
    PackageAssertions.assert_phase_139_recovery_candidate_relation!()
  end

  @tag :phase140_recovery_relation
  @tag :phase140_entrypoint_recovery
  @tag timeout: 600_000
  test "Phase 140 recovery authenticates the exact planning preparation prefix" do
    PackageAssertions.assert_phase_140_planning_preparation_recovery_chain!()
  end

  @tag :phase139_final_acceptance
  @tag timeout: 600_000
  test "sealed candidate advances main through one exact fast-forward from a clean candidate worktree" do
    PackageAssertions.assert_phase_139_final_acceptance!()
  end

  @tag :phase139_acceptance_receipt
  @tag timeout: 600_000
  test "sealed candidate records exact live acceptance outside the worktree" do
    PackageAssertions.assert_phase_139_acceptance_receipt!()
  end

  @tag :phase138_finalizer_gap
  @tag timeout: 600_000
  test "phase finalizer publishes once before verification and validates only after transition" do
    PackageAssertions.assert_phase_138_finalizer_contract!()
  end

  @tag :phase138_finalizer_recovery_gap
  @tag timeout: 300_000
  test "phase finalizer failures preserve host-owned pending recovery state" do
    PackageAssertions.assert_phase_138_finalizer_recovery_contract!()
  end

  @tag :phase138_relation_gap
  @tag :phase138_closeout_gap
  @tag timeout: 300_000
  test "baseline snapshot relation authorizes only exact GSD plan closeout metadata" do
    PackageAssertions.assert_baseline_inventory_gsd_plan_closeout_transitions!()
  end

  @tag :phase138_source_authority_gap
  @tag timeout: 180_000
  test "baseline snapshot relation accepts external receipts only from live sources" do
    PackageAssertions.assert_baseline_inventory_external_source_authority!()
  end

  test "complete baseline inventory renders executable currentness instructions" do
    PackageAssertions.assert_baseline_inventory_currentness_instructions!()
  end

  @tag :phase138_prohibition
  test "138-06-1 rejects partial publication after interruption" do
    PackageAssertions.assert_baseline_inventory_output_lifecycle!()
  end

  @tag :phase138_prohibition
  test "138-08-1 rejects unidentified Git records without successful-zero evidence" do
    PackageAssertions.assert_baseline_inventory_stable_id_failures!()
  end

  @tag :phase138_prohibition
  test "138-12-1 rejects affirmative GitHub disposition from partial namespaces" do
    PackageAssertions.assert_baseline_inventory_github_aggregate_fail_closed!()
  end

  @tag :phase138_prohibition
  @tag timeout: 180_000
  test "138-02-1 rejects credential-like material at display boundaries" do
    PackageAssertions.assert_baseline_inventory_credential_redaction!()
  end

  @tag :phase138_prohibition
  @tag timeout: 180_000
  test "138-09-2 rejects hostile maintained paths from escaping the collector" do
    PackageAssertions.assert_baseline_inventory_maintained_fail_closed!()
  end

  @tag :phase138_prohibition
  test "138-15-2 rejects semantically unrelated post-snapshot bookkeeping" do
    PackageAssertions.assert_baseline_inventory_post_snapshot_drift!()
  end

  @tag :phase138_prohibition
  test "138-18-1 rejects failed Git receipts as complete evidence" do
    PackageAssertions.assert_baseline_inventory_git_domain_receipts!()
  end

  @tag :phase138_prohibition
  test "138-13-1 rejects output replacement outside the target-lock transaction" do
    PackageAssertions.assert_baseline_inventory_publication_transaction!()
  end
end
