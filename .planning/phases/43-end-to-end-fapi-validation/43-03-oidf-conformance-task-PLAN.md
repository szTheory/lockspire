---
phase: 43-end-to-end-fapi-validation
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/mix/tasks/lockspire.oidf_conformance.ex
  - scripts/conformance/fapi2-plan.json
  - docs/maintainer-conformance.md
  - test/mix/tasks/lockspire/oidf_conformance_test.exs
autonomous: true
requirements: [FAPI-06]
must_haves:
  truths:
    - "Running `mix lockspire.oidf_conformance --validate-env` exits 0 when env vars, dependencies, and required artifact paths are present (D-13, D-14)"
    - "Running `mix lockspire.oidf_conformance --validate-env` exits non-zero with a clear error message when any prerequisite is missing"
    - "The Mix task does NOT execute the OIDF Docker suite — it only validates the environment (D-14, D-16)"
    - "scripts/conformance/fapi2-plan.json is committed and pins the canonical FAPI 2.0 plan name + variants verbatim (D-15)"
    - "docs/maintainer-conformance.md pins the same plan + variants and references the JSON file (D-15)"
    - "The three orphan references to `mix lockspire.oidf_conformance` (docs, workflow, contract test) all resolve once this task exists"
  artifacts:
    - path: "lib/mix/tasks/lockspire.oidf_conformance.ex"
      provides: "Mix.Task implementing the OIDF preflight (D-13)"
      contains: "defmodule Mix.Tasks.Lockspire.OidfConformance"
    - path: "scripts/conformance/fapi2-plan.json"
      provides: "Pinned OIDF FAPI 2.0 plan + variants (D-15)"
      contains: "fapi2-security-profile-final-test-plan"
    - path: "docs/maintainer-conformance.md"
      provides: "Documented plan name + variant axes verbatim (D-15)"
      contains: "fapi2-security-profile-final-test-plan"
  key_links:
    - from: "Mix.Tasks.Lockspire.OidfConformance.run/1"
      to: "scripts/conformance/fapi2-check.sh"
      via: "preflight artifact existence check"
      pattern: "scripts/conformance/fapi2-check.sh"
    - from: "Mix.Tasks.Lockspire.OidfConformance.run/1"
      to: "scripts/conformance/fapi2-plan.json"
      via: "preflight artifact existence check"
      pattern: "scripts/conformance/fapi2-plan.json"
    - from: ".github/workflows/oidf-conformance.yml line 66"
      to: "Mix.Tasks.Lockspire.OidfConformance"
      via: "task name match — workflow already calls `mix lockspire.oidf_conformance --validate-env`"
      pattern: "mix lockspire\\.oidf_conformance"
---

<objective>
Implement `mix lockspire.oidf_conformance` as a real, env-validating Mix task that resolves the
three orphan references currently in the repo (`docs/maintainer-conformance.md:53`,
`.github/workflows/oidf-conformance.yml:66`, `test/lockspire/release_readiness_contract_test.exs:481`).

Per D-13, D-14, D-16: the task is a deterministic `--validate-env` preflight that checks env vars,
shell dependencies, and required artifact paths. It does NOT execute the external OIDF Docker
suite — that remains a documented manual maintainer step.

Also pin the canonical OIDF FAPI 2.0 plan name + variant axes verbatim in a new
`scripts/conformance/fapi2-plan.json` (mirroring `scripts/conformance/phase37-plan.json`) and
document the same plan + variants in `docs/maintainer-conformance.md` (D-15).

Purpose: Close the residual Phase 42 closure work so Phase 43's E2E proof lane has an executable
preflight, and so any maintainer can reproduce the OIDF run from documented inputs.

Output: One new Mix task module, one new JSON artifact, one updated docs file, one new test
file proving the task exits 0/non-zero correctly.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md
@.planning/phases/43-end-to-end-fapi-validation/43-RESEARCH.md
@.planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md

