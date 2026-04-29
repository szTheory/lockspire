# Phase 37-04 Deferred Items

## Pre-existing Test Failure (Out of Scope)

**File:** `test/lockspire/release_readiness_contract_test.exs` line 347
**Test:** "planning metadata and repo truth keep PAR scoped to the narrow v1.3 slice"
**Failure:** Cannot read `.planning/milestones/v1.3-ROADMAP.md` — file has never been in git

This failure predates phase 37 (confirmed by `git show d256da1:.planning/milestones/`). It is not caused by any changes in plans 37-01 through 37-04.

## OIDF Docker Suite

The full OIDF external suite (`scripts/conformance/run_phase37_suite.sh`) requires:
- Docker daemon running
- Internet access to gitlab.com (OIDF conformance suite download)
- Browser automation capability

In environments without Docker (e.g., this worktree execution), use `LOCKSPIRE_PHASE37_SKIP_SUITE=true` to run the integration proof and create artifact structure without the external suite.
