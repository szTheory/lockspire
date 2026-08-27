# Phase 137 Plan 07: Scheduled Supplemental Conformance Summary

**Completed:** 2026-08-27
**Requirements:** CONF-01, CONF-02

## Outcome

The default-branch supplemental OIDF workflow now runs the immutable Phase 37
and FAPI 2.0 profiles on a weekly schedule and remains manually dispatchable.
It has read-only permissions, bounded timeouts and retention, overlap
cancellation, immutable action/container pins, and uploads only each runner's
validated `receipt.json`. Raw suite work, Compose configuration, provider
configuration, URLs, and logs are never artifact paths.

The optional hosted lane is manual-only and isolates its hosted URLs to that
job, so scheduled runs do not request credentials. Maintainer documentation
now records the exact suite tag/commit and evidence schema, reproducible local
commands, update policy, and infrastructure/suite/integration-only/success
classification without implying certification or release-gate status.

`mix lockspire.oidf_conformance --check` now validates the checked-in lock,
plans, scripts, evidence builder, Docker Compose, Python, curl, and jq before a
run and prints the exact profile commands. The former environment variables
were removed from preflight because the immutable runners do not consume them.

## Evidence

- Task, workflow, and redacted-evidence contracts: 12 tests, 0 failures.
- Real local immutable-input/tool preflight passes.
- Repo-pinned Actionlint and ShellCheck workflow validation passes.
- Strict documentation generation passes with no warnings.

## Security Notes

- Scheduled jobs contain no secrets and retain only schema-bounded receipts.
- Hosted URLs cannot enter scheduled jobs or uploaded evidence.
- Mutable suite refs and images remain rejected by the Plan 05 lock validator.
- This lane is explicitly supplemental reliability history, not certification.