<interfaces>
Mix.Task scaffold pattern (verbatim from `lib/mix/tasks/lockspire.client.create.ex`):
```elixir
defmodule Mix.Tasks.Lockspire.Client.Create do
  @moduledoc """..."""
  @shortdoc "Registers a durable OAuth client"
  use Mix.Task
  @requirements ["app.config"]
  @switches [client_id: :string, ..., help: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
    if invalid != [] do
      Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end
    if Keyword.get(opts, :help, false) do
      Mix.shell().info(help())
    else
      ...
    end
  end
end
```

Existing OIDF preflight precedent (verbatim from `scripts/conformance/fapi2-check.sh`):
- Required env: `LOCKSPIRE_CLIENT_ID`, `LOCKSPIRE_BASE_URL` (default present)
- Required commands: `bash`, `curl`

Existing OIDF maintainer-conformance.md hint at line 53:
```markdown
You can also run the `mix lockspire.oidf_conformance` task to perform this check.
It expects `LOCKSPIRE_TEST_DB_HOST` and `OIDF_CONFORMANCE_SERVER` to be set if not in dry-run.
```
The env vars referenced by the docs are `LOCKSPIRE_TEST_DB_HOST` and `OIDF_CONFORMANCE_SERVER`.
The task MUST require these.

Pinned OIDF plan JSON precedent (mirror `scripts/conformance/phase37-plan.json` shape).
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create scripts/conformance/fapi2-plan.json with pinned plan + variants (D-15)</name>
  <files>scripts/conformance/fapi2-plan.json</files>
  <read_first>
    - scripts/conformance/phase37-plan.json (entire file — exact precedent shape)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-15 — verbatim plan name + variant axes)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("scripts/conformance/fapi2-plan.json" section)
  </read_first>
  <action>
    Create `scripts/conformance/fapi2-plan.json` with this EXACT content:

    ```json
    {
      "description": "Lockspire Phase 43 FAPI 2.0 Security Profile Final test plan",
      "artifact_dir": ".artifacts/conformance/fapi2",
      "plans": [
        {
          "name": "fapi-2-0-security-profile-final",
          "suite_plan": "fapi2-security-profile-final-test-plan",
          "variants": {
            "fapi_profile": "plain_fapi",
            "client_auth_type": "private_key_jwt",
            "sender_constrain": "dpop",
            "fapi_request_method": "unsigned",
            "fapi_response_mode": "plain_response"
          },
          "modules": []
        }
      ]
    }
    ```

    The plan name `fapi2-security-profile-final-test-plan` and the five variant axes are LOCKED
    by D-15 — do NOT alter them. `modules: []` mirrors the phase37 precedent's "all-modules-of-plan"
    semantics.
  </action>
  <verify>
    <automated>test -f scripts/conformance/fapi2-plan.json &amp;&amp; cat scripts/conformance/fapi2-plan.json | python3 -m json.tool &gt;/dev/null &amp;&amp; grep -q "fapi2-security-profile-final-test-plan" scripts/conformance/fapi2-plan.json &amp;&amp; grep -q "private_key_jwt" scripts/conformance/fapi2-plan.json &amp;&amp; grep -q '"sender_constrain": "dpop"' scripts/conformance/fapi2-plan.json</automated>
  </verify>
  <acceptance_criteria>
    - File `scripts/conformance/fapi2-plan.json` exists
    - File is valid JSON (`python3 -m json.tool` exits 0)
    - File contains the literal string `"fapi2-security-profile-final-test-plan"`
    - File contains all five variant values: `"plain_fapi"`, `"private_key_jwt"`, `"dpop"`, `"unsigned"`, `"plain_response"`
    - `grep -c '"modules": \[\]' scripts/conformance/fapi2-plan.json` returns 1
    - File contains `"artifact_dir": ".artifacts/conformance/fapi2"`
  </acceptance_criteria>
  <done>
    Plan JSON committed; valid JSON; verbatim plan name + variant axes per D-15.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Implement Mix.Tasks.Lockspire.OidfConformance with --validate-env (D-13, D-14, D-16)</name>
  <files>lib/mix/tasks/lockspire.oidf_conformance.ex, test/mix/tasks/lockspire/oidf_conformance_test.exs</files>
  <read_first>
    - lib/mix/tasks/lockspire.client.create.ex (entire file — Mix.Task scaffold pattern)
    - scripts/conformance/fapi2-check.sh (entire file — required env vars precedent)
    - scripts/conformance/run_phase37_suite.sh (lines 1-80 — `require_command` pattern)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-13 task name, D-14 deterministic preflight, D-16 NO docker compose)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Mix task wrapping fapi2-check.sh" section)
    - test/mix/tasks/ (list directory — confirm test dir layout for Mix.Task tests)
  </read_first>
  <behavior>
    - `mix lockspire.oidf_conformance --validate-env` with all required env vars, commands, and artifacts present prints a success line and exits 0
    - The same invocation with any required env var missing raises `Mix.Error` with a message naming the missing variable
    - The same invocation with `scripts/conformance/fapi2-plan.json` or `scripts/conformance/fapi2-check.sh` missing raises `Mix.Error` naming the missing artifact
    - The same invocation with `bash` or `curl` missing on PATH raises `Mix.Error` naming the missing command
    - `mix lockspire.oidf_conformance --help` prints usage info to stdout and exits 0
    - The task NEVER invokes `docker`, `docker compose`, or any OIDF suite binary directly (D-14, D-16)
    - Default invocation (no flags) behaves the same as `--validate-env`
  </behavior>
  <action>
    Create `lib/mix/tasks/lockspire.oidf_conformance.ex` with this exact module shape:

    ```elixir
    defmodule Mix.Tasks.Lockspire.OidfConformance do
      @moduledoc """
      Validate the OIDF FAPI 2.0 conformance preflight environment.

      This task does NOT execute the OIDF conformance Docker suite. The live suite
      run remains a documented manual maintainer step (see
      `docs/maintainer-conformance.md`). This task only verifies that the
      environment, dependencies, and pinned plan artifacts are present so a
      maintainer can proceed with the manual run.

      ## Usage

          mix lockspire.oidf_conformance --validate-env

      Required environment variables:
        * `LOCKSPIRE_TEST_DB_HOST`
        * `OIDF_CONFORMANCE_SERVER`

      Required commands on PATH: `bash`, `curl`
      Required artifacts: `scripts/conformance/fapi2-check.sh`, `scripts/conformance/fapi2-plan.json`
      """

      @shortdoc "Validates the OIDF FAPI 2.0 conformance preflight environment"

      use Mix.Task

      @requirements ["app.config"]

      @required_envs ~w(LOCKSPIRE_TEST_DB_HOST OIDF_CONFORMANCE_SERVER)
      @required_artifacts [
        "scripts/conformance/fapi2-check.sh",
        "scripts/conformance/fapi2-plan.json"
      ]
      @required_commands ~w(bash curl)

      @switches [validate_env: :boolean, help: :boolean]

      @impl Mix.Task
      def run(args) do
        {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

        if invalid != [] do
          Mix.raise("Unknown options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
        end

        cond do
          Keyword.get(opts, :help, false) -> Mix.shell().info(help())
          true -> validate_env!()
        end
      end

      defp validate_env! do
        missing_envs = Enum.reject(@required_envs, &(System.get_env(&1) not in [nil, ""]))
        missing_artifacts = Enum.reject(@required_artifacts, &File.exists?/1)
        missing_commands = Enum.reject(@required_commands, &System.find_executable/1)

        if missing_envs != [] or missing_artifacts != [] or missing_commands != [] do
          Mix.raise("""
          OIDF FAPI 2.0 conformance preflight failed.
            missing env vars: #{inspect(missing_envs)}
            missing artifacts: #{inspect(missing_artifacts)}
            missing commands: #{inspect(missing_commands)}

          See docs/maintainer-conformance.md for setup instructions.
          """)
        end

        Mix.shell().info(
          "OIDF FAPI 2.0 preflight OK: env, artifacts, and dependencies present. " <>
            "Proceed with the manual Docker suite run per docs/maintainer-conformance.md."
        )
      end

      defp help do
        """
        mix lockspire.oidf_conformance --validate-env

        Validates the OIDF FAPI 2.0 conformance preflight environment.
        Does NOT run the live Docker suite (manual maintainer step).

        Required env vars: #{Enum.join(@required_envs, ", ")}
        Required commands: #{Enum.join(@required_commands, ", ")}
        Required artifacts:
          #{Enum.join(@required_artifacts, "\n          ")}
        """
      end
    end
    ```

    The task MUST NOT spawn `docker` or any OIDF suite binary. Per D-16, live suite execution
    stays a documented manual step.

    Create `test/mix/tasks/lockspire/oidf_conformance_test.exs` (mkdir -p the test dir if missing) with
    these test cases. Use `ExUnit.CaptureIO`, `System.put_env/2` / `System.delete_env/1`, and
    `assert_raise Mix.Error` to drive the behavior assertions:

    ```elixir
    defmodule Mix.Tasks.Lockspire.OidfConformanceTest do
      use ExUnit.Case, async: false
      import ExUnit.CaptureIO

      @task Mix.Tasks.Lockspire.OidfConformance

      setup do
        prior_db = System.get_env("LOCKSPIRE_TEST_DB_HOST")
        prior_oidf = System.get_env("OIDF_CONFORMANCE_SERVER")

        on_exit(fn ->
          if prior_db, do: System.put_env("LOCKSPIRE_TEST_DB_HOST", prior_db),
            else: System.delete_env("LOCKSPIRE_TEST_DB_HOST")
          if prior_oidf, do: System.put_env("OIDF_CONFORMANCE_SERVER", prior_oidf),
            else: System.delete_env("OIDF_CONFORMANCE_SERVER")
        end)

        :ok
      end

      test "exits 0 with success message when env, artifacts, and commands are all present" do
        System.put_env("LOCKSPIRE_TEST_DB_HOST", "localhost")
        System.put_env("OIDF_CONFORMANCE_SERVER", "https://localhost.emobix.co.uk:8443/")

        out = capture_io(fn -> @task.run(["--validate-env"]) end)
        assert out =~ "OIDF FAPI 2.0 preflight OK"
      end

      test "raises when LOCKSPIRE_TEST_DB_HOST is missing" do
        System.delete_env("LOCKSPIRE_TEST_DB_HOST")
        System.put_env("OIDF_CONFORMANCE_SERVER", "https://localhost.emobix.co.uk:8443/")

        assert_raise Mix.Error, ~r/LOCKSPIRE_TEST_DB_HOST/, fn ->
          @task.run(["--validate-env"])
        end
      end

      test "raises when OIDF_CONFORMANCE_SERVER is missing" do
        System.put_env("LOCKSPIRE_TEST_DB_HOST", "localhost")
        System.delete_env("OIDF_CONFORMANCE_SERVER")

        assert_raise Mix.Error, ~r/OIDF_CONFORMANCE_SERVER/, fn ->
          @task.run(["--validate-env"])
        end
      end

      test "raises on unknown switches" do
        assert_raise Mix.Error, ~r/Unknown options/, fn ->
          @task.run(["--no-such-flag"])
        end
      end

      test "--help prints usage and does not validate" do
        System.delete_env("LOCKSPIRE_TEST_DB_HOST")
        System.delete_env("OIDF_CONFORMANCE_SERVER")

        out = capture_io(fn -> @task.run(["--help"]) end)
        assert out =~ "mix lockspire.oidf_conformance"
        assert out =~ "--validate-env"
      end
    end
    ```

    Do NOT add tests that call `docker compose` — D-14/D-16 forbid live suite execution from
    this task.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/lockspire/oidf_conformance_test.exs --color &amp;&amp; grep -c "docker" lib/mix/tasks/lockspire.oidf_conformance.ex | grep -E "^0$" &amp;&amp; grep -q "fapi2-plan.json" lib/mix/tasks/lockspire.oidf_conformance.ex &amp;&amp; grep -q "fapi2-check.sh" lib/mix/tasks/lockspire.oidf_conformance.ex</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "defmodule Mix.Tasks.Lockspire.OidfConformance" lib/mix/tasks/lockspire.oidf_conformance.ex` returns 1
    - `grep -c "use Mix.Task" lib/mix/tasks/lockspire.oidf_conformance.ex` returns 1
    - `grep -c "@requirements" lib/mix/tasks/lockspire.oidf_conformance.ex` returns 1
    - `grep -c "scripts/conformance/fapi2-check.sh" lib/mix/tasks/lockspire.oidf_conformance.ex` returns >= 1
    - `grep -c "scripts/conformance/fapi2-plan.json" lib/mix/tasks/lockspire.oidf_conformance.ex` returns >= 1
    - `grep -c "LOCKSPIRE_TEST_DB_HOST" lib/mix/tasks/lockspire.oidf_conformance.ex` returns >= 1
    - `grep -c "OIDF_CONFORMANCE_SERVER" lib/mix/tasks/lockspire.oidf_conformance.ex` returns >= 1
    - `grep -cE "docker|System\.cmd" lib/mix/tasks/lockspire.oidf_conformance.ex` returns 0 (D-14, D-16 — task does NOT invoke docker/suite)
    - `mix test test/mix/tasks/lockspire/oidf_conformance_test.exs` exits 0 (all 5 tests pass)
    - `mix compile --warnings-as-errors` exits 0
    - With both required env vars set, `LOCKSPIRE_TEST_DB_HOST=localhost OIDF_CONFORMANCE_SERVER=https://x mix lockspire.oidf_conformance --validate-env` exits 0
  </acceptance_criteria>
  <done>
    Mix task implemented; env-validating only; tests prove pass + each failure mode; no docker invocation in source.
  </done>
