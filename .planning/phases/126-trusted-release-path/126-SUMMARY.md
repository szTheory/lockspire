---
phase: 126
status: complete
requirements: [RELEASE-01, RELEASE-02, RELEASE-03, SUPPLY-01, SUPPLY-02, CI-01]
---

# Phase 126: Trusted Release Path Summary

Lockspire now requires successful CI evidence for the exact post-merge main SHA before it can enter its protected publication path.

## Delivered

- Split Release Please merge from publication dispatch; only the merged commit's own successful `CI` push run can dispatch release.
- Made dispatch validation fail closed on a lowercase full SHA, current `origin/main`, main ancestry, and matching GitHub Actions CI metadata.
- Published only from detached validated SHA, with GitHub release target validation, Hex publication, and an unprivileged install-truth log artifact.
- Upgraded the checked-in Release Please runtime to `@actions/core` 3.0.1 and `release-please` 17.11.2 with a zero-vulnerability production npm audit and nested Dependabot coverage.
- Pinned external action/service references, bounded all workflow jobs, made dependency review fail closed, and added a checksum-verified Actionlint/ShellCheck entrypoint plus non-mutating lock verification.

## Verification

- 55 Phase 126 release/supply-chain/static contract tests passed.
- `bash scripts/ci/lint_workflows.sh` passed with zero warning-or-higher findings.
- Runtime `npm audit --omit=dev --audit-level=moderate` reported zero vulnerabilities.
- `mix deps.get --check-locked` and the lockfile diff gate passed.

## Commits

- `8792498` — release runtime RED contract
- `05fcc4f` — audited runtime pins and Dependabot
- `9a7e000` — ignore local npm runtime installs
- `15455bb` — trusted release flow, workflow supply chain, and CI lint/lock gates

## Follow-up

The fresh `mix deps.get --check-locked` output reports advisories in Bandit, Phoenix LiveView, and Postgrex. They predate this release-path change and are outside this phase's approved dependency scope; they remain actionable dependency-upgrade work.
