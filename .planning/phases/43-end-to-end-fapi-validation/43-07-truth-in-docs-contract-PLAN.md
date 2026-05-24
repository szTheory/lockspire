---
phase: 43-end-to-end-fapi-validation
plan: 07
type: execute
wave: 2
depends_on: [43-03-oidf-conformance-task, 43-04-host-test-template, 43-05-truthful-claim-docs]
files_modified:
  - test/lockspire/release_readiness_contract_test.exs
autonomous: true
requirements: [FAPI-05, FAPI-06]
must_haves:
  truths:
    - "release_readiness_contract_test.exs gains a 'phase 43 FAPI 2.0 milestone' test asserting the 8 pinned positive strings appear in SECURITY.md, README.md, and docs/supported-surface.md (D-12, D-19, D-20)"
    - "The contract test refutes the literal word 'certified' in each of the three docs (D-19)"
    - "The contract test asserts the canonical OIDF plan name + variants appear in docs/maintainer-conformance.md AND scripts/conformance/fapi2-plan.json (D-15, D-20)"
    - "The contract test asserts the new install-generator template entry exists in lib/lockspire/generators/templates.ex (D-17)"
    - "The line-481 reference to 'mix lockspire.oidf_conformance' in the workflow is preserved (orphan resolves once Plan 03 lands)"
    - "A new module attribute @fapi2_conformance_plan_path is added pointing at scripts/conformance/fapi2-plan.json"
  artifacts:
    - path: "test/lockspire/release_readiness_contract_test.exs"
      provides: "Phase 43 truth-in-docs contract test block"
      contains: "phase 43 FAPI 2.0"
    - path: "test/lockspire/release_readiness_contract_test.exs"
      provides: "Module attribute for fapi2-plan.json path"
      contains: "@fapi2_conformance_plan_path"
  key_links:
    - from: "release_readiness_contract_test.exs (new test block)"
      to: "SECURITY.md / README.md / docs/supported-surface.md"
      via: "File.read! + assert =~ pinned strings"
      pattern: "FAPI 2\\.0 Security Profile"
    - from: "release_readiness_contract_test.exs (new test block)"
      to: "scripts/conformance/fapi2-plan.json (Plan 03)"
      via: "File.read! + assert pinned plan + variant strings"
      pattern: "fapi2-security-profile-final-test-plan"
    - from: "release_readiness_contract_test.exs (new test block)"
      to: "lib/lockspire/generators/templates.ex (Plan 04)"
      via: "File.read! + assert template registry contains fapi_smoke_e2e_test entry"
      pattern: "fapi_smoke_e2e_test\\.exs"
---

<objective>
Update `test/lockspire/release_readiness_contract_test.exs` (the locked truth-in-docs validator)
with a new test block that asserts every truth-in-docs claim made by Phase 43 is actually
present in the repo. Per D-12/D-19/D-20, this test is the executable contract that prevents
silent doc drift after the v1.10 archive.

The new test block asserts:
1. The 8 pinned positive strings appear in SECURITY.md, README.md, and docs/supported-surface.md
   (D-19, mirroring Plan 05)
2. The literal word `certified` is absent from each of the three docs
3. The canonical OIDF plan name + 5 variant axes appear in `docs/maintainer-conformance.md` AND
   `scripts/conformance/fapi2-plan.json` (D-15, mirroring Plan 03)
4. The new install-generator template entry exists in `lib/lockspire/generators/templates.ex`
   (D-17, mirroring Plan 04)
5. The existing line-481 workflow reference to `mix lockspire.oidf_conformance` is preserved
   (orphan resolution from Plan 03)

Purpose: This test is the tripwire. If anyone deletes the FAPI 2.0 claim language, the OIDF plan
pin, or the host-template registration, CI will fail and prevent silent regression of milestone
truth claims.

Output: One modified test file (~40 new lines including module attribute + the new test block).
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
@.planning/phases/43-end-to-end-fapi-validation/43-03-oidf-conformance-task-PLAN.md
@.planning/phases/43-end-to-end-fapi-validation/43-04-host-test-template-PLAN.md
@.planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-PLAN.md

