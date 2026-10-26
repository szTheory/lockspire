# Roadmap: Lockspire

## Milestones

- 🚧 **v1.48 Client Authentication Key Isolation & Rotation** — Phases 175–178 approved; Phase 175 verified complete with 3 non-authoritative prohibition flags; Phase 176 discussion is next when resumed.
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
- [ ] **Phase 177: Safe Verifier Maintenance & Recovery** - Deliver atomic rewrap/check/status and key rotation/loss recovery without changing client credentials.
- [ ] **Phase 178: Packaged Upgrade Proof & Delivery Handoff** - Prove the selected journeys, pass review/gates and leave exact delivery/main-acceptance custody.

## Phase Details

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

**Plans**: To be created after the runtime boundary is verified; no broad admin redesign or new UI quality machinery.

### Phase 178: Packaged Upgrade Proof & Delivery Handoff

**Goal**: Maintainer can reproduce the complete selected adoption/upgrade/rotation story and assess a reviewed delivery with accurate guidance and intentional resource custody.
**Depends on**: Phase 177 and all prior selected acceptance outcomes.
**Requirements**: VPROOF-02, VDELIV-01, VDELIV-02
**Success Criteria** (what must be TRUE):
  1. Source/package-bound fresh and legacy-installed hosts on both existing dependency pairs reproduce the selected upgrade, mixed-version/key, writer activation, rewrap/rotation, legacy rejection, rollback limits and recovery cases, including the declared configured-store composition. Missing/unavailable proof stays a blocker, not a pass.
  2. Reviewer can inspect required actual PostgreSQL concurrency/rollback evidence, focused security/code review, all 18 verified requirements and the milestone audit, plus passing full contributor and canonical candidate CI gates at exact identities.
  3. Fresh-install, generator, upgrade, diagnostic and support guidance matches verified behavior without changing public protocol scope, signing format, host ownership, schema or runtime dependencies unless explicitly re-scoped through GSD.
  4. A dated handoff records reviewed integration and fresh exact-main acceptance or explicit unresolved delivery blockers, resource owners/purpose/next actions and preserved unknown work; UI quality remains the next substantial candidate with the completed interview intact. No package publication is inferred.

**Plans**: To be created after prior outcomes pass; the normal milestone PR and protected release train remain distinct.

## Progress

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 175. Accepted Baseline & Verifier Compatibility Contract | 3/3 | Complete    | 2026-10-25 |
| 176. Dedicated Verifier Custody & Compatible Runtime | 7/7 | Complete    | 2026-10-25 |
| 177. Safe Verifier Maintenance & Recovery | 0/0 | Not started | — |
| 178. Packaged Upgrade Proof & Delivery Handoff | 0/0 | Not started | — |

**Coverage:** 18/18 approved requirements map exactly once; 4 approved phases; Phase 175 completed 3/3 plans and Phase 176 completed 7/7 plans; 2/4 phases complete. Dedicated custody and compatible runtime are verified; maintenance and packaged delivery remain pending. Roadmap approved 2026-10-25.

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
