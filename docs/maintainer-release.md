# Maintainer And Release Guide

Lockspire release work should stay boring, reviewable, tied to repo truth, and inside the 1.0 GA support contract defined in `docs/supported-surface.md`.

## Repository evidence policy

`tmp/admin-ui-polish/*.png` is retained, repo-only milestone evidence. Images
must use demo data or be redaction-safe, must never be imported by runtime code
or package inputs, and may be replaced only when a newer inventory supersedes
them. Before deleting an image, update every retained evidence matrix that
references it. Generated build outputs, logs, dependency directories, and
one-off debug scripts are not durable evidence and must remain untracked.

Lockspire now operates on a sustaining release train by default. That means the normal posture is not "open the next milestone"; it is "keep `main` green, keep release truth coherent, and let patch-eligible merged changes flow toward the next patch release."

This guide is maintainer-only release operations guidance. It does not define a second public support contract.
For DCR/logout wording in release notes or release review, defer to the canonical support contract in `docs/supported-surface.md` rather than restating a separate support matrix here. The same rule applies to `client_secret_jwt`: this guide can acknowledge the shipped narrow direct-client slice, but the canonical support contract and the dedicated host guide own the exact support wording.
The same rule applies to advanced setup claims such as mTLS and protected-route support: release notes and maintainer review can point to `docs/supported-surface.md`, `docs/mtls-host-guide.md`, and `docs/protect-phoenix-api-routes.md`, but should not invent broader trust equivalence, automatic proxy trust, or generic deployment automation language here. Canonical wording enforcement belongs in the proof-focused contract tests and should stay there rather than being redefined in this guide.

## Normal flow

Run the repo hygiene gate before opening release-prep cleanup or trying to cut a release:

```bash
./scripts/maintainer/repo_hygiene_check.sh
```

Treat `PASS` as ready, `WARN` as triage required, and `BLOCK` as stop-and-fix. If you already have fresh contributor-gate evidence for the exact branch, you can skip the local rerun with `./scripts/maintainer/repo_hygiene_check.sh --skip-mix-ci`.

The standing release-train ledger lives in `.planning/RELEASE-TRAIN.md`. Update it after every real publish so the next maintainer inherits concrete proof instead of oral history.

1. Merge reviewed changes to `main`.
2. Let Release Please open or update the release PR.
3. Treat the Release Please PR as review-only evidence, not authenticated release proof.
4. Review the release PR diff, `mix.exs`, `CHANGELOG.md`, and the workflow/config artifacts that define the release lane.
5. Let `.github/workflows/release-please-automerge.yml` squash-merge an eligible bot Release Please PR after green `main` CI, or manually merge it if the guard does not apply.
6. Wait for the merge commit's own successful `CI` push run on the current `main` head. That exact run dispatches the trusted release lane with its SHA and run ID; the pre-merge CI run is never publish evidence.
7. Let the validator confirm the exact immutable main SHA, matching successful CI run, and repository identity.
8. Let the unprivileged prepublish job build one tar, bind it to a redacted manifest, and prove that local tar through the clean-room SaaS HTTP journey.
9. Let the protected publisher validate and consume that same SHA-bound artifact; it must not rebuild release intent from a moving branch.
10. Treat the resulting protected GitHub release, Hex checksum proof, exact-version public HTTP journey, and bounded evidence artifact as the authoritative release record.

Checked-in proof stops at the merged release commit plus the repo-owned workflow and docs. Protected-environment proof starts only when the `publish` job in `.github/workflows/release.yml` enters the `hex-publish` environment.
Normal releases maintain the Release Please PR on `main` pushes. After the repository token merges a Release Please PR, automation explicitly dispatches canonical CI for that exact current main SHA because token-authored merges do not recursively emit push workflows. A successful canonical CI run—either a normal `push` or that bounded `workflow_dispatch`—then dispatches publish. Recovery needs the same full SHA, successful CI run ID, and auditable reason; it cannot publish a tag, a stale SHA, or a pre-merge run.

## Evidence boundaries

Keep release evidence in three separate buckets:

- Repo-owned proof: `.github/workflows/release.yml`, `.github/workflows/release-please-automerge.yml`, `.github/actions/release-please/action.yml`, `docs/maintainer-release.md`, and `test/lockspire/release_readiness_contract_test.exs` define the canonical lane and should stay reviewable in git.
- GitHub settings proof: the live `hex-publish` environment settings prove branch restriction to `main`, admin-bypass posture, and environment-secret placement.
- Workflow-run proof: the single-artifact chain retains a schema-versioned manifest plus bounded prepublish/postpublish receipts. The manifest binds source SHA, package version, tar checksum and byte size, and pinned Elixir/OTP/Mix/Hex/Phoenix/LiveView/PostgreSQL versions. Raw OAuth journey logs, process configuration, and secrets are never uploaded.

