---
phase: "140"
slug: bounded-operational-loose-end-triage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-28"
---

# Phase 140 — Validation Strategy

> Draft validation contract for bounded evidence refresh, disposition, dependency assessment, and exact-SHA acceptance.

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

## Per-Requirement Verification Map

| Requirement | Plan / Task | Threat Ref | Secure Behavior | Test Type | Automated Command / Evidence | Existing Coverage | Status |
|-------------|-------------|------------|-----------------|-----------|------------------------------|-------------------|--------|
| CI-06 | 140-04-T2; post-summary verifier | T-140-11 | Required repository checks are bound to one synchronized final SHA. | External integration | Focused exact-SHA hygiene contract in T2; after all summaries, exact-SHA hygiene receipt plus canonical CI run/job identity for final `main`. | Existing hygiene contract and dated entry receipt; final-SHA gate remains external. | ⬜ pending external gate |
| CI-07 | 140-04-T2; post-summary verifier | T-140-11, T-140-12 | Release evidence is same-SHA and intentionally no-publish; protected publication ownership remains unchanged. | External integration | Release-graph contract in T2; final same-SHA Release workflow, successful no-publish job graph, and hygiene receipt. | Existing release-graph contract; final-SHA gate remains external. | ⬜ pending external gate |
| BASE-03 | 140-01-T1/T2, 140-04-T1 | T-140-01, T-140-03 | Actions name exact targets and preserve uncommitted work, intentional refs, and historical evidence. | Contract + action review | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_relation_gap` plus target-specific authority and pre-action evidence. | Existing inventory relation and hygiene contracts; no cleanup action is selected in these plans. | ⬜ pending |
| TRIAGE-03 | 140-03-T1/T2 | T-140-07 | Each dependency PR has an independent compatibility, security, and required-gate assessment. | External integration + manual review | `gh pr view` exact metadata for #98/#97/#96 and #91/#88/#87; each row cites official upstream evidence and current required check results. | Existing supply-chain contract; mutable PR and upstream evidence need fresh assessment. | ⬜ pending |
| LOOSE-02 | 140-01-T1/T2, 140-02-T1, 140-03-T1/T2, 140-04-T1 | T-140-01, T-140-10 | Every credible finding has exactly one supported disposition and traceable source evidence. | Artifact consistency | `git diff --check` plus manual source-ID and terminal-proof audit against the refreshed ledger and archive paths. | Existing maintained-record collector; add recurring contract only for a demonstrated repeatable gap. | ⬜ pending |
| LOOSE-03 | 140-02-T1/T2, 140-04-T1 | T-140-04, T-140-05 | Current blockers and bounded regressions receive focused proof; speculative or feature-sized work stays deferred. | Focused contract + final full suite | Run the three v1.27 failure-group test files in 140-02-T1 and release-readiness/planning-consistency contracts in T2; one final `mix ci` after selected repairs. | Existing repair-specific seams; no product-code repair is presumed by planning. | ⬜ pending |

Task IDs are fixed above. The final external exact-SHA gate occurs after plan summaries so it measures the resulting SHA, not a pre-summary candidate.

---

## Wave 0 Requirements

- No test framework or shared fixture gap is demonstrated. Reuse existing ExUnit, Node, Bash, Git, and GitHub evidence controls.
- The planner must identify any small deterministic disposition-record check only if the refreshed evidence demonstrates a repeatable repository-owned gap.
- Local Mix requires explicit Elixir/OTP selection in this environment; verification commands must retain the working `ASDF_ELIXIR_VERSION`, `ASDF_ERLANG_VERSION`, and scheduler settings shown above.

## Multi-Source Coverage Audit

| Source | ID / item | Plan-task coverage | Status |
|--------|-----------|--------------------|--------|
| GOAL | Maintainers close only safe, evidence-backed maintenance gaps and retain a clear, recoverable disposition for everything else. | 140-01-T1/T2, 140-02-T1/T2, 140-03-T1/T2, 140-04-T1/T2 | COVERED |
| REQ | CI-06 | 140-04-T2 and post-summary exact-SHA verifier gate | COVERED |
| REQ | CI-07 | 140-04-T2 and post-summary Release no-publish verifier gate | COVERED |
| REQ | BASE-03 | 140-01-T1/T2, 140-04-T1 exact-target/authority contract | COVERED |
| REQ | TRIAGE-03 | 140-03-T1/T2 individual PR review | COVERED |
| REQ | LOOSE-02 | 140-01-T1/T2, 140-02-T1, 140-03-T1/T2, 140-04-T1 single disposition record | COVERED |
| REQ | LOOSE-03 | 140-02-T1/T2, 140-04-T1 bounded repair/deferral proof | COVERED |
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

## Validation Sign-Off

- [ ] Every generated task has an exact `<automated>` verify command or an explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks lack automated verification.
- [ ] Wave 0 covers every confirmed missing test reference.
- [ ] No watch-mode flags.
- [ ] Focused feedback commands stay under 30 seconds where stated; the full gate has its explicit 30-minute budget.
- [ ] `nyquist_compliant: true` set only after the plan checker confirms task-level mapping and verification commands.

**Approval:** pending planning verification
