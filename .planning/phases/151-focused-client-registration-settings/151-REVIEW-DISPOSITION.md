---
phase: 151
review: 151-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Apps list has no pagination controls, so apps past the first 10 are unreachable from the UI"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Non-string `q` (for example `?q[]=a`) crashes the LiveView"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Disable/enable failure is silent"
  - id: WR-04
    severity: warning
    disposition: open
    title: "`save_client` trusts a client-supplied `mode` and crashes when it is missing or unknown"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "Successful saves outside `:edit` give no confirmation"
  - id: IN-01
    severity: info
    disposition: open
    title: "Client IDs are concatenated into paths without encoding"
  - id: IN-02
    severity: info
    disposition: open
    title: "Action-group slot names and button styles disagree with the documented variant semantics"
  - id: IN-03
    severity: info
    disposition: open
    title: "Show page \"Back to apps\" drops the operator's inventory filters"
open: 6
total: 8
recorded: 2026-10-15T20:20:52.604Z
---

# Phase 151: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | fixed | 151-REVIEW-FIX.md |
| WR-04 | warning | open | - |
| WR-05 | warning | fixed | 151-REVIEW-FIX.md |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
