# Phase 140: Bounded Operational Loose-End Triage - Context

**Gathered:** 2026-09-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 140 closes only safe, evidence-backed maintenance gaps and retains a clear, recoverable disposition for everything else. It covers CI-06, CI-07, BASE-03, TRIAGE-03, LOOSE-02, and LOOSE-03: current finding dispositions, authorized exact-target cleanup, individual dependency-PR assessment, bounded repairs, and exact-SHA required acceptance. Phase 141 owns the final milestone baseline handoff and return to the sustaining GA release train.

This phase preserves Lockspire's embedded-library shape, host-owned seams, secure defaults, intentional work, and historical release evidence. It does not add protocol or admin capabilities, conduct a broad dependency/refactoring campaign, force supplemental conformance success, create a maintenance subsystem, or manually change release-owned versioning/publication state.

</domain>

<decisions>
## Implementation Decisions

### One Traceable Disposition Record
- **D-01:** Create one authoritative Phase 140 Markdown disposition record referencing stable Phase 138 evidence IDs and canonical source paths or URLs. Preserve the original Phase 138 inventory as immutable observed evidence; do not rewrite it to make proposals appear executed.
- **D-02:** Assign each credible maintained finding exactly one supported disposition: `fix-now`, `defer-with-trigger`, `retain-historical`, `already-resolved`, or `out-of-scope`. Deduplicate repeated mentions while preserving their references. Keep domain-native Git/PR/issue dispositions alongside the finding disposition where applicable.
- **D-03:** Record the evidence, rationale, current target identity, next proof or recheck trigger, and proposed-versus-executed state. A fix or resolved claim requires terminal evidence; historical means intentionally retained. A healthy baseline does not require an empty queue or deleted history.

### Revalidate Before Action
- **D-04:** Refresh evidence at the authorized Phase 140 inventory boundary and validate its relationship to the preserved snapshot before relying on proposals. Incomplete evidence, identity mismatch, or `refresh_required` cannot be treated as current action authority. Reuse the existing collector and relation controls; research the bounded refresh path before implementation.
- **D-05:** Immediately before any inventory action, revalidate its exact target, current state, existing authority, recovery path, worktree safety, and historical-evidence safety. Preserve uncommitted work and intentional refs. Defer a changed or inadequately supported target with the missing proof and trigger recorded.
- **D-06:** Confirmation of this context locks the decision framework; it does not itself authorize deleting a particular branch, tag, or worktree, merging or closing a particular GitHub item, or publishing a release. Apply authority already established for a concrete action and seek additional authority only where genuinely missing.

### Finite Evidence-Led Triage
- **D-07:** Review the nine archived v1.32/v1.27 UAT records as candidates against current behavior and evidence. Preserve their existing out-of-scope or deferred dispositions unless current evidence supports changing them. Do not replay completed phase plans or convert historical notes into mandatory new work.
- **D-08:** Include demonstrated maintained-record contradictions as bounded candidates, such as Phase 139's inconsistent roadmap plan counts and stale current-state prose. Reconcile only claims contradicted by current evidence; preserve historical records and pre-existing local edits.
- **D-09:** Fix only current blockers, regressions, contradictions, stale actionable artifacts, and small high-confidence maintenance gaps. Defer speculative, feature-sized, or insufficiently evidenced work with a concrete trigger. Stop when the finite refreshed set of credible findings has supported dispositions, selected bounded fixes have proof, and required acceptance passes.
- **D-10:** Reuse existing repository controls. Add or tighten recurring automation only for a demonstrated repeatable repository-owned gap; avoid another maintenance framework or new product/runtime surface.

### Individual Dependency Evidence and Final Acceptance
- **D-11:** Assess each current dependency-update PR independently for compatibility, security, and required repository gates. Refresh the PR's actual version change, target identity, and check results; dated inventory rows and another PR's green checks are insufficient. Research current upstream compatibility and security evidence for the specific package/version under consideration.
- **D-12:** Use focused automated checks at the earliest useful point for selected repairs. Reuse existing unit, integration, contract, smoke, and seam checks; add recurring CI proof only where reliable and valuable. Reliable executable evidence satisfies verification without an unnecessary human UAT handoff.
- **D-13:** Close CI-06 and CI-07 against the resulting synchronized final `main` SHA, with required canonical CI and a successful intentional Release no-publish outcome for that same SHA. Bind local `mix ci` and hygiene evidence through the existing acceptance path; retain an explicit disposition for each hygiene `WARN` and no unresolved `BLOCK`.
- **D-14:** The recorded Phase 140 entry receipt is dated proof for its exact SHA, not blanket acceptance of later state. Preserve the blocking `plan:pre` contract and revalidate through its supported lifecycle. Keep supplemental OIDF/FAPI findings redacted and non-certifying, separate from required acceptance; preserve the historical 1.5.0 release chain and Release Please/protected publishing ownership.

### Execution Scope Amendment (2026-09-30)

The user approved a narrow rescope for Plan 140-02: assess only archived findings whose source identities are actually supported. The v1.27 grouped `5+2+2` report remains a grouped test-failure report, not nine UAT-record identities. The five Phase81 names may be tracked individually as source-native test cases, separately from that grouped report and from D-07's original nine-UAT-record target. The four historical Phase32/AuditWriter test identities remain unavailable; do not invent names or map current rerun selectors back to them. Keep v1.32 Phase115/JWKS caveats at their archived aggregate level. This approved amendment supersedes D-07's nine-distinct-record execution target; retain the source limitation in the disposition and plan summary.

