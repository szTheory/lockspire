# Phase 141: Maintenance-Baseline Closure - Context

**Gathered:** 2026-10-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a durable, dated handoff for the final v1.38 maintenance baseline, reconcile GSD project, roadmap, requirements, state, and milestone truth, and identify the next action on Lockspire's sustaining GA release train. Phase 141 depends on completed Phase 140 terminal acceptance. It records evidence and closes planning truth; it does not publish a release, change release-owned version metadata, add protocol or host-app capabilities, or create product UI.

</domain>

<decisions>
## Implementation Decisions

### Terminal Acceptance and Evidence Identity
- **D-01:** Base the final baseline on Phase 140's post-summary acceptance for one synchronized full `main` SHA. Refresh and revalidate the terminal evidence at closure; predecessor receipts, entry-gate receipts, separate green runs, and local-only gates do not transfer. Phase 140 acceptance is still marked pending in the evidence reviewed for this discussion, so Phase 141 must not invent or pre-fill its final accepted SHA.
- **D-02:** Create one canonical dated Markdown baseline record in the Phase 141 directory. Connect the accepted source SHA to the exact local `mix ci` and hygiene results, required canonical CI jobs, successful Release no-publish graph, release evidence, Phase 140 dispositions, and explicit deferrals using full immutable SHAs and direct source links. Link to detailed Phase 140 artifacts instead of duplicating raw logs or the complete inventory; preserve redaction and existing historical evidence.
- **D-03:** Distinguish the SHA whose source tree was accepted from the commit that contains the final Phase 141 report and planning updates whenever they differ. State which evidence applies to which SHA. If a claim is made about a later tree, require matching proof for that tree; do not imply that a report's later documentation commit was covered by an earlier same-SHA receipt.

### Planning Completion and Published Release Truth
- **D-04:** Mark v1.38 and Phase 141 complete only after the evidence handoff and synchronized GSD records agree on completion and the next sustaining GA action. Milestone completion is not package publication. Leave version bumps, changelog release bookkeeping, tag creation, GitHub releases, and Hex publication to their existing release owners.
- **D-05:** At discussion time, authoritative Hex and GitHub evidence identifies `1.5.0` as the latest public release: published source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`, canonical CI run `33141161205`, protected publication run `33141484467`, and package checksum `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`. Repository metadata and prose conflict: `mix.exs`, `.release-please-manifest.json`, `CHANGELOG.md`, and `.planning/RELEASE-TRAIN.md` name `1.5.1`, while `.planning/PROJECT.md` and `.planning/MILESTONES.md` say public `1.5.0`; no public Hex release or GitHub tag for `1.5.1` was found. Revalidate public release and protected-run evidence at Phase 141 closure, then reconcile explanatory planning prose to that evidence. Do not treat source metadata as publication proof or manually rewrite release-owned files.

### Disposition and Deferral Truth
- **D-06:** Carry Phase 140's source-linked terminal dispositions and recheck triggers into the final handoff. Keep resolved, historical, deferred-with-trigger, and out-of-scope work distinguishable. A healthy baseline does not require an empty queue; deferral is not completion. Keep supplemental OIDF/FAPI evidence redacted, supplemental, and non-certifying, with future conformance work explicitly outside v1.38.

### Maintainer Journey and Scope
- **D-07:** Optimize the record for a release steward or future maintainer returning after a gap. They need to determine what was accepted, what proves it, what remains deferred, and the next supported action from the repository and its linked GitHub evidence. Use concise semantic headings, direct links, explicit text statuses, clear dates and SHA labels, and calm factual wording; meaning must not depend on color, icons, or backend knowledge.
- **D-08:** Keep this a repository documentation and planning-state phase. Do not add Phoenix UI, a public API, a Mix task, Ecto persistence, an admin design-system change, a dashboard, or a new maintenance framework. Use the current root `brandbook/` as the visual source if an in-scope visual product decision ever arises; Phase 141 itself has no UI or graphic-design work. Apply the relevant release-engineering and maintainer-documentation guidance from `prompts/`; do not pull unrelated protocol, host-seam, or LiveView design choices into this phase.

### the agent's Discretion
The user confirmed the recommendation set without corrections. Planning may choose the baseline filename, concise Markdown table layout, and ordering of evidence sections. It may group references for readability, but must preserve the decision set above, currentness labels, exact source identities, deferral triggers, release ownership, and accessible text-only status meaning.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, acceptance, and prior decisions
- `AGENTS.md` — Embedded-library boundary, project scope, and security defaults.
- `.planning/PROJECT.md` — v1.38 goal, project truth, and verification posture; reconcile stale release claims with evidence.
- `.planning/REQUIREMENTS.md` — BASE-04 and BASE-05 acceptance criteria.
- `.planning/ROADMAP.md` — Phase 141 boundary and success criteria.
- `.planning/STATE.md` — Current workflow state and predecessor handoff.
- `.planning/METHODOLOGY.md` — Evidence-first, one-shot recommendations and high-threshold escalation.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-CONTEXT.md` — Immutable snapshot, evidence taxonomy, source completeness, and maintainer-document UX.
- `.planning/phases/139-required-truth-reconciliation/139-CONTEXT.md` — Exact-SHA acceptance, release ownership, historical release evidence, and supplemental conformance boundary.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-CONTEXT.md` — Approved Phase 140 disposition and final-acceptance decisions.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-HANDOFF.md` — Current execution status and transition constraints.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md` — Required final same-SHA local, CI, Release no-publish, and hygiene evidence.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md` — Phase 140 goal-backward verification and remaining blockers.
- `.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md` — Source-linked loose-end outcomes and triggers to carry forward.

