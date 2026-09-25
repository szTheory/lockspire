# Requirements: Lockspire

**Defined:** 2026-08-28
**Milestone:** v1.38 Repository Baseline & Reconciliation
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.38 Requirements

Requirements for the Repository Baseline & Reconciliation milestone. Each requirement maps to exactly one roadmap phase.

### Repository Baseline

- [x] **BASE-01**: Maintainer can refresh origin refs and tags and prove that local `main` is clean and synchronized with `origin/main`, or record the exact divergence blocking that state.
- [x] **BASE-02**: Maintainer can inspect every relevant local/remote branch, tag, and worktree with an explicit keep, remove, or defer disposition.
- [ ] **BASE-03**: Maintainer can perform only authorized, exact-target cleanup without deleting uncommitted work, intentional refs, or historical release evidence.

### GitHub Triage

- [x] **TRIAGE-01**: Maintainer can inspect every open pull request and record a merge-ready, needs-work, close, or defer disposition supported by current evidence.
- [x] **TRIAGE-02**: Maintainer can inspect every open issue and record a close, retain, or defer disposition without using zero open issues as a success metric.
- [ ] **TRIAGE-03**: Maintainer can evaluate each dependency-update PR independently against compatibility, security, and required repository gates rather than treating updates as a bulk campaign.

### CI and Release Evidence

- [ ] **CI-06**: Maintainer can prove all required repo-owned CI checks pass for the exact synchronized final `main` SHA.
- [ ] **CI-07**: Maintainer can prove the release workflow is successful or intentionally skipped/no-op for that same baseline without publishing or manually changing release-owned files.
- [x] **CI-08**: Maintainer can distinguish required acceptance checks from supplemental OIDF runs and retain OIDF findings as redacted, non-certifying evidence.

### Local Gates

- [x] **QUAL-05**: Maintainer can run `mix ci` from the reconciled baseline with all checks passing.
- [x] **HYGIENE-05**: Maintainer can run the repository hygiene check with no unresolved `BLOCK` result and an explicit disposition for every `WARN`.
- [x] **HYGIENE-06**: Maintainer can add or tighten a deterministic repository-health check only when execution demonstrates a repeatable repository-owned gap.

### Planning and Release Truth

- [x] **TRUTH-03**: Maintainer can verify that `PROJECT.md`, `ROADMAP.md`, `STATE.md`, `MILESTONES.md`, requirements, and maintained planning records describe one coherent current milestone and release posture.
- [x] **TRUTH-04**: Maintainer can trace the current public release through its source SHA, CI run, release run, tag, package checksum, Hex package, and maintained release records without rewriting historical evidence.
- [x] **TRUTH-05**: Maintainer can verify that Release Please ownership, protected exact-ref publishing, full-SHA action pins, and manifest-bound artifact proof remain intact.

### Evidence-Led Loose Ends

- [x] **LOOSE-01**: Maintainer can inventory pending todos, archived audit and verification findings, debug or handoff artifacts, roadmap notes, and other maintained follow-up records.
- [ ] **LOOSE-02**: Maintainer can assign each credible finding exactly one evidence-backed disposition: fix now, defer with a trigger, retain as historical evidence, already resolved, or out of scope.
- [ ] **LOOSE-03**: Maintainer can close blockers, regressions, contradictions, stale actionable artifacts, and small high-confidence maintenance gaps while excluding speculative or feature-sized work.

### Baseline Closure

- [ ] **BASE-04**: Maintainer can inspect a dated baseline record tying final Git state, local gates, required workflow runs, release evidence, loose-end dispositions, and explicit deferrals to exact SHAs and sources.
- [ ] **BASE-05**: Maintainer can finish v1.38 with coherent GSD state and an explicit return to Lockspire's sustaining GA release train.

## Future Requirements

Deferred to a later sustaining pass or separately justified milestone.

### Follow-Up Candidates

- **FUTURE-04**: Maintainer can rely on additional repository-truth drift checks if v1.38 demonstrates recurring, mechanically detectable drift not covered by existing gates.
- **FUTURE-05**: Maintainer can run a bounded conformance-hardening milestone with measurable acceptance around retained OIDF findings.
- **FUTURE-06**: Maintainer can reconsider CI or merge-process design if sustained queue contention or insufficient current controls are demonstrated.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New OAuth/OIDC protocol capability | v1.38 is a maintenance baseline, not a product-expansion milestone. |
| Host-seam or admin-surface expansion | Requires separate adopter evidence and feature planning. |
| Forced OIDF/FAPI suite success or certification claim | Supplemental results remain honest, redacted, non-certifying follow-up evidence. |
| New CI platform, issue tracker, dashboard, or maintenance subsystem | Existing repository tooling is sufficient; no replacement need was demonstrated. |
| Broad dependency-refresh or speculative refactor campaign | Each dependency or code change must be justified by concrete repository evidence. |
| Destructive bulk cleanup, history rewriting, or zero-open-issues target | Cleanliness is an evidence-backed disposition, not erasure of work or history. |
| Manual version, changelog, manifest, tag, or package publication changes | Release Please and the protected exact-ref publishing lane retain ownership. |

## Traceability

Populated during roadmap creation. Every v1.38 requirement must map to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BASE-01 | Phase 138 | Complete |
| BASE-02 | Phase 138 | Complete |
| BASE-03 | Phase 140 | Pending |
| TRIAGE-01 | Phase 138 | Complete |
| TRIAGE-02 | Phase 138 | Complete |
| TRIAGE-03 | Phase 140 | Pending |
| CI-06 | Phase 140 | Pending |
| CI-07 | Phase 140 | Pending |
| CI-08 | Phase 139 | Complete |
| QUAL-05 | Phase 139 | Complete |
| HYGIENE-05 | Phase 139 | Complete |
| HYGIENE-06 | Phase 139 | Complete |
| TRUTH-03 | Phase 139 | Complete |
| TRUTH-04 | Phase 139 | Complete |
| TRUTH-05 | Phase 139 | Complete |
| LOOSE-01 | Phase 138 | Complete |
| LOOSE-02 | Phase 140 | Pending |
| LOOSE-03 | Phase 140 | Pending |
| BASE-04 | Phase 141 | Pending |
| BASE-05 | Phase 141 | Pending |

**Coverage:**

- v1.38 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-28*
*Last updated: 2026-09-25 after Phase 139 verification*
