---
gsd_state_version: 1.0
milestone: v1.27
milestone_name: Phoenix Resource Server Token Acceptance
status: Awaiting next milestone
last_updated: "2026-06-03T00:12:54.618Z"
last_activity: 2026-06-03 — Milestone v1.27 completed and archived
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 24
  completed_plans: 24
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security defaults while keeping account, login, tenant policy, and operator authentication in the host app.

**Current focus:** Phase 102 — generated-host-scaffolding-telemetry-migration

## Current Position

Phase: Milestone v1.27 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-03 — Milestone v1.27 completed and archived

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
- [Phase ?]: TELEMETRY-01: [:lockspire, :rs, :token_format] emitted via direct :telemetry.execute/3 at two VerifyToken sites; :jwt at format-confirmation time (independent of apply_restrictions/2), literal :"opaque-rejected" with all-nil metadata on the opaque branch; deliberately not Observability.emit/4 (avoids audit double-emit + nil-metadata redaction drop).
- [Phase ?]: Phase 102-04: token_format doctor reproduces AccessTokenSigner.resolve_format/2 precedence inline (effective_format/2) rather than promoting the signer fn public; read-only/diagnostic-only (no Mix.raise/non-zero exit on flagged clients).
- [Phase ?]: Phase 102-03: docs/upgrading/v1.27.md documents the issuance default flip with the honest runtime opt-out (ServerPolicy.put_access_token_format(:opaque), NOT a config :lockspire key) and the nil-inherit affected-client set; pinned by a release_readiness_contract_test clause (MIGRATE-01).

## Blockers/Concerns

- None active. v1.27 has 28 requirements mapped 100% across 6 phases with no orphans.

## Session Continuity

**Next action:** Plan Phase 97 (Contract + Docs First). The canonical pipeline-declaration block, single authoritative `docs/protect-phoenix-api-routes.md` page, supported-surface non-goals, and the `release_readiness_contract_test` content-hash assertion all land before any plug or signer code changes.
**Resume file:** None
**Stopped at:** Phase 102 context gathered (assumptions mode)
**Ecosystem:** .planning/ECOSYSTEM-SIGRA.md

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 101-adoption-demo-re-wire P01 | 10 | 1 tasks | 4 files |
| Phase 101 P02 | 5min | 1 tasks | 1 files |
| Phase 102 P01 | ~10min | 2 tasks | 1 files |
| Phase 102 P02 | ~3min | 2 tasks | 2 files |
| Phase 102 P04 | ~12min | 2 tasks | 3 files |
| Phase 102 P03 | 6min | 2 tasks | 2 files |

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
