---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: JAR and Request Objects
status: executing
stopped_at: Completed 22-06-PLAN.md
last_updated: "2026-04-25T21:13:22.658Z"
last_activity: 2026-04-25
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 10
  completed_plans: 9
  percent: 90
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-24)

**Core value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 22 — Request Object Integration

## Current Position

Milestone: v1.4 — JAR and Request Objects

Phase: 22

Plan: 07

Status: Ready to execute

Last activity: 2026-04-25

## Performance Metrics

- Phases completed: 0/4 (v1.4)
- Plans completed: 5/10 (v1.4)
- Recorded tasks completed: 8 (v1.4)
- Timeline: 2026-04-24 -> present

## Accumulated Context

### Decisions

See `PROJECT.md` Key Decisions and archived milestones.

- Milestone v1.3 successfully established PAR policy controls (Global/Client/Effective) and hardened the truthful PAR support surface.
- Milestone v1.4 expands interoperability via JWT Secured Authorization Requests (JAR - RFC 9101).
- Phase 21 structure: 01 (Foundation/Parsing), 02 (Signatures), 03 (Security Claims).
- Reuse existing client key infrastructure for request object signature validation.
- Use JOSE.JWT.peek_payload and JOSE.JWS.peek_protected for initial unverified JAR decoding.
- Represent JAR as a struct with :claims and :header fields.
- Consume signed request objects before `validate_with_client/3` so the existing `/authorize` pipeline stays unchanged after projection.
- Treat `request` + `request_uri` as a sealed-envelope conflict and pin the request-object reason-code matrix at the protocol seam.
- Use a fresh JAR-capable client fixture in the controller test describe block because client updates do not persist jwks.
- Assert the browser-error page by its rendered headline and the valid-JAR handoff by the existing /sign-in redirect shape.
- Treat the happy-path redirect as the redirect-safe proof because D-16 makes JAR-failure redirect safety unreachable at this seam.

### Blockers/Concerns

- No current execution blockers.

## Session Continuity

**Next action:** Execute Phase 22 Plan 07.

**Resume file:** None

**Stopped at:** Completed 22-06-PLAN.md

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Completed Milestone:** v1.3 (PAR Policy Controls) — archived to `.planning/milestones/v1.3-*`.

**Planned Phase:** 22 (Request Object Integration) — 7 plans — 2026-04-25T16:08:21.045Z
