---
gsd_state_version: 1.0
milestone: v1.24
milestone_name: client_secret_jwt
status: requirements
stopped_at: defining requirements
last_updated: "2026-05-24T19:00:00Z"
last_activity: 2026-05-24 -- Milestone v1.24 client_secret_jwt started.
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 9
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** Defining requirements for `v1.24 client_secret_jwt`.

## Current Position

Phase: Not started (defining requirements)
Plan: -
Status: Defining requirements
Last activity: 2026-05-24 -- Milestone v1.24 client_secret_jwt started.

## Performance Metrics

- Phases completed: 0/3
- Plans completed: 0/9

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| — | — | — | — | — |

## Deferred Items

None.

## Accumulated Context

### Decisions

- Milestone v1.20 Mutual TLS (RFC 8705) will be implemented via an explicit extraction behaviour (`Lockspire.MTLS.Extractor`).
- Proxy extraction MUST be explicitly configured by the host app.
- Protected Phoenix API routes use `VerifyToken -> EnforceSenderConstraints -> RequireToken` as the canonical shipped pipeline.
- Route-level audience mismatches stay `401 invalid_token`, while scope failures render `403 insufficient_scope`.
- DCR create now accepts logout propagation metadata through shared Lockspire URI/origin validation and persists it on typed client fields.
- DCR create and management-read responses serialize persisted logout metadata directly from stored client state.
- RFC 7592 management update now applies logout propagation metadata through the same normalized typed-field path and clears omitted values under full-replace semantics.
- Repo-native proof for logout metadata management now covers rotated RAT truth, provenance/audit continuity, and negative validation contracts across protocol and controller seams.
- DCR and RFC 7592 now manage the existing logout propagation metadata while preserving the durable back-channel and best-effort front-channel truth model.

### Blockers/Concerns

- None

## Session Continuity

**Next action:** Start with `$gsd-plan-phase 88` after reviewing the new roadmap, or use `$gsd-discuss-phase 88` to refine the implementation approach first.
**Resume file:** None
**Stopped at:** defining requirements
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
