---
gsd_state_version: 1.0
milestone: v1.17
milestone_name: "Real Public Release"
status: phase_complete
stopped_at: "phase 67 execution complete"
last_updated: "2026-05-07T15:40:00Z"
last_activity: 2026-05-07
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security FAPI 2.0 standards.

**Current focus:** v1.17 phase 68 publish verification and install truth

## Current Position

Phase: 68 (next up)
Plan: —
Status: Phase 67 complete
Last activity: 2026-05-07 — Phase 67 execution completed

## Performance Metrics

- Phases completed: 1/3
- Plans completed: 3/3

| Phase | Plan | Duration | Tasks | Files |
|-------|------|----------|-------|-------|
| 67 | 67-01..67-03 | completed | 5 | release/docs/tests |
| 68 | — | planned | — | publish verification |
| 69 | — | planned | — | planning/closure |

## Deferred Items

Items acknowledged and deferred at milestone close on 2026-05-07:

| Category | Item | Status |
|----------|------|--------|
| verification | 37-VERIFICATION.md | retired_non_claim_historical_context |
| seed | 001-cut-next-real-release | dormant |

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

- The real public release must stay scoped to release execution and truth verification rather than reopening product-surface expansion.
- Publish verification depends on trusted release credentials and public package visibility, so the milestone must separate repo-owned proof from protected-environment execution evidence cleanly.

## Session Continuity

**Next action:** Begin Phase 68 publish verification and install-truth execution

**Resume file:** None

**Stopped at:** phase 67 execution complete

**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
