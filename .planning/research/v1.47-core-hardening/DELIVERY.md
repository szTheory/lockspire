# Delivery and Repository Posture

**Project:** Lockspire
**Scope:** Efficient milestone delivery, trustworthy main acceptance, and safe worktree handoff
**Researched:** 2026-10-24
**Confidence:** HIGH for repository policy and local snapshot; MEDIUM for the orchestrator-supplied live GitHub observation

## Recommendation

Treat repository readiness as a short maintenance preflight that unlocks product work, not as a giant milestone. Keep the current `.planning/DEVELOPMENT-TRAIN.md` and `.planning/RELEASE-TRAIN.md` lanes: patch-eligible support/security/CI/runbook work can use focused ordinary PRs; scope-expanding product work gets one milestone branch and one milestone PR. Require an exact, fresh `main` SHA to pass both the complete local contributor gate and the repository's exact-SHA acceptance gate before declaring a baseline green. For every milestone or delegated run, record branch/commit ownership, local edits and their hashes, unique-commit ancestry, gates, CI receipts, and handoff status before starting and when stopping.

The present checkout is a provenance warning, not evidence that `main` is dirty or that CI is failing. At inspection it was `feat/164-client-secret-lifetimes` at `f8951d74c0e103f697812d070097de262beea25e`, 155 commits ahead of its tracking ref, with a preexisting modified `.planning/state.json`; its observed SHA-256 is `cf20f8428c4777a3e99478b2b4e56750ebed2d74d0761bf74fdc6c28e36b1b80`. The diff replaces prior milestone/phase state with v1.45 and empty phases. This file is GSD-generated state, so it may be a stale cache or output from another planning run, but its provenance cannot be proven from the diff alone. Preserve the before-image/hash; compare it with canonical `.planning/STATE.md`, roadmap, branch history, and the run that generated it before any SDK reconciliation. Do not commit its wholesale replacement as incidental delivery cleanup. Three additional worktrees existed: one had 85 commits ahead/23 behind `origin/main`, one had no ahead commits/22 behind, and one had 77 ahead/23 behind. The two ahead branches contain unique history; none may be removed, rebased, or called stale based only on age or directory name. `origin/main` at inspection was `a1e39a01aca258d0ac5f36414bf47c45686d92c1`; the primary checkout is not that SHA. These local observations were read-only; this agent did not refresh refs or perform cleanup.

## Durable Ownership and Handoff

Keep this policy in `.planning/research/v1.47-core-hardening/DELIVERY.md` as the durable posture for this hardening effort. Keep executable acceptance behavior in `scripts/maintainer/repo_hygiene_check.sh`; keep release publication truth in `.planning/RELEASE-TRAIN.md`; keep milestone scope and phase state in the normal GSD files. Do not copy a second checklist into CI or another runbook. If recurring provenance errors prove this protocol is insufficient, revise the existing checklist/script with a focused change and add CI enforcement only for a deterministic, repository-owned invariant.

At the beginning and end of each milestone or agent run, capture a handoff record with:

| Field | Required evidence |
|---|---|
| Run identity | Date/time, milestone/phase/task, operator or agent, purpose |
| Base provenance | Branch, `HEAD`, intended base SHA, refreshed `origin/main` SHA and fetch observation time |
| Checkout state | Porcelain status including untracked paths; for every preexisting edit, path, author/owner if known, first-seen time, and content hash or immutable snapshot location |
| Worktree ownership | Worktree path, branch, owner, purpose, last activity known, clean/dirty state |
| Commit containment | `merge-base` with intended base; counts and identities of commits unique to the worktree and commits missing from its base; disposition/owner for every unique commit before cleanup |
| Validation | Commands, revision before/after, result, test count where applicable, environment limits, and linked CI run IDs/URLs |
| Outcome | Completed, handed off, blocked, or intentionally retained; next owner/action; cleanup authorization only after proof |

Never silently overwrite or reset a preexisting change. Preserve it in place or make an explicit immutable snapshot with recorded hash and owner; stage/commit only work attributable to the current task. If attribution is unknown, hand it to the repository owner without changing it. End-of-run status must distinguish files created by the run, files merely observed, and preexisting edits. A clean status is not a substitute for commit provenance.

