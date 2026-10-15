---
phase: 152
review: 152-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Filter step runs outside the rescue in `handle_params` (interactions and device pages)"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Summary \"Pending\" and \"Waiting\" counts include expired requests, while the pending filter and overview exclude them"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Logout deliveries `load_deliveries` relies on CaseClauseError being rescued"
  - id: IN-01
    severity: info
    disposition: open
    title: "Device \"App may check again\" shows \"Not recorded\" when nothing is recorded"
  - id: IN-02
    severity: info
    disposition: open
    title: "Inconsistent copy and duplicated helpers across the pages"
  - id: IN-03
    severity: info
    disposition: open
    title: "Inconsistent path construction"
open: 6
total: 6
recorded: 2026-10-15T20:40:34.731Z
---

# Phase 152: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
