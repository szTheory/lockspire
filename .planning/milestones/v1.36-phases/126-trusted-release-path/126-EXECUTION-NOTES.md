# Phase 126 Execution Notes

## Implemented

- Exact post-merge CI evidence is required before a Release Please merge can dispatch publication.
- The release validator accepts only the current `origin/main` full SHA with a matching successful `CI` push run.
- Publication uses that detached SHA, emits a GitHub release before Hex publication, and runs a separate unprivileged install-truth job.
- The local Release Please runtime is pinned to `@actions/core` 3.0.1 and `release-please` 17.11.2; `npm audit --omit=dev --audit-level=moderate` reported zero vulnerabilities on 2026-08-26.
- Workflow external actions and PostgreSQL services are immutable, jobs are bounded, dependency review fails closed, and repository-owned Actionlint/ShellCheck verification is active.

## Verification

- `npm ci --prefix .github/actions/release-please/runtime --ignore-scripts`
- `npm audit --prefix .github/actions/release-please/runtime --omit=dev --audit-level=moderate`
- `bash scripts/ci/lint_workflows.sh`
- Focused Phase 126 source contracts: 8 tests, 0 failures.

## Remaining contract migration

`test/lockspire/release_readiness_contract_test.exs` has seven expectations for the superseded release design (pre-merge evidence, tag recovery, mutable artifact tag, and old release outputs). Its update is required before the existing broad release-readiness contract can pass; it was deliberately not suppressed or weakened in this execution.
