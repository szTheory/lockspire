# Lockspire Release Train

Lockspire is on a sustaining GA release train.

The default operating mode is not "find the next milestone." The default is: keep `main` green, keep release truth coherent, and let patch-eligible merged changes ride the maintained automated release lane.

## Current Baseline

- Latest released version: `1.1.0`
- Release date: `2026-05-26`
- Protected publish proof: GitHub Actions run `26454274652` succeeded end to end on the trusted `hex-publish` environment.
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.1.0` on `2026-05-26`.

## Normal Train Rules

- `milestone: none` remains the default GSD state.
- Patch-eligible merged changes should flow to the next release through Release Please on `main`.
- The train is ready to move only when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` passes without `BLOCK`.
- `workflow_dispatch` is recovery-only and must replay an exact immutable ref; it does not create a new release intent.

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

## Next Cut Condition

Cut the next patch release when there is at least one merged patch-eligible change on `main`, the latest `main` CI is green, the repo hygiene gate reports no `BLOCK`, and release truth still points to `docs/supported-surface.md` as the canonical contract.
