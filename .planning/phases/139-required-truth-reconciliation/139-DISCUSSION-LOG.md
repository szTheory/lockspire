# Phase 139: Required Truth Reconciliation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-09-11
**Phase:** 139-required-truth-reconciliation
**Mode:** assumptions
**Areas analyzed:** Exact-SHA Acceptance Boundary, Release Outcome and Historical Traceability, Deterministic Hygiene and Supply-Chain Guardrails, Planning and Supplemental-Evidence Taxonomy

## Assumptions Presented

### Exact-SHA Acceptance Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 139 binds the revalidated Phase 138 inventory, fresh `mix ci`, repository hygiene, canonical CI, and release-workflow outcome to one synchronized final `main` SHA; adjacent and historical SHAs are not interchangeable. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `mix.exs`; `scripts/maintainer/baseline_inventory.sh`; `scripts/maintainer/repo_hygiene_check.sh` |

### Release Outcome and Historical Traceability

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| A successful push-triggered Release run with publication jobs intentionally skipped is valid Phase 139 evidence; only exact-ref dispatch may publish, and the `1.5.0` chain remains separate historical truth. | Confident | `.github/workflows/release.yml`; `.github/workflows/release-please-automerge.yml`; `.planning/RELEASE-TRAIN.md`; `.planning/MILESTONES.md`; `.planning/STATE.md`; `test/support/lockspire/release_proof/workflow_assertions.ex` |

### Deterministic Hygiene and Supply-Chain Guardrails

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 139 tightens only demonstrated mechanical gaps, especially exact-head workflow evidence and full-SHA pins across workflows and the composite action, using repo-local shell and focused ExUnit proof. | Confident | `.planning/REQUIREMENTS.md`; `scripts/maintainer/repo_hygiene_check.sh`; `test/lockspire/workflow_supply_chain_contract_test.exs`; `.github/actions/release-please/action.yml`; Phase 138 context |

### Planning and Supplemental-Evidence Taxonomy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Planning describes active v1.38/Phase 139 while release records preserve shipped v1.37/`1.5.0`; OIDF results remain redacted, supplemental, non-certifying, and outside required acceptance. | Confident | `.planning/PROJECT.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/MILESTONES.md`; `.planning/RELEASE-TRAIN.md`; `.github/workflows/oidf-conformance.yml`; conformance contract tests |

## Corrections Made

No corrections — all assumptions confirmed.

