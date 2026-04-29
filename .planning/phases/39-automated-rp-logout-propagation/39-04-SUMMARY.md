---
phase: 39-automated-rp-logout-propagation
plan: "04"
subsystem: infra
tags: [oban, req, oidc, backchannel-logout, telemetry, audit, redaction]
requires:
  - phase: 39-03
    provides: durable logout event and delivery snapshots for worker execution
provides:
  - named Lockspire-owned Oban runtime with fail-fast config validation
  - JOSE-backed logout-token signing for back-channel logout deliveries
  - snapshot-authoritative logout delivery worker using Req with bounded retries
  - truthful logout lifecycle telemetry, audit events, and redaction coverage
affects: [phase-39-05, phase-39-06, logout-propagation, observability]
tech-stack:
  added: [req]
  patterns: [named-oban-runtime, snapshot-authoritative-workers, logout-lifecycle-instrumentation]
key-files:
  created: [lib/lockspire/oban.ex, lib/lockspire/protocol/logout_token.ex, lib/lockspire/workers/backchannel_logout_delivery_worker.ex]
  modified: [mix.exs, mix.lock, lib/lockspire/application.ex, lib/lockspire/observability.ex, lib/lockspire/audit/event.ex, lib/lockspire/redaction.ex, test/lockspire/application_test.exs, test/lockspire/protocol/logout_token_test.exs, test/lockspire/workers/backchannel_logout_delivery_worker_test.exs]
key-decisions:
  - "Lockspire starts its own named Oban instance and raises immediately when repo or Oban runtime config is missing or invalid."
  - "Back-channel delivery dispatch stays authoritative to the persisted logout_delivery snapshot instead of re-reading live client logout metadata."
  - "Logout lifecycle instrumentation is split into requested, enqueued, attempted, succeeded, failed, and discarded stages with raw tokens and raw response payloads redacted before telemetry or audit emission."
patterns-established:
  - "Named Oban runtime: library-owned queues start through Lockspire.Application with explicit runtime validation."
  - "Snapshot-authoritative worker: durable delivery rows carry the URI and delivery policy needed for dispatch without live client re-resolution."
  - "Lifecycle instrumentation: telemetry and audit helpers share canonical logout stage names and redact sensitive payloads at the boundary."
requirements-completed: [SLO-03]
duration: 13min
completed: 2026-04-29
---

# Phase 39 Plan 04: Automated RP Logout Propagation Summary

**Named Oban startup, JOSE logout-token signing, and snapshot-authoritative back-channel logout delivery with truthful lifecycle instrumentation**

## Performance

- **Duration:** 13 min
- **Started:** 2026-04-29T19:26:52Z
- **Completed:** 2026-04-29T19:40:32Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added `Req` and a named `Lockspire.Oban` runtime that fails fast when required repo or Oban config is missing or invalid.
- Implemented logout-token signing plus an Oban worker that posts `logout_token=<jwt>` from persisted logout delivery snapshots and classifies retryable versus terminal failures.
- Added explicit logout lifecycle telemetry and audit helpers for requested, enqueued, attempted, succeeded, failed, and discarded stages, with redaction coverage for raw tokens and sensitive response payloads.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Req and named Lockspire Oban startup wiring** - `5382161` (test), `75ff291` (feat)
2. **Task 2: Build logout-token signing and snapshot-authoritative worker execution** - `e606900` (test), `b872e7f` (feat)
3. **Task 3: Add full logout lifecycle telemetry, audit, and redaction coverage** - `d97c437` (feat)

## Files Created/Modified

- `mix.exs` and `mix.lock` - add `Req` and resolve the new runtime dependency graph.
- `lib/lockspire/application.ex` and `lib/lockspire/oban.ex` - start a named Lockspire-owned Oban instance with validated runtime config.
- `lib/lockspire/protocol/logout_token.ex` - sign OIDC back-channel logout tokens from persisted logout event and delivery data.
- `lib/lockspire/workers/backchannel_logout_delivery_worker.ex` - deliver snapshot-backed logout POSTs, persist lifecycle state, and classify retryable versus terminal outcomes.
- `lib/lockspire/observability.ex`, `lib/lockspire/audit/event.ex`, and `lib/lockspire/redaction.ex` - define canonical logout lifecycle events and redact sensitive logout payloads.
- `test/lockspire/application_test.exs`, `test/lockspire/protocol/logout_token_test.exs`, and `test/lockspire/workers/backchannel_logout_delivery_worker_test.exs` - lock startup, signing, dispatch, retry, and redaction behavior with regression coverage.

