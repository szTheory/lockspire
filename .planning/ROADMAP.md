# Roadmap: Lockspire

## Milestones

- 🚧 **v1.47 OAuth/OIDC Core Interoperability & Hardening** — Phases 171–174; planning, with product execution gated on reviewed prior delivery and fresh accepted main.
- ✅ [v1.46 Embedded Host Integration Reliability](milestones/v1.46-ROADMAP.md) — completed 2026-10-24; Phases 167–170, 16 plans, 15/15 requirements; package publication separate.
- ✅ [v1.45 DCR Lifetime Enforcement](milestones/v1.45-ROADMAP.md) — completed 2026-10-22; Phases 162–166, 40 plans, 18/18 requirements; package publication separate.
- ✅ [v1.44 Adopter Polish & Verified 1.6.0](milestones/v1.44-ROADMAP.md) — completed 2026-10-20; Phases 158–161; shipped in Lockspire 1.6.0.
- ✅ [v1.43 Signing Key Encryption at Rest](milestones/v1.43-ROADMAP.md) — completed 2026-10-16; Phases 155–157; closes CR-01; no OAuth/OIDC behavior change.
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## v1.47 OAuth/OIDC Core Interoperability & Hardening

Clients using the supported embedded Phoenix surface receive secure, standards-grounded authorization and PAR/profile behavior, with reproducible evidence for each selected outcome. First reconcile accumulated prior delivery and qualify a finite set of current findings; then deliver only the supported authorization and conditional PAR/profile cases that survive qualification, followed by packaged proof and a verifiable delivery handoff. The four phases map all 14 v1.47 requirements once. No current protocol defect, accepted implementation baseline or public release is asserted by this roadmap.

**Scope authority:** [requirements](REQUIREMENTS.md), [scope and decisions](research/v1.47-core-hardening/SCOPE.md), [research synthesis](research/v1.47-core-hardening/SUMMARY.md), [dated baseline](research/v1.47-core-hardening/BASELINE.md), [standing guide](MILESTONE-GUIDE.txt) and [rolling milestone ranking](MILESTONE-ARC.md).

## Phases

- [ ] **Phase 171: Accepted Baseline & Finding Qualification** - Establish delivery readiness and freeze the finite, attributable case ledger before dependent plans.
- [ ] **Phase 172: Authorization Responses** - Deliver the qualified safe-callback, error/state, response-mode and silent-auth outcomes.
- [ ] **Phase 173: Conditional PAR & Profile Boundaries** - Deliver only qualified pushed-request and profile cases after transport and harness attribution.
- [ ] **Phase 174: Packaged Proof & Delivery Handoff** - Prove all selected behavior, pass required gates and leave an exact, resumable delivery record.

## Phase Details

### Phase 171: Accepted Baseline & Finding Qualification

**Goal**: Maintainers can identify an accepted implementation base and a finite set of current, supported cases whose expected outcomes and owners are settled before dependent planning.
**Depends on**: Nothing (first phase of v1.47).
**Requirements**: BASE-01, BASE-02, FIND-01, FIND-02
**Success Criteria** (what must be TRUE):
  1. Before product implementation, the maintainer can inspect reviewed disposition of accumulated prior delivery and unknown work, plus a fresh receipt from the existing exact-main acceptance gate identifying synchronized main, complete local contributor checks, matching canonical CI and Release no-publish evidence, warning dispositions and explicit edit/worktree ownership.
  2. The maintainer can invoke the selected existing conformance profiles with recorded provider/package, suite, image/helper and plan identities; missing or obsolete inputs fail visibly, unavailable history stays unavailable, and any input refresh is reviewed separately from a protocol correction.
  3. The maintainer can inspect one finite, redacted case ledger with source/date and exact identities, normative/support references, observed and expected outcomes, deterministic repro commands, regression owners and dispositions distinguishing protocol, harness/transport/browser, infrastructure, unsupported and already-correct/not-reproduced cases.
  4. Downstream implementers can use the frozen AUTHR/PARB case matrix before dependent plans are created or executed; unresolved security/API/support decisions block that planning, current proof is reused for correct cases, and invalidated slices explicitly narrow/replan requirements and roadmap rather than receive a fabricated pass.

**Plans**: 3 plans

Plans:
**Wave 1**
- [ ] 171-01-PLAN.md — Reviewed delivery/exact-main entry and one end-to-end qualification tracer.

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 171-02-PLAN.md — Exact immutable profile observations and finite attributable case ledger.

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 171-03-PLAN.md — Qualified matrix freeze and explicit downstream scope reconciliation.

### Phase 172: Authorization Responses

**Goal**: Clients receive the qualified authorization-response and authentication-freshness outcomes while callback safety and host account/session authority remain intact.
**Depends on**: Phase 171; its accepted-main gate and frozen authorization case matrix must be satisfied before implementation planning.
**Requirements**: AUTHR-01, AUTHR-02, AUTHR-03
**Success Criteria** (what must be TRUE):
  1. A client receives the selected safe authorization-error response for each qualified invalid-client/redirect case; exact registered-redirect checks prevent an attacker-controlled callback.
  2. A client with a valid callback receives the qualified error/state and supported response-mode representation, with reserved/error parameters encoded unambiguously under the selected adversarial inputs.
  3. A client using the selected prompt=none or max_age cases receives the applicable protocol outcome and authentication-freshness claims without an inappropriate host login redirect; the host remains authoritative for accounts and sessions.

**Plans**: TBD

