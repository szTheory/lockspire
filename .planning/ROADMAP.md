# Roadmap: Lockspire

## Milestones

- 🚧 **v1.48 Client Authentication Key Isolation & Rotation** — Phases 175–177 independently verified complete; Phase 178 Plan 10 completes current local VPROOF-02 for the 1,078-input closure. VDELIV-01/02 remain pending: PR #141 required candidate CI is incomplete, and main/delivery acceptance is unobserved. Non-authoritative edge/prohibition flags remain visible.
- ✅ [v1.47 OAuth/OIDC Core Interoperability & Hardening](milestones/v1.47-ROADMAP.md) — completed 2026-10-25; Phases171–174, 10 plans, 14/14 requirements; accepted main173059a1; package publication separate.
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

## Current Milestone: v1.48 Client Authentication Key Isolation & Rotation

**Selected 2026-10-25:** The owner accepted the recommended SEC-01-first order. A Phoenix host can protect and rotate `client_secret_jwt` verifier material independently of endpoint/session secrets while preserving existing clients through an explicit upgrade path.

**Planning status:** Focused research is complete and the owner approved all 18 requirements with “lgtm” on 2026-10-25. The owner approved the four-phase roadmap on 2026-10-25. Preserve historical Phase 142/143 directories. [Planning baseline and implementation-entry gate](research/v1.48-client-auth-key-isolation/BASELINE.md), [requirements](REQUIREMENTS.md), [research](research/v1.48-client-auth-key-isolation/SUMMARY.md).

**Next candidate:** UI Stories & Continuous Quality follows SEC-01, preserving its completed Q1–Q10 interview and confirmed final summary. No UI version/phases are reserved. [Ranking and triggers](MILESTONE-ARC.md), [UI proposal](research/ui-quality-engine/MILESTONE-PROPOSAL.md).

## Phases

- [x] **Phase 175: Accepted Baseline & Verifier Compatibility Contract** - Establish fresh implementation entry and freeze the finite custody, legacy, rollout and store contract. (completed 2026-10-25)
- [x] **Phase 176: Dedicated Verifier Custody & Compatible Runtime** - Wire independent keys through every production reader/writer and prove the supported rolling transition. (completed 2026-10-25)
- [x] **Phase 177: Safe Verifier Maintenance & Recovery** - Deliver atomic rewrap/check/status and key rotation/loss recovery without changing client credentials. (completed 2026-10-26)
- [ ] **Phase 178: Packaged Upgrade Proof & Delivery Handoff** - Prove the selected journeys, pass review/gates and leave exact delivery/main-acceptance custody.

## Phase Details

### Phase 172: Authorization Responses

**Goal**: Correct only the reproduced unsupported `response_mode` disposition in A171-003 while carrying forward existing callback and silent-auth proof; preserve host account/session authority.
**Depends on**: Phase 171; its accepted-main gate and frozen authorization case matrix must be satisfied before implementation planning.
**Requirements**: AUTHR-01, AUTHR-02, AUTHR-03
**Success Criteria** (what must be TRUE):
  1. A171-003 receives HTTP 400 without OAuth Error Response parameters for unsupported `response_mode`; move this required assertion to its existing regression owner and show RED at the qualified source followed by GREEN after correction.
  2. Reuse A171-001 and A171-002 proof for exact redirect safety and registered-callback error/state encoding; do not schedule duplicate correction work for those already-proven cases.
  3. Reuse A171-004, A171-005 and A171-006 proof for `prompt=none`, `max_age` and host-provided `auth_time`; preserve host ownership of accounts and sessions.

**Plans**: 1/1 plans complete

Plans:
- [x] 172-01-PLAN.md — Unsupported-mode HTTP 400 correction, Router RED/GREEN and existing authorization proof preservation.

### Phase 173: Conditional PAR & Profile Boundaries

