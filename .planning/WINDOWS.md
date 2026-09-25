---
schema_version: 1
open_count: 0
waived_count: 0
fixed_count: 9
total_count: 9
last_updated: 2026-09-12T00:29:32.780Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 138 | deviation | test/support/lockspire/release_proof/package_assertions.ex | 1826 | Fake Git owned-path fixture needed an explicit successful no-op after unmatched globs under set -e. | fixed |  | 2026-08-28T23:25:45.579Z | 2026-08-28T23:25:55.576Z |
| 2 | 138 | deviation | scripts/maintainer/baseline_inventory.sh |  | Empty maintained JSONL aggregate was initially treated as a structured failure; fixed by allowing valid zero-record aggregation. | fixed |  | 2026-08-28T23:58:29.712Z | 2026-08-28T23:58:40.465Z |
| 3 | 138 | deviation | scripts/maintainer/baseline_inventory.sh |  | Normalized signed Bash bytes and scoped phase labels for the full CI proof | fixed |  | 2026-08-29T00:50:38.718Z | 2026-08-29T00:51:00.826Z |
| 4 | 138 | deviation | scripts/maintainer/baseline_inventory.sh |  | Replaced a non-expanding active-record brace pathspec with explicit Git pathspecs. | fixed |  | 2026-08-29T01:48:45.074Z | 2026-08-29T01:48:49.263Z |
| 5 | 138 | deviation | scripts/maintainer/baseline_inventory.sh |  | Added positive lifecycle classification for current REVIEW and VERIFICATION authorities. | fixed |  | 2026-08-29T01:48:45.148Z | 2026-08-29T01:48:49.336Z |
| 6 | 138 | deviation | test/support/lockspire/release_proof/package_assertions.ex |  | Aligned fake active-record selection with production Git pathspecs | fixed |  | 2026-09-10T01:22:43.531Z | 2026-09-10T01:23:56.766Z |
| 7 | 138 | deviation | test/support/lockspire/release_proof/package_assertions.ex |  | Raised async contention sentinel deadline for the expanded process matrix | fixed |  | 2026-09-10T01:22:43.612Z | 2026-09-10T01:23:56.845Z |
| 8 | 138 | deviation | scripts/maintainer/baseline_inventory.sh |  | Task 2 external per-field matcher caused contract timeouts; replaced by bounded Bash matching in fa1b8c46 | fixed |  | 2026-09-10T18:31:35.339Z | 2026-09-10T18:32:02.104Z |
| 9 | 139 | deviation | test/support/lockspire/release_proof/package_assertions.ex |  | Added explicit real linked-worktree rejection coverage after the initial GREEN fixture | fixed |  | 2026-09-12T00:29:10.877Z | 2026-09-12T00:29:32.780Z |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "138",
    "file": "test/support/lockspire/release_proof/package_assertions.ex",
    "line": 1826,
    "description": "Fake Git owned-path fixture needed an explicit successful no-op after unmatched globs under set -e.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T23:25:45.579Z",
    "resolved_at": "2026-08-28T23:25:55.576Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "138",
    "file": "scripts/maintainer/baseline_inventory.sh",
    "line": null,
    "description": "Empty maintained JSONL aggregate was initially treated as a structured failure; fixed by allowing valid zero-record aggregation.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T23:58:29.712Z",
    "resolved_at": "2026-08-28T23:58:40.465Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "138",
    "file": "scripts/maintainer/baseline_inventory.sh",
    "line": null,
    "description": "Normalized signed Bash bytes and scoped phase labels for the full CI proof",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-29T00:50:38.718Z",
    "resolved_at": "2026-08-29T00:51:00.826Z"
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "138",
    "file": "scripts/maintainer/baseline_inventory.sh",
    "line": null,
    "description": "Replaced a non-expanding active-record brace pathspec with explicit Git pathspecs.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-29T01:48:45.074Z",
    "resolved_at": "2026-08-29T01:48:49.263Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "138",
    "file": "scripts/maintainer/baseline_inventory.sh",
    "line": null,
    "description": "Added positive lifecycle classification for current REVIEW and VERIFICATION authorities.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-29T01:48:45.148Z",
    "resolved_at": "2026-08-29T01:48:49.336Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "138",
    "file": "test/support/lockspire/release_proof/package_assertions.ex",
    "line": null,
    "description": "Aligned fake active-record selection with production Git pathspecs",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T01:22:43.531Z",
    "resolved_at": "2026-09-10T01:23:56.766Z"
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "138",
    "file": "test/support/lockspire/release_proof/package_assertions.ex",
    "line": null,
    "description": "Raised async contention sentinel deadline for the expanded process matrix",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T01:22:43.612Z",
    "resolved_at": "2026-09-10T01:23:56.845Z"
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "138",
    "file": "scripts/maintainer/baseline_inventory.sh",
    "line": null,
    "description": "Task 2 external per-field matcher caused contract timeouts; replaced by bounded Bash matching in fa1b8c46",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-10T18:31:35.339Z",
    "resolved_at": "2026-09-10T18:32:02.104Z"
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "139",
    "file": "test/support/lockspire/release_proof/package_assertions.ex",
    "line": null,
    "description": "Added explicit real linked-worktree rejection coverage after the initial GREEN fixture",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-12T00:29:10.877Z",
    "resolved_at": "2026-09-12T00:29:32.780Z",
    "milestone": "v1.38"
  }
]
````
