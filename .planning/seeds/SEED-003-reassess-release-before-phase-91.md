---
id: SEED-003
status: dormant
planted: 2026-05-25
planted_during: v1.25 milestone planning
trigger_when: Before executing Phase 91, reassess release from current green main by comparing Hex 1.0.0 against the shipped v1.22-v1.24 delta, refreshing or replacing stale release-prep/v1.1.0 from main, and deciding whether to cut the next Hex release before more v1.25 work lands.
scope: medium
---

# SEED-003: Reassess the next Hex release before Phase 91 starts

## Why This Matters

Lockspire has shipped a substantial amount of real product surface since the public `1.0.0` package on Hex. The repo is now operationally credible again, but the public package story is still unchanged and the old `release-prep/v1.1.0` lane is stale. If Phase 91 starts without revisiting release readiness, the repo risks accumulating another milestone of shipped surface behind an outdated public package signal.

## When to Surface

**Trigger:** Before executing Phase 91, reassess release from current green main by comparing Hex 1.0.0 against the shipped v1.22-v1.24 delta, refreshing or replacing stale release-prep/v1.1.0 from main, and deciding whether to cut the next Hex release before more v1.25 work lands.

This seed should be presented during `$gsd-new-milestone` when the milestone
scope matches any of these conditions:
- the team is about to begin Phase 91 in `v1.25`
- the repo has a clean green `main` and the remaining question is whether to publish the next package
- maintainers need to decide whether the shipped v1.22-v1.24 product delta is large enough to cut the next Hex release before additional milestone work continues

## Scope Estimate

**medium** — a focused release-readiness pass covering the public Hex version, shipped milestone delta, release branch freshness, checked-in version story, and whether the next clean release should be cut now from current `main`.

## Breadcrumbs

Related code and decisions found in the current codebase:

- `mix.exs` — checked-in package version is still `1.0.0`
- `.planning/ROADMAP.md` — active milestone is `v1.25`, and Phase 91 is the next execution boundary
- `.planning/STATE.md` — planning truth is `ready_for_phase_planning`
- `.planning/PROJECT.md` — shipped milestones since `1.0.0` include `v1.22`, `v1.23`, and `v1.24`
- `.planning/MILESTONES.md` — `v1.22`, `v1.23`, and `v1.24` are archived as shipped
- live Hex package state: `lockspire 1.0.0`, last updated May 9, 2026
- latest successful `main` CI run `26406437481` on May 25, 2026
- stale extra worktree/branch: `release-prep/v1.1.0`

## Notes

As of May 25, 2026:

- the public Hex version is still `1.0.0`
- `main` is green and clean
- no open PR backlog is blocking a release decision
- the main reason not to release immediately is that the old release-prep lane no longer matches current `main`

Do not surface this seed merely because time has passed. Surface it when `main` is green, the shipped product delta is still materially ahead of Hex, and the repo is about to start another implementation wave that would widen the gap further.