**Goal**: Correct only P171-005's reproduced rejection of a conflicting outer `scope` for a valid pushed request; carry existing PAR lifecycle, required-PAR and issuer-metadata proof forward.
**Depends on**: Phase 172 and Phase 171's frozen PAR/profile case matrix; retained scope must survive qualification before implementation planning.
**Requirements**: PARB-01, PARB-02, PARB-03
**Success Criteria** (what must be TRUE):
  1. For P171-005, a valid PAR reference reaches consent with pushed `openid email`; a conflicting outer `scope=profile` is ignored without union or override, with state and nonce preserved. Move this assertion to its existing regression owner and show RED at the qualified source followed by GREEN after correction.
  2. Reuse P171-001, P171-002 and P171-003 proof for client binding, expiry and one-use; reuse P171-004 proof for required-PAR, preserving existing PKCE and security-profile boundaries.
  3. Reuse P171-006 source-host issuer/discovery metadata proof. External provider-origin, TLS/proxy and browser reachability remain supplemental and unavailable; that limitation does not create another selected code or infrastructure project.

**Plans**: 1/1 plans complete

Plans:
- [x] 173-01-PLAN.md — Pushed-parameter authority correction, real PAR RED/GREEN and retained lifecycle/profile proof.

### Phase 174: Packaged Proof & Delivery Handoff

**Goal**: Maintainers and adopters can review source-bound proof of every selected behavior and resume from an honest, reviewed delivery handoff through the existing train.
**Depends on**: Phases 172 and 173, or an explicit qualification-driven revision that narrows their scope before dependent plans.
**Requirements**: CPROOF-01, CPROOF-02, DELIV-01, DELIV-02
**Success Criteria** (what must be TRUE):
  1. Every selected supported behavior has a deterministic automated owner and applicable negative/security evidence; each actual correction has a failing-before/passing-after regression, and already-correct behavior cites valid existing proof without duplicate matrices.
  2. A packaged embedded Phoenix host demonstrates the selected authorization/PAR outcomes at recorded source/package identities; supplemental external results keep their exact classifications, with no certification claim or implied full-suite gate.
  3. The maintainer can review current source-bound milestone verification/audit, focused security review and passing required candidate contributor/CI checks, with support/guidance matching delivered behavior and unresolved external limits explicit.
  4. The next run can resume from a dated handoff identifying reviewed integration and fresh main acceptance or explicit remaining delivery blockers, owned resource/worktree cleanup or retained owner/purpose/next action, preserved unknown edits/unique commits, and a refreshed ranked milestone direction with sources and triggers.

**Plans**: 4/4 plans complete

Plans:
**Wave 1**
- [x] 174-01-PLAN.md — Packaged authorization tracer, host-owned freshness and strict partial receipts.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 174-02-PLAN.md — Packaged PAR/discovery expansion, guidance and independent scoped reviews.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 174-03-PLAN.md — Reviewed lifecycle repair, frozen all-case proof and verifier-owner freshness.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 174-04-PLAN.md — Exact candidate contributor/CI gates, reviewed delivery or concrete blockers, custody and ranking handoff.

## Execution Gates and Limits

- Phase 171 planning may proceed in this feature checkout. Its first execution boundary is reviewed cumulative prior-delivery reconciliation followed by the existing fresh synchronized exact-main acceptance gate in [REPO-HYGIENE-CHECKLIST.md](REPO-HYGIENE-CHECKLIST.md); the [dated baseline](research/v1.47-core-hardening/BASELINE.md) is not that receipt. Follow the [development train](DEVELOPMENT-TRAIN.md) for the implementation branch.
- Phase 171 must freeze finite case IDs, exact inputs, expected outcomes, standards/support boundaries, repro commands and regression owners before phases 172–174 are planned. Historical suite_failure summaries alone authorize neither dependent plans nor behavior changes. If qualification removes a slice's premise, explicitly amend requirements/roadmap and replan before continuing; do not force empty implementation phases or silently mark their requirements passed.
- Before a product fix, reproduce a supported-surface defect and obtain a deterministic failing regression. Reuse current evidence for already-correct cases; add only meaningful missing proof. Keep protocol corrections separate from reviewed suite/harness input changes. Resolve a newly discovered security policy, API, migration or support expansion before dependent work proceeds.
- Every selected supported behavior is mandatory acceptance. Full external conformance success remains optional, supplemental and non-certifying; unavailable infrastructure or an overall suite result cannot stand in for a selected protocol pass. Reuse existing harnesses and jobs, iterate with focused checks, then run complete required candidate gates. Prefer small auditable glue and existing vetted primitives; no dependency/platform upgrade is selected.
- Preserve S256 PKCE, exact redirects, hashed client secrets, short-lived single-use codes, refresh rotation/family-wide reuse revocation, no implicit flow, no alg=none, redaction and narrow host ownership. No UI redesign, new flow family, broad protocol audit, token retry-grace policy, verifier-key migration, KMS/Vault or manual publication is scheduled. Historical phase directories 142/143 and archived receipts retain their owners and meaning.
- Phase 174 records actual delivery status. A blocked integration/main/cleanup handoff is explicit incomplete delivery, not a clean-main claim; it does not authorize the next milestone's product execution. Public publication remains separate under the [release train](RELEASE-TRAIN.md).

