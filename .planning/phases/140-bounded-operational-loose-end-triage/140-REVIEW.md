---
phase: 140-bounded-operational-loose-end-triage
reviewed: 2026-09-30T18:16:36Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/maintainer/baseline_inventory.sh
  - scripts/maintainer/finalize_phase_139_acceptance.sh
  - scripts/maintainer/supersede_phase_139_host_receipt.sh
  - tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 140: Code Review Report

**Reviewed:** 2026-09-30T18:16:36Z  
**Depth:** standard  
**Files Reviewed:** 5  
**Status:** issues_found

## Summary

The Phase 140 supersession path creates a v2 recovery receipt, but the acceptance script raises an unhandled `NameError` while validating its archived predecessor. This blocks all v2 receipts before the explicit publication step.

## Critical Issues

### CR-01: V2 recovery validation references `allowed` before assignment

**Classification:** BLOCKER  
**File:** `scripts/maintainer/finalize_phase_139_acceptance.sh:191, 208-213`  
**Issue:** In `resolve_sealed_candidate`, the v2 receipt branch compares `prior_transform["allowedPaths"]` to `allowed` at line 191. The name `allowed` is assigned only later inside the loop that validates preserved worktree records (line 208). Python therefore raises `NameError` when this comparison is reached for every `phase-140-recovery-v2` receipt. `set -u` does not affect the embedded Python; its exception is caught and returned as a validation failure. The acceptance script calls this validator at line 729, so a superseded receipt cannot pass candidate authentication or reach publication.

**Fix:** Define the expected transformation paths before the v2 branch and compare against that constant, keeping the per-record `allowed` variable local to the later loop. For example:

```python
expected_paths = [
    ".planning/PROJECT.md", ".planning/STATE.md",
    ".planning/ROADMAP.md", ".planning/REQUIREMENTS.md",
]
...
prior_transform.get("allowedPaths") != expected_paths
```

## Warnings

## Info

---

_Reviewed: 2026-09-30T18:16:36Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
