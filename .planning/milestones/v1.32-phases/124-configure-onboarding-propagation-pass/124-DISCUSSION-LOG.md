# Phase 124: Configure Onboarding Propagation Pass - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-29T21:24:00Z
**Phase:** 124-configure-onboarding-propagation-pass
**Mode:** assumptions
**Areas analyzed:** Surface Boundary, Page Hierarchy, Copy-Once Handoff, Action Semantics

## Assumptions Presented

### Surface Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 124 should only polish existing Configure routes and existing Admin-backed behaviors; it should not add public APIs, new admin shell routes, Storybook/lab routes, or host-owned auth/layout seams. | Confident | `.planning/ROADMAP.md:78-94`; `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md`; `lib/lockspire/web/admin_router.ex`; `lib/lockspire/admin.ex` |

### Page Hierarchy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Configure pages should converge on the existing page-first pattern: `page_hero` for route intent, summary/posture content before dense lists or forms, then grouped actions and follow-up routes using existing primitives. | Likely | `lib/lockspire/web/components/admin_components.ex`; `lib/lockspire/web/live/admin/clients_live/show.ex`; `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`; `lib/lockspire/web/live/admin/dcr_live/index.ex`; `lib/lockspire/web/live/admin/iat_live/index.html.heex`; `lib/lockspire/web/live/admin/keys_live/index.ex` |

### Copy-Once Handoff

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| DCR/IAT/RAT handoff should remain a copy-once Configure workflow: plaintext appears only at creation or rotation, then the UI returns to redacted posture/inventory and partner handoff guidance. | Confident | `lib/lockspire/admin/initial_access_tokens.ex`; `lib/lockspire/web/live/admin/iat_live/new.html.heex`; `lib/lockspire/web/live/admin/clients_live/show.ex`; `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex`; `test/lockspire/web/live/admin/iat_live_test.exs` |

### Action Semantics

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Configure destructive and risky actions should use the shared `confirmation_panel` plus clear consequence copy, and safe/secondary/destructive controls should be grouped with `action_group`; browser `data-confirm` should not remain the main model for Configure destructive actions. | Likely | `lib/lockspire/web/components/admin_components.ex`; `lib/lockspire/web/live/admin/clients_live/show.ex`; `lib/lockspire/web/live/admin/keys_live/action_component.ex`; `lib/lockspire/web/live/admin/iat_live/index.html.heex`; `test/lockspire/web/live/admin/design_system_contract_test.exs` |

## Corrections Made

No corrections — auto mode accepted all Confident/Likely assumptions.

## Auto-Resolved

- Page Hierarchy: auto-selected the hybrid existing-primitive approach rather than forcing every Configure page into one component shape or leaving uneven pages unchanged.
- Action Semantics: auto-selected inline confirmation panels and action groups as the recommended Configure destructive-action model rather than retaining browser `data-confirm` as the primary pattern.

## External Research

No external research was needed; the codebase and prior v1.32 context provided enough evidence.
