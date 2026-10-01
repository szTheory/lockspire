---
phase: "140"
slug: bounded-operational-loose-end-triage
status: audited-partial
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-28"
audited: "2026-10-01"
---

# Phase 140 — Validation Strategy

> Current status (2026-10-01): all 14 local plans are complete. The Plan 140-14 candidate a68ab1bb74aa0b8dbed30f46fd632d42731a54c5 passed complete local CI, and the unchanged post-merge candidate passed all 60 hygiene tests. CI-06/CI-07 remain pending final exact-SHA acceptance. The 2026-09-30 tables below are retained as historical failed-run evidence; the current delta at the end supersedes their local-failure status.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | ExUnit via Mix; Node `node:test`; repository-local Bash, Git, and GitHub CLI checks |
| **Config files** | `mix.exs`; `.github/workflows/ci.yml`; finalizer contracts under `tools/gsd-capabilities/lockspire-phase-finalizer/` |
| **Quick run command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release_ci_evidence_contract_test.exs test/lockspire/workflow_supply_chain_contract_test.exs` |
| **Full suite command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix ci` |
| **Estimated runtime** | Allow about 30 minutes for a clean isolated full run on this host; focused ExUnit/Node checks should complete much sooner. |

---

## Sampling Rate

- **After every task commit:** Run the nearest affected ExUnit or Node contract; use the quick command when repository evidence or CI contracts change.
- **After every plan wave:** Run focused checks for the files actually changed. Reserve the roughly 30-minute full `mix ci` for the final candidate after selected repairs; rerun only if a material source change or failed gate requires it.
- **During `$gsd-verify-work`:** After all Phase 140 plan/SUMMARY writes, require the final synchronized `main` SHA, full local CI for that candidate, and exact-SHA hygiene/CI/Release evidence. Do not transfer the entry receipt or a pre-summary acceptance result to a later SHA.
- **Max feedback latency:** 30 minutes for the clean full acceptance path; under 30 seconds for focused contracts where noted.

---

## Historical Per-Requirement Verification Map (2026-09-30)

| Requirement | Plan / Task | Threat Ref | Secure Behavior | Test Type | Automated Command / Evidence | Existing Coverage | Status |
|-------------|-------------|------------|-----------------|-----------|------------------------------|-------------------|--------|
| CI-06 | 140-04-T2; post-summary verifier | T-140-11 | Required repository checks are bound to one synchronized final SHA. | External integration | Focused exact-SHA hygiene contract passed (2 tests); required final evidence is exact hygiene receipt plus canonical CI run/job identity for final synchronized `main`. | Entry-only receipt covers SHA `c6332d3a8b716b938f93d978243281764e3ac41` (as recorded in acceptance); no post-summary final-SHA receipt. Local `mix ci` failed and cannot satisfy this requirement. | PENDING external gate |
| CI-07 | 140-04-T2; post-summary verifier | T-140-11, T-140-12 | Release evidence is same-SHA and intentionally no-publish; protected publication ownership remains unchanged. | External integration | Release-evidence contract passed (3 tests); required final evidence is same-SHA Release workflow with successful intentional no-publish job graph plus exact hygiene receipt. | Phase 139 entry receipt is for an older SHA; no Phase 140 final-SHA Release run/job evidence. | PENDING external gate |
| BASE-03 | 140-01-T1/T2, 140-04-T1 | T-140-01, T-140-03 | Actions name exact targets and preserve uncommitted work, intentional refs, and historical evidence. | Contract + action review | Focused relation selector: 2 tests, 0 failures. Full `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release/repository_hygiene_contract_test.exs`: 58 tests, 2 failures. | Inventory/disposition keep actions proposal-only and defer incomplete source domains; the two recovery-diagnostic assertions fail against phase-139 sealed-candidate output. No action authority or cleanup is claimed. | WARNING — proposal safety evidenced; full contract unresolved |
| TRIAGE-03 | 140-03-T1/T2 | T-140-07 | Each dependency PR has an independent compatibility, security, and required-gate assessment. | External integration + manual review | Six exact `gh pr view` metadata/diff/check queries and official-source review recorded in 140-03-SUMMARY.md and DISPOSITIONS; `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/workflow_supply_chain_contract_test.exs`: 5 tests, 0 failures. | All six dependency candidates separately assessed; failed, missing, stale, and undocumented-check evidence remains explicit defer triggers. External PR/check data is time-bounded (2026-09-30 02:34–02:43 UTC), not merge authorization. | WARNING — recorded evidence complete to available sources; refresh before action |
| LOOSE-02 | 140-01-T1/T2, 140-02-T1, 140-03-T1/T2, 140-04-T1 | T-140-01, T-140-10 | Every credible finding has exactly one supported disposition and traceable source evidence. | Artifact consistency | Candidate table audit recorded: 109 unique rows with allowed outcomes and nonempty trigger/retention; `git diff --check` passed on plan edits. Full hygiene contract: 58 tests, 2 failures. | Phase 139 source-pair correction and disposition evidence recorded; four unnamed historical Phase32/AuditWriter IDs were not invented. Full hygiene contract failure prevents a blanket green claim. | WARNING — artifact audit recorded; recovery contract failures open |
| LOOSE-03 | 140-02-T1/T2, 140-04-T1 | T-140-04, T-140-05 | Current blockers and bounded regressions receive focused proof; speculative or feature-sized work stays deferred. | Focused contract + final full suite | Archived-candidate focused run: 18 tests, 4 failures (two current Phase32 and two AuditWriter `:invalid_signing_key` failures). Planning/readiness contracts rerun: 4 tests, 0 failures. Final `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix ci`: 1439 tests, 44 failures, 6 skipped (286 excluded), exit 1. | Four current selector failures remain explicitly unresolved; full CI failure has additional representative failures recorded in 140-04-SUMMARY.md. No implementation repair was in scope. | BLOCKER — escalate bounded fixture failures and failed full suite |

