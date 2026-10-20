---
phase: 161-docs-verified-1-6-0-release
plan: 09
subsystem: release
tags: [ledger, release-train, verified-publication]
requires: ["161-08"]
provides: ["Verified1.6.0 release ledger on main", "Green conditional record merge and preserved local planning state"]
affects: [milestone-closeout]
requirements-completed: [REL-02]
actuals:
  tasks: 4
completed: 2026-10-20
status: complete
---

# Phase161 Plan09: Public release recorded on main

PR133 squash `5e8a484cb834197bb0f57902fdbd6cb9675a2715` records verified public Lockspire1.6.0 from source `428a9c53e02bc573376d0fcac313f047fbbea81c`. The published artifact and later documentation source are explicitly distinct.

## Evidence

- Refreshed ledger uses public API date/checksum, exact protected/source CI runs and terminal receipt release_verified true/blocker none. Prior1.5.1 and earlier1.5.0 history preserved. Release Please metadata/date and standing train rules unchanged.
- Local hygiene18PASS/0BLOCK and existing release/repository contracts13tests/0failures; no test edits. PR133 at440f65b6 passed all eight checks and merged under explicit conditional authorization, normal protection and exact-head pin.
- Merge parent is S, tree equals R, origin/main ledger names1.6.0. Release push39485083062 succeeded; no new open autorelease:pending PR.
- Safe reset used state.json-only stash, empty clean-tree gate, backup/local-main-pre-record-reset, replay of all three post-R planning commits and exact state.json restoration. Local differences beyond main are planning-only.
- Maintainer requested no repeated manual confirmations when checks are green; remaining scoped steps used that authorization through normal APIs. Existing persistent workflow setting remains disabled_manually, preserving its prior state; no unsolicited unattended release setting change. Dependabot125–127 remain open/deferred. One-use authorized-SHA variable remains absent.

## Completion boundary

All REL-02 publication, independent verification and main-branch recording criteria are now satisfied. Final phase goal verification follows; final main CI39485083024 is tracked separately until terminal before the final readiness report. Additional phase closure records remain local after the record PR tip, as the plan specifies.
