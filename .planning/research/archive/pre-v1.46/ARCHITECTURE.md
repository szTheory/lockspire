# Architecture Research

**Domain:** Repository-baseline and reconciliation maintenance for an embedded Phoenix/Elixir OAuth/OIDC library
**Researched:** 2026-08-28
**Confidence:** HIGH for repository integration and ordering; MEDIUM for GitHub-hosted evidence retention behavior

## Standard Architecture

### System Overview

Lockspire should treat v1.38 as a bounded **maintenance evidence flow**, not as a new product subsystem or a second release process. The current repository already contains the enforcement points needed to establish a baseline. The milestone should connect them in one ordered, auditable chain and correct only evidence-backed inconsistencies.

```
┌─────────────────────── Inventory / observation ───────────────────────┐
│ local Git + worktrees │ GitHub PRs/issues │ workflow runs │ planning   │
└──────────────┬────────┴──────────┬────────┴───────┬───────┴───────────┘
               │                   │                │
               └───────────────────▼────────────────┘
┌────────────────────── Classification / disposition ───────────────────┐
│ required blocker │ concrete regression │ stale action │ defer │ retain │
│ Every item records source, exact SHA/run/URL where relevant, owner,   │
│ and one terminal disposition.                                         │
└──────────────────────────────┬────────────────────────────────────────┘
                               │ only approved, bounded changes
┌────────────────────── Required repository proof ──────────────────────┐
│ mix ci │ repo_hygiene_check.sh --ci │ required GitHub CI │ release     │
│ exact-SHA checks and public-package proof apply only when a cut occurs │
└──────────────────────────────┬────────────────────────────────────────┘
                               │
┌──────────────────────── Closure truth ────────────────────────────────┐
│ GSD phase verification + requirements/roadmap/state reconciliation    │
│ RELEASE-TRAIN remains the operating runbook; archival evidence stays  │
│ historical, and OIDF receipts remain supplemental/non-certifying.     │
└───────────────────────────────────────────────────────────────────────┘
```

The authority order should be: reproducible live repository/GitHub evidence, required repository-owned gate output, current checked-in contracts and maintained runbooks, then archived milestone evidence. A failed supplemental OIDF suite produces a classified follow-up item, not a release blocker or a certification conclusion, unless a concrete Lockspire regression is independently reproduced through the required path.

### Component Responsibilities

| Component | Responsibility | Typical implementation / current artifact |
|-----------|----------------|-------------------------------------------|
| Local repository inventory | Establish the exact branch, worktree, tag, remote, and dirty-state baseline. | Git plus the local mode of `scripts/maintainer/repo_hygiene_check.sh` and `REPO-HYGIENE-CHECKLIST.md`. |
| GitHub inventory | Identify open PRs/issues and exact workflow status/SHA without changing them. | `gh pr list`, `gh issue list`, `gh run list/view`; GitHub URLs/run IDs are evidence locators. |
| Repository quality contract | Prove maintained source, lifecycle, release, and public-surface drift contracts. | `mix ci`, `repo_hygiene_check.sh --ci`, CI jobs in `.github/workflows/ci.yml`. |
| Release authority | Create release intent and publish only from the protected, exact-ref lane. | `.github/workflows/release.yml`, Release Please action/runtime, `RELEASE-TRAIN.md`. |
| GSD planning truth | State the milestone scope, requirements, plans, verification, and closure without overwriting historical evidence. | `.planning/{PROJECT,REQUIREMENTS,ROADMAP,STATE,MILESTONES}.md`, standard phase artifacts. |
| Supplemental conformance | Preserve bounded observations from immutable suite inputs. | `.github/workflows/oidf-conformance.yml`, `scripts/conformance/`, redacted receipts. |

## Recommended Project Structure

No runtime project structure should change for v1.38. Use the repository's existing separation:

