defmodule Lockspire.Maintainer.AdopterWalkContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)
  @walk_script_path Path.join(@repo_root, "scripts/maintainer/adopter_path_walk.sh")
  @mix_exs_path Path.join(@repo_root, "mix.exs")
  @gitignore_path Path.join(@repo_root, ".gitignore")

  test "walk script exists and uses FAIL-tolerant strict mode" do
    assert File.regular?(@walk_script_path)

    source = File.read!(@walk_script_path)

    assert source =~ "set -uo pipefail"
    refute source =~ "set -euo pipefail"
  end

  test "walk script defines the accumulator and report/verdict lines" do
    source = File.read!(@walk_script_path)

    assert source =~ "record_result"
    assert source =~ ~r/Summary:/
    assert source =~ "Result: adopter path is"
  end

  test "walk script implements the ADOPT-03 resume contract" do
    source = File.read!(@walk_script_path)

    assert source =~ ".walk/steps"
    assert source =~ "--from-step"
    assert source =~ "--workdir"
    assert source =~ "--keep"
    assert source =~ "--port"
  end

  test "walk script isolates the Mix archive directory" do
    source = File.read!(@walk_script_path)

    assert source =~ "MIX_ARCHIVES"
  end

  test "walk script never strips generator capabilities" do
    source = File.read!(@walk_script_path)

    refute source =~ ~r/--no-(ecto|html|assets|mailer)/
  end

  test "walk script preserves the evidence tree unconditionally" do
    source = File.read!(@walk_script_path)

    refute source =~ ~r/trap[^\n]*rm -rf/
    refute source =~ "mktemp -d"
  end

  test "mix.exs wires the adopter.walk alias and keeps it out of ci" do
    source = File.read!(@mix_exs_path)

    assert source =~
             ~s("adopter.walk": ["cmd bash scripts/maintainer/adopter_path_walk.sh"])

    ci_alias =
      source
      |> String.split(~r/\n\s*ci:\s*\[/, parts: 2)
      |> List.last()
      |> String.split(~r/\n\s*\]/, parts: 2)
      |> List.first()

    refute ci_alias =~ "adopter_path_walk"
  end

  test ".gitignore ignores the harness-local Mix archive directory" do
    source = File.read!(@gitignore_path)

    assert source =~ ".harness"
  end

  test "walk script pins and forces the isolated phx_new archive install" do
    source = File.read!(@walk_script_path)

    assert source =~ "mix archive.install hex phx_new 1.8.9 --force"
    assert source =~ "Phoenix installer v1.8.9"
  end

  test "walk script generates a stock database-backed Phoenix app" do
    source = File.read!(@walk_script_path)

    assert source =~ "mix phx.new host_app --database postgres"
  end

  test "walk script applies phx.gen.auth with the mandatory --live flag" do
    source = File.read!(@walk_script_path)

    assert source =~ "mix phx.gen.auth Accounts User users --live"
  end

  test "walk script still never strips a generator capability after generation steps" do
    source = File.read!(@walk_script_path)

    refute source =~ ~r/--no-(ecto|html|assets|mailer)/
  end

  test "walk script never copies the committed adoption-demo secret_key_base literal" do
    walk_source = File.read!(@walk_script_path)

    demo_config_path =
      Path.join(@repo_root, "examples/adoption_demo/config/config.exs")

    demo_config = File.read!(demo_config_path)

    demo_secret =
      Regex.run(~r/secret_key_base:\s*"([^"]+)"/, demo_config, capture: :all_but_first)

    case demo_secret do
      [literal] -> refute walk_source =~ literal
      nil -> :ok
    end
  end

  test "walk script exports the cross-plan walk credential contract" do
    source = File.read!(@walk_script_path)

    assert source =~ "LOCKSPIRE_WALK_EMAIL"
    assert source =~ "LOCKSPIRE_WALK_PASSWORD"
    assert source =~ "walker@adopter.test"
    assert source =~ "walk-adopter-password-2026"
  end

  test "walk script seeds the user through the generator's own confirmation path" do
    source = File.read!(@walk_script_path)

    assert source =~ "register_user"
    assert source =~ "build_email_token"
    assert source =~ "login_user_by_magic_link"
    assert source =~ "update_user_password"
  end
end
