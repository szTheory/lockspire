# Requirements: Lockspire v1.42 Admin UI Clarity & Workflow Refinement

**Defined:** 2026-10-12
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Status:** Approved for execution from the user's explicit request for a systematic admin UI cleanup pass.

## v1.42 Requirements

### Clear, focused admin tasks

- [x] **UI-01**: Each of the 29 existing admin route scorecards and the Phase 151 `/admin/clients/new` route has a clearly identifiable user job, a useful page title, and an information order that puts the decision or next task before secondary context. Review all 30 current paths; remove duplicate page/section titles and generic introductions when they repeat information.
- [x] **UI-02**: User-facing labels and help use plain, consistent language grounded in staff users' goals. Remove backend/provenance commentary that does not help a decision; explain necessary protocol terms in context, and describe unfamiliar state in terms of its supported consequence and next action. Do not use “operator” as visible audience copy or generic UI filler.
- [x] **UI-03**: Overview metrics and queue labels accurately match the records and filters they describe. Explain token reuse and logout-delivery outcomes without implying compromise or claiming unsupported controls. A failed read remains distinct from an empty or healthy result.
- [x] **UI-04**: Client registration is a dedicated route with one title, one concise explanation, focused form context, and a clear return path to the client inventory. Other client task routes show the relevant client identity and task without making the user scan the full unrelated workspace first.
- [x] **UI-05**: Primary, secondary, and destructive action emphasis follows a consistent, documented rule across the admin surface. The main task action is easiest to identify; supporting navigation and recovery actions remain quieter; destructive actions retain explicit consequence and confirmation.
- [x] **UI-06**: Pages use the existing components and design tokens to improve hierarchy, spacing, scanability, and control affordances. Remove metric rows, nested containers, and helper text that do not help the current task. Correct the theme selector's demonstrated right-edge caret spacing.
- [ ] **UI-07**: Changed views remain usable at narrow widths and 200% zoom, with light/dark/system theme parity, readable text contrast, visible keyboard focus, labeled controls, reduced-motion support, and no clipped content or actions.

### Automated evidence and safety boundaries

- [ ] **PROOF-01**: All 29 admin route scorecards and the Phase 151 `/admin/clients/new` route receive redaction-safe baseline and final rendered captures (30 current paths). Capture each full page; when a full-page image is too tall or unreadable, capture each meaningful section. Focused tests and browser checks verify affected tasks, state labels, action hierarchy, responsive layout, and theme control. Add checks to CI only when they provide reliable recurring regression value.
- [ ] **SAFE-01**: The cleanup preserves OAuth/OIDC behavior, security defaults, credential redaction and copy-once behavior, confirmation semantics, and distinct revocation scopes. Interaction, device-authorization, and logout queues remain read-only. The host app retains account, login, layout, branding, and product-policy ownership. Do not add dependencies or expose private key material in browser evidence.

## Delivery Rules

- Inspect the current mounted demo and all route scorecards before broad edits. Keep screenshots synthetic, redaction-safe, and tied to the same served source being reviewed.
- Use Impeccable in Operate mode and Emil Kowalski's design-engineering guidance for clarity and interaction details. Refine the current Signal Cyan identity and existing component/token system; do not replace the design system or add motion without a real interaction need.
- Use contextual help only when it answers a decision question. Do not move low-value provenance into a tooltip; remove it. Tooltips must remain available to keyboard and assistive-technology users when they carry necessary information.
- Apply consistent action semantics: primary for the principal safe task on a page, secondary for navigation/supporting/recovery actions, and danger for consequential destructive actions. Do not show competing primary actions without a user-task reason.
- Treat UI-state contradictions as correctness issues. Verify status labels and counts against query/filter semantics before changing copy.
- Shift verification left. Prefer existing ExUnit/LiveView, HTML contracts, and the current demo proof lane; add a browser check only when it proves a recurring rendered behavior those tests cannot establish.
- Preserve CR-01 (plaintext private signing-key material at rest) as a separate, critical, unresolved security issue requiring its own design. This UI milestone does not accept or resolve it.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Private signing-key encryption at rest (CR-01) | Requires a separate security design and operational decision; visual work cannot resolve it. |
| New OAuth/OIDC capabilities, changed security defaults, or new queue controls | This milestone refines existing presentation and focused task flow only. |
| Host-owned account, login, consent, outer layout, branding, or product policy | These remain the embedding application's responsibility. |
| Wholesale visual identity or design-system replacement | The existing Signal Cyan identity, shared components, and tokens are the starting point. |
| New UI dependencies, paid visual-judge APIs, or open-ended critique loops | Prefer the current stack and bounded local/browser evidence. |
| Repeating v1.41 documentation/repository cleanup | That scope is complete and archived. |

## Traceability

Every requirement maps to exactly one v1.42 phase; the roadmap will assign phase numbers and status.

| Requirement | Phase | Status |
|-------------|-------|--------|
| UI-01 | Phase 153 | Complete |
| UI-02 | Phase 153 | Complete |
| UI-03 | Phase 152 | Complete |
| UI-04 | Phase 151 | Complete |
| UI-05 | Phase 151 | Complete |
| UI-06 | Phase 153 | Complete |
| UI-07 | Phase 154 | Pending |
| PROOF-01 | Phase 154 | Pending |
| SAFE-01 | Phase 154 | Pending |

**Coverage:** 9 total; 9 mapped exactly once; 0 unmapped.
