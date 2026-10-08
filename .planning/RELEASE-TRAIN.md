# Lockspire Release Train

Lockspire is on a sustaining GA release train.

The default operating mode is not "find the next milestone." The default is: keep `main` green, keep release truth coherent, and let patch-eligible merged changes ride the maintained automated release lane. When future feature work is justified, use the milestone PR lane in `.planning/DEVELOPMENT-TRAIN.md`.

## Current Baseline

- Release Please version metadata: `1.5.2` <!-- x-release-please-version -->
- Release Please date metadata: `2026-10-08` <!-- x-release-please-date -->
- Latest public package: Hex lists `1.5.0` as latest at the 2026-10-05 closure observation; the exact `1.5.1` release query returned HTTP 404. Release Please metadata above is not publication proof.
- Published source: `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; canonical CI run `33141161205` passed and protected `workflow_dispatch` run `33141484467` published successfully for this same SHA.
- Artifact truth: the published `lockspire-1.5.0` package checksum is `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`; the protected release run verified the exact package and public install journey.
- GitHub release truth: [lockspire-v1.5.0](https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0) was created on `2026-08-28` for the source used by release run `33141484467`, after Release Please auto-merged release PR #93.
- Phase 141 planning completion and Phase 140's accepted source SHA do not represent a new package publication. See the [dated Phase 141 baseline](milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md) for observation times, same-SHA acceptance, links, and evidence boundaries.
- Release Please bookkeeping: the publish job now advances the merged release PR's `autorelease:` label itself (#78). Before that fix the label stayed `pending`, and Release Please aborted every later run with "There are untagged, merged release PRs outstanding", silently proposing no further releases. #79 was labelled `autorelease: tagged` automatically, confirming the fix end to end.

## Normal Train Rules

- `milestone: none` remains the default GSD state.
- Patch-eligible merged changes should flow to the next release through Release Please on `main`.
- The train is ready to move only when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` passes without `BLOCK`.
- `workflow_dispatch` is exact-ref only for release automation or recovery and must replay an exact immutable ref; it does not create a new release intent.
- Push-triggered Release Please manages release PRs only; it must not create GitHub releases directly because the exact-ref dispatch publish lane owns GitHub release/tag creation and Hex publish.
- `workflow_dispatch` validates and publishes one exact lowercase 40-hex commit equal to current `origin/main`, backed by its matching successful canonical CI run; a push never enters the protected publication jobs.
- Eligible Release Please PRs should auto-merge only after green `main` CI and only through the guarded Release Please branch/title/file allowlist.
- Exact-ref dispatch publishes the manifest-verified package to Hex before creating or validating the matching `lockspire-v<version>` GitHub release, then verifies public install truth from the same SHA-bound artifact.
- Before starting a new milestone or cutting a release, run the reusable hygiene checklist in `.planning/REPO-HYGIENE-CHECKLIST.md`.

## Patch-Eligible Change Classes

- Bug fixes on shipped behavior
- Docs or support-truth corrections that narrow drift without widening claims
- Release-hygiene, CI-drift, or maintainer-runbook hardening
- Narrow hardening on already-supported surfaces that does not expand the embedded-library contract

## Work That Requires A New Milestone

- New protocol families or endpoint surfaces
- Wider public support claims or topology claims
- Host seam expansion
- Material operator/admin breadth
- Anything that changes Lockspire's embedded-library scope instead of sustaining it

Feature milestones should run on `milestone/vNEXT-short-slug` branches and merge through one PR to `main` after GSD verification, milestone audit, `mix ci`, and GitHub PR checks pass. Do not create manual release branches for feature milestones; after merge, Release Please owns the normal release PR.

## Next Cut Condition

Cut the next patch release when there is at least one merged patch-eligible change on `main`, canonical CI is green for the exact current `origin/main` commit, the repo hygiene gate reports no `BLOCK`, and release truth still points to `docs/supported-surface.md` as the canonical contract.

## Current Main Readiness

At the 2026-10-05 Phase 140 terminal acceptance, the accepted source was `877a0f758aa0bbd5433cbe3d70f1476fa0e12223`; required CI run `37354878786` passed all seven required jobs and Release run `37354878693` succeeded with the protected publication jobs skipped. This is current repository-baseline evidence, not a package release. The latest evidenced public release remains `1.5.0` from source `5d10ce2219c2e687cf9573c8b280abfb118a47d8`, as detailed in the Current Baseline and the [Phase 141 baseline](milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md).
