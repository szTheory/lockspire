# Lockspire Release Train

Lockspire is on a sustaining GA release train.

The default operating mode is not "find the next milestone." The default is: keep `main` green, keep release truth coherent, and let patch-eligible merged changes ride the maintained automated release lane. When future feature work is justified, use the milestone PR lane in `.planning/DEVELOPMENT-TRAIN.md`.

## Current Baseline

- Latest released version: `1.3.0`
- Release date: `2026-07-28`
- Protected publish proof: GitHub Actions run `30323976705` succeeded end to end on the trusted `hex-publish` environment, publishing from the exact-ref dispatch lane at `197608f`.
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.3.0` on `2026-07-28`.
- GitHub release truth: `lockspire-v1.3.0` was created on `2026-07-28` at `197608f` by the exact-ref dispatch publish lane, after Release Please auto-merged the `1.3.0` release PR (#71) on `main`. No backfill was needed.

## Normal Train Rules

- `milestone: none` remains the default GSD state.
- Patch-eligible merged changes should flow to the next release through Release Please on `main`.
- The train is ready to move only when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` passes without `BLOCK`.
- `workflow_dispatch` is exact-ref only for release automation or recovery and must replay an exact immutable ref; it does not create a new release intent.
- Push-triggered Release Please manages release PRs only; it must not create GitHub releases directly because the exact-ref dispatch publish lane owns GitHub release/tag creation and Hex publish.
- Push-triggered Hex publish remains guarded by Release Please release-SHA equality with the current `main` push SHA as a stale-event defense, but normal automated publishing should happen through the auto-merge workflow's exact-ref dispatch.
- Eligible Release Please PRs should auto-merge only after green `main` CI and only through the guarded Release Please branch/title/file allowlist.
- Exact-ref dispatch publish must ensure the matching `lockspire-v<version>` GitHub release exists before Hex publish so GitHub release truth, changelog links, tags, Hex, and HexDocs stay coherent.
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

Cut the next patch release when there is at least one merged patch-eligible change on `main`, the latest `main` CI is green, the repo hygiene gate reports no `BLOCK`, and release truth still points to `docs/supported-surface.md` as the canonical contract.

## Current Main Readiness

As of 2026-07-01, `main` includes the v1.33-v1.35 readiness work from PR #58 at `9fb219b`. No new Hex release was published by this hygiene checkpoint; the latest public release remains `1.2.0`.
