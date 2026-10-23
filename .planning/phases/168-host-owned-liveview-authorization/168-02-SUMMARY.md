---
phase: 168-host-owned-liveview-authorization
plan: "02"
subsystem: auth
tags: [phoenix, liveview, host-authorization, integration-tests]
requires:
  - phase: 168-host-owned-liveview-authorization
    provides: Mutable host authority fixture and connected authorization hook from Plan 01
provides:
  - Cached-response rejoin evidence across default, nested and root admin mounts
  - Independent session, binding, identity and staff-policy denial controls
  - Protected callback and action halt evidence for a denied new connected join
affects: [168-03, 169, 170]
actuals:
  tokens: 2657
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Reuse a sent signed response with public live(conn) to start a distinct server-side connected lifecycle
    - Resolve mutable host session, identity and staff policy again at each new connected join
key-files:
  created: []
  modified:
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
key-decisions:
  - "Use public live(sent_conn) for cached-response server lifecycle evidence; actual browser/socket recovery remains Phase 170 work."
patterns-established:
  - "Cached-response authorization: stop the old LiveView PID, retain the original sent 200 conn, mutate only host authority, then call live(conn) without a path."
  - "Drain old lifecycle messages and require fresh connected-hook traces while asserting there is no new HTTP or session callback."
requirements-completed: [HAUTH-02, HAUTH-04]
coverage:
  - id: D1
    description: Allowed and denied cached-response connected rejoins across all existing admin mount shapes
    requirement: HAUTH-04
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#cached admin rejoin checks session, identity and policy at every mount
        status: pass
    human_judgment: false
  - id: D2
    description: Denied new connected joins halt before protected host probe callbacks or actions
    requirement: HAUTH-02
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#cached-response denial halts before protected probe callbacks and actions
        status: pass
    human_judgment: false
duration: 8m
completed: 2026-10-22
status: complete
plan_head_before: b2427de26a7012d19dd5e5d6545988db9f9bb9cf
plan_head_after: d49ddcf4386919dcc9ec448f90670c559a526280
---

# Phase 168 Plan 02: Cached-response connected authorization Summary

**Previously issued signed admin HTML starts a distinct connected process only when current host session, identity and staff policy still allow it.**

## Performance

- **Duration:** 8 minutes
- **Started:** 2026-10-22T20:11:30-04:00
- **Completed:** 2026-10-22T20:19:30-04:00
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Reused the original sent 200 response with public `live(conn)` after monitoring and stopping the previous LiveView PID; successful rejoins returned a distinct PID and a fresh connected host-hook observation.
- Verified allowed rejoins at default, nested and root admin mounts. At each mount, independently invalidated the session, removed its binding, deleted the host identity, or withdrew staff policy and confirmed the next connected join redirected to `/host/sign-in`.
- Added a positive host probe lifecycle control and proved denied joins halt before connected mount, params, render-data and action callbacks. Rejoin assertions observed no new HTTP policy or host session callback.

## Evidence

- **Executed revision:** `d49ddcf4386919dcc9ec448f90670c559a526280`.
- **Runtime:** Elixir 1.20.4 / OTP 29.1.1; locked Phoenix 1.8.13 and Phoenix LiveView 1.2.10.
- **Task 1 tracer:** `LOCKSPIRE_TEST_DB_NAME=lockspire_phase168_20261022 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` — 19 passed.
- **Task 2 and final focused verification:** same runtime command with `test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` — 23 passed.
- **Lifecycle contract:** installed `Phoenix.LiveViewTest.live/3` accepts a nil path; its sent-200 branch calls `connect_from_static_token/3` on the supplied response (`deps/phoenix_live_view/lib/phoenix_live_view/test/live_view_test.ex`, lines 263–276 and 329–336). The lifecycle reducer halts subsequent mount hooks when a hook returns `{:halt, socket}` (`deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex`, lines 155–177).
- **Observed:** the allowed default tracer rejoined the unchanged original response with a different PID. Each mount’s allowed control did the same. Twelve independent denied joins reached a fresh connected authorization decision and produced no destination view; session references and stale `host_staff_id` assigns remained in the retained conn while current authority denied access.

## Task Commits

1. **Task 1: Rejoin the default real admin page from its original signed response** — `ef727354` (`test`)
2. **Task 2: Cover invalid sessions, deleted identities and policy changes at every existing mount** — `d49ddcf4` (`test`)

## Files Created/Modified

- `test/lockspire/web/live/admin/admin_route_integration_test.exs` — exercises public cached-response joins, current host-authority denial cases, and protected callback/action markers.

## Decisions Made

- Treat this as server-side new-join evidence. It does not prove browser reconnection orchestration, WebSocket transport recovery, network-drop behavior, or continuous checks on an already-running socket; Phase 170 owns transport and exact-floor proof.
- Keep account/session authority in the mutable host fixture. Lockspire adds no host session service, logout implementation or event-level policy.

## Deviations from Plan

None — the final tests use the approved public `live(sent_conn)` entry point, original signed response, existing authority fixture and all three existing mount shapes.

## Issues Encountered

The first focused draft used a router fixture without the probe route and asserted a page heading whose wording was not stable. The probe was moved to the canonical host router fixture and the mount matrix now asserts the real destination module. The final focused command passed.

## Next Phase Readiness

Plan 03 can build on the cached-response lifecycle proof. P-168-02 evidence-claim closure and the final Phase 168 union remain for Plan 03. A-168-P08 remains unclassified; this plan does not invent another reconnect requirement. Phase 169 owns adoption and documentation convergence. Phase 170 owns browser/socket transport, package and exact-supported-floor proof.

---
*Phase: 168-host-owned-liveview-authorization*
*Completed: 2026-10-22*

## Self-Check: PASSED

- SUMMARY exists at the required phase path.
- Task commits `ef727354` and `d49ddcf4` are ancestors of HEAD and the plan scope check found both commits.
- The plan-level focused integration/runtime-contract command passed with 23 tests.
