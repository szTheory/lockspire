# Maintainer And Release Guide

Lockspire release work should stay boring, reviewable, tied to repo truth, and inside the `v0.1` preview support contract defined in `docs/supported-surface.md`.

## Normal flow

1. Merge reviewed changes to `main`.
2. Let Release Please open or update the release PR.
3. Treat the Release Please PR as review-only evidence, not authenticated release proof.
4. Review the release PR diff, `mix.exs`, `CHANGELOG.md`, and the workflow/config artifacts that define the release lane.
5. Merge the release PR.
6. Let the Release workflow cross the `hex-publish` environment boundary on `main`.
7. Treat the resulting protected workflow run as the only authoritative proof of authenticated `mix release.preflight` and `mix hex.publish --yes`.

## Evidence boundaries

Keep release evidence in three separate buckets:

- Repo-owned proof: `.github/workflows/release.yml`, `docs/maintainer-release.md`, and `test/lockspire/release_readiness_contract_test.exs` define the canonical lane and should stay reviewable in git.
- GitHub settings proof: the live `hex-publish` environment settings prove branch restriction to `main`, admin-bypass posture, and environment-secret placement.
- Workflow-run proof: one successful `hex-publish` workflow run proves the trusted job actually crossed the protected secret boundary and executed `mix release.preflight` followed by `mix hex.publish --yes`.

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
- Restrict the environment to deployments from `main`.
- Keep workflow permissions minimal and publish jobs pinned to immutable action SHAs.
- Keep the authenticated dry-run inside the trusted workflow via `mix release.preflight`.
- If a merged release needs to be replayed after a workflow failure, use `workflow_dispatch` with a recovery reason to rerun the same protected publish lane.
- Record protected-environment evidence separately from repo-owned proof: deployment restrictions, bypass posture, and environment-secret placement all live in GitHub settings rather than in the repo.

## Release posture

Preview releases should only claim the supported surface the repo can currently prove.

The repo should not claim full release readiness or broader protocol support until the docs, CI, support policy, and maintainer runbooks all agree with implemented behavior.

That means release posture must stay inside the embedded Phoenix library wedge already proven in-repo: authorization code + PKCE, discovery, JWKS, userinfo, revocation, introspection, refresh rotation, generator-backed install, and operator workflows.

Do not broaden release claims to PAR, device flow, dynamic client registration, hosted auth service language, certification language, demo-app proof, or full CIAM positioning.

## Preflight checklist

Before merging a release PR, confirm:

- `mix ci`
- the Release Please PR is still review-only and points at the same release workflow/config artifacts
- `release-please-config.json` and `.release-please-manifest.json` still match the intended preview release policy
- publish job still targets the protected `hex-publish` environment
- trusted release workflow still runs `mix release.preflight`
- trusted publish lane still runs `mix hex.publish --yes`
- public docs and `SECURITY.md` still match the supported surface

## Hold points

Stop the release if:

- docs require claims the repo no longer proves
- package metadata or docs build drift from the release artifact
- a workflow change bypasses CODEOWNERS or dependency review
- CI stops being equivalent to the maintained `mix ci` contract
- the protected `hex-publish` environment stops being restricted to `main`, allows bypass you do not intend to allow, or stores `HEX_API_KEY` outside the environment boundary
