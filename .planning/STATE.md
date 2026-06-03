---
gsd_state_version: 1.0
milestone: v1.28
milestone_name: Admin UI Operator Experience Polish
status: Awaiting next milestone
last_updated: "2026-06-03T22:35:00.000Z"
last_activity: 2026-06-03 — Milestone v1.28 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 2
  completed_plans: 2
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider with high-security defaults while keeping account, login, tenant policy, and operator authentication in the host app.

**Current focus:** Milestone v1.28 complete

## Current Position

Phase: Milestone v1.28 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-03 — Milestone v1.28 completed and archived

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
| v1.28 | 103-106 | 2 | 17 | shipped |
| v1.27 | 97-102 | 24 | 28 | shipped |
| v1.26 | 94-96 | 3 | 5 | shipped |
| v1.25 | 91-93 | 9 | 9 | shipped |

## v1.28 Phase Plan

| Phase | Name | REQs | UI |
|-------|------|------|----|
| 103 | Admin UI Journey Contract + Design System Foundation | 7 | yes |
| 104 | Client Workspace Recomposition | 1 | yes |
| 105 | Support, Operate, Security, DCR, and Keys Workflow Polish | 5 | yes |
| 106 | Demo Seeds, Docs, Screenshots, and Contract Verification | 4 | yes |

## Decisions

- v1.28 is a deliberate UI/operator-experience milestone; opened because the admin surface now has enough breadth that operator clarity and design-system consistency are the highest-leverage adoption wedge.
- v1.28 treats the previous admin overview/nav/security/DCR/demo-seed polish already present in the worktree as the baseline, not work to redo.
- v1.28 doubles down on BEM/design-token CSS and shared Phoenix components; no Tailwind migration and no theming engine.
- v1.28 shipped with two explicit planning summaries: one combined execution summary for Phases 103-105 and one Phase 106 closeout summary.
- Branch A + JWT-default issuance is the resolution: narrow `Lockspire.Plug.VerifyToken` to RFC 9068 `at+jwt` only; flip default access-token issuance to `:jwt` for AC/refresh/device/CIBA; keep opaque as a per-client opt-in for `/userinfo` and `/introspect`.
- Phase 97 (contract + docs) must land before any runtime implementation; the canon is explicit that docs is a contract the implementation honors.
- Sustainment patch-train work continues in parallel on `main` while v1.27 feature work runs on `milestone/v1.27-phoenix-rs-token-acceptance`.
- [Phase ?]: TELEMETRY-01: [:lockspire, :rs, :token_format] emitted via direct :telemetry.execute/3 at two VerifyToken sites; :jwt at format-confirmation time (independent of apply_restrictions/2), literal :"opaque-rejected" with all-nil metadata on the opaque branch; deliberately not Observability.emit/4 (avoids audit double-emit + nil-metadata redaction drop).
- [Phase ?]: Phase 102-04: token_format doctor reproduces AccessTokenSigner.resolve_format/2 precedence inline (effective_format/2) rather than promoting the signer fn public; read-only/diagnostic-only (no Mix.raise/non-zero exit on flagged clients).
- [Phase ?]: Phase 102-03: docs/upgrading/v1.27.md documents the issuance default flip with the honest runtime opt-out (ServerPolicy.put_access_token_format(:opaque), NOT a config :lockspire key) and the nil-inherit affected-client set; pinned by a release_readiness_contract_test clause (MIGRATE-01).

## Blockers/Concerns

- None active. v1.28 has 17 requirements mapped 100% across 4 phases.

## Session Continuity

**Next action:** Start the next milestone with `$gsd-new-milestone`
**Resume file:** None
**Stopped at:** Milestone v1.28 archived
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

- Start the next milestone with `$gsd-new-milestone`.
