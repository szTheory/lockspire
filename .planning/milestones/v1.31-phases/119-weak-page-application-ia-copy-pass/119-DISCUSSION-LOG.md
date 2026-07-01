# Phase 119: Weak-Page Application & IA/Copy Pass - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-26T02:06:08Z
**Phase:** 119-weak-page-application-ia-copy-pass
**Mode:** assumptions
**Areas analyzed:** Component Adoption Boundary, Client Detail IA, DCR Policy Workflow, Support And Operate Surfaces

## Assumptions Presented

### Component Adoption Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 119 should consume existing `AdminComponents` primitives and keep LiveViews responsible for page intent, URL state, forms, and mutations. | Confident | `.planning/phases/118-primitive-meta-component-upgrade/118-CONTEXT.md`; `lib/lockspire/web/components/admin_components.ex`; `.planning/ROADMAP.md` |

### Client Detail IA

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Client detail should be re-grouped around the existing identity, posture, credentials, endpoints/logout, DCR/RAT, support-pivot, and lifecycle concepts, using the new structural primitives while preserving existing action destinations and events. | Confident | `.planning/ROADMAP.md`; `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md`; `lib/lockspire/web/live/admin/clients_live/show.ex`; `test/lockspire/web/live/admin/clients_live_test.exs` |

### DCR Policy Workflow

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| DCR policy should remain one submitted policy form, but visually separate gate, allowlist, lifetime, auth-method, and risk/posture decisions with shared workflow/field chrome. | Confident | `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`; `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex`; `lib/lockspire/web/live/admin/policies_live/dcr.ex`; `test/lockspire/web/live/admin/policies_live/dcr_test.exs` |

### Support And Operate Surfaces

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Token detail, consent detail, and IAT pages need targeted primitive/copy alignment, while Operate queues should stay read-only and migrate away from table-like wrappers only where rows are not true tables. | Confident | `lib/lockspire/web/live/admin/tokens_live/show.ex`; `lib/lockspire/web/live/admin/consents_live/show.ex`; `lib/lockspire/web/live/admin/iat_live/new.html.heex`; `lib/lockspire/web/live/admin/interactions_live/index.ex`; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`; `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` |

## Corrections Made

No corrections - all assumptions were treated as confirmed. The interactive AskUserQuestion tool was unavailable in this runtime mode, and all assumptions were Confident with no external research gaps.