```
.planning/
├── PROJECT.md                    # product boundary and current milestone intent
├── REQUIREMENTS.md               # v1.38 acceptance requirements and traceability
├── ROADMAP.md                    # dependency-ordered phase plan
├── STATE.md                      # live milestone position and decisions
├── REPO-HYGIENE-CHECKLIST.md     # human preflight runbook
├── RELEASE-TRAIN.md              # standing sustaining/release operating contract
└── phases/<phase>/               # standard PLAN, SUMMARY, and VERIFICATION evidence

scripts/maintainer/
└── repo_hygiene_check.sh         # executable repository-owned hygiene contract

.github/workflows/
├── ci.yml                        # required repository CI / release-hygiene drift job
├── release.yml                   # Release Please plus protected exact-SHA release path
├── release-please-automerge.yml  # guarded post-merge automation
└── oidf-conformance.yml          # explicitly supplemental OIDF evidence lane
```

### Structure Rationale

- **Planning files remain the narrative and decision layer.** Modify them only when the observed baseline changes their stated truth; do not create a parallel “maintenance dashboard.”
- **Scripts and workflows remain the executable authority.** A checklist can direct maintainers to a gate but must not become a substitute for its output.
- **Standard GSD phase verification remains the loose-end ledger.** A concise disposition table in the relevant phase verification/summary is sufficient: source, finding, classification, disposition, evidence, and follow-up. Do not add a durable custom tracker unless the existing artifacts demonstrably cannot represent an item.
- **OIDF artifacts stay outside the required gate.** Their immutable suite identity and redacted receipt are valuable provenance, but the workflow naming and planning records must continue to state that they are non-certifying.

## Architectural Patterns

### Pattern 1: Evidence first, disposition second

**What:** Inventory every candidate loose end before modifying production, CI, planning, or release files. Assign it exactly one of: blocker, concrete regression, stale actionable artifact, deferred bounded follow-up, or retained historical evidence.

**When to use:** For old branches, worktrees, Dependabot PRs, draft PRs, open issues, failed supplemental workflows, historical TODOs, and apparent planning/release drift.

**Trade-offs:** This adds a short read-only pass, but prevents archaeology from silently becoming feature work. It is preferable here because v1.38 explicitly excludes speculative broadening.

**Disposition record shape:**

```text
source → observed fact → classification → action/no-action → proof of terminal state
PR #86 → dependency update remains open → triage required → defer or merge by policy → PR URL + gate result
OIDF run 33139876101 → classified suite failure → supplemental evidence → retain for future conformance milestone → receipt + scope statement
```

### Pattern 2: Executable contract is stronger than a prose assertion

**What:** Keep the checklist and release train as discoverable runbooks, but make `mix ci`, `repo_hygiene_check.sh --ci`, and CI workflows the proof-bearing gates.

**When to use:** Any claim that a branch is ready, a release contract is coherent, or a repository-owned workflow is maintained.

**Trade-offs:** Shell/source contracts intentionally validate scoped repository behavior rather than the whole GitHub account state. Pair them with the read-only local/GitHub inventory; do not enlarge CI with privileged PR/issue cleanup automation.

### Pattern 3: Exact-SHA release evidence, not “latest green” inference

**What:** Release recovery validates the specified `main` head and CI run SHA, then checks out that verified SHA before package proof and publication. The milestone baseline should preserve that chain and record the SHA for every release claim.

**When to use:** Release reconciliation, dispatch/recovery review, and any interpretation of a GitHub Actions run.

**Trade-offs:** It is stricter than checking a workflow’s successful conclusion alone, but avoids attributing earlier green CI to later source. Workflow artifacts are retained subject to GitHub retention policy, so run IDs and durable checked-in release records must accompany artifacts.

## Data Flow

### Baseline Reconciliation Flow

```
Read-only inventory
  ├─ git status / refs / worktrees / tags
  ├─ gh PRs, issues, workflow runs, SHA and conclusion
  ├─ required gate source and current local results
  └─ planning, release-train, archived verification records
        ↓
Evidence matrix (one row per loose end)
        ↓
Classify: fix now | reconcile docs/state | explicitly defer | retain historical
        ↓
Small, scoped change only when evidence demands it
        ↓
Run affected focused proof → `mix ci` → repo hygiene CI contract
        ↓
Update GSD requirements/roadmap/state and phase verification
        ↓
If patch-eligible change merged: normal Release Please → exact-SHA release lane
```