### Existing release and maintenance controls
- `.planning/RELEASE-TRAIN.md` — Sustaining train, supported publication lane, and current release claims needing evidence-based reconciliation.
- `.planning/DEVELOPMENT-TRAIN.md` — Boundary between sustaining work and feature milestones.
- `.planning/REPO-HYGIENE-CHECKLIST.md` — Exact-SHA acceptance and readiness expectations.
- `scripts/maintainer/repo_hygiene_check.sh` — Existing exact-SHA acceptance and hygiene interface; reuse it.
- `scripts/maintainer/finalize_phase_139_acceptance.sh` — Existing Phase 139 acceptance lifecycle; preserve its ownership and historical evidence.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Contract coverage for current repository hygiene behavior.
- `test/lockspire/release_ci_evidence_contract_test.exs` — Exact-SHA required workflow evidence contract.
- `.github/workflows/ci.yml` and `.github/workflows/release.yml` — Canonical CI and protected/no-publish release ownership.
- `.planning/MILESTONES.md`, `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` — Current milestone and release metadata to reconcile without mistaking metadata for publication.

### Applicable prompt and design references
- `prompts/README.md` — Prompt corpus ownership and relevance guidance.
- `prompts/lockspire-release-engineering-and-ci.md` — Release automation ownership, contributor DX, and exact artifact/evidence patterns.
- `prompts/lockspire-release-readiness-and-conformance.md` — Release gates, documentation-as-contract, and non-certifying conformance boundaries.
- `prompts/lockspire-elixir-oss-library-practices.md` — Apply only its packaging, documentation, compatibility, and public-release guidance; no Elixir API design is in scope.
- `brandbook/README.md` and `brandbook/notes/accessibility-checks.md` — Current root brandbook and accessibility reference if visual product guidance becomes relevant; the older `prompts/lockspire_brand_book.md` is not the current design source.

