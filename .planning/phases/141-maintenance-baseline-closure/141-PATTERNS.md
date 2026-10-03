# Phase 141: Maintenance-Baseline Closure - Pattern Map

**Mapped:** 2026-10-02
**Files analyzed:** 7 planned documentation deliverables
**Analogs found:** 7 / 7 (documentation patterns; no application-code analogs)

Phase 141 is a documentation and planning-state closeout. No Phoenix, Plug, Ecto, LiveView, UI, API, test, or runtime source files are in scope. The files below are derived from CONTEXT.md and RESEARCH.md: one canonical baseline report and the six planning records explicitly named for reconciliation.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/141-maintenance-baseline-closure/141-BASELINE.md` (new; dated record content) | documentation / evidence index | evidence-to-summary transform; links to immutable receipts and external sources | `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` | role-match; analogous dated evidence artifact, broader inventory than this concise handoff |
| `.planning/PROJECT.md` | project configuration / status documentation | reconciliation of milestone and release facts | `.planning/PROJECT.md` current structure; `.planning/STATE.md` release evidence block | role-match |
| `.planning/ROADMAP.md` | roadmap documentation | phase/milestone status transition | `.planning/ROADMAP.md` existing milestone and phase rows | exact structural match |
| `.planning/REQUIREMENTS.md` | requirements documentation | requirement status and evidence-reference update | `.planning/REQUIREMENTS.md` BASE-04/05 rows | exact structural match |
| `.planning/STATE.md` | workflow state / handoff documentation | state transition and next-action handoff | `.planning/phases/140-bounded-operational-loose-end-triage/140-HANDOFF.md` | role-match; handoff prose format, while STATE is canonical GSD state |
| `.planning/MILESTONES.md` | milestone archive documentation | milestone summary and evidence linking | `.planning/MILESTONES.md` v1.37 entry | exact structural match |
| `.planning/RELEASE-TRAIN.md` | maintainer runbook / release policy documentation | current release truth plus next-action procedure | `.planning/RELEASE-TRAIN.md` current baseline and next-cut sections | exact structural match |

## Pattern Assignments

### `.planning/phases/141-maintenance-baseline-closure/141-BASELINE.md` (documentation / evidence index, evidence-to-summary)

**Analog:** `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md`

Use the evidence artifact's explicit snapshot boundary and provenance fields, but keep this deliverable a concise index rather than copying its inventory. The dated artifact identifies its evidence base and observation window before presenting rows:

**Provenance and currentness pattern** (`baseline-inventory-2026-08-28.md`, lines 22-35):

```markdown
# Git baseline evidence receipt

Observed. Revalidation required before action. This receipt proposes no cleanup.

## Collection provenance

- Collection window: `2026-09-26T15:33:35Z` to `2026-09-26T15:34:01Z`
- Snapshot boundary: bounded as of `2026-09-26T15:33:35Z`; immutable refs and normalized source receipts are rechecked immediately before atomic publication.
- Completeness: `complete`
- Limitation: None. Source receipt is complete.
```

**Disposition row pattern** (`140-DISPOSITIONS.md`, lines 75-77):

```markdown
| Stable ID / source-native ID | Exact target and observed identity | Finding disposition | Domain-native state / proposal | Evidence and rationale | Next proof or trigger | Proposed / executed |
| --- | --- | --- | --- | --- | --- | --- |
| GIT-BR-87e9639dca0d | `refs/heads/agent-140-01`; observed SHA `4738b0d550e0435c3fac5dd0d1b926f7317cf92a` | defer-with-trigger | lifecycle=active; inventory proposal=defer | ... | Before any change, re-query exact ref/OID, owner, ancestry, recoverability, dirty-worktree protection, and release linkage. | proposed; not executed |
```

For 141, identify the accepted **source SHA** separately from the later report/planning **commit SHA**. Include observation time/currentness, local exact-SHA gate receipt, canonical CI run and required jobs, Release no-publish graph, public release chain, and Phase 140 disposition links. Preserve existing evidence with direct links; do not duplicate raw logs, confidential receipt content, or the entire disposition inventory. Use explicit statuses and dates in text, not color or icons. Do not fill in an accepted SHA until Phase 140 terminal acceptance supplies it.

### `.planning/PROJECT.md` (project status documentation, reconciliation)

**Analog:** `.planning/PROJECT.md` current structure; use `.planning/STATE.md` lines 46-50 for how dated release evidence is stated.

Preserve the document's stable project framing and update only milestone/current-state claims supported by the completed baseline. The release evidence block uses version, source SHA, CI run, protected run, checksum, and supplemental-evidence caveat as separate facts (`STATE.md`, lines 46-50):

```markdown
### Recent Sustaining Release: 1.5.0

