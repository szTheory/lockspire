# Feature Research

**Domain:** Repository-baseline and evidence-led loose-end reconciliation for a mature embedded OAuth/OIDC library
**Project:** Lockspire v1.38 Repository Baseline & Reconciliation
**Researched:** 2026-08-28
**Confidence:** HIGH for repository-derived scope; MEDIUM for GitHub/Git operational recommendations (verified against primary documentation).

## Feature Landscape

This is a maintenance milestone, not a protocol or product feature release. Its usable outcome is a maintainer who can inspect `main`, local Git state, GitHub work, gates, release evidence, and GSD records and reach one reproducible conclusion: each is clean and current, deliberately deferred, or recorded as a concrete follow-up. “Clean” must not mean hiding evidence, deleting work indiscriminately, or manufacturing passing status.

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Dependencies / testable behavior |
|---------|--------------|------------|----------------------------------|
| Synchronized clean-main proof | The declared baseline must be the actual default-branch commit, not a stale local checkout. | LOW | Existing Git remote and `REPO-HYGIENE-CHECKLIST.md`; after fetch/prune/tags, `main` is clean and matches `origin/main`, or the divergence is explicitly recorded. |
| Intentional ref, branch, tag, and worktree inventory | Parallel work is safe only when every ref and checkout has a purpose. | MEDIUM | Existing Git history, worktree metadata, milestone/release branches; enumerate each item with keep/delete/defer rationale before any mutation. |
| Open PR and issue disposition | Untriaged GitHub work makes “baseline” ambiguous. | LOW | Existing GitHub repository and `gh`; every open PR/issue is merged, closed with reason, or deferred with owner/next review point and link to durable planning evidence. |
| Required CI and release evidence at the current main SHA | Green history at an older SHA does not prove a green baseline. GitHub requires checks to pass on the latest commit SHA. | MEDIUM | Existing Actions/release workflows and protected branch settings; identify required checks and show success, intentional skip/no-op, or a named blocker at the synchronized SHA. |
| Local quality-gate proof | Cloud CI alone cannot validate repository-local scripts and developer reproducibility. | MEDIUM | Existing `mix ci` and `scripts/maintainer/repo_hygiene_check.sh`; run from the clean baseline and retain concise pass/failure evidence. |
| Coherent planning and release truth | Operators and future maintainers need one current release/milestone story. | MEDIUM | `PROJECT.md`, `ROADMAP.md`, `STATE.md`, `MILESTONES.md`, `RELEASE-TRAIN.md`, release PR/tag/Hex evidence; correct concrete contradictions or state precise deferrals. |
| Evidence-led loose-end register and closure | Mature repositories accumulate TODOs and audit findings; their status must be reviewable. | MEDIUM | Existing plans, archived evidence, docs, TODOs, debug/handoff files; classify each candidate as fix now, explicitly defer, already resolved, or out of scope, with evidence. |
| Honest supplemental OIDF disposition | Existing suite failures are follow-up evidence, not certification. | LOW | Existing immutable receipts and allowlist; preserve findings, non-certifying wording, and optional hosted-provider boundary without turning them into release blockers. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Dependencies / testable behavior |
|---------|-------------------|------------|----------------------------------|
| One repeatable baseline report | Converts scattered terminal checks into an auditable maintainer handoff and reduces rediscovery. | MEDIUM | Existing hygiene script, Actions URLs, release ledger, GSD files; one dated report maps each check to command, SHA, disposition, and source evidence. |
| Machine-checkable drift fence for repo truth | Prevents the next patch release from silently separating planning/release claims from reality. | MEDIUM | Existing release-contract and documentation tests; add only deterministic assertions for concrete linkage or version facts, never a brittle scrape of GitHub UI. |
| Explicit safe-defer protocol | Makes “not doing this now” responsible rather than vague while protecting the bounded scope. | LOW | GSD roadmap/state and GitHub issues; a deferred item contains evidence, reason, boundary, owner/revisit trigger, and no false completion claim. |
| Exact-SHA release provenance synopsis | Preserves the v1.37 strength: CI, release tar, public package, tag, and docs trace to one exact source revision. | LOW | Existing release lane and `STATE.md`; baseline record identifies the canonical current release evidence without rerunning publication. |
| Reconciliation-oriented hygiene output | PASS/WARN/BLOCK plus remediation is calmer and safer than a generic cleanup command. | MEDIUM | Existing hygiene gate; report repo-owned actionable state with scope and recommended disposition, while retaining user-owned unrelated work. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| “Delete everything stale” cleanup | A visually empty branch/worktree/issue list feels tidy. | Risks deleting intentional work, historical release evidence, or other worktree changes; violates evidence-led scope. | Inventory first; delete only exact, confirmed obsolete targets and record the disposition. |
| Force-push, force-delete, or history rewriting to make main look clean | It can appear to resolve divergence quickly. | It can invalidate release provenance and disrupt collaborators; repository cleanliness is not authority to rewrite shared history. | Fetch, compare, and resolve through ordinary reviewed GitHub flow; escalate genuine remote anomalies. |
| Rerun or alter supplemental OIDF suites until green | A green conformance dashboard is attractive. | Converts honest non-certifying evidence into unbounded protocol/conformance work and risks unsupported claims. | Preserve immutable findings and create a future bounded conformance-hardening candidate only when justified. |
| New OAuth/OIDC, host seam, or admin-surface work | Loose ends can expose desirable feature ideas. | Directly exceeds v1.38 and obscures whether the maintenance baseline is complete. | Defer feature-sized work to a separately evidenced milestone. |
| New CI platform, merge queue, or issue-management system | Automation can seem like a durable solution. | High migration cost and workflow risk with no repository evidence that present controls are insufficient. GitHub positions merge queues for busy branches. | Validate and repair existing required workflows; consider platform changes only with measured throughput pain. |
| “Close all issues” metric | It creates an easy completion number. | Destroys useful backlog signal and turns valid deferred work into invisible debt. | Give each item a durable, explicit disposition and retain valid deferred issues. |
| Manual version/changelog/manifest bumps | It appears to reconcile release facts immediately. | Contradicts the established Release Please and protected publishing contracts. | Let the existing release automation own release-version files; reconcile narrative records only where evidence proves drift. |

