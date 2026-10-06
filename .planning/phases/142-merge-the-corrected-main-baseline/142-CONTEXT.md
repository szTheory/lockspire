# Phase 142: Merge the Corrected Main Baseline - Context

**Gathered:** 2026-10-06 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Merge the reviewed Phase 141 correction through the normal PR path so `main` truthfully identifies Lockspire 1.5.0 as the latest public package until public proof establishes 1.5.1. Then establish release readiness for the exact current `main` commit using matching canonical CI and repository-hygiene evidence. Phase 142 stops before package publication; protected publication and public artifact verification belong to Phase 143. This phase does not change OAuth/OIDC behavior, runtime APIs, the host integration seam, operator UI, or the release system's ownership boundaries.

</domain>

<decisions>
## Implementation Decisions

### Reviewed merge and release truth
- **D-01:** Merge the Phase 141 correction through the normal reviewed PR path. Keep 1.5.0 identified as the latest public package until current public evidence proves 1.5.1 was published. Release automation continues to own version and changelog bookkeeping, tag/release creation, and package publication; source metadata, a merged PR, green CI, or a no-publish run is not public-package proof.
- **D-02:** Phase 142 ends with an exact-main readiness handoff. It does not dispatch or perform package publication. Phase 143 owns protected publication after Phase 142's gates pass.

### Exact-main readiness
- **D-03:** Prove readiness only after the correction is merged: refresh `origin/main`, require local `main` and `origin/main` to identify the same full commit SHA, and require canonical CI to pass for that exact SHA. Do not reuse pre-merge CI or Phase 140's earlier accepted SHA as proof for this commit.
- **D-04:** Run the maintained repository-hygiene check for that same SHA. There must be no `BLOCK`; every `WARN` needs one explicit recorded disposition. Use the existing `--accept-sha` receipt only when its own checks and output establish the required evidence; do not claim the full receipt passed if a prerequisite is missing. Keep OIDF/FAPI supplemental results non-certifying and outside the release gate.
- **D-05:** Before merging, inspect the live Release Please PR and workflow state. If merging the correction could cause the automation to publish 1.5.1 before Phase 142's readiness evidence is complete, stop and resolve that timing boundary before proceeding. Do not infer live PR or workflow state from repository files.

### Maintainer record and shift-left check
- **D-06:** Correct the Phase 141 baseline link in `.planning/RELEASE-TRAIN.md` to its archived path: `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md`.
- **D-07:** Add a small automated contract in the existing release-hygiene test area that checks local links in `.planning/RELEASE-TRAIN.md` resolve. Keep it narrow to this maintained record; do not introduce a repository-wide Markdown-link framework. This turns the observed broken baseline link into a CI-detectable regression.
- **D-08:** Do not add manual UAT for properties proved by exact-SHA CI and repository hygiene. The normal PR review and authorization to perform consequential GitHub actions remain separate from verification evidence.

### the agent's Discretion
- Choose the filename and concise layout for Phase 142's durable result record. It should record the exact accepted SHA, matching CI evidence, hygiene summary, each warning disposition, current public-release truth, and the Phase 143 boundary without copying raw logs.
- Reuse the existing workflow and contract-test structure. If a required live check is unavailable or contradicts the record, stop with the specific missing evidence rather than assuming success.
- No Elixir API, Plug/Phoenix/Ecto, UI, or brandbook decision applies to this repository-maintenance phase. The local release process and prompt corpus provide enough guidance; no broad ecosystem comparison is needed.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, requirements, and standing decisions
- `AGENTS.md` — Project boundaries and security defaults.
- `.planning/PROJECT.md` — v1.39 goal and verification-automation default.
- `.planning/REQUIREMENTS.md` — TRUTH-06 and CI-09 acceptance criteria.
- `.planning/ROADMAP.md` — Phase 142 goal, success criteria, and Phase 143 boundary.
- `.planning/STATE.md` — Current milestone state and release-truth evidence.
- `.planning/METHODOLOGY.md` — Research-first, recommendation-led planning and escalation bar.

