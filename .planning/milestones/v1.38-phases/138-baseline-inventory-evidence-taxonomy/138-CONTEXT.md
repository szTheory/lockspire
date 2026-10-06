# Phase 138: Baseline Inventory & Evidence Taxonomy - Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 138 delivers one dated, non-destructive evidence inventory covering refreshed local and remote Git state, every open GitHub pull request and issue, and every maintained operational follow-up source. It records observations, completeness, provenance, and proposed dispositions. It does not delete refs or worktrees, merge or close GitHub items, fix findings, change release-owned files, add product/runtime surface, or perform Phase 140's authorized actions.

</domain>

<decisions>
## Implementation Decisions

### Inventory Artifact and Ownership
- **D-01:** Produce one canonical dated Markdown ledger under the Phase 138 planning directory. Use compact YAML front matter for snapshot-wide metadata, stable domain sections for Git, GitHub, and maintained records, and stable evidence IDs that later phases can reference without copying rows.
- **D-02:** Markdown is the authoritative record. The collector may use temporary JSON internally to parse structured command output, but no JSON/YAML sidecar is canonical or committed unless later evidence proves a recurring machine-consumption need.
- **D-03:** Add a purpose-built repo-local Bash collector under `scripts/maintainer/` rather than a Mix task, Ecto schema, Phoenix route, LiveView, Oban job, or runtime module. Repository-maintainer workflow must not become supported Hex-library or host-application surface.
- **D-04:** Keep `scripts/maintainer/repo_hygiene_check.sh` focused on recurring `PASS`/`WARN`/`BLOCK` readiness gates. The inventory collector answers what was observed and proposed; it must not overload gate semantics or turn the hygiene script into an artifact store.
- **D-05:** Prefer compact summary tables plus detail blocks for ambiguous or actionable entries. Do not copy raw command output when exact structured fields, source links, and reproduction commands are sufficient.

### Freshness, Provenance, and Completeness
- **D-06:** Record a UTC RFC 3339 collection window, repository identity, local HEAD, refreshed `origin/main`, full immutable SHAs, tool versions, commands, exit status, query scope, canonical paths or URLs, and limitations. Keep `observed_at`, upstream `source_updated_at`, mutable ref names, and immutable observed SHAs as separate concepts.
- **D-07:** Every evidence source reports `complete`, `partial`, `unavailable`, or `not_applicable`. A failed fetch, missing or unauthenticated tool, API error, pagination boundary, inaccessible source, or redacted field is never represented as an empty or clean result.
- **D-08:** Do not assign an arbitrary time-to-live to a snapshot. Revalidate relevant mutable evidence at the start of Phases 139 and 140, immediately before any Phase 140 mutation, and again during Phase 141 exact-SHA closure.
- **D-09:** Refresh origin branches and tags as required, but explicitly prevent local-tag pruning. Fetch is the only permitted local metadata mutation during collection; the collector must not alter the working tree, local branches, tags, worktrees, GitHub objects, release-owned files, or historical evidence.
- **D-10:** Use stable, script-oriented interfaces such as Git porcelain output, `git for-each-ref`, and structured/paginated GitHub CLI or API output. Default or silently bounded list limits are not completeness evidence.
- **D-11:** Redact secrets and uncontrolled bodies. Preserve full identifiers, safe status fields, counts, URLs, and redacted receipt links; do not embed raw CI/OIDF logs, tokens, credentials, environment values, or issue-body dumps.

### Evidence and Disposition Taxonomy
- **D-12:** Use a layered model: shared evidence/lifecycle fields plus exact domain-native proposed dispositions. Shared lifecycle values are `active`, `resolved`, `historical`, and `incidental`; confidence values are `direct_current`, `corroborated`, and `inferred`.
- **D-13:** Branches, tags, and worktrees use `keep`, `proposed-remove`, or `defer`. Pull requests use `merge-ready`, `needs-work`, `close`, or `defer`. Issues use `close`, `retain`, or `defer`. Maintained findings use `fix-now`, `defer-with-trigger`, `retain-historical`, `already-resolved`, or `out-of-scope`.
- **D-14:** Each row includes a stable ID and kind, canonical subject, observed state, lifecycle, domain-specific proposed disposition, evidence reference, concise rationale, confidence, recheck trigger or next proof, required authority, and explicit proposed-versus-executed state.
- **D-15:** Phase 138 dispositions are proposals only. Phase 140 must revalidate the exact target, current state, authority, recovery path, uncommitted-work safety, historical-evidence safety, and required gates before any action.
- **D-16:** `resolved` requires terminal proof; `historical` means intentionally preserved, never disposable; `close` must distinguish completed from not planned; and a green PR check snapshot alone does not establish merge readiness.