Task IDs are fixed above. The final external exact-SHA gate occurs after plan summaries so it measures the resulting SHA, not a pre-summary candidate.

---

## Wave 0 Requirements

- No test framework or shared fixture gap is demonstrated. Reuse existing ExUnit, Node, Bash, Git, and GitHub evidence controls.
- The planner must identify any small deterministic disposition-record check only if the refreshed evidence demonstrates a repeatable repository-owned gap.
- Local Mix requires explicit Elixir/OTP selection in this environment; verification commands must retain the working `ASDF_ELIXIR_VERSION`, `ASDF_ERLANG_VERSION`, and scheduler settings shown above.

## Historical Multi-Source Coverage Audit (2026-09-30)

| Source | ID / item | Plan-task coverage | Status |
|--------|-----------|--------------------|--------|
| GOAL | Maintainers close only safe, evidence-backed maintenance gaps and retain a clear, recoverable disposition for everything else. | 140-01-T1/T2, 140-02-T1/T2, 140-03-T1/T2, 140-04-T1/T2 | COVERED |
| REQ | CI-06 | 140-04-T2 and post-summary exact-SHA verifier gate | PENDING external gate |
| REQ | CI-07 | 140-04-T2 and post-summary Release no-publish verifier gate | PENDING external gate |
| REQ | BASE-03 | 140-01-T1/T2, 140-04-T1 exact-target/authority contract | PARTIAL — focused relation test passes; full hygiene contract has 2 failures |
| REQ | TRIAGE-03 | 140-03-T1/T2 individual PR review | WARNING — six assessed; mutable checks and some source diagnostics need refresh/proof |
| REQ | LOOSE-02 | 140-01-T1/T2, 140-02-T1, 140-03-T1/T2, 140-04-T1 single disposition record | PARTIAL — record audit passed; full hygiene contract has 2 failures |
| REQ | LOOSE-03 | 140-02-T1/T2, 140-04-T1 bounded repair/deferral proof | BLOCKER — four focused current failures and failed full suite |
| RESEARCH | Existing collector/relation, immutable Phase 138 ledger, `refresh_required` | 140-01-T1 | COVERED |
| RESEARCH | Nine archived UAT candidate records, the v1.27 grouped failures, and v1.32 broad-suite caveats | 140-02-T1 | COVERED |
| RESEARCH | Phase 139 count/current-state contradiction | 140-02-T2 | COVERED |
| RESEARCH | Six stale dependency PRs and package-specific upstream evidence | 140-03-T1/T2 | COVERED |
| RESEARCH | Final same-SHA hygiene/CI/Release, WARN and no-publish path | 140-04-T2 | COVERED |
| RESEARCH | No new runtime/package/maintenance framework; protected overlays | 140-01-T1/T2, 140-04-T1 | COVERED |
| CONTEXT | D-01, D-02, D-03 | 140-01-T1/T2, 140-04-T1 | COVERED |
| CONTEXT | D-04, D-05, D-06 | 140-01-T1/T2, 140-04-T1 | COVERED |
| CONTEXT | D-07 | 140-02-T1 | COVERED |
| CONTEXT | D-08, D-09, D-10 | 140-02-T2, 140-04-T1 | COVERED |
| CONTEXT | D-11 | 140-03-T1/T2 | COVERED |
| CONTEXT | D-12 | 140-02-T1/T2, 140-03-T1/T2, 140-04-T1/T2 | COVERED |
| CONTEXT | D-13, D-14 | 140-04-T2 | COVERED |

