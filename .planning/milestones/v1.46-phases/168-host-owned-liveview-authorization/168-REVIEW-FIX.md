---
phase: 168
fixed_at: "2026-10-23T01:03:35Z"
review_path: .planning/phases/168-host-owned-liveview-authorization/168-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 168: Code Review Fix Report

**Fixed at:** 2026-10-23T01:03:35Z
**Source review:** `.planning/phases/168-host-owned-liveview-authorization/168-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### WR-01: Legacy HTTP fallback treats every nonempty identity as authorized

**Files modified:** `test/support/lockspire/web/admin_route_host.ex`, `test/lockspire/web/live/admin/admin_route_integration_test.exs`
**Commit:** `50035272` (`fix(168): WR-01 enforce fallback identity allowlist`)
**Source revision before fix:** `ee58e3ffdf3f305cc1b9e1be4f1a8671ed700a11`
**Status:** fixed; independently re-reviewed and security-checked at `50035272`.
**Applied fix:** The no-store HTTP fallback now resolves identity through `Identity.resolve/1`, assigns the resolved staff ID only for the explicit `staff-1` baseline, and records the existing denial trace and halts on unknown identities. The mutable authority path remains unchanged. Added HTTP coverage for allowed `staff-1`, arbitrary and deleted identities, and missing and empty identity controls. Denials assert the HTTP guard runs before the admin session, hook, authorization callback, or protected response.

## Verification

Verification ran in the main checkout on the working-tree source subsequently committed as `50035272236cd84ce9adc381bef0393f431ee5b7`; `ee58e3f` was the pre-fix HEAD, not the tested source. No worktree was created.

- `HEX_HOME=/tmp/lockspire-phase168-hex LOCKSPIRE_TEST_DB_NAME=lockspire_phase168_20261022 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix format --check-formatted` — passed.
- Focused integration, separation, and compile tests — 39 passed, 0 failures.
- Phase focused union (`admin_routes_compile_test`, `admin_route_inventory_test`, `admin_route_separation_test`, `admin_route_integration_test`, and `admin_liveview_runtime_contract_test`) — 45 passed, 0 failures.
- `HEX_HOME=/tmp/lockspire-phase168-hex LOCKSPIRE_TEST_DB_NAME=lockspire_phase168_20261022 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test.fast` — 1,977 passed (1,975 tests and 2 properties), 6 skipped, 497 excluded.
- `HEX_HOME=/tmp/lockspire-phase168-hex LOCKSPIRE_TEST_DB_NAME=lockspire_phase168_20261022 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix compile` — passed. Existing compiler warnings remain, including the duplicate `record_trace/2` clauses.
- `git diff --check 66fa5c7a --` — passed.

## Independent Closure

The code reviewer inspected the exact fix and no-authority fallback regression and returned clean with zero findings. The security auditor independently verified current authority and the explicit fallback allowlist at `50035272`, retaining 15/15 closed threats. These deterministic checks resolve the generated human-verification suggestion under VERIFICATION-POLICY.md; no human pass was assumed and no manual action remains for WR-01. Reopen only on relevant source/criterion changes or contradictory evidence.

---

_Fixed: 2026-10-23T01:03:35Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