<interfaces>
Existing precedent block in `test/lockspire/release_readiness_contract_test.exs` (lines 465-482):
```elixir
test "phase 42 preparatory lane docs stay truthful about certification and feature support" do
  maintainer_conformance = File.read!(@maintainer_conformance_path)
  workflow = File.read!(@oidf_conformance_workflow_path)

  assert maintainer_conformance =~ "preparatory OIDF lane"
  assert maintainer_conformance =~ "Phase 42 wires the lane for Phase 43 consumption"
  assert maintainer_conformance =~ "does not claim pass-ready certification"
  assert maintainer_conformance =~ "does not imply support for mTLS or `private_key_jwt`"

  refute maintainer_conformance =~ "fully certified"
  refute maintainer_conformance =~ "Phase 43 completion"

  assert workflow =~ "uses: actions/upload-artifact@v4"
  assert workflow =~ "mix lockspire.oidf_conformance"
end
```

Existing module attributes (lines 22-36) include:
- `@maintainer_conformance_path`
- `@security_policy_path`
- `@readme_path`
- `@supported_surface_path`
- `@oidf_conformance_workflow_path`

New module attribute to add for the OIDF plan JSON:
```elixir
@fapi2_conformance_plan_path Path.expand("../../scripts/conformance/fapi2-plan.json", __DIR__)
```

Pinned string vocabulary (from Plan 05 `<pinned_strings>`):
POSITIVE (must appear in each of SECURITY.md, README.md, docs/supported-surface.md):
1. `FAPI 2.0 Security Profile`
2. `PAR`
3. `DPoP`
4. `ES256/PS256`
5. `exact-match redirect URIs`
6. `RFC 9207`
7. `authorization_response_iss_parameter_supported`
8. `require_pushed_authorization_requests`