Deferred ideas and Phase 141's final milestone-baseline handoff are excluded from this Phase 140 audit by their source scope. Final CI-06/CI-07 status remains pending until the post-summary external gate runs on the resulting synchronized SHA.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Approve any concrete delete, merge, close, cleanup, or publication action. | BASE-03 | Phase context fixes the decision framework but does not authorize a particular destructive or externally visible target. | Re-query the exact target, its current state, authorization, recovery path, worktree safety, and historical-evidence impact immediately before action. If authority or proof is missing, record a deferred disposition with a concrete trigger. |
| Assess package-specific compatibility and security evidence for each dependency PR. | TRIAGE-03 | Upstream release/advisory evidence and host compatibility require a separate judgment for each package/version; another PR’s checks cannot substitute. | Review the exact proposed version and target SHA against official package documentation/release notes, applicable advisories, and that PR’s refreshed required checks; record the sources and rationale per PR. |

---

## Audit Trail (2026-09-30)

This audit used the four plan/SUMMARY pairs, this map, `140-DISPOSITIONS.md`, and `140-ACCEPTANCE.md`. It does not overwrite `140-VERIFICATION.md` and adds no test files: the candidate-level record check is an artifact review, while the real uncovered behavior discovered by execution is already covered by existing failing selectors and must be escalated to implementation owners.

| Evidence | Observed result | Audit treatment |
|----------|-----------------|-----------------|
| Plan 140-01 focused relation command | 2 tests, 0 failures (56 excluded); protected-file hashes and artifact checks reported passing. | Record as a focused pass only. Origin refresh failed (exit 255), and `140-HANDOFF.md` was ambiguous, so affected evidence stays deferred. |
| Plan 140-02 archived candidate selectors | 18 tests, 4 failures; Phase81 cases passed, two Phase32 and two AuditWriter cases failed with invalid signing keys. | LOOSE-03 remains open; four historical identities remain unnamed. |
| Plan 140-02 readiness/planning contracts | Initial 4 tests, 1 failure from stale temporary STATE assertions; after the contract was adjusted, rerun was 4 tests, 0 failures. | Current rerun is green; earlier failure and adjustment remain in the summary. |
| Plan 140-03 supply-chain contract and GitHub/upstream review | 5 tests, 0 failures; six dependency PRs independently assessed; missing/failed/stale evidence recorded per PR. | Warning-level evidence: assessment is time-bounded and some upstream/check diagnostics remain unavailable; no PR action is authorized. |
| Plan 140-04 repository hygiene contract | 58 tests, 2 failures (exit 2); both failures are Phase 140 recovery diagnostic expectations receiving `relation_boundary|phase-139-sealed-candidate|refresh_required`. | Not covered-passing. Escalate the two contract mismatches; do not weaken assertions in this audit. |
| Plan 140-04 focused exact-SHA / Release evidence contracts | 2 tests, 0 failures; Release evidence contract 3 tests, 0 failures; acceptance diff check passed. | Contract behavior only; it does not create external final-SHA evidence. |
| Plan 140-04 final local `mix ci` | 1439 tests, 44 failures, 6 skipped (286 excluded), exit 1; preceding build/lint/security/docs/package/migration gates passed as documented. | Failed suite, not covered-passing. Output was truncated; listed causes are representative only. `.git/FETCH_HEAD` permission error is not accepted as fetch proof. |
| CI-06/CI-07 post-summary external acceptance | No final synchronized SHA receipt or same-SHA canonical CI/Release job graph recorded. | Both remain pending external gates. The Phase 139 entry receipt is older and cannot substitute. |

Overall audit outcome: **PARTIAL**. No implementation files were changed. The existing validation contract is reusable; no new deterministic test boundary was identified beyond the already failing selectors/contracts.

## Historical Validation Sign-Off (2026-09-30)

- [ ] Every generated task has an exact `<automated>` verify command or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks lack automated verification.
- [ ] Wave 0 covers every confirmed missing test reference.
- [ ] No watch-mode flags.
- [ ] Focused feedback commands stay under 30 seconds where stated; the full gate has its explicit 30-minute budget.
- [ ] `nyquist_compliant: true` remains false until the escalated hygiene/LOOSE-03 failures are resolved and post-summary external CI-06/CI-07 evidence is available.

