# Phase 65: Release Truth & Support Contract Reconciliation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `65-CONTEXT.md`.

**Date:** 2026-05-07
**Phase:** 65-release-truth-support-contract-reconciliation
**Areas discussed:** Release posture baseline, Canonical support contract shape, Changelog and version-history posture, Proof boundary for release claims

---

## Release posture baseline

| Option | Description | Selected |
|--------|-------------|----------|
| Align repo on strict artifact-first `1.0.0` GA now | Make the next protected release the first authoritative `1.0.0` and align metadata/docs/tests together | ✓ |
| Revert public posture to truthful `0.x` preview | Walk docs/tests back down until a later GA release | |
| Transitional `1.0.0-rc` or “GA-ready” posture | Add a bridge posture between current `0.x` metadata and GA docs | |

**User's choice:** Delegated to the agent with instruction to return a cohesive recommendation bundle.
**Notes:** Recommended baseline is strict `1.0.0` artifact-first GA, with immediate rollback to truthful `0.x` only if planning finds a real proof gap that makes GA dishonest.

---

## Canonical support contract shape

| Option | Description | Selected |
|--------|-------------|----------|
| `docs/supported-surface.md` as canonical contract | README/SECURITY/release docs point to one authoritative contract page | ✓ |
| README as canonical contract | Put the full public support policy in README | |
| Machine-readable contract as source of truth | Generate or heavily drive docs from a schema file | |

**User's choice:** Delegated to the agent with instruction to optimize for least surprise and strong DX.
**Notes:** Recommendation keeps a single human-readable canonical contract and avoids multiple equal-weight truth sources.

---

## Changelog and version-history posture

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve `0.x` history, align docs down until later | Keep `0.x` history and revert support posture now | |
| Preserve `0.x` history, cut next coordinated release as real `1.0.0` | Keep history factual, make the next release the first true GA signal | ✓ |
| Retroactively rewrite history as if earlier releases were already `1.0` | Clean up the narrative by reshaping history | |

**User's choice:** Delegated to the agent with instruction to avoid low-signal back-and-forth.
**Notes:** Recommendation is to preserve immutable published history and add explicit `1.0.0` transition wording instead of rewriting chronology.

---

## Proof boundary for release claims

| Option | Description | Selected |
|--------|-------------|----------|
| Public claims depend only on checked-in repo proof | Keep public truth entirely inside docs, workflow contracts, and tests | |
| Repo proof first, optional narrow supplemental release-proof artifact | Keep repo contract primary, allow a tightly scoped supplemental artifact | ✓ |
| Public claims depend on live operational posture and maintainer attestations | Broaden claims to include mutable environment and workflow-run state | |

**User's choice:** Delegated to the agent with instruction to think deeply and choose coherently.
**Notes:** Recommendation keeps public claims rooted in checked-in proof and treats any per-release artifact as supplemental only; live environment settings and trusted runs stay maintainer evidence, not broad public support promises.

---

## the agent's Discretion

- Exact wording and file-level distribution of GA/support/non-claim language
- Exact shape of supplemental release-proof artifact, if implemented
- Exact release-contract test inventory and assertion boundaries

## Deferred Ideas

- Broader audited release-attestation program
- Schema-first support contract generation
- Wider public certification or enterprise-assurance claims