### Current authoritative public-release evidence (revalidate at closure)
- `https://hex.pm/api/packages/lockspire` — Current public package version listing.
- `https://hex.pm/api/packages/lockspire/releases/1.5.0` and `https://hex.pm/api/packages/lockspire/releases/1.5.1` — Exact public release records; the latter returned 404 during this discussion.
- `https://github.com/szTheory/lockspire/releases/tag/lockspire-v1.5.0` — Public release and tag source identity.
- `https://github.com/szTheory/lockspire/actions/runs/33141161205` and `https://github.com/szTheory/lockspire/actions/runs/33141484467` — Matching canonical CI and protected publication evidence for 1.5.0.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/maintainer/repo_hygiene_check.sh --accept-sha <sha> --format json` already joins synchronized refs, local gates, required workflow evidence, and explicit hygiene-WARN dispositions. Use its accepted receipt rather than inventing another acceptance route.
- `140-ACCEPTANCE.md` and `140-DISPOSITIONS.md` already hold the source-native terminal proof contract and bounded finding outcomes. Phase 141 should reference their final verified revisions.
- `.planning/RELEASE-TRAIN.md` and `.planning/DEVELOPMENT-TRAIN.md` define the existing sustaining and feature lanes; the handoff can point to these as the next-action contract.

### Established Patterns
- Immutable historical receipts and mutable current state are distinct; revalidate mutable refs and hosted-service evidence at the decision boundary.
- An accepted local or predecessor SHA cannot certify a later completion-record commit. Evidence must name its exact source SHA and retain its meaning when records advance.
- GSD planning truth and latest shipped package truth are separate. Release Please and the protected exact-ref workflow own version bookkeeping and publication.
- The maintainer-facing interaction is terminal plus accessible Markdown, with explicit status wording and no color-only meaning; this is a documentation UX task, not a Phoenix UI task.

### Integration Points
- Join the final Phase 140 acceptance receipt, local hygiene/CI results, canonical GitHub CI and Release no-publish runs, protected published-release proof, and the Phase 140 disposition register in one Phase 141 baseline record.
- Reconcile `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, and `.planning/RELEASE-TRAIN.md` from their appropriate evidence sources; preserve release automation ownership.
- Record the next action from the sustaining GA train only after the final acceptance and current release truth have been revalidated.

</code_context>

<specifics>
## Specific Ideas

- Who: release steward or future maintainer returning after a gap. What: establish accepted state, evidence, remaining deferrals, and the next safe action. Where: the repository, its planning records, and linked GitHub/Hex sources. When: after Phase 140 terminal acceptance and all Phase 141 state writes are accounted for. Why: close v1.38 without implying that every deferred issue was resolved or a package was published.
- Distinguish the accepted source SHA from the containing report commit SHA if they differ; avoid a circular claim that evidence covers a commit created after that evidence.
- Current public release evidence supports Lockspire 1.5.0, not 1.5.1. The 1.5.1 values in source metadata/changelog do not prove publication; recheck at closure and reconcile only explanatory claims.
- External comparison was limited to authoritative Hex/GitHub publication records because Phase 141 does not change Elixir/Phoenix APIs, protocol behavior, or product UI. The applicable Elixir OSS lessons are release ownership, executable gates, durable docs, and contributor/maintainer clarity as captured in the local prompt corpus.

</specifics>

<deferred>
## Deferred Ideas

- Supplemental OIDF/FAPI remediation remains future bounded conformance work unless Phase 140's final evidence demonstrates a specific in-scope regression.
- Protocol, host-seam, admin UI, design-system, public API, persistence, dashboard, broad dependency, and new maintenance-framework work remain outside Phase 141.
- Do not publish 1.5.1, dispatch a protected release, or edit Release Please-owned version/changelog metadata as part of baseline closure. Any future publication follows the existing protected release train.
- No additional ecosystem or UI research is required for this documentation-and-evidence phase; revisit those lenses when a phase contains an API, runtime, or user-interface decision.

</deferred>

---

*Phase: 141-maintenance-baseline-closure*
*Context gathered: 2026-10-02*
