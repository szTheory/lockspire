# Phase 122 Deferred Items

## Out-of-Scope Test Failures

- **Found during:** Plan 122-03 phase gate (`MIX_ENV=test mix test.fast --max-failures 5`)
- **Status:** Deferred, unrelated to Plan 122-03 consent detail changes
- **Details:** `Lockspire.ReleaseReadinessContractTest` has 4 failures against adoption-demo documentation and lifecycle scripts from Phase 115-era contracts.
- **Affected files reported by failures:** `docs/adoption-demo.md`, `scripts/maintainer/repo_hygiene_check.sh`
- **Reason deferred:** Those files were already dirty before Plan 122-03, are outside the plan `files_modified` set, and are excluded from Phase 122 Support investigation scope.
- **Plan-scoped evidence:** Focused consent tests and the Phase 122 token/consent/design-system gate pass after the consent detail changes.
