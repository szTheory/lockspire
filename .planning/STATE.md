---
gsd_state_version: 1.0
milestone: v1.25
milestone_name: Support-Burden Reduction
status: ready_for_phase_planning
stopped_at: Milestone v1.25 started
last_updated: "2026-05-25T08:15:00Z"
last_activity: 2026-05-25
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

**Current focus:** Start phase planning for milestone v1.25 support-burden reduction work

## Current Position

Phase: Not started
Plan: -
Status: Ready to plan Phase 91
Last activity: 2026-05-25 - Milestone v1.25 defined

## Performance Metrics

- Phases completed: 0/3 in active milestone slot
- Plans completed: 0/9 in active milestone slot

Most recently shipped milestone:

| Milestone | Phases | Plans | Requirements | Status |
|-----------|--------|-------|--------------|--------|
| v1.24 | 88-90 | 9 | 7 | shipped |

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
- Client records now store typed `token_endpoint_auth_signing_alg` truth so `client_secret_jwt` and `HS256` round-trip coherently across DCR, RFC 7592, discovery, and admin surfaces.
- Discovery now publishes `client_secret_jwt` only on the shared verifier endpoints and emits endpoint-local mixed JWT signing-alg unions with `HS256` kept symmetric-only.
- Admin create, detail, and DCR policy surfaces now expose the narrow `client_secret_jwt` slice with read-only `HS256` truth and unchanged secret-handling posture.
- Milestone v1.24 is complete and archived; the next default candidate should favor support-burden reduction over additional protocol breadth.

### Blockers/Concerns

- None

## Session Continuity

**Next action:** $gsd-plan-phase 91
**Resume file:** None
**Stopped at:** Milestone v1.25 started
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