## Decisions Made

- Lockspire owns a named Oban runtime instead of borrowing the host app's default Oban name, which keeps queue wiring explicit for an embedded library.
- The delivery worker treats the persisted `logout_delivery` row as the authoritative dispatch contract so logout propagation remains truthful to the pre-revocation snapshot.
- Logout lifecycle helpers emit distinct attempted, succeeded, failed, and discarded stages so telemetry and audit surfaces reflect actual worker behavior instead of inferred state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Substituted `--trace` for unsupported `mix test -x`**
- **Found during:** Task 1, Task 2, and Task 3 verification
- **Issue:** The current Mix version rejects the plan's `mix test ... -x` commands with `** (Mix) Could not invoke task "test": 1 error found! -- unknown option -x`.
- **Fix:** Ran the same targeted test files with `--trace`, which is supported in this environment and preserves detailed execution output.
- **Files modified:** None
- **Verification:** `MIX_ENV=test mix test test/lockspire/application_test.exs --trace`; `MIX_ENV=test mix test test/lockspire/protocol/logout_token_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs --trace`; `MIX_ENV=test mix test test/lockspire/application_test.exs test/lockspire/protocol/logout_token_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs --trace`
- **Committed in:** Verification-only substitution; no code change required

**2. [Rule 3 - Blocking] Accepted legacy persisted signing-key encoding in logout-token signing**
- **Found during:** Task 2 (Build logout-token signing and snapshot-authoritative worker execution)
- **Issue:** Active signing keys in the current repo can be stored as legacy `:erlang.term_to_binary/1` payloads rather than JSON JWK strings, which caused logout-token signing to fail against existing stored keys.
- **Fix:** Extended logout-token key loading to accept both JSON JWK payloads and safe-decoded legacy term binaries before signing.
- **Files modified:** `lib/lockspire/protocol/logout_token.ex`, `test/lockspire/protocol/logout_token_test.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/protocol/logout_token_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs --trace`
- **Committed in:** `b872e7f`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both deviations were required for environment compatibility and correct signing behavior. Scope remained within the plan's intended runtime delivery surface.

## Issues Encountered

- Worker-level JWT verification could not reliably depend on a freshly inserted signing-key fixture because the repository resolves the active key independently. I kept full cryptographic signing assertions in `logout_token_test.exs` and used payload inspection plus delivery-state assertions in the worker tests.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 39-05 can now enqueue back-channel logout work against a named Lockspire Oban runtime and rely on durable worker lifecycle transitions.
- The logout lifecycle event vocabulary is established for completion-endpoint orchestration, admin surfaces, and future end-to-end observability checks.

## Verification

- `MIX_ENV=test mix test test/lockspire/application_test.exs --trace` - passed
- `MIX_ENV=test mix test test/lockspire/protocol/logout_token_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs --trace` - passed
- `MIX_ENV=test mix test test/lockspire/workers/backchannel_logout_delivery_worker_test.exs --trace` - passed
- `MIX_ENV=test mix test test/lockspire/application_test.exs test/lockspire/protocol/logout_token_test.exs test/lockspire/workers/backchannel_logout_delivery_worker_test.exs --trace` - passed (`12 tests, 0 failures`)

## Self-Check

PASSED

- Found `.planning/phases/39-automated-rp-logout-propagation/39-04-SUMMARY.md`
- Verified task commits `5382161`, `75ff291`, `e606900`, `b872e7f`, and `d97c437` in `git log --oneline --all`

---
*Phase: 39-automated-rp-logout-propagation*
*Completed: 2026-04-29*
