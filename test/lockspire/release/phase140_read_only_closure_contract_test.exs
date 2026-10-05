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
    ci_jobs = #{@ci_jobs |> Enum.map(&inspect/1) |> Enum.join(", ")}
    release_jobs = #{@release_jobs |> Enum.map(fn {name, _} -> inspect(name) end) |> Enum.join(", ")}
    skipped = {name: ("success" if name == "Maintain Release Please PR" else "skipped") for name in release_jobs}

    def jobs(items):
        return [{"name": name, "status": "completed", "conclusion": conclusion} for name, conclusion in items.items()]

    if args.startswith("auth status "):
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
        print(json.dumps({"total_count": len(ci_jobs), "jobs": jobs({name: "success" for name in ci_jobs})}))
    elif "actions/runs/120/jobs" in args:
        print(json.dumps({"total_count": len(release_jobs), "jobs": jobs(skipped)}))
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
    if [ "$1" = "-C" ] && [ "$3" = "remote" ] &&
       [ "$4" = "get-url" ] && [ "$5" = "origin" ]; then
      printf '%s\\n' 'https://github.com/owner/repo.git'
      exit 0
    fi
    exec "$LOCKSPIRE_REAL_GIT" "$@"
    """
  end

  defp run_verifier(fixture) do
    env = [
      {"PATH", fixture.fake_bin <> ":" <> System.get_env("PATH")},
      {"LOCKSPIRE_FAKE_SHA", fixture.sha},
      {"LOCKSPIRE_FIXTURE_REPO", fixture.repository},
      {"LOCKSPIRE_REAL_GIT", fixture.real_git}
    ]

    System.cmd(
      "python3",
      [
        @script,
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
        fixture.reviewer,
        "--trusted-fingerprint",
        fixture.fingerprint,
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
