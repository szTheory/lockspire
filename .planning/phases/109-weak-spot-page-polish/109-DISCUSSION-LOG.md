# Phase 109: weak-spot-page-polish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 109-weak-spot-page-polish
**Mode:** assumptions
**Areas analyzed:** Support Investigation Surfaces, Operations Queue Surfaces, Configure Weak Spots, Security And Redaction, Verification Boundary

## Assumptions Presented

### Support Investigation Surfaces

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Tokens and consents should become support investigation pages, not generic list pages. Keep existing URL-driven account/client/status filters, but add page hero/job copy, metric or summary context, `resource_item` rows, long-value handling, clearer pivots, and verb-plus-noun actions like `Filter tokens`, `Review token`, and `Review stored grant`. | Likely | `.planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md`; `lib/lockspire/web/live/admin/tokens_live/index.ex`; `lib/lockspire/web/live/admin/consents_live/index.ex`; `lib/lockspire/web/components/admin_components.ex` |

### Operations Queue Surfaces

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Logout deliveries, device authorizations, and interactions should move away from raw-table/plain-list first content into queue-style operation views. Use status bucket summaries plus responsive rows showing client, status, age/timestamps, identifiers, and safe review/retry/discard context where supported by current domain APIs. | Confident | `.planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md`; `.planning/REQUIREMENTS.md` OPS-02/OPS-03; `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`; `lib/lockspire/web/live/admin/interactions_live/index.ex`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` |

### Configure Weak Spots

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| DCR/IAT, keys, and client detail need targeted grouping/readability polish, not a redesign. Preserve their stronger v1.28/v1.29 baseline patterns, then tighten DCR onboarding vocabulary, IAT copy-once handling, key long-value/readability, and client detail `action_group` sections for routine configuration, credentials/RAT, endpoints, and destructive lifecycle actions. | Likely | `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md`; `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md`; `lib/lockspire/web/live/admin/dcr_live/index.ex`; `lib/lockspire/web/live/admin/iat_live/index.html.heex`; `lib/lockspire/web/live/admin/iat_live/new.html.heex`; `lib/lockspire/web/live/admin/keys_live/index.ex`; `lib/lockspire/web/live/admin/keys_live/show.ex`; `lib/lockspire/web/live/admin/clients_live/show.ex` |

### Security And Redaction

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| No new protocol behavior or secret exposure belongs in Phase 109. All polish must keep token plaintext, client secrets, IAT/RAT plaintext after creation, user codes, and verifier material out of list/detail rows, confirmations, logs, docs, and screenshots; confirmations should identify resources by durable non-secret context. | Confident | Project security defaults; `.planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md`; `lib/lockspire/web/live/admin/tokens_live/show.ex`; `lib/lockspire/web/components/admin_components.ex` copy-once/redaction primitives |

### Verification Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 109 should add deterministic LiveView/component contract tests plus focused mobile/no-overflow proof for touched routes, while leaving full screenshot inventory and docs regression proof to Phase 110. It should extend `design_system_contract_test.exs` and focused admin LiveView tests around route copy, shared primitives, action labels, redaction, confirmation copy, and 390px overflow where feasible. | Likely | `.planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md`; `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md`; `.planning/ROADMAP.md`; `test/lockspire/web/live/admin/design_system_contract_test.exs` |

## Corrections Made

No corrections - all assumptions confirmed.
