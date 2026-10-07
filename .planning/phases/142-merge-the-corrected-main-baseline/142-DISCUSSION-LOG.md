# Phase 142: Merge the Corrected Main Baseline - Discussion Log (Assumptions Mode)

> **Audit trail only.** Decisions are captured in `142-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-10-06
**Phase:** 142-merge-the-corrected-main-baseline
**Mode:** assumptions
**Areas analyzed:** public release truth, merge automation boundary, exact-main evidence, warning disposition, maintainer record links

## Assumptions Presented

### Public release truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Merge through the reviewed PR path, preserve 1.5.0 as latest public, and leave release-owned version bookkeeping and publication to existing automation. | Confident | `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`; `.planning/RELEASE-TRAIN.md`; `.github/workflows/release.yml` |

### Merge automation boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Check the live Release Please PR and workflow state before merge; do not let automatic publication cross Phase 142's readiness boundary. | Unclear — live state must be checked when executing | `.github/workflows/release-please-automerge.yml`; `.github/workflows/release.yml` |

### Exact-main evidence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Use post-merge full-SHA identity, matching canonical CI, and exact-SHA hygiene; do not reuse pre-merge or Phase 140 evidence for the new commit. | Likely | `scripts/maintainer/repo_hygiene_check.sh`; `.planning/REPO-HYGIENE-CHECKLIST.md`; `.planning/ROADMAP.md` |

### Warning disposition
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Require no hygiene `BLOCK`, one explicit disposition per `WARN`, and keep OIDF/FAPI outside the release gate. | Confident | `scripts/maintainer/repo_hygiene_check.sh`; `.planning/REPO-HYGIENE-CHECKLIST.md`; `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` |

### Maintainer record link
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Fix the stale Phase 141 baseline pointer and add a narrow required-CI contract for local links in the release-train record. | Confident | `.planning/RELEASE-TRAIN.md`; `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`; `test/lockspire/release/repository_hygiene_contract_test.exs` |

## Corrections Made

No corrections. The user approved the recommendation set.

## External Research

No separate ecosystem comparison was needed: this phase has no Elixir API, runtime, or UI design choices, and the repository's release workflow and prompt corpus already define the relevant practice. The current PR/workflow/publication state is mutable and must be observed during execution rather than inferred from repository files.

## Agent Discretion

- Record the exact post-merge SHA and matching CI/hygiene evidence in a concise durable Phase 142 artifact.
- Add only a focused local-link contract for `.planning/RELEASE-TRAIN.md`; no broad Markdown checker.
- No manual UAT for properties established by automated CI and hygiene evidence.
