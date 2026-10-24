---
phase: "171"
slug: "accepted-baseline-finding-qualification"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-24"
---

# Phase 171 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit/Mix and Python standard-library conformance helpers |
| Config file | `config/test.exs`, `mix.exs` |
| Quick run | `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only` |
| Focused suite | `mix test test/lockspire/release/repository_hygiene_contract_test.exs test/lockspire/conformance_immutable_inputs_contract_test.exs test/lockspire/conformance_profile_execution_test.exs test/mix/tasks/lockspire/oidf_conformance_test.exs` |
| Full contributor gate | `mix ci`, invoked by the existing exact-main acceptance gate |
| Runtime estimate | Unmeasured here; time focused commands during execution; full contributor and hosted gates are deliberately separate from quick feedback |

## Sampling Rate

- After each artifact change, run its focused consistency/contract check. Reuse existing tests; add a small check only for a material uncovered invariant.
- After each wave, run the focused suite relevant to that wave. No three consecutive tasks may lack automated feedback.
- Run complete required local/canonical hosted checks at baseline/candidate acceptance, not after each ledger edit.
- External profiles remain supplemental and non-certifying. A setup failure or unavailable historical assertion never supplies protocol acceptance.

## Per-Task Verification Map

Plan 03 task map revised on 2026-10-24 using 171-QUALIFICATION-REPLAN.md. Plans 01/02 have completed summaries; their rows below preserve the original planned commands, not instructions to rerun acceptance or profile attempts. Plan 03 remains pending. Reuse the original accepted-main receipt and the actual Plan 02 source-host results. Both supplemental wrappers were NOT LAUNCHED and have no live profile receipt. External gates and actual review remain distinct from artifact contracts and normative assertions.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 171-01-01 | 171-01 | 1 | BASE-01, FIND-01 | T-171-01, T-171-02, T-171-03 | Reviewed ownership, exact-main authority and one real HTTP qualification | tracer + artifact contract + external receipt | `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha "$LOCKSPIRE_ACCEPT_SHA" --format json`; `mix test test/integration/phase37_protocol_strictness_e2e_test.exs:106`; `mix test test/lockspire/qualification_ledger_contract_test.exs` | Existing gate/HTTP test; new contract created by tracer after accepted entry | pending |
| 171-01-02 | 171-01 | 1 | BASE-01, FIND-01 | T-171-01, T-171-02, T-171-03 | Reject incomplete/wrong identity and missing ownership evidence | negative artifact fixtures + existing contract | `mix test test/lockspire/qualification_ledger_contract_test.exs test/lockspire/release/repository_hygiene_contract_test.exs` | New contract from 171-01-01; existing hygiene test | pending |
| 171-02-01 | 171-02 | 2 | BASE-02 | T-171-04, T-171-05, T-171-06 | Immutable inputs, serialized owned resources, original allowlisted receipts | input/runner contract + external observation | `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only`; `mix test test/lockspire/conformance_immutable_inputs_contract_test.exs test/lockspire/conformance_profile_execution_test.exs test/mix/tasks/lockspire/oidf_conformance_test.exs`; `mix lockspire.oidf_conformance --check` | yes; actual profile observations pending | pending |
| 171-02-02 | 171-02 | 2 | FIND-01 | T-171-05, T-171-07 | Finite attributed cases; equality/empty/order edges; reuse proof | existing HTTP/protocol proof + artifact fixtures | `mix test test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs`; `mix test test/lockspire/qualification_ledger_contract_test.exs` | Existing behavior tests; new contract from 171-01-01 | pending |
| 171-03-01 | 171-03 | 3 | FIND-02 | T-171-07, T-171-11, T-171-12 | Valid controls before exact normative HTTP assertions; minimize evidence and separate RED from execution failure | phase-local controlled HTTP probe + counterexample artifact contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs --seed 0`; same runtime prefix with `mix test test/lockspire/qualification_ledger_contract_test.exs` | Probe/allowlisted observation created by this task; existing ledger contract | pending; expected normative RED must be observed, never presumed |
| 171-03-02 | 171-03 | 3 | FIND-02 | T-171-08, T-171-09, T-171-12 | All twelve cases and six downstream IDs get evidence-driven dispositions; actual proof failures block | matrix-to-ledger negative fixtures | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs` | Existing contract; new probe references from 171-03-01 | pending |
| 171-03-03 | 171-03 | 3 | FIND-02 | T-171-08, T-171-09, T-171-10 | Case-driven amendments and identity-bound freeze; reproduced defects remain downstream work | frozen matrix/requirements contract + scoped diff | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs`; `git diff --check -- .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md test/lockspire/qualification_ledger_contract_test.exs` | Existing contract; freeze/amendments pending | pending |

Every runnable plan command has an immediately following observable `<fails_when>`. Measure focused command duration during execution; split by existing file/test name if a quick-feedback command exceeds 60 seconds. Exact-main acceptance and external profile runs are deliberately external/long-running proof, not quick feedback. Existing profile commands remain `LOCKSPIRE_OIDF_EPHEMERAL_DB=true bash scripts/conformance/run_ephemeral_oidf_profile.sh phase37` and the corresponding `fapi2` invocation with new owned output directories; their results never satisfy selected protocol assertions by coarse status.

Plan 03 probe semantics: two explicitly invoked tests outside default test_paths demand the required A171-003 and P171-005 outcomes. The inspection-based prediction is two final normative assertion failures after all valid controls succeed. Record actual test/failure counts, exit and each exact mismatch; a nonzero result is neither swallowed nor called a passing protocol test. A compile/setup/control failure or skipped case is an unavailable required proof and blocks freeze. A completed controlled counterexample qualifies downstream correction and does not block qualification merely because the product is still wrong. A real required-outcome pass removes that correction premise. The green ledger contract checks evidence integrity only. No new default failing test, product change, dependency or second framework is selected.

Spec-less fallback accounting: BASE-02 idempotency/concurrency and FIND-01 equality/empty/ordering have explicit truths and negative-fixture acceptance in 171-02. BASE-01 and FIND-02 remain unresolved/unclassified flagged assumptions. Three descriptor-less prohibitions across 171-01/171-03 remain flagged-unverified, with no invented wired checks. None is silently dismissed or counted as passing.

## Wave 0 Requirements

Plan 03 current entry: the original baseline receipt already exists and is reused unchanged; do not repeat the acceptance command listed for completed Plan 01. Confirm the available Elixir 1.19.5/OTP 28 and owned disposable test database from Plan 02. The new two-case probe and allowlisted observation are created before the matrix consumes them. Python-wrapper preparation below remains a supplemental handoff with its recorded owner; it does not prevent selected local HTTP qualification. The original checkboxes below retain historical planning meaning and are not new execution claims.

- [ ] Phase 171 executing maintainer: activate available Elixir 1.19.5/OTP 28 before ExUnit/`mix ci`, or select the existing pinned CI environment; research observed an unselected shim, not proof that installation is absent. Before the sole exact-main invocation, derive/export LOCKSPIRE_ACCEPT_SHA from freshly refreshed origin/main, validate 40 lowercase hex and require equality with HEAD/local main/refreshed origin/main; no historical fallback.
- [ ] Phase 171 executing maintainer: select the existing CPython 3.13.15/pip 26.2.1 runner environment and verify the complete runner-requirements.lock closure, including httpx 0.28.1/pyparsing 3.3.2. Missing dependencies remain unavailable with a concrete isolated-environment preparation handoff using the existing install_runner_dependencies.sh after applicable package-legitimacy review, or the existing prepared CI environment. Retry --check and the same locked profile only after preparation; readiness is not a protocol pass.
- [ ] Define a finite ledger/matrix contract and its smallest meaningful consistency check. No new framework or duplicate behavioral tests.
- [ ] Obtain fresh reviewed delivery/worktree ownership reconciliation and exact-main receipt during execution; planning artifacts are not acceptance receipts.

## Manual or External Verifications

| Behavior | Requirement | Why outside quick unit checks | Verification |
|---|---|---|---|
| Reviewed prior-delivery disposition and unknown work ownership | BASE-01 | Human review/ownership cannot be inferred from a clean tree | Retain actual review disposition, exact identities and unresolved owners; block on unknown required decisions |
| Fresh synchronized main plus matching canonical CI/Release no-publish | BASE-01 | Requires live repository/hosted evidence and full contributor checks | Existing `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha <current-main-sha> --format json`; preserve the actual receipt and exit status |
| Selected external profile observations | BASE-02, FIND-01 | Docker/network/provider setup and historical raw assertions may be unavailable | Existing pinned `phase37`/`fapi2` wrappers after acceptance; retain redacted classifications and distinct identities; no infrastructure-as-pass |
| Newly discovered security/API/support choice | FIND-02 | New scope or policy exceeds routine qualification | Record explicit blocker and resolve before dependent planning; replan invalidated slices |

## Validation Sign-Off

- [ ] Final task map names every task and verification command.
- [ ] All tasks have automated verification or explicit Wave 0 dependencies.
- [ ] No three consecutive tasks lack automated feedback; no watch flags.
- [ ] All missing references are produced before consumption.
- [ ] Exact-main and selected protocol evidence are current, source-bound and independently satisfied.
- [ ] Measured focused feedback latency recorded; no invented timing or passing execution result.
- [ ] `nyquist_compliant: true` set only after execution/audit proves it.

**Approval:** pending execution; planning only.
