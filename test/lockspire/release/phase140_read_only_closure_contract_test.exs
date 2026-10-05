defmodule Lockspire.Release.Phase140ReadOnlyClosureContractTest do
  use ExUnit.Case, async: false

  @script "scripts/maintainer/verify_phase140_read_only_closure.py"
  @reviewer "phase140-reviewer@example.invalid"
  @namespace "lockspire-phase140-review"
  @ci_jobs [
    "Dialyzer",
    "Release Hygiene Drift",
    "Fast Checks",
    "Minimum Supported Elixir/OTP",
    "Integration Checks",
    "Complete Coverage Evidence",
    "Adoption Demo Smoke"
  ]
  @release_jobs [
    {"Maintain Release Please PR", "success"},
    {"Validate exact main head and CI evidence", "skipped"},
    {"Prove exact package before publication", "skipped"},
    {"Publish verified release to Hex", "skipped"},
    {"Verify public install truth", "skipped"}
  ]
  @protected_files [
    ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md",
    ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md",
    ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md",
    "docs/lockspire-milestone-roadmap-ratchet-prompt.txt"
  ]

  @tag :phase140_closure_tracer
  test "the committed closure command exposes independent signed-review inputs" do
    repo_root = Path.expand("../../..", __DIR__)
    script = Path.join(repo_root, @script)

    {output, status} = System.cmd("python3", [script, "--help"], cd: repo_root)

    assert status == 0
    assert output =~ "--verify-review-only"
    assert output =~ "--review-statement"
    assert output =~ "--review-signature"
    assert output =~ "--allowed-signers"
    assert output =~ "--reviewer-principal"
    assert output =~ "--trusted-fingerprint"
  end

  @tag :phase140_closure_tracer
  @tag timeout: 180_000
  test "an SSH-signed review authorizes the private read-only closure result" do
    repo_root = Path.expand("../../..", __DIR__)
    fixture = build_fixture!(repo_root)
    on_exit(fn -> cleanup_fixture(fixture) end)

    valid_signature = File.read!(fixture.signature)
    File.write!(fixture.signature, "not an OpenSSH signature\n")
    File.chmod!(fixture.signature, 0o600)

    {invalid_output, invalid_status} = run_verifier(fixture)
    assert invalid_status != 0
    assert invalid_output =~ "external review signature is invalid"
    refute File.exists?(fixture.output)

    File.write!(fixture.signature, valid_signature)
    File.chmod!(fixture.signature, 0o600)
    before = repository_state(fixture.repository)
    protected_before = Enum.map(@protected_files, &File.read!(Path.join(fixture.repository, &1)))

    {output, status} = run_verifier(fixture)

    assert status == 0, output
    assert File.stat!(fixture.output).mode |> Bitwise.band(0o777) == 0o600
    result = fixture.output |> File.read!() |> Jason.decode!()
    assert result["sha"] == fixture.sha
    assert result["requirements"] == %{"CI-06" => "pass", "CI-07" => "pass"}
    assert result["method"]["external_review"]["reviewer_principal"] == @reviewer
    assert result["method"]["external_review"]["trusted_fingerprint"] == fixture.fingerprint
    assert result["method"]["external_review"]["statement_sha256"] == fixture.statement_sha256
    assert repository_state(fixture.repository) == before

    assert Enum.map(@protected_files, &File.read!(Path.join(fixture.repository, &1))) ==
             protected_before

    original_result = File.read!(fixture.output)
    {repeat_output, repeat_status} = run_verifier(fixture)

    assert repeat_status != 0
    assert repeat_output =~ "output already exists; refusing to overwrite private evidence"
    assert File.read!(fixture.output) == original_result
  end

  @tag :phase140_closure_tracer
  @tag timeout: 240_000
  test "review-only preflight validates the signature without a receipt or output" do
    repo_root = Path.expand("../../..", __DIR__)
    fixture = build_fixture!(repo_root)
    on_exit(fn -> cleanup_fixture(fixture) end)
    File.rm!(fixture.receipt)

    before = repository_state(fixture.repository)
    {output, status} = run_review_preflight(fixture)

    assert status == 0, output
    assert Jason.decode!(output)["review_preflight"] == "PASS"
    refute File.exists?(fixture.output)
    refute File.exists?(fixture.receipt)
    assert repository_state(fixture.repository) == before
  end

  @tag :phase140_closure_tracer
  @tag timeout: 360_000
  test "rejects forged trust, lifecycle, receipt, workflow, and in-flight state" do
    repo_root = Path.expand("../../..", __DIR__)
    summary_path = ".planning/phases/140-bounded-operational-loose-end-triage/140-18-SUMMARY.md"
    requirements_path = ".planning/REQUIREMENTS.md"

    cases = [
      {"wrong reviewer principal", fn fixture -> fixture end,
       [reviewer: "other-reviewer@example.invalid"], "review statement principal differs"},
      {"wrong trusted fingerprint", fn fixture -> fixture end,
       [fingerprint: "SHA256:" <> String.duplicate("A", 43)], "key fingerprint differs"},
      {"wrong signer key", &replace_signer_with_untrusted_key!/1, [],
       "external review signature is invalid"},
      {"reviewed commit has an altered executable blob", &review_altered_blob!/1, [],
       "running executable bytes differ from the committed executable"},
      {"missing committed plan summary",
       fn fixture -> advance_candidate!(fixture, summary_path, :delete) end, [],
       "conditional record is not a regular committed file"},
      {"CI-06 was marked complete",
       fn fixture ->
         content = File.read!(Path.join(fixture.repository, requirements_path))
         updated = String.replace(content, "- [ ] **CI-06**", "- [x] **CI-06**", global: false)
         if updated == content, do: flunk("CI-06 fixture requirement row was not found")
         advance_candidate!(fixture, requirements_path, updated)
       end, [], "CI-06 is not pending"},
      {"HEAD changed after candidate capture", &advance_unbound_candidate!/1, [],
       "HEAD and local main must already equal"},
      {"local main changed after candidate capture", &diverge_local_main!/1, [],
       "HEAD and local main must already equal"},
      {"origin main changed during workflow checks", fn fixture -> fixture end,
       [git_scenario: "remote_changed"], "refs or worktree changed"},
      {"a required CI job is missing", fn fixture -> fixture end, [gh_scenario: "missing_ci_job"],
       "CI live job list is incomplete"},
      {"a required CI job is duplicated", fn fixture -> fixture end,
       [gh_scenario: "duplicate_ci_job"], "CI live job list is incomplete"},
      {"a Release publication job succeeded", fn fixture -> fixture end,
       [gh_scenario: "publication_job_succeeded"], "Release live job graph differs"},
      {"a WARN lacks its exact disposition", &remove_warn_disposition!/1, [],
       "WARN disposition count does not match"},
      {"the receipt has unsafe permissions", &make_receipt_public!/1, [],
       "regular owner-only mode-0600 file"},
      {"a tracked file changed during live checks", fn fixture -> fixture end,
       [gh_scenario: "tracked_write"], "refs or worktree changed"},
      {"origin moved after result publication", &advance_empty_candidate!/1,
       [git_scenario: "final_remote_move"], "checkout changed while writing"}
    ]

    Enum.each(cases, fn {label, mutate, options, expected} ->
      fixture = build_fixture!(repo_root)
      fixture = mutate.(fixture)

      try do
        {output, status} = run_verifier(fixture, options)

        assert status != 0, "#{label} unexpectedly passed"
        assert output =~ expected, "#{label} returned an unexpected diagnostic: #{output}"
        refute File.exists?(fixture.output), "#{label} left a private pass result"
      after
        cleanup_fixture(fixture)
      end
    end)
  end

  defp build_fixture!(repo_root) do
    nonce = System.unique_integer([:positive])
    directory = Path.join(System.tmp_dir!(), "lockspire-phase140-closure-#{nonce}")
    repository = Path.join(directory, "repository")
    origin = Path.join(directory, "origin.git")
    private_dir = "/private/tmp/lockspire-140-plan"
    File.mkdir_p!(repository)
    File.mkdir_p!(private_dir)
    File.chmod!(private_dir, 0o700)

    git!(directory, ["init", "--bare", "--initial-branch=main", "--quiet", origin])
    git!(directory, ["init", "--initial-branch=main", "--quiet", repository])
    git!(repository, ["config", "user.name", "Lockspire fixture"])
    git!(repository, ["config", "user.email", "fixture@example.invalid"])

    files = [
      @script,
      ".planning/REQUIREMENTS.md",
      ".planning/ROADMAP.md",
      ".planning/STATE.md",
      ".planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md",
      ".planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md"
      | @protected_files
    ]

    Enum.each(files, fn relative ->
      target = Path.join(repository, relative)
      File.mkdir_p!(Path.dirname(target))
      File.cp!(Path.join(repo_root, relative), target)
    end)

    historical_protected_blobs = %{
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md" =>
        "98cb653bae3e3fd57c1d6b598f42b84c155e983c",
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md" =>
        "e286437b73b7b39f087e90175723525aaa223e05"
    }

    Enum.each(historical_protected_blobs, fn {relative, commit} ->
      target = Path.join(repository, relative)
      File.write!(target, git!(repo_root, ["show", "#{commit}:#{relative}"]))
    end)

    File.chmod!(Path.join(repository, @script), 0o755)

    summary = """
    ---
    phase: 140-bounded-operational-loose-end-triage
    plan: "18"
    requirements-completed: []
    status: complete
    ---
    # Phase 140 Plan 18 fixture summary

    CI-06 and CI-07 remain pending until the private terminal result exists.
    Fixture nonce: #{nonce}
    """

    summary_path =
      Path.join(
        repository,
        ".planning/phases/140-bounded-operational-loose-end-triage/140-18-SUMMARY.md"
      )

    File.write!(summary_path, summary)
    git!(repository, ["add", "--", "."])
    git!(repository, ["commit", "--quiet", "-m", "fixture state"])
    git!(repository, ["remote", "add", "origin", origin])
    git!(repository, ["push", "--quiet", "--set-upstream", "origin", "main"])
    sha = git!(repository, ["rev-parse", "HEAD"]) |> String.trim()
    tree = git!(repository, ["rev-parse", "HEAD^{tree}"]) |> String.trim()

    alternate_sha =
      git!(repository, [
        "-c",
        "user.name=Lockspire fixture",
        "-c",
        "user.email=fixture@example.invalid",
        "commit-tree",
        tree,
        "-p",
        sha,
        "-m",
        "concurrent remote main"
      ])
      |> String.trim()

    git!(repository, ["push", "--quiet", "origin", "#{alternate_sha}:refs/heads/adversarial"])

    key_base = Path.join(private_dir, "140-18-fixture-#{sha}")
    key_path = key_base
    public_path = key_base <> ".pub"
    statement = key_base <> ".statement.json"
    signature = statement <> ".sig"
    allowed_signers = key_base <> ".allowed-signers"
    receipt = Path.join(private_dir, "140-18-final-acceptance.#{sha}.json")
    output = Path.join(private_dir, "140-18-read-only-closure.#{sha}.json")

    ssh_keygen!(directory, ["-q", "-t", "ed25519", "-N", "", "-C", @reviewer, "-f", key_path])

    [key_type, encoded_key | _comment] =
      public_path |> File.read!() |> String.trim() |> String.split()

    File.write!(
      allowed_signers,
      "#{@reviewer} namespaces=\"#{@namespace}\" #{key_type} #{encoded_key}\n"
    )

    File.chmod!(allowed_signers, 0o600)

    executable_digest =
      Path.join(repository, @script)
      |> File.read!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    review_statement = %{
      "schema" => "lockspire-phase-140-external-review-v1",
      "reviewed_commit" => sha,
      "executable_sha256" => executable_digest,
      "reviewer_principal" => @reviewer,
      "verdict" => "PASS",
      "review_scope" => [
        "read-only tracked/ref behavior",
        "receipt validation",
        "workflow identity",
        "no-publish classification"
      ]
    }

    statement_bytes = Jason.encode!(review_statement) <> "\n"
    File.write!(statement, statement_bytes)
    File.chmod!(statement, 0o600)
    ssh_keygen!(directory, ["-Y", "sign", "-f", key_path, "-n", @namespace, statement])
    File.chmod!(signature, 0o600)

    fingerprint =
      ssh_keygen!(directory, ["-lf", public_path, "-E", "sha256"])
      |> String.split()
      |> Enum.at(1)

    File.write!(receipt, Jason.encode!(receipt(sha)) <> "\n")
    File.chmod!(receipt, 0o600)

    fake_bin = Path.join(directory, "bin")
    File.mkdir_p!(fake_bin)
    fake_gh = Path.join(fake_bin, "gh")
    File.write!(fake_gh, fake_gh_script())
    File.chmod!(fake_gh, 0o755)
    fake_git = Path.join(fake_bin, "git")
    File.write!(fake_git, fake_git_script())
    File.chmod!(fake_git, 0o755)

    %{
      directory: directory,
      repository: repository,
      origin: origin,
      initial_sha: sha,
      alternate_sha: alternate_sha,
      sha: sha,
      signature: signature,
      statement: statement,
      statement_sha256: :crypto.hash(:sha256, statement_bytes) |> Base.encode16(case: :lower),
      allowed_signers: allowed_signers,
      reviewer: @reviewer,
      fingerprint: fingerprint,
      key_path: key_path,
      public_path: public_path,
      receipt: receipt,
      output: output,
      fake_bin: fake_bin,
      git_count_file: Path.join(directory, "ls-remote-count"),
      real_git: System.find_executable("git")
    }
  end

  defp receipt(sha) do
    %{
      "schema" => "lockspire-phase-139-acceptance-v1",
      "baseline_sha" => sha,
      "local_gate" => %{"status" => "pass", "exunit_tests" => 1},
      "hygiene" => %{"status" => "pass", "pass" => 24, "warn" => 0, "block" => 0},
      "required_ci" => workflow_run(110, @ci_jobs),
      "release_no_publish" => workflow_run(120, @release_jobs, "no_publish"),
      "warn_dispositions" => [],
      "supplemental_oidf" => %{
        "classification" => "supplemental_non_certifying",
        "required_gate" => false
      }
    }
  end

  defp advance_candidate!(fixture, relative_path, content) do
    target = Path.join(fixture.repository, relative_path)

    case content do
      :delete ->
        git!(fixture.repository, ["rm", "--quiet", "--", relative_path])

      updated when is_binary(updated) ->
        File.write!(target, updated)
        git!(fixture.repository, ["add", "--", relative_path])
    end

    git!(fixture.repository, ["commit", "--quiet", "-m", "adversarial candidate state"])
    git!(fixture.repository, ["push", "--quiet", "origin", "main"])
    refresh_fixture_candidate!(fixture)
  end

  defp advance_empty_candidate!(fixture) do
    git!(fixture.repository, ["commit", "--quiet", "--allow-empty", "-m", "candidate moved"])
    git!(fixture.repository, ["push", "--quiet", "origin", "main"])
    refresh_fixture_candidate!(fixture)
  end

  defp advance_unbound_candidate!(fixture) do
    git!(fixture.repository, [
      "commit",
      "--quiet",
      "--allow-empty",
      "-m",
      "candidate moved after capture"
    ])

    git!(fixture.repository, ["push", "--quiet", "origin", "main"])
    fixture
  end

  defp refresh_fixture_candidate!(fixture) do
    new_sha = git!(fixture.repository, ["rev-parse", "HEAD"]) |> String.trim()
    old_receipt = fixture.receipt
    receipt_path = Path.join(Path.dirname(old_receipt), "140-18-final-acceptance.#{new_sha}.json")

    output_path =
      Path.join(Path.dirname(fixture.output), "140-18-read-only-closure.#{new_sha}.json")

    receipt_data =
      old_receipt |> File.read!() |> Jason.decode!() |> Map.put("baseline_sha", new_sha)

    File.rm!(old_receipt)
    File.write!(receipt_path, Jason.encode!(receipt_data) <> "\n")
    File.chmod!(receipt_path, 0o600)

    %{fixture | sha: new_sha, receipt: receipt_path, output: output_path}
  end

  defp diverge_local_main!(fixture) do
    git!(fixture.repository, ["checkout", "--quiet", "--detach", fixture.sha])
    git!(fixture.repository, ["commit", "--quiet", "--allow-empty", "-m", "divergent local main"])
    moved_local_main = git!(fixture.repository, ["rev-parse", "HEAD"]) |> String.trim()
    git!(fixture.repository, ["checkout", "--quiet", "--detach", fixture.sha])
    git!(fixture.repository, ["update-ref", "refs/heads/main", moved_local_main])
    fixture
  end

  defp replace_signer_with_untrusted_key!(fixture) do
    other_key = Path.join(fixture.directory, "other-reviewer-key")
    other_public = other_key <> ".pub"
    ssh_keygen!(fixture.directory, ["-q", "-t", "ed25519", "-N", "", "-f", other_key])
    [key_type, encoded_key | _] = other_public |> File.read!() |> String.trim() |> String.split()

    File.write!(
      fixture.allowed_signers,
      "#{@reviewer} namespaces=\"#{@namespace}\" #{key_type} #{encoded_key}\n"
    )

    File.chmod!(fixture.allowed_signers, 0o600)

    fingerprint =
      ssh_keygen!(fixture.directory, ["-lf", other_public, "-E", "sha256"])
      |> String.split()
      |> Enum.at(1)

    %{fixture | fingerprint: fingerprint}
  end

  defp review_altered_blob!(fixture) do
    script_path = Path.join(fixture.repository, @script)
    original_script = File.read!(script_path)
    File.write!(script_path, original_script <> "\n# altered historical verifier blob\n")
    git!(fixture.repository, ["add", "--", @script])
    git!(fixture.repository, ["commit", "--quiet", "-m", "alter reviewed verifier blob"])
    altered_commit = git!(fixture.repository, ["rev-parse", "HEAD"]) |> String.trim()

    File.write!(script_path, original_script)
    git!(fixture.repository, ["add", "--", @script])
    git!(fixture.repository, ["commit", "--quiet", "-m", "restore reviewed verifier bytes"])
    git!(fixture.repository, ["push", "--quiet", "origin", "main"])
    fixture = refresh_fixture_candidate!(fixture)
    candidate_script = git!(fixture.repository, ["show", "#{fixture.sha}:#{@script}"])

    if candidate_script != original_script,
      do: flunk("restored candidate did not retain the original verifier bytes")

    if File.read!(script_path) != candidate_script,
      do: flunk("fixture checkout differs from its restored verifier blob")

    executable_digest = :crypto.hash(:sha256, original_script) |> Base.encode16(case: :lower)

    statement = %{
      "schema" => "lockspire-phase-140-external-review-v1",
      "reviewed_commit" => altered_commit,
      "executable_sha256" => executable_digest,
      "reviewer_principal" => @reviewer,
      "verdict" => "PASS",
      "review_scope" => [
        "read-only tracked/ref behavior",
        "receipt validation",
        "workflow identity",
        "no-publish classification"
      ]
    }

    statement_bytes = Jason.encode!(statement) <> "\n"
    File.write!(fixture.statement, statement_bytes)
    File.chmod!(fixture.statement, 0o600)
    File.rm!(fixture.signature)

    ssh_keygen!(fixture.directory, [
      "-Y",
      "sign",
      "-f",
      fixture.key_path,
      "-n",
      @namespace,
      fixture.statement
    ])

    File.chmod!(fixture.signature, 0o600)

    %{
      fixture
      | statement_sha256: :crypto.hash(:sha256, statement_bytes) |> Base.encode16(case: :lower)
    }
  end

  defp remove_warn_disposition!(fixture) do
    receipt_data = fixture.receipt |> File.read!() |> Jason.decode!()
    updated = receipt_data |> put_in(["hygiene", "warn"], 1) |> Map.put("warn_dispositions", [])
    File.write!(fixture.receipt, Jason.encode!(updated) <> "\n")
    File.chmod!(fixture.receipt, 0o600)
    fixture
  end

  defp make_receipt_public!(fixture) do
    File.chmod!(fixture.receipt, 0o644)
    fixture
  end

  defp workflow_run(id, jobs, outcome \\ nil) do
    base = %{
      "status" => "pass",
      "run_id" => id,
      "event" => "push",
      "conclusion" => "success",
      "url" => "https://github.com/owner/repo/actions/runs/#{id}",
      "jobs" =>
        Enum.map(jobs, fn
          {name, conclusion} ->
            %{"name" => name, "status" => "completed", "conclusion" => conclusion}

          name ->
            %{"name" => name, "status" => "completed", "conclusion" => "success"}
        end)
    }

    if outcome, do: Map.put(base, "outcome", outcome), else: base
  end

  defp fake_gh_script do
    """
    #!/usr/bin/env python3
    import json
    import os
    import sys

    args = " ".join(sys.argv[1:])
    sha = os.environ["LOCKSPIRE_FAKE_SHA"]
    scenario = os.environ.get("LOCKSPIRE_FAKE_GH_SCENARIO", "")
    ci_jobs = [#{@ci_jobs |> Enum.map(&inspect/1) |> Enum.join(", ")}]
    release_jobs = [#{@release_jobs |> Enum.map(fn {name, _} -> inspect(name) end) |> Enum.join(", ")}]
    if scenario == "missing_ci_job":
        ci_jobs = ci_jobs[:-1]
    if scenario == "duplicate_ci_job":
        ci_jobs = ci_jobs + [ci_jobs[0]]
    release_status = {name: ("success" if name == "Maintain Release Please PR" else "skipped") for name in release_jobs}
    if scenario == "publication_job_succeeded":
        release_status["Publish verified release to Hex"] = "success"

    def jobs(items):
        return [{"name": name, "status": "completed", "conclusion": conclusion} for name, conclusion in items]

    if args.startswith("auth status "):
        if scenario == "tracked_write":
            state = os.path.join(os.environ["LOCKSPIRE_FIXTURE_REPO"], ".planning/STATE.md")
            with open(state, "a", encoding="utf-8") as stream:
                stream.write("\\n# concurrent tracked write\\n")
        raise SystemExit(0)
    if args.startswith("repo view "):
        print(json.dumps({"nameWithOwner": "owner/repo"}))
    elif "actions/workflows/ci.yml/runs?" in args:
        print(json.dumps({"total_count": 1, "workflow_runs": [{"id": 110, "head_sha": sha, "head_branch": "main", "event": "push", "workflow_id": 11}]}))
    elif "actions/workflows/release.yml/runs?" in args:
        print(json.dumps({"total_count": 1, "workflow_runs": [{"id": 120, "head_sha": sha, "head_branch": "main", "event": "push", "workflow_id": 12}]}))
    elif "actions/workflows/ci.yml" in args:
        print(json.dumps({"id": 11, "name": "CI", "path": ".github/workflows/ci.yml", "state": "active"}))
    elif "actions/workflows/release.yml" in args:
        print(json.dumps({"id": 12, "name": "Release", "path": ".github/workflows/release.yml", "state": "active"}))
    elif "actions/runs/110/jobs" in args:
        print(json.dumps({"total_count": len(ci_jobs), "jobs": jobs([(name, "success") for name in ci_jobs])}))
    elif "actions/runs/120/jobs" in args:
        print(json.dumps({"total_count": len(release_jobs), "jobs": jobs([(name, release_status[name]) for name in release_jobs])}))
    elif "actions/runs/110" in args:
        print(json.dumps({"id": 110, "name": "CI", "path": ".github/workflows/ci.yml", "workflow_id": 11, "repository": {"full_name": "owner/repo"}, "event": "push", "head_branch": "main", "head_sha": sha, "status": "completed", "conclusion": "success", "html_url": "https://github.com/owner/repo/actions/runs/110"}))
    elif "actions/runs/120" in args:
        print(json.dumps({"id": 120, "name": "Release", "path": ".github/workflows/release.yml", "workflow_id": 12, "repository": {"full_name": "owner/repo"}, "event": "push", "head_branch": "main", "head_sha": sha, "status": "completed", "conclusion": "success", "html_url": "https://github.com/owner/repo/actions/runs/120"}))
    elif "ls-remote" in args:
        raise SystemExit(0)
    else:
        raise SystemExit("unexpected fake gh command: " + args)
    """
  end

  defp fake_git_script do
    """
    #!/bin/sh
    if [ "$1" = "-C" ] && [ "$3" = "ls-remote" ]; then
      scenario="$LOCKSPIRE_FAKE_GIT_SCENARIO"
      count=0
      if [ -f "$LOCKSPIRE_GIT_COUNT_FILE" ]; then count="$(cat "$LOCKSPIRE_GIT_COUNT_FILE")"; fi
      count=$((count + 1))
      printf '%s\\n' "$count" > "$LOCKSPIRE_GIT_COUNT_FILE"
      if { [ "$scenario" = "remote_changed" ] && [ "$count" -eq 1 ]; } || \
         { [ "$scenario" = "final_remote_move" ] && [ "$count" -eq 2 ]; }; then
        "$LOCKSPIRE_REAL_GIT" --git-dir "$LOCKSPIRE_FAKE_ORIGIN" update-ref refs/heads/main "$LOCKSPIRE_FAKE_OLD_SHA"
      fi
    fi
    if [ "$1" = "-C" ] && [ "$3" = "remote" ] &&
       [ "$4" = "get-url" ] && [ "$5" = "origin" ]; then
      printf '%s\\n' 'https://github.com/owner/repo.git'
      exit 0
    fi
    exec "$LOCKSPIRE_REAL_GIT" "$@"
    """
  end

  defp run_verifier(fixture, options \\ []) do
    env = [
      {"PATH", fixture.fake_bin <> ":" <> System.get_env("PATH")},
      {"LOCKSPIRE_FAKE_SHA", fixture.sha},
      {"LOCKSPIRE_FIXTURE_REPO", fixture.repository},
      {"LOCKSPIRE_FAKE_ORIGIN", fixture.origin},
      {"LOCKSPIRE_FAKE_OLD_SHA", fixture.alternate_sha},
      {"LOCKSPIRE_FAKE_GH_SCENARIO", Keyword.get(options, :gh_scenario, "")},
      {"LOCKSPIRE_FAKE_GIT_SCENARIO", Keyword.get(options, :git_scenario, "")},
      {"LOCKSPIRE_GIT_COUNT_FILE", fixture.git_count_file},
      {"LOCKSPIRE_REAL_GIT", fixture.real_git}
    ]

    reviewer = Keyword.get(options, :reviewer, fixture.reviewer)
    fingerprint = Keyword.get(options, :fingerprint, fixture.fingerprint)

    System.cmd(
      "python3",
      [
        Path.join(fixture.repository, @script),
        "--sha",
        fixture.sha,
        "--record-head",
        fixture.sha,
        "--receipt",
        fixture.receipt,
        "--review-statement",
        fixture.statement,
        "--review-signature",
        fixture.signature,
        "--allowed-signers",
        fixture.allowed_signers,
        "--reviewer-principal",
        reviewer,
        "--trusted-fingerprint",
        fingerprint,
        "--output",
        fixture.output
      ],
      cd: fixture.repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp run_review_preflight(fixture) do
    env = [
      {"PATH", fixture.fake_bin <> ":" <> System.get_env("PATH")},
      {"LOCKSPIRE_REAL_GIT", fixture.real_git}
    ]

    System.cmd(
      "python3",
      [
        Path.join(fixture.repository, @script),
        "--verify-review-only",
        "--review-statement",
        fixture.statement,
        "--review-signature",
        fixture.signature,
        "--allowed-signers",
        fixture.allowed_signers,
        "--reviewer-principal",
        fixture.reviewer,
        "--trusted-fingerprint",
        fixture.fingerprint
      ],
      cd: fixture.repository,
      env: env,
      stderr_to_stdout: true
    )
  end

  defp repository_state(repository) do
    %{
      head: git!(repository, ["rev-parse", "HEAD"]),
      local_main: git!(repository, ["rev-parse", "refs/heads/main"]),
      tree: git!(repository, ["rev-parse", "HEAD^{tree}"]),
      status: git!(repository, ["status", "--porcelain=v1", "--untracked-files=all"])
    }
  end

  defp git!(cwd, args), do: command!("git", args, cwd)
  defp ssh_keygen!(cwd, args), do: command!("ssh-keygen", args, cwd)

  defp command!(program, args, cwd) do
    case System.cmd(program, args, cd: cwd, stderr_to_stdout: true) do
      {output, 0} ->
        output

      {output, status} ->
        flunk("#{program} #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end

  defp cleanup_fixture(fixture) do
    Enum.each(
      [
        fixture.signature,
        fixture.statement,
        fixture.allowed_signers,
        fixture.key_path,
        fixture.public_path,
        fixture.receipt,
        fixture.output
      ],
      &File.rm/1
    )

    File.rm_rf!(fixture.directory)
  end
end
