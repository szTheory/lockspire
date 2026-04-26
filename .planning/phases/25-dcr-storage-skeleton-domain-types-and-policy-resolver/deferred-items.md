# Deferred Items - Phase 25

## Pre-existing test failures (not caused by this phase)

### test/lockspire/release_readiness_contract_test.exs:250

- **Test:** "planning metadata and repo truth keep PAR scoped to the narrow v1.3 slice"
- **Failure:** asserts `PROJECT.md` contains "Current Milestone: v1.3 PAR Policy Controls", but project has advanced to v1.5
- **Confirmed pre-existing:** verified with `git stash` against base commit `54a450c`; failure reproduces without any Phase 25 changes
- **Disposition:** Out of scope for Plan 25-04 — release-readiness-contract drift is a milestone-bookkeeping concern, not a domain-type concern. Recommend Phase 29 closure work updates this assertion.
- **Discovered by:** Plan 25-04 (Task 1)
- **Discovered at:** 2026-04-26
