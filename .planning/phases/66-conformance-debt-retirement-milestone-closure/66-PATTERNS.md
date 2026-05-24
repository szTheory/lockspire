# Phase 66: Conformance Debt Retirement & Milestone Closure - Pattern Map

**Mapped:** 2026-05-07
**Scope:** milestone closure artifacts, canonical doc hierarchy, historical-artifact demotion language, validation-strategy structure, and plan granularity patterns from Phases 63-65.

## File Classification

| Target Artifact | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/milestones/v1.16-MILESTONE-AUDIT.md` | audit | batch | `.planning/milestones/v1.15-MILESTONE-AUDIT.md` | exact |
| `.planning/phases/66-conformance-debt-retirement-milestone-closure/66-VALIDATION.md` | validation | batch | `.planning/phases/65-release-truth-support-contract-reconciliation/65-VALIDATION.md` | exact |
| `.planning/phases/66-conformance-debt-retirement-milestone-closure/66-0N-PLAN.md` | plan | batch | `63-04-PLAN.md`, `64-03-PLAN.md`, `65-01..03-PLAN.md` | exact |
| canonical doc updates touching support/release/conformance truth | doc-contract | request-response | `docs/supported-surface.md`, `docs/maintainer-release.md` | exact |
| historical closure or debt labeling inside audit/docs | audit-note | batch | `v1.14-MILESTONE-AUDIT.md`, `v1.15-MILESTONE-AUDIT.md`, `65-DISCUSSION-LOG.md` | exact |

## Pattern Assignments

### Milestone audit / closure artifact structure

**Primary analog:** `.planning/milestones/v1.15-MILESTONE-AUDIT.md`

Preserve this shape:

- YAML frontmatter first: `milestone`, `audited`, `status`, `scores`, `nyquist`, `gaps`, `tech_debt`
- Then fixed sections in this order:
  1. `## Verdict`
  2. `## Scorecard`
  3. `## Requirements Audit`
  4. `## Phase Audit`
  5. `## Integration Audit`
  6. optional flow section such as `## E2E Flow Audit`
  7. `## Nyquist Discovery`
  8. optional deferred historical-context section

Concrete wording patterns to copy:

- Passed closure uses short decisive verdicts: “achieved its definition of done”, “No unsatisfied milestone requirements... were found.”
- Artifact drift is separated from closure status via frontmatter `tech_debt`, not mixed into the verdict.
- Historical leftovers are explicitly isolated, for example:
  - “informational only because shipped verification is present...”
  - “predates v1.15, is already tracked in `STATE.md`, and does not block...”

### Canonical doc hierarchy and non-claim handling

**Primary analogs:** [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md), [docs/maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md), `.planning/phases/65-release-truth-support-contract-reconciliation/65-02-SUMMARY.md`, `.planning/phases/65-release-truth-support-contract-reconciliation/65-03-SUMMARY.md`

Hierarchy to preserve:

- `docs/supported-surface.md` is the single canonical public contract.
- `README.md` is orientation only.
- `SECURITY.md` is disclosure/security-boundary policy only.
- `docs/maintainer-release.md` is maintainer operations guidance only.

Non-claim pattern to preserve:

- State support positively in a bounded “Supported in scope” section.
- Follow with an explicit “Explicitly out of scope” section rather than implying omissions.
- Use secondary docs to defer upward, not restate policy:
  - “This guide is maintainer-only... It does not define a second public support contract.”
  - “This file does not broaden the Lockspire product contract. For public support truth, defer to...”

When Phase 66 needs conformance wording, keep it in the same posture:

- repo-owned proof first
- manual maintainer runs labeled as supplemental evidence
- no certification or broad readiness claim unless the repo can prove it

### Historical artifact demotion / labeling patterns

