---
phase: 121-route-scorecards-judgment-contract
fixed_at: 2026-06-28T18:44:16Z
review_path: .planning/phases/121-route-scorecards-judgment-contract/121-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 121: Code Review Fix Report

**Fixed at:** 2026-06-28T18:44:16Z
**Source review:** `.planning/phases/121-route-scorecards-judgment-contract/121-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: Non-route follow-up allowance accepts invalid admin routes

**Files modified:** `test/lockspire/web/live/admin/design_system_contract_test.exs`
**Commit:** 07b4627
**Applied fix:** Tightened `explicit_non_route_follow_up?/1` so `/admin...` values cannot be treated as explicit non-routes, and added regression assertions for `none`, documentation-only text, and invalid admin route examples.

### WR-02: Duplicate scorecard fields are silently overwritten

**Files modified:** `test/support/lockspire/web/admin_proof/route_scorecards.ex`, `test/lockspire/web/live/admin/design_system_contract_test.exs`
**Commit:** da03bd1
**Applied fix:** Made `RouteScorecards.parse!/1` raise on duplicate field labels within a scorecard and added a parser regression contract.

### WR-03: Secret-evidence guard misses common OAuth leak shapes

**Files modified:** `test/lockspire/web/live/admin/design_system_contract_test.exs`
**Commit:** a5eff43
**Applied fix:** Added regex guards for bearer authorization headers, OAuth credential parameters, JSON credential fields, and PEM private-key headers, with regression coverage for leak shapes and ordinary prose references.

## Skipped Issues

None - all in-scope findings were fixed.

## Verification

- Passed: `mix format --check-formatted test/support/lockspire/web/admin_proof/route_scorecards.ex test/lockspire/web/live/admin/design_system_contract_test.exs`
- Passed: `mix test test/lockspire/web/live/admin/design_system_contract_test.exs:406` (7 tests, 0 failures)
- Orchestrator rerun in the primary checkout passed: `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` (50 tests, 0 failures).
- Orchestrator rerun in the primary checkout passed: `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` (56 tests, 0 failures).
- Orchestrator rerun in the primary checkout passed: `mix docs.verify`.

---

_Fixed: 2026-06-28T18:44:16Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
