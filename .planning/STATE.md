---
gsd_state_version: 1.0
milestone: v1.37
milestone_name: Prime-Time Readiness Ratchet
current_phase: 132
current_phase_name: Public API and Resource-Server Truth
status: planning
stopped_at: Phase 132 context gathered (assumptions mode)
last_updated: "2026-08-26T23:24:27.409Z"
last_activity: 2026-08-26
last_activity_desc: Phase 131 complete, transitioned to Phase 132
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 7
  completed_plans: 7
  percent: 14
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 131 — Executable Installation

## Current Position

Phase: 132 — Public API and Resource-Server Truth
Plan: Not started
Status: Ready to plan
Last activity: 2026-08-26 — Phase 131 complete, transitioned to Phase 132

Progress: [██████████] 100%

## Accumulated Context

### Decisions

- v1.37 is an evidence-led readiness milestone: installation and the clean-room SaaS journey are the acceptance spine.
- Public API changes are additive or deprecation-only; supported v1.x behavior and security defaults remain compatible.
- The host owns accounts, login, branding, tenant/product policy, and operator authentication; Lockspire remains an embedded library.
- Admin visual redesign and formal certification are excluded while maintainer review capacity is limited.
- [Phase ?]: Generated Lockspire routes are an imported Phoenix macro; host-owned verification and consent routes precede an explicitly operator-guarded admin forward and public router.
- [Phase ?]: Install config declares the host logout path, and the account-resolver example uses only subject, id_token, and userinfo Claims fields.
- [Phase ?]: Migration installation preflights the complete package and host inventories before creating files, and exclusive writes preserve the host no-overwrite boundary.
- [Phase 131]: ConsentContext exposes only safe host display fields and terminal redirects.
- [Phase 131]: Installer consent template must exactly match a compiling executable fixture.
- [Phase 131]: Default generated smoke proves the :none profile, discovery/JWKS, S256 PKCE, and exact redirects; FAPI proof is explicit and separately discovered.
- [Phase ?]: Install verification now aggregates independently actionable runtime, seam, compiled-route, and host-migration diagnostics.
- [Phase ?]: Generated consent renders a non-interactive loading status and snapshots mount-time host resolver context for deferred authoritative lookup.

### Pending Todos

None yet.

### Blockers/Concerns

None active.

## Session Continuity

Last session: 2026-08-26T23:24:27.398Z
Stopped at: Phase 132 context gathered (assumptions mode)
Resume file: .planning/phases/132-public-api-and-resource-server-truth/132-CONTEXT.md

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 131 P01 | 8m | 2 tasks | 7 files |
| Phase 131 P02 | 4m | 2 tasks | 2 files |
| Phase 131 P03 | 17min | 2 tasks | 11 files |
| Phase 131 P04 | 18 min | 2 tasks | 7 files |
| Phase 131 P05 | 7 min | 2 tasks | 7 files |
| Phase 131 P06 | 30 min | 2 tasks | 5 files |
| Phase 131 P07 | 19m | 2 tasks | 4 files |
