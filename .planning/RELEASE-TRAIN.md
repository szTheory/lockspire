# Lockspire Release Train

Lockspire is on a sustaining GA release train.

The default operating mode is not "find the next milestone." The default is: keep `main` green, keep release truth coherent, and let patch-eligible merged changes ride the maintained automated release lane. When future feature work is justified, use the milestone PR lane in `.planning/DEVELOPMENT-TRAIN.md`.

## Current Baseline

- Latest released version: `1.1.1`
- Release date: `2026-05-27`
- Protected publish proof: GitHub Actions run `26497862703` succeeded end to end on the trusted `hex-publish` environment.
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.1.1` on `2026-05-27`.

## Normal Train Rules

- `milestone: none` remains the default GSD state.
- Patch-eligible merged changes should flow to the next release through Release Please on `main`.
- The train is ready to move only when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` passes without `BLOCK`.
- `workflow_dispatch` is exact-ref only for release automation or recovery and must replay an exact immutable ref; it does not create a new release intent.
- Eligible Release Please PRs should auto-merge only after green `main` CI and only through the guarded Release Please branch/title/file allowlist.

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