## Feature Dependencies

```text
Synchronized clean main
    ├──requires──> ref / branch / tag / worktree inventory
    ├──requires──> open PR and issue disposition
    └──requires──> current-SHA CI and release evidence

Current-SHA CI evidence ──requires──> passing local gates
Coherent planning and release truth ──requires──> exact-SHA release provenance
Loose-end closure ──requires──> evidence inventory + safe-defer protocol

Supplemental OIDF disposition ──conflicts──> forced certification / protocol expansion
```

### Dependency Notes

- **Synchronized main requires intentional repository state:** pruning or cleanup before recording branch/worktree purpose could erase the evidence needed for a defensible baseline.
- **Current-SHA CI requires the baseline SHA:** GitHub’s required-check behavior is commit-specific; previous successful runs are context, not acceptance proof for a changed `main`.
- **Truth reconciliation requires release provenance:** release ledger/doc corrections must tie to the existing tag, release PR, protected release run, package checksum, and source SHA rather than inferred versions.
- **Loose-end closure requires safe deferral:** a candidate cannot be called complete merely because it is not fixed; it needs a bounded disposition backed by repository evidence.
- **Supplemental OIDF finding preservation conflicts with conformance forcing:** v1.38 must retain the non-certifying classification stated in the project records.

## MVP Definition

### Launch With (v1.38)

- [ ] Clean, synchronized `main` and deliberate local Git/worktree/ref disposition — establishes the factual baseline.
- [ ] Triage of all open PRs/issues plus required CI/release and local-gate evidence at the baseline SHA — proves operational health.
- [ ] Reconciled GSD/release/document truth and an evidence-backed loose-end register — makes the result durable for the next maintainer.
- [ ] Preservation of supplemental OIDF findings as explicitly non-certifying follow-up evidence — preserves honesty and scope.

### Add After Validation (next sustaining pass)

- [ ] Deterministic repository-truth drift checks — add only if this reconciliation finds recurring, mechanically detectable drift.
- [ ] Narrow hygiene-script improvements — add only for concrete false negatives/positives observed during the baseline run.

### Future Consideration (separate milestone only)

- [ ] Bounded conformance hardening — only after defining measurable acceptance around the retained OIDF findings.
- [ ] CI/merge-process redesign — only after evidence of sustained queue contention or insufficient current controls.
- [ ] Any protocol, host-seam, or operator-surface changes — follow adopter evidence and normal feature-milestone planning.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Clean synchronized state and intentional Git inventory | HIGH | LOW/MEDIUM | P1 |
| Current-SHA CI/release plus local-gate proof | HIGH | MEDIUM | P1 |
| PR/issue triage and loose-end dispositions | HIGH | MEDIUM | P1 |
| GSD/release/document reconciliation | HIGH | MEDIUM | P1 |
| Repeatable baseline report | MEDIUM | MEDIUM | P2 |
| Machine-checkable drift fences | MEDIUM | MEDIUM | P2, evidence-triggered |
| CI platform or protocol/conformance expansion | LOW for this goal | HIGH | P3 / excluded |

## Sources

- Lockspire repository evidence: [PROJECT.md](../PROJECT.md), [REPO-HYGIENE-CHECKLIST.md](../REPO-HYGIENE-CHECKLIST.md), [ROADMAP.md](../ROADMAP.md), and [STATE.md](../STATE.md) — HIGH.
- [GitHub: About protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) — MEDIUM; required-status, strictness, and merge-queue behavior.
- [GitHub: Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) — MEDIUM; latest-SHA and merge-group workflow constraints.
- [GitHub: Planning and tracking work](https://docs.github.com/en/issues/tracking-your-work-with-issues/learning-about-issues/planning-and-tracking-work-for-your-team-or-project) and [Managing labels](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels) — MEDIUM; durable triage metadata.

---
*Feature research for: Lockspire v1.38 Repository Baseline & Reconciliation*
*Researched: 2026-08-28*
