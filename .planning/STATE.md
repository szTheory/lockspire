---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: PAR Foundation
status: defining_requirements
last_updated: "2026-04-24T12:47:13Z"
last_activity: 2026-04-24 -- Started v1.2 milestone and reset planning state
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Define and stage the v1.2 PAR Foundation milestone.

## Current Position

Milestone: v1.2 — PAR Foundation

Phase: Not started (defining requirements)

Plan: -

Status: Defining requirements

Last activity: 2026-04-24 -- Milestone v1.2 started

## Performance Metrics

- Phases completed: 0/0
- Plans completed: 0/0
- Recorded tasks completed: 0
- Timeline: 2026-04-24 -> present

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions. The v1.0 milestone locked the embedded-library product shape, narrow host seam, Phoenix-native operator UX, Ecto/Postgres durable storage default, and preview-before-1.0 release posture. The v1.1 milestone adds a polish-first sequencing decision: make the current preview surface boring to ship before expanding protocol breadth, with PAR queued next. Phase 12 also locked the closure rule that the final blocker was missing verification rollup/traceability, not missing trusted release implementation.

- Keep Phase 12 limited to the missing verification rollup and state tracking; do not reopen release implementation or requirements-ledger edits.
- Anchor RELS-01 through RELS-03 closure on existing Phase 11 evidence, Phase 08 verification, the milestone audit, and the Phase 11 validation record.
- Treat `.planning/milestones/v1.1-MILESTONE-AUDIT.md` as the canonical source of the final milestone gaps and frame roadmap/state only as prior handoff artifacts later corrected by that audit.
- Reconcile RELS-01 through RELS-03 to Phase 12 completion without attributing new release-path implementation to Phase 13.
- Keep v1.2 narrow: PAR extends the authorization request path, but does not justify dynamic registration, device flow, sender-constrained tokens, or hosted-auth ambitions.

### Pending Todos

- Define milestone-scoped v1.2 requirements for PAR and release-tooling hygiene.
- Split the milestone into executable phases and map every requirement.
- Decide whether Nyquist backfill belongs inside a v1.2 phase or remains deferred tech debt.

### Blockers/Concerns

- The `googleapis/release-please-action` pin still emits a Node.js 20 deprecation warning during the successful release run and should be upgraded before the GitHub runner cutoff.

## Session Continuity

**Next action:** Finish `$gsd-new-milestone` by writing research, requirements, and the v1.2 roadmap.

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Completed Milestone:** v1.1 (Release Hardening) — archived to `.planning/milestones/v1.1-*` with a `tech_debt` audit verdict limited to Nyquist completeness gaps and the `release-please-action` Node.js 20 warning.
