# v1.22 DPoP Nonce Support Roadmap

## Overview
This milestone adds the remaining high-leverage DPoP trust wedge without widening Lockspire's product shape: server-provided nonce challenge and retry behavior on the DPoP surfaces Lockspire already owns and proves today.

## Architecture & Sequencing
The work starts with one shared nonce primitive and validator path, then adopts it on Lockspire-owned token and protected-resource surfaces, and finishes by updating the host plug contract plus the public support story.

## Phases

### Phase 82: Shared DPoP Nonce Primitive
**Goal**: Add one shared DPoP nonce issuance and validation path without introducing new operator or client policy knobs.

**Plans:** 2/2 plans complete
- [x] 82-01-PLAN.md — Add a shared DPoP nonce primitive and wire nonce validation into the existing proof validator
- [x] 82-02-PLAN.md — Add unit proof for nonce issuance, purpose separation, and typed nonce failure reasons

### Phase 83: Lockspire-owned DPoP Endpoint Adoption
**Goal**: Apply nonce challenge/retry behavior to the Lockspire-owned DPoP token and protected-resource surfaces.

**Plans:** 3 planned
- [ ] 83-01-PLAN.md — Add authorization-server nonce challenge and retry behavior on `/token`
- [ ] 83-02-PLAN.md — Add resource-server nonce challenge and retry behavior on `/userinfo`
- [ ] 83-03-PLAN.md — Keep replay, `ath`, binding, MTLS, and bearer regressions covered while adopting nonce support

### Phase 84: Host Plug Pipeline, Docs, and Milestone Closure
**Goal**: Extend the shipped host Phoenix plug contract and public support story to include nonce-backed DPoP.

**Plans:** 3 planned
- [ ] 84-01-PLAN.md — Add nonce-aware DPoP challenge behavior to `EnforceSenderConstraints` and `RequireToken`
- [ ] 84-02-PLAN.md — Update supported-surface and protected-route docs plus release-readiness contract wording
- [ ] 84-03-PLAN.md — Prove the generated-host protected-route nonce retry path and close the milestone
