defmodule Lockspire.Maintainer.AdopterWalkContractTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)
  @walk_script_path Path.join(@repo_root, "scripts/maintainer/adopter_path_walk.sh")
  @mix_exs_path Path.join(@repo_root, "mix.exs")
  @gitignore_path Path.join(@repo_root, ".gitignore")
  @guide_path Path.join(@repo_root, "docs/install-and-onboard.md")
  # plan 126-03 delivers this file in the same wave; it may not exist yet when this test runs on
  # its own plan, and an absent driver must contribute nothing to the mapping gate rather than
  # erroring (D-16 union scope).
  @flow_driver_path Path.join(@repo_root, "scripts/maintainer/adopter_path_flow.py")

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

  # -- ADOPT-03 step-ID <-> guide-section mapping (D-16) -------------------------------------
  #
  # The gate scans two sources, not one: `record_result` calls in the shell script, and the
  # printed `[PASS|FAIL] step-NN...: §N ...` result-line literals plan 126-05 folds verbatim into
  # the shell harness's RESULTS accumulator from `scripts/maintainer/adopter_path_flow.py` (plan
  # 126-03, not yet delivered when this test is first written). Every assertion below runs over
  # the union of both, so a driver-emitted step is exactly as protected as a shell step.

  defp shell_steps(source) do
    ~r/record_result\s+"(?:PASS|FAIL)"\s+"(step-0[1-8][a-z]?-[a-zA-Z0-9_-]+)"\s+"([^"]*)"/
    |> Regex.scan(source, capture: :all_but_first)
    |> Enum.map(fn [id, detail] -> {id, detail} end)
  end

  defp driver_steps(source) do
    ~r/\[(?:PASS|FAIL)\]\s+(step-0[1-8][a-z]?-[a-zA-Z0-9_-]+):\s*(§\d+[^\n"]*)/
    |> Regex.scan(source, capture: :all_but_first)
    |> Enum.map(fn [id, detail] -> {id, detail} end)
  end

  defp combined_steps do
    shell_source = File.read!(@walk_script_path)

    driver_source =
      if File.regular?(@flow_driver_path) do
        File.read!(@flow_driver_path)
      else
        ""
      end

    shell_steps(shell_source) ++ driver_steps(driver_source)
  end

  defp step_section_number(id) do
    id
    |> String.replace_prefix("step-", "")
    |> String.slice(0, 2)
    |> String.to_integer()
    |> Integer.to_string()
  end

  defp label_section_number(detail) do
    case Regex.run(~r/§(\d+)/, detail) do
      [_, number] -> number
      nil -> nil
    end
  end

  test "every guide-mapped step ID resolves to a real docs/install-and-onboard.md section (ADOPT-03 structural mapping)" do
    guide = File.read!(@guide_path)

    section_headings =
      ~r/^## (\d+)\./m
      |> Regex.scan(guide, capture: :all_but_first)
      |> List.flatten()
      |> MapSet.new()

    steps = combined_steps()
    assert steps != [], "expected at least one guide-mapped step-0[1-8] to be present"

    for {id, _detail} <- steps do
      section = step_section_number(id)

      assert section in section_headings,
             "#{id} has no matching '## #{section}.' heading in docs/install-and-onboard.md"
    end
  end

  test "every step's §N label agrees with its own step ID number (ADOPT-03 semantic mapping)" do
    for {id, detail} <- combined_steps() do
      section = step_section_number(id)
      label = label_section_number(detail)

      refute is_nil(label), "#{id}'s detail #{inspect(detail)} carries no §N label"

      assert label == section,
             "#{id} labels itself §#{label} but its own ID number is #{section}"
    end
  end

  test "no two steps share a step-NN number while labelling different guide sections (ADOPT-03 uniqueness)" do
    combined_steps()
    |> Enum.map(fn {id, detail} ->
      nn = id |> String.replace_prefix("step-", "") |> String.slice(0, 2)
      {nn, label_section_number(detail)}
    end)
    |> Enum.group_by(fn {nn, _label} -> nn end, fn {_nn, label} -> label end)
    |> Enum.each(fn {nn, labels} ->
      unique_labels = labels |> Enum.reject(&is_nil/1) |> Enum.uniq()

      assert length(unique_labels) <= 1,
             "step-#{nn}* steps disagree on guide section: #{inspect(unique_labels)}"
    end)
  end

  test "every workaround marker matches the exact LOCKSPIRE_WALK_WORKAROUND ADOPT-D shape" do
    source = File.read!(@walk_script_path)

    marker_lines =
      source
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 =~ "LOCKSPIRE_WALK_WORKAROUND"))

    assert marker_lines != [], "expected at least one workaround marker"

    for line <- marker_lines do
      assert line =~ ~r/^# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D\d+$/,
             "malformed workaround marker: #{inspect(line)}"
    end
  end

  test "both lockspire_routes/0 interpretations are exercised as separate walk steps" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-03b-router-call"
    assert source =~ "step-03b-router-paste"
    assert source =~ "step-03b-router-wire"
  end
end