## Progress

**Execution order:** 171 → 172 → 173 → 174, subject to the qualification/replan gates above. Phases 171–173 are complete; Phase 173 has six verified behavioral truths and two flagged judgment reviews. Phase 174 is preparing packaged proof and delivery. Prior verification owners must reassess freshness after the covered source/evidence changes. 3 of 4 phases are complete.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 171. Accepted Baseline & Finding Qualification | 4/4 | Complete    | 2026-10-24 |
| 172. Authorization Responses | 1/1 | Complete    | 2026-10-24 |
| 173. Conditional PAR & Profile Boundaries | 1/1 | Complete    | 2026-10-24 |
| 174. Packaged Proof & Delivery Handoff | 4/4 | Complete    | 2026-10-25 |

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

### Phase 175: Accepted Baseline & Verifier Compatibility Contract

**Goal**: Maintainer can identify a fresh accepted implementation base and a finite, reviewable verifier-custody/compatibility contract before dependent implementation is planned.
**Depends on**: Nothing (first phase of v1.48); uses completed v1.47 evidence without restamping it.
**Requirements**: VBASE-01, VBASE-02
**Success Criteria** (what must be TRUE):
  1. Maintainer can inspect reviewed retained-delivery/worktree disposition and a fresh receipt from the existing exact-main helper binding synchronized main, local contributor checks, matching canonical CI/Release no-publish and explicit warning/resource dispositions before product implementation.
  2. Maintainer can reproduce the qualified legacy-age behavior through its actual caller/lifecycle seam and inspect distinct dispositions for usable, aged, malformed and configured-expired credentials; no age override or security-policy change is silently selected.
  3. Implementers can inspect a frozen finite ledger covering every writer/reader, stable client-identity sealing, text format/key configuration, missing-key behavior, supported custom-store transaction/capability contract, rollout/rollback states, expected outcomes and automated proof owners.
  4. Unresolved material policy/API/support changes stop dependent planning; evidence that invalidates the recommended no-schema/no-new-dependency scope produces an explicit GSD revision rather than an unreviewed expansion. Historical Phase 142/143 and immutable receipts remain intact.

**Plans**: 3/3 plans complete

Plans:
**Wave 1**
- [x] 175-01-PLAN.md — Reconcile retained lineage and custody; establish fresh exact-main baseline.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 175-02-PLAN.md — Qualify persisted legacy age, public metadata and helper compatibility; resolve material policy gates.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 175-03-PLAN.md — Freeze the finite custody/compatibility contract and reconcile the qualified candidate with accepted entry main.

### Phase 176: Dedicated Verifier Custody & Compatible Runtime

