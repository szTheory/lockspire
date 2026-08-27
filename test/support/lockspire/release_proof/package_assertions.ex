defmodule Lockspire.TestSupport.ReleaseProof.PackageAssertions do
  @moduledoc false

  import ExUnit.Assertions

  alias Lockspire.TestSupport.ReleaseProof.Paths

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
