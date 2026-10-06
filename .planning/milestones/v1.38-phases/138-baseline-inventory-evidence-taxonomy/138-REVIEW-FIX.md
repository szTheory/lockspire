---
phase: 138-baseline-inventory-evidence-taxonomy
fixed_at: 2026-09-12T23:50:06Z
review_path: /Users/jon/projects/lockspire/.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 138: Code Review Fix Report

**Fixed at:** 2026-09-12T23:50:06Z
**Source review:** `/Users/jon/projects/lockspire/.planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: External cancellation orphans the detached finalizer process group

**Status:** fixed: requires human verification
**Files modified:** `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalizer-process-supervisor.cjs`, `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs`
**Commit:** 37d114cb
**Applied fix:** Unified timeout and external-signal shutdown in the process-group supervisor. `SIGHUP`, `SIGINT`, and `SIGTERM` now stop the timeout path, propagate to the detached finalizer group, escalate against resistant descendants after a grace period, reap the finalizer, and return conventional statuses 129, 130, and 143. The integration regression exercises all three signals and verifies bounded exit, lock cleanup, finalizer and descendant termination, and no post-cancellation mutation.

### WR-01: The active installed capability still executes the pre-fix router

**Status:** fixed: requires human verification
**Files modified:** `.gsd-capabilities.json`, `tools/gsd-capabilities/lockspire-phase-finalizer/capability.json`, `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs`, `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs`
**Commit:** 953efb17
**Applied fix:** Bumped the capability to 1.1.1 and refreshed the project installation through the supported `capability update` command. Lifecycle routing now resolves the active installed command module from the project registry, while the installed-runtime test requires the installed manifest, router, and supervisor to exist and match the tracked source byte-for-byte before exercising lifecycle behavior.

## Verification

Verification ran in the main checkout because `workflow.use_worktrees` is `false`.

- Node syntax checks passed for the modified supervisor and lifecycle/router tests.
- The command-router suite passed: 9 tests, 0 failures, including real timeout and HUP/INT/TERM process-group regressions.
- The focused installed-source parity and Phase 139 lifecycle run passed: 3 tests, 0 failures.
- The active project capability listing reported `lockspire-phase-finalizer` 1.1.1 with status `active`.
- Direct byte comparisons passed for the tracked and installed manifest, router, and supervisor.
- The complete router and installed-lifecycle suite passed: 16 tests, 0 failures.
- `git diff --check` passed for both finding-specific change sets before commit.

---

_Fixed: 2026-09-12T23:50:06Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
