# Requirements: Lockspire v1.40 Admin Operator UI Refinement

**Defined:** 2026-10-09
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Status:** Approved for planning by the user’s `$gsd-plan-phase 144` instruction on 2026-10-09; see STATE.md.

## v1.40 Requirements

Refine existing supported capabilities. Requirement IDs below are new UI-specific categories, distinct from archived protocol and release requirements. Read [PRODUCT.md](../PRODUCT.md) and [UI-MILESTONE-PREFLIGHT.md](UI-MILESTONE-PREFLIGHT.md) for the confirmed audience, existing surface, source findings, and lessons already researched.

### Working baseline and representative workflows

- [x] **UIB-01**: Maintainer can open a working host-mounted demo backed by synthetic data and inspect a refreshed inventory of the existing 28 admin routes plus the logout-propagation query workflow, with current source/style identity and baseline observations recorded.
- [x] **UIB-02**: Operator can complete a representative client-configuration workflow and a token/consent-investigation workflow with a clear primary task, readable information hierarchy, and consistent form/action grouping demonstrated in the mounted UI.
- [x] **UIB-03**: Maintainer can apply the demonstrated page, typography, spacing, control, and domain-copy patterns using the existing shared components and tokens, with an evidence-based UI contract and concrete before/after examples.

### Configure and onboard

- [x] **UIC-01**: Operator can find, inspect, create, and edit a client through coherent list/detail/form navigation with visible primary actions, useful validation, and preserved client context.
- [x] **UIC-02**: Operator can configure supported redirect and logout settings with labels/help that distinguish browser return destinations from relying-party cleanup endpoints and identify invalid values at the relevant input.
- [x] **UIC-03**: Operator can understand and change supported issuer/client security policies with explicit inherited versus overridden settings, consistent field grouping, and truthful save or failure feedback.
- [x] **UIC-04**: Operator can issue or rotate supported client credentials with clear consequences and a usable one-time handoff that never exposes the credential again after that handoff ends.
- [x] **UIC-05**: Operator can follow DCR onboarding and initial-access-token workflows with clear lifecycle, scope, and expiry information, without conflating initial access tokens with registration access tokens or onboarding with policy configuration.
- [x] **UIC-06**: Operator can inspect signing-key lifecycle and perform already-supported key actions with a clear current state, action consequences, and accurate completion or failure feedback.

### Support investigation

- [x] **UIS-01**: Operator can filter token and consent inventories, inspect a matching record, and follow supported client/authorization pivots without losing the context needed to continue the investigation.
- [x] **UIS-02**: Operator can read relevant token, consent, and refresh-family lifecycle evidence, complete authorized diagnostic identifiers, and timestamps without confusing redacted credentials with safe identifiers.
- [x] **UIS-03**: Operator can distinguish and confirm the supported token, consent-grant, and refresh-family revocation actions, recover from failure, and see an accurate resulting state without widening the action's scope.

### Truthful overview and operations

- [x] **UIO-01**: Operator can distinguish a successful empty token/consent/device inventory from a failed or unavailable observation; failed loads retain useful context and an appropriate existing recovery path rather than silently becoming empty lists.
- [x] **UIO-02**: Operator can inspect interaction, device, and logout queues and client logout propagation with legible lifecycle/evidence states and useful existing pivots while these surfaces remain read-only.
- [x] **UIO-03**: Operator can use the overview to identify the next useful investigation or configuration task, with unavailable observations visibly distinct from measured zero or healthy state.

### Consistent behavior across the surface

- [x] **UIQ-01**: Operator can use the refreshed admin surface at narrow, intermediate, and desktop widths and at actual 200% browser zoom without clipped controls, lost diagnostic values, unreadably shrunken text, or unintended page overflow.
- [x] **UIQ-02**: Operator can complete changed forms and confirmation workflows by keyboard with associated labels/errors, visible and restored focus, and intact controls through busy, success, error, repeat-action, and LiveView patch cycles.
- [x] **UIQ-03**: Operator can read content and distinguish controls/status in light, dark, and system appearance with AA contrast targets, non-color-only cues, and one unambiguous selected theme preference distinct from its effective appearance.
- [x] **UIQ-04**: Operator sees concise, consistent domain language across navigation, headings, fields, actions, and feedback; explanations describe the job or consequence rather than CSS, code, or the development process.
- [x] **UIQ-05**: Operator receives prompt, purposeful interaction feedback that respects reduced motion and does not replay distracting animation or announcements on routine LiveView patches.

### Bounded finish and durable evidence

- [x] **UIV-01**: Maintainer can inspect fresh rendered evidence for every existing route/workflow, with deeper task/state/theme/viewport coverage selected by risk and linked to named findings rather than inferred from screenshot existence or source assertions.
- [x] **UIV-02**: Maintainer can run focused regression checks that exercise changed behavior and the actual delivered styling path, visibly report failures/skips, preserve expected screenshot baselines during ordinary verification, and run in the CI lane claimed for them where reliable.
- [x] **UIV-03**: Maintainer can compare representative before/after views using matching synthetic data and capture conditions, review one batched visual finding list, and see fixes plus one confirmation pass with explicit remaining limitations.
- [x] **UIV-04**: User can open a stable, documented final preview and follow the refined operator jobs, with current operator guidance and a concise evidence handoff suitable for optional feedback without repeating completed mechanical verification.

