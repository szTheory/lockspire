---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: PAR Foundation
status: human_needed
last_updated: "2026-04-24T15:40:00.000Z"
last_activity: 2026-04-24 -- Phase 16 awaiting live human verification
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 8
  completed_plans: 6
  percent: 75
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 16 — verification-and-release-runtime-hygiene

## Current Position

Milestone: v1.2 — PAR Foundation

Phase: 16 (verification-and-release-runtime-hygiene) — HUMAN VERIFICATION PENDING

Plan: 2 of 2 complete

Status: Awaiting live GitHub Actions verification for the Release workflow recovery lane

Last activity: 2026-04-24 -- Phase 16 awaiting live human verification

## Performance Metrics

- Phases completed: 2/3
- Plans completed: 6/6
- Recorded tasks completed: 10
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

### Pending Todos

- Run the `Release` workflow on `workflow_dispatch` with an invalid branch ref and confirm it fails before publish.
- Run the `Release` workflow on `workflow_dispatch` with a valid 40-character SHA or existing tag and confirm it proceeds without the deprecated Node 20 warning.

### Blockers/Concerns

- Phase 16 is blocked only on live GitHub Actions proof of the recovery-ref enforcement and warning-free runtime; local repo verification is complete.

## Session Continuity

**Next action:** Execute the `16-HUMAN-UAT.md` recovery workflow checks, then approve Phase 16 so it can be marked complete.

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Completed Milestone:** v1.1 (Release Hardening) — archived to `.planning/milestones/v1.1-*` with a `tech_debt` audit verdict limited to Nyquist completeness gaps and the `release-please-action` Node.js 20 warning.
