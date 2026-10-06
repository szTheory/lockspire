defmodule Lockspire.Release.Phase140ReadOnlyClosureContractTest do
  use ExUnit.Case, async: false

  @script "scripts/maintainer/verify_phase140_read_only_closure.py"
  @contract_test "test/lockspire/release/phase140_read_only_closure_contract_test.exs"
  @pre_terminal_planning_commit "877a0f758aa0bbd5433cbe3d70f1476fa0e12223"
  @conditional_planning_records [
    ".planning/REQUIREMENTS.md",
    ".planning/ROADMAP.md",
    ".planning/STATE.md",
    ".planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md",
    ".planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md"
  ]
  @ci_workflow ".github/workflows/ci.yml"
  @mix_file "mix.exs"
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
  test "the committed closure command exposes only the exact-SHA acceptance inputs" do
    repo_root = Path.expand("../../..", __DIR__)
    script = Path.join(repo_root, @script)

    {output, status} = System.cmd("python3", [script, "--help"], cd: repo_root)

    assert status == 0
    assert output =~ "--sha"
    assert output =~ "--record-head"
    assert output =~ "--receipt"
    assert output =~ "--private-dir"
    assert output =~ "--output"
    refute output =~ "--review-signature"
  end

  @tag :phase140_closure_tracer
  @tag timeout: 180_000
  test "automated contract and same-SHA workflow evidence authorize the private read-only result" do
    repo_root = Path.expand("../../..", __DIR__)
    fixture = build_fixture!(repo_root)
    on_exit(fn -> cleanup_fixture(fixture) end)
    assert_pre_terminal_planning_inputs!(fixture, repo_root)

    before = repository_state(fixture.repository)
    protected_before = Enum.map(@protected_files, &File.read!(Path.join(fixture.repository, &1)))

    {output, status} = run_verifier(fixture)

    assert status == 0, output
    assert File.stat!(fixture.output).mode |> Bitwise.band(0o777) == 0o600
    result = fixture.output |> File.read!() |> Jason.decode!()
    assert result["sha"] == fixture.sha
    assert result["requirements"] == %{"CI-06" => "pass", "CI-07" => "pass"}
    automated = result["method"]["automated_verification"]
    assert automated["contract_test_path"] == @contract_test
    assert automated["ci_workflow_path"] == @ci_workflow
    assert automated["ci_job"] == "Minimum Supported Elixir/OTP"
    assert automated["ci_command"] == "mix test.fast"
    assert automated["executable_sha256"] == result["method"]["executable_sha256"]
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
  @tag timeout: 360_000
  test "rejects missing automated test coverage, lifecycle, receipt, workflow, and in-flight state" do
    repo_root = Path.expand("../../..", __DIR__)
    summary_path = ".planning/phases/140-bounded-operational-loose-end-triage/140-18-SUMMARY.md"
    requirements_path = ".planning/REQUIREMENTS.md"

    cases = [
      {"missing closure contract test",
       fn fixture -> advance_candidate!(fixture, @contract_test, :delete) end, [],
       "committed automated verifier contract is incomplete"},
      {"minimum-supported CI does not run the fast test suite",
       fn fixture ->
         workflow = File.read!(Path.join(fixture.repository, @ci_workflow))

         updated =
           String.replace(workflow, "run: mix test.fast", "run: mix compile", global: false)

         if updated == workflow, do: flunk("Fast Checks command was not found")
         advance_candidate!(fixture, @ci_workflow, updated)
       end, [], "minimum-supported CI does not run the fast test suite"},
      {"fast test alias omits lockspire tests",
       fn fixture ->
         mix_file = File.read!(Path.join(fixture.repository, @mix_file))

         updated =
           String.replace(
             mix_file,
             "test test/lockspire test/mix test/integration",
             "test test/mix test/integration",
             global: false
           )

         if updated == mix_file, do: flunk("fast test alias was not found")
         advance_candidate!(fixture, @mix_file, updated)
       end, [], "mix test.fast does not include the committed lockspire contract tests"},
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
      {"the receipt directory is publicly accessible", &make_private_directory_public!/1, [],
       "private evidence directory must be an owner-only mode-0700 directory"},
      {"the receipt directory is a symlink", &make_private_directory_symlink!/1, [],
       "private evidence directory must not be a symlink"},
      {"the receipt has unsafe permissions", &make_receipt_public!/1, [],
       "regular owner-only mode-0600 file"},
      {"a tracked file changed during live checks", fn fixture -> fixture end,
       [gh_scenario: "tracked_write"], "refs or worktree changed"},
      {"a protected file changed after candidate capture",
       fn fixture ->
         relative = hd(@protected_files)
         content = File.read!(Path.join(fixture.repository, relative))
         advance_candidate!(fixture, relative, content <> "\nchanged after baseline\n")
       end, [],
       "protected hash changed for .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"},
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
    nonce = "#{System.pid()}-#{System.unique_integer([:positive])}"
    directory = Path.join(System.tmp_dir!(), "lockspire-closure-fixture-#{nonce}")
    repository = Path.join(directory, "repository")
    origin = Path.join(directory, "origin.git")
    private_dir = Path.join(directory, "private")
    File.mkdir_p!(repository)
    File.mkdir_p!(private_dir)
    File.chmod!(private_dir, 0o700)

    git!(directory, ["init", "--bare", "--initial-branch=main", "--quiet", origin])
    git!(directory, ["init", "--initial-branch=main", "--quiet", repository])
    git!(repository, ["config", "user.name", "Lockspire fixture"])
    git!(repository, ["config", "user.email", "fixture@example.invalid"])

    files = [
      @script,
      @contract_test,
      @ci_workflow,
      @mix_file | @protected_files
    ]

    Enum.each(files, fn relative ->
      target = Path.join(repository, relative)
      File.mkdir_p!(Path.dirname(target))
      File.cp!(Path.join(repo_root, relative), target)
    end)

    Enum.each(@conditional_planning_records, fn relative ->
      target = Path.join(repository, relative)
      File.mkdir_p!(Path.dirname(target))

      File.write!(
        target,
        git!(repo_root, ["show", "#{@pre_terminal_planning_commit}:#{relative}"])
      )
    end)

    protected_baseline_blobs = %{
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md" =>
        "171d46351f804951e8a13c82173113662bb14c1c",
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md" =>
        @pre_terminal_planning_commit,
      ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md" =>
        "17a908a794449885c39e5a059f370a5823eeefd3"
    }

    Enum.each(protected_baseline_blobs, fn {relative, commit} ->
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

    receipt = Path.join(private_dir, "140-18-final-acceptance.#{sha}.json")
    output = Path.join(private_dir, "140-18-read-only-closure.#{sha}.json")

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
      private_dir: private_dir,
      receipt: receipt,
      output: output,
      fake_bin: fake_bin,
      git_count_file: Path.join(directory, "ls-remote-count"),
      real_git: System.find_executable("git")
    }
  end

  defp assert_pre_terminal_planning_inputs!(fixture, repo_root) do
    records =
      Map.new(@conditional_planning_records, fn relative ->
        expected =
          git!(repo_root, ["show", "#{@pre_terminal_planning_commit}:#{relative}"])

        actual = File.read!(Path.join(fixture.repository, relative))
        assert actual == expected, "fixture did not use historical planning blob #{relative}"
        {relative, actual}
      end)

    requirements = Map.fetch!(records, ".planning/REQUIREMENTS.md")

    for id <- ["CI-06", "CI-07"] do
      pending = Regex.compile!("^- \\[ \\] \\*\\*#{id}\\*\\*:", "m")
      complete = Regex.compile!("^- \\[x\\] \\*\\*#{id}\\*\\*:", "m")

      assert length(Regex.scan(pending, requirements)) == 1
      assert Regex.scan(complete, requirements) == []
    end

    roadmap = Map.fetch!(records, ".planning/ROADMAP.md")
    assert Regex.match?(~r/^- \[ \] \*\*Phase 140:/m, roadmap)
    refute Regex.match?(~r/^- \[x\] \*\*Phase 140:/m, roadmap)

    state = Map.fetch!(records, ".planning/STATE.md")
    assert Regex.match?(~r/^current_phase: 140$/m, state)
    assert Regex.match?(~r/^status: verifying$/m, state)

    verification =
      Map.fetch!(
        records,
        ".planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md"
      )

    assert Regex.match?(~r/^status: gaps_found$/m, verification)
    assert Regex.match?(~r/^score: 30\/32 must-haves verified$/m, verification)

    acceptance =
      Map.fetch!(
        records,
        ".planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md"
      )

    assert acceptance =~ "CI-06 and CI-07 remain pending"
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

  defp make_private_directory_public!(fixture) do
    File.chmod!(fixture.private_dir, 0o755)
    fixture
  end

  defp make_private_directory_symlink!(fixture) do
    real_directory = fixture.private_dir <> "-real"
    File.rename!(fixture.private_dir, real_directory)
    File.ln_s!(real_directory, fixture.private_dir)
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
    ci_jobs = [#{Enum.map_join(@ci_jobs, ", ", &inspect/1)}]
    release_jobs = [#{Enum.map_join(@release_jobs, ", ", fn {name, _} -> inspect(name) end)}]
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

    System.cmd(
      "python3",
      [
        Path.join(fixture.repository, @script),
        "--sha",
        fixture.sha,
        "--record-head",
        fixture.sha,
        "--private-dir",
        fixture.private_dir,
        "--receipt",
        fixture.receipt,
        "--output",
        fixture.output
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
        fixture.receipt,
        fixture.output
      ],
      &File.rm/1
    )

    File.rm_rf!(fixture.directory)
  end
end
