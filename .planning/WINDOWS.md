---
schema_version: 1
open_count: 6
waived_count: 0
fixed_count: 11
total_count: 17
last_updated: 2026-10-26T01:20:35.414Z
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
| 10 | 145 | unrun-verify | .planning/phases/145-configure-and-onboard/145-CREDENTIAL-BROWSER.md |  | Browser credential-changing handoff and narrow/200% zoom/reduced-motion states were intentionally left unobserved; ExUnit covers secret lifecycle and the remaining visual limits are documented. | open |  | 2026-10-09T21:35:14.803Z |  |
| 11 | 168 | lint-warning | test/support/lockspire/web/admin_route_host.ex | 39 | Pre-existing duplicate record_trace/2 clauses in test host fixture emit compiler warnings. | open |  | 2026-10-23T00:10:29.843Z |  |
| 12 | 170 | deviation | scripts/acceptance/clean_room_admin_journey.py |  | Runtime asset validation accepts only the isolated provider host or its pair-scoped dependency cache; root checkout sources are rejected. | open |  | 2026-10-24T03:08:29.033Z |  |
| 13 | 170 | deviation | test/lockspire/web/live/admin/interactions_live_test.exs |  | Allow only safe data-phx-link-state push/replace metadata while preserving OAuth state and token sentinel assertions. | fixed |  | 2026-10-24T07:25:37.986Z | 2026-10-24T07:25:40.649Z |
| 14 | 170 | deviation | test/lockspire/host_integration_ci_contract_test.exs |  | Formatted the phase-owned Plan 04 CI contract after the whole-project formatter exposed its long assertions; behavior unchanged. | fixed |  | 2026-10-24T07:25:42.812Z | 2026-10-24T07:25:44.957Z |
| 15 | 174 | deviation | scripts/acceptance/clean_room_saas_journey.py |  | The clean-room authorization helper was corrected to follow the host-owned direct consent redirect for authenticated A171-006. | open |  | 2026-10-25T01:32:57.121Z |  |
| 16 | 174 | deviation | test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex |  | The clean-room resolver now reads account identity and auth_time from the same fetched host session connection. | open |  | 2026-10-25T01:32:59.172Z |  |
| 17 | 177 | deviation | test/support/delegated_verifier_maintenance_store.ex |  | Moved the selected maintenance test adapter into shared test support so the plan integration command can load it. | open |  | 2026-10-26T01:20:35.414Z |  |

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
  },
  {
    "id": 10,
    "kind": "unrun-verify",
    "phase": "145",
    "file": ".planning/phases/145-configure-and-onboard/145-CREDENTIAL-BROWSER.md",
    "line": null,
    "description": "Browser credential-changing handoff and narrow/200% zoom/reduced-motion states were intentionally left unobserved; ExUnit covers secret lifecycle and the remaining visual limits are documented.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-09T21:35:14.803Z",
    "resolved_at": null,
    "milestone": "v1.40"
  },
  {
    "id": 11,
    "kind": "lint-warning",
    "phase": "168",
    "file": "test/support/lockspire/web/admin_route_host.ex",
    "line": 39,
    "description": "Pre-existing duplicate record_trace/2 clauses in test host fixture emit compiler warnings.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-23T00:10:29.843Z",
    "resolved_at": null,
    "milestone": "v1.46"
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "170",
    "file": "scripts/acceptance/clean_room_admin_journey.py",
    "line": null,
    "description": "Runtime asset validation accepts only the isolated provider host or its pair-scoped dependency cache; root checkout sources are rejected.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-24T03:08:29.033Z",
    "resolved_at": null,
    "milestone": "v1.46"
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "170",
    "file": "test/lockspire/web/live/admin/interactions_live_test.exs",
    "line": null,
    "description": "Allow only safe data-phx-link-state push/replace metadata while preserving OAuth state and token sentinel assertions.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-24T07:25:37.986Z",
    "resolved_at": "2026-10-24T07:25:40.649Z",
    "milestone": "v1.46"
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "170",
    "file": "test/lockspire/host_integration_ci_contract_test.exs",
    "line": null,
    "description": "Formatted the phase-owned Plan 04 CI contract after the whole-project formatter exposed its long assertions; behavior unchanged.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-24T07:25:42.812Z",
    "resolved_at": "2026-10-24T07:25:44.957Z",
    "milestone": "v1.46"
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "174",
    "file": "scripts/acceptance/clean_room_saas_journey.py",
    "line": null,
    "description": "The clean-room authorization helper was corrected to follow the host-owned direct consent redirect for authenticated A171-006.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-25T01:32:57.121Z",
    "resolved_at": null,
    "milestone": "v1.47"
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "174",
    "file": "test/clean_room/provider_host/lib/clean_room_provider/lockspire/account_resolver.ex",
    "line": null,
    "description": "The clean-room resolver now reads account identity and auth_time from the same fetched host session connection.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-25T01:32:59.172Z",
    "resolved_at": null,
    "milestone": "v1.47"
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "177",
    "file": "test/support/delegated_verifier_maintenance_store.ex",
    "line": null,
    "description": "Moved the selected maintenance test adapter into shared test support so the plan integration command can load it.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-26T01:20:35.414Z",
    "resolved_at": null,
    "milestone": "v1.48"
  }
]
````