Public release claims stay anchored to `docs/supported-surface.md` plus the checked-in artifact chain (`mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`). GitHub settings and workflow-run evidence support that story, but they do not replace the canonical support contract.

## Contributor gate

Contributors should have one canonical answer before merge: run `mix ci`.

`mix ci` is the maintained contributor lane and it covers:

- `mix qa` for format, warnings-as-errors compile, Credo, and Sobelow
- `mix docs.verify`
- `mix deps.audit`
- `mix package.build`
- `mix test.fast`
- `mix test.integration` (including the canonical onboarding and OIDC e2e proofs)
- `mix test.phase3`

CI may keep those checks split into separate jobs for cacheability and diagnostics, but that workflow still needs to remain mechanically equivalent to `mix ci`.

Dialyzer is a required, cached PR CI job with a zero-warning baseline and no warning suppression. It remains available locally as `mix qa.dialyzer` and stays separate from the faster `mix ci` contributor loop so the expensive type proof is explicit and independently diagnosable.

Release Please generated PR checks are informative review context. They are not authoritative release proof, because trusted proof starts only after merge in the protected `hex-publish` lane.

Keep the Release Please invocation repo-controlled. `.github/workflows/release.yml` should call `./.github/actions/release-please`, and that checked-in action should remain the only implementation detail between the workflow contract and the upstream `release-please` runtime.

## Maintainer-only release gate

`mix release.preflight` stays additive to `mix ci`. It is not a second contributor command; release automation runs it at the exact verified SHA before the secret-bearing environment and binds its tar output to the retained manifest.

`mix package.publish-dry-run` remains a required release gate through `mix release.preflight`. It does not require the publish secret and is not a manual local verification requirement for contributor closure.

If `workflow_dispatch` is used, treat it as exact-ref only. It is not a new release-intent trigger, it does not replace the Release Please driven path, and it must target the exact commit SHA or tag being published by release automation or recovered by a maintainer.

## Sustaining release train

The default train rules are:

- patch-eligible merged changes on shipped surfaces should ride the next patch release
- the train moves only from green `main`
- `./scripts/maintainer/repo_hygiene_check.sh` is the maintainer readiness gate
- `workflow_dispatch` is exact-ref only for release automation or recovery
- anything that widens Lockspire's support boundary or product scope should become a new milestone rather than an opportunistic patch release

## Release candidate checklist

Before merging a Release Please PR for the root package, confirm this checked-in release-candidate contract end to end. The auto-merge workflow uses the latest successful `main` CI as the contributor gate for the release candidate because the Release Please PR is generated by `GITHUB_TOKEN` and contains only release metadata files.

1. Confirm latest `main` CI is green; if merging manually because the guard does not apply, run `mix ci` or review equivalent fresh CI evidence.
2. Review `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` together so version, package metadata, and release notes describe one embedded-library release story.
3. Review `release-please-config.json` and confirm the root package still uses `component: "lockspire"`, `include-v-in-tag: true`, and `include-component-in-tag: true`.
4. Confirm the expected root release tag target is still `lockspire-v<version>` for the root package and matches the current `mix.exs` / manifest version.
5. Review `.github/workflows/release.yml` and confirm the only checked-in Release Please entry point is `uses: ./.github/actions/release-please`.
6. Confirm `.github/actions/release-please/action.yml` still preserves root outputs such as `tag_name` and `release_created`, because those outputs define which merged release commit is allowed to approach the protected publish lane.
7. Confirm `workflow_dispatch` remains exact-ref only, requires both `recovery_reason` and `recovery_ref`, and is documented as publishing an exact immutable SHA or existing tag rather than creating a new release intent.
8. Confirm the publish job still targets exactly one protected environment, `hex-publish`, and that checked-in proof stops there.
9. Confirm `docs/supported-surface.md` remains the canonical support contract and that this maintainer guide, `README`, and `SECURITY.md` only defer to it rather than creating a second support matrix.
10. Let the guarded auto-merge workflow merge the reviewed Release Please PR, or merge it manually if the guard does not apply, and let the protected workflow run become the first authenticated evidence bucket.

Repo-owned commands stop at `mix ci` and the checked-in artifact review above. `mix release.preflight` and the exact-tar Hex upload are release-workflow commands only; publication belongs to the protected `hex-publish` boundary, not to local maintainer folklore.

## Secrets and environment

