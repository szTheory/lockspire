# Pitfalls Research

**Domain:** Repository-baseline and evidence-led reconciliation for an embedded Phoenix/Elixir OAuth/OIDC library
**Researched:** 2026-08-28
**Confidence:** HIGH for repository-specific risks; MEDIUM for GitHub-hosted behavior

## Critical Pitfalls

### Pitfall 1: Treating a green run as proof for a different source SHA

**What goes wrong:** A maintainer calls `main` green because the newest visible CI run succeeded, although the local branch, release candidate, or merge commit has a different SHA. This is already a live risk: local `main` contains the v1.38 planning-start commit ahead of `origin/main`, while the prior canonical run proves the 1.5.0 release SHA.

**Why it happens:** GitHub’s run list is optimized for recency; local and remote references can diverge; release recovery is easy to describe as “latest green” rather than as a source-to-run relation.

**How to avoid:** Start with a read-only evidence matrix. For every readiness or release claim record `HEAD` SHA, `origin/main` SHA, workflow name/run ID, trigger, conclusion, and `head_sha`; reject the claim if those do not match. Preserve exact-ref release validation, detached checkout, manifest, and clean-room package proof. Do not manually change a release version to repair apparent drift.

**Warning signs:** `git status --short --branch` reports ahead/behind; `gh run list --commit <sha>` finds no successful required CI run; a run is successful but its `headSha` differs from the candidate; planning says “current main is green” without a SHA and run ID.

**Recovery posture:** Stop at observation. Push or fetch only through the normal authorized path, then obtain CI for the exact immutable SHA; if release state is suspect, use protected recovery rather than rebuilding or publishing from a workstation.

**Phase to address:** Phase 1 — Baseline inventory and evidence taxonomy.

---

### Pitfall 2: Destructive cleanup without ownership and disposition evidence

**What goes wrong:** Old branches, worktrees, draft PRs, Dependabot PRs, artifacts, or untracked files are deleted, closed, merged, or reset merely because they look stale. This can destroy useful evidence, another maintainer’s work, a still-relevant dependency update, or a recovery path.

**Why it happens:** A clean tree is mistaken for the objective. Git/GitHub inventory combines objects with different owners and lifecycles, while the milestone permits only bounded reconciliation.

**How to avoid:** Inventory first and classify every candidate exactly once: blocker, concrete regression, stale actionable artifact, deferred bounded follow-up, or retained historical evidence. Record source, observed fact, owner/authority, action or no-action, and terminal proof in standard phase verification. Use close/defer/retain for GitHub state unless policy and passing checks justify merge; do not force-push, bulk-delete, run `git clean`, or remove worktrees as baseline activity.

**Warning signs:** A proposed command targets a glob, all worktrees, all untracked files, or remote branches; no source URL/SHA/run ID accompanies a cleanup item; “no open PRs” is asserted from a truncated/default listing; a supplemental receipt is treated as disposable because its run failed.

**Recovery posture:** Stop before mutation; preserve the object and record it as retained/deferred. If an accidental local deletion occurs, recover only the explicit known target from Git/reflog or backups with owner confirmation; do not use broad rollback commands that overwrite concurrent work.

**Phase to address:** Phase 1 for classification; Phase 3 — Bounded operational loose-end triage for authorized dispositions.

---

### Pitfall 3: Letting prose, executable gates, and release records drift independently

**What goes wrong:** `PROJECT.md`, `ROADMAP.md`, `STATE.md`, the checklist, `RELEASE-TRAIN.md`, version/changelog/manifest data, and workflows make incompatible claims. Rewriting history can make the repository look coherent while removing provenance needed to reproduce why a release was trusted.

**Why it happens:** Planning is edited manually while the release lane updates selected files automatically; contributors treat a runbook as proof; prior facts are copied forward without reconciling date, SHA, or scope.

**How to avoid:** Scripts and workflow output are executable authority; prose describes observed current state. Run `bash ./scripts/maintainer/repo_hygiene_check.sh --ci` after each correction and `mix ci` for source-affecting corrections. Keep standing policy in `RELEASE-TRAIN.md`; put v1.38 dispositions in ordinary phase verification rather than a parallel maintenance tracker. Never rewrite v1.37 evidence merely to make it look current.

**Warning signs:** Hygiene version comparison fails; a release claim lacks exact source/run; a checklist command differs from its script; state differs across planning records; a new dashboard duplicates GSD verification.

**Recovery posture:** Correct the smallest authoritative layer first, run focused proof then full gates, and reconcile narrative records with dated evidence. Retain superseded historical records; add a correction note rather than silently erasing them.

**Phase to address:** Phase 2 — Reconcile required repository truth; Phase 4 — Maintenance-baseline closure.

---

### Pitfall 4: Misclassifying supplemental OIDF evidence as a required gate or certification

**What goes wrong:** A failed OIDF/FAPI run blocks the baseline without a reproduced repository defect, or a passing/partial receipt is described as formal certification. Conversely, a concrete reproducible failure is dismissed merely because the suite is supplemental.

