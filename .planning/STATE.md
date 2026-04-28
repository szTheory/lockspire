---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: dpop-core
status: executing
stopped_at: Completed 33-03-PLAN.md
last_updated: "2026-04-28T15:26:00Z"
last_activity: 2026-04-28 -- Phase 33 execution completed
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 12
  completed_plans: 3
  percent: 25
---

# Project State

## Project Reference

See: `.planning/PROJECT.md`

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 34 — token issuance and refresh/device binding

## Current Position

Phase: 34 (token-issuance-and-refresh-device-binding) — NOT STARTED
Plan: —
Status: Phase 33 complete; Phase 34 is next
Last activity: 2026-04-28 -- Phase 33 execution completed

## Performance Metrics

- Phases completed: 1/4 (v1.7)
- Plans completed: 3/12 (v1.7)

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions and archived milestones.

- **v1.7 DPoP Core**: The next milestone should strengthen the real-client trust story rather than add breadth for its own sake.
- The next wedge should optimize first for public and CLI-oriented clients because that is where sender-constrained tokens most improve the current preview surface.
- DPoP is preferred over mTLS for this milestone because it composes with the embedded Phoenix library shape and the device-flow path without introducing enterprise PKI assumptions.
- The first DPoP milestone should be a usable core: proof validation, token binding, replay protection, owned-surface consumption, and truthful discovery/docs.
- The longer-range milestone arc should be persisted in `.planning/EPIC.md` so future milestone selection compounds from repo truth.
- Phase 33-02 keeps DPoP replay storage narrow and durable around a unique replay key plus explicit proof claims instead of a generic cache abstraction.
- Phase 33-02 rejects replayed proofs on the token-endpoint preflight seam now, while leaving cnf binding and token_type work for Phase 34.
- Model DPoP enablement as explicit durable enums instead of metadata so bearer-default behavior and later admin/DCR truth remain deterministic.
- Keep server policy as :bearer | :dpop and client policy as :inherit | :bearer | :dpop so existing clients stay inherited while explicit overrides can narrow or opt in.
- Make the resolver return explicit invalid-policy errors instead of silently coercing malformed state into bearer behavior.

### Blockers/Concerns

- No current execution blockers.
- DPoP replay protection and proof-validation boundaries need deliberate scope control so the milestone stays narrow and repo-verifiable.

## Session Continuity

**Next action:** Start `$gsd-plan-phase 34`

**Resume file:** None

**Stopped at:** Completed 33-03-PLAN.md

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Planned Phase:** 34 — Token issuance and refresh/device binding
