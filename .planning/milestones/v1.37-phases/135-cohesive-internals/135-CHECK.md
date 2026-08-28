---
phase: 135-cohesive-internals
checked: 2026-08-27
status: passed
plans_checked: 9
revision_gate: 1
---

# Phase 135 Plan Check

## Verdict

**PASSED.** The nine plans can achieve the Phase 135 goal: aggregate-specific Ecto ownership and focused token-grant collaborators move inward while `Repository` and `TokenExchange` remain compatible public facades.

This check made two required planning corrections before passing:

1. The research decisions for legacy option compatibility and the dependency-bundle form are now explicitly resolved: preserve every observed token-internal option key through `LegacyOptions`, and use a non-advertised, validated `Dependencies` struct.
2. COH-05 now explicitly characterizes mounted `TokenController` HTTP statuses, headers, and JSON bodies for every grant in addition to stable-facade result, durable-state, audit, and telemetry assertions. Direct `TokenExchange` calls alone would not prove the endpoint-response part of the requirement.

## Goal-Backward Coverage

| Requirement | Executable coverage | Verdict |
|---|---|---|
| COH-01 | Plans 02–05 move all repository behavior families to aggregate owners; Plan 09 rejects aggregate queries, changesets, locks, and lifecycle logic returning to the facade. | Covered |
| COH-02 | Plan 01 establishes PostgreSQL rollback/concurrency characterization; Plans 02 and 05 preserve client/DCR, code, refresh-family, and signing-key atomic owners; Plan 09 reruns the proof. | Covered |
| COH-03 | Plans 07–08 split auth, resource selection, polling, issuance, persistence, and observability, retain neutral grant coordinators, and Plan 09 makes ownership permanent. | Covered |
| COH-04 | Plan 06 creates the one legacy-option adapter and typed dependency bundle; Plans 07–08 consume bundle subsets; Plan 09 rejects runtime discovery, `Mix.env()`, and downstream option reads. | Covered |
| COH-05 | Plan 01 pins five stable-facade and mounted-token-endpoint flows, including response/errors/tokens/audit/telemetry; Plans 06–09 rerun and permanently include it. | Covered |

## Dependency and Contract Check

| Wave | Plans | Result |
|---|---|---|
| 1 | 01 | Characterization precedes all structural movement. |
| 2 | 02, 06 | Independent storage and token trees; no listed-file overlap. |
| 3 | 03, 07 | Each consumes only its respective Wave 2 predecessor. |
| 4 | 04, 08 | Independent storage/token trees; no listed-file overlap. |
| 5 | 05 | Completes the serialized Repository facade extraction. |
| 6 | 09 | Waits for both storage and token convergence before enforcing final fitness/full gates. |

The graph is acyclic, every dependency exists and precedes its consumer, and shared facade files are serialized. All 22 tasks have Files, Action, automated Verify, and Done fields. Every task has a focused automated command; no command uses a watch mode, suppressed failing comparison, or unmeasured hard-coded count.

The transaction plan assigns lock, state-validation, write, and audit work to a single aggregate entry point for code redemption, refresh rotation/reuse, DCR/RAT mutation, PAR, polling state machines, and key transitions. It therefore does not introduce a cross-plan partial-write contract. The explicit bundle is built at public/compatibility entries, then threaded inward; it does not introduce a reverse edge to `TokenExchange` or a new public storage surface, preserving Phase 134's topology contract.

## Context, Research, and Project Compliance

- No Phase 135 `CONTEXT.md` exists; the plans honor the roadmap/requirements as the binding scope and retain Phase 134's literal compatibility baseline.
- The research open questions are resolved in `135-RESEARCH.md`; no unresolved research question blocks execution.
- Plans follow the established facade-over-private-collaborator pattern from `PATTERNS.md`, preserve host seams, use no new OAuth grants or hosted-service scope, and retain the AGENTS.md security defaults.
- The architectural responsibility map is honored: Ecto aggregate adapters own locks/transactions, public facades own compatibility conversion, and token collaborators own only their designated concerns.

## Execution Advisory

Plan 08 changes 13 files across three intentionally sequenced tasks. That exceeds the normal eight-file target but remains below the hard split threshold and is bounded by clear collaborator ownership plus focused tests. Execute its three tasks as separate commits and stop to rerun the listed characterization/atomicity tests after each task.

## Verification Evidence

- `verify.plan-structure` reports all nine plans valid, with 22/22 complete tasks.
- `135-VALIDATION.md` covers every COH requirement, all required proof gaps, waves, and final gates.
- `135-RESEARCH.md` contains an Architectural Responsibility Map and now has `## Open Questions (RESOLVED)`.
- `git diff --check` passes for the planning corrections.

Plans verified. Proceed with `$gsd-execute-phase 135`.