**Goal**: Host can use independent verifier keys across existing credential creation, rotation and authentication paths, with deliberate legacy compatibility and safe reader-first rollout.
**Depends on**: Phase 175; accepted-main entry and frozen contract must pass before dependent implementation planning.
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, VUP-01, VUP-02
**Success Criteria** (what must be TRUE):
  1. Host explicitly configures independent verifier read/write keys and transition mode; dedicated writes use the current key without endpoint/signing-key fallback, while malformed/missing required configuration fails through the qualified redacted contract without a surprise unrelated-auth boot failure.
  2. Direct registration, DCR and operator secret rotation persist coherent hash/verifier pairs bound to canonical client identity; new text-safe envelopes reject key/version/header/tag/client/purpose tampering, and existing signing-envelope bytes and key behavior remain compatible.
  3. Supported token, introspection, revocation, device-authorization and CIBA paths accept valid dedicated verifiers and reject invalid ones while preserving existing HS256, audience, JTI/replay, configured lifetimes and PAR/FAPI boundaries.
  4. Qualified usable legacy rows read only within the explicit compatibility policy and fail under legacy rejection; aged/unreadable rows follow the frozen disposition, with no silent credential-expiry or authority change.
  5. Maintainer can execute the finite reader-first/writer-activation/rollback cases: old code is never exposed to unsupported writes in the supported sequence, and after activation the documented rollback boundary is truthful.

**Plans**: 7/7 plans complete, 14 tasks; independent verification passed 28/28 truths and all seven requirements on 2026-10-25. Security review closed 22/22 planned threats.

Plans:
**Wave 1**
- [x] 176-01-PLAN.md — Persisted native-verifier tracer and strict envelope parsing.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 176-02-PLAN.md — Immutable node configuration and operation-local failure isolation.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 176-03-PLAN.md — Compatible helpers and final-ID direct registration.
- [x] 176-04-PLAN.md — Legacy/migrated age and configured lifecycle boundaries.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 176-05-PLAN.md — Final-ID DCR and operator secret rotation.
- [x] 176-06-PLAN.md — Supported endpoints and ciphertext-sensitive guarded issuance.

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 176-07-PLAN.md — Local reader-first rollout, runtime guidance and candidate gate.

### Phase 177: Safe Verifier Maintenance & Recovery

**Goal**: Operator can inspect, rewrap and rotate verifier-key custody safely, and recover affected clients after key loss, without changing partner secrets or hiding failed work.
**Depends on**: Phase 176.
**Requirements**: VUP-03, VOPS-01, VOPS-02, VOPS-03, VOPS-04, VPROOF-01
**Success Criteria** (what must be TRUE):
  1. Maintainer can run repo-safe preview/apply/check and retry a partial run idempotently; failures/conflicts are distinct and requested readiness/completion fails when unfulfilled, with accurate operator guidance and bare-Mix startup behavior.
  2. Actual PostgreSQL contention/rollback cases prove verifier-only writes and audit atomicity through the selected supported store/transaction authority, preserving concurrent secret/hash/client updates, lifetimes and rotation timestamps; unsupported adapter capability fails before mutation.
  3. Status accounts for all stored material, including inactive/expired/non-JWT-method clients, and distinguishes legacy/current/old-key/unknown/malformed/unreadable/uninspected states. No partial/local check claims complete/fleet-wide readiness.
  4. Operator can introduce/read a new key, activate writes, rewrap and safely retire the old key; missing/lost-key cases identify affected clients and demonstrate valid-key restoration or existing authorized secret rotation/reprovision while affected JWT auth fails closed.
  5. Sentinel-based proof across crypto/runtime/task/storage failures shows no verifier plaintext, encryption key or ciphertext in logs/SQL diagnostics, telemetry, audit, operator reports or protocol responses. Endpoint/session secrets, signing custody and unrelated supported methods remain intact.

**Plans**: 9/9 plans complete in 7 waves; independently verified 2026-10-26 (47/47 truths, six requirements). Package-installed proof and delivery remain Phase 178.

Plans:
**Wave 1**
- [x] 177-01-PLAN.md — Native persisted rewrap tracer, selected authority and exact CAS.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 177-02-PLAN.md — Authenticated custody, preserved migrated age and qualified legacy promotion.
- [x] 177-07-PLAN.md — Existing-path nested inspection and dual query-channel disclosure controls.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 177-03-PLAN.md — Exhaustive bytewise inventory, safe status and complete-mode outcomes.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 177-04-PLAN.md — Task-local configuration, bare Mix modes and Repo ownership.
- [x] 177-05-PLAN.md — Independent PostgreSQL contention, rollback and retry proof.

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 177-06-PLAN.md — Real guarded issuance, key rotation and key-loss recovery.

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 177-08-PLAN.md — Forced-failure sentinel matrix and executable operator guidance.

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 177-09-PLAN.md — Exact source acceptance, coverage audit and Phase 178 handoff.