**Primary analogs:** `.planning/milestones/v1.14-MILESTONE-AUDIT.md`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md`, `.planning/phases/65-release-truth-support-contract-reconciliation/65-DISCUSSION-LOG.md`

Use explicit labels instead of silent omission:

- `informational only`
- `non-blocking`
- `does not block milestone closure`
- `audit trail only. Do not use as input to planning...`
- `maintainer evidence`, `review-only evidence`, `secondary`, `subordinate`

Preserve the repo’s demotion rule:

- historical gaps can stay visible if they are already tracked elsewhere
- but they must be named as non-authoritative for the current closure decision
- closure text should say why they do not block, not just that they exist

### Validation strategy artifact structure for recent phases

**Primary analog:** `.planning/phases/65-release-truth-support-contract-reconciliation/65-VALIDATION.md`

Preferred Phase 66 shape:

- Frontmatter:
  - `phase`
  - `slug`
  - `status`
  - `nyquist_compliant: true`
  - `wave_0_complete: true`
  - `created`
- Sections in this order:
  1. `## Test Infrastructure`
  2. `## Sampling Rate`
  3. `## Per-Task Verification Map`
  4. `## Wave 0 Requirements`
  5. `## Manual-Only Verifications`
  6. `## Validation Sign-Off`

Recent evolution to preserve:

- Phase 63/64 used plan-level verification maps and acceptance checklists.
- Phase 65 is the newer preferred form: task-level rows with `Task ID`, `Plan`, `Wave`, `Requirement`, `Threat Ref`, `Secure Behavior`, `Test Type`, `Automated Command`, `File Exists`, `Status`.
- Manual-only checks are allowed, but only for facts outside git or outside local execution, and they must say exactly why.

### Plan granularity pattern from Phases 63-65

**Primary analogs:** `63-01..04-PLAN.md`, `64-01..03-PLAN.md`, `65-01..03-PLAN.md`

Granularity to preserve:

- Split a phase into 3-4 plans, each with one coherent subsystem outcome.
- Keep each plan at 2 tasks by default.
- Use waves to encode ordering:
  - wave 1 for baseline/proof fences
  - later waves for doc alignment, integration, or closure
- Put dependency edges at plan level, not task level, unless unavoidable.

Plan document structure to copy:

- frontmatter with `phase`, `plan`, `type`, `wave`, `depends_on`, `files_modified`, `requirements`
- `must_haves` divided into `truths`, `artifacts`, `key_links`
- then `objective`, `execution_context`, `context`, `tasks`, `threat_model`, `verification`, `success_criteria`, `output`

Task structure to preserve:

- `<read_first>` list
- one concrete `<action>` paragraph
- hard acceptance criteria expressed as file-content or artifact-truth checks
- exactly one focused automated verify command where possible
- short `<done>` statement tied to user-visible truth

## Shared Patterns

### Closure separates status from debt
**Source:** `.planning/milestones/v1.14-MILESTONE-AUDIT.md`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md`

Apply to Phase 66 milestone closure:

- keep `status: passed` or equivalent based on shipped proof
- track residual cleanup under `tech_debt` / `Nyquist Discovery`
- explicitly say residual historical items are non-blocking when current-phase proof is sufficient

### Canonical-vs-secondary authority must be explicit
**Source:** [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md), [docs/maintainer-release.md](/Users/jon/projects/lockspire/docs/maintainer-release.md)

Apply to any conformance/debt-retirement docs:

- one canonical truth source
- companion or maintainer artifacts defer to it
- secondary artifacts must say they do not broaden the contract

### Proof-first, non-claim-first wording
**Source:** [docs/supported-surface.md](/Users/jon/projects/lockspire/docs/supported-surface.md), `.planning/phases/64-sigra-golden-path-generated-host-proof/64-03-PLAN.md`

Apply to Phase 66 conformance language:

- name the exact proof artifact or test for each positive claim
- keep “out of scope”, “not a pass-gate”, and “manual maintainer step” wording explicit where applicable
- do not turn a maintained manual procedure into implied CI proof

## Planner Notes

- If Phase 66 creates a milestone-closing audit, model it on `v1.15-MILESTONE-AUDIT.md`, not on a phase summary.
- If it creates or refreshes validation strategy, use the newer Phase 65 task-level map, not the older plan-only map.
- If it touches historical conformance debt, surface it as named `tech_debt`, `informational only`, or `audit trail only` rather than deleting context.
- If it changes docs around conformance or support posture, keep `docs/supported-surface.md` authoritative and keep maintainer/contributor artifacts explicitly secondary.
