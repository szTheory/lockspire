# Phase 162: Lifetime Semantics & Upgrade Contract - Pattern Map

**Mapped:** 2026-10-20  
**Files analyzed:** 3 planned artifacts  
**Analogs found:** 2 / 3 (one partial validator style match)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| Phase-local normative lifetime and upgrade contract (exact public docs path to be selected in plan) | documentation / contract | decision-to-contract transform | `.planning/milestones/v1.27-phases/97-contract-docs-first/97-PATTERNS.md` and its documented source contracts | role-match |
| Phase-local JSON acceptance matrix / semantic fixtures | fixture / data | declarative transform | No close JSON semantic fixture analog found; derive cases from `162-CONTEXT.md` and `162-RESEARCH.md` | no analog |
| Phase-local stdlib Python contract validator | utility / validator | file I/O, parse and validate | `scripts/maintainer/verify_phase140_read_only_closure.py` | partial (standalone validator structure; its network/GitHub workflow is out of scope)

## Pattern Assignments

### Normative lifetime and upgrade contract (documentation, decision-to-contract)

**Analog:** `.planning/milestones/v1.27-phases/97-contract-docs-first/97-PATTERNS.md`; tracked source verified with `git ls-files`.

Follow the precedent of making contract edits traceable to existing decisions and preserving existing ownership boundaries. For Phase 162, map every D-01–D-27 decision and DCR-02/03/04 requirement to substantive contract sections and observable acceptance expectations. Organize the content around the chosen lifetime matrix, endpoint/error inventory, management recovery, legacy/custom-store compatibility, and ordered deployment/rollback states, as required by `162-RESEARCH.md`'s Architecture Patterns and Validation Strategy. This is a content-organization precedent rather than a code excerpt: Phase 97's PATTERNS document is highly task-specific and does not supply a reusable OAuth lifetime contract.

Use `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md` as the locked policy source and reuse the completed Phase 153 audit. Preserve the scope limit stated in both context and research: contract/acceptance design only; do not imply runtime enforcement.

### JSON acceptance matrix (fixture, declarative transform)

**Analog:** None found among the nearby tracked planning artifacts or repository acceptance fixtures. Treat the JSON schema and case layout as new, minimal phase-local artifacts. Give each case a stable identifier, input/state assumptions, expected result, and decision/requirement references. Include deterministic boundary arithmetic and explicit expected-contract labeling; avoid embedding runtime claims in fixture names or descriptions.

### Python validator (utility, file I/O and validation)

**Analog:** `scripts/maintainer/verify_phase140_read_only_closure.py` (tracked; standalone Python standard-library validator). Its imports at lines 15–30 show the repository's standard-library-only style (`argparse`, `json`, `Path`, `re`, `sys`). Its `strict_json` at lines 103–119 demonstrates rejecting duplicate keys and malformed JSON; `exact_keys` and integer helpers at lines 122–134 demonstrate small schema predicates; `fail` at lines 77–78 uses one domain exception for actionable validation failures.

Copy only the relevant local-file validation shape: deterministic reads, explicit schema checks, useful failure messages, and nonzero failure on invalid input. Phase 162's validator should check document/fixture coverage, local links, arithmetic and selected semantic contradictions, then exit. Do not copy the Phase 140 verifier's network calls, authenticated CLI, Git refresh, receipt handling, private result writing, or workflow-specific schemas.

## Shared Patterns

### Contract truth boundary

**Sources:** `162-CONTEXT.md`, `162-RESEARCH.md`, and `162-VALIDATION.md`. 
All fixtures and validator output describe completeness and consistency of the design contract. Runtime behavior, migrations, race handling, security controls, and CI proof remain assigned to Phases 163–166. Validation output must state this boundary clearly.

### Traceability and scope

Reuse the selected decisions rather than reopen them; map DCR requirements separately from D-number coverage. Reuse the Phase 153 audit instead of repeating the broad source audit. Keep standards metadata distinct from Lockspire duration policy and local extension fields.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Phase-local JSON acceptance matrix | fixture / data | declarative transform | No tracked repository fixture matches this phase's deterministic lifecycle, compatibility, and deployment contract cases. |

## Metadata

**Analog search scope:** `.planning/milestones/` contract and validation artifacts; tracked Python under `scripts/maintainer/`; phase-local `162-VALIDATION.md`.  
**Pattern extraction date:** 2026-10-20
