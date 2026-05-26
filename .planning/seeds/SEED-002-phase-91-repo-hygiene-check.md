---
id: SEED-002
status: obsolete
planted: 2026-05-25
planted_during: v1.25 milestone planning
resolved: 2026-05-26
resolved_in: v1.25 milestone close prep
trigger_when: Before starting Phase 91 implementation or creating a new release branch, run a repo-hygiene pass to confirm main is green, git status is clean, and the stale release-prep/v1.1.0 worktree is either removed or refreshed from current main.
scope: small
---

# SEED-002: Re-run repo hygiene before Phase 91 or the next release branch

## Why This Matters

The repo is currently healthy enough for milestone work, but one stale release-prep lane still exists. If that old worktree lingers into Phase 91 execution or the next release attempt, it creates unnecessary confusion about which branch reflects the real release candidate. A lightweight hygiene pass at the next natural boundary keeps milestone work starting from a trustworthy base and prevents release-lane drift from quietly accumulating again.

## When to Surface

**Trigger:** Before starting Phase 91 implementation or creating a new release branch, run a repo-hygiene pass to confirm main is green, git status is clean, and the stale release-prep/v1.1.0 worktree is either removed or refreshed from current main.

This seed should be presented during `$gsd-new-milestone` when the milestone
scope matches any of these conditions:
- the team is about to begin Phase 91 implementation in `v1.25`
- a maintainer is preparing a fresh release candidate from current `main`
- repo hygiene needs a quick re-check after a green-main stabilization pass but before the next execution wave starts

## Scope Estimate

**small** — a focused admin pass covering `git status`, `main` CI health, active worktrees, and whether `release-prep/v1.1.0` should be deleted or recreated from current `main`.

## Breadcrumbs

Related code and decisions found in the current codebase:

- `.planning/ROADMAP.md` — `v1.25` is active and Phase 91 is the next execution entry point
- `.planning/STATE.md` — repo planning truth is `ready_for_phase_planning`
- `mix.exs` — checked-in package version is still `1.0.0`
- latest successful `main` CI run `26406437481` on May 25, 2026
- latest successful `main` Release workflow run `26406437482` on May 25, 2026
- active extra worktree: `.claude/worktrees/release-prep-v1.1.0`

## Notes

As of May 25, 2026:

- `main` is clean and green
- open PR count is zero
- the remaining hygiene concern is narrow release-lane clutter, not general repo instability

This should not block routine planning, but it should be revisited before Phase 91 implementation or any new release-prep branch so the next execution wave starts from one intentional branch story.

## Outcome

This seed is now obsolete. Its trigger boundary passed during `v1.25`, and the remaining repo/worktree hygiene work should be reconsidered as a fresh release-prep or repo-maintenance task rather than as a pre-Phase-91 blocker.