### Maintained-Record Boundary
- **D-17:** Drive discovery from an explicit source-family manifest rather than an unrestricted full-repository text dump. Include `.planning/todos/`, `.planning/debug/`, `.planning/quick/`, `.planning/threads/`, `.planning/seeds/`, active or ambiguous review/audit/verification/UAT/handoff/checkpoint records, `.continue-here.md`, current roadmap/state/milestone/release-train claims, retained supplemental conformance findings, and credible tracked `TODO`/`FIXME` follow-ups.
- **D-18:** Summarize completed milestone, quick-work, debug, audit, review, and verification archive containers instead of re-triaging every fulfilled file. Expand only unresolved, contradictory, ambiguous, or still-actionable findings.
- **D-19:** Exclude generated and incidental paths such as `deps`, `_build`, `cover`, generated `doc`, `.artifacts`, `tmp`, `.DS_Store`, caches, and abandoned tool workspaces from per-file inventory. If a repository-owned gate reports a meaningful problem in such a path, record one finding with its exact source rather than inventorying the tree.
- **D-20:** Deduplicate repeated mentions into one canonical evidence row with references from other records. Preserve supersession and rationale instead of rewriting historical records.

### Maintainer Experience and Verification
- **D-21:** The primary persona is the release steward returning after a milestone; secondary personas are an on-call maintainer, a contributor evaluating queued work, and a future maintainer reconstructing prior decisions. Their job is to establish what is true, retained, and justified without deleting proof.
- **D-22:** This phase's user experience is terminal plus accessible Markdown, not a Phoenix UI. Use semantic headings and tables, deterministic ordering, concise low-anxiety copy, explicit text statuses, and no color- or emoji-only meaning. Follow the current repo-root brandbook when presentation guidance applies.
- **D-23:** Prefer microcopy such as `Observed`, `Proposed disposition`, `Collection unavailable`, `Revalidation required before action`, and `No open issues observed; query succeeded with 0 results`. Avoid unconditional claims such as `Everything clean`, `Safe to delete`, or `Nothing found` when evidence is incomplete.
- **D-24:** Add focused contract proof for deterministic ordering, stable IDs and headings, complete Git/GitHub enumeration, pagination/count handling, failed-source semantics, redaction, non-destructive command policy, tag-pruning safety, and the absence of new public/runtime/Mix-task surface.

### the agent's Discretion
The user delegated the complete decision set to the agent after research. Downstream planning may choose internal shell function names, exact table layout, and temporary parsing mechanics, provided the locked ownership, evidence, taxonomy, safety, accessibility, and phase-boundary decisions above remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope and Truth
- `.planning/PROJECT.md` — Defines v1.38 as an evidence-led maintenance baseline and locks the product/runtime scope exclusions.
- `.planning/REQUIREMENTS.md` — Defines BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, and LOOSE-01 plus the later-phase action boundaries.
- `.planning/ROADMAP.md` — Defines Phase 138's goal, success criteria, dependencies, and handoff into Phases 139-141.
- `.planning/STATE.md` — Carries the current milestone position, exact recent release evidence, locked decisions, and known concerns.

### Maintainer and Release Contracts
- `.planning/REPO-HYGIENE-CHECKLIST.md` — Existing local Git, GitHub, gate, GSD, and release-readiness command vocabulary to preserve and strengthen.
- `.planning/RELEASE-TRAIN.md` — Defines sustaining GA posture, exact-ref release ownership, and retained release truth.
- `.planning/DEVELOPMENT-TRAIN.md` — Defines feature versus sustaining lanes and the boundary around release-publication ownership.

