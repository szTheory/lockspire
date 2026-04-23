# Maintainer And Release Guide

Lockspire release work should stay boring, reviewable, and tied to repo truth.

## Normal flow

1. Merge reviewed changes to `main`.
2. Let Release Please open or update the release PR.
3. Treat the Release Please PR as review-only evidence, not authenticated release proof.
4. Review the release PR diff, `mix.exs`, `CHANGELOG.md`, and the workflow/config artifacts that define the release lane.
5. Merge the release PR.
6. Approve the protected `hex-publish` deployment when the Release workflow reaches the environment gate.
7. Treat the approved protected workflow run as the only authoritative proof of authenticated `mix release.preflight` and `mix hex.publish --yes`.

## Contributor gate

Contributors should have one canonical answer before merge: run `mix ci`.

`mix ci` is the maintained contributor lane and it covers:

- `mix qa`
- `mix docs.verify`
- `mix deps.audit`
- `mix package.build`
- `mix test.fast`
- `mix test.integration` (including the canonical onboarding and OIDC e2e proofs)
- `mix test.phase3`

CI may keep those checks split into separate jobs for cacheability and diagnostics, but that workflow still needs to remain mechanically equivalent to `mix ci`.

Release Please generated PR checks are informative review context. They are not authoritative release proof, because trusted proof starts only after merge in the protected `hex-publish` lane.

## Maintainer-only release gate

`mix release.preflight` stays additive to `mix ci`. It is not a second contributor command and it should remain limited to the trusted publish path.

`mix package.publish-dry-run` remains a required release gate, but it is enforced from the trusted release workflow where `HEX_API_KEY` is available. It is not a manual local verification requirement for contributor closure.

If `workflow_dispatch` is used, treat it as recovery-only. It is not a normal publish trigger and it does not replace the Release Please driven path.

## Secrets and environment

- Use a protected `hex-publish` environment for publish jobs.
- Store `HEX_API_KEY` as an environment secret, not an inline workflow secret.
- Keep workflow permissions minimal and publish jobs pinned to immutable action SHAs.
- Keep the authenticated dry-run inside the trusted workflow via `mix release.preflight`.
- Record protected-environment evidence separately from repo-owned proof: required reviewers, no self-review, restricted deployment refs, and environment-secret placement all live in GitHub settings rather than in the repo.

## Release posture

Preview releases should only claim the supported surface the repo can currently prove.

The repo should not claim full release readiness or broader protocol support until the docs, CI, support policy, and maintainer runbooks all agree with implemented behavior.

## Preflight checklist

Before merging a release PR, confirm:

- `mix ci`
- the Release Please PR is still review-only and points at the same release workflow/config artifacts
- workflow files still use pinned action SHAs
- publish job still targets the protected `hex-publish` environment
- trusted release workflow still runs `mix release.preflight`
- public docs and `SECURITY.md` still match the supported surface

## Hold points

Stop the release if:

- docs require claims the repo no longer proves
- package metadata or docs build drift from the release artifact
- a workflow change bypasses CODEOWNERS or dependency review
- CI stops being equivalent to the maintained `mix ci` contract
- the protected `hex-publish` deployment no longer requires explicit reviewer approval or stores `HEX_API_KEY` outside the environment boundary
