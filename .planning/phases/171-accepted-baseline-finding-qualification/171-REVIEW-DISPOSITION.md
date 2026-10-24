---
phase: 171
review: 171-REVIEW.md
titles: json
findings:
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "Scalar case requirement IDs can still crash validation"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Delivery record reports a stale final contract count"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Consent control accepts an off-origin redirect"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Malformed nested ledger entries can crash validation"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "Validator complexity exceeds the project Credo limit"
open: 0
total: 5
recorded: 2026-10-24T21:28:32.089Z
---

# Phase 171: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-05 | warning | fixed | 171-REVIEW-FIX.iter2.md (not in the current review) |
| WR-01 | warning | fixed | 171-REVIEW-FIX.md (not in the current review) |
| WR-02 | warning | fixed | 171-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 171-REVIEW-FIX.md (not in the current review) |
| WR-04 | warning | fixed | 171-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
