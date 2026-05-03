---
phase: S01
plan: 02
subsystem: telemetry
tags: [telemetry, observability, fapi, dpop]
dependency_graph:
  requires: [S01-01]
  provides: [S01-INSTRUMENT]
  affects: [protocol-boundary]
tech_stack:
  added: []
  patterns: [telemetry_emission]
key_files:
  created: []
  modified:
    - lib/lockspire/protocol/protected_resource_dpop.ex
    - lib/lockspire/protocol/fapi20_enforcer_plug.ex
decisions:
  - Extract exact failure reason codes and paths into telemetry payload without including sensitive full request metadata.
metrics:
  tasks_completed: 2
  total_tasks: 2
  duration_minutes: 3
  completed_date: "2024-06-25"
---

# Phase S01 Plan 02: Protocol Failure Telemetry Summary

**One-liner:** Emits rich telemetry events on DPoP and FAPI 2.0 protocol validation failures.

## Key Changes

- **DPoP Telemetry:** Injected `Observability.emit/4` into `ProtectedResourceDPoP` failure paths, adding client ID, account ID, and explicit reason codes to the failure metadata.
- **FAPI 2.0 Telemetry:** Injected `Observability.emit/4` into `FAPI20EnforcerPlug` failure paths, ensuring specific protocol requirements (missing request URI, missing DPoP) are logged with context and routing information.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
- [x] Modified files exist
- [x] Commits made with proper hashes
- [x] Tests passed
