# Phase 139: Required Truth Reconciliation - Context

**Gathered:** 2026-09-11 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 139 reconciles one exact-SHA, repository-owned acceptance and release truth across local gates, required CI, release workflow outcomes, repository hygiene, planning records, and the existing public-release evidence chain. It may make only narrow truth or deterministic-check corrections supported by repository evidence. It does not publish a release, manually change release-owned versioning files, perform Phase 140 cleanup or dependency-PR triage, rewrite historical evidence, force supplemental OIDF success, or add product/runtime surface.

</domain>

<decisions>
## Implementation Decisions

### Exact-SHA Acceptance Boundary
- **D-01:** Use one synchronized final `main` SHA as Phase 139's acceptance anchor. The Phase 138 publication SHA, a phase-branch HEAD, the historical `1.5.0` source SHA, and an arbitrary latest successful workflow run are distinct evidence and must not substitute for that anchor.
- **D-02:** Revalidate the immutable Phase 138 inventory relation at Phase 139's required authority boundaries. The inventory remains proposal-only; any `refresh_required`, incomplete source, identity mismatch, or unauthorized post-snapshot movement fails closed instead of being reinterpreted as current acceptance evidence.
- **D-03:** Bind fresh `mix ci`, repository-hygiene results, the canonical required-CI result, and the release-workflow outcome to the same reconciled final `main` SHA. A successful workflow result for another SHA cannot satisfy the phase even if it is the newest green run.

### Release Outcome and Historical Traceability
- **D-04:** Treat a successful push-triggered Release workflow whose publication-only jobs intentionally skip as a valid no-publish outcome for the reconciled baseline. Only the existing protected exact-ref dispatch path may publish.
- **D-05:** Preserve the proven `1.5.0` release chain as historical evidence: source SHA `5d10ce2219c2e687cf9573c8b280abfb118a47d8`, canonical CI run `33141161205`, protected release run `33141484467`, package SHA-256 `30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de`, its tag, public Hex package, and maintained release records. Do not rewrite that chain as though it describes the newer reconciliation SHA.
- **D-06:** Treat the executable protected-release workflow and its contract tests as the authority for release ordering and eligibility. Where maintained explanatory prose disagrees, reconcile the prose to the executable contract without manually changing versions, changelog entries, manifests, tags, or package publication state.

### Deterministic Hygiene and Supply-Chain Guardrails
- **D-07:** Add or tighten a repository-health check only when Phase 139 execution demonstrates a repeatable repository-owned gap. Keep any correction narrow, deterministic, and tied to an already-required invariant rather than building a new maintenance subsystem.
- **D-08:** Close the demonstrated exact-head evidence gap: repository checks that claim required workflow success must compare the observed workflow SHA to the reconciled baseline SHA. Preserve full-commit-SHA pinning across workflow actions and the repository-controlled composite Release Please action.
- **D-09:** Keep Phase 139 maintainer enforcement in existing repo-local shell and focused ExUnit contract tests. Do not introduce a Mix task, Phoenix route, LiveView, Ecto schema, Oban job, or packaged/runtime Lockspire API.

### Planning and Supplemental-Evidence Taxonomy
- **D-10:** Planning truth and shipped-release truth are related but distinct: `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` should identify v1.38 and Phase 139 as active, while release records continue to identify v1.37 / Lockspire `1.5.0` as the latest shipped state until the normal release train changes that fact.
- **D-11:** Keep OIDF/FAPI results in a separate redacted, supplemental, non-certifying evidence class. Supplemental results neither satisfy required acceptance nor block a baseline whose required repository-owned checks pass; retained failures remain future bounded conformance evidence.
- **D-12:** Reconcile maintained planning and release prose only where current repository evidence proves a contradiction. Preserve historical records and explicit deferrals instead of rewriting archives or declaring the active maintenance milestone released.

