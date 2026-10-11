# Requirements: Lockspire v1.41 Product Language & Repository Clarity

**Defined:** 2026-10-10
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Status:** Approved for planning by the user's confirmation on 2026-10-10.

## v1.41 Requirements

### Plain, accurate admin UI language

- [x] **LANG-01**: Existing admin pages use concise, task- and object-centered labels, headings, and help text shaped by the user's goals, familiarity, mental model, questions, and decisions. Translate internal concepts into helpful user-facing language; avoid implementation jargon, repetitive boilerplate, and persona labels. “Operator” is internal planning language and must not be used as visible UI audience copy or generic UI filler.
- [x] **LANG-02**: User-facing language preserves OAuth/OIDC meanings and security distinctions, including client IDs versus secrets, consent grants versus host consent UX, access tokens versus refresh tokens and token families, Initial Access Tokens versus Registration Access Tokens, and logout redirects versus propagation endpoints. When a precise protocol term is necessary but unfamiliar to the intended reader, explain it in the task context instead of exposing unexplained internal wording.
- [x] **LANG-03**: Validation, empty, unavailable, loading, confirmation, success, and failure messages state what happened and its real consequence, with a useful next action where one exists. Copy does not invent causes or claim unproven outcomes.

### Adopter and maintainer documentation

- [ ] **DOC-01**: The README routes adopters and maintainers through product fit and boundaries, Phoenix installation, verification, and the relevant next guide.
- [ ] **DOC-02**: README and generated HexDocs navigation make maintained guides findable by task; `docs/supported-surface.md` remains the canonical capability and non-claim contract.
- [ ] **DOC-03**: Maintained setup steps, commands, links, and capability claims match the current code and are checkable through existing documentation verification.

### Repository clarity and verified cleanup

- [ ] **REPO-01**: Contributors can identify the purpose and lifecycle of major repository areas, including maintained documentation, generated output, fixtures, brand assets, and planning records.
- [ ] **REPO-02**: Any moved or removed repository content has verified ownership and lifecycle, with active worktree, CI, test, package, generator, and documentation references checked before the change and relevant verification passing afterward.

## Delivery and verification rules

- Complete the empathetic, persona- and task-aware admin UI language review first; use its approved terms when revising the README and guides.
- Preserve protocol meaning, security boundaries, truthful action outcomes, host-owned UX boundaries, and Lockspire's embedded-library shape. Do not add protocol features or expand UI behavior.
- Follow Impeccable's `clarify` guidance for copy review. This milestone does not require a visual redesign or a new design system.
- Keep `docs/supported-surface.md` canonical for supported capabilities and explicit non-claims. Verify all changed setup steps, commands, links, and claims against source and existing checks.
- Do not move or remove content until ownership, active worktree use, and CI/test/package/generator/documentation references have been checked. Prefer a clear ownership map over churn.
- Apply the project verification default: add or update deterministic checks where they have recurring value, run checks as early as practical, and avoid handing off mechanically verifiable work for manual UAT.

## Future Requirements

- A later UI refinement based on feedback after this milestone is complete.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New OAuth/OIDC protocol capabilities or changed security defaults | This milestone clarifies existing behavior and documentation only. |
| Host-owned account, login, consent, layout, branding, or product-policy UX | These remain the embedding application's responsibility. |
| Broad visual redesign or design-system replacement | The requested work is language and repository clarity, not visual refinement. |
| Unverified cleanup, bulk path changes, or speculative repository reorganization | Changes require ownership and reference evidence plus passing relevant checks. |
| New dependencies for copy or documentation maintenance | Existing language and documentation tools are sufficient unless research proves otherwise. |

## Traceability

Each requirement maps to exactly one v1.41 phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LANG-01 | Phase 148 | Complete |
| LANG-02 | Phase 148 | Complete |
| LANG-03 | Phase 148 | Complete |
| REPO-01 | Phase 149 | Not started |
| REPO-02 | Phase 149 | Not started |
| DOC-01 | Phase 150 | Not started |
| DOC-02 | Phase 150 | Not started |
| DOC-03 | Phase 150 | Not started |

**Coverage:** 8 total; 8 mapped; 0 unmapped.

---
*Requirements defined: 2026-10-10*
