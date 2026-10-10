# Roadmap: Lockspire

## Milestones

- 🚧 **v1.41 Product Language & Repository Clarity** — Phases 148–150 (planning).
- ✅ **[v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md)** — Completed 2026-10-10; Phases 144–147, 21 plans, 24 requirements. Override closeout: three verification reports stale, Phase 146 `human_needed`; see the [audit](milestones/v1.40-MILESTONE-AUDIT.md).
- ✅ **[v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md)** — Phases 142–143; Lockspire 1.5.1 shipped 2026-10-08 with an acknowledged PR #119 merge-authorization gap.
- ✅ **[v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md)** — Phases 138–141; completed 2026-10-06 as planning closeout, without package publication.
- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131–137; shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Overview

Make Lockspire's admin UI language useful to the people doing the work, then make the repository easier to understand and the adopter/maintainer docs easier to follow. Begin with user goals, familiarity, mental models, and decisions; translate internal terms into plain language while preserving precise OAuth/OIDC meaning and truthful consequences. Map repository areas and verify ownership/references before any cleanup. Finish by organizing the README and guides around adopter and maintainer tasks, grounded in the reviewed vocabulary and current implementation.

## Phases

- [ ] **Phase 148: User-Facing Admin Language** — Rewrite existing admin UI copy around user goals and mental models without losing protocol precision or truthful outcomes.
- [ ] **Phase 149: Repository Ownership and Lifecycle** — Make the purpose and lifecycle of major repository areas clear; move or remove content only after ownership and reference checks prove it safe.
- [ ] **Phase 150: Adopter and Maintainer Documentation** — Give Phoenix teams a clear, accurate path through fit, installation, verification, and ongoing use.

## v1.41 Product Language & Repository Clarity

### Phase 148: User-Facing Admin Language

**Goal**: People managing clients, keys, tokens, and consent can understand each page and action in language grounded in their goals, familiarity, and mental models.
**Depends on**: Nothing; first phase of v1.41.
**Requirements**: LANG-01, LANG-02, LANG-03
**Success Criteria** (what must be TRUE):
  1. A person can tell what each existing admin page helps them do from its title, headings, and primary labels without being addressed through an internal persona label.
  2. Labels, help, confirmations, empty/unavailable states, and action feedback reflect the reader's task and explain unfamiliar terms only where needed.
  3. Client/secret, consent, token/family, Initial/Registration Access Token, and logout-destination wording preserves the security and behavior distinctions users need to make safe decisions.
  4. Success and failure copy reports only confirmed outcomes and offers a useful next action where one exists; changed wording preserves redaction and behavior.
  5. Existing automated checks cover recurring high-risk language/outcome rules, while relevant changed-page and rendered checks pass without new UI behavior or dependencies.

**Plans**: 7 plans

Plans:
**Wave 1**
- [ ] 148-01-PLAN.md — Shared language tracer, overview, and route-inventory test repair

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 148-02-PLAN.md — Client detail, edit, credential, and logout-workflow copy
- [ ] 148-03-PLAN.md — DCR onboarding and Initial Access Token copy
- [ ] 148-04-PLAN.md — Issuer policy index, DCR, and PAR copy
- [ ] 148-05-PLAN.md — Issuer DPoP and security-profile copy
- [ ] 148-06-PLAN.md — Consent and token investigation/revocation copy
- [ ] 148-07-PLAN.md — Key lifecycle and read-only operations copy

**UI hint**: yes

Planning note: Use Impeccable `clarify` to review complete page and task paths, not isolated strings. Name the user persona/task internally to guide the work, but do not expose “operator” as visible audience copy or generic UI filler. This is a language pass, not a visual redesign; animation work is not needed.

### Phase 149: Repository Ownership and Lifecycle

**Goal**: Contributors can tell what the major repository areas contain and whether their contents are maintained, generated, test-only, or historical.
**Depends on**: Phase 148.
**Requirements**: REPO-01, REPO-02
**Success Criteria** (what must be TRUE):
  1. Contributors can find a concise map of major repository areas and understand the purpose and lifecycle of maintained docs, generated output, fixtures, brand assets, and planning records.
  2. Every proposed move or removal has an ownership and lifecycle finding plus checks of active worktrees and CI, test, package, generator, and documentation references before mutation.
  3. Any evidence-backed cleanup is narrow and passes the affected checks; ambiguous or still-used content remains in place with its status made clear.

**Plans**: TBD

Planning note: Inventory first. Age, names, or apparent generated status do not prove an item is stale. Do not reorganize paths for appearance alone.

### Phase 150: Adopter and Maintainer Documentation

**Goal**: Phoenix adopters and maintainers can quickly decide whether Lockspire fits, install and verify it in an existing application, and find the next guide for their task.
**Depends on**: Phases 148 and 149.
**Requirements**: DOC-01, DOC-02, DOC-03
**Success Criteria** (what must be TRUE):
  1. The README gives a concise product-fit/boundaries summary and routes readers to installation, verification, the supported-surface contract, and relevant maintainer guides.
  2. Maintained guides are findable by adopter or maintainer task in README and generated HexDocs navigation, using the user-facing vocabulary established in Phase 148.
  3. `docs/supported-surface.md` remains the single canonical capability/non-claim contract, and all changed setup steps, commands, links, and claims match source.
  4. Existing docs and build checks provide deterministic evidence for changed links, navigation, setup instructions, and published guide structure; no manual handoff duplicates proof they establish.

**Plans**: TBD

Planning note: Keep the README an orientation and routing page; let focused guides explain the steps. Reuse existing ExDoc and docs-check infrastructure.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 148. User-Facing Admin Language | v1.41 | 0/7 | Not started | — |
| 149. Repository Ownership and Lifecycle | v1.41 | 0/TBD | Not started | — |
| 150. Adopter and Maintainer Documentation | v1.41 | 0/TBD | Not started | — |

## Backlog

### Phase 999.1: Repository Readability & Docs Polish (PROMOTED TO v1.41)

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Promoted into v1.41 Product Language & Repository Clarity; the active phase breakdown above replaces this backlog entry.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
