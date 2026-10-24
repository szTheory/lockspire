---
phase: "171"
slug: "accepted-baseline-finding-qualification"
status: validated
nyquist_compliant: true
wave_0_complete: true
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

Plan 03 task map revised on 2026-10-24 using 171-QUALIFICATION-DECISIONS.md. Plans 01/02 have completed summaries; their rows below preserve the original planned commands, not instructions to rerun acceptance or profile attempts. Plan 03 remains pending. Reuse the original accepted-main receipt and the actual Plan 02 source-host results. Both supplemental wrappers were NOT LAUNCHED and have no live profile receipt. External gates and actual review remain distinct from artifact contracts and normative assertions.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 171-01-01 | 171-01 | 1 | BASE-01, FIND-01 | T-171-01, T-171-02, T-171-03 | Reviewed ownership, exact-main authority and one real HTTP qualification | tracer + artifact contract + external receipt | `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha "$LOCKSPIRE_ACCEPT_SHA" --format json`; `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs:106`; `mix test test/lockspire/qualification_ledger_contract_test.exs` | Existing gate/HTTP test; new contract created by tracer after accepted entry | covered |
| 171-01-02 | 171-01 | 1 | BASE-01, FIND-01 | T-171-01, T-171-02, T-171-03 | Reject incomplete/wrong identity and missing ownership evidence | negative artifact fixtures + existing contract | `mix test test/lockspire/qualification_ledger_contract_test.exs test/lockspire/release/repository_hygiene_contract_test.exs` | New contract from 171-01-01; existing hygiene test | covered |
| 171-02-01 | 171-02 | 2 | BASE-02 | T-171-04, T-171-05, T-171-06 | Immutable inputs, serialized owned resources, original allowlisted receipts | input/runner contract + external observation | `python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only`; `mix test test/lockspire/conformance_immutable_inputs_contract_test.exs test/lockspire/conformance_profile_execution_test.exs test/mix/tasks/lockspire/oidf_conformance_test.exs`; `mix lockspire.oidf_conformance --check` | yes; actual profile observations pending | covered |
| 171-02-02 | 171-02 | 2 | FIND-01 | T-171-05, T-171-07 | Finite attributed cases; equality/empty/order edges; reuse proof | existing HTTP/protocol proof + artifact fixtures | `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs`; `mix test test/lockspire/qualification_ledger_contract_test.exs` | Existing behavior tests; new contract from 171-01-01 | covered |
| 171-03-01 | 171-03 | 3 | FIND-02 | T-171-07, T-171-11, T-171-12 | Valid controls before exact normative HTTP assertions; minimize evidence and separate RED from execution failure | phase-local controlled HTTP probe + counterexample artifact contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs --seed 0`; same runtime prefix with `mix test test/lockspire/qualification_ledger_contract_test.exs` | Probe/allowlisted observation created by this task; existing ledger contract | pending; expected normative RED must be observed, never presumed |
| 171-03-02 | 171-03 | 3 | FIND-02 | T-171-08, T-171-09, T-171-12 | All twelve cases and six downstream IDs get evidence-driven dispositions; actual proof failures block | matrix-to-ledger negative fixtures | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs` | Existing contract; new probe references from 171-03-01 | covered |
| 171-03-03 | 171-03 | 3 | FIND-02 | T-171-08, T-171-09, T-171-10 | Case-driven amendments and identity-bound freeze; reproduced defects remain downstream work | frozen matrix/requirements contract + scoped diff | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs`; `git diff --check -- .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md test/lockspire/qualification_ledger_contract_test.exs` | Existing contract; freeze/amendments pending | covered |
| 171-04-01 | 171-04 | 4 | BASE-02, FIND-02 | T-171-13, T-171-14 | Honest downstream planning states, procedure-scoped current claim and actual delegated dispositions; prior claims and uncertainty preserved | bounded document-state checks + attributed maintainer review | Run the two exact Python standard-library checks in `171-04-PLAN.md` task 04-01: six downstream fields, amended must_haves truth and three dated disposition sections | Existing documents; amended sections not yet written | pending gap closure; no execution or human confirmation claimed |
| 171-04-02 | 171-04 | 4 | BASE-02, FIND-02 | T-171-13, T-171-14 | Reject unlaunched interruption evidence independently of digest drift; refresh only reviewed consumed references and preserve actual observations | one draft negative fixture + existing frozen-ledger contract + reference/receipt/format/diff checks | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs`; exact required-reference/original-receipt Python check, format and scoped diff commands in task 04-02 | Existing contract; targeted regression and reviewed metadata refresh pending | pending gap closure; baseline 21 tests, no new result claimed |

