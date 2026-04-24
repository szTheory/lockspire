# Phase 11 Plan 01 Protected Release Evidence

Status: pending external proof
Environment: hex-publish
Requirements: RELS-01, RELS-02, RELS-03

## Repo Contract Snapshot

- Workflow: `Release`
- Canonical trigger path: `push` to `main` via Release Please
- Protected publish boundary: `hex-publish`
- Trusted commands:
  - `mix release.preflight`
  - `mix hex.publish --yes`
- Release policy files:
  - `release-please-config.json`
  - `.release-please-manifest.json`
- Package truth: `mix.exs`
- Repo-owned drift fence: `test/lockspire/release_readiness_contract_test.exs`

The checked-in contract remains one canonical publish lane: Release Please opens the review-only PR, merge to `main` triggers the `Release` workflow, and the `Publish to Hex` job crosses the protected `hex-publish` environment before running `mix release.preflight` and `mix hex.publish --yes`.

## Live GitHub Environment Proof

Pending live GitHub inspection for:

- Environment existence
- Deployment restriction posture for `main`
- Admin-bypass posture
- Reviewer/self-review posture
- `HEX_API_KEY` environment-secret placement

## Approved Protected Publish Run Proof

Pending live GitHub inspection for:

- Workflow name `Release`
- Run ID
- Run URL
- Trigger event
- Commit SHA
- Tag or release version, if present
- Publish job name
- Environment `hex-publish`
- Approval state
- Approval timestamp
- Proven command chain:
  - `mix release.preflight`
  - `mix hex.publish --yes`

## Drift Reconciliation

No repo-owned drift recorded yet. Reconcile only if live GitHub proof contradicts:

- `.github/workflows/release.yml`
- `docs/maintainer-release.md`
- `release-please-config.json`
- `.release-please-manifest.json`
- `mix.exs`
- `test/lockspire/release_readiness_contract_test.exs`

## Closure Decision

Pending external proof. Do not mark passed until the live `hex-publish` environment posture and one canonical approved protected `Release` workflow run are recorded with exact identifiers, timestamps, and the trusted command chain.