## Safe Delivery Sequence

1. **Observe before acting.** Read planning state and repository guidance; record `git status --short --branch`, `HEAD`, configured upstream, `git worktree list --porcelain`, and each worktree's owner/purpose, status, base, and ahead/behind counts. Do not fetch, prune, remove, stash, reset, or branch-switch until the user's current authorization and working-tree owners are clear. A later explicit acceptance run may refresh `origin/main`; that refresh is not part of this read-only snapshot.
2. **Triage scope before scheduling.** Resolve whether a change is maintenance or changes public behavior/support/topology. Group only tightly related maintenance tasks; avoid a housekeeping mega-milestone. An upstream security/schema/API decision is a dependency gate: resolve and verify it before spending downstream work on dependents. Parallelize only independent tasks with explicit file ownership and one integrator; otherwise sequence to avoid merge/review churn.
3. **Establish the exact baseline.** On a clean, synchronized local `main`, select its exact lowercase 40-character SHA only after refreshing remote truth. Run `mix ci`, then `bash ./scripts/maintainer/repo_hygiene_check.sh --accept-sha <SHA> --format json` (with one disposition per observed WARN). The exact mode requires HEAD, local `main`, and refreshed `origin/main` all equal the accepted SHA before/after local gates; it verifies `mix ci` actually ran tests and checks one successful canonical push CI run plus one successful push-triggered Release run with protected publication jobs skipped. Record the JSON receipt and run URLs/IDs. Do not describe a branch-local pass, a recent run, or the historical release record as current `main` acceptance.
4. **Use the correct lane.** For maintenance, submit a focused ordinary PR. For feature milestones, branch from the accepted main SHA using the documented `milestone/vNEXT-short-slug` convention, complete GSD phases and audit there, and merge one milestone PR to `main`. No milestone branch publishes a package; Release Please and the protected exact-ref release lane own that boundary.
5. **Validate for risk and test economics.** Run focused tests during iteration, then `mix ci` and exact-SHA acceptance where the result is intended to establish main readiness. Use risk-based coverage for protocol/security changes (OAuth/OIDC grant and token lifecycle, replay/revocation, redirect/PKCE, secret handling, redaction), and adopter/release checks for public contracts, migrations, generators, package/docs, or clean-room install changes. The supplemental OIDF/FAPI lane is redacted and non-certifying; do not turn it into a required gate by implication. Keep hosted/slow suites supplemental unless evidence justifies the cost.
6. **Close the handoff.** Before declaring completion or cleanup, record commit ownership and ancestry again, confirm all intended changes are committed or explicitly retained, capture verification, and leave unrelated/unattributed work untouched. A worktree is eligible for cleanup only when its owner confirms disposition, it is clean or its edits are preserved and attributable, and every unique commit is reachable from an agreed durable ref or explicitly handed off. Then update the end-of-run handoff; cleanup is a separate, explicit operation.

## Acceptance Gates and Tradeoffs

| Gate | Required for | Value | Cost / limitation |
|---|---|---|---|
| Clean synchronized `main` at recorded SHA | Starting main-ready milestone/release work | Makes baseline reproducible and prevents stale branch assumptions | Requires fresh remote observation; does not establish CI success alone |
| `mix ci` on exact candidate | Merge readiness | Exercises the repo's complete contributor gate, including tests | Local environment can differ; do not repeat after every edit when a focused test is faster |
| Exact acceptance receipt | Claiming accepted current main | Correlates local state, complete local gate, canonical push CI, and intentional Release no-publish outcome to one SHA | Requires clean checkout, `gh` access, bounded workflow completion, and explicit dispositions for WARNs |
| Milestone verification/audit + PR checks | Feature-milestone merge | Catches goal gaps beyond task completion and gives reviewers one coherent unit | Keep patch maintenance out of this heavier lane unless scope warrants it |
| Security/adopter focused evidence | Security, protocol, migration, generator, packaging, and host integration changes | Spends test time where user harm and upgrade risk concentrate | Avoid duplicating the full slow matrix for low-risk copy/runbook-only work |
| Worktree ownership and ancestry check | Any worktree retirement | Prevents losing another agent's dirty work or unique commits | Cleanup waits for attribution; age and naming are not evidence of abandonment |

