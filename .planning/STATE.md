---
gsd_state_version: 1.0
milestone: v1.37
milestone_name: Prime-Time Readiness Ratchet
current_phase: 133
current_phase_name: Clean-Room SaaS Journey
status: planning
stopped_at: Phase 133 context gathered (assumptions mode)
last_updated: "2026-08-27T00:30:00.000Z"
last_activity: 2026-08-26
last_activity_desc: Phase 132 complete, transitioned to Phase 133
progress:
  total_phases: 7
  completed_phases: 2
  total_plans: 11
  completed_plans: 11
  percent: 29
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 133 — Clean-Room SaaS Journey

## Current Position

Phase: 133 — Clean-Room SaaS Journey
Plan: Not started
Status: Ready to plan
Last activity: 2026-08-26 — Phase 132 complete, transitioned to Phase 133

Progress: [███░░░░░░░] 29%

## Accumulated Context

### Decisions

- v1.37 is an evidence-led readiness milestone: installation and the clean-room SaaS journey are the acceptance spine.
- Public API changes are additive or deprecation-only; supported v1.x behavior and security defaults remain compatible.
- The host owns accounts, login, branding, tenant/product policy, and operator authentication; Lockspire remains an embedded library.
- Admin visual redesign and formal certification are excluded while maintainer review capacity is limited.
- [Phase 131]: Generated Lockspire routes are an imported Phoenix macro; host-owned verification and consent routes precede an explicitly operator-guarded admin forward and public router.
- [Phase 131]: Install config declares the host logout path, and the account-resolver example uses only subject, id_token, and userinfo Claims fields.
- [Phase 131]: Migration installation preflights the complete package and host inventories before creating files, and exclusive writes preserve the host no-overwrite boundary.
- [Phase 131]: ConsentContext exposes only safe host display fields and terminal redirects.
- [Phase 131]: Installer consent template must exactly match a compiling executable fixture.
- [Phase 131]: Default generated smoke proves the :none profile, discovery/JWKS, S256 PKCE, and exact redirects; FAPI proof is explicit and separately discovered.
- [Phase 131]: Install verification now aggregates independently actionable runtime, seam, compiled-route, and host-migration diagnostics.
- [Phase 131]: Generated consent renders a non-interactive loading status and snapshots mount-time host resolver context for deferred authoritative lookup.
- [Phase 132]: `Lockspire.AccessToken` is the canonical semantic parser for subject, scopes, audiences, expiration, and allowlisted sender confirmation; raw claims remain compatible.
- [Phase 132]: Direct and dynamic client registration share a neutral capability validator, with optional RFC 7591 scope metadata kept distinct from the direct facade's required scope list.
- [Phase 132]: Protected-resource DPoP replay recording defaults to the configured durable Ecto repository; incompatible or failing custom stores fail closed.
- [Phase 132]: Lockspire establishes protocol validity and sender constraints, while the host separately owns tenant, object, billing, product, response, and rate-limit authorization.

### Pending Todos

None yet.

### Blockers/Concerns

None active.

## Session Continuity

Last session: 2026-08-27T00:30:00.000Z
Stopped at: Phase 133 context gathered (assumptions mode)
Resume file: .planning/phases/133-clean-room-saas-journey/133-CONTEXT.md

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
| Phase 132 P01 | 7m | 2 tasks | 4 files |
| Phase 132 P02 | 16m | 2 tasks | 8 files |
| Phase 132 P03 | 12m | 2 tasks | 5 files |
| Phase 132 P04 | - | 2 tasks | 12 files |