</task>

<task type="auto">
  <name>Task 3: Pin canonical OIDF plan + variants in docs/maintainer-conformance.md (D-15)</name>
  <files>docs/maintainer-conformance.md</files>
  <read_first>
    - docs/maintainer-conformance.md (entire file — confirm existing line 53 hint, find the FAPI 2.0 section near line 88-98 for placement)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-15 — pin plan + variants verbatim)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("docs/maintainer-conformance.md" section)
  </read_first>
  <action>
    In `docs/maintainer-conformance.md`, append a new H2 section (use the existing "## FAPI 2.0 notes"
    section's location as guidance — place the new section immediately after it, OR replace that
    section with the new pinned content if the existing notes are obsolete after this edit). The
    new section MUST contain this EXACT block (verbatim — no rewording, the strings here are pinned
    by Plan 07's contract test):

    ```markdown
    ## FAPI 2.0 OIDF plan (Phase 43)

    Use the `fapi2-security-profile-final-test-plan` plan in the OIDF UI, with these variants:

    - `fapi_profile`: `plain_fapi`
    - `client_auth_type`: `private_key_jwt`
    - `sender_constrain`: `dpop`
    - `fapi_request_method`: `unsigned`
    - `fapi_response_mode`: `plain_response`

    The same plan and variants are pinned in `scripts/conformance/fapi2-plan.json`.
    The live Docker run remains a manual maintainer step; CI does not gate on it.

    Run `mix lockspire.oidf_conformance --validate-env` to verify your environment, dependencies,
    and pinned artifacts before launching the suite.
    ```

    Do NOT remove or rewrite the existing line 53 reference (`mix lockspire.oidf_conformance`) —
    Plan 02 of Phase 42 already wrote it as the orphan that this plan resolves. The text MAY be
    edited only if it is currently inaccurate (e.g., wrong env var names); the env vars
    `LOCKSPIRE_TEST_DB_HOST` and `OIDF_CONFORMANCE_SERVER` from the existing line MUST match the
    `@required_envs` list in Task 2.
  </action>
  <verify>
    <automated>grep -q "fapi2-security-profile-final-test-plan" docs/maintainer-conformance.md &amp;&amp; grep -q "private_key_jwt" docs/maintainer-conformance.md &amp;&amp; grep -q '\`sender_constrain\`: \`dpop\`' docs/maintainer-conformance.md &amp;&amp; grep -q "scripts/conformance/fapi2-plan.json" docs/maintainer-conformance.md</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "fapi2-security-profile-final-test-plan" docs/maintainer-conformance.md` returns >= 1
    - `grep -c "private_key_jwt" docs/maintainer-conformance.md` returns >= 1
    - `grep -c "plain_fapi" docs/maintainer-conformance.md` returns >= 1
    - `grep -c "fapi_request_method" docs/maintainer-conformance.md` returns >= 1
    - `grep -c "scripts/conformance/fapi2-plan.json" docs/maintainer-conformance.md` returns >= 1
    - `grep -c "mix lockspire.oidf_conformance" docs/maintainer-conformance.md` returns >= 1 (preserved orphan-resolving reference)
    - `grep -c "LOCKSPIRE_TEST_DB_HOST" docs/maintainer-conformance.md` returns >= 1 (matches Task 2's required env)
  </acceptance_criteria>
  <done>
    Maintainer doc pins the canonical OIDF plan + all five variants verbatim; references the new JSON file; preserves the orphan-resolving Mix task reference.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Maintainer shell -> Mix task | Local-only execution; trust boundary is operator credentials |
| Mix task -> file system reads + env reads | Read-only preflight; no remote calls |
| Maintainer doc -> external OIDF suite | Documentation-as-contract; suite execution is manual and out of CI scope |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-11 | Spoofing (config drift) | OIDF run uses different plan/variants than what Lockspire claims | mitigate | Plan name + variants pinned verbatim in `scripts/conformance/fapi2-plan.json` AND `docs/maintainer-conformance.md`. Plan 07 contract test asserts the strings appear in both. Severity: HIGH — silent variant drift would invalidate any conformance claim. |
| T-43-12 | Tampering (orphan reference reachability) | CI workflow / docs reference a nonexistent Mix task | mitigate | Task 2 implements the task; Task 3 ensures the docs ref still resolves. Plan 07 reasserts `mix lockspire.oidf_conformance` appears in the workflow. Severity: HIGH — orphan refs are themselves a contract-test invariant. |
| T-43-13 | Elevation of Privilege (task running suite without operator awareness) | Task silently invokes docker compose with privileged mounts | mitigate | Task 2 acceptance criteria explicitly forbids `docker` or `System.cmd` calls. D-14/D-16 codify this. Severity: HIGH — addressed structurally by design. |
| T-43-14 | Information Disclosure (env vars leaked in error messages) | `Mix.raise` echoes env var names with values | mitigate | The task only echoes env var NAMES (e.g., `"LOCKSPIRE_TEST_DB_HOST"`), never values, in the missing-env list. The Mix.raise body shows `inspect(missing_envs)` which is the list of names. Severity: LOW. |
| T-43-15 | Repudiation (no record of preflight pass) | Operator runs preflight but no artifact records the outcome | accept | Task is intentionally stdout-only; CI captures stdout via `actions/upload-artifact`. Severity: LOW. |
| T-43-16 | Tampering (malicious plan JSON edit) | Attacker edits `fapi2-plan.json` to a weaker plan | mitigate | Plan 07 contract test asserts the canonical plan string appears in the JSON file. Severity: MEDIUM. |
</threat_model>

<verification>
- `mix test test/mix/tasks/lockspire/oidf_conformance_test.exs` exits 0
- `mix compile --warnings-as-errors` exits 0
- `cat scripts/conformance/fapi2-plan.json | python3 -m json.tool` exits 0
- All grep assertions in Task 1, Task 2, and Task 3 acceptance_criteria pass
- `grep -c "docker\|System\.cmd" lib/mix/tasks/lockspire.oidf_conformance.ex` returns 0
- `LOCKSPIRE_TEST_DB_HOST=localhost OIDF_CONFORMANCE_SERVER=https://x mix lockspire.oidf_conformance --validate-env` exits 0
</verification>

<success_criteria>
- Mix task `lockspire.oidf_conformance` exists, is env-validating only, and resolves the three orphan references
- `scripts/conformance/fapi2-plan.json` exists with pinned plan name + all five variant axes verbatim per D-15
- `docs/maintainer-conformance.md` documents the same pinned plan + variants and references the JSON
- Plan 07 will reassert these strings in the truth-in-docs contract test
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-03-SUMMARY.md`
</output>
