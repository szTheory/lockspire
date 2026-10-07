# Phase 138: Baseline Inventory & Evidence Taxonomy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 138-Baseline Inventory & Evidence Taxonomy
**Areas discussed:** Inventory artifact shape, Freshness and provenance, Disposition vocabulary, Maintained-record boundary

---

## Inventory Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| One canonical dated Markdown ledger | Human-readable, Git-reviewable ledger with compact front matter, domain sections, and stable evidence IDs. | ✓ |
| Markdown index plus per-domain records | Small index linking separate Git, GitHub, follow-up, and later evidence records. | |
| Structured canonical ledger plus generated Markdown | JSON/YAML source of truth with schema validation and a rendered report. | |

**User's choice:** Delegated the choice to the agent, then accepted the recommendation for one canonical Markdown ledger.
**Notes:** Temporary structured parsing is allowed, but no sidecar becomes a second source of truth. Split records and a generator/schema subsystem add overhead that Phase 138 has not justified.

### Collector Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the existing hygiene checker | Add inventory generation to the current `PASS`/`WARN`/`BLOCK` gate. | |
| Add a Mix task | Put maintainer collection under `lib/mix/tasks` for familiar Elixir invocation. | |
| Purpose-built repo-local Bash collector | Keep evidence collection separate from gates and outside packaged/runtime surface. | ✓ |

**User's choice:** Accepted the agent's recommendation for a purpose-built `scripts/maintainer/` collector.
**Notes:** No Ecto, Phoenix, LiveView, Oban, Mix task, or supported host-facing surface. Existing repo conventions and contract tests make repo-local Bash the least-surprising boundary.

---

## Freshness and Provenance

| Option | Description | Selected |
|--------|-------------|----------|
| Timestamp-only snapshot | Record a generation date and human narrative. | |
| Exact-SHA and source-bound provenance | Record collection window, exact identities, commands, versions, completeness, and limitations. | ✓ |
| Raw command-output archive | Preserve complete stdout/stderr captures as the primary proof. | |

**User's choice:** Accepted exact-SHA and source-bound provenance.
**Notes:** Failures become `unavailable`, bounded results become `partial`, and a successful zero-result query is explicit. Mutable evidence is revalidated before later reconciliation, action, and closure. Tag refresh must not prune local tags.

---

## Disposition Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Domain vocabularies only | Use unrelated Git, PR, issue, and finding fields with no shared lifecycle/evidence layer. | |
| One normalized vocabulary | Force every subject into common states and actions. | |
| Layered model | Share lifecycle, evidence, confidence, and proposal fields while preserving domain-native dispositions. | ✓ |

**User's choice:** Accepted the layered model.
**Notes:** Phase 138 records proposals only. Phase 140 must revalidate target, authority, recovery, cleanliness, historical safety, and required gates before action. `Historical` never means disposable, and `resolved` requires terminal evidence.

---

## Maintained-Record Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit maintained source-family manifest | Inventory known maintained record families, summarize closed archives, and expand ambiguous findings. | ✓ |
| Full-repository dump | Search and copy every filename or text match, including generated and incidental files. | |
| GitHub-only backlog | Treat PRs and issues as the sole source of actionable work. | |

**User's choice:** Accepted the explicit source-family manifest.
**Notes:** Include planning todos, debug, quick, threads, seeds, active/ambiguous audit and verification records, handoffs/checkpoints, current truth claims, and retained conformance findings. Exclude generated/incidental trees unless a gate produces one meaningful finding. Deduplicate through canonical evidence IDs.

---

## the agent's Discretion

- The user explicitly requested subagent research and delegated all decision points to the agent, with emphasis on coherent architecture, maintainer DX, least surprise, safety, and applicable UX/accessibility lenses.
- The agent selected tactical defaults for artifact structure, repo-local ownership, evidence semantics, taxonomy, record boundaries, microcopy, and contract-proof expectations.
- Internal shell function names, exact temporary parsing mechanics, and final table formatting remain planner discretion within the locked decisions.

## Deferred Ideas

- A recurring machine-readable repository-health subsystem is deferred unless v1.38 demonstrates a repeatable mechanically detectable gap.
- A Phoenix/LiveView dashboard or consumer-facing Mix task is outside this maintainer-only phase.
