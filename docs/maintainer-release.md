# Maintainer And Release Guide

Lockspire release work should stay boring, reviewable, tied to repo truth, and inside the 1.0 GA support contract defined in `docs/supported-surface.md`.

This guide is maintainer-only release operations guidance. It does not define a second public support contract.
For DCR/logout wording in release notes or release review, defer to the canonical support contract in `docs/supported-surface.md` rather than restating a separate support matrix here. The same rule applies to `client_secret_jwt`: this guide can acknowledge the shipped narrow direct-client slice, but the canonical support contract and the dedicated host guide own the exact support wording.
The same rule applies to advanced setup claims such as mTLS and protected-route support: release notes and maintainer review can point to `docs/supported-surface.md`, `docs/mtls-host-guide.md`, and `docs/protect-phoenix-api-routes.md`, but should not invent broader trust equivalence, automatic proxy trust, or generic deployment automation language here. Canonical wording enforcement belongs in the proof-focused contract tests and should stay there rather than being redefined in this guide.

## Normal flow

Run the repo hygiene gate before opening release-prep cleanup or trying to cut a release:

```bash
./scripts/maintainer/repo_hygiene_check.sh
```

Treat `PASS` as ready, `WARN` as triage required, and `BLOCK` as stop-and-fix. If you already have fresh contributor-gate evidence for the exact branch, you can skip the local rerun with `./scripts/maintainer/repo_hygiene_check.sh --skip-mix-ci`.

1. Merge reviewed changes to `main`.
2. Let Release Please open or update the release PR.
3. Treat the Release Please PR as review-only evidence, not authenticated release proof.
4. Review the release PR diff, `mix.exs`, `CHANGELOG.md`, and the workflow/config artifacts that define the release lane.
5. Merge the release PR.
6. Let the Release workflow cross the `hex-publish` environment boundary on `main` automatically, without a reviewer gate.
7. Treat the resulting protected workflow run as the only authoritative proof of authenticated `mix release.preflight` and `mix hex.publish --yes`.

Checked-in proof stops at the merged release commit plus the repo-owned workflow and docs. Protected-environment proof starts only when the `publish` job in `.github/workflows/release.yml` enters the `hex-publish` environment.
Normal releases on `main` should auto-publish once the Release Please PR is merged. `workflow_dispatch` remains recovery-only, but recovery should also cross `hex-publish` without a manual approval step.

## Evidence boundaries

Keep release evidence in three separate buckets:

- Repo-owned proof: `.github/workflows/release.yml`, `.github/actions/release-please/action.yml`, `docs/maintainer-release.md`, and `test/lockspire/release_readiness_contract_test.exs` define the canonical lane and should stay reviewable in git.
- GitHub settings proof: the live `hex-publish` environment settings prove branch restriction to `main`, admin-bypass posture, and environment-secret placement.
- Workflow-run proof: one successful `hex-publish` workflow run proves the trusted job actually crossed the protected secret boundary and executed `mix release.preflight` followed by `mix hex.publish --yes`.

Public release claims stay anchored to `docs/supported-surface.md` plus the checked-in artifact chain (`mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`). GitHub settings and workflow-run evidence support that story, but they do not replace the canonical support contract.

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

Keep the Release Please invocation repo-controlled. `.github/workflows/release.yml` should call `./.github/actions/release-please`, and that checked-in action should remain the only implementation detail between the workflow contract and the upstream `release-please` runtime.

## Maintainer-only release gate

`mix release.preflight` stays additive to `mix ci`. It is not a second contributor command and it should remain limited to the trusted publish path.

`mix package.publish-dry-run` remains a required release gate, but it is enforced from the trusted release workflow where `HEX_API_KEY` is available. It is not a manual local verification requirement for contributor closure.

If `workflow_dispatch` is used, treat it as recovery-only. It is not a normal publish trigger, it does not replace the Release Please driven path, and it must target the exact commit SHA or tag being recovered.

## Release candidate checklist

Before merging a Release Please PR for the root package, confirm this checked-in release-candidate contract end to end:

1. Run `mix ci` on the candidate revision.
2. Review `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` together so version, package metadata, and release notes describe one embedded-library release story.
3. Review `release-please-config.json` and confirm the root package still uses `component: "lockspire"`, `include-v-in-tag: true`, and `include-component-in-tag: true`.
4. Confirm the expected root release tag target is still `lockspire-v<version>` for the root package and matches the current `mix.exs` / manifest version.
5. Review `.github/workflows/release.yml` and confirm the only checked-in Release Please entry point is `uses: ./.github/actions/release-please`.
6. Confirm `.github/actions/release-please/action.yml` still preserves root outputs such as `tag_name` and `release_created`, because those outputs define which merged release commit is allowed to approach the protected publish lane.
7. Confirm `workflow_dispatch` remains recovery-only, requires both `recovery_reason` and `recovery_ref`, and is documented as replaying an exact immutable SHA or existing tag rather than creating a new publish intent.
8. Confirm the publish job still targets exactly one protected environment, `hex-publish`, and that checked-in proof stops there.
9. Confirm `docs/supported-surface.md` remains the canonical support contract and that this maintainer guide, `README`, and `SECURITY.md` only defer to it rather than creating a second support matrix.
10. Merge the reviewed Release Please PR and let the protected workflow run become the first authenticated evidence bucket.

