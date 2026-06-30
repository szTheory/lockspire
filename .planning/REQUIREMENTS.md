# Requirements: Lockspire v1.32 Admin Page IA & Interaction Model Polish

**Defined:** 2026-06-28
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.32 Requirements

### Page IA And Judgment

- [x] **IA-01**: Maintainer can review a scorecard for every admin route that names persona, JTBD, top task, entry point, primary decision, primary action, empty state, error state, long-data state, mobile/theme/focus risk, and follow-up route.
- [x] **IA-02**: Maintainer can run deterministic guardrails that flag page sections whose hierarchy, redundant actions, generic copy, unsupported affordances, or unearned UI elements violate the v1.32 judgment rubric.
- [x] **IA-03**: Maintainer can verify v1.32 preserves the v1.31 design-system boundary: Phoenix function components by default, BEM/token CSS, internal lab only, no public design-system route, no required PhoenixStorybook dependency, and no public theming API.

### Support Investigation

- [x] **SUPPORT-01**: Support operator can use token index and detail pages to understand selected filters, token health, family context, smallest safe action, and incident pressure without token plaintext or redundant metadata dumps.
- [x] **SUPPORT-02**: Support operator can use consent index and detail pages to understand selected filters, grant status, scope context, client/account pivots, and revocation consequences without exposing secret material.
- [x] **SUPPORT-03**: Support investigation pages handle empty, no-match, revoked, expired, reuse-detected, long identifier, dense result, validation/error, and already-revoked states with concise, consequence-oriented copy.

### Operate Queues

- [x] **OPERATE-01**: Operator can scan interactions, device authorizations, and logout delivery queues by status pressure, channel/prompt, client, subject, age, expiry or last activity, and durable non-secret identifiers without table-like overload.
- [x] **OPERATE-02**: Operate queue pages truthfully remain read-only unless a backed domain API exists; no retry, discard, approve, deny, or worker-control UI is introduced by polish alone.
- [x] **OPERATE-03**: Operate queue pages remain usable at mobile widths, in light/dark/system themes, with reduced motion, keyboard focus, empty states, dense states, long URLs, and incident states.

### Configure Propagation

- [x] **CONFIG-01**: Configure operator can move through clients, DCR onboarding, IATs, keys, and policy pages with page hierarchy, summaries, actions, and follow-up routes aligned to one deliberate interaction model.
- [x] **CONFIG-02**: Partner-onboarding operator can complete DCR/IAT copy-once and handoff workflows with clear current posture, short-lived credential guidance, and no plaintext leakage after creation.
- [x] **CONFIG-03**: Security/platform owner can distinguish safe, secondary, and destructive Configure actions through consistent confirmation forms, consequence copy, status semantics, and action grouping.

### Fixtures And Proof

- [x] **PROOF-01**: Maintainer can render redaction-safe fixtures for v1.32 scorecards covering empty, one item, many items, long names, long IDs, long URLs, high counts, zero counts, missing optional fields, warning, incident, disabled, expired, revoked, reuse-detected, copy-once, stale/read-only, light, dark, system, reduced motion, and mobile states.
- [x] **PROOF-02**: Automated guardrails cover route scorecard drift, unsupported action drift, generic CTA drift, redaction drift, long-value handling, focus/label references, duplicate IDs, light/dark/system token usage, and responsive no-page-overflow claims for the changed pages.
- [x] **PROOF-03**: Maintainer can review browser/manual evidence and operator docs for the representative v1.32 route matrix without turning screenshots, browser tooling, AI judges, or lab artifacts into public support surface.

## Future Requirements

### Optional Tooling

- **FUTURE-01**: Re-evaluate PhoenixStorybook only if the internal component lab becomes too hard to maintain after v1.32.
- **FUTURE-02**: Add visual snapshot tooling only after manual/browser evidence proves low-noise selectors, fixtures, and route stability.
- **FUTURE-03**: Add optional LLM persona review prompts only as maintainer evidence, not as required CI or release gates.

## Out of Scope

| Feature | Reason |
|---------|--------|
| OAuth/OIDC protocol behavior | v1.32 is admin/operator UI quality, not protocol breadth. |
| Storage schema changes | Page IA and fixture work should use existing domain surfaces unless a later phase proves a narrow test-only need. |
| Public design-system route or Storybook | The component lab remains maintainer/test-only and not supported admin surface. |
| Public theming or host component registry | Host apps own product branding outside Lockspire's bounded admin surface; v1.32 should not create a theming product. |
| Runtime LLM judge gate | Judgment artifacts must be deterministic and repo-native; optional AI review can stay maintainer evidence. |
| New queue worker actions | Retry/discard/approve/deny controls require backed domain APIs and are not introduced by UI polish. |
| Full admin rebuild | v1.32 tightens page clusters and proven patterns; it does not replace the LiveView architecture or v1.31 design-system foundations. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| IA-01 | Phase 121 | Complete |
| IA-02 | Phase 121 | Complete |
| IA-03 | Phase 121 | Complete |
| SUPPORT-01 | Phase 122 | Complete |
| SUPPORT-02 | Phase 122 | Complete |
| SUPPORT-03 | Phase 122 | Complete |
| OPERATE-01 | Phase 123 | Complete |
| OPERATE-02 | Phase 123 | Complete |
| OPERATE-03 | Phase 123 | Complete |
| CONFIG-01 | Phase 124 | Complete |
| CONFIG-02 | Phase 124 | Complete |
| CONFIG-03 | Phase 124 | Complete |
| PROOF-01 | Phase 125 | Complete |
| PROOF-02 | Phase 125 | Complete |
| PROOF-03 | Phase 125 | Complete |

**Coverage:**

- v1.32 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-06-28*
*Last updated: 2026-06-28 after v1.32 milestone initialization*
