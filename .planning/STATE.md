---
gsd_state_version: "1.0"
milestone: v1.38
milestone_name: Repository Baseline & Reconciliation
current_phase: 139
current_phase_name: Required Truth Reconciliation
current_plan: Verification refresh
status: Verification stale after Phase 138 closeout
stopped_at: Phase 139 implementation and UAT are complete; refresh its stale verification before moving to Phase 140
last_updated: "2026-09-25T21:57:06Z"
last_activity: 2026-09-25
last_activity_desc: Phase 138 complete; Phase 139 verification fingerprint needs refresh
state_head: 0ecf6ad8c0cce50920bbb22ef5ca2b4a7c49c976
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 47
  completed_plans: 47
  percent: 50
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** A Phoenix SaaS team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Current focus:** Phase 139 — Required Truth Reconciliation verification refresh

## Current Position

Phase: 139 — Required Truth Reconciliation
Current Plan: Verification refresh
Total Plans in Phase: 9/9 complete
Plan: Implementation and UAT are complete; refresh verification after Phase 138 closeout changed a covered artifact
Status: Verification stale; next command is `$gsd-verify-work 139`
Last activity: 2026-09-25 — Phase 138 complete; Phase 139 verification fingerprint needs refresh

Progress: [███░░░░░░░] 25%

## Accumulated Context

### Recent Sustaining Release: 1.5.0