Repo-owned commands stop at `mix ci` and the checked-in artifact review above. `mix release.preflight` and `mix hex.publish --yes` are trusted-workflow commands only; they belong to the protected `hex-publish` boundary, not to local maintainer folklore.

## Secrets and environment

- Use a protected `hex-publish` environment for publish jobs.
- Store `HEX_API_KEY` as an environment secret, not an inline workflow secret.
- Restrict the environment to deployments from `main`.
- Do not require environment reviewers for `hex-publish`; protection comes from environment scoping, branch restriction, and the checked-in workflow contract rather than a manual approval click.
- Keep workflow permissions minimal and publish jobs pinned to immutable action SHAs.
- Keep the authenticated dry-run inside the trusted workflow via `mix release.preflight`.
- If a merged release needs to be replayed after a workflow failure, use `workflow_dispatch` with both a recovery reason and the exact recovery ref so the protected publish lane replays the intended revision rather than whatever `main` points to later.
- Record protected-environment evidence separately from repo-owned proof: deployment restrictions, bypass posture, and environment-secret placement all live in GitHub settings rather than in the repo.

## Release posture

Releases should only claim the supported surface the repo can currently prove.

The repo should not claim full release readiness or broader protocol support until the docs, CI, support policy, and maintainer runbooks all agree with implemented behavior.

That means release posture must stay inside the embedded Phoenix library wedge already proven in-repo: authorization code + PKCE, discovery, JWKS, repo-proven `private_key_jwt` on Lockspire-owned direct-client endpoints, userinfo, revocation, introspection, refresh rotation, generator-backed install, and operator workflows. The same release posture can now also acknowledge the narrow `client_secret_jwt` direct-client slice documented in `docs/supported-surface.md` and `docs/client-secret-jwt-host-guide.md`.

Do not broaden release claims to request-object-by-value support, generic external request_uri handling, unsupported client-auth methods, hosted auth service language, certification language, demo-app proof, or full CIAM positioning. Generic JWT client-auth beyond the documented `client_secret_jwt` direct-client slice remains outside that release posture as well.

## Preflight checklist

Before merging a release PR, confirm:

- `./scripts/maintainer/repo_hygiene_check.sh`
- `mix ci`
- the Release Please PR is still review-only and points at the same release workflow/config artifacts
- `.github/workflows/release.yml` still calls `./.github/actions/release-please` rather than a direct third-party Release Please action reference
- `release-please-config.json` and `.release-please-manifest.json` still match the intended release policy
- publish job still targets the protected `hex-publish` environment
- trusted release workflow still runs `mix release.preflight`
- trusted publish lane still runs `mix hex.publish --yes`
- public docs and `SECURITY.md` still defer to `docs/supported-surface.md`

## Hold points

Stop the release if:

- docs require claims the repo no longer proves
- package metadata or docs build drift from the release artifact
- a workflow change bypasses CODEOWNERS or dependency review
- CI stops being equivalent to the maintained `mix ci` contract
- the protected `hex-publish` environment stops being restricted to `main`, allows bypass you do not intend to allow, or stores `HEX_API_KEY` outside the environment boundary

This file does not broaden the Lockspire product contract. For public support truth, defer to `docs/supported-surface.md`.

## Post-Publish Verification

After a successful publish to Hex, you must verify the published artifact to guarantee "Install Truth". Run the post-publish script:

```bash
./scripts/publish/verify_install_truth.sh
```

This step verifies the published Hex artifact and docs against the canonical support contract and proves clean Phoenix installability.

## Hygiene Automation

The repo-owned hygiene gate lives at `./scripts/maintainer/repo_hygiene_check.sh`.

- Local mode checks git cleanliness, main divergence, worktree and branch clutter, open PR triage, recent GitHub workflow health, release metadata coherence, and optionally reruns `mix ci`.
- CI runs `./scripts/maintainer/repo_hygiene_check.sh --ci` to fence the repo-owned release truth that GitHub can prove without local state.
- Keep this command diagnostic-first. It should tell maintainers what to fix, not silently mutate branches or PR state.
