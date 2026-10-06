---
phase: 138
review: 138-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Git fixture splits a generated remote path on whitespace"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Handoff fixture splits a generated filesystem path as command text"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "External cancellation orphans the detached finalizer process group"
open: 2
total: 3
recorded: 2026-10-04T15:26:20.594Z
---

# Phase 138: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - (not in the current review) |
| CR-01 | critical | fixed | 138-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
