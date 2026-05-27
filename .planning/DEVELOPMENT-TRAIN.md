# Lockspire Development Train

Lockspire uses two lanes after the `1.1.0` GA release:

- The sustaining release train keeps `main` green and lets patch-eligible changes flow through Release Please.
- The milestone development train gives future feature work a reviewable GSD branch and one PR back to `main`.

This document defines the feature-development lane. Release publication remains owned by `.planning/RELEASE-TRAIN.md` and the repo-controlled Release Please workflow.

## Default Posture

`main` is the release-train source of truth. Do not run open-ended feature work directly on `main`.

Patch/support/release-hygiene changes may use ordinary PRs when they do not widen Lockspire's public support contract or embedded-library scope. New feature work uses a milestone branch and one milestone PR.

## Milestone PR Shape

Use one branch and one PR per feature milestone.

- Branch name: `milestone/vNEXT-short-slug`
- PR target: `main`
- GSD state: active only on the milestone branch
- Merge condition: milestone audit, verification evidence, `mix ci`, and GitHub PR checks all pass

Examples:

- `milestone/v1.26-adopter-support-wedge`
- `milestone/v1.27-protocol-feature`

Do not create a separate release branch for feature work. After the milestone PR merges to `main`, Release Please decides the release PR from merged commits and checked-in release config.

## When To Use A Milestone PR

Open a milestone PR for work that changes Lockspire beyond normal sustainment:

- New protocol families or endpoint surfaces
- Host seam expansion
- Material operator or admin workflow breadth
- Wider public support, topology, or trust claims
- Feature work large enough to need multiple GSD phases or plans

Keep using ordinary patch PRs for:

- Bug fixes on shipped behavior
- Docs or support-truth corrections that narrow drift without widening claims
- CI, release-hygiene, and maintainer-runbook hardening
- Narrow hardening on already-supported surfaces

## Workflow

1. Start from clean, green `main`.
2. Run `./scripts/maintainer/repo_hygiene_check.sh` before opening the milestone branch.
3. Create `milestone/vNEXT-short-slug` from `main`.
4. Use GSD on the milestone branch to create requirements, roadmap, phases, plans, verification, and audit artifacts.
5. Execute milestone phases on the milestone branch. Keep task commits reviewable and tied to phase evidence.
6. Open one PR from the milestone branch to `main` when the milestone is implementation-complete.
7. Before merge, confirm `mix ci`, GitHub PR checks, GSD verification, and milestone audit are green.
8. Merge the milestone PR to `main`.
9. Let Release Please update or open the release PR from `main`.
10. After any real publish, update `.planning/RELEASE-TRAIN.md` with protected publish and install-truth proof.

## Merge Gate

A milestone PR is mergeable only when all of these are true:

- GSD phase summaries exist for every planned phase.
- Milestone verification and audit artifacts are present and passing.
- `mix ci` passes on the candidate revision.
- GitHub PR checks pass.
- Public support wording still defers to `docs/supported-surface.md`.
- The PR does not bypass Release Please or create a manual release path.

## Release Boundary

Milestone PRs deliver product changes to `main`; they do not publish packages by themselves.

Release Please remains the normal release-intent mechanism. The trusted `hex-publish` lane starts only after the Release Please PR merges to `main`, as described in `.planning/RELEASE-TRAIN.md` and `docs/maintainer-release.md`.

## Standing Assumptions

- Future feature milestones remain welcome when there is concrete adopter, support, trust, or product evidence.
- `milestone: none` remains the normal idle state between feature milestones.
- GSD planning artifacts may live on milestone branches before merge.
- Patch train work should not be inflated into a milestone unless it changes scope, support truth, or public contract.
