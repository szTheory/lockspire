# Lockspire Roadmap

## Active Milestone

### v1.16 Embedded Adoption Hardening & Sigra Golden Path

**Status:** Planned
**Phases:** 63-66
**Total Requirements:** 11

#### Overview

v1.16 shifts Lockspire from adding more protocol surface to making the embedded Phoenix path boring and trustworthy. The milestone hardens the canonical host install and upgrade path, proves the Sigra companion story end to end through generated-host flows, reconciles package and support truth, and retires the conformance debt that still affects public claims.

## Phases

### Phase 63: Canonical Install Path & Host Diagnostics
**Goal**: Phoenix teams can install and upgrade Lockspire in the intended embedded shape without guessing where host ownership ends and Lockspire ownership begins.
**Depends on**: None (v1.15 completed)
**Requirements**: HOST-01, HOST-02, HOST-03
**Success criteria:**
1. A maintainer can generate the recommended Lockspire-plus-Sigra host path from documented commands and get a consistent file layout.
2. The install or upgrade path fails early with actionable messages when router wiring, behaviours, migrations, or required runtime configuration are missing.
3. Generated host files and docs make regeneration boundaries explicit enough that a Phoenix team can update Lockspire-owned files without accidentally treating host-owned logic as library-owned.

### Phase 64: Sigra Golden Path & Generated-Host Proof
**Goal**: The Sigra companion story becomes executable repo-owned proof rather than guidance-only documentation.
**Depends on**: Phase 63
**Requirements**: SIGRA-01, SIGRA-02, SIGRA-03
**Success criteria:**
1. The repo can run an end-to-end Sigra-backed authorization-code onboarding flow through generated host code.
2. The proof exercises the host-owned security seams Lockspire depends on, including login redirect preservation, account resolution, consent handoff, and claims construction.
3. Sigra companion docs match the generated host behavior exactly and do not imply a direct dependency or ownership blur between the two libraries.

### Phase 65: Release Truth & Support Contract Reconciliation
**Goal**: Lockspire's package posture, changelog, release automation, and public support contract tell the same story.
**Depends on**: Phase 64
**Requirements**: TRUTH-01, TRUTH-02
**Success criteria:**
1. Package version metadata, release manifests, and changelog posture align with the public release state Lockspire intends to claim.
2. README, SECURITY, supported-surface docs, and release-contract tests describe only the repo-proven embedded surface.
3. Maintainers can point to one coherent release-truth story without caveats caused by stale metadata or contradictory docs.

### Phase 66: Conformance Debt Retirement & Milestone Closure
**Goal**: Public trust claims are backed by executable proof, and the remaining non-claims are explicit.
**Depends on**: Phase 65
**Requirements**: CONF-01, CONF-02, V-01
**Success criteria:**
1. Historical conformance or verification debt that affects Lockspire's trust story is resolved or explicitly retired as a documented non-claim.
2. Maintainer-facing conformance guidance cleanly separates repo-native proof from optional external-suite verification.
3. Every milestone requirement is covered by traceable proof, and closure artifacts leave no ambiguity about what v1.16 does and does not ship.

## Archived Milestones

- [v1.15: JWKS URI & Private Key JWT Client Authentication](./milestones/v1.15-ROADMAP.md) — shipped 2026-05-06; phases 59-62; delivered guarded `jwks_uri` support, shared cryptographic `private_key_jwt` verification, truthful metadata/docs, and release-proof end-to-end coverage.
- [v1.14: Advanced Authorization & Resource Targetting](./milestones/v1.14-ROADMAP.md) — shipped 2026-05-06; phases 54-58; delivered Resource Indicators and Rich Authorization Requests.