Keep `repo_hygiene_check.sh --ci` deterministic and repository-owned. The ordinary local hygiene mode is diagnostic and may yield WARNs; exact mode is the acceptance contract and requires each WARN to have a bounded disposition (including an explicit empty list when there are none). Do not equate the ordinary mode's most recent-main checks with exact-SHA proof. OIDF/FAPI receipts are supplemental. Do not add a permanent CI job merely to restate this procedure; first show repeated, material human error that an automatic check can prevent without introducing expensive or flaky gates.

## Adversarial Cases to Reject

- A fresh-looking feature branch is treated as main because its working tree is clean, though it has diverged or carries unverified commits.
- “Latest CI is green” is accepted even though its `head_sha`, branch, event, workflow identity, or required job graph differs from the intended SHA.
- A successful Release workflow is treated as a publish; on push, the expected safe shape is Release Please maintenance succeeding while exact-ref validation, package proof, Hex publish, and public-install verification are skipped.
- The main worktree looks clean but another registered worktree contains an untracked migration, modified file, or unique commit; deleting/pruning by stale name loses it.
- A preexisting `state.json` edit is overwritten by a new GSD run or included in a commit without clear attribution.
- A failed upstream security or schema decision is allowed to invalidate multiple downstream implementations; stop dependents at the decision gate and replan their scope.
- Supplemental conformance evidence is represented as required acceptance or as a product certification claim.
- A WARN is hand-waved as harmless, or a missing GitHub observation is reported as green. Exact acceptance must record a disposition per WARN and block when exact evidence is unavailable.

## Current Observation and Evidence Boundary

Read locally on 2026-10-24: `AGENTS.md`, `.planning/DEVELOPMENT-TRAIN.md`, `.planning/RELEASE-TRAIN.md`, `.planning/REPO-HYGIENE-CHECKLIST.md`, `scripts/maintainer/repo_hygiene_check.sh`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, and `.github/workflows/oidf-conformance.yml`. The CI workflow defines seven required jobs; the hygiene script's exact mode binds the canonical CI and Release no-publish run to the same SHA and validates required job shapes. The checklist already specifies `mix ci`, hygiene acceptance, and GSD/release-truth review. The release workflow's push path maintains Release Please and does not enter protected publication jobs. The orchestrator separately observed successful canonical main CI and Release push runs for the same then-current `origin/main` SHA `a1e39a01aca258d0ac5f36414bf47c45686d92c1` (CI `39500039338`, Release `39500039371`). That is a fresh remote fact for that SHA; it does not make this feature checkout accepted. The orchestrator also observed local `main` at `a1a55de0`, distinct from remote main, so do not claim synchronized local `main`.

No test, container, fetch, branch mutation, cleanup, GitHub API query, or release action was performed by this agent. The `.planning/RELEASE-TRAIN.md` publication evidence is a dated historical release record, distinct from the orchestrator's fresh same-SHA CI/Release observation above. The supplied primary-checkout state hash matched the current file during inspection, but its author and origin remain unverified. Re-observe and preserve it before any operation that changes GSD state.

## Sources

- `AGENTS.md` — Lockspire product boundary, stack, security defaults.
- `.planning/DEVELOPMENT-TRAIN.md` — maintenance versus milestone lane and merge conditions.
- `.planning/RELEASE-TRAIN.md` — release-source and exact-SHA publication truth.
- `.planning/REPO-HYGIENE-CHECKLIST.md` — current baseline, gate, GSD, and release checklist.
- `scripts/maintainer/repo_hygiene_check.sh` — executable exact acceptance and hygiene behavior.
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `.github/workflows/oidf-conformance.yml` — CI, no-publish push shape, and supplemental conformance boundaries.
