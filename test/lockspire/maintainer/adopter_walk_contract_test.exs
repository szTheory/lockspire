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

  test "mix.exs wires the adopter.walk.verify alias, outside ci, and it never references adopter_path_walk" do
    source = File.read!(@mix_exs_path)

    assert source =~
             ~s("adopter.walk.verify": ["cmd bash scripts/maintainer/adopter_walk_ci.sh"])

    ci_alias =
      source
      |> String.split(~r/\n\s*ci:\s*\[/, parts: 2)
      |> List.last()
      |> String.split(~r/\n\s*\]/, parts: 2)
      |> List.first()

    refute ci_alias =~ "adopter_path_walk"
    refute ci_alias =~ "adopter.walk.verify"
    refute ci_alias =~ "adopter_walk_ci"
  end

  test "walk script always writes a machine-readable JSON report" do
    source = File.read!(@walk_script_path)

    assert source =~ "--report-json"
    assert source =~ "REPORT_JSON"
    assert source =~ "scripts/maintainer/adopter_walk_report.py"
  end

  test "record_result appends to the NUL-delimited record stream" do
    source = File.read!(@walk_script_path)

    assert source =~ "RECORD_STREAM"
    assert source =~ ~s(printf '%s\\0%s\\0%s\\0' "$level" "$label" "$detail" >>"$RECORD_STREAM")
  end

  test "the baseline file exists and parses as JSON" do
    baseline_path = Path.join(@repo_root, "scripts/maintainer/adopter_walk_baseline.json")

    assert File.regular?(baseline_path)

    assert {:ok, %{"schema" => "lockspire.adopter_walk.baseline/1"}} =
             baseline_path |> File.read!() |> Jason.decode()
  end

  test "the verifier never provides a --bless or --update-baseline flag" do
    verify_path = Path.join(@repo_root, "scripts/maintainer/adopter_walk_verify.py")

    assert File.regular?(verify_path)

    source = File.read!(verify_path)

    # Checks for an actual argparse flag registration, not the doc comment explaining this
    # script deliberately never registers one.
    refute source =~ ~s(add_argument("--bless")
    refute source =~ ~s(add_argument("--update-baseline")
    assert source =~ "--print-baseline-patch"
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

  # -- Plan 126-04: guide §3c host resolver seam, §3d app-tree wiring, §3e protected route -----

  test "walk script implements the host resolver seam as step-03c-resolver" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-03c-resolver"
    assert source =~ "resolve_account"
    assert source =~ "build_claims"
    assert source =~ "walker@adopter.test"
  end

  test "the host resolver seam is written into the generated host, never the library or templates" do
    source = File.read!(@walk_script_path)

    assert source =~ ~s(lib/host_app/lockspire/account_resolver.ex)

    refute source =~ ~r/cat\s*>[^\n]*priv\/templates\/lockspire\.install\/account_resolver\.ex/
    refute source =~ ~r/cat\s*>[^\n]*lib\/lockspire\/account_resolver\.ex/

    assert System.cmd("git", ["diff", "--exit-code", "--", "priv/templates/lockspire.install/"],
             cd: @repo_root
           )
           |> elem(1) == 0

    assert System.cmd("git", ["diff", "--exit-code", "--", "lib/lockspire/"], cd: @repo_root)
           |> elem(1) == 0
  end

  test "the resolver's login path is /users/log-in with no harness workaround (ADOPT-D09 closed)" do
    source = File.read!(@walk_script_path)

    refute source =~ "ADOPT-D09"
    refute source =~ "# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D09"
    assert source =~ "/users/log-in"
  end

  test "walk script wires application-start ordering and supervision children as step-03d-app-tree (ADOPT-D05)" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-03d-app-tree"
    assert source =~ "included_applications: [:lockspire]"
    assert source =~ "# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D05"
    assert source =~ "Lockspire.Oban"
    assert source =~ "Lockspire.KeyCache"
    assert source =~ "lockspire_jwks_cache"
    assert source =~ "ADOPT-D05"

    # included_applications alone is not sufficient: Application.ensure_all_started/1 never walks
    # an included application's own dependency chain, so :oban's and :cachex's own supervision
    # trees (Oban.Registry, the Cachex supervisor) never start unless named directly in the
    # host's own extra_applications -- confirmed empirically (Registry.whereis_name/2 raised
    # "unknown registry: Oban.Registry" against a real generated host until this was added).
    assert source =~ "extra_applications: [:logger, :runtime_tools, :oban, :cachex]"

    # ADOPT-D04's own marker (step-03a-config-import) must remain the only marker for the
    # queue-disabling config key -- step-03d must not add a second one.
    refute source =~ "LOCKSPIRE_WALK_WORKAROUND: ADOPT-D04\nLOCKSPIRE_WALK_WORKAROUND: ADOPT-D04"
  end

  test "walk script wires the protected host API route as step-03e-protected-route with the canonical plug order" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-03e-protected-route"
    assert source =~ "BEGIN LOCKSPIRE_PROTECTED_PIPELINE"
    assert source =~ "END LOCKSPIRE_PROTECTED_PIPELINE"
    assert source =~ "read:walk"
    assert source =~ "/api/walk/summary"

    verify_index = index_of(source, "Lockspire.Plug.VerifyToken")
    constraints_index = index_of(source, "Lockspire.Plug.EnforceSenderConstraints")
    require_index = index_of(source, "Lockspire.Plug.RequireToken")

    assert verify_index < constraints_index
    assert constraints_index < require_index
  end

  test "the protected route path in the harness is byte-identical to the flow driver's default" do
    walk_source = File.read!(@walk_script_path)

    driver_default_path =
      if File.regular?(@flow_driver_path) do
        driver_source = File.read!(@flow_driver_path)

        case Regex.run(~r/DEFAULT_PROTECTED_PATH\s*=\s*"([^"]+)"/, driver_source,
               capture: :all_but_first
             ) do
          [path] -> path
          nil -> nil
        end
      end

    refute is_nil(driver_default_path),
           "expected adopter_path_flow.py to define DEFAULT_PROTECTED_PATH"

    assert walk_source =~ driver_default_path
  end

  test "the contract test fails if the protected route plug order is broken (regression guard)" do
    source = File.read!(@walk_script_path)

    # The plug order lives in a single-line `printf '...'` argument in the shell source, so the
    # literal file text carries backslash-n escape pairs, not real newlines -- match on that
    # literal text rather than an interpolated \n.
    reordered =
      String.replace(
        source,
        ~s(plug Lockspire.Plug.VerifyToken, scopes: ["read:walk"]\\n    plug Lockspire.Plug.EnforceSenderConstraints\\n    plug Lockspire.Plug.RequireToken),
        ~s(plug Lockspire.Plug.RequireToken\\n    plug Lockspire.Plug.EnforceSenderConstraints\\n    plug Lockspire.Plug.VerifyToken, scopes: ["read:walk"])
      )

    verify_index = index_of(reordered, "Lockspire.Plug.VerifyToken")
    constraints_index = index_of(reordered, "Lockspire.Plug.EnforceSenderConstraints")
    require_index = index_of(reordered, "Lockspire.Plug.RequireToken")

    refute verify_index < constraints_index and constraints_index < require_index
  end

  defp index_of(source, needle) do
    case :binary.match(source, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  # -- Plan 126-05: guide §4 migrate, §5 verify, §6 client/signing-key, boot/drive/teardown -----

  test "walk script implements guide §4 migrate and §5 verify as step-04-migrate and step-05-verify" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-04-migrate"
    assert source =~ "step-05-verify"
    assert source =~ "mix ecto.migrate"
    assert source =~ "mix lockspire.verify"
  end

  test "step-04-migrate never records PASS -- the migration verdict is deferred to step-05-verify" do
    source = File.read!(@walk_script_path)

    refute source =~ ~s(record_result "PASS" "step-04-migrate")
    assert source =~ ~s(record_result "FAIL" "step-04-migrate")
  end

  test "step-05-verify parses mix lockspire.verify's captured output instead of only checking its exit status" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-05-verify"
    assert source =~ "Pending Lockspire or Oban migrations detected"
    assert source =~ "pending_count"
    assert source =~ "missing_tables"
  end

  test "the migrations workaround uses the release-safe application-directory form and never the dependency-directory form (ADOPT-D07)" do
    source = File.read!(@walk_script_path)

    assert source =~ "ADOPT-D07"
    assert source =~ "# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D07"
    assert source =~ ~s[Application.app_dir(:lockspire, "priv/repo/migrations")]
    refute source =~ "deps/lockspire/priv/repo/migrations"
  end

  test "the contract test fails if the release-safe migrations form is replaced by the dependency-directory form (regression guard)" do
    source = File.read!(@walk_script_path)

    mutated =
      String.replace(
        source,
        ~s[Application.app_dir(:lockspire, "priv/repo/migrations")],
        ~s(deps/lockspire/priv/repo/migrations)
      )

    refute mutated =~ ~s[Application.app_dir(:lockspire, "priv/repo/migrations")]
    assert mutated =~ "deps/lockspire/priv/repo/migrations"
  end

  test "walk script implements guide §6 client registration and signing key as step-06a-client" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-06a-client"
    assert source =~ "mix lockspire.client.create"
    assert source =~ "adopter-walk-public"
    assert source =~ "read:walk"
    assert source =~ "Lockspire.Admin.generate_key"
    refute source =~ "ADOPT-D08"
    refute source =~ "# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D08"
    assert source =~ "ADOPT-D06"
    assert source =~ "# LOCKSPIRE_WALK_WORKAROUND: ADOPT-D06"
  end

  test "walk script boots the generated host, invokes the flow driver, and redirects server output to a workdir-local log" do
    source = File.read!(@walk_script_path)

    assert source =~ "scripts/maintainer/adopter_path_flow.py"
    assert source =~ "mix phx.server"
    assert source =~ "SERVER_LOG"
    assert source =~ "server.log"
  end

  test "walk script installs only a pid-only trap and never removes the workdir on exit" do
    source = File.read!(@walk_script_path)

    assert source =~ "trap cleanup EXIT INT TERM"
    refute source =~ ~r/trap[^\n]*rm -rf/
  end

  test "walk script folds the flow driver's PASS/FAIL result lines into its own RESULTS accumulator" do
    source = File.read!(@walk_script_path)

    assert source =~ ~s(record_result "$level")
    assert source =~ "driver_step_id"
    assert source =~ "driver_detail"
  end

  test "walk script terminates the server by default and respects --keep as the only opt-out" do
    source = File.read!(@walk_script_path)

    assert source =~ ~s(kill "$SERVER_PID")
    assert source =~ "stays bound"
    assert source =~ ~s(if [[ "$KEEP" -eq 1 ]])
  end

  test "walk script accounts for guide §7 and §8 as explicitly not walked" do
    source = File.read!(@walk_script_path)

    assert source =~ "step-07-upgrade (not walked)"
    assert source =~ "step-08-verify-seam (not walked)"
    assert source =~ "not walked"
  end

  test "the not-walked §7/§8 report lines are excluded from the ADOPT-03 step-ID mapping gate by design" do
    source = File.read!(@walk_script_path)

    refute {"step-07-upgrade (not walked)",
            "§7 Upgrade only the managed scaffolding: not walked -- an upgrade path for existing installs, not the first-install path this walk proves"} in shell_steps(
             source
           )

    refute Enum.any?(shell_steps(source), fn {id, _detail} ->
             id =~ "not walked"
           end)
  end

  test "the protected route path used by step-06 boot/drive matches the flow driver invocation" do
    source = File.read!(@walk_script_path)

    assert source =~ "/api/walk/summary"
    assert source =~ "--protected-path /api/walk/summary"
  end
end