- Release PR #93 merged the 1.5.0 bookkeeping at `02e74366`; release automation hardening #94 produced source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`.
- Canonical `main` CI run `33141161205` passed at that SHA; protected release run `33141484467` published and re-verified the exact tar (SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`).
- Supplemental OIDF run `33139876101` retained redacted, non-certifying suite-failure evidence; it is not a release gate or certification claim.
```

At closure revalidate each mutable public-release claim, then reconcile explanatory prose. Keep package publication and GSD milestone completion distinct. Do not edit Release Please-owned version metadata, changelog, tags, or publication state.

### `.planning/ROADMAP.md` (roadmap documentation, phase/milestone status)

**Analog:** `.planning/ROADMAP.md`, lines 3-15.

The top-level milestone row and phase checklist communicate lifecycle state compactly. Update the v1.38 milestone row and Phase 140/141 rows only after their evidence gates and closeout agree; match the existing wording/links and retain the distinction between milestone completion and package publication:

```markdown
## Milestones

- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131-137 (shipped 2026-08-28 as Lockspire 1.5.0)
- 🚧 **v1.38 Repository Baseline & Reconciliation** — Phases 138-141 (planned)

## Phases

- [x] **Phase 138: Baseline Inventory & Evidence Taxonomy** - ...
- [ ] **Phase 140: Bounded Operational Loose-End Triage** - ...
- [ ] **Phase 141: Maintenance-Baseline Closure** - ...
```

### `.planning/REQUIREMENTS.md` (requirements documentation, status/evidence update)

**Analog:** `.planning/REQUIREMENTS.md`, lines 47-50.

Use the existing requirement ID, checkbox, concise user-capability statement, and evidence-bearing description style. Mark BASE-04 and BASE-05 complete only when the terminal evidence and synchronized GSD records actually satisfy them. Preserve exact SHAs/source links in the baseline and use a compact pointer here rather than pasting duplicate receipts.

```markdown
### Baseline Closure

- [ ] **BASE-04**: Maintainer can inspect a dated baseline record tying final Git state, local gates, required workflow runs, release evidence, loose-end dispositions, and explicit deferrals to exact SHAs and sources.
- [ ] **BASE-05**: Maintainer can finish v1.38 with coherent GSD state and an explicit return to Lockspire's sustaining GA release train.
```

### `.planning/STATE.md` (workflow state / handoff, state transition)

**Analog:** `.planning/phases/140-bounded-operational-loose-end-triage/140-HANDOFF.md`, especially lines 6-25.

The phase handoff leads with an updated date, next command, position, and a short actionable current-position section, then records evidence limits and authority boundaries. Use that orientation in the canonical GSD state update: identify completed phase/milestone, exact current/report SHAs as applicable, currentness, and the supported next sustaining-train action. Avoid copying obsolete predecessor instructions. The handoff explicitly says an earlier receipt does not certify later commits (`140-HANDOFF.md`, lines 20-25):

```markdown
## Durable Phase 140 context

- Phase 139 is the most recently completed phase. Phase 140 remains in progress. Phase 141 follows Phase 140 verification and completion...
- The Phase 140 `plan:pre` entry gate passed against the Phase 139 acceptance receipt for exact SHA `...`. That receipt does not certify later commits.
- Local planning commits are not pushed. No earlier SHA approval authorizes a new push...
```

### `.planning/MILESTONES.md` (milestone archive documentation, summary/evidence)

**Analog:** `.planning/MILESTONES.md`, lines 9-30 (v1.37 entry).

Follow the established completed-milestone structure: delivered summary, phase/plan/requirement totals where known, key accomplishments, production proof, audit/verification pointer, and archive references. For v1.38, state that this is a maintenance-baseline closeout, include exact-source acceptance/report-commit distinction where relevant, and explicitly say milestone completion does not mean a new package was published. Do not infer package version from repository metadata.

```markdown
## v1.37 Prime-Time Readiness Ratchet (Shipped: 2026-08-28)

**Delivered:** ...
**Phases completed:** **7** (**131-137**), **58** plans, **127** tasks, **36** requirements closed.
...
**Production proof:** canonical CI run `33141161205`; protected release run `33141484467`; released source `...`; public package `1.5.0`; tar SHA-256 `...`.
**Archives:** ...
```

### `.planning/RELEASE-TRAIN.md` (maintainer runbook / policy, currentness reconciliation)

**Analog:** `.planning/RELEASE-TRAIN.md`, lines 7-27 and 46-52.

Retain the concise current baseline and normal-train action criteria. Replace conflicting explanatory latest-release claims only after rechecking Hex and GitHub evidence; keep the source metadata/changelog under Release Please ownership. Distinguish a successful push-triggered no-publish run from a protected publication run and package availability. Preserve explicit conditions for the next patch cut:

```markdown
## Current Baseline

- Latest released version: `...`
- Protected publish proof: GitHub Actions ... source SHA ... after canonical exact-SHA CI run ... passed.
- Artifact truth: ... SHA-256 ...
- GitHub release truth: ...

## Next Cut Condition

Cut the next patch release when there is at least one merged patch-eligible change on `main`, canonical CI is green for the exact current `origin/main` commit, the repo hygiene gate reports no `BLOCK`, and release truth still points to `docs/supported-surface.md` as the canonical contract.
```

## Shared Patterns

### Evidence identity and freshness

**Sources:** `140-ACCEPTANCE.md` lines 29-38 and 56-77; `141-CONTEXT.md` decisions D-01 through D-05.
**Apply to:** Baseline record and every GSD document making acceptance or publication claims.

- Bind every gate claim to one full immutable source SHA and cite exact workflow run IDs/jobs.
- Keep the source SHA whose tree was accepted distinct from the commit SHA containing this report and planning updates.
- Revalidate mutable refs and hosted release state at the closure boundary; label discussion-time identities historical until refreshed.
- A Release no-publish graph is not proof of package publication. Verify public package and protected publication evidence independently.
- An unavailable or failed observation stays explicit and pending; absence of evidence is not evidence of absence.

### Maintainer-facing documentation UX

**Sources:** `140-DISPOSITIONS.md` lines 13-21 and 75-77; `140-HANDOFF.md` lines 6-25; D-07.
**Apply to:** New baseline and status/handoff prose.

Lead with the decision/currentness and the next supported action. Use semantic headings, explicit textual statuses, clear dates, full SHA labels, direct evidence links, and concrete recheck triggers. Keep resolved, historical, deferred-with-trigger, and out-of-scope work distinguishable. Do not make meaning depend on color, glyphs, internal implementation detail, or an empty queue.

### Existing acceptance seam and authority boundary

**Source:** `scripts/maintainer/repo_hygiene_check.sh` lines 17-40, 63-99.
**Apply to:** Evidence references and plan actions that consume the final Phase 140 acceptance.

```text
Usage: repo_hygiene_check.sh --accept-sha SHA [--wait-seconds SECONDS]
                             [--warn-disposition LABEL=DISPOSITION] [--format json]
--accept-sha SHA       Prove local and GitHub acceptance for one synchronized main SHA.
--warn-disposition     Record one bounded disposition for an exact-mode WARN label.
--format json          Emit the allowlisted exact-acceptance JSON receipt.
```

Reuse this existing receipt; do not add another script, parser, or acceptance database. Phase 141 consumes Phase 140's completed terminal receipt and must not invent or run a replacement path. Evidence does not grant authority to push, dispatch, publish, edit protected files, or mutate refs.

## No Analog Found

No application/runtime files are planned, so there are no Elixir, Phoenix, Plug, Ecto, UI, or test analogs to map. There is no close precedent for a single final baseline handoff that combines terminal exact-SHA acceptance, publication truth, dispositions, and milestone closure; use the narrower ledger, Phase 140 disposition/handoff, and release-train patterns above without copying their irrelevant inventory or execution detail.

## Metadata

**Analog search scope:** `.planning/` current milestone/state/release records; Phase 138 dated baseline; Phase 140 handoff, disposition register, and acceptance contract; `scripts/maintainer/repo_hygiene_check.sh`.
**Files scanned:** 10 tracked candidate source documents; 7 selected analog/reference files.
**Tracked-source gate:** All named repository analog paths were confirmed tracked with `git ls-files`.
**Pattern extraction date:** 2026-10-02
