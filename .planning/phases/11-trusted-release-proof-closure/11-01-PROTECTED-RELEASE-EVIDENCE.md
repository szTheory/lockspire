# Phase 11 Plan 01 Protected Release Evidence

Status: blocked
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
- Updated At: `2026-04-23T21:58:33Z`
- Deployment restriction posture: custom branch policies enabled; deployments restricted to `main`
- Branch policy API evidence: `gh api repos/szTheory/lockspire/environments/hex-publish/deployment-branch-policies` returned only `main`
- Admin-bypass posture: disabled (`can_admins_bypass=false`)
- Reviewer protection posture: absent; the environment `protection_rules` payload contains only `branch_policy`
- Self-review posture: not configurable because no required reviewers are configured on `hex-publish`
- Environment secret posture: `HEX_API_KEY` exists as an environment secret
- Secret API evidence: `gh api repos/szTheory/lockspire/environments/hex-publish/secrets` returned `HEX_API_KEY` with `created_at=2026-04-23T21:55:34Z`

Contradiction: the live `hex-publish` environment does not require reviewer approval, so it cannot produce the approved protected-run proof required for `RELS-01` closure.

## Approved Protected Publish Run Proof

- Workflow: Release
- Run ID: 24869779639
- Run URL: https://github.com/szTheory/lockspire/actions/runs/24869779639
- Trigger Event: push
- Head Branch: `main`
- Commit SHA: 159050a673489b6e7ad6c00908114e8b2d499489
- Display Title: `chore(main): release lockspire 0.1.2 (#6)`
- Run Started At: `2026-04-24T02:54:05Z`
- Run Completed At: `2026-04-24T02:55:31Z`
- Publish Job: `Publish to Hex`
- Publish Job URL: `https://github.com/szTheory/lockspire/actions/runs/24869779639/job/72813553712`
- Environment: hex-publish
- Approval State: blocked - no approval rule was configured on `hex-publish`, so this canonical `push` run crossed the environment without reviewer approval
- Approved At: none
- Trusted command proof:
  - `gh run view 24869779639 --job 72813553712 --log` shows `mix release.preflight` at `2026-04-24T02:54:31.8563040Z`
  - the same log shows `mix hex.publish --yes` at `2026-04-24T02:55:25.7506182Z`

Non-canonical run note: `workflow_dispatch` run `24869621652` exists, but it is recovery-only and cannot replace the normal `push`-driven proof lane.

## Drift Reconciliation

No repo-owned release-lane drift required correction in this plan.

- `.github/workflows/release.yml` still defines the single canonical Release Please -> `push` on `main` -> `hex-publish` lane plus recovery-only `workflow_dispatch`.
- `docs/maintainer-release.md` still keeps repo-owned proof, GitHub settings proof, and workflow-run proof separate.
- `release-please-config.json` and `.release-please-manifest.json` still encode the checked-in release policy.
- `mix.exs` remains package truth and still defines `release.preflight` as `package.build`, `package.publish-dry-run`, and `docs.verify`.
- `test/lockspire/release_readiness_contract_test.exs` still fences the canonical release-lane invariants that the repo can prove.

The contradiction is live-environment posture, not checked-in workflow/docs/config drift: the environment is branch-bound and secret-scoped as expected, but reviewer approval is absent.

## Closure Decision

Blocked. Phase 11 Plan 01 cannot mark `RELS-01` passed because the live `hex-publish` environment lacks reviewer approval protection and the canonical `Release` run `24869779639` therefore provides successful publish proof without approved protected-run proof.

To close this plan as passed, the live GitHub environment must be revised to require approval at the `hex-publish` boundary and a later canonical `push`-triggered `Release` run on `main` must record an explicit approved state with a real approval timestamp before executing `mix release.preflight` and `mix hex.publish --yes`.
