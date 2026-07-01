---
phase: 123-operate-queue-flow-polish
reviewed: 2026-06-29T21:08:05Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
  - lib/lockspire/web/live/admin/interactions_live/index.ex
  - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
  - test/lockspire/web/live/admin/design_system_contract_test.exs
  - test/lockspire/web/live/admin/device_authorizations_live_test.exs
  - test/lockspire/web/live/admin/interactions_live_test.exs
  - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 123: Code Review Report

**Reviewed:** 2026-06-29T21:08:05Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Narrative Findings (AI reviewer)

### Summary

Reviewed the three Operate queue LiveViews and their focused/design-system contracts. The rendered happy paths avoid the obvious raw secret fields, but the implementation still has two warning-tier defects: the new contract cements storage-adapter access from LiveViews instead of the admin boundary, and the queue pages mishandle storage failures.

### WR-01: Operate LiveViews Bypass The Admin Boundary

**Classification:** WARNING

**File:** `lib/lockspire/web/live/admin/interactions_live/index.ex:7`, `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:7`, `test/lockspire/web/live/admin/design_system_contract_test.exs:167`

**Issue:** `InteractionsLive` and `LogoutDeliveriesLive` import `Lockspire.Storage.Ecto.Repository` directly and call it from `mount/3`. The Phase 123 contract then locks this in by requiring `"Repository.list_interactions"` and `"Repository.list_all_logout_deliveries"` while explicitly rejecting `Lockspire.Admin` delegates for those queues. That contradicts the project boundary that keeps LiveView/admin surfaces separated from storage and leaves these pages coupled to the Ecto adapter instead of the operator-facing admin API used by the other admin pages and by device authorizations.

**Fix:**

```elixir
# lib/lockspire/admin.ex
alias Lockspire.Admin.{Interactions, LogoutDeliveries}

defdelegate list_interactions(opts \\ []), to: Interactions
defdelegate list_logout_deliveries(opts \\ []), to: LogoutDeliveries

# lib/lockspire/web/live/admin/interactions_live/index.ex
alias Lockspire.Admin

Admin.list_interactions()

# lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
alias Lockspire.Admin

Admin.list_logout_deliveries()
```

Update the Phase 123 source contract to require the `Admin.*` read paths and remove the assertions that forbid read-only Operate delegates.

### WR-02: Storage Failures Either Crash Or Render As A False Empty Queue

**Classification:** WARNING

**File:** `lib/lockspire/web/live/admin/interactions_live/index.ex:13`, `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex:13`, `lib/lockspire/web/live/admin/device_authorizations_live/index.ex:99`

**Issue:** Interactions and logout deliveries pattern-match `{:ok, rows}` in `mount/3`, so any repository error raises a `MatchError` and takes down the admin route. Device authorizations takes the opposite unsafe path: `load_device_authorizations/0` turns every `{:error, reason}` into `[]`, causing the UI to state that no records are waiting when the queue was not loaded. The focused tests only cover successful reads and empty assigned lists, so the phase can pass while operators see either a 500 or a misleading empty queue during storage outages.

**Fix:**

```elixir
defp load_interactions do
  case Admin.list_interactions() do
    {:ok, interactions} -> %{items: interactions, load_error?: false}
    {:error, _reason} -> %{items: [], load_error?: true}
  end
end
```

Apply the same shape to all three Operate queues, assign the load-error state separately from the item list, and render an explicit non-secret error/temporarily unavailable state instead of crashing or showing the normal empty copy. Add focused tests that stub or inject `{:error, reason}` for each queue loader.

---

_Reviewed: 2026-06-29T21:08:05Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
