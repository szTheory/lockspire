---
id: SEED-001
status: dormant
planted: 2026-05-06
planted_during: v1.16 milestone planning
trigger_when: When the embedded host path is executable end to end and package/release/support truth are reconciled, plan a real public release instead of continuing to accumulate shipped surface behind stale metadata.
scope: medium
---

# SEED-001: Cut the next real Lockspire release after v1.16 truth work lands

## Why This Matters

Lockspire has shipped substantial protocol capability since the last package version recorded in `mix.exs` and `.release-please-manifest.json`, but the public release artifact story is still stale. The repo now claims a much stronger GA posture in docs than the package metadata and changelog currently reflect. Once the canonical embedded Phoenix/Sigra path is proved and the release truth work in v1.16 lands, continuing to defer a real release would create needless trust and adoption drag.

## When to Surface

**Trigger:** When the embedded host path is executable end to end and package/release/support truth are reconciled, plan a real public release instead of continuing to accumulate shipped surface behind stale metadata.

This seed should be presented during `$gsd-new-milestone` when the milestone
scope matches any of these conditions:
- v1.16 or a follow-on milestone has closed the Sigra golden path and generated-host proof work.
- package version, changelog, release manifest, and supported-surface docs are aligned and the remaining question is whether to cut the release now.
- maintainers need to decide whether the repo has crossed the threshold from “major milestone shipped” to “publish a new Hex release.”

## Scope Estimate

**medium** — release planning, changelog/version posture, release PR review, trusted publish verification, and any final support-contract reconciliation needed before pushing the next public package.

## Breadcrumbs

Related code and decisions found in the current codebase:

- `mix.exs` — package version still reads `0.2.0`
- `.release-please-manifest.json` — release manifest still reads `0.2.0`
- `CHANGELOG.md` — stale relative to shipped milestones
- `docs/supported-surface.md` — public docs claim `1.0.0` GA support posture
- `docs/maintainer-release.md` — canonical release gate and hold points
- `.github/workflows/release.yml` — trusted publish workflow
- `.planning/PROJECT.md` — v1.16 milestone rationale
- `.planning/ROADMAP.md` — Phase 65 centers release-truth reconciliation

## Notes

As of 2026-05-06:

- the last milestone tag is `v1.15`
- there are nineteen non-merge commits after `v1.14`, including the shipped v1.15 client-auth work
- the package and release metadata still do not match the public support posture

Do not surface this seed merely because “a lot changed.” Surface it when the repo can make one coherent public release claim and the trusted publish lane is the main remaining step.