Execution waves: 1: 01; 2: 02 + 07; 3: 03; 4: 04 + 05; 5: 06; 6: 08; 7: 09.

### Phase 178: Packaged Upgrade Proof & Delivery Handoff

**Goal**: Maintainer can reproduce the complete selected adoption/upgrade/rotation story and assess a reviewed delivery with accurate guidance and intentional resource custody.
**Depends on**: Phase 177 and all prior selected acceptance outcomes.
**Requirements**: VPROOF-02, VDELIV-01, VDELIV-02
**Success Criteria** (what must be TRUE):
  1. Source/package-bound fresh and legacy-installed hosts on both existing dependency pairs reproduce the selected upgrade, mixed-version/key, writer activation, rewrap/rotation, legacy rejection, rollback limits and recovery cases, including the declared configured-store composition. Missing/unavailable proof stays a blocker, not a pass.
  2. Reviewer can inspect required actual PostgreSQL concurrency/rollback evidence, focused security/code review, all 18 verified requirements and the milestone audit, plus passing full contributor and canonical candidate CI gates at exact identities.
  3. Fresh-install, generator, upgrade, diagnostic and support guidance matches verified behavior without changing public protocol scope, signing format, host ownership, schema or runtime dependencies unless explicitly re-scoped through GSD.
  4. A dated handoff records reviewed integration and fresh exact-main acceptance or explicit unresolved delivery blockers, resource owners/purpose/next actions and preserved unknown work; UI quality remains the next substantial candidate with the completed interview intact. No package publication is inferred.

**Plans**: 10/12 plans executed in 8 waves; the normal milestone PR and protected release train remain distinct.

Plans:
**Wave 1**
- [x] 178-01-PLAN.md — Installed tracer, honest package attribution and generic pair selection.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 178-02-PLAN.md — Four fresh core cells, declared delegation and installed preview/apply/check.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 178-03-PLAN.md — Actual predecessor/shared-store rollout and pinned public legacy control.
- [x] 178-04-PLAN.md — Five HTTP endpoints per pair and booted release RPC.
- [x] 178-05-PLAN.md — Real PostgreSQL lock orders, reached audit INSERT and outer rollback.
- [x] 178-06-PLAN.md — Preservation, exact age/retry/recovery and stale-issuance/JTI witnesses.
- [x] 178-07-PLAN.md — Installed success/failure disclosure channels and sentinel rejection.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 178-08-PLAN.md — Closed aggregate and existing locked/floor CI integration.

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 178-09-PLAN.md — Observed install/generator/upgrade/support/release guidance.

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 178-10-PLAN.md — Independent reviews, frozen inputs and final local/package gates.

**Wave 7** *(blocked on Wave 6 completion)*
- [ ] 178-11-PLAN.md — Single reviewed candidate and actual complete hosted graph.

**Wave 8** *(blocked on Wave 7 completion)*
- [ ] 178-12-PLAN.md — Canonical audit, dated custody/ranking and pending-or-accepted main handoff.

## Progress

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 175. Accepted Baseline & Verifier Compatibility Contract | 3/3 | Complete    | 2026-10-25 |
| 176. Dedicated Verifier Custody & Compatible Runtime | 7/7 | Complete    | 2026-10-25 |
| 177. Safe Verifier Maintenance & Recovery | 9/9 | Complete    | 2026-10-26 |
| 178. Packaged Upgrade Proof & Delivery Handoff | 10/12 | In Progress | — |

**Coverage:** 18/18 approved requirements map exactly once; 4 approved phases; Phases 175–177 completed 19/19 plans and 15/18 requirements. Phase 178 has 10/12 plans executed; current 1,078-input local review/refreeze/source/package qualification completes VPROOF-02. VDELIV-01/02 remain pending because PR #141 candidate CI is incomplete and main/delivery acceptance remains unobserved. Plan 11 is incomplete; Plan 12 has not started. The phase remains in progress. Roadmap approved 2026-10-25.

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
