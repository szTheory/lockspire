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
| **Quick run command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release/release_ci_evidence_contract_test.exs test/lockspire/workflow_supply_chain_contract_test.exs` |
| **Full suite command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix ci` |
| **Estimated runtime** | Allow about 30 minutes for a clean isolated full run on this host; focused ExUnit/Node checks should complete much sooner. |

---

## Sampling Rate

- **After every task commit:** Run the nearest affected ExUnit or Node contract; use the quick command when repository evidence or CI contracts change.
- **After every plan wave:** Run the full `mix ci` command above when local toolchain selection is available; otherwise capture the precise blocking toolchain evidence and rely on required CI without claiming local validation.
- **Before `$gsd-verify-work`:** Require full local CI and exact-SHA hygiene/CI/Release evidence for the synchronized final `main` SHA.
- **Max feedback latency:** 30 minutes for the clean full acceptance path; under 30 seconds for focused contracts where noted.

---

## Per-Requirement Verification Map

| Requirement | Plan / Task | Threat Ref | Secure Behavior | Test Type | Automated Command / Evidence | Existing Coverage | Status |
|-------------|-------------|------------|-----------------|-----------|------------------------------|-------------------|--------|
| CI-06 | Assigned by planner | T-140-01 | Required repository checks are bound to one synchronized final SHA. | External integration | Exact-SHA hygiene result plus canonical CI run/job identity for final `main`. | Existing hygiene contract and durable entry receipt; final-SHA gate is external. | ⬜ pending |
| CI-07 | Assigned by planner | T-140-01 | Release evidence is same-SHA and intentionally no-publish; protected publication ownership remains unchanged. | External integration | Same-SHA Release workflow and skipped publication-job graph; retain the final hygiene receipt. | Existing release-graph contract and durable entry receipt; final-SHA gate is external. | ⬜ pending |
| BASE-03 | Assigned by planner | T-140-02 | Actions name exact targets and preserve uncommitted work, intentional refs, and historical evidence. | Contract + manual action review | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release/repository_hygiene_contract_test.exs` plus target-specific authority and pre-action evidence. | Existing inventory relation and hygiene contracts; each proposed action still needs its own review. | ⬜ pending |
| TRIAGE-03 | Assigned by planner | T-140-03 | Each dependency PR has an independent compatibility, security, and required-gate assessment. | External integration + manual review | Refresh each PR’s target/head/base/checks with `gh pr view <number> --json number,title,headRefOid,baseRefOid,mergeStateStatus,statusCheckRollup`; attach package-specific official upstream evidence. | Existing workflow supply-chain contract; mutable PR and upstream evidence must be refreshed. | ⬜ pending |
| LOOSE-02 | Assigned by planner | T-140-04 | Every credible finding has exactly one supported disposition and traceable source evidence. | Artifact consistency | Validate the disposition record against stable Phase 138 IDs, canonical source paths, one disposition per finding, and terminal proof for fixed/resolved claims. | No Phase 140 disposition-record contract exists yet; add one only if the planner confirms a repeatable repository-owned gap. | ⬜ pending |
| LOOSE-03 | Assigned by planner | T-140-05 | Current blockers and bounded regressions receive focused proof; speculative or feature-sized work stays deferred. | Focused contract + full suite | Run the nearest existing regression selector after each selected repair, then the full `mix ci` command above. | Existing repair-specific seams; exact selectors depend on the refreshed candidate set. | ⬜ pending |

*Task IDs and waves are assigned during planning; the planner must replace this requirement-level map with exact plan/task coverage and runnable commands.*

---

## Wave 0 Requirements

- No test framework or shared fixture gap is demonstrated. Reuse existing ExUnit, Node, Bash, Git, and GitHub evidence controls.
- The planner must identify any small deterministic disposition-record check only if the refreshed evidence demonstrates a repeatable repository-owned gap.
- Local Mix requires explicit Elixir/OTP selection in this environment; verification commands must retain the working `ASDF_ELIXIR_VERSION`, `ASDF_ERLANG_VERSION`, and scheduler settings shown above.

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