NEGATIVE:
A. literal word `certified` MUST NOT appear in any of the three docs
B. `mTLS` MUST appear in each (negative-claim context)
C. `OIDF` MUST appear in each (negative-claim context)
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add @fapi2_conformance_plan_path module attribute and Phase 43 truth-in-docs test (D-12, D-19, D-20)</name>
  <files>test/lockspire/release_readiness_contract_test.exs</files>
  <read_first>
    - test/lockspire/release_readiness_contract_test.exs (entire file — confirm existing module attribute block lines 1-36, find the existing Phase 42 test block at lines 465-482 to use as the immediate-prior precedent)
    - SECURITY.md (re-read after Plan 05 lands — confirm pinned strings are present)
    - README.md (re-read after Plan 05 lands)
    - docs/supported-surface.md (re-read after Plan 05 lands)
    - docs/maintainer-conformance.md (re-read after Plan 03 lands — confirm pinned plan + variants)
    - scripts/conformance/fapi2-plan.json (created by Plan 03 — confirm content)
    - lib/lockspire/generators/templates.ex (re-read after Plan 04 lands — confirm fapi_smoke_e2e_test.exs registry entry)
    - .planning/phases/43-end-to-end-fapi-validation/43-CONTEXT.md (D-12, D-15, D-17, D-19, D-20)
    - .planning/phases/43-end-to-end-fapi-validation/43-PATTERNS.md ("Truth-in-docs assertions" section)
    - .planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-PLAN.md (`<pinned_strings>` block)
  </read_first>
  <behavior>
    - Adding the new test block does NOT break any existing test in the file
    - The new test asserts all 8 positive pinned strings appear in EACH of SECURITY.md, README.md, docs/supported-surface.md (24 positive assertions total)
    - The new test refutes the literal word `certified` in EACH of the three docs (3 refute assertions)
    - The new test asserts `mTLS` and `OIDF` appear in EACH of the three docs (6 assertions)
    - The new test asserts the canonical OIDF plan + 5 variant axes appear in `docs/maintainer-conformance.md` (6 assertions) AND in `scripts/conformance/fapi2-plan.json` (6 assertions)
    - The new test asserts `lib/lockspire/generators/templates.ex` contains `fapi_smoke_e2e_test.exs` (1 assertion)
    - The new test asserts `.github/workflows/oidf-conformance.yml` still references `mix lockspire.oidf_conformance` (1 assertion — preserves the orphan-now-resolved reference)
  </behavior>
  <action>
    Edit `test/lockspire/release_readiness_contract_test.exs`:

    1. Add a new module attribute immediately after the existing module attribute block (after `@requirements_path` around line 36):
       ```elixir
       @fapi2_conformance_plan_path Path.expand("../../scripts/conformance/fapi2-plan.json", __DIR__)
       @templates_registry_path Path.expand("../../lib/lockspire/generators/templates.ex", __DIR__)
       ```

    2. Append a new test block IMMEDIATELY AFTER the existing `test "phase 42 preparatory lane docs stay truthful..."` block (which is the LAST test in the file at lines 465-482). The new test block must be inside the same module (before the final `end`):

       ```elixir
       test "phase 43 FAPI 2.0 milestone claims stay truthful and bounded (D-12, D-19, D-20)" do
         security = File.read!(@security_policy_path)
         readme = File.read!(@readme_path)
         supported_surface = File.read!(@supported_surface_path)
         maintainer_conformance = File.read!(@maintainer_conformance_path)
         fapi2_plan = File.read!(@fapi2_conformance_plan_path)
         templates_registry = File.read!(@templates_registry_path)
         workflow = File.read!(@oidf_conformance_workflow_path)

         positive_pinned_strings = [
           "FAPI 2.0 Security Profile",
           "PAR",
           "DPoP",
           "ES256/PS256",
           "exact-match redirect URIs",
           "RFC 9207",
           "authorization_response_iss_parameter_supported",
           "require_pushed_authorization_requests"
         ]

         # D-19 positive claims: each pinned string must appear in each of the three docs
         for {doc_name, doc_text} <- [
               {"SECURITY.md", security},
               {"README.md", readme},
               {"docs/supported-surface.md", supported_surface}
             ] do
           for pinned <- positive_pinned_strings do
             assert doc_text =~ pinned,
                    "expected #{doc_name} to contain pinned positive FAPI 2.0 string #{inspect(pinned)}"
           end

           # D-19 negative claims: do NOT claim certification, do NOT claim mTLS support
           refute Regex.match?(~r/\bcertified\b/, doc_text),
                  "#{doc_name} must NOT contain the literal word 'certified'"

           assert doc_text =~ "mTLS",
                  "#{doc_name} must mention mTLS in negative-claim context"
           assert doc_text =~ "OIDF",
                  "#{doc_name} must mention OIDF in negative-claim context"
         end

         # D-15: pin the OIDF plan + 5 variant axes in maintainer-conformance.md AND fapi2-plan.json
         oidf_plan_pins = [
           "fapi2-security-profile-final-test-plan",
           "plain_fapi",
           "private_key_jwt",
           "dpop",
           "unsigned",
           "plain_response"
         ]

         for pinned <- oidf_plan_pins do
           assert maintainer_conformance =~ pinned,
                  "expected docs/maintainer-conformance.md to pin #{inspect(pinned)}"
           assert fapi2_plan =~ pinned,
                  "expected scripts/conformance/fapi2-plan.json to pin #{inspect(pinned)}"
         end

         # D-17: install generator emits a host-owned FAPI smoke test template
         assert templates_registry =~ "fapi_smoke_e2e_test.exs",
                "expected templates registry to register the FAPI smoke E2E test template"

         # Plan 03: Mix task reference in the OIDF workflow stays resolved
         assert workflow =~ "mix lockspire.oidf_conformance"
       end
       ```

    3. Do NOT remove or modify any existing test. The new test sits AFTER the Phase 42 block and
       is the LAST test in the module.
  </action>
  <verify>
    <automated>mix test test/lockspire/release_readiness_contract_test.exs --color</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "@fapi2_conformance_plan_path" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "@templates_registry_path" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c 'phase 43 FAPI 2.0 milestone claims' test/lockspire/release_readiness_contract_test.exs` returns 1
    - `grep -c "fapi2-security-profile-final-test-plan" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "fapi_smoke_e2e_test.exs" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "FAPI 2.0 Security Profile" test/lockspire/release_readiness_contract_test.exs` returns >= 1 (in the positive_pinned_strings list)
    - `grep -c "ES256/PS256" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "RFC 9207" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "exact-match redirect URIs" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "authorization_response_iss_parameter_supported" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `grep -c "require_pushed_authorization_requests" test/lockspire/release_readiness_contract_test.exs` returns >= 1
    - `mix test test/lockspire/release_readiness_contract_test.exs` exits 0 (ALL tests in the file pass — both pre-existing and the new block)
    - The line-481 reference `assert workflow =~ "mix lockspire.oidf_conformance"` in the Phase 42 block is preserved (it now resolves because Plan 03 created the task)
    - `mix compile --warnings-as-errors` exits 0
  </acceptance_criteria>
  <done>
    Phase 43 truth-in-docs contract test added; all assertions pass against the doc/JSON/template state produced by Plans 03/04/05; pre-existing tests remain green.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Future PR -> release_readiness_contract_test.exs | Any change that drops a pinned FAPI 2.0 claim, removes the OIDF plan pin, or unregisters the host template fails CI |
