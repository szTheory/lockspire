# Phase 140: Bounded Operational Loose-End Triage - Pattern Map

**Mapped:** 2026-09-28  
**Files analyzed:** 1 definite new file; additional edits are conditional on refreshed evidence.  
**Analogs found:** 5 / 5 likely file groups

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md` (name discretionary) | planning documentation | transform / evidence join | `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` | role-match |
| `.planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md` | verification record | request-response / evidence join | `.planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md` | role-match |
| `.planning/phases/140-bounded-operational-loose-end-triage/140-*-SUMMARY.md` and modified planning records, only if discrepancies are confirmed | planning documentation | transform | `.planning/phases/139-required-truth-reconciliation/139-04-SUMMARY.md` | role-match |
| `scripts/maintainer/baseline_inventory.sh` or focused tests, only if a repeatable gap is demonstrated | maintenance utility / test | file-I/O, request-response | `scripts/maintainer/baseline_inventory.sh`; `test/lockspire/release/repository_hygiene_contract_test.exs` | exact / role-match |
| `scripts/maintainer/repo_hygiene_check.sh` or focused tests, only if required acceptance has a demonstrated gap | maintenance utility / test | request-response | `scripts/maintainer/repo_hygiene_check.sh`; `test/lockspire/release/repository_hygiene_contract_test.exs` | exact / role-match |

The disposition record and verification report are the expected artifacts. Source changes are conditional: reuse the Phase 138 collector and Phase 139 acceptance path unless refreshed evidence demonstrates a recurring repository-owned defect. Do not treat this map as permission for any concrete cleanup or dependency action.

## Pattern Assignments

### `140-DISPOSITIONS.md` (planning documentation, evidence join)

**Analog:** `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` (tracked)

The immutable inventory shows the source-record convention and the boundary between observation and action. Front matter records collection identity and `executed: "no — inventory proposal only"` (lines 1-20); the body states “Observed. Revalidation required before action. This receipt proposes no cleanup.” (lines 22-24). Its rows carry stable IDs, observed state, proposed disposition, evidence reference, rationale, confidence, recheck proof, required authority, and executed state (lines 37-50).

**Copy:** Link each Phase 140 row to stable Phase 138 IDs and canonical source references. Keep finding disposition separate from Git/PR-native disposition. Include current identity, evidence and rationale, trigger/next proof, and proposed-versus-executed status. A resolved or fixed claim needs terminal evidence; preserve the Phase 138 source as historical observation.

### `140-VERIFICATION.md` (verification record, evidence join)

**Analog:** `.planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md` (tracked)

Lines 91-104 show the useful structure: goal, timestamp/status, a bounded revalidation section, dated evidence, and explicit limits on what old proof establishes. Lines 110-118 map each success criterion to status and evidence; lines 131-141 map required artifacts to verification evidence.

**Copy:** Bind each acceptance claim to exact sources and SHA. State which receipt/run is dated evidence, which checks cover the final state, and which findings remain deferred. Keep supplemental OIDF/FAPI evidence explicitly non-certifying and outside required acceptance.

### Conditional maintained-record reconciliation / phase summaries

**Analog:** `.planning/phases/139-required-truth-reconciliation/139-04-SUMMARY.md` (tracked), lines 30-45 and 49-79.

The summary uses `key-files` to identify created/modified artifacts, preserves historical versus active truth classes, and records bounded changes with requirement-linked proof. Use this format only for contradictions confirmed against actual plan/summary pairs and current repository evidence. Preserve history and pre-existing local changes; do not normalize counts by assumption.

### Conditional inventory tooling repair

**Analog:** `scripts/maintainer/baseline_inventory.sh` (tracked), lines 100-124 and 414-424.

Lines 100-124 document distinct collection and read-only relation commands. Lines 414-424 explain the immutable snapshot boundary, relation proof, and `refresh_required` consequence. The relation implementation at lines 4684-4713 fails closed on unresolved or changed snapshot identity. Reuse the collector and relation controls; collection refreshes origin metadata and writes a ledger, so the read-only relation check and collection must not be conflated.

**Test analog:** `test/lockspire/release/repository_hygiene_contract_test.exs` (tracked), lines 50-88, invokes focused assertions for safe receipts, deterministic rows, malformed evidence, stable-ID failures, and complete GitHub evidence. Add a focused contract only if a repeatable defect has been proven.

### Conditional exact-SHA acceptance repair

**Analog:** `scripts/maintainer/repo_hygiene_check.sh` (tracked), lines 326-345, 434-474, and 476-510.

The workflow validator binds workflow ID/name/path, repository, push event, `main`, terminal success, and the requested exact SHA. The Release validator requires the successful no-publish job graph (lines 434-474), and WARN labels require explicit, unique dispositions (lines 476-510). The exact mode returns success only after exact acceptance completes without blocks (lines 1037-1048).

**Copy:** Keep required local gates, hygiene, canonical CI, and intentional Release no-publish proof attached to one synchronized final SHA. Re-query each dependency PR's own head/base and checks; do not transfer another PR's result. Do not add a second acceptance checker.

## Shared Patterns

### Evidence freshness and authority

**Sources:** `baseline_inventory.sh` lines 414-424 and 4684-4713; immutable Phase 138 ledger lines 22-24 and 37-50.  
Keep historical observations immutable. Refresh mutable evidence at the authorized boundary and revalidate exact identity, authority, worktree safety, and recovery immediately before any action. `refresh_required`, partial evidence, or identity mismatch cannot support action.

### Same-SHA acceptance

**Source:** `repo_hygiene_check.sh` lines 326-345 and 434-510.  
Bind `mix ci`, hygiene results and explicit WARN dispositions, canonical CI, and successful Release no-publish outcome to the same synchronized final `main` SHA. An entry receipt proves only its recorded SHA.

### Finding and dependency dispositions

**Sources:** `140-CONTEXT.md` D-01–D-14 and `.planning/REQUIREMENTS.md` lines 41-45.  
Assign exactly one finding disposition (`fix-now`, `defer-with-trigger`, `retain-historical`, `already-resolved`, or `out-of-scope`) and keep any Git/PR-native status alongside it. Assess each dependency PR independently against its refreshed version delta, target identity, compatibility/security evidence, and required checks.

## No Analog Found

No new product/runtime module or maintenance subsystem is in scope. No analog should be invented for those excluded roles. Any source or test file not listed above should enter planning only if fresh evidence identifies a concrete bounded repair.

## Metadata

**Analog search scope:** `.planning/phases/138-baseline-inventory-evidence-taxonomy/`, `.planning/phases/139-required-truth-reconciliation/`, `scripts/maintainer/`, and `test/lockspire/release/`.  
**Files scanned:** 5 primary analogs plus phase research/context and requirement/roadmap inputs.  
**Tracked-source gate:** All named source analogs verified by `git ls-files`; no ignored capability mirrors used.  
**Pattern extraction date:** 2026-09-28
