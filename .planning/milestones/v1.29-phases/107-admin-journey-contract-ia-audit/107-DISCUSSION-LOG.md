# Phase 107: admin-journey-contract-ia-audit - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-03T23:03:08Z
**Phase:** 107-admin-journey-contract-ia-audit
**Mode:** assumptions
**Areas analyzed:** Contract Artifact Shape, Journey Vocabulary, Audit Evidence, Weak-Spot Priority, Disambiguation Rules, Verification Shape

## Assumptions Presented

### Contract Artifact Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The phase should create a repo-local route journey contract/audit artifact before changing admin LiveView code. | Confident | `.planning/ROADMAP.md`, `.planning/phases/107-admin-journey-contract-ia-audit/107-UI-SPEC.md`, `lib/lockspire/web/admin_router.ex` |

### Journey Vocabulary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use the four journey names exactly: Orient, Configure, Support, Operate, and assign every admin route to exactly one primary journey while allowing secondary pivots. | Confident | `.planning/REQUIREMENTS.md`, `.planning/phases/107-admin-journey-contract-ia-audit/107-UI-SPEC.md`, `lib/lockspire/web/live/admin_layout_live.ex` |

### Audit Evidence

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat the v1.28 screenshot inventory in `tmp/admin-ui-polish/` plus code/doc references as valid audit evidence; classify each route as strong, adequate, or weak for desktop/mobile and operator clarity. | Likely | `.planning/ROADMAP.md`, `tmp/admin-ui-polish/`, `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-CONTEXT.md` |

### Weak-Spot Priority

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The audit should flag support/operations/raw-list surfaces first: logout deliveries, device authorizations, interactions, tokens/consents, then DCR/IAT and client-detail action grouping. | Likely | `.planning/REQUIREMENTS.md`, `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`, `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`, `lib/lockspire/web/live/admin/overview_live/index.ex`, `lib/lockspire/web/live/admin/dcr_live/index.ex` |

### Disambiguation Rules

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Lock the two known naming splits into the contract: DCR onboarding vs DCR policy, and post-logout redirect URIs vs logout propagation URIs. | Confident | `.planning/REQUIREMENTS.md`, `.planning/phases/107-admin-journey-contract-ia-audit/107-UI-SPEC.md`, `docs/operator-admin.md`, `lib/lockspire/web/live/admin/clients_live/form_component.ex` |

### Verification Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Extend existing deterministic contract proof rather than introduce a new UI framework or runtime dependency. | Likely | `test/lockspire/web/live/admin/design_system_contract_test.exs`, `.planning/phases/107-admin-journey-contract-ia-audit/107-UI-SPEC.md` |

## Corrections Made

No corrections — all assumptions confirmed.
