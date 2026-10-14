defmodule Lockspire.TestSupport.ReleaseProof.PackageAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.ReleaseProof.Paths

  @next_phase_number "139"

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
    assert adoption_docs =~ "black-box OAuth/OIDC proof"
    assert adoption_docs =~ "not a production deployment guide"
    refute ci =~ "docker compose"
    refute ci =~ "docker-compose"
    refute script =~ "mix lockspire.demo.cleanup"
    refute File.exists?(Paths.path("lib/lockspire/repo_hygiene.ex"))
  end

  def assert_phase_139_exact_sha_hygiene! do
    script = Paths.read!("scripts/maintainer/repo_hygiene_check.sh")
    {output, status} = run_exact_sha_hygiene_fixture!("success", assert_main_only_fetch: true)

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

  def assert_phase_139_release_train_fail_closed! do
    release_train_path = Paths.path(".planning/RELEASE-TRAIN.md")
    metadata_line = "- Release Please version metadata: `1.5.1` <!-- x-release-please-version -->"

    public_line =
      "- Latest public package: Hex `1.5.1`, published from source `0b56503859b69531ff86d8e4a465a0e75f963594` on 2026-10-08. Release Please metadata above is not publication proof."

    artifact_line =
      "- Artifact truth: protected release run [37795671282](https://github.com/szTheory/lockspire/actions/runs/37795671282) for source `0b56503859b69531ff86d8e4a465a0e75f963594` was backed by matching canonical push CI [37788996197](https://github.com/szTheory/lockspire/actions/runs/37788996197), whose seven required jobs passed on that exact SHA. The release run verified the public Hex checksum `c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3`, HexDocs, [lockspire-v1.5.1](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.1), and clean-room install. Its terminal receipt records `release_verified: true` with no blocker. The overall run failed only in bounded evidence retention; PR #120 fixed the receipt validator."

    source = File.read!(release_train_path)

    for historical_value <- [
          "Previous release: source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`",
          "33141161205",
          "33141484467",
          "lockspire-v1.5.0",
          "30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de"
        ] do
      assert source =~ historical_value
    end

    cases = [
      {"missing Release Please metadata", String.replace(source, metadata_line <> "\n", "")},
      {"duplicate Release Please metadata",
       String.replace(source, metadata_line, metadata_line <> "\n" <> metadata_line)},
      {"malformed Release Please metadata",
       String.replace(
         source,
         metadata_line,
         "- Release Please version metadata: `one.five.one` <!-- x-release-please-version -->"
       )},
      {"mismatched Release Please metadata",
       String.replace(source, metadata_line, String.replace(metadata_line, "1.5.1", "1.5.2"))},
      {"missing public package claim", String.replace(source, public_line <> "\n", "")},
      {"duplicate public package claim",
       String.replace(source, public_line, public_line <> "\n" <> public_line)},
      {"malformed public package claim",
       String.replace(
         source,
         public_line,
         String.replace(public_line, "Hex `1.5.1`", "Hex `latest`")
       )},
      {"public package disagrees with Release Please metadata",
       String.replace(
         source,
         public_line,
         String.replace(public_line, "Hex `1.5.1`", "Hex `1.5.2`")
       )},
      {"public package source disagrees with protected release proof",
       String.replace(
         source,
         public_line,
         String.replace(
           public_line,
           "0b56503859b69531ff86d8e4a465a0e75f963594",
           "1b56503859b69531ff86d8e4a465a0e75f963594"
         )
       )},
      {"missing artifact proof", String.replace(source, artifact_line <> "\n", "")},
      {"duplicate artifact proof",
       String.replace(source, artifact_line, artifact_line <> "\n" <> artifact_line)},
      {"malformed artifact checksum",
       String.replace(
         source,
         artifact_line,
         String.replace(
           artifact_line,
           "c13dabddef307dcb5d89490642272571e91d12bdf3fd14756e820600121df0b3",
           "invalid"
         )
       )},
      {"artifact tag disagrees with public package",
       String.replace(
         source,
         artifact_line,
         String.replace(artifact_line, "lockspire-v1.5.1", "lockspire-v1.5.0")
       )},
      {"GitHub release URL disagrees with its label",
       String.replace(
         source,
         artifact_line,
         String.replace(artifact_line, "/tag/lockspire-v1.5.1)", "/tag/lockspire-v1.5.2)")
       )},
      {"GitHub release URL points to another repository",
       String.replace(
         source,
         artifact_line,
         String.replace(
           artifact_line,
           "https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.1",
           "https://github.com/another-owner/another-repo/releases/tag/lockspire-v1.5.1"
         )
       )},
      {"legacy release label cannot replace metadata",
       String.replace(source, metadata_line, "- Latest released version: `1.5.1`")}
    ]

    Enum.each(cases, fn {label, contents} ->
      {output, status} =
        run_exact_sha_hygiene_fixture!("success", release_train_contents: contents)

      assert status != 0, "#{label} unexpectedly passed: #{output}"

      assert output =~ "[BLOCK] release train ledger",
             "#{label} did not block the ledger: #{output}"

      refute output =~ "fixture-credential-sentinel", "#{label} leaked fixture credentials"
      refute output =~ ~s({"workflow_runs"), "#{label} leaked a raw workflow response"
    end)
  end

  def assert_phase_139_docker_volume_name_matching! do
    script = Paths.read!("scripts/maintainer/repo_hygiene_check.sh")

    assert length(Regex.scan(~r/project_volumes="\$\(active_project_volume_names\)"/, script)) ==
             2

    refute script =~ "active_project_volume_names || true"

    {output, status} =
      run_exact_sha_hygiene_fixture!("docker-volume-exact",
        dispositions: ["adoption demo volumes=reviewed"]
      )

    assert status == 0, output
    receipt = Jason.decode!(output)
    assert receipt["hygiene"]["warn"] == 1

    assert receipt["warn_dispositions"] == [
             %{"label" => "adoption demo volumes", "disposition" => "reviewed"}
           ]

    {output, status} = run_exact_sha_hygiene_fixture!("docker-volume-lookalikes", [])

    assert status == 0, output
    receipt = Jason.decode!(output)
    assert receipt["hygiene"]["warn"] == 0
    assert receipt["warn_dispositions"] == []
  end

  def assert_phase_139_local_docker_list_failures! do
    script = Paths.read!("scripts/maintainer/repo_hygiene_check.sh")
    assert script =~ "running_observation_failed=true"
    assert script =~ "stopped_observation_failed=true"
    assert script =~ "volume_observation_failed=true"

    cases = [
      {
        "running-container-list-failure",
        "[WARN] adoption demo containers: running active-project container state could not be observed for lockspire-adoption-demo",
        "[PASS] adoption demo containers: no running active-project demo containers found for lockspire-adoption-demo"
      },
      {
        "stopped-container-list-failure",
        "[WARN] adoption demo stopped containers: stopped active-project container state could not be observed for lockspire-adoption-demo",
        "[PASS] adoption demo stopped containers: no stopped project containers found for lockspire-adoption-demo"
      },
      {
        "volume-list-failure",
        "[WARN] adoption demo volumes: active-project volume state could not be observed for lockspire-adoption-demo",
        "[PASS] adoption demo volumes: no active-project demo volumes found for lockspire-adoption-demo"
      }
    ]

    fixture = unique_tmp_fixture("lockspire-local-volume-failure")
    bin = Path.join(fixture, "bin")

    real_git =
      System.find_executable("git") || flunk("git is required for the local hygiene fixture")

    try do
      File.mkdir_p!(bin)
      File.write!(Path.join(bin, "git"), local_hygiene_git_script())
      File.write!(Path.join(bin, "gh"), "#!/usr/bin/env bash\nexit 1\n")
      File.write!(Path.join(bin, "docker"), local_hygiene_docker_script())

      for command <- ["git", "gh", "docker"] do
        File.chmod!(Path.join(bin, command), 0o755)
      end

      Enum.each(cases, fn {scenario, expected_warning, forbidden_pass} ->
        {output, status} =
          System.cmd(
            "bash",
            [Paths.path("scripts/maintainer/repo_hygiene_check.sh"), "--skip-mix-ci"],
            cd: Paths.path("."),
            env: [
              {"PATH", bin <> ":" <> System.get_env("PATH", "")},
              {"REAL_GIT", real_git},
              {"FAKE_LOCAL_HYGIENE_SCENARIO", scenario}
            ],
            stderr_to_stdout: true
          )

        assert status in [0, 1], output
        assert output =~ expected_warning
        refute output =~ forbidden_pass
      end)
    after
      File.rm_rf(fixture)
    end
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
      {"Docker running-container list failure", "docker-running-list-failure", []},
      {"Docker stopped-container list failure", "docker-stopped-list-failure", []},
      {"identity movement during Docker inspection", "docker-main-race", []},
      {"Docker volume-list failure", "docker-volume-list-failure", []},
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

  defp unique_tmp_fixture(prefix) do
    suffix = "#{System.os_time(:nanosecond)}-#{System.unique_integer([:positive])}"
    Path.join(System.tmp_dir!(), "#{prefix}-#{suffix}")
  end

  defp run_exact_sha_hygiene_fixture!(scenario, options) do
    fixture = unique_tmp_fixture("lockspire-exact-sha-hygiene")
    bin = Path.join(fixture, "bin")
    state = Path.join(fixture, "state")
    jq = System.find_executable("jq") || flunk("jq is required for the exact-SHA fixture")

    repository =
      if Keyword.has_key?(options, :release_train_contents),
        do:
          prepare_release_train_fixture_repo!(
            fixture,
            Keyword.fetch!(options, :release_train_contents)
          ),
        else: Paths.path(".")

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
          cd: repository,
          env: [
            {"PATH", bin <> ":" <> System.get_env("PATH", "")},
            {"FAKE_REPO_ROOT", repository},
            {"FAKE_HYGIENE_SHA", acceptance_sha()},
            {"FAKE_HYGIENE_STATE", state},
            {"TMPDIR", state},
            {"FAKE_HYGIENE_SCENARIO", scenario},
            {"LOCKSPIRE_HYGIENE_REPOSITORY", "szTheory/lockspire"}
          ],
          stderr_to_stdout: true
        )

      if Keyword.get(options, :assert_main_only_fetch, false) do
        fetch_log = Path.join(state, "fetch.argv")

        assert File.exists?(fetch_log),
               "exact-SHA acceptance did not refresh origin/main: #{elem(result, 0)}"

        fetch_commands =
          fetch_log
          |> File.read!()
          |> String.split("\n", trim: true)

        assert fetch_commands != [], "exact-SHA acceptance recorded no fetch command"

        assert Enum.all?(fetch_commands, fn command ->
                 command ==
                   "fetch --no-tags origin refs/heads/main:refs/remotes/origin/main"
               end),
               "exact-SHA acceptance must fetch only origin/main without tags or pruning"
      end

      if Keyword.has_key?(options, :release_train_contents) do
        refute File.exists?(Path.join(state, "fetch.argv")),
               "a blocked release-train claim must stop before origin/main fetch"

        refute elem(result, 0) =~ ~s("schema":"lockspire-phase-),
               "a blocked release-train claim must not emit an acceptance receipt"
      end

      refute Enum.any?(File.ls!(state), &String.starts_with?(&1, "lockspire-mix-ci."))
      result
    after
      File.rm_rf(fixture)
    end
  end

  defp prepare_release_train_fixture_repo!(fixture, release_train_contents) do
    source_root = Paths.path(".")
    repository = Path.join(fixture, "repo")

    generated_or_mutable = [
      ".git",
      ".planning",
      "_build",
      "deps",
      "node_modules",
      "coverage",
      ".elixir_ls",
      "tmp"
    ]

    File.mkdir_p!(Path.join(repository, ".planning"))

    for entry <- File.ls!(source_root), entry not in generated_or_mutable do
      File.ln_s!(Path.join(source_root, entry), Path.join(repository, entry))
    end

    File.write!(Path.join(repository, ".planning/RELEASE-TRAIN.md"), release_train_contents)
    repository
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
      "fetch --no-tags origin refs/heads/main:refs/remotes/origin/main")
        printf '%s\n' "$*" >> "$FAKE_HYGIENE_STATE/fetch.argv"
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
      "container ls --filter label=com.docker.compose.project=lockspire-adoption-demo --format {{.Names}}")
        [ "$scenario" = "docker-running-list-failure" ] && exit 98 || : ;;
      "container ls --all --filter label=com.docker.compose.project=lockspire-adoption-demo --filter status=exited --format {{.Names}}")
        if [ "$scenario" = "docker-stopped-list-failure" ]; then exit 99; fi
        [ "$scenario" = "docker-warn" ] && printf 'stopped-demo\n' || : ;;
      "volume list --format {{.Name}}")
        case "$scenario" in
          docker-volume-list-failure) exit 97 ;;
          docker-main-race) : > "$FAKE_HYGIENE_STATE/docker-inspected" ;;
          docker-volume-exact)
            printf '%s\n' \
              'lockspire-adoption-demo_db_data' \
              'prefix-lockspire-adoption-demo_db_data' \
              'lockspire-adoption-demo_db_data_backup' \
              'lockspire-adoption-demo_other' ;;
          docker-volume-lookalikes)
            printf '%s\n' \
              'prefix-lockspire-adoption-demo_db_data' \
              'lockspire-adoption-demo_db_data_backup' \
              'lockspire-adoption-demo_other' ;;
          *) : ;;
        esac ;;
      *) printf 'unexpected fake docker command\n' >&2; exit 96 ;;
    esac
    """
  end

  defp local_hygiene_git_script do
    ~S"""
    #!/usr/bin/env bash
    set -eu
    if [[ "$*" == "fetch origin --prune" ]]; then
      exit 1
    fi
    exec "$REAL_GIT" "$@"
    """
  end

  defp local_hygiene_docker_script do
    ~S"""
    #!/usr/bin/env bash
    set -eu
    scenario="${FAKE_LOCAL_HYGIENE_SCENARIO:-volume-list-failure}"
    case "$*" in
      "version") exit 0 ;;
      "container ls --filter label=com.docker.compose.project=lockspire-adoption-demo --format {{.Names}}")
        [[ "$scenario" != "running-container-list-failure" ]] || exit 97 ;;
      "container ls --all --filter label=com.docker.compose.project=lockspire-adoption-demo --filter status=exited --format {{.Names}}")
        [[ "$scenario" != "stopped-container-list-failure" ]] || exit 98 ;;
      "volume list --format {{.Name}}")
        [[ "$scenario" != "volume-list-failure" ]] || exit 99 ;;
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
