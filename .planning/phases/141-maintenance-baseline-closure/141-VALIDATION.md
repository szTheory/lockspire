---
phase: "141"
slug: "maintenance-baseline-closure"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-02"
---

# Phase 141 — Validation Strategy

> Validation contract for the documentation and planning-state closeout. Runtime behavior is outside this phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit exists in the project; no application test is in scope for this documentation-only phase |
| **Config file** | `mix.exs` (existing project configuration; do not change it for Phase 141) |
| **Quick run command** | `git add -- <task-owned-paths> && git diff --cached --check -- <task-owned-paths>` before committing the task |
| **Full suite command** | The three task-scoped staged whitespace checks plus the manual evidence review below; application tests do not establish the truth of the release handoff |
| **Estimated runtime** | Under 5 seconds for the mechanical check; evidence review depends on available Phase 140 receipts and read-only sources |

---

## Sampling Rate

- **Before every task commit:** Stage only that task's declared paths, then run its exact `git diff --cached --check -- <task-owned-paths>` command. This includes new files and checks the staged task content before the commit makes it disappear from the working diff.
- **After every plan wave:** Complete the applicable manual evidence reviews and confirm each task-scoped staged check passed before its commit.
- **Before `$gsd-verify-work`:** Reconcile the dated baseline report and GSD records against the final Phase 140 terminal acceptance and current read-only Hex/GitHub release evidence.
- **Max feedback latency:** 5 seconds for the mechanical check; remote evidence latency is external.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 141-01-01 | 01 | 1 | BASE-04 | T-141-01 | Consume only Phase 140 terminal evidence for the accepted source SHA; preserve separate report-commit provenance and redact sensitive proof | docs + evidence review | `git add -- .planning/phases/141-maintenance-baseline-closure/141-BASELINE.md && git diff --cached --check -- .planning/phases/141-maintenance-baseline-closure/141-BASELINE.md` | N/A | ⬜ pending |
| 141-01-02 | 01 | 1 | BASE-05 | T-141-02 | Base public-release prose on revalidated Hex/GitHub publication evidence; preserve release-owner boundaries | docs + evidence review | `git add -- .planning/PROJECT.md .planning/RELEASE-TRAIN.md && git diff --cached --check -- .planning/PROJECT.md .planning/RELEASE-TRAIN.md` | N/A | ⬜ pending |
| 141-01-03 | 01 | 1 | BASE-04, BASE-05 | T-141-03 | Gate completion statuses on the terminal receipt and keep accepted-source, baseline-report, and reconciliation-commit identities separate | docs + cross-record review | `git add -- .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md .planning/MILESTONES.md && git diff --cached --check -- .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md .planning/MILESTONES.md` | N/A | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers the phase's mechanical documentation check. No test file, fixture, dependency, application configuration, or code change is required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The canonical dated baseline record ties local gates, required canonical CI jobs, the no-publish Release graph, public release evidence, Phase 140 dispositions, and explicit deferrals to immutable full SHAs and direct sources. | BASE-04 | Correctness depends on matching separate source-native records and current remote observations; a string or unit test cannot prove that relationship. | Confirm Phase 140 CI-06/CI-07 terminal receipt and verifier are complete for one synchronized full SHA. Match the Phase 141 record's local and hosted evidence to that SHA. Revalidate Hex/GitHub publication evidence at the closure boundary. Record unavailable evidence as pending rather than inferring absence. |
| The report and GSD project, roadmap, requirements, state, and milestone records agree about v1.38 completion and the next sustaining GA action. | BASE-05 | This is a cross-document lifecycle truth check and must account for the GSD state transition and release ownership. | Read each updated planning record and verify consistent phase/milestone status, next action, and source/report SHA labels. Verify publication is separately evidenced and no release-owned files, refs, or publication state were changed. |
| Every carried disposition remains classified as resolved, historical, deferred with a recheck trigger, or out of scope, with supplemental conformance evidence explicitly non-certifying. | BASE-04 | Disposition meaning comes from Phase 140 source records and is not safely inferred from automated label matching. | Compare the handoff against the Phase 140 disposition register and link to the source rows. Confirm each deferral has its trigger and no deferred item is represented as completed. |

---

## Validation Sign-Off

- [ ] All plan tasks have a mechanical check and a specific manual evidence review.
- [ ] Sampling continuity: every task's staged content is checked before commit and every wave receives its applicable evidence review.
- [x] Wave 0 covers all requirements; no new test infrastructure is applicable.
- [x] No watch-mode flags.
- [ ] Phase 140 exact-SHA acceptance dependency is satisfied before closure claims are made.
- [x] `nyquist_compliant: false` because semantic evidence joins and cross-record truth require a human review; `git diff --check` covers only Markdown whitespace.

**Approval:** pending
