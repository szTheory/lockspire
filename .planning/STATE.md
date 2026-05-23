---
gsd_state_version: 1.0
milestone: v1.21
milestone_name: Resource Server (API Protection)
status: completed
stopped_at: milestone completed
last_updated: "2026-05-23T18:55:00.000Z"
last_activity: 2026-05-23 -- Milestone v1.21 successfully completed and archived.
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** Awaiting next milestone.

## Current Position

Phase: 81
Plan: 03
Status: completed
Last activity: 2026-05-23 -- Milestone v1.21 successfully completed and archived.

## Performance Metrics

- Phases completed: 3/3
- Plans completed: 9/9

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 79 | 01,02,03 | ~30m | 9 | 9 |
| 80 | 01,02,03 | ~75m | 6 | 18 |
| 81 | 01,02,03 | ~39m | 7 | 16 |

## Deferred Items

None.

## Accumulated Context

### Decisions

- Milestone v1.20 Mutual TLS (RFC 8705) will be implemented via an explicit extraction behaviour (`Lockspire.MTLS.Extractor`).
- Proxy extraction MUST be explicitly configured by the host app.
- Protected Phoenix API routes use `VerifyToken -> EnforceSenderConstraints -> RequireToken` as the canonical shipped pipeline.
- Route-level audience mismatches stay `401 invalid_token`, while scope failures render `403 insufficient_scope`.

### Blockers/Concerns

- None

## Session Continuity

**Next action:** Awaiting user to start a new milestone or task.
**Resume file:** None
**Stopped at:** milestone completed
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