### Current Baseline Observations

- The executable CI-mode hygiene gate passed on 2026-08-28 with 18 PASS, 0 WARN, and 0 BLOCK. That proves the checked-in repository contract, not the local GitHub queue.
- The local `main` worktree is clean but one commit ahead of `origin/main` (`docs: start milestone v1.38...`). Therefore the latest remote `main` CI cannot yet prove the local planning-start commit; a future current-head claim must wait for its push and CI result.
- The GitHub inventory returned five open Dependabot PRs (#86–#91, excluding already closed numbers) and one old draft milestone PR (#83); no open issues were returned. These are disposition inputs, not evidence of a runtime regression.
- The latest listed default-branch required CI was successful for archived v1.37 source; the listed supplemental OIDF run `33139876101` failed, matching the repository’s declared non-certifying classification.

## Dependency-Aware Work Order

1. **Baseline inventory and evidence taxonomy**
   - Capture Git state, worktrees, tags, remote divergence, GitHub PR/issue/run inventories, current planning/release records, and the required-gate outputs.
   - Establish each source’s authority and record every loose end once. Do not edit product code or release automation yet.

2. **Reconcile required repository truth**
   - Resolve only contradictions among current planning files, release train, version/release metadata, required workflows, and executable gates.
   - Run focused contracts and the full repo-owned gates for each concrete correction. Keep supplemental OIDF evidence classified and outside the acceptance gate.

3. **Triage bounded operational loose ends**
   - Dispose of stale branches/worktrees, draft/open PRs, dependency updates, TODOs, and obsolete GSD artifacts only after confirming ownership and active relevance.
   - Use close/defer/retain records for external GitHub state; do not infer authority to merge or delete from inventory alone.

4. **Close the maintenance baseline**
   - Update requirements, roadmap, state, and standard phase verification so their claims point to the final evidence matrix and gate outputs.
   - Re-run local and CI-required proof. If a patch-eligible repository change lands, let the established Release Please and exact-SHA publish path handle release rather than inventing a v1.38 release lane.

**Ordering rationale:** Step 1 prevents false positives from stale history and differentiates remote-vs-local SHA evidence. Step 2 creates a reliable acceptance spine before any cleanup action. Step 3 is safe only after the classification rules exist. Step 4 is last because closeout is a claim about the post-triage repository, not an input to it.

## Integration Points

### Existing vs. Minimally Modified Artifacts

| Artifact | Status in v1.38 | Integration rule |
|----------|----------------|------------------|
| `scripts/maintainer/repo_hygiene_check.sh` | Existing executable gate; modify only for demonstrated missing repository-owned check. | Its `--ci` mode remains CI-safe and its local mode reports, rather than mutates, local/GitHub state. |
| `.planning/REPO-HYGIENE-CHECKLIST.md` | Existing human runbook; modify only to remove observed drift or add a proven omitted preflight. | Keep command order aligned with the script and release train. |
| `.github/workflows/ci.yml` | Existing required proof. | Maintain the Release Hygiene Drift job; no supplemental suite should become a required job by implication. |
| `.github/workflows/release.yml` and automerge workflow | Existing protected release authority. | Preserve Release Please ownership, exact-SHA CI validation, detached checkout, and protected Hex publish. |
| `.github/workflows/oidf-conformance.yml` and `scripts/conformance/` | Existing supplemental evidence lane. | Preserve immutable-input/redacted-receipt practices and explicit non-certifying wording. |
| `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` | Existing planning truth; expected to be updated at normal milestones checkpoints. | Reconcile current v1.38 scope and final dispositions; never rewrite prior milestone facts to make them appear current. |
| `RELEASE-TRAIN.md` | Existing standing operational contract. | Change only if a verified release-train process fact changes; it is not a v1.38 task log. |
| `.planning/phases/<phase>/*-VERIFICATION.md` and summaries | New standard GSD evidence for this milestone. | Store the compact disposition matrix and commands/results here instead of creating a bespoke loose-end framework. |
| `lib/`, public docs, generators, protocol/storage/admin code | No planned change. | Touch only to correct a reproducible regression found by the required gates; no product architecture redesign. |

### Internal Boundaries

| Boundary | Communication | Rule |
|----------|---------------|------|
| Checklist ↔ hygiene script | Runbook invokes executable command. | Script output wins if prose conflicts. |
| Hygiene script ↔ CI | `--ci` executes only repository-owned static/drift checks. | CI must remain Docker-daemon-free and must not depend on personal GitHub workstation state. |
| Local GitHub inventory ↔ GSD phase evidence | Read-only `gh` and Git observations feed a dated disposition matrix. | Do not claim queue closure until a fresh inventory confirms it. |
| CI ↔ Release workflow | Required CI evidence is bound to the exact release source SHA. | “Latest green” is insufficient where SHA differs. |
| Required gates ↔ OIDF suite | Required gates determine baseline pass/fail; OIDF produces classified supplemental evidence. | Never upgrade its status to certification or a release blocker without an explicit future decision. |
| Release train ↔ milestone closure | Sustaining rules remain in `RELEASE-TRAIN.md`; phase records prove this milestone. | Avoid duplicate release policies or manual version/release branches. |

## Anti-Patterns

### Anti-Pattern 1: Treating every old artifact as active work

**What people do:** Turn stale branches, archived findings, and failed optional suite runs into a broad cleanup or protocol-hardening program.

**Why it is wrong:** It erases the distinction between historical evidence, actionable drift, and future scope; v1.38 then becomes an unbounded feature milestone.

**Do this instead:** Require a source-backed classification and terminal disposition before changing anything.

### Anti-Pattern 2: Equating a successful workflow with proof for arbitrary source

**What people do:** Use the newest green workflow as evidence that a different local or release SHA is good.

**Why it is wrong:** A local `main` already ahead of `origin/main` demonstrates the gap directly.

**Do this instead:** Record and compare head SHA, workflow run ID, trigger, conclusion, and relevant gate/job. Use the exact-SHA release workflow as the model.

### Anti-Pattern 3: Making supplemental conformance a shadow required gate

**What people do:** Treat suite failure as a repository-baseline failure or describe it as certification evidence.

**Why it is wrong:** The repository deliberately classifies it as supplemental, and its external suite behavior cannot replace Lockspire’s required repository-owned proof.

**Do this instead:** Retain immutable suite inputs and redacted receipts, state their classification, and route a reproducible product concern to a future bounded conformance milestone.

### Anti-Pattern 4: Adding a maintenance subsystem to solve planning drift

**What people do:** Add runtime modules, Mix tasks, an app database, or a permanent custom tracking framework for repository cleanup.

**Why it is wrong:** It broadens Lockspire’s shipped surface and duplicates GSD phase verification, scripts, and GitHub’s native queue.

**Do this instead:** Keep maintenance logic in existing repo-local scripts, workflows, planning files, and normal GitHub disposition mechanisms.

## Sources

- Repository evidence inspected 2026-08-28: `.planning/PROJECT.md`, `REPO-HYGIENE-CHECKLIST.md`, `ROADMAP.md`, `STATE.md`, `RELEASE-TRAIN.md`, `scripts/maintainer/repo_hygiene_check.sh`, and the CI/release/conformance workflows.
- Repository command evidence: `bash ./scripts/maintainer/repo_hygiene_check.sh --ci` — 18 PASS, 0 WARN, 0 BLOCK; read-only Git and GitHub CLI inventory.
- [GitHub Docs: workflow artifacts and retention](https://docs.github.com/en/actions/tutorials/store-and-share-data) — MEDIUM confidence via verified web-search source.
- [GitHub CLI: `gh run list`](https://cli.github.com/manual/gh_run_list), [GitHub CLI: `gh issue list`](https://cli.github.com/manual/gh_issue_list), and [GitHub CLI: pull requests](https://cli.github.com/manual/gh_pr) — MEDIUM confidence via verified web-search source.

---
*Architecture research for: Lockspire v1.38 Repository Baseline & Reconciliation*
*Researched: 2026-08-28*