### Existing release, hygiene, and merge controls
- `.planning/RELEASE-TRAIN.md` — Release ownership, exact-main conditions, current package truth, and the baseline pointer to correct.
- `.planning/REPO-HYGIENE-CHECKLIST.md` — Maintainer readiness and exact-SHA evidence expectations.
- `docs/maintainer-release.md` — Normal reviewed release flow, contributor gate, and protected publication boundary.
- `scripts/maintainer/repo_hygiene_check.sh` — Existing local and exact-SHA hygiene interfaces, block/warning rules, and acceptance receipt.
- `.github/workflows/ci.yml` — Canonical CI workflow and required checks.
- `.github/workflows/release.yml` — Release Please and protected publication behavior.
- `.github/workflows/release-please-automerge.yml` — Live Release Please merge and exact post-merge CI dispatch behavior.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Existing release-hygiene contract-test home.
- `test/lockspire/release_ci_evidence_contract_test.exs` — Exact-SHA canonical CI evidence contract.

### Prior decisions and release evidence
- `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-CONTEXT.md` — Phase 141 evidence boundaries, release ownership, and source-vs-documentation identity.
- `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` — Dated public 1.5.0 proof, accepted-source SHA, and Phase 140 dispositions.
- `.planning/milestones/v1.38-phases/139-required-truth-reconciliation/139-CONTEXT.md` — Exact-SHA joins, no-publish semantics, and release ownership.
- `.planning/milestones/v1.38-phases/140-bounded-operational-loose-end-triage/140-CONTEXT.md` — Phase 140 dispositions and evidence boundaries.

### Applicable project prompts
- `prompts/README.md` — How to select relevant prompt guidance.
- `prompts/lockspire-release-engineering-and-ci.md` — Release PR review, CI, and automation principles.
- `prompts/lockspire-release-readiness-and-conformance.md` — Release gates and non-certifying conformance boundaries.
- `prompts/lockspire-elixir-oss-library-practices.md` — Consult only release, packaging, and documentation guidance; API and UI sections do not apply.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/maintainer/repo_hygiene_check.sh` already checks exact-SHA readiness, canonical CI, hygiene outcomes, and warning dispositions; use its established evidence path rather than creating another acceptance command.
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`, and `.github/workflows/release-please-automerge.yml` implement the existing merge, post-merge CI, and protected-release lanes.
- `test/lockspire/release/repository_hygiene_contract_test.exs` is the existing place for a narrow regression contract around the release-train record.

### Established Patterns
- Current release claims join on full immutable SHAs; evidence for an earlier commit never transfers to a later merge commit.
- Planning completion and release metadata are separate from public package publication proof.
- Automated CI and hygiene results satisfy repeatable verification; human attention stays on PR review and consequential action authorization.

### Integration Points
- The reviewed Phase 141 PR lands on `main`, after which canonical CI and exact-SHA repository hygiene establish the Phase 142 readiness result.
- The release-train baseline link should target the archived Phase 141 artifact under `.planning/milestones/v1.38-phases/`.
- Release Please automation can react to a successful `main` CI run, so its current live state must be checked against the Phase 143 publication boundary before merge.

</code_context>

<specifics>
## Specific Ideas

- Correct the release-train pointer to `.planning/milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` and keep a focused CI contract for local links in `.planning/RELEASE-TRAIN.md`.
- Capture exact post-merge SHA and matching CI/hygiene evidence in the Phase 142 result record. Use the 2026-10-05 Phase 141 baseline as historical context, not current proof for a later commit.
- Keep all automated proof in CI or the maintained hygiene check. No manual UAT is needed for these deterministic checks.

</specifics>

<deferred>
## Deferred Ideas

- Protected publication, Hex checksum verification, matching GitHub release, and clean-room public install proof remain Phase 143 work.
- Broad release-workflow redesign, new release interfaces, OAuth/OIDC behavior, host integration, admin UI, and visual design are outside this phase.
- If live release automation state would bypass Phase 142 readiness, treat it as a concrete stop condition for planning/execution; do not widen this phase into speculative release-system changes.

</deferred>

---

*Phase: 142-merge-the-corrected-main-baseline*
*Context gathered: 2026-10-06*