- Release PR #93 merged the 1.5.0 bookkeeping at `02e74366`; release automation hardening #94 produced source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`.
- Canonical `main` CI run `33141161205` passed at that SHA; protected release run `33141484467` published and re-verified the exact tar (SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`).
- Supplemental OIDF run `33139876101` retained redacted, non-certifying suite-failure evidence; it is not a release gate or certification claim.

### Decisions

- v1.38 is an evidence-led maintenance baseline: inventory before mutation, bind readiness to the final exact SHA, and use existing repository controls.
- No protocol, host-seam, admin-surface, CI-platform, broad dependency, speculative refactor, destructive bulk-cleanup, or manual release-publication work belongs in this milestone.
- Release Please owns release bookkeeping; protected exact-ref publishing and manifest/checksum proof must remain intact.
- [Phase ?]: The collector permits only git fetch --prune --tags REMOTE as metadata mutation and records degraded evidence visibly.
- [Phase ?]: Git evidence IDs derive from kind plus canonical subject through git hash-object, never list position.
- [Phase ?]: GitHub PR and issue inventories use separate authenticated cursor queries with proposal-only rows.
- [Phase ?]: Maintained evidence uses an explicit source-family allowlist, archive summaries, and proposal-only REC rows.
- [Phase ?]: REC identity derives from canonical tracked paths and aggregates discovery-family references.
- [Phase ?]: Collector provenance snapshots before collector-owned artifacts; canonical ledger explicitly records evidence_base_sha.
- [Phase ?]: Ledger commit 3425f1d0 is the direct child of evidence base dcff5263 and changes only the canonical ledger.
- [Phase 138]: Only a complete and row-valid PR-plus-issue aggregate grants affirmative disposition authority.
- [Phase 138]: Usable rows from a complete sibling namespace remain visible as defer-only evidence when the aggregate is partial.
- [Phase 138]: GitHub renderers consume validated normalized JSON rows and never mutate aggregate collection status.
- [Phase 138]: Stable Git evidence identity accepts only a complete 40- or 64-character hexadecimal object digest.
- [Phase 138]: An identity failure suppresses only the unidentified row while making the exact domain and aggregate partial.
- [Phase 138]: Partial Git domains retain safely identified sibling rows but never render successful-zero evidence.
- [Phase 138]: Maintained selector output is buffered to collector-owned files so command exits and NUL-delimited paths remain separate and observable.
- [Phase 138]: REC identity continues to hash the exact normalized tracked path, while only sanitized display values cross TSV and Markdown boundaries.
- [Phase 138]: Maintained deduplication keys by stable REC ID rather than rendered subject text, preserving identity when redaction collapses display values.
- [Phase 138]: Treat the canonical ledger as an immutable snapshot anchored by a ledger-only child commit, then classify later bookkeeping instead of requiring the ledger to be the repository's final write. — This preserves evidence immutability while allowing exact, disclosed GSD lifecycle bookkeeping.
- [Phase 138]: Authorize post-snapshot movement only from exact ancestry, identity, subject, path, content, and external-receipt proof; all ambiguity requires refresh. — Fail-closed currentness prevents hostile near misses from being mistaken for harmless bookkeeping.
- [Phase 138]: Treat a gaps_found verification as superseded only when its exact four Phase 138 gap mappings have complete 138-07 through 138-10 summaries. — Supersession is bounded to the known verification artifact and cannot be inferred from loose prose.
- [Phase 138]: Anchor the canonical ledger to the clean pre-collection commit and publish it as that commit's ledger-only child. — Makes the evidence relation immutable and self-reference-safe.
- [Phase 138]: Bound currentness to the UTC evidence window and require the semantic classifier after every later lifecycle write. — Prevents bookkeeping from silently broadening the snapshot claim.
- [Phase 138]: Keep every inventory disposition proposal-only until its named revalidation and maintainer authority are satisfied. — Publication is evidence capture, not cleanup authority.
- [Phase 138]: Collect each pull request statusCheckRollup through a dedicated nested cursor query. — Nested completeness must be proven independently from outer pull-request pagination.
- [Phase 138]: Corroborate duplicate GitHub node IDs only on exact normalized agreement. — Contradictory decision-bearing copies cannot safely acquire disposition authority.
- [Phase 138]: Acquire the target lock before overwrite authorization, fetch, or snapshot capture so publication authority is always current.
- [Phase 138]: Require identical successful normalized porcelain-v2 projections while excluding only exact registered collector-owned paths.
- [Phase 138]: Maintained evidence stays as named JSON objects through validation, stable-ID aggregation, and deterministic sorting; Markdown encoding occurs only at the final field boundary.
- [Phase 138]: Tracked-marker exit 1 is complete-zero only with an empty buffer; exit 0 requires valid matched records, and every other or inconsistent result is unavailable.
- [Phase 138]: Valid Unicode is preserved, invalid path bytes are percent-escaped for display, and YAML uses JSON-compatible quoted scalars distinct from Markdown cell encoding.
- [Phase 138]: Normalize only authorized primary main/root-worktree advancement back to the immutable evidence base; compare every other topology receipt exactly.
- [Phase 138]: Authorize lifecycle bookkeeping through positive file, identity, structure, and old-to-new semantic validators rather than keyword denial.
- [Phase 138]: Apply one Phase 138-to-139 transition contract to committed, staged, unstaged, and mixed-index projections.
- [Phase 138]: Plan 138-16: Enumerate each active-record suffix as an explicit Git pathspec; Git does not expand brace alternatives.
- [Phase 138]: Plan 138-16: Classify active REVIEW and VERIFICATION authorities only through exact status plus document structure.
- [Phase 138]: Plan 138-17: Reject nonempty or malformed top-level GraphQL errors before accepting outer or nested response data.
- [Phase 138]: Plan 138-17: Apply contradiction gating identically to PR and issue namespaces while retaining validated siblings only as defer evidence.
- [Phase 138]: Plan 138-18: Require fetch, object-format-valid baseline refs, exact divergence grammar, and valid porcelain evidence for complete Git status.
- [Phase 138]: Plan 138-18: Bind publication to an identity-checked non-symlink regular target and a no-follow directory-descriptor rename.
- [Phase 138]: Plan 138-19: Resolve snapshot authority only after one repository-bound complete canonical frontmatter block validates every declared source fingerprint.
- [Phase 138]: Plan 138-19: Treat malformed porcelain-v2 branch metadata as unavailable currentness evidence even when git status exits successfully.
- [Phase 138]: Plan 138-19: Authorize lifecycle commits only when every changed companion satisfies its class-specific parent-to-child semantic contract.
- [Phase 138]: Plan 138-20: Derive maintained family receipts and archive accounting from one exclusion-filtered NUL path set.
- [Phase 138]: Plan 138-20: Preserve exact path identity while asserting every hostile displayed semantic field by stable REC ID.
- [Phase 138]: Plan 138-20: Verify JSON-compatible YAML scalars with repository-owned Elixir rather than a personal GSD path.
- [Phase 138]: Plan 138-21: Bind the refreshed canonical ledger to corrected evidence base c2313891 and preserve it as ledger-only commit 632af389.
- [Phase 138]: Plan 138-21: Treat repository identity as part of snapshot authority, including working-tree transition fixtures.
- [Phase 138]: Plan 138-21: Keep ledger dispositions proposal-only and rerun the production relation after lifecycle writes.
- [Phase 138]: Plan 138-22: Nested PR check evidence gains authority only when its single validated commit OID equals the captured outer headRefOid.
- [Phase 138]: Plan 138-22: Archive expansion and classification read the complete tracked blob while display excerpts remain independently bounded.
- [Phase 138]: Plan 138-22: Branch, tag, and worktree object identities must match the captured repository object format exactly.
- [Phase 138]: Archive action authority requires explicit markers; incidental historical prose and superseded review status remain summarized.
- [Phase 138]: GSD state.json is authorized in Phase 138 summary bookkeeping only when its contract-v1 Phase 138 entry is in_progress.
- [Phase 138]: Plan 138-24: GitHub PR object identity uses one exact 40-or-64 hexadecimal predicate across validation and proposal authority.
- [Phase 138]: Plan 138-24: Exact REVIEW/VERIFICATION structure and status control active lifecycle classification before incidental display prose.
- [Phase 138]: Plan 138-24: Archive expansion and classification share one structured action authority; conflicts remain ambiguous and partial.
- [Phase 138]: Free-form fix-now prose is not archive action authority; only anchored fix-now markers or existing structural action forms qualify. — Prevents terminal archived records from becoming ambiguous while preserving every explicit Plan 138-24 marker family.
- [Phase 138]: The canonical ledger is bound to evidence base 0d777d1a and ledger-only publication 15a556a9. — One-parent, one-path publication plus an unchanged blob makes the snapshot relation immutable and independently auditable.
- [Phase 138]: Plan 138-26: Worktree porcelain uses NUL field boundaries and validated JSON objects before final Markdown encoding.
- [Phase 138]: Plan 138-26: Relative output targets resolve once against the physical invocation directory.
- [Phase 138]: Plan 138-26: git, python3, and jq are preflighted before collection or relation observation.
- [Phase 138]: External receipt authority is derived only from current authenticated GitHub collection and current tracked maintained-source observation.
- [Phase 138]: Closeout summaries expose exactly one canonical bounded frontmatter object; body text never supplies authoritative metadata.
- [Phase 138]: ROADMAP and STATE closeout validators require the exact target-plan diff cardinality and reject all surplus matching-prefix rows.
- [Phase 138]: Plan 138-28: Canonical evidence identity and deduplication remain exact; credential detection runs only at the final display boundary.
- [Phase 138]: Plan 138-28: Opaque-secret detection requires a long mixed-case alphanumeric component and exempts exact Git object widths plus word-like public identifiers.
- [Phase 138]: Plan 138-28: Named provider, JWT, PEM, bearer, and keyword detection remains independent of the opaque fallback.
- [Phase 138]: Phase 138 evidence base is 37b08394fbcec49ed92d527a3bad583dedd7283d and publication 891fe796 is its ledger-only child.
- [Phase 138]: Authorize new Phase 138 STATE decisions only when one canonical bounded key-decisions scalar matches exactly; retain Plan 138-29 compatibility only for immutable commit c872cd23d4bee940ad34485d28de2791ee7f8245.
- [Phase 138]: Authorize the STATE performance row only when normalized duration, canonical task count, and summary-derived modified-file count all match the same bounded summary.
- [Phase 138]: Treat semantic versions and public HTTPS URLs as safe only when every 32+ character mixed-case alphanumeric component independently passes the closed public-identifier allowlist.
- [Phase 138]: Trust post-transition state only when the host-emitted writer, transformation, hooks, before/after identities, current worktree digest, and lifecycle semantics all agree. — Live hashes alone cannot recreate missing begin-time or seal-time authority.
- [Phase 138]: Expose exactly one synchronous command family whose only accepted raw argv select pre-verify or post-transition for numeric Phase 138. — A closed command surface keeps both lifecycle boundaries bounded and auditable.
- [Phase 139]: Exact acceptance derives authority only from equality with synchronized main and stable workflow identities. — Caller input and recency cannot establish the one-SHA join required by CI-06 and CI-07.
- [Phase 139]: Exact acceptance receipts expose only allowlisted workflow scalars, bounded dispositions, and a non-certifying supplemental OIDF classification. — This preserves redaction while making the intentional Release no-publish shape and WARN handling independently auditable.
- [Phase 139]: Remove the three demonstrated dead shell states rather than inventing new output or lifecycle state merely to consume them.
- [Phase 139]: Compose every active proof phase fragment from the existing baseline/next attributes and commit prefix so generated fixture bytes remain authoritative while source labels stay maintainable.
- [Phase 139]: Static source proof is not a live release claim: it protects job eligibility and ordering, while the later exact-main plan remains responsible for observed workflow outcomes.
- [Phase 139]: The immutable-reference predicate rejects multiple @ separators as well as mutable suffixes, preventing a tag or branch prefix from hiding before a full SHA.
- [Phase 139]: Maintained release prose is a checked projection of executable workflow authority: push maintains Release Please state, while only protected workflow_dispatch may publish an exact lowercase current-main commit after matching CI proof.
- [Phase 139]: v1.38/Phase 139 is active planning truth while v1.37/Lockspire 1.5.0 remains latest shipped history; coherence preserves both truth classes without rewriting either one.
- [Phase 139]: Keep the Phase 138 inventory schema immutable while adding phase-aware review capture and distinct Phase 139 preverify/posttransition relation modes.
- [Phase 139]: Authorize final local-main and origin-main movement only as an exact synchronized fast-forward pair to the host-sealed candidate, with every other topology and ledger byte held constant.
- [Phase 139]: Final main authority comes only from the pending host-sealed candidate, ancestor proofs, compare-and-swap local update, and a normal exact-ref push followed by re-fetch.
- [Phase 139]: The durable acceptance receipt joins current exact-SHA proof with separately corroborated immutable 1.5.0 history while supplemental OIDF remains non-certifying.
- [Phase 139]: Keep one installed command family and exactly two halt-capable hooks; phase-aware fixed dispatch supplies timing without broadening the public surface.
- [Phase 139]: Other numeric phases return inert success without spawning so Phase 139 finalization authority cannot leak into later work.
- [Phase 139]: Host pending state clears only after sealed hook identity and post-transition acceptance succeed; recovery never replays completed plan or preverify work.
- [Phase 138]: Expose existing production-CLI proof through structured SUMMARY coverage instead of duplicating the subprocess-heavy repository-hygiene suite. — The exact behaviors already have passing executable proof, so metadata repair preserves signal without adding runtime.
- [Phase 138]: Run only the self-contained finalizer router contract in release-hygiene CI; keep GSD-dependent lifecycle and authenticated mutable-source proof at execute/verify boundaries. — This is the cheapest durable recurring boundary and avoids unsafe credentials or mutable-source prerequisites in pull-request CI.
- [Phase 138]: Compose Phase 139 fixture labels from semantic phase attributes so repository proof remains phase-neutral without weakening assertions. — The user-authorized repair restores the existing active proof-label hygiene contract while preserving generated fixture semantics.
- [Phase 139]: Keep Phase 139 verification gaps and external acceptance separate from repository-owned proof mapping; requirements stay pending until synchronized live receipt evidence exists.
- [Operating default]: Shift verification left into the earliest reliable automated layer; add repeatable integration, end-to-end, smoke, and seam checks to required CI when they provide recurring regression value. Treat passing automated evidence as satisfying UAT and hand off only subjective judgment or a truly unreachable external boundary, with its machine-owned lifecycle gate named.

### Pending Todos

- Reconcile required CI, release, hygiene, and planning truth against the immutable Phase 138 inventory before taking any bounded action.

### Blockers/Concerns

- Phase 139 must revalidate ledger `b8b9ad75` at each named authority boundary; the inventory remains proposal-only and does not authorize cleanup by itself.
- Lifecycle ordering resolution (2026-09-24): Phase 139 now verifies repository-owned acceptance contracts and local gates. CI-06 and CI-07 are mapped to Phase 140 and remain pending until the existing blocking `plan:pre` hook validates synchronized refs, canonical same-SHA CI/Release evidence, and the durable receipt before any Phase 140 planning. No GSD runtime patch or live acceptance claim is involved.
- Supplemental OIDF findings remain future bounded conformance work unless a reproducible repository regression warrants a narrowly scoped correction.
- 139-09 Task 1 historical blocker: live parity was initially blocked on GSD 1.10.0. Resolved 2026-09-24 after the installed runtime reached 1.14.0; the capability is active and fixture-backed live hook parity passed 16/16. The exact-SHA receipt is the mandatory Phase 140 pre-planning gate, not an active Phase 139 blocker.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260924-mhp | Classify active UAT lifecycle records from structured status and document shape | 2026-09-24 | 37a1d62c | [260924-mhp-classify-active-uat-records-in-the-phase](./quick/260924-mhp-classify-active-uat-records-in-the-phase/) |

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Conformance | Supplemental OIDF/FAPI findings | Future bounded conformance milestone; non-certifying | v1.38 start |
| Repository automation | Additional drift checks | Only if a repeatable repository-owned gap is demonstrated | v1.38 start |

## Session Continuity

Last session: 2026-09-25T21:11:55.718Z
Stopped at: Phase 138 complete, ready to plan Phase 139
Resume file: .planning/phases/138-baseline-inventory-evidence-taxonomy/138-38-PLAN.md
Resume instruction: User prefers automatically following recommended GSD options; pause for destructive, one-way, or explicitly approval-gated choices.

## Performance Metrics

The original 36 Phase 138 plans and all nine Phase 139 plans have summaries. Phase 138 Plan 138-37 is complete; Plan 138-38 awaits explicit maintainer outcomes for 98 pending claims. G-138-98 remains open. Phase 139 verification is stale. Phase 140 planning remains gated on the exact-SHA acceptance receipt.
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 138 P01 | 600 | 2 tasks | 3 files |
| Phase 138 P02 | 1920 | 2 tasks | 3 files |
| Phase 138 P03 | 900 | 2 tasks | 4 files |
| Phase 138 P05 | 1200 | 2 tasks | 2 files |
| Phase 138 P06 | 1140 | 2 tasks | 3 files |
| Phase 138 P07 | 526 | 2 tasks | 3 files |
| Phase 138 P08 | 408 | 2 tasks | 3 files |
| Phase 138 P09 | 880 | 2 tasks | 3 files |
| Phase 138 P10 | 35 min | 3 tasks | 3 files |
| Phase 138 P11 | 18min | 1 tasks | 1 files |
| Phase 138 P12 | 18min | 2 tasks | 3 files |
| Phase 138 P13 | 12min | 2 tasks | 3 files |
| Phase 138 P14 | 27min | 3 tasks | 4 files |
| Phase 138 P15 | 31min | 2 tasks | 3 files |
| Phase 138 P16 | 55 min | 2 tasks | 4 files |
| Phase 138 P17 | 780 | 2 tasks | 4 files |
| Phase 138 P18 | 1020 | 2 tasks | 3 files |
| Phase 138 P19 | 30min | 3 tasks | 3 files |
| Phase 138 P20 | 11min | 3 tasks | 3 files |
| Phase 138 P21 | 2460 | 2 tasks | 5 files |
| Phase 138 P22 | 25min | 3 tasks | 4 files |
| Phase 138 P23 | 2h38m | 2 tasks | 5 files |
| Phase 138 P24 | 38min | 3 tasks | 4 files |
| Phase 138 P25 | 81min | 2 tasks | 4 files |
| Phase 138 P26 | 1h 8m | 2 tasks | 3 files |
| Phase 138 P27 | 45min | 2 tasks | 3 files |
| Phase 138 P28 | 1h 53m | 2 tasks | 3 files |
| Phase 138 P29 | 1h 40m | 2 tasks | 2 files |
| Phase 138 P30 | 30 min | 2 tasks | 3 files |
| Phase 138 P31 | 33 min | 2 tasks | 2 files |
| Phase 138 P32 | 20 min | 2 tasks | 5 files |
| Phase 138 P33 | 15 min | 2 tasks | 5 files |
| Phase 139 P01 | 41 min | 2 tasks | 3 files |
| Phase 139 P02 | 26 min | 2 tasks | 3 files |
| Phase 139 P03 | 36 min | 2 tasks | 2 files |
| Phase 139 P04 | 7 min | 2 tasks | 5 files |
| Phase 139 P05 | 37 min | 2 tasks | 5 files |
| Phase 139 P06 | 13 min | 2 tasks | 3 files |
| Phase 139 P07 | 7 min | 2 tasks | 6 files |
| Phase 138 P34 | 53 min | 3 tasks | 12 files |
| Phase 139 P08 | 32min | 2 tasks | 6 files |
| Phase 138 P37 | 17 min | 3 tasks | 5 files |
| Phase 138 P38 | 8 min | 2 tasks | 3 files |