Gap-plan task-map addition (2026-10-24): 171-04 follows completed 171-03 in Wave 4. The two rows are prospective checks only. Existing validated/audit fields and earlier task rows retain their historical meaning. The unchanged ledger still hashes the prior VALIDATION bytes; the executing maintainer must review this task-map addition and the later scoped disposition/audit, refresh only the affected manifest entries under 171-04-02, then rerun the focused contract before re-verification. Neither optional wrapper, main acceptance authority nor controlled HTTP probe is scheduled by this map.

Every runnable plan command has an immediately following observable `<fails_when>`. Measure focused command duration during execution; split by existing file/test name if a quick-feedback command exceeds 60 seconds. Exact-main acceptance and external profile runs are deliberately external/long-running proof, not quick feedback. Existing profile commands remain `LOCKSPIRE_OIDF_EPHEMERAL_DB=true bash scripts/conformance/run_ephemeral_oidf_profile.sh phase37` and the corresponding `fapi2` invocation with new owned output directories; their results never satisfy selected protocol assertions by coarse status.

Plan 03 probe semantics: two explicitly invoked tests outside default test_paths demand the required A171-003 and P171-005 outcomes. The inspection-based prediction is two final normative assertion failures after all valid controls succeed. Record actual test/failure counts, exit and each exact mismatch; a nonzero result is neither swallowed nor called a passing protocol test. A compile/setup/control failure or skipped case is an unavailable required proof and blocks freeze. A completed controlled counterexample qualifies downstream correction and does not block qualification merely because the product is still wrong. A real required-outcome pass removes that correction premise. The green ledger contract checks evidence integrity only. No new default failing test, product change, dependency or second framework is selected.

Spec-less fallback accounting: BASE-02 idempotency/concurrency and FIND-01 equality/empty/ordering have explicit truths and negative-fixture acceptance in 171-02. BASE-01 and FIND-02 remain unresolved/unclassified flagged assumptions. Three descriptor-less prohibitions across 171-01/171-03 remain flagged-unverified, with no invented wired checks. None is silently dismissed or counted as passing.

## Wave 0 Requirements

Plan 03 current entry: the original baseline receipt already exists and is reused unchanged; do not repeat the acceptance command listed for completed Plan 01. Confirm the available Elixir 1.19.5/OTP 28 and owned disposable test database from Plan 02. The new two-case probe and allowlisted observation are created before the matrix consumes them. Python-wrapper preparation below remains a supplemental handoff with its recorded owner; it does not prevent selected local HTTP qualification. The original checkboxes below retain historical planning meaning and are not new execution claims.

- [x] Phase 171 executing maintainer: activate available Elixir 1.19.5/OTP 28 before ExUnit/`mix ci`, or select the existing pinned CI environment; research observed an unselected shim, not proof that installation is absent. Before the sole exact-main invocation, derive/export LOCKSPIRE_ACCEPT_SHA from freshly refreshed origin/main, validate 40 lowercase hex and require equality with HEAD/local main/refreshed origin/main; no historical fallback.
- [x] Phase 171 executing maintainer: select the existing CPython 3.13.15/pip 26.2.1 runner environment and verify the complete runner-requirements.lock closure, including httpx 0.28.1/pyparsing 3.3.2. Missing dependencies remain unavailable with a concrete isolated-environment preparation handoff using the existing install_runner_dependencies.sh after applicable package-legitimacy review, or the existing prepared CI environment. Retry --check and the same locked profile only after preparation; readiness is not a protocol pass.
- [x] Define a finite ledger/matrix contract and its smallest meaningful consistency check. No new framework or duplicate behavioral tests.
- [x] Obtain fresh reviewed delivery/worktree ownership reconciliation and exact-main receipt during execution; planning artifacts are not acceptance receipts.