| CI -> v1.10 milestone archive | Contract test pass is the gate condition |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-43-34 | Tampering (silent doc drift) | Future PR removes positive FAPI 2.0 claims from a doc | mitigate | Contract test asserts all 8 positive pinned strings in EACH of 3 docs (24 assertions). Drift fails CI. Severity: HIGH — this is the core truth-in-docs gate. |
| T-43-35 | Spoofing (overclaim re-introduction) | Future PR adds the word "certified" back to a doc | mitigate | `refute Regex.match?(~r/\bcertified\b/, doc_text)` blocks word-boundary "certified" in all 3 docs. Severity: HIGH. |
| T-43-36 | Tampering (OIDF plan variant drift) | Future PR changes the variant axes in fapi2-plan.json or maintainer-conformance.md | mitigate | Contract test asserts all 6 plan/variant strings in BOTH artifacts (12 assertions). Severity: HIGH — silent variant drift would invalidate any conformance claim. |
| T-43-37 | Tampering (host template unregistered) | Future PR removes the fapi_smoke_e2e_test.exs entry from the templates registry | mitigate | Contract test asserts `fapi_smoke_e2e_test.exs` appears in `lib/lockspire/generators/templates.ex`. Severity: HIGH — host integrators lose their FAPI proof scaffold. |
| T-43-38 | Tampering (orphan reference re-introduced) | Future PR removes the Mix task `lockspire.oidf_conformance` while workflow still references it | mitigate | Contract test re-asserts `workflow =~ "mix lockspire.oidf_conformance"` (preserves Phase 42 intent that this reference must resolve). Severity: MEDIUM — Plan 03 already implements the task; this is the reachability gate. |
| T-43-39 | Repudiation (test passes but milestone archive lacks proof) | Test runs but no artifact records the proof | accept | The test file IS the proof; CI captures pass/fail per-PR. Severity: LOW. |
| T-43-40 | Information Disclosure (test reveals internal pinned strings to attacker) | Pinned strings include implementation-relevant constants | accept | All pinned strings are already public (in docs / discovery). No new disclosure. Severity: LOW. |
</threat_model>

<verification>
- `mix test test/lockspire/release_readiness_contract_test.exs` exits 0
- `mix compile --warnings-as-errors` exits 0
- All grep assertions in Task 1 acceptance_criteria pass
- The new test block's name `phase 43 FAPI 2.0 milestone claims stay truthful and bounded (D-12, D-19, D-20)` shows up in test output
- The Phase 42 precedent block at lines 465-482 is unchanged
</verification>

<success_criteria>
- Truth-in-docs contract test extended with Phase 43 milestone assertions
- All 24 positive doc assertions pass (8 strings × 3 docs)
- The literal word "certified" is refuted in all 3 docs
- All 12 OIDF plan + variant assertions pass (6 strings × 2 artifacts)
- Host template registry assertion passes
- Workflow Mix task reference assertion passes (orphan now resolved)
- v1.10 milestone archive can proceed because all FAPI 2.0 claim language is locked by the contract
</success_criteria>

<output>
After completion, create `.planning/phases/43-end-to-end-fapi-validation/43-07-SUMMARY.md`
</output>
