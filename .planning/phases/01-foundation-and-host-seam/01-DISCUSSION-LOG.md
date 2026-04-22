# Phase 1: Foundation and Host Seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-22T23:27:13Z
**Phase:** 1-Foundation and Host Seam
**Areas discussed:** Public API and install shape, Host seam contract, Storage and adapter boundary, Generated host code footprint

---

## Public API and install shape

| Option | Description | Selected |
|--------|-------------|----------|
| Mounted Phoenix component + small config block | Generator-led onboarding with router mount and runtime config | |
| Behaviour-driven explicit wiring | Narrow explicit modules/behaviours as the real integration contract | |
| Hybrid of both | Phoenix-first install path backed by explicit behaviour/module seams | ✓ |
| Macro-heavy DSL / near-zero generation | Compile-time or fully manual alternatives | |

**User's choice:** One-shot research-backed recommendation rather than picking ad hoc. Locked outcome: Phoenix-first install DX for onboarding, explicit behaviour/module contract underneath.
**Notes:** Rejected macro-heavy DSLs and bare manual Plug mounting as primary Phase 1 posture. Emphasis on least surprise, explicitness, and strong DX.

---

## Host seam contract

| Option | Description | Selected |
|--------|-------------|----------|
| One narrow `AccountResolver` behaviour | Single explicit host-owned identity seam | ✓ |
| Several separate behaviours/modules | Split account, claims, redirects, and subject mapping apart | |
| Loose callback config | Anonymous functions or config-driven callbacks as the main seam | |

**User's choice:** Research-backed recommendation. Locked outcome: one narrow `AccountResolver`-style behaviour.
**Notes:** The behaviour must stay narrow and must not absorb session ownership, product policy, or resource authorization concerns.

---

## Storage and adapter boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Default Ecto/Postgres with thin domain seams | Serious Ecto/Postgres implementation with future adapter escape hatches | ✓ |
| Deep backend-agnostic abstraction from day one | Full portability target in Phase 1 | |
| No meaningful abstraction | Protocol code talks to Ecto directly everywhere | |

**User's choice:** Research-backed recommendation. Locked outcome: Ecto/Postgres-first with thin domain-level store behaviours.
**Notes:** SQL constraints and transactions are treated as a feature for a security-sensitive embedded library, not an implementation detail.

---

## Generated host code footprint

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal glue only | Mount/config stubs with little or no editable host UX | |
| Generated glue plus editable consent/interaction surfaces | Narrow host-owned modules, templates, and tests for app-facing integration | ✓ |
| Very heavy codegen | Broad framework shell generated into the host app | |

**User's choice:** Research-backed recommendation. Locked outcome: generate only the host-owned glue and editable app-facing UX surfaces.
**Notes:** Protocol services, storage logic, and admin internals stay inside Lockspire.

---

## the agent's Discretion

- Final module naming and internal directory structure.
- Precise callback signatures within the chosen narrow seam.
- Exact composition of domain-level storage behaviours.

## Deferred Ideas

- Alternate storage backends beyond Ecto/Postgres.
- Additional host extension points beyond the primary seam.
- Macro/DSL conveniences.
- Broader host-side admin customization.
