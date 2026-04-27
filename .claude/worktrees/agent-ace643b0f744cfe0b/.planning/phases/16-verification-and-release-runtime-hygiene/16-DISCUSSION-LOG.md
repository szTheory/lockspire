# Phase 16: Verification and Release Runtime Hygiene - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-24
**Phase:** 16-Verification and Release Runtime Hygiene
**Areas discussed:** Verification closure scope, PAR closure proof style, release workflow upgrade scope, release docs and contract strictness

---

## Verification Closure Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Phase 16 narrow | Close only `PAR-04` and `RELS-04`; leave older Nyquist backfill as separate debt | ✓ |
| Fold Nyquist backfill into Phase 16 | Backfill `10/12/13-VALIDATION.md` during this phase to improve completeness | |

**User's choice:** Adopt the recommendation and decide by default.
**Notes:** Narrow scope best matches Lockspire's milestone discipline, least-surprise planning, and the v1.2 PAR wedge. Backfilling old validation files inside Phase 16 would blur milestone closure and raise review noise.

---

## PAR Closure Proof Style

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing harnesses | Build `16-VALIDATION.md` and `16-VERIFICATION.md` around current protocol/web/integration/truth-surface tests | |
| Add duplicate Phase 16 suites | Create new phase-branded tests for PAR closure even if scenarios already exist | |
| Hybrid minimal gap-filling | Reuse existing harnesses first; add only narrowly targeted tests if traceability reveals a real gap | ✓ |

**User's choice:** Adopt the recommendation and decide by default.
**Notes:** This is the most idiomatic ExUnit approach for a library: strong focused tests, one canonical end-to-end proof, and artifact-level traceability instead of duplicated suites for optics.

---

## Release Workflow Upgrade Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Smallest pin bump | Upgrade only the `googleapis/release-please-action` SHA/version if upstream supports a newer runtime | |
| Broader cleanup/refactor | Redesign the release lane while fixing the warning | |
| Narrow implementation swap | Keep Release Please semantics and protected publish lane, but replace the Node 20-bound action implementation with a pinned CLI-based invocation | ✓ |

**User's choice:** Adopt the recommendation and decide by default.
**Notes:** Research found that as of 2026-04-24 the latest published `release-please-action` still declares `runs: using: node20`, so a simple pin refresh would not remove the warning. The right move is a narrow implementation swap, not a policy rewrite.

---

## Release Docs And Contract Strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Update only real contract changes | Keep docs/tests focused on actual release invariants and behavior changes | ✓ |
| Increase strictness aggressively | Add more repo-truth assertions around release internals and wording | |
| Loosen docs/tests | Reduce strictness to avoid maintenance burden | |

**User's choice:** Adopt the recommendation and decide by default.
**Notes:** Lockspire already has strong repo-truth discipline. The right balance is precise, durable assertions around the maintainer contract, not brittle coupling to every literal phrase or upstream implementation detail.

---

## the agent's Discretion

- Downstream agents should research broadly, synthesize decisively, and avoid re-asking decisions unless a choice materially affects milestone scope, trust boundaries, or supported surface.

## Deferred Ideas

- Revisit older missing validation artifacts after the v1.2 milestone if the project still wants full Nyquist completeness.
- Keep any broader release-lane redesign out of Phase 16.