### the agent's Discretion
Downstream planning may choose internal shell helper names, the exact compact format used to record SHA-bound receipts and hygiene `WARN` dispositions, deterministic ordering, and which existing focused contract-test module owns each assertion. Those choices must preserve the exact-SHA boundary, immutable historical evidence, release ownership, fail-closed semantics, supplemental-evidence taxonomy, and repo-local tooling boundary above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope and Prior Evidence
- `.planning/PROJECT.md` — Defines the v1.38 maintenance-baseline goal, current release posture, and product/runtime exclusions.
- `.planning/REQUIREMENTS.md` — Defines CI-06 through CI-08, QUAL-05, HYGIENE-05 through HYGIENE-06, and TRUTH-03 through TRUTH-05.
- `.planning/ROADMAP.md` — Defines Phase 139's boundary, success criteria, dependencies, and handoff to Phases 140-141.
- `.planning/STATE.md` — Carries the active phase, exact `1.5.0` release receipts, Phase 138 decisions, and current revalidation concerns.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-CONTEXT.md` — Locks the inventory ownership, evidence taxonomy, provenance, safety, and proposal-only disposition contract.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — Canonical immutable inventory and the exact revalidation contract Phase 139 must consume.

### Acceptance, Hygiene, and Release Controls
- `mix.exs` — Defines the repository's `mix ci` contributor gate and project/package truth.
- `scripts/maintainer/baseline_inventory.sh` — Implements immutable-ledger publication and fail-closed snapshot-relation verification.
- `scripts/maintainer/repo_hygiene_check.sh` — Existing `PASS`/`WARN`/`BLOCK` hygiene surface and current workflow-evidence checks.
- `.planning/REPO-HYGIENE-CHECKLIST.md` — Maintainer-facing command vocabulary and expected repository-readiness interpretation.
- `.github/workflows/ci.yml` — Canonical required CI jobs and SHA-bound coverage/release-hygiene evidence.
- `.github/workflows/release.yml` — Release Please maintenance, exact-ref validation, package proof, protected publication, and public-install verification behavior.
- `.github/workflows/release-please-automerge.yml` — Post-merge canonical-CI dispatch, no-eligible-release handling, and exact CI evidence forwarding.
- `.github/actions/release-please/action.yml` — Repository-controlled composite action whose external action dependencies must remain full-SHA pinned.
- `.planning/RELEASE-TRAIN.md` — Maintained sustaining-GA and public-release traceability contract.
- `.planning/DEVELOPMENT-TRAIN.md` — Defines feature versus sustaining lanes and release-publication ownership boundaries.
- `.planning/MILESTONES.md` — Historical milestone and latest-shipped-release record that reconciliation must preserve.

### Executable Contract Proof
- `test/lockspire/release_ci_evidence_contract_test.exs` — Pins exact successful-CI metadata and release-dispatch evidence behavior.
- `test/support/lockspire/release_proof/workflow_assertions.ex` — Shared assertions for protected release ordering and artifact proof.
- `test/lockspire/workflow_supply_chain_contract_test.exs` — Existing full-SHA action-pinning contract and the composite-action coverage seam.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Existing repository-hygiene and maintainer-surface boundary proof.

### Supplemental Conformance Evidence
- `.github/workflows/oidf-conformance.yml` — Separately scheduled supplemental OIDF evidence workflow.
- `test/lockspire/conformance_workflow_contract_test.exs` — Pins the non-release-gate and non-certification boundary.
- `test/lockspire/conformance_redacted_evidence_contract_test.exs` — Pins redaction and bounded retained-evidence behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/maintainer/baseline_inventory.sh`: Reuse its production snapshot-relation verifier rather than inventing a second currentness model.
- `scripts/maintainer/repo_hygiene_check.sh`: Extend its existing result aggregation and `PASS`/`WARN`/`BLOCK` vocabulary if exact-head checking or disposition recording needs correction.
- `test/lockspire/release/repository_hygiene_contract_test.exs` and `test/lockspire/workflow_supply_chain_contract_test.exs`: Natural focused homes for deterministic hygiene and action-pinning assertions.
- Existing GitHub Actions API queries in the maintainer scripts and workflows: Reuse structured `headSha`, workflow identity, event, branch, conclusion, and repository metadata for exact-SHA proof.

### Established Patterns
- Repository acceptance is executable and fail-closed: exact identities, complete receipts, successful commands, and semantic validation outrank convenient prose or latest-run heuristics.
- Maintainer automation stays in repo-local shell, while ExUnit contract tests prevent drift and public/package-surface expansion.
- Release truth is exact-SHA- and manifest-bound; Release Please owns bookkeeping and only protected dispatch owns publication.
- Historical release and conformance evidence is retained, redacted where necessary, and classified rather than rewritten.

### Integration Points
- Run the Phase 138 production relation verifier before treating the inventory as current Phase 139 input and again after lifecycle writes as its contract requires.
- Bind local-gate and GitHub workflow receipts through `scripts/maintainer/repo_hygiene_check.sh` and focused contract tests.
- Reconcile explanatory planning/release records against `.github/workflows/release.yml` and `.github/workflows/release-please-automerge.yml` without changing release-owned state.
- Carry the resulting SHA-bound truth forward for Phase 140's per-target revalidation and Phase 141's final baseline record.

</code_context>

<specifics>
## Specific Ideas

- Use the reconciled final `main` SHA as the visible join key across local gates, required CI, release outcome, and maintained truth records.
- Record an intentional no-publish release outcome explicitly; do not describe a successful skip as missing evidence or as a release failure.
- Phrase supplemental OIDF status consistently as redacted, non-certifying evidence that is not a release gate.

</specifics>

<deferred>
## Deferred Ideas

- Per-PR dependency compatibility, security, and merge/close decisions remain Phase 140 work.
- Branch, tag, worktree, issue, PR, or maintained-record cleanup remains Phase 140 work and requires exact-target revalidation.
- Final dated baseline publication and the return to the sustaining GA release train remain Phase 141 work.
- Supplemental OIDF/FAPI failure remediation remains a future bounded conformance-hardening milestone unless Phase 139 proves a narrow repository regression.
- A new CI platform, maintenance database/dashboard, broad dependency campaign, protocol capability, host seam, or admin surface remains outside v1.38.

</deferred>

---

*Phase: 139-required-truth-reconciliation*
*Context gathered: 2026-09-11*
