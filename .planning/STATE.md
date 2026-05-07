---
gsd_state_version: 1.0
milestone: v1.16
milestone_name: "Embedded Adoption Hardening & Sigra Golden Path"
status: phase_complete
stopped_at: "phase 66 complete; awaiting post-phase milestone-close workflow"
last_updated: "2026-05-07T14:30:01Z"
last_activity: 2026-05-07
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 13
  completed_plans: 13
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** v1.16 embedded adoption hardening, release-truth completion, and conformance debt retirement

## Current Position

Phase: 66 complete
Plan: 66-03 complete
Status: v1.16 closure audit and planning-state alignment complete; milestone rollover remains owned by the post-phase milestone-close workflow
Last activity: 2026-05-07 — Completed Phase 66 conformance-debt retirement, historical non-claim alignment, and the v1.16 milestone audit

## Performance Metrics

- Phases completed: 4/4
- Plans completed: 13/13

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 63 | 63-01..63-04 | complete | 8 | install/docs/tests |
| 64 | 64-01..64-03 | complete | 8 | generated-host/docs/tests |
| 65 | 65-01..65-03 | complete | 7 | release/docs/tests |
| 66 | 66-01..66-03 | complete | 6 | docs/planning |

## Deferred Items

Items preserved as historical audit context at milestone close on 2026-05-07:

| Category | Item | Status |
|----------|------|--------|
| verification | 37-VERIFICATION.md | retired_non_claim_historical_context |

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

- No live blocker remains for v1.16 closure. The historical Phase 37 external-suite lane is retired as a non-claim for the current support story and preserved only as audit-trail context alongside `37-VERIFICATION.md`.
- Milestone progress rollover, archival, and any next-milestone activation remain owned by the post-phase milestone-close workflow rather than this phase plan.

## Session Continuity

**Next action:** Run the post-phase milestone-close workflow to roll roadmap/archive state forward from the completed v1.16 closure audit

**Resume file:** None

**Stopped at:** phase 66 complete; awaiting post-phase milestone-close workflow

**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
