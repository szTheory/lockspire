---
phase: 159
review: 159-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Clean-room boundary audit silently weakened for the non-install path"
  - id: WR-02
    severity: warning
    disposition: open
    title: "`{:system, var}` values are not normalised, so a stray newline or space fails with a misleading error"
  - id: IN-01
    severity: info
    disposition: open
    title: "`gen.kek --id` for rotation prints a block that does not match the rotation guide"
  - id: IN-02
    severity: info
    disposition: open
    title: "`--raw` silently ignores `--id`, and the default output has a double trailing blank line"
open: 4
total: 4
recorded: 2026-10-19T19:45:31.988Z
---

# Phase 159: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
