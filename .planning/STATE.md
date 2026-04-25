---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: JAR and Request Objects
status: executing
stopped_at: Completed 22-07-PLAN.md
last_updated: "2026-04-25T21:58:28.365Z"
last_activity: 2026-04-25
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 10
  completed_plans: 10
  percent: 100
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

Status: Completed

Last activity: 2026-04-25

## Performance Metrics

- Phases completed: 0/4 (v1.4)
- Plans completed: 6/10 (v1.4)
- Recorded tasks completed: 9 (v1.4)
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
- Extend the existing Phase 15 PAR e2e file with one JAR-via-PAR branch instead of creating a parallel phase22 JAR e2e file.
- Valid Basic auth remains required at /par; JAR signing is additive and does not replace client authentication.
- Proved the JAR request object composes through /par, /authorize, consent, and /token without changing the downstream PAR flow.

### Blockers/Concerns

- No current execution blockers.

## Session Continuity

**Next action:** Continue with remaining Phase 22 work or milestone verification.

**Resume file:** None

**Stopped at:** Completed 22-07-PLAN.md

**Ecosystem:** `.planning/ECOSYSTEM-SIGRA.md`

**Completed Milestone:** v1.3 (PAR Policy Controls) — archived to `.planning/milestones/v1.3-*`.

**Planned Phase:** 22 (Request Object Integration) — 7 plans — 2026-04-25T16:08:21.045Z