**Why it happens:** Conformance output has security significance and is easy to over-interpret. Its short-lived artifacts and external-suite semantics differ from repository-owned required CI.

**How to avoid:** Preserve immutable suite identity, redacted receipt, run ID, profile, and explicit non-certifying classification. Required repo-native gates determine v1.38 pass/fail. Route only independently reproduced regressions to a bounded corrective task; retain broad interoperability observations for a separately approved conformance milestone. Never add provider secrets to required CI or change the supplemental workflow’s status by implication.

**Warning signs:** An acceptance criterion says “OIDF green” without “supplemental”; a failure lacks classification/receipt; a receipt exposes secrets/tokens/provider configuration; a fix expands protocol surface solely to satisfy an external suite.

**Recovery posture:** Keep the failed receipt and immutable inputs, redact before sharing, write a bounded finding, and reproduce through the required path before changing shipped behavior. If reproduction fails, retain it as non-certifying follow-up rather than forcing conformance work.

**Phase to address:** Phase 2 for classification and wording; Phase 4 for final evidence closure.

---

### Pitfall 5: Breaking the protected release chain while repairing release hygiene

**What goes wrong:** A small workflow, Release Please, or dependency update bypasses exact-SHA validation, publishes a rebuilt rather than clean-room-proven tar, weakens action pinning, or leaves the merged release PR in the wrong `autorelease:` state. The next automated release silently fails to propose or proves the wrong input.

**Why it happens:** Release automation spans configuration, checked-in runtime, CI, dispatch/recovery jobs, artifacts, tags, GitHub releases, Hex, docs, and release-train prose. A successful conclusion does not validate every link.

**How to avoid:** Keep Release Please as release-PR bookkeeping and protected exact-ref as publisher. For any release-hygiene modification inspect the chain: immutable ref equals current `main`; canonical CI reports that SHA; detached checkout builds one tar; manifest/checksum binds it; pre/post-publish checks use that tar; GitHub tag/release and Hex/HexDocs agree; PR label changes only after successful publish. Keep third-party actions pinned to verified full commit SHAs and run workflow/runtime lint and audit contracts.

**Warning signs:** Version, manifest, changelog, and ledger differ; a workflow uses floating action tag; a GitHub release targets another commit; tar is rebuilt in publish job; artifacts are the only record of critical SHA; Release Please says success but creates no eligible PR.

**Recovery posture:** Do not manually bump, tag, or publish. Halt, retain manifest/run evidence, fix the narrow workflow/config defect, and use protected exact-ref recovery after proof. Missing artifacts are an evidence-preservation problem, not permission to infer equivalence.

**Phase to address:** Phase 2 — Reconcile required repository truth, with end-to-end verification in Phase 4.

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| “Latest green” without SHA/run evidence | Fast status update | False readiness/release claims | Never for baseline or release claims |
| New maintenance dashboard | One visible list | Duplicates GSD verification and drifts from gates | Never in v1.38 |
| Bulk cleanup to make Git quiet | Appears tidy | Loss of work/evidence and unclear ownership | Never |
| Manual version/changelog/tag repair | Appears to unblock release | Breaks Release Please and artifact provenance | Only when protected process explicitly calls for it |
| Making OIDF required to force attention | Stronger apparent security signal | Non-certifying external behavior becomes shadow release gate | Never without separately approved policy |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Git + worktrees | Treating current worktree as whole repo state | Fetch/prune read-only, inspect all worktrees/refs, obtain ownership before cleanup |
| GitHub PRs/issues | Using default list limits or mutating commands during inventory | Use read-only `gh ... list --state ... --limit ... --json ...`; record URL, owner, labels, head SHA, disposition |
| Required CI / protection | Accepting prior check or enabling merge queue without `merge_group` | Bind required evidence to exact SHA; if merge queue is enabled, add/prove `merge_group` first |
| Release Please + publish | Letting a PR, tag, or rebuilt package substitute for proof | Keep PR-bookkeeping and exact-ref publisher boundary; validate manifest, SHA, tar, tag, public package together |
| Actions artifacts | Treating 30-day receipts as permanent or deleting runs casually | Check in durable redacted facts/run IDs; workflow-run deletion also deletes artifacts |
| Supplemental OIDF | Passing secrets or treating results as certification | Keep opt-in, immutable-input, redacted, explicitly non-certifying |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Running every gate for read-only inventory | Slow, noisy start; unrelated failures obscure state | Inventory first, focused proof for demonstrated correction, full gates before closure | Immediately on mature suite |
| CI hygiene depends on workstation/Docker/GitHub account | Flaky CI and unreproducible failures | Keep `--ci` repository-owned; local mode may report external state but must not mutate | Any hosted CI run |
| Artifact-only evidence | Release/conformance assertion unverifiable after retention | Persist redacted receipt facts, immutable IDs, and source SHA in records | At expiry or workflow-run deletion |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Replacing full-SHA action pins with tags | Upstream action revision can change executed code | Preserve verified full-length SHA pins and revalidate provenance on update |
| Publishing from local/nonvalidated ref | Wrong package/version reaches Hex/GitHub release | Use protected exact-ref release path with canonical CI and manifest checks |
| Copying raw OIDF/release logs into planning | Tokens, secrets, or provider config leak | Use redacted receipt pattern; audit artifact before durable storage |
| Giving required CI secrets to make optional conformance pass | Enlarges exposure and creates release dependency | Keep hosted comparison opt-in and separate from required jobs |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Hygiene says only “dirty” or “failed” | Maintainer cannot separate blocker from retained evidence | Report scope, authority, classification, and one safe next action |
| Planning says “all clean” without dated inventory | Status loses trust after first discrepancy | Cite observation date plus exact SHA/run/URL in phase evidence |
| Supplemental failure looks like outage | Panic or speculative work | Label non-certifying and state reproduction/disposition path |