### the agent's Discretion
The user confirmed the complete recommendation bundle without corrections. Planning may choose the disposition filename and compact table layout, bounded task grouping, focused test selectors, and internal helper details. Those choices must preserve stable references, explicit authority, finite scope, current proof, existing release ownership, and the distinction between observed, proposed, and executed work. Fresh research is the selected next planning step.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, Prior Decisions, and Current Position
- `AGENTS.md` — Embedded-library boundaries and security defaults.
- `.planning/PROJECT.md` — v1.38 maintenance scope and verification/automation default.
- `.planning/REQUIREMENTS.md` — CI-06, CI-07, BASE-03, TRIAGE-03, LOOSE-02, and LOOSE-03.
- `.planning/ROADMAP.md` — Phase 140 boundary, entry gate, and Phase 141 handoff.
- `.planning/STATE.md` — Latest verification, dated entry receipt, refresh obligation, and archived candidates.
- `.planning/METHODOLOGY.md` — Evidence-first recommendations and high-threshold escalation.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-CONTEXT.md` — Immutable proposal-only inventory, taxonomy, currentness, and authority rules.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — Original stable IDs and dated source observations; revalidation required.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md` — Explicitly deferred snapshot-refresh check #100.
- `.planning/phases/139-required-truth-reconciliation/139-CONTEXT.md` — Exact-SHA, release, and supplemental-evidence boundaries.
- `.planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md` — Current repository-owned reconciliation proof.
- `.planning/milestones/v1.27-MILESTONE-AUDIT.md` and `.planning/milestones/v1.32-MILESTONE-AUDIT.md` — Archived non-blocking/deferred candidates; inspect referenced records only as needed.

### Existing Maintenance and Acceptance Controls
- `.planning/REPO-HYGIENE-CHECKLIST.md` — Maintainer gates and explicit WARN dispositions.
- `.planning/RELEASE-TRAIN.md` and `.planning/DEVELOPMENT-TRAIN.md` — Sustaining lane, historical release truth, and publishing ownership.
- `scripts/maintainer/baseline_inventory.sh` — Existing collection and snapshot-relation controls.
- `scripts/maintainer/repo_hygiene_check.sh` — Local gates and same-SHA CI/Release acceptance.
- `scripts/maintainer/finalize_phase_139_acceptance.sh` — Supported Phase 139 acceptance finalization consumed by the Phase 140 entry boundary.
- `tools/gsd-capabilities/lockspire-phase-finalizer/capability.json` — Blocking lifecycle hook contract.
- `mix.exs` — Required local CI aliases and dependency/package truth.
- `.github/workflows/ci.yml`, `.github/workflows/dependency-review.yml`, and `.github/workflows/release.yml` — Required checks, dependency review, and no-publish/publish behavior.
- `test/lockspire/release/repository_hygiene_contract_test.exs`, `test/lockspire/release_ci_evidence_contract_test.exs`, and `test/lockspire/workflow_supply_chain_contract_test.exs` — Existing focused regression-proof seams.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `baseline_inventory.sh` already collects scoped Git, GitHub, and maintained-record evidence with stable IDs and complete/partial/unavailable semantics. Collection refreshes metadata and writes evidence; distinguish it from read-only relation inspection.
- `repo_hygiene_check.sh` already binds clean local state, local gates, canonical workflow identities, exact SHAs, and explicit WARN dispositions.
- The existing finalizer capability owns the blocking Phase 140 entry boundary. Preserve its supported lifecycle rather than inventing another acceptance route.
- Existing ExUnit contracts cover repository hygiene, release CI evidence, and supply-chain boundaries; `mix ci` remains the broad local gate.

### Established Patterns
- Maintainer controls live in repository-local tooling and Markdown; they are not supported Hex-library or host-application APIs.
- Immutable evidence and mutable current state are distinct. Historical receipts retain their meaning while new actions require current proof.
- Release Please owns bookkeeping and the protected exact-ref lane owns publication. Supplemental OIDF results neither replace nor redefine required acceptance.

### Integration Points
- Join the new disposition record to Phase 138 stable IDs and specific archived sources.
- Refresh mutable Git/GitHub evidence at the named boundary and immediately before an authorized action.
- Apply bounded fixes through existing source/test/doc seams; carry exact acceptance and disposition evidence forward to Phase 141.

</code_context>

<specifics>
## Specific Ideas

- The user selected “Proceed” for all four presented areas: one disposition record, revalidation before action, finite maintenance scope, and individual dependency/final-baseline proof.
- The recorded entry receipt names synchronized `main` SHA `7ab6e495fbd89bc2c5d71862c86ac9ce6ab1fea9`, CI run `36314255664`, and Release no-publish run `36314255656`. These are dated references, not a claim that the current working tree is clean or later changes have passed.
- Discussion observed five modified planning files and an untracked roadmap prompt. Preserve that work; context capture does not dispose of it.
- Phase 139 roadmap details report 9/11 plans while its progress table reports 13/13. Treat this as a concrete reconciliation candidate, verifying actual plan/summary pairs before editing claims.
- No external research was needed for the phase-wide decision bundle. Fresh planning research should determine the supported snapshot-refresh path and current candidate-specific dependency evidence.

</specifics>

<deferred>
## Deferred Ideas

- Final dated milestone-baseline publication and return to the sustaining GA release train belong to Phase 141.
- Supplemental OIDF/FAPI remediation remains future bounded conformance work unless current evidence demonstrates a narrowly scoped repository regression.
- Broad dependency refresh, speculative refactoring, protocol/host/admin expansion, maintenance dashboards/frameworks, destructive bulk cleanup, and manual release publication remain outside this phase.
- No pending todos matched Phase 140 during discussion; no additional todos were folded into scope.

</deferred>