### Phase 173: Conditional PAR & Profile Boundaries

**Goal**: Clients and integrators can rely on the selected supported PAR/profile contract and distinguish its assertions from issuer, TLS, proxy and browser-harness failures.
**Depends on**: Phase 172 and Phase 171's frozen PAR/profile case matrix; retained scope must survive qualification before implementation planning.
**Requirements**: PARB-01, PARB-02, PARB-03
**Success Criteria** (what must be TRUE):
  1. A client using selected pushed-request references observes the qualified client binding, expiry and one-use semantics; invalid, mismatched and reused references receive the specified failures.
  2. A client receives the qualified outcome for selected pushed-versus-front-channel parameter conflicts and required-PAR cases while existing PKCE and security-profile boundaries remain effective.
  3. An integrator can distinguish the selected PAR/profile assertions from public issuer/TLS/proxy/browser-harness failures, using redacted evidence whose advertised endpoints and tested configured surface agree for those cases.

**Plans**: TBD

### Phase 174: Packaged Proof & Delivery Handoff

**Goal**: Maintainers and adopters can review source-bound proof of every selected behavior and resume from an honest, reviewed delivery handoff through the existing train.
**Depends on**: Phases 172 and 173, or an explicit qualification-driven revision that narrows their scope before dependent plans.
**Requirements**: CPROOF-01, CPROOF-02, DELIV-01, DELIV-02
**Success Criteria** (what must be TRUE):
  1. Every selected supported behavior has a deterministic automated owner and applicable negative/security evidence; each actual correction has a failing-before/passing-after regression, and already-correct behavior cites valid existing proof without duplicate matrices.
  2. A packaged embedded Phoenix host demonstrates the selected authorization/PAR outcomes at recorded source/package identities; supplemental external results keep their exact classifications, with no certification claim or implied full-suite gate.
  3. The maintainer can review current source-bound milestone verification/audit, focused security review and passing required candidate contributor/CI checks, with support/guidance matching delivered behavior and unresolved external limits explicit.
  4. The next run can resume from a dated handoff identifying reviewed integration and fresh main acceptance or explicit remaining delivery blockers, owned resource/worktree cleanup or retained owner/purpose/next action, preserved unknown edits/unique commits, and a refreshed ranked milestone direction with sources and triggers.

**Plans**: TBD

## Execution Gates and Limits

- Phase 171 planning may proceed in this feature checkout. Its first execution boundary is reviewed cumulative prior-delivery reconciliation followed by the existing fresh synchronized exact-main acceptance gate in [REPO-HYGIENE-CHECKLIST.md](REPO-HYGIENE-CHECKLIST.md); the [dated baseline](research/v1.47-core-hardening/BASELINE.md) is not that receipt. Follow the [development train](DEVELOPMENT-TRAIN.md) for the implementation branch.
- Phase 171 must freeze finite case IDs, exact inputs, expected outcomes, standards/support boundaries, repro commands and regression owners before phases 172–174 are planned. Historical suite_failure summaries alone authorize neither dependent plans nor behavior changes. If qualification removes a slice's premise, explicitly amend requirements/roadmap and replan before continuing; do not force empty implementation phases or silently mark their requirements passed.
- Before a product fix, reproduce a supported-surface defect and obtain a deterministic failing regression. Reuse current evidence for already-correct cases; add only meaningful missing proof. Keep protocol corrections separate from reviewed suite/harness input changes. Resolve a newly discovered security policy, API, migration or support expansion before dependent work proceeds.
- Every selected supported behavior is mandatory acceptance. Full external conformance success remains optional, supplemental and non-certifying; unavailable infrastructure or an overall suite result cannot stand in for a selected protocol pass. Reuse existing harnesses and jobs, iterate with focused checks, then run complete required candidate gates. Prefer small auditable glue and existing vetted primitives; no dependency/platform upgrade is selected.
- Preserve S256 PKCE, exact redirects, hashed client secrets, short-lived single-use codes, refresh rotation/family-wide reuse revocation, no implicit flow, no alg=none, redaction and narrow host ownership. No UI redesign, new flow family, broad protocol audit, token retry-grace policy, verifier-key migration, KMS/Vault or manual publication is scheduled. Historical phase directories 142/143 and archived receipts retain their owners and meaning.
- Phase 174 records actual delivery status. A blocked integration/main/cleanup handoff is explicit incomplete delivery, not a clean-main claim; it does not authorize the next milestone's product execution. Public publication remains separate under the [release train](RELEASE-TRAIN.md).

## Progress

**Execution order:** 171 → 172 → 173 → 174, subject to the qualification/replan gates above. Phase 171 has 3 verified plans; downstream plans remain gated on its accepted baseline and frozen case matrix. 0 of 4 phases are complete.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 171. Accepted Baseline & Finding Qualification | 0/3 | Planned; execution gated | - |
| 172. Authorization Responses | 0/TBD | Not started | - |
| 173. Conditional PAR & Profile Boundaries | 0/TBD | Not started | - |
| 174. Packaged Proof & Delivery Handoff | 0/TBD | Not started | - |

## Next Milestone

No later phase numbers are reserved. [MILESTONE-ARC.md](MILESTONE-ARC.md) ranks SEC-01 verifier-key isolation/rotation as preferred provisional v1.48; it remains outside v1.47. Refresh the ranking at each start/close against fresh evidence. Token lifecycle work requires a current gap, OPS-03 requires scale evidence and KEK-04 requires a concrete adopter custody need; existing deferred work keeps its owners.

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
