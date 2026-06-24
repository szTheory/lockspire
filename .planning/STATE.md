---
gsd_state_version: 1.0
milestone: v1.30
milestone_name: Adoption Demo Docker DX & Repo Hygiene
current_phase: 114
current_phase_name: startup-output-smoke-wrapper-docs
status: verifying
stopped_at: Completed 114-03-PLAN.md
last_updated: "2026-06-24T16:57:45.506Z"
last_activity: 2026-06-24
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 9
  completed_plans: 9
  percent: 80
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security defaults while keeping account, login, tenant policy, and operator authentication in the host app.

**Current focus:** Phase 114 — startup-output-smoke-wrapper-docs

## Current Position

Phase: 114 (startup-output-smoke-wrapper-docs) — EXECUTING
Plan: 3 of 3
Status: Phase complete — ready for verification
Last activity: 2026-06-24

## Most Recent Release

- Version: `1.2.0`
- Release PR: `#41 chore(main): release lockspire 1.2.0`
- Milestone PR: `#40 v1.26 Host Integration & Operator Boundary Hardening`
- Protected publish proof: GitHub Actions run `26502800103`
- Install-truth proof: `./scripts/publish/verify_install_truth.sh` passed for `1.2.0`
- GitHub release: `lockspire-v1.2.0`

## Recently Shipped Milestones

| Milestone | Phases | Plans | Requirements | Status |
|-----------|--------|-------|--------------|--------|
| v1.29 | 107-110 | 17 | 24 | shipped |
| v1.28 | 103-106 | 2 | 17 | shipped |
| v1.27 | 97-102 | 24 | 28 | shipped |
| v1.26 | 94-96 | 3 | 5 | shipped |
| v1.25 | 91-93 | 9 | 9 | shipped |

## v1.30 Phase Plan

| Phase | Name | REQs | Focus |
|-------|------|------|-------|
| 111 | Demo URL Contract & Config Unification | 5 | Docker DX |
| 112 | Default Docker Compose App + DB | 6 | Docker DX |
| 113 | Conflict Controls & Optional Traefik | 6 | Docker DX |
| 114 | Startup Output, Smoke Wrapper & Docs | 8 | Demo DX |
| 115 | Repo Hygiene Gate & Scoped Cleanup | 10 | Hygiene |

## Decisions

- v1.29 is a deliberate second-pass admin UI milestone, not an admin UI rebuild.
- v1.29 treats v1.28 as the baseline and focuses hardest on less-polished support, operations, mobile, and cross-route information architecture.
- The admin journey model remains Orient / Configure / Support / Operate.
- The CSS architecture remains BEM/design-token `lockspire-admin-*`; no Tailwind migration, theming engine, or arbitrary override layer.
- Motion is allowed only when it improves orientation, feedback, or state continuity, and must respect reduced-motion preferences.
- Host-owned seams remain unchanged: Lockspire does not own staff authentication, MFA, role checks, tenant policy, layouts, branding, or developer portal UX.
- v1.30 is an adoption-demo Docker DX and repo-hygiene milestone, not a new protocol or admin UI polish milestone.
- Default local demo access should be direct host-port Docker with Traefik as an optional profile.
- `LOCKSPIRE_DEMO_BASE_URL` should become the single public URL truth for endpoint URL, issuer, seeds, docs, startup output, and smoke proof.
- Phase 113 Plan 01 kept direct Docker as the default path and used Compose project-name precedence for resource isolation.
- Phase 113 Plan 01 kept PostgreSQL host-port exposure absent by default and isolated host access in an explicit override file.
- Phase 113 Plan 01 kept reset scoped to active-project `db_data`, `deps_volume`, and `build_volume` Docker volumes.
- [Phase 113]: Phase 113 Plan 02 kept direct Docker as the default path with optional Traefik isolated in an explicit override file.
- [Phase 113]: Phase 113 Plan 02 attached only web to the external Traefik proxy network while keeping db project-internal.
- [Phase 113]: Phase 113 Plan 02 kept LOCKSPIRE_DEMO_BASE_URL as the hostname smoke truth for Traefik mode.
- [Phase 114]: Plan 01 docker-info uses static allowlisted fixture truth instead of database inspection or seed stdout.
- [Phase 114]: Plan 01 docker-start prints startup information only after wait_for_http succeeds.
- [Phase 114]: Plan 02 kept scripts/demo/adoption_smoke.py as the only black-box OAuth/OIDC proof implementation.
- [Phase 114]: Plan 02 used LOCKSPIRE_DEMO_BASE_URL as the only direct Docker versus optional Traefik smoke switch.
- [Phase 114]: Plan 02 recorded docker compose exec against the running web service as INFO-04 reprint truth.
- [Phase 114]: Plan 03 kept Docker as the default maintainer path with host-local Mix/Postgres as fallback.
- [Phase 114]: Plan 03 documented scripts/demo/adoption_smoke.sh as the maintainer smoke entrypoint while preserving the Python smoke as the black-box proof.
- [Phase 114]: Plan 03 left broader cleanup and hygiene command implementation to Phase 115.

## Blockers/Concerns

- None active.
- `gsd-sdk query init.new-milestone` reported stale helper metadata for latest completed milestone and phase archive path after v1.28 closeout. Do not run destructive phase cleanup from that stale path without rechecking archive targets.

## Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260604-fpq | close v1.29 audit gaps from .planning/v1.29-MILESTONE-AUDIT.md | 2026-06-04 | docs-only | [260604-fpq-close-v1-29-audit-gaps-from-planning-v1-](./quick/260604-fpq-close-v1-29-audit-gaps-from-planning-v1-/) |

## Session Continuity

**Last session:** 2026-06-24T16:57:45.499Z

**Next action:** Plan Phase 114 with `$gsd-plan-phase 114`.
**Resume file:** None
**Stopped at:** Completed 114-03-PLAN.md
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 107 P01 | 20 min | 1 tasks | 1 files |
| Phase 107 P02 | 8 min | 1 tasks | 1 files |
| Phase 107 P03 | 6 min | 1 tasks | 1 files |
| Phase 108 P01 | 3 min | 3 tasks | 2 files |
| Phase 108 P02 | 3 min | 3 tasks | 3 files |
| Phase 108 P03 | 5 min | 4 tasks | 8 files |
| Phase 109 P01 | 8 min | 2 tasks | 3 files |
| Phase 109 P02 | 5 min | 2 tasks | 3 files |
| Phase 109 P03 | 7 min | 3 tasks | 6 files |
| Phase 109 P04 | 5 min | 2 tasks | 5 files |
| Phase 109 P05 | 6 min | 2 tasks | 6 files |
| Phase 109 P06 | 6 min | 2 tasks | 5 files |
| Phase 110 P05 | 22 min | 3 tasks | 5 files |
| Phase 111 P01 | 24 min | 2 tasks | 2 files |
| Phase 111 P02 | 18 min | 3 tasks | 3 files |
| Phase 113 P01 | 6 min | 3 tasks | 5 files |
| Phase 113 P02 | 4min | 2 tasks | 3 files |
| Phase 114 P01 | 5 min | 2 tasks | 3 files |
| Phase 114 P02 | 4 min | 3 tasks | 3 files |
| Phase 114 P03 | 8 min | 3 tasks | 3 files |

## Operator Next Steps

- Execute Phase 114 Plan 03.
