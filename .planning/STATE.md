---
gsd_state_version: 1.0
milestone: v1.3
milestone_name: PAR Policy Controls
status: complete
last_updated: "2026-04-24T21:00:00.000Z"
last_activity: 2026-04-24
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 20 — Verification and Milestone Closure

## Current Position

Milestone: v1.3 — PAR Policy Controls

Phase: 20 (Verification and Milestone Closure) — COMPLETE

Plan: 2 of 2

Status: Milestone complete — all requirements verified

Last activity: 2026-04-24

## Performance Metrics

- Phases completed: 4/4
- Plans completed: 8/8
- Recorded tasks completed: 22
- Timeline: 2026-04-24 -> present

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions. The v1.0 milestone locked the embedded-library product shape, narrow host seam, Phoenix-native operator UX, Ecto/Postgres durable storage default, and preview-before-1.0 release posture. The v1.1 milestone adds a polish-first sequencing decision: make the current preview surface boring to ship before expanding protocol breadth, with PAR queued next. Phase 12 also locked the closure rule that the final blocker was missing verification rollup/traceability, not missing trusted release implementation.

- Keep Phase 12 limited to the missing verification rollup and state tracking; do not reopen release implementation or requirements-ledger edits.
- Anchor RELS-01 through RELS-03 closure on existing Phase 11 evidence, Phase 08 verification, the milestone audit, and the Phase 11 validation record.
- Treat `.planning/milestones/v1.1-MILESTONE-AUDIT.md` as the canonical source of the final milestone gaps and frame roadmap/state only as prior handoff artifacts later corrected by that audit.
- Reconcile RELS-01 through RELS-03 to Phase 12 completion without attributing new release-path implementation to Phase 13.
- Keep v1.2 narrow: PAR extends the authorization request path, but does not justify dynamic registration, device flow, sender-constrained tokens, or hosted-auth ambitions.
- PAR request_uri values are stored durably by hash, not plaintext.
- Burn PAR references inside the repository transaction even on wrong-client or expired use so replay resistance does not depend on controller logic.
- Resolve Lockspire-issued PAR references into canonical authorization params before validation so AuthorizationFlow keeps the existing %Validated{} contract.
- Advertise PAR only through pushed_authorization_request_endpoint when the mounted /par route exists.
- Describe PAR publicly only as Lockspire-issued request_uri support on the existing authorization code plus PKCE flow.
- Keep 15-03 proof-only on top of 15-01/15-02 runtime behavior instead of reopening implementation.
- Enforce narrow PAR support claims through discovery, docs, SECURITY, and release contract tests.
- Prioritize PAR policy controls before broader JAR, DCR, device flow, or sender-constrained token work because they tighten the narrow `1.0` path more directly.
- Keep v1.3 limited to PAR policy controls and operator UX; broader request-object interoperability remains a follow-on milestone.
- Pin discovery metadata to capability-only fields, refuting universal-required or JAR-related metadata until implemention proven.
- Enforce shared wording for PAR capability-vs-policy resolution across README, supported-surface, and SECURITY docs.
- Include explicit operator routes and workflow terms (Global/Client/Effective policy) in operator docs to ensure admin-surface explainability.
- Use `.link patch` for internal admin navigation to preserve LiveView state and simplify testing/UX.
- Allow empty string as a valid `mount_path` config to support root-mounted library usage.
- Consolidate all PAR policy resolution branches into a single integration verification artifact for milestone closure.
- Omit 'openid' from registered allowed_scopes as it is implicitly allowed by the protocol and rejected by registration validation.

### Blockers/Concerns

- No current execution blockers. The active constraint is scope discipline: v1.3 should not blur into JAR-by-value, generic external `request_uri`, dynamic client registration, device flow, or release-process expansion.

## Session Continuity

**Next action:** Milestone v1.3 complete. Prepare for the next milestone in the roadmap (e.g., JAR or DCR).

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Completed Milestone:** v1.3 (PAR Policy Controls) — all requirements (PARPOL-01 through PARPOL-06) verified with consolidated integration proof; v1.2 (PAR Foundation) — archived to `.planning/milestones/v1.2-*` with a passed milestone audit and no remaining in-scope gaps.