## Delivery and verification rules

- Begin Phase 144 with the real preview and current observations. Implement a useful representative slice in that phase; do not spend an entire milestone stage only producing scorecards or restating prior work.
- Refine the existing identity and shared components. Impeccable Operate guidance and the code-first preference apply. Use Emil Kowalski's skills selectively when interaction/motion work benefits; no animation quota or new animation dependency is required.
- Establish the common UI contract before broad propagation. Prefer headings, proximity, and quiet dividers; choose rows, lists, forms, tables, and containers according to the job. Do not force every surface into cards, columns, or tables.
- Responsive, keyboard, theme, copy, redaction, and motion rules apply to every changed journey when implemented. Their final cross-surface acceptance has one phase owner; do not postpone all accessibility fixes until the end.
- Reuse the route scorecards, fixtures, stress components, and relevant tests. Use real rendered inspection for clipping, hierarchy, focus, zoom, and runtime patches. An evidence parser only validates the record, not the page.
- The final visual review is bounded: one batched inspection, one repair batch, and one confirmation pass. Any additional work needs a named unresolved defect; no aesthetic score chasing or paid model-judge service.
- Keep the feedback preview stable. Run mutating fixture checks against a separate disposable instance/data set, and retain only synthetic, redaction-safe evidence. Do not reset an existing user preview to make tests pass.
- Keep automation small and reusable; add tests for meaningful regressions, not assertions that mirror every cosmetic edit. Report exact tested scope, skipped cases, and limits without inventing accessibility certification.

## Future Requirements

- Optional second design iteration based on the user's feedback after inspecting the completed baseline.
- Repository Readability & Docs Polish remains backlog Phase 999.1; it is not promoted by this milestone.
- Optional Impeccable live picker integration only after the actual Phoenix preview and injection target are verified, if it helps the work; it is not a prerequisite or a milestone deliverable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New protocol capabilities, changed security defaults, or broad backend refactors | This milestone refines existing supported operator behavior; narrow error-state fixes through existing service seams are in scope. |
| Host accounts, login/consent UX, staff auth/MFA/roles, tenancy, or global branding redesign | These belong to the embedding Phoenix application. |
| New approve/deny/retry/discard or worker controls on operation queues | Existing read-only boundaries are intentional and must remain intact. |
| Design-system replacement, new frontend stack, host-wide reset, or external font requirement | Existing LiveView components and scoped admin tokens are the implementation base. |
| Standalone authentication service, SAML, LDAP/AD, or full CIAM expansion | Violates Lockspire's embedded companion-library scope. |
| Exposing credentials in screenshots/traces, weakening copy-once behavior, or merging revocation meanings | Preserving existing security and domain semantics is mandatory. |
| Paid visual-judge infrastructure, unbounded critique loops, or a full browser-testing platform | Use bounded direct inspection and high-value deterministic checks without creating a new maintenance burden. |
| Package publication, release ceremony, or historical approval-gap repair | Separate from UI delivery; acknowledged v1.39 evidence remains unchanged and non-blocking. |

## Traceability

Approved roadmap mapping. Each of the 24 requirements belongs to exactly one phase beginning at Phase 144.

| Requirement | Phase | Status |
|-------------|-------|--------|
| UIB-01 | Phase 144 | Complete |
| UIB-02 | Phase 144 | Complete |
| UIB-03 | Phase 144 | Complete |
| UIC-01 | Phase 145 | Complete |
| UIC-02 | Phase 145 | Complete |
| UIC-03 | Phase 145 | Complete |
| UIC-04 | Phase 145 | Complete |
| UIC-05 | Phase 145 | Complete |
| UIC-06 | Phase 145 | Complete |
| UIS-01 | Phase 146 | Complete |
| UIS-02 | Phase 146 | Complete |
| UIS-03 | Phase 146 | Complete |
| UIO-01 | Phase 146 | Complete |
| UIO-02 | Phase 146 | Complete |
| UIO-03 | Phase 146 | Complete |
| UIQ-01 | Phase 147 | Complete |
| UIQ-02 | Phase 147 | Complete |
| UIQ-03 | Phase 147 | Complete |
| UIQ-04 | Phase 147 | Complete |
| UIQ-05 | Phase 147 | Complete |
| UIV-01 | Phase 147 | Complete |
| UIV-02 | Phase 147 | Complete |
| UIV-03 | Phase 147 | Complete |
| UIV-04 | Phase 147 | Complete |

**Coverage:**
- v1.40 requirements: 24 total
- Mapped to phases: 24 (approved roadmap)
- Unmapped: 0

---
*Requirements defined: 2026-10-09*
*Last updated: 2026-10-09 from the confirmed UI direction and completed preflight*
