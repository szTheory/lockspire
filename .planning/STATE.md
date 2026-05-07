---
gsd_state_version: 1.0
milestone: v1.16
milestone_name: "Embedded Adoption Hardening & Sigra Golden Path"
status: defining_requirements
stopped_at: "v1.16 planned; phase work not started"
last_updated: "2026-05-06T16:00:00Z"
last_activity: 2026-05-06
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** v1.16 embedded adoption hardening, Sigra golden-path proof, release truth, and conformance debt retirement

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-06 — Started v1.16 milestone planning for embedded adoption hardening and Sigra golden-path proof

## Performance Metrics

- Phases completed: 0/4
- Plans completed: 0/0

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 63 | — | planned | — | — |
| 64 | — | planned | — | — |
| 65 | — | planned | — | — |
| 66 | — | planned | — | — |

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| verification | 37-VERIFICATION.md | gaps_found |

## Accumulated Context

### Decisions

- Completed v1.14 Advanced Authorization & Resource Targetting milestone.
- Added Resource Indicators (RFC 8707) and Rich Authorization Requests (RFC 9396).
- Kept RAR validation and consent semantics host-owned through explicit seams.
- Resolved RAR introspection by durable consent-grant reference rather than token bloat.
- Phase 59 admits and persists the narrow `private_key_jwt` + `jwks_uri` registration slice.
- Phase 59 admin surfaces derive and expose read-only `private_key_jwt` policy truth from existing server policy and security profile.
- Phase 59 discovery metadata omits `private_key_jwt` until cryptographic verification ships, keeping public metadata truthful to current runtime behavior.
- Phase 60 hardens `Lockspire.JwksFetcher` into a narrow security boundary with `https`-only fetches, redirects disabled, retries disabled, stable failure tuples, and low timeout budgets.
- Phase 60 rejects unsafe resolved targets and oversized JWKS payloads before remote key retrieval can widen trust.
- Phase 60 exposes explicit JWKS cache TTL and a single bounded forced-refresh path that preserves the last-known-good cache entry on refresh failure.
- Phase 61 moves `private_key_jwt` client authentication to a shared staged verifier with explicit key resolution, JOSE signature verification, trusted-claim enforcement, and post-verification replay recording.
- Phase 61 aligns discovery, introspection, direct-client endpoint behavior, telemetry, audit, and redaction around the same shared runtime capability.
- v1.16 will prioritize embedded adoption hardening over new protocol breadth.
- The chosen v1.16 wedge is a canonical Sigra-backed host path with executable generated-host proof, release-truth reconciliation, and selective conformance debt retirement.
- `client_secret_jwt` remains deferred because it has lower leverage than adoption proof and pressures Lockspire's hashed-secret posture.

### Blockers/Concerns

- Historical Phase 37 verification debt remains acknowledged and deferred.

## Session Continuity

**Next action:** Run `$gsd-plan-phase 63` to start execution

**Resume file:** None

**Stopped at:** v1.16 planned; phase execution not yet started

**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
