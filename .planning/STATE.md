---
gsd_state_version: 1.0
milestone: v1.27
milestone_name: Phoenix Resource Server Token Acceptance
status: executing
stopped_at: Phase 99 context gathered (assumptions mode)
last_updated: "2026-05-28T11:39:08.797Z"
last_activity: 2026-05-28
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 9
  completed_plans: 9
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security defaults while keeping account, login, tenant policy, and operator authentication in the host app.

**Current focus:** Phase 98 — plug-hardening

## Current Position

Phase: 99
Plan: Not started
Status: Executing Phase 98
Last activity: 2026-05-28

Progress: [░░░░░░░░░░] 0% (0/6 phases, 0 plans)

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
| v1.26 | 94-96 | 3 | 5 | shipped |
| v1.25 | 91-93 | 9 | 9 | shipped |
| v1.24 | 88-90 | 9 | 7 | shipped |

## v1.27 Phase Plan

| Phase | Name | REQs | UI |
|-------|------|------|----|
| 97 | Contract + Docs First | 3 | no |
| 98 | Plug Hardening | 6 | no |
| 99 | Signer Extraction + JWT-Default Issuance | 8 | yes (admin client-detail) |
| 100 | Sender-Constraint End-to-End Proof | 3 | no |
| 101 | Adoption-Demo Re-Wire | 3 | no |
| 102 | Generated-Host Scaffolding + Telemetry + Migration | 5 | yes (install template) |

## Decisions

- v1.27 is the deliberate exception to the standing sustainment default; opened because adoption-demo evidence in PR #44 exposed the RS-token-shape tension as the next highest-leverage adopter wedge.
- Branch A + JWT-default issuance is the resolution: narrow `Lockspire.Plug.VerifyToken` to RFC 9068 `at+jwt` only; flip default access-token issuance to `:jwt` for AC/refresh/device/CIBA; keep opaque as a per-client opt-in for `/userinfo` and `/introspect`.
- Phase 97 (contract + docs) must land before any runtime implementation; the canon is explicit that docs is a contract the implementation honors.
- Sustainment patch-train work continues in parallel on `main` while v1.27 feature work runs on `milestone/v1.27-phoenix-rs-token-acceptance`.

## Blockers/Concerns

- None active. v1.27 has 28 requirements mapped 100% across 6 phases with no orphans.

## Session Continuity

**Next action:** Plan Phase 97 (Contract + Docs First). The canonical pipeline-declaration block, single authoritative `docs/protect-phoenix-api-routes.md` page, supported-surface non-goals, and the `release_readiness_contract_test` content-hash assertion all land before any plug or signer code changes.
**Resume file:** .planning/phases/99-signer-extraction-jwt-default-issuance/99-CONTEXT.md
**Stopped at:** Phase 99 context gathered (assumptions mode)
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md