## Manual or External Verifications

| Behavior | Requirement | Why outside quick unit checks | Verification |
|---|---|---|---|
| Reviewed prior-delivery disposition and unknown work ownership | BASE-01 | Human review/ownership cannot be inferred from a clean tree | Retain actual review disposition, exact identities and unresolved owners; block on unknown required decisions |
| Fresh synchronized main plus matching canonical CI/Release no-publish | BASE-01 | Requires live repository/hosted evidence and full contributor checks | Existing `bash scripts/maintainer/repo_hygiene_check.sh --accept-sha <current-main-sha> --format json`; preserve the actual receipt and exit status |
| Selected external profile observations | BASE-02, FIND-01 | Docker/network/provider setup and historical raw assertions may be unavailable | Existing pinned `phase37`/`fapi2` wrappers after acceptance; retain redacted classifications and distinct identities; no infrastructure-as-pass |
| Newly discovered security/API/support choice | FIND-02 | New scope or policy exceeds routine qualification | Record explicit blocker and resolve before dependent planning; replan invalidated slices |

## Validation Sign-Off

- [x] Final task map names every task and verification command.
- [x] All tasks have automated verification or explicit Wave 0 dependencies.
- [x] No three consecutive tasks lack automated feedback; no watch flags.
- [x] All missing references are produced before consumption.
- [x] Exact-main and selected protocol evidence are current, source-bound and independently satisfied.
- [x] Measured focused feedback latency recorded; no invented timing or passing execution result.
- [x] `nyquist_compliant: true` set only after execution/audit proves it.

**Audit:** Codex executing maintainer, 2026-10-24; automated qualification coverage validated. This is not a human protocol or certification approval.

## Execution audit evidence

All four Phase 171 requirements are covered by the committed receipt/ledger checks and seven task verification records. The fresh final ledger contract ran after the last implementation change: 19 tests, 0 failures in 7.4 seconds. Plans 01/02 retain their measured named HTTP result (1 test), source-host tests (44), discovery tests (7), runner contracts (17) and ledger fixtures. No unchanged broad suite was repeated for metadata.

The explicitly invoked final probe produced 2 tests, 2 named normative assertion failures, Mix exit 2, with all positive controls passing. That is successful counterexample qualification for FIND-02, not green behavior for A171-003/P171-005. Current correction ownership is Phase 172/173. The default test suite does not discover the phase-local probe.

The required runtime, baseline receipt, ownership reconciliation and ledger contract are satisfied. The checked Python setup row means its availability and exact owner/action were assessed; CPython 3.13.15/pip 26.2.1 and the locked closure remain unavailable. Neither supplemental profile launched, neither has an invented receipt, and retry preparation remains optional with the recorded executing-maintainer owner. No missing selected-case test or new behavioral test was identified by this audit. Normative interpretation and historical unavailable assertions remain explicitly attributed judgments/boundaries, not fabricated human confirmations.

## Validation Audit 2026-10-24

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Post-review validation (2026-10-24)

At correction commit `9d774872`, the nested-type regression is covered and the contract passes **20 tests, 0 failures**; formatting passes for both changed ExUnit files and full `mix credo --strict` exits 0 with no issues. The earlier 19-test audit above remains its dated prior observation. No additional broad suite was repeated.

The tightened consent-origin probe ran at source `30e385a33bb2a7f67d94c558dedf7691ecde5863`: exit 2, 2 tests, 2 named normative assertion failures, 0 skipped, with valid-path and off-origin/network-path/lookalike controls passing. Its new dated observation is canonical; the original observation bytes and source/probe identities remain in the dated archive and ledger history. The two protocol failures still belong to downstream correction work. All four review findings have concrete fixes and await independent re-review; no human confirmation is asserted.

## Final guard audit (2026-10-24)

WR-05 at `688d0712` closes the remaining requirement-ID shape hole with a failing-before/passing-after fixture. The final focused contract passes **21 tests, 0 failures** and full Credo remains clean. Probe bytes and normative evidence are unchanged, so no duplicate external/main/probe run was made. Earlier 19/20-test records above retain their original dated meaning. The iteration-2 fix report contains the exact final verification.
