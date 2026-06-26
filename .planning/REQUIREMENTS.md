# Requirements: Lockspire v1.31 Admin Design-System Stress Test

**Defined:** 2026-06-25
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.31 Requirements

### Inventory And Lab

- [x] **LAB-01**: Maintainer can inspect every admin primitive and recurring component group in a lightweight Lockspire-owned stress surface without mounting a new supported admin route.
- [x] **LAB-02**: The stress surface covers normal, empty, error, disabled, destructive, long-value, dense-data, light, dark, system, and reduced-motion states.
- [x] **LAB-03**: Route inventory for stress proof derives from `Lockspire.Web.AdminRouter` plus the query-driven client logout-propagation workflow.

### Foundations And Components

- [x] **DS-01**: Admin CSS declares explicit light and dark color-scheme behavior while preserving semantic-alias dark-mode remapping from the brand book.
- [x] **DS-02**: Shared admin components expose backward-compatible primitives for architectural panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, and table/list alternatives.
- [x] **DS-03**: Every real admin status used by Configure, Support, and Operate surfaces maps to intentional badge semantics instead of falling through to disabled styling.
- [x] **DS-04**: Production admin forms use shared field, help, error, and workflow primitives or document a tested exception.
- [x] **DS-05**: Admin motion uses explicit properties, purposeful short feedback, and reduced-motion-safe behavior with no `transition: all`.

### Page And Flow Polish

- [x] **FLOW-01**: Client detail uses clearer pane/group structure for identity, posture, credentials, endpoints, DCR/RAT, support pivots, and destructive lifecycle actions.
- [x] **FLOW-02**: DCR policy uses a workflow structure that separates gate, allowlist, lifetime, auth-method, and risk decisions without changing policy semantics.
- [x] **FLOW-03**: IAT index/new, token detail, consent detail, and operation queues render clear page jobs, primary decisions, empty states, risk states, and next safe actions.
- [x] **FLOW-04**: Read-only operation queues describe current supported actions truthfully and do not add retry/discard UI unless backed by existing domain APIs.
- [x] **FLOW-05**: UX microcopy is concise, domain-accurate, calm under operator stress, and names destructive consequences without fear language.

### Fixtures And Evidence

- [x] **PROOF-01**: Demo seeds or reusable test fixtures cover healthy, warning, incident, disabled, self-registered, expired, revoked, reuse-detected, copy-once, empty, dense, and long-value states while preserving redaction.
- [x] **PROOF-02**: Browser proof covers 320px, 390px, 768px, 1024px, and 1440px widths across light, dark, system, and reduced-motion modes for the representative route matrix.
- [x] **PROOF-03**: Automated guardrails cover brand-token drift, raw color drift, responsive overflow, focus reachability, accessible labels/descriptions, duplicate IDs, contrast token pairs, plaintext secret leakage, and generic CTA drift.
- [x] **PROOF-04**: Operator docs explain the strengthened design-system workflow, component lab boundary, theme behavior, and verification expectations without creating new public support claims.

## Future Requirements

### Component Documentation

- **FUTURE-01**: Evaluate PhoenixStorybook after v1.31 if the lightweight lab becomes too bespoke or the component API surface grows beyond the current admin UI needs.
- **FUTURE-02**: Add visual snapshot comparisons only after the browser harness proves stable enough to avoid high-noise screenshot churn.

## Out of Scope

| Feature | Reason |
|---------|--------|
| OAuth/OIDC protocol breadth | This milestone is design-system and operator UI quality, not new protocol capability. |
| Storage schema changes | The page and fixture work should use existing domain surfaces unless a later phase proves a narrow test fixture need. |
| Hosted admin service | Lockspire remains an embedded Phoenix library mounted behind host-owned operator authentication. |
| Public theming engine | Tokens may be strengthened, but per-host or per-tenant theming is not part of this milestone. |
| Required PhoenixStorybook dependency | A lightweight lab is the default; PhoenixStorybook remains a future option. |
| React/JS Storybook admin shell | A separate frontend runtime would weaken the embedded LiveView library shape. |
| New logout retry/discard actions | Operation queues may clarify read-only state, but actions require existing domain APIs and are not assumed. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LAB-01 | Phase 116 | Complete |
| LAB-02 | Phase 117 | Complete |
| LAB-03 | Phase 116 | Complete |
| DS-01 | Phase 117 | Complete |
| DS-02 | Phase 118 | Complete |
| DS-03 | Phase 118 | Complete |
| DS-04 | Phase 118 | Complete |
| DS-05 | Phase 117 | Complete |
| FLOW-01 | Phase 119 | Complete |
| FLOW-02 | Phase 119 | Complete |
| FLOW-03 | Phase 119 | Complete |
| FLOW-04 | Phase 119 | Complete |
| FLOW-05 | Phase 119 | Complete |
| PROOF-01 | Phase 117 | Complete |
| PROOF-02 | Phase 120 | Complete |
| PROOF-03 | Phase 120 | Complete |
| PROOF-04 | Phase 120 | Complete |

**Coverage:**

- v1.31 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0

---
*Requirements defined: 2026-06-25*
*Last updated: 2026-06-25 after v1.31 milestone initialization*
