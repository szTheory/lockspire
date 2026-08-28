# Lockspire Release Train

Lockspire is on a sustaining GA release train.

The default operating mode is not "find the next milestone." The default is: keep `main` green, keep release truth coherent, and let patch-eligible merged changes ride the maintained automated release lane. When future feature work is justified, use the milestone PR lane in `.planning/DEVELOPMENT-TRAIN.md`.

## Current Baseline

- Latest released version: `1.5.0` <!-- x-release-please-version -->
- Release date: `2026-08-28` <!-- x-release-please-date -->
- Protected publish proof: GitHub Actions run `30386337705` succeeded end to end on the trusted `hex-publish` environment, publishing the merged release commit `ee32dbd` from the push-triggered lane.
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.4.0` on `2026-07-28`, resolving and compiling a clean-room Phoenix host app against the published package.
- GitHub release truth: `lockspire-v1.4.0` was created on `2026-07-28` at `ee32dbd`, after Release Please auto-merged the `1.4.0` release PR (#79) on `main`. No backfill was needed.
- Release Please bookkeeping: the publish job now advances the merged release PR's `autorelease:` label itself (#78). Before that fix the label stayed `pending`, and Release Please aborted every later run with "There are untagged, merged release PRs outstanding", silently proposing no further releases. #79 was labelled `autorelease: tagged` automatically, confirming the fix end to end.

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

As of 2026-07-28, `main` is at the `1.4.0` release commit `ee32dbd` and the latest public release is `1.4.0`. That release carried the host-owned demo 404 page and working Disconnect (#75), the remembered-consent duplication fix (#77), the `phoenix_live_view` range widening (#76), and the Release Please unblock (#78).
