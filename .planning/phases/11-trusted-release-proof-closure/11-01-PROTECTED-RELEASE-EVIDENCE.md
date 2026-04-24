# Phase 11 Plan 01 Protected Release Evidence

Status: passed
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

- Repository: `szTheory/lockspire`
- Environment URL: `https://github.com/szTheory/lockspire/deployments/activity_log?environments_filter=hex-publish`
- Exists: yes
- Created At: `2026-04-23T21:55:10Z`
- Updated At: `2026-04-24T09:17:15Z`
- Deployment restriction posture: custom branch policies enabled; deployments restricted to `main`
- Branch policy API evidence: `gh api repos/szTheory/lockspire/environments/hex-publish/deployment-branch-policies` returned only `main`
- Admin-bypass posture: disabled (`can_admins_bypass=false`)
- Reviewer protection posture: present; `gh api -X PUT repos/szTheory/lockspire/environments/hex-publish` configured `required_reviewers` for user `szTheory` (`id=28652`)
- Reviewer rule API evidence: `gh api repos/szTheory/lockspire/environments/hex-publish` now returns `required_reviewers` plus `branch_policy`
- Self-review posture: allowed (`prevent_self_review=false`) for the configured `szTheory` reviewer
- Environment secret posture: `HEX_API_KEY` exists as an environment secret
- Secret API evidence: `gh api repos/szTheory/lockspire/environments/hex-publish/secrets` returned `HEX_API_KEY` with `created_at=2026-04-23T21:55:34Z`

## Approved Protected Publish Run Proof

- Workflow: Release
- Run ID: 24882045589
- Run URL: https://github.com/szTheory/lockspire/actions/runs/24882045589
- Trigger Event: push
- Head Branch: `main`
- Commit SHA: e42055f7f1ff17bd69733119862e251588e56b3f
- Display Title: `Merge pull request #7 from szTheory/release-please--branches--main--components--lockspire`
- Release PR: `#7`
- Release Version: `0.2.0`
- Run Started At: `2026-04-24T09:18:15Z`
- Run Completed At: `2026-04-24T09:19:09Z`
- Publish Job: `Publish to Hex`
- Publish Job URL: `https://github.com/szTheory/lockspire/actions/runs/24882045589/job/72852673899`
- Environment: hex-publish
- Approval State: approved
- Approval Evidence:
  - Deployment `4471851825` entered `waiting` at `2026-04-24T09:18:29Z`
  - `gh api -X POST repos/szTheory/lockspire/actions/runs/24882045589/pending_deployments` approved environment `14515201466`
  - Deployment moved to `in_progress` at `2026-04-24T09:18:46Z`
- Approved At: `2026-04-24T09:18:46Z`
- Trusted command proof:
  - `gh run view 24882045589 --job 72852673899 --log` shows `mix release.preflight` under the `Run trusted release preflight inside protected environment` step from `2026-04-24T09:19:00Z` to `2026-04-24T09:19:02Z`
  - the same log shows `mix hex.publish --yes` under the `Publish package from the trusted lane` step from `2026-04-24T09:19:02Z` to `2026-04-24T09:19:05Z`
  - the publish log records `Package published to https://hex.pm/packages/lockspire/0.2.0`

Non-canonical run note: `workflow_dispatch` run `24869621652` exists, but it is recovery-only and cannot replace the normal `push`-driven proof lane.

## Drift Reconciliation

No repo-owned release-lane drift required correction after the environment repair and canonical rerun.

- `.github/workflows/release.yml` still defines the single canonical Release Please -> `push` on `main` -> `hex-publish` lane plus recovery-only `workflow_dispatch`.
- `docs/maintainer-release.md` still keeps repo-owned proof, GitHub settings proof, and workflow-run proof separate.
- `release-please-config.json` and `.release-please-manifest.json` still encode the checked-in release policy.
- `mix.exs` remains package truth and still defines `release.preflight` as `package.build`, `package.publish-dry-run`, and `docs.verify`.
- `test/lockspire/release_readiness_contract_test.exs` still fences the canonical release-lane invariants that the repo can prove.

The only drift was live-environment posture. Repo-owned workflow/docs/config truth already matched the intended lane; the missing piece was the reviewer-approval gate on `hex-publish`, which is now configured and exercised by the canonical run above.

## Closure Decision

Passed. Phase 11 Plan 01 now closes the protected-run proof gap for `RELS-01`: the live `hex-publish` environment requires reviewer approval, the canonical `Release` run `24882045589` on `push` to `main` recorded an explicit approval transition, and the protected publish job then executed `mix release.preflight` followed by `mix hex.publish --yes` successfully.