### Local Research and Design Guidance
- `prompts/lockspire-elixir-oss-library-practices.md` — Elixir library DX, explicit API, documentation, observability, packaging, and public-surface guidance applicable to keeping maintenance tooling repo-local.
- `prompts/lockspire-release-engineering-and-ci.md` — Release evidence, deterministic CI, immutable action pins, artifact/provenance, and release-automation footguns.
- `prompts/lockspire-release-readiness-and-conformance.md` — Release-gate, maintained-doc, conformance, and sustainability expectations.
- `brandbook/README.md` — Identifies the repo-root brandbook as the current shipped design-system package and source of presentation truth.
- `brandbook/notes/decision-log.md` — Current accessibility, light/dark/system, typography, and calm operator-product decisions; supersedes conflicting older prompt-brand guidance where presentation applies.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/maintainer/repo_hygiene_check.sh`: Existing repo-local Bash conventions for Git, GitHub, release, Docker, and local-gate inspection. Reuse narrow read-only command patterns or helpers, but preserve its gate-only responsibility.
- `.planning/REPO-HYGIENE-CHECKLIST.md`: Existing maintainer command surface and source-family starting point.
- `test/lockspire/release/repository_hygiene_contract_test.exs`: Established ExUnit contract-test entry point for repository hygiene and public-surface boundaries.
- `test/support/lockspire/release_proof/package_assertions.ex`: Existing assertions that keep repository hygiene deterministic and outside packaged runtime surface.
- GitHub CLI structured JSON and Git porcelain formats: Existing tools support deterministic collection without a new application dependency.

### Established Patterns
- Maintainer lifecycle and hygiene automation is implemented as repo-local shell tooling, while ExUnit contract tests pin its boundary and deterministic source contract.
- Release and conformance evidence is exact-SHA-bound, redaction-conscious, and explicit about required versus supplemental proof.
- The project deliberately blocks cleanup/hygiene Mix tasks and runtime modules so maintainer mechanics do not become Lockspire consumer API.
- Planning history is preserved under `.planning/` and archived milestone directories rather than rewritten or deleted.

### Integration Points
- Add the collector under `scripts/maintainer/` and its focused contract proof under the existing release/repository-hygiene test support.
- Write the dated canonical inventory under `.planning/phases/138-baseline-inventory-evidence-taxonomy/`.
- Phases 139-141 should reference stable Phase 138 evidence IDs and revalidate mutable sources rather than duplicating or silently trusting stale rows.
- The existing hygiene checker may point maintainers to the current inventory, but should not generate or own it.

</code_context>

<specifics>
## Specific Ideas

- The current pre-refresh workspace illustrates the required distinctions: the working tree is clean while local `main` is five commits ahead of the cached `origin/main`; several local branches report gone upstreams; and old verification/snapshot/WIP branches require explicit evidence-backed dispositions rather than age-based deletion.
- A read-only GitHub sample on 2026-08-28 found six open PRs (five Dependabot updates and one older draft milestone PR) and zero open issues. Some PRs were green while others had failed checks, demonstrating why every item needs its own disposition and why a healthy queue is not defined as empty. These observations are examples only; implementation must recollect them with the locked provenance contract.
- Use stable row prefixes such as `GIT-BR-*`, `GIT-TAG-*`, `GIT-WT-*`, `GH-PR-*`, `GH-ISSUE-*`, and `REC-*` so later phases can cite exact evidence.
- A source that succeeds with zero items should say so explicitly; a source that fails should remain visibly unavailable.

</specifics>

<deferred>
## Deferred Ideas

- A recurring machine-readable repository-health database, JSON schema, generator pipeline, or CI-enforced inventory subsystem is deferred unless v1.38 demonstrates a repeatable mechanically detectable gap, consistent with FUTURE-04.
- A Phoenix/LiveView dashboard or consumer-facing Mix task is not warranted for this maintainer-only phase and remains outside the embedded-library surface.

</deferred>

---

*Phase: 138-Baseline Inventory & Evidence Taxonomy*
*Context gathered: 2026-08-28*