- Use a protected `hex-publish` environment for publish jobs.
- Store `HEX_API_KEY` as an environment secret, not an inline workflow secret.
- Restrict the environment to deployments from `main`.
- Do not require environment reviewers for `hex-publish`; protection comes from environment scoping, branch restriction, and the checked-in workflow contract rather than a manual approval click.
- Keep workflow permissions minimal and publish jobs pinned to immutable action SHAs.
- Keep `HEX_API_KEY` available only to the protected publish step. The prepublish clean-room proof and postpublish public verification stay unprivileged.
- Configure the `hex-publish` environment to serialize and restrict publication from `main`; the workflow's release concurrency remains non-canceling.
- If a merged release needs to be replayed after a workflow failure, use `workflow_dispatch` with both a recovery reason and the exact recovery ref so the protected publish lane replays the intended revision rather than whatever `main` points to later.
- Record protected-environment evidence separately from repo-owned proof: deployment restrictions, bypass posture, and environment-secret placement all live in GitHub settings rather than in the repo.

## Release posture

Releases should only claim the supported surface the repo can currently prove.

The repo should not claim full release readiness or broader protocol support until the docs, CI, support policy, and maintainer runbooks all agree with implemented behavior.

That means release posture must stay inside the embedded Phoenix library wedge already proven in-repo: authorization code + PKCE, PAR, JAR request objects by value on the shipped `/authorize` and `/par` paths, discovery, JWKS, repo-proven `private_key_jwt` on Lockspire-owned direct-client endpoints, userinfo, revocation, introspection, refresh rotation, generator-backed install, and operator workflows. The same release posture can now also acknowledge the narrow `client_secret_jwt` direct-client slice documented in `docs/supported-surface.md` and `docs/client-secret-jwt-host-guide.md`.

Do not broaden release claims to external JAR-by-reference, generic external request_uri handling, unsupported client-auth methods, hosted auth service language, certification language, demo-app proof, or full CIAM positioning. Generic JWT client-auth beyond the documented `client_secret_jwt` direct-client slice remains outside that release posture as well.

## Preflight checklist

Before merging a release PR, confirm:

- `./scripts/maintainer/repo_hygiene_check.sh`
- `mix ci`
- the Release Please PR is still review-only and points at the same release workflow/config artifacts
- `.github/workflows/release-please-automerge.yml` still limits auto-merge to the GitHub Actions bot Release Please branch, exact release title, and the `mix.exs` / `.release-please-manifest.json` / `CHANGELOG.md` file allowlist
- `.github/workflows/release.yml` still calls `./.github/actions/release-please` rather than a direct third-party Release Please action reference
- `release-please-config.json` and `.release-please-manifest.json` still match the intended release policy
- publish job still targets the protected `hex-publish` environment
- trusted release workflow still runs `mix release.preflight`
- trusted publish lane passes the manifest-verified tar bytes directly to `Hex.API.Release.publish/5` and uses `mix hex.publish docs --yes` only for documentation
- prepublish, protected publish, and postpublish jobs all carry the same verified SHA, manifest version, and tar checksum
- retained release evidence contains only the manifest and bounded JSON receipts, never raw journey logs
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

The release workflow automatically verifies the exact published artifact to guarantee "Install Truth". Its invocation is manifest-bound:

```bash
./scripts/publish/verify_install_truth.sh release-manifest.json <same-verified-sha> postpublish-receipt.json
```

The verifier polls only the release-specific Hex endpoint with bounded retries,
requires the public checksum to equal the reviewed tar, checks versioned
HexDocs, and fetches that exact public version into the clean-room SaaS HTTP
journey. A checksum mismatch is an immediate hard failure: stop, preserve the
bounded evidence, and investigate registry/source identity. Do not republish or
replace a public version opportunistically.

Recovery must reuse the same verified SHA, successful source CI run ID,
version, and manifest-bound artifact. Re-dispatch with an auditable recovery
reason; never rebuild from the current branch or substitute a new tar. Runtime
and tool versions in the manifest describe the prepublish builder used for the
reviewed bytes. They are reproducibility evidence, not a claim that every host
must run those exact versions.

The final `release-evidence-<sha>` artifact has explicit retention and contains
only `release-manifest.json`, `prepublish-receipt.json`, and, after public proof
succeeds, `postpublish-receipt.json`. Workflow console output remains ephemeral
and must already be redacted by the clean-room runner.

After that verification passes, record the shipped version, publish proof, and install-truth proof in `.planning/RELEASE-TRAIN.md`.

## Hygiene Automation

The repo-owned hygiene gate lives at `./scripts/maintainer/repo_hygiene_check.sh`.

- Local mode checks git cleanliness, main divergence, worktree and branch clutter, open PR triage, recent GitHub workflow health, release metadata coherence, and optionally reruns `mix ci`.
- CI runs `./scripts/maintainer/repo_hygiene_check.sh --ci` to fence the repo-owned release truth that GitHub can prove without local state, including the standing release-train ledger.
- Keep this command diagnostic-first. It should tell maintainers what to fix, not silently mutate branches or PR state.
