defmodule Lockspire.Release.RepositoryHygieneContractTest do
  use ExUnit.Case, async: true
  use Lockspire.TestSupport.ReleaseContractHelpers

  test "phase 115 hygiene separates local Docker checks from deterministic CI source checks" do
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)
    ci_workflow = File.read!(@ci_workflow_path)

    assert repo_hygiene_script =~ "local_demo_docker_hygiene_checks"
    assert repo_hygiene_script =~ "local_demo_artifact_hygiene_checks"
    assert repo_hygiene_script =~ "ci_source_contract_checks"
    assert repo_hygiene_script =~ "repo_hygiene_check.sh [--ci] [--project NAME]"
    assert repo_hygiene_script =~ "bash ./scripts/maintainer/repo_hygiene_check.sh --ci"

    assert repo_hygiene_script =~ "if [[ \"$MODE\" != \"ci\" ]]; then"
    assert repo_hygiene_script =~ "local_demo_docker_hygiene_checks"
    assert repo_hygiene_script =~ "local_demo_artifact_hygiene_checks"

    ci_branch =
      repo_hygiene_script
      |> String.split(~S(if [[ "$MODE" != "ci" ]]; then), parts: 2)
      |> hd()

    refute ci_branch =~ "docker ps"
    refute ci_branch =~ "docker volume ls"
    refute ci_branch =~ "docker info"

    assert ci_workflow =~ "bash ./scripts/maintainer/repo_hygiene_check.sh --ci"
  end

  test "phase 115 hygiene resolves the active Docker project like lifecycle helpers" do
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)
    reset_script = File.read!(@docker_reset_path)
    stop_script = File.read!(@docker_stop_path)
    cleanup_script = File.read!(@docker_cleanup_path)

    for script <- [repo_hygiene_script, reset_script, stop_script, cleanup_script] do
      assert script =~ "--project"
      assert script =~ "COMPOSE_PROJECT_NAME"
      assert script =~ "lockspire-adoption-demo"
    end

    assert repo_hygiene_script =~
             "./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci"

    explicit_project = byte_offset(repo_hygiene_script, "project=\"$2\"")
    env_project = byte_offset(repo_hygiene_script, "COMPOSE_PROJECT_NAME")
    default_project = byte_offset(repo_hygiene_script, "lockspire-adoption-demo")

    assert explicit_project > env_project
    assert env_project < default_project
  end

  test "phase 115 local hygiene classifies Docker state with calm exact remediation" do
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)

    assert repo_hygiene_script =~ "Docker is unavailable or unreachable"
    assert repo_hygiene_script =~ "WARN"
    assert repo_hygiene_script =~ "com.docker.compose.project"
    assert repo_hygiene_script =~ "running active-project demo containers"
    assert repo_hygiene_script =~ "BLOCK"
    assert repo_hygiene_script =~ "examples/adoption_demo/bin/docker-stop --project $project"

    assert repo_hygiene_script =~
             "examples/adoption_demo/bin/docker-cleanup --project $project --execute"

    assert repo_hygiene_script =~ "docker-cleanup --execute"
  end

  test "phase 115 generated artifact hygiene is allowlisted and preserves admin UI evidence" do
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)
    cleanup_script = File.read!(@docker_cleanup_path)

    for path <- [
          "tmp/adoption_demo.log",
          "examples/adoption_demo/_build",
          "examples/adoption_demo/deps"
        ] do
      assert repo_hygiene_script =~ path
      assert cleanup_script =~ path
    end

    assert repo_hygiene_script =~ "tmp/admin-ui-polish/"
    assert repo_hygiene_script =~ "Preserved"
    refute repo_hygiene_script =~ "rm -rf tmp"
    refute repo_hygiene_script =~ "find tmp"
  end

  test "Hex package inputs stay slim and exclude local build artifacts" do
    package_files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)

    assert "lib/lockspire.ex" in package_files
    assert "lib/lockspire/storage/ecto/prefix.ex" in package_files
    assert "lib/lockspire/web/live/admin/iat_live/index.html.heex" in package_files
    assert Enum.any?(package_files, &String.starts_with?(&1, "priv/repo/migrations/"))
    assert "priv/templates/lockspire.install/router.ex" in package_files
    assert "priv/templates/lockspire.install/config.exs" in package_files
    assert "priv/templates/lockspire.install/authorized_apps/index.html.heex" in package_files
    assert "docs/upgrading/storage-prefix.md" in package_files
    assert "SECURITY.md" in package_files

    refute Enum.any?(package_files, &String.contains?(&1, "*"))
    refute "lib" in package_files
    refute "priv" in package_files
    refute "priv/repo/migrations" in package_files
    refute "priv/templates" in package_files
    refute "docs" in package_files
    refute "lib/lockspire/test_repo.ex" in package_files
    refute "lib/mix/tasks/lockspire.test.setup.ex" in package_files

    package_paths =
      package_files
      |> Enum.flat_map(fn rel_path ->
        path = Path.expand("../../../#{rel_path}", __DIR__)

        cond do
          String.contains?(rel_path, "*") -> Path.wildcard(path, match_dot: true)
          File.dir?(path) -> Path.wildcard(Path.join(path, "**/*"), match_dot: true)
          File.exists?(path) -> [path]
          true -> []
        end
      end)
      |> Enum.reject(&File.dir?/1)
      |> Enum.map(&Path.relative_to(&1, Path.expand("../../..", __DIR__)))

    refute Enum.any?(package_paths, &String.ends_with?(&1, ".bak"))
    refute Enum.any?(package_paths, &String.ends_with?(&1, ".DS_Store"))
    refute Enum.any?(package_paths, &String.starts_with?(&1, "priv/plts/"))
  end

  test "phase 115 CI keeps Python smoke proof and avoids full Docker Compose smoke" do
    ci_workflow = File.read!(@ci_workflow_path)
    smoke_script = File.read!(@adoption_smoke_script_path)
    smoke_wrapper = File.read!(@adoption_smoke_wrapper_path)

    assert ci_workflow =~ "name: Adoption Demo Smoke"
    assert ci_workflow =~ "python3 scripts/demo/adoption_smoke.py"
    refute ci_workflow =~ "docker compose"
    refute ci_workflow =~ "docker-compose"

    assert smoke_script =~ "exercise_authorization_code"
    assert smoke_script =~ "exercise_discovery_and_admin"
    assert smoke_script =~ "anonymous admin login redirect"
    assert smoke_script =~ "non-operator admin access"
    assert smoke_wrapper =~ "exec python3 scripts/demo/adoption_smoke.py"
  end

  test "phase 115 CI and docs keep deterministic Docker validation only" do
    ci_workflow = File.read!(@ci_workflow_path)
    docs = File.read!(@adoption_demo_docs_path)

    assert ci_workflow =~ "name: Release Hygiene Drift"
    assert ci_workflow =~ "bash ./scripts/maintainer/repo_hygiene_check.sh --ci"
    assert ci_workflow =~ "name: Adoption Demo Smoke"
    assert ci_workflow =~ "python3 scripts/demo/adoption_smoke.py"

    refute ci_workflow =~ "docker compose"
    refute ci_workflow =~ "docker-compose"
    refute ci_workflow =~ "examples/adoption_demo/bin/docker-stop"
    refute ci_workflow =~ "examples/adoption_demo/bin/docker-cleanup"
    refute ci_workflow =~ "repo_hygiene_check.sh --project"

    assert docs =~ "CI keeps the existing Python smoke proof"
    assert docs =~ "deterministic Docker validation"
    assert docs =~ "does not run the full Docker Compose lifecycle"
  end

  test "phase 115 repo hygiene stays repo-local and does not broaden public support surface" do
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)
    docs = File.read!(@adoption_demo_docs_path)
    mix_task_paths = Path.wildcard(Path.expand("../../../lib/mix/tasks/*.ex", __DIR__))

    refute Enum.any?(mix_task_paths, &String.contains?(&1, "cleanup"))
    refute Enum.any?(mix_task_paths, &String.contains?(&1, "hygiene"))

    for source <- [repo_hygiene_script, docs] do
      refute source =~ "production Docker packaging"
      refute source =~ "hosted auth service"
      refute source =~ "public support expansion"
      refute source =~ "Lockspire owns operator authentication"
    end

    refute File.exists?(Path.expand("../../../lib/lockspire/repo_hygiene.ex", __DIR__))
    refute File.exists?(Path.expand("../../../lib/lockspire/docker_cleanup.ex", __DIR__))
  end

  test "phase 115 adoption demo docs stay repo-local without production Docker claims" do
    docs = File.read!(@adoption_demo_docs_path)

    assert docs =~ "repo-local adopter proof"
    assert docs =~ "canonical support contract still lives in `docs/supported-surface.md`"
    assert docs =~ "not a production deployment guide"
    assert docs =~ "not hosted authentication"

    refute docs =~ "production Docker packaging"
    refute docs =~ "production Docker deployment"
    refute docs =~ "hosted auth service"
    refute docs =~ "public support expansion"
    refute docs =~ "Lockspire owns operator authentication"
  end

  test "phase 115 CI source contracts prove lifecycle allowlists and public surface boundaries" do
    repo_hygiene_script = File.read!(@repo_hygiene_script_path)

    assert repo_hygiene_script =~ "docker-reset contract"
    assert repo_hygiene_script =~ "db_data deps_volume build_volume"
    assert repo_hygiene_script =~ "smoke wrapper contract"

    assert repo_hygiene_script =~
             "scripts/demo/adoption_smoke.py remains the black-box OAuth/OIDC proof"

    assert repo_hygiene_script =~ "public surface contract"

    assert repo_hygiene_script =~
             "no Mix cleanup task, runtime module, protocol/admin behavior, packaged Docker surface, or hosted-auth support expansion"

    refute repo_hygiene_script =~ "mix lockspire.demo.cleanup"
    refute repo_hygiene_script =~ "defmodule Lockspire.RepoHygiene"
  end
end
