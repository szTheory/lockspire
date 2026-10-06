---
phase: 140-bounded-operational-loose-end-triage
reviewed: 2026-10-05T22:43:06Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/maintainer/baseline_inventory.sh
  - scripts/maintainer/finalize_phase_139_acceptance.sh
  - scripts/maintainer/supersede_phase_139_host_receipt.sh
  - tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
resolution: remediated_in_worktree
remaining_critical: 0
remaining_warning: 0
---

# Phase 140: Finalizer Supersession Code Review Report

**Reviewed:** 2026-10-05T22:43:06Z  
**Depth:** standard  
**Files Reviewed:** 5  
**Status:** issues_found

## Summary

Reviewed the five scoped files for receipt supersession, archival lineage, recovery validation, and publication ordering. Four state integrity defects require repair before relying on the new supersession path. The existing `140-REVIEW.md` was not changed. This was a read-only code review; no finalizer or tests were run.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Supersession accepts an invalid durable acceptance receipt

**Severity:** BLOCKER  
**File:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:359-376`  
**Related:** `/Users/jon/projects/lockspire/scripts/maintainer/finalize_phase_139_acceptance.sh:416-429`; `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs:409-413`  
**Issue:** `acceptedPhase139Base` accepts any mode-0600 JSON containing the schema and a 40-character `baseline_sha`. The lifecycle test deliberately supplies only those two fields. The acceptance driver later requires the complete durable receipt, so the helper can archive a prior pending receipt and publish a v2 successor against a truncated or otherwise invalid accepted base, after which the driver rejects the durable receipt and cannot complete. The two commands disagree on the authority required for the same base SHA.  
**Fix:** Validate the entire durable acceptance receipt against the acceptance driver's schema and evidence rules before `archiveReceipt` or `writeReceipt`. Share the validator, or make the helper call a strict read-only validator with the same contract. Replace the abbreviated test fixture with a fully valid durable receipt and add an invalid-receipt rejection case that checks unchanged pending bytes and archive state.

### CR-02: A second supersession breaks validation of the original archive

**Severity:** BLOCKER  
**File:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:294-301`  
**Related:** `/Users/jon/projects/lockspire/scripts/maintainer/baseline_inventory.sh:4718-4755`; `/Users/jon/projects/lockspire/scripts/maintainer/finalize_phase_139_acceptance.sh:163-204`  
**Issue:** `supersede` permits an existing v2 receipt as its predecessor, because it includes `previous.recovery` in the self-digest but never follows its `supersedesSha256`. Both consumers validate only the immediate archived predecessor. Thus two calls with the current pending digest can create A → B → C; after C is written, removal or alteration of A's archive is invisible to both v2 validators. C remains acceptable even though its recorded provenance chain is broken. No new commit is required between the two calls because the ancestor check accepts the same HEAD.  
**Fix:** Validate the complete archived predecessor chain before publishing and when consuming v2 receipts, following each v2 `supersedesSha256` with a bounded depth and cycle check. Alternatively reject superseding an existing v2 receipt until a separate, explicit chain-preserving protocol is defined. Add a two-supersession case that rejects a missing or altered first archive.

### CR-03: The compare-and-swap can resurrect a completed pending receipt

**Severity:** BLOCKER  
**File:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:344-347`  
**Related:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:635-639`  
**Issue:** Supersession checks the old digest, then unconditionally renames the successor over the target. `complete` deletes that same target without acquiring `acquireFinalizerLock`. If `complete` unlinks the old receipt after line 346 and before line 347, the rename creates a new pending receipt after completion. The command's digest check is therefore a read followed by a write, not a compare-and-swap with respect to another supported state-helper command.  
**Fix:** Put `complete` and every receipt mutation under the same lock and recheck the expected target identity immediately before publication. Make completion conditional on the exact receipt it observed so a concurrent successor cannot be deleted or resurrected. Add an interleaving test for completion between the digest check and rename.

### CR-04: Ref drift is detected only after publishing the successor

**Severity:** BLOCKER  
**File:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:268`  
**Related:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:344-355`  
**Issue:** The helper snapshots all refs before observation but compares them only after archiving and replacing the pending receipt. A concurrent ref update, including an ordinary fetch of `origin/main`, makes the command fail at line 353 while leaving the new successor and archive in place. That is a failed operation with a committed receipt change, and the successor may describe a main-ref state that is no longer current.  
**Fix:** Recheck the ref snapshot before archive and receipt publication. Coordinate supported ref mutators with the same lock, and define a recovery path if the final post-publication check still detects drift. On failure, report the exact receipt state so callers cannot mistake the prior pending receipt for the current one.

## Warnings

### WR-01: Successor publication omits the durability steps used for the archive

**Severity:** WARNING  
**File:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:71-85`  
**Related:** `/Users/jon/projects/lockspire/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs:218-234`  
**Issue:** `archiveReceipt` syncs its file and containing directory, but `writeReceipt` only writes, renames, and changes mode. A crash after success is reported can leave the archive durable without the successor rename or contents being durable. This weakens the recovery record precisely at the archival handoff.  
**Fix:** Open and `fsync` the temporary successor file before rename, then `fsync` the lifecycle directory after rename and mode setting. Report success only after those operations complete.

## Focused Re-review and Dispositions — 2026-10-05T22:58:32Z

The reviewer re-read the five scoped files after the fixes and found no remaining concrete blocker in the supersession path. The original finding counts above preserve the initial review record; all five findings are closed in the current worktree.

| Finding | Disposition | Evidence |
| --- | --- | --- |
| CR-01 | Closed | `supersede` requires full durable acceptance evidence before archiving; the fixture rejects the truncated receipt and preserves pending bytes. |
| CR-02 | Closed | The issuer rejects a v2 predecessor, and both Python consumers reject nested v2 lineage. The fixture rejects repeat supersession with pending bytes unchanged. |
| CR-03 | Closed | All supported receipt mutation commands take `receipt-mutation.lock`; the fixture proves direct completion is blocked while the lock is held. |
| CR-04 | Closed | Ref and advertised-main checks precede archive and successor publication. Late detected drift restores the exact prior bytes; a fixture Git wrapper triggers that branch without moving refs. |
| WR-01 | Closed | Successor temporary file and lifecycle directory are synced. An injected post-rename sync failure restores the prior receipt. Existing archive entries are also directory-synced before retry proceeds. |

**Focused checks:** The Phase 140 recovery fixture passed (`1/1`). The lifecycle file in tracked portable-host mode passed (`7/7` applicable, `2` skipped). `node --check`, `bash -n`, and `git diff --check` passed. In an isolated temporary source copy, the current regression failed against the pre-fix helper at the truncated-authority assertion, then passed after replacing only the helper with the repaired version. No live finalizer, supersession, publication, planner, or ref command was run.

**Verification limit:** The installed-capability mode's byte-equality assertion reports that the installed `post-completion-finalizer-state.cjs` differs from the tracked, edited source. The installed copy was left untouched. The portable-host mode exercises the tracked source and passes. The live Phase 139 gate remains blocked; no live receipt or ref movement is claimed.

---

_Reviewed: 2026-10-05T22:43:06Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