**Audit status:** partial; blocker failures and external gates remain open.

## Current Validation Delta (2026-10-01)

The earlier tables predate completed Plans 140-05 through 140-13. Their source/selector, recovery, signing-key, formatter, isolation, and full-CI findings are closed by bounded fixes. The previously failed `8fadb098` candidate remains historical evidence. Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87` passed complete `mix ci`: 1,441 unit tests, 0 failures, 6 skipped; 102 integration tests, 0 failures. Its private complete log is `/private/tmp/lockspire-140-13-ci.oVxPXP`. The umask-controlled legacy/current probe establishes a sufficient cause for both original receipt identity errors without claiming the old run measured that umask.

The primary checkout stayed at `8061247594fb563d79e3b7d62f1d21b6789ede9f` across post-merge compile and the full hygiene replay: 60 tests, 0 failures, seed 924694. Source diff from the complete-CI candidate is empty. The prior standalone sealed-relation failure is WR-01, deferred with a trigger to reopen on recurrence; its cause is unknown and it is not marked fixed. Plan 140-04's local audit and focused 2-test/3-test acceptance contracts passed. All 114 current IDs are accounted for and all four protected file hashes match.

| Current requirement or check | Owning plan | Automated proof required | Status |
|------------------------------|-------------|--------------------------|--------|
| LOOSE-03 receipt identity blocker | 140-13-T1/T2 | Exact original selectors, discriminating mismatch regression, and actual complete local `mix ci` including integration | PASS — causal regression and complete CI recorded |
| CI-06 local prerequisite | 140-13-T2 | Current complete local `mix ci`, zero unit and integration failures, exact candidate SHA | PASS locally at 0227dea2; final-SHA requirement remains pending |
| LOOSE-02 and finite dispositions | 140-04-T1, 140-09 | Source-linked rows and terminal evidence for any executed closure | PASS — Plan 140-04 local closeout complete, 114 current IDs and protected hashes verified |
| CI-06/CI-07 final acceptance | 140-04-T2 and unfiltered verifier | Same final synchronized main SHA, local `mix ci`, exact hygiene, required canonical CI jobs, and successful Release no-publish graph | PENDING; no final-SHA receipt |
| Phase 139 host receipt recovery | Post-write orchestrator handoff under `140-ACCEPTANCE.md` | Supported supersession CAS, archived old bytes, lineage/hook/remote/worktree checks, then no-publish barrier result | BLOCKED at current `plan:pre`; no live receipt mutation in 140-13 |

Both new tasks have runnable `<automated>` checks and explicit `<fails_when>` signals. The full gate is intentionally long-running; its result must be captured once after the source repair, and a new run is justified only by a subsequent change or a concrete failed check. The Phase 140 `140-VERIFICATION.md` file remains the canonical report until unfiltered verification updates it. `nyquist_compliant: true` remains unavailable until the final exact-SHA acceptance is proven; all current local repair checks pass.

## Execution Tail Evidence

- Wave-post schema drift: no drift and no block. Codebase drift: skipped because no STRUCTURE.md exists, no action required. UI safety: no frontend/UI files and no block.
- Execute-post Phase 139 predicate on Phase 140: inert command success, no finalizer action. This does not override the separately failed plan-entry receipt gate.
- Regression evidence reuse: all nine unique prior-phase test paths cited by Phase 138/139 verification are under `test/lockspire` and included in the passing complete `mix ci` command. The changed receipt suite additionally passed its full post-merge replay. No implementation changed after the complete-CI candidate. Repeating the complete suite before another material change would add no new local source evidence.
- Final local CI on the eventual synchronized acceptance SHA remains required by `140-ACCEPTANCE.md`; the earlier local run is preparatory proof only.

## Current Recovery and Acceptance Delta (2026-10-01, after live CAS)

All 13 previously completed local plans remain closed. The supported CAS archived the former pending receipt byte-identically at SHA-256 `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d` and wrote a current recovery-v2 pending receipt with SHA-256 `59df9121aa8680f29c856a78f51608b34e8d84d4497ad63e4b092a019728093c`, naming HEAD `5259a6545c04277ee44038779b23b139b6b1fcb2`. The actual no-publish `post-transition 139` entry point exited 1 at `relation_boundary|phase-139-sealed-candidate|refresh_required` before its explicit authorization barrier. Before/after HEAD, refs, worktree and pending-receipt digest matched. This is a failed gate, not Phase 140 acceptance. Source evidence: `/private/tmp/lockspire-140-plan/live-recovery-diagnosis.md`, `live-no-publish-probe-result.json`, and the private probe log named there.

Read-only production-function diagnosis showed that `validate_phase_140_recovery_chain` accepts the seven planning-prefix commits from accepted Phase 139 SHA `c6332d3a8b716b938f93d978243281764e3eac41` through `5ad2b2e935556c8f1a91be32605958530b477527`, first rejects execution commit `d9ed1899bed11f80891475fd11bce07da6ac4892`, and requires single-parent history while completed Phase 140 contains executor merges. The earlier Plan 140-06 Node fixture authenticated resolver behavior and hostile receipts but did not traverse the full production entry point. The live probe now proves that the current completed-phase history does not pass the old planning-entry route; it does not identify a before-file identity defect or justify expanding the entry classifier. WR-01's earlier standalone Phase 139 relation failure remains cause-unknown and deferred on exact recurrence, separately from this demonstrated stage mismatch.

Plan `140-14-PLAN.md` (Wave 14, dependencies 04/06/09/13) now has three bounded tasks. Its tracer extends the existing ExUnit fixture in `package_assertions.ex` and `repository_hygiene_contract_test.exs`, which already constructs the complete accepted Phase 139 relation and seven recognized Phase 140 planning-prefix commits. It must create a fully shaped fixture-local durable accepted receipt, use supported CAS to obtain recovery-v2, run the real finalizer without a publish argument to the exact no-publish diagnostic, then tamper archived lineage and prove specific earlier rejection. Before/after fixture refs, pending/archive bytes, worktree and publication state must match; all fixture Git and receipt writes stay under its temporary repository and bare origin. The primary live checkout is audited read-only by the second task; the third records the historical-entry versus completed-phase final-acceptance distinction in `140-ACCEPTANCE.md`. A resolver-only or static barrier check cannot close the behavioral gap. No additional Phase 139 classifier subjects, arbitrary merge allowance, new framework or live receipt rewrite is planned.

The repository's existing `repo_hygiene_check.sh --accept-sha` and the 140-ACCEPTANCE.md steps 1–6 remain the final control. After the plan SUMMARY and all lifecycle/verifier writes, a new exact candidate packet must be prepared. Any required local-main movement or push requires separate blocking-human authorization for that full SHA and freshly observed remote OID; earlier `8fadb098` approval does not transfer. CI-06/CI-07 remain pending until the final synchronized SHA has current local `mix ci`, exact hygiene with every WARN disposition and zero BLOCK, canonical required CI, and the successful intentional Release no-publish job graph. The previous 0227dea2 complete local CI and 80612475 hygiene replay remain valid preparatory evidence; T1's test-source change is material and requires one new complete local `mix ci` before final handoff, followed by the final-SHA run required by acceptance.


## Plan 140-14 Validation Delta (2026-10-01)

Plan 140-14 closes the missing real-entrypoint behavior proof. Its tagged ExUnit selector passed (1 test, 0 failures, seed 355859): an authentic fixture-local accepted Phase 139 receipt and recovery-v2 candidate traversed the production sealed-relation and planning-consistency path to the exact no-publish authorization barrier. Tampered archived predecessor bytes failed earlier at superseded receipt archive digest. The test asserted unchanged fixture HEAD, refs, worktree, pending/archive bytes, and publication-call state. The focused mode-0600 log is /private/tmp/lockspire-140-plan/phase140-entrypoint-recovery.bSVnM5.

The fresh full mix ci at candidate a68ab1bb74aa0b8dbed30f46fd632d42731a54c5 passed: 1,441 unit tests, 0 failures, 6 skipped (286 excluded), and 102 integration tests, 0 failures (33 excluded). The complete private mode-0600 log is /private/tmp/lockspire-140-plan/phase140-14-mix-ci.g5QHGn. Its MixAudit step could not read .git/FETCH_HEAD in the sandbox; the supported advisory-only mix deps.audit was then rerun with repository Elixir/OTP and escalation, refreshed the advisory cache, and exited 0 with no vulnerabilities. mix.lock and project source status were unchanged. The original CI log retains that refresh limitation.

Independent deep code review of the two changed test source files found no findings; see 140-14-REVIEW.md. The valid historical planning-prefix path does not change the prior live post-transition 139 failure at 5259a654, which remains exit 1 before the no-publish barrier due to the strict classifier historical stage scope. The previous successful CAS and current pending/archive digests remain immutable. CI-06 and CI-07 stay pending the post-summary synchronized-main exact-SHA hygiene, required CI and Release no-publish receipts.