## Looks Done But Isn't Checklist

- [ ] **Inventory:** Git status, refs/tags, every worktree, PRs, issues, and runs were inspected with complete read-only listings; live claims carry date and source.
- [ ] **Green CI:** Required workflow, run ID, trigger, conclusion, and `head_sha` match exact current/release source; no earlier run is reused.
- [ ] **Hygiene:** `mix ci` and `repo_hygiene_check.sh --ci` passed after final applicable change; local-only findings were reported, not placed in CI.
- [ ] **Release truth:** Version, manifest, changelog, release ledger, tag/release, checksum, and exact-ref run agree where release is claimed.
- [ ] **Loose ends:** Every PR/issue/branch/worktree/TODO/finding has one evidence-backed disposition; no unapproved merge, close, deletion, force push, or refactor occurred.
- [ ] **OIDF:** Inputs/receipt are immutable/redacted and supplemental/non-certifying; suite result is not claimed as certification.
- [ ] **Closure:** Current planning files agree without rewriting completed history; final verification points to evidence matrix and gates.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| SHA/run mismatch | MEDIUM | Stop claim; capture local/remote SHAs; obtain/identify required CI for exact SHA; update narrative only after match. |
| Unauthorized cleanup | HIGH | Stop mutation; preserve evidence; identify exact target/owner; restore only confirmed target with approval; document disposition. |
| Planning/executable drift | MEDIUM | Correct smallest proven authority, run focused proof then full gates, reconcile records with dated evidence. |
| OIDF misclassification | LOW/MEDIUM | Correct wording/classification, retain redacted receipt, reproduce required path before product fix. |
| Release-chain break | HIGH | Do not manually publish/tag; retain manifest/run IDs; fix narrow defect; use protected exact-ref recovery after proof. |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SHA/run mismatch | Phase 1: Baseline inventory | Matrix joins local/remote SHA to `gh run` JSON and required CI run ID. |
| Unauthorized cleanup | Phase 1 + Phase 3: Operational triage | Each candidate has source, classification, owner/authority, disposition, terminal proof; no broad destruction. |
| Planning/executable release drift | Phase 2: Required truth reconciliation | Hygiene contract and affected checks pass; planning/release records match executable facts. |
| Supplemental OIDF misclassification | Phase 2 + Phase 4: Closure | Workflow, receipts, verification consistently state supplemental/non-certifying and retained scope. |
| Release-chain break | Phase 2 + Phase 4: Closure | Contracts preserve SHA pins, exact ref/CI validation, detached package proof, manifest, and release linkage. |
| Future merge-queue drift | Phase 2 | If queue enabled, required workflows include/pass `merge_group`; otherwise document it as disabled. |

## Sources

- Repository evidence inspected 2026-08-28: `.planning/PROJECT.md`, `REPO-HYGIENE-CHECKLIST.md`, `ROADMAP.md`, `STATE.md`, `RELEASE-TRAIN.md`, research, `scripts/maintainer/repo_hygiene_check.sh`, `.github/workflows/{ci,release,oidf-conformance}.yml`, and local Git/worktree state.
- [GitHub Docs: troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) — MEDIUM; latest-SHA, skipped checks, merge-queue trigger behavior.
- [GitHub Docs: managing a merge queue](https://docs.github.com/en/enterprise-cloud%40latest/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue) — MEDIUM; `merge_group` requirement for required Actions checks.
- [GitHub Docs: secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — MEDIUM; full-length commit SHA action pinning.
- [GitHub Docs: removing workflow artifacts](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/remove-workflow-artifacts) and [retention configuration](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization) — MEDIUM; retention and run-deletion consequences.
- [GitHub CLI: `gh run list`](https://cli.github.com/manual/gh_run_list), [`gh pr`](https://cli.github.com/manual/gh_pr), and [`gh issue list`](https://cli.github.com/manual/gh_issue_list) — MEDIUM; non-mutating inventory commands and filters.

---
*Pitfalls research for: Lockspire v1.38 Repository Baseline & Reconciliation*
*Researched: 2026-08-28*
